`timescale 1ns / 1ps

module matrix_mult #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 32,
    parameter M = 4, // Rows of A and C
    parameter N = 4, // Cols of A and Rows of B
    parameter P = 4  // Cols of B and C
)(
    input clk,
    input rst_n,

    input start,
    output reg done,

    // Matrix A BRAM interface
    output reg [$clog2(M*N)-1:0] bram_a_addr,
    input [DATA_WIDTH-1:0] bram_a_rdata,

    // Matrix B BRAM interface
    output reg [$clog2(N*P)-1:0] bram_b_addr,
    input [DATA_WIDTH-1:0] bram_b_rdata,

    // Matrix C BRAM interface
    output reg [$clog2(M*P)-1:0] bram_c_addr,
    output reg bram_c_we,
    output reg [ACC_WIDTH-1:0] bram_c_wdata
);

    // FSM states
    localparam IDLE = 4'd0;
    localparam FETCH_A = 4'd1;
    localparam WAIT_A = 4'd2;
    localparam FETCH_B = 4'd3;
    localparam COMPUTE = 4'd4;
    localparam WRITE_C = 4'd5;
    localparam UPDATE_IJ = 4'd6;
    localparam FINISH = 4'd7;

    reg [3:0] state, next_state;

    // Loop counters
    reg [$clog2(M)-1:0] i; // for C rows
    reg [$clog2(P)-1:0] j; // for C cols
    reg [$clog2(N)-1:0] k; // for inner product

    // PE instance
    wire [ACC_WIDTH-1:0] pe_out_d;
    wire                 pe_out_valid;
    reg  [DATA_WIDTH-1:0] pe_in_a;
    reg  [DATA_WIDTH-1:0] pe_in_b;
    reg  [ACC_WIDTH-1:0]  pe_in_c;
    reg                  pe_in_valid;

    pe #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) pe_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in_a(pe_in_a),
        .in_b(pe_in_b),
        .in_c(pe_in_c),
        .in_valid(pe_in_valid),
        .out_d(pe_out_d),
        .out_valid(pe_out_valid)
    );
    
    reg [ACC_WIDTH-1:0] accum_reg;

    // FSM logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            i <= 0;
            j <= 0;
            k <= 0;
            accum_reg <= 0;
            done <= 0;
            bram_a_addr <= 0;
            bram_b_addr <= 0;
            bram_c_addr <= 0;
            bram_c_we <= 0;
            bram_c_wdata <= 0;
            pe_in_valid <= 0;
        end else begin
            state <= next_state;

            // Default assignments
            pe_in_valid <= 0;
            bram_c_we <= 0;

            case(state)
                IDLE: begin
                    if (start) begin
                        i <= 0;
                        j <= 0;
                        k <= 0;
                        accum_reg <= 0;
                        done <= 0;
                    end
                end
                FETCH_A: begin
                    // Address is set, wait a cycle for data to be ready
                end
                WAIT_A: begin
                    pe_in_a <= bram_a_rdata;
                end
                FETCH_B: begin
                    pe_in_b <= bram_b_rdata;
                    pe_in_c <= (k == 0) ? 0 : accum_reg;
                    pe_in_valid <= 1;
                end
                COMPUTE: begin
                    if(pe_out_valid) begin
                        accum_reg <= pe_out_d;
                        if (k < N-1) begin
                            k <= k + 1;
                        end
                    end
                end
                WRITE_C: begin
                    bram_c_we <= 1;
                    bram_c_wdata <= accum_reg;
                end
                UPDATE_IJ: begin
                    k <= 0;
                    accum_reg <= 0;
                    if (i == M-1 && j == P-1) begin
                        // done will be set in FINISH state
                    end else if (j == P-1) begin
                        i <= i + 1;
                        j <= 0;
                    end else begin
                        j <= j + 1;
                    end
                end
                FINISH: begin
                   done <= 1;
                end
            endcase
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case(state)
            IDLE:
                if (start) next_state = FETCH_A;
            FETCH_A:
                next_state = WAIT_A;
            WAIT_A:
                next_state = FETCH_B;
            FETCH_B:
                next_state = COMPUTE;
            COMPUTE:
                if (pe_out_valid) begin
                    if (k == N-1) begin
                        next_state = WRITE_C;
                    end else begin
                        next_state = FETCH_A;
                    end
                end
            WRITE_C: begin
                next_state = UPDATE_IJ;
            end
            UPDATE_IJ: begin
                if (i == M-1 && j == P-1) begin
                    next_state = FINISH;
                end else begin
                    next_state = FETCH_A;
                end
            end
            FINISH:
                if(!start) next_state = IDLE;
        endcase
    end
    
    // BRAM addressing
    always @(*) begin
        // A is stored row-major. A[i,k]
        bram_a_addr = i * N + k;
        // B is stored column-major for efficiency. B[k,j]
        bram_b_addr = j * N + k;
        // C is stored row-major. C[i,j]
        bram_c_addr = i * P + j;
    end

endmodule 