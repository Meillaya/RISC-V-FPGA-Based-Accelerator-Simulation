`timescale 1ns / 1ps

module matrix_accel_wrapper #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 32,
    parameter M = 4,
    parameter N = 4,
    parameter P = 4,
    parameter BASE_ADDR = 32'h10000000
)(
    input clk,
    input rst_n,
    
    // CPU memory interface
    input         mem_valid,
    output        mem_ready,
    input  [31:0] mem_addr,
    input  [31:0] mem_wdata,
    input  [3:0]  mem_wstrb,
    output [31:0] mem_rdata
);

    // Memory map offsets  
    localparam CONTROL_REG = 32'h00000100;  // 0x10000100 - Control register
    localparam STATUS_REG  = 32'h00000104;  // 0x10000104 - Status register  
    localparam CONFIG_REG  = 32'h00000108;  // 0x10000108 - Config register
    localparam MATRIX_A_BASE = 32'h00000000; // 0x10000000 - Matrix A data
    localparam MATRIX_B_BASE = 32'h00000040; // 0x10000040 - Matrix B data  
    localparam MATRIX_C_BASE = 32'h00000080; // 0x10000080 - Result matrix

    // Calculate relative address
    wire [31:0] rel_addr = mem_addr - BASE_ADDR;
    
    // Address decode
    wire access_control = (rel_addr == CONTROL_REG);
    wire access_status  = (rel_addr == STATUS_REG);
    wire access_config  = (rel_addr == CONFIG_REG);
    wire access_matrix_a = (rel_addr >= MATRIX_A_BASE) && (rel_addr < MATRIX_A_BASE + M*N*4);
    wire access_matrix_b = (rel_addr >= MATRIX_B_BASE) && (rel_addr < MATRIX_B_BASE + N*P*4);
    wire access_matrix_c = (rel_addr >= MATRIX_C_BASE) && (rel_addr < MATRIX_C_BASE + M*P*4);
    
    // Control and status registers
    reg [31:0] control_reg;
    reg [31:0] status_reg;
    reg [31:0] config_reg;
    
    // Matrix data storage
    reg [DATA_WIDTH-1:0] matrix_a [0:M*N-1];
    reg [DATA_WIDTH-1:0] matrix_b [0:N*P-1];
    reg [ACC_WIDTH-1:0]  matrix_c [0:M*P-1];
    
    // Matrix accelerator signals
    wire accel_start = control_reg[0];
    wire accel_reset = control_reg[1];
    wire accel_done;
    
    // Always ready for register/memory accesses
    assign mem_ready = mem_valid;
    
    // Read logic
    reg [31:0] read_data;
    assign mem_rdata = read_data;
    
    always @(*) begin
        read_data = 32'h0;
        if (mem_valid && (mem_wstrb == 4'h0)) begin  // Read operation
            if (access_control) begin
                read_data = control_reg;
            end else if (access_status) begin
                read_data = {30'h0, accel_done, ~accel_done}; // [1:0] = {done, busy}
            end else if (access_config) begin
                read_data = config_reg;
            end else if (access_matrix_a) begin
                // Read from matrix A
                read_data = {24'h0, matrix_a[(rel_addr - MATRIX_A_BASE) >> 2]};
            end else if (access_matrix_b) begin
                // Read from matrix B
                read_data = {24'h0, matrix_b[(rel_addr - MATRIX_B_BASE) >> 2]};
            end else if (access_matrix_c) begin
                // Read from matrix C results
                read_data = matrix_c[(rel_addr - MATRIX_C_BASE) >> 2];
            end
        end
    end
    
    // Write logic
    integer i;
    always @(posedge clk) begin
        if (!rst_n) begin
            control_reg <= 32'h0;
            status_reg <= 32'h0;
            config_reg <= {16'h0, P[7:0], N[7:0]}; // Default config
            
            // Initialize matrices to zero
            for (i = 0; i < M*N; i = i + 1) matrix_a[i] <= 8'h0;
            for (i = 0; i < N*P; i = i + 1) matrix_b[i] <= 8'h0;
            for (i = 0; i < M*P; i = i + 1) matrix_c[i] <= 32'h0;
        end else begin
            // Clear start bit automatically after one cycle
            if (control_reg[0]) control_reg[0] <= 1'b0;
            
            if (mem_valid && |mem_wstrb) begin  // Write operation
                if (access_control) begin
                    if (mem_wstrb[0]) control_reg[7:0]   <= mem_wdata[7:0];
                    if (mem_wstrb[1]) control_reg[15:8]  <= mem_wdata[15:8];
                    if (mem_wstrb[2]) control_reg[23:16] <= mem_wdata[23:16];
                    if (mem_wstrb[3]) control_reg[31:24] <= mem_wdata[31:24];
                end else if (access_config) begin
                    if (mem_wstrb[0]) config_reg[7:0]   <= mem_wdata[7:0];
                    if (mem_wstrb[1]) config_reg[15:8]  <= mem_wdata[15:8];
                    if (mem_wstrb[2]) config_reg[23:16] <= mem_wdata[23:16];
                    if (mem_wstrb[3]) config_reg[31:24] <= mem_wdata[31:24];
                end else if (access_matrix_a) begin
                    // Write to matrix A (only write lowest byte)
                    if (mem_wstrb[0]) matrix_a[(rel_addr - MATRIX_A_BASE) >> 2] <= mem_wdata[7:0];
                end else if (access_matrix_b) begin
                    // Write to matrix B (only write lowest byte)
                    if (mem_wstrb[0]) matrix_b[(rel_addr - MATRIX_B_BASE) >> 2] <= mem_wdata[7:0];
                end
            end
        end
    end

    // Connect matrix accelerator - we need to bridge between BRAM interface and our arrays
    
    // BRAM interface signals for matrix accelerator
    wire [$clog2(M*N)-1:0] bram_a_addr;
    wire [DATA_WIDTH-1:0]  bram_a_rdata;
    wire [$clog2(N*P)-1:0] bram_b_addr;
    wire [DATA_WIDTH-1:0]  bram_b_rdata;
    wire [$clog2(M*P)-1:0] bram_c_addr;
    wire                   bram_c_we;
    wire [ACC_WIDTH-1:0]   bram_c_wdata;
    
    // Connect matrix data to BRAM interface
    assign bram_a_rdata = matrix_a[bram_a_addr];
    assign bram_b_rdata = matrix_b[bram_b_addr];
    
    // Write results back to matrix C
    always @(posedge clk) begin
        if (bram_c_we) begin
            matrix_c[bram_c_addr] <= bram_c_wdata;
        end
    end

    // Matrix multiplication accelerator instance
    matrix_mult #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .M(M),
        .N(N),
        .P(P)
    ) matrix_mult_inst (
        .clk(clk),
        .rst_n(rst_n & ~accel_reset),
        .start(accel_start),
        .done(accel_done),
        .bram_a_addr(bram_a_addr),
        .bram_a_rdata(bram_a_rdata),
        .bram_b_addr(bram_b_addr),
        .bram_b_rdata(bram_b_rdata),
        .bram_c_addr(bram_c_addr),
        .bram_c_we(bram_c_we),
        .bram_c_wdata(bram_c_wdata)
    );

endmodule 