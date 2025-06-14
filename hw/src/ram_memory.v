`timescale 1ns / 1ps

module ram_memory #(
    parameter SIZE_BYTES = 16384,
    parameter BASE_ADDR = 32'h00010000
)(
    input clk,
    input rst_n,
    
    input         mem_valid,
    output        mem_ready,
    input  [31:0] mem_addr,
    input  [31:0] mem_wdata,
    input  [3:0]  mem_wstrb,
    output [31:0] mem_rdata
);

    localparam SIZE_WORDS = SIZE_BYTES / 4;
    localparam ADDR_BITS = $clog2(SIZE_WORDS);

    // RAM storage
    reg [31:0] ram_data [0:SIZE_WORDS-1];

    // Address calculation
    wire [ADDR_BITS-1:0] word_addr = (mem_addr - BASE_ADDR) >> 2;
    
    // RAM is always ready (1 cycle latency)
    assign mem_ready = mem_valid;
    
    // Read logic
    assign mem_rdata = mem_valid ? ram_data[word_addr] : 32'h0;

    // Write logic with byte enables
    always @(posedge clk) begin
        if (mem_valid && |mem_wstrb) begin
            if (mem_wstrb[0]) ram_data[word_addr][7:0]   <= mem_wdata[7:0];
            if (mem_wstrb[1]) ram_data[word_addr][15:8]  <= mem_wdata[15:8];
            if (mem_wstrb[2]) ram_data[word_addr][23:16] <= mem_wdata[23:16];
            if (mem_wstrb[3]) ram_data[word_addr][31:24] <= mem_wdata[31:24];
        end
    end

    // Initialize RAM to known values for debugging
    integer i;
    initial begin
        for (i = 0; i < SIZE_WORDS; i = i + 1) begin
            ram_data[i] = 32'h00000000;
        end
    end

endmodule 