`timescale 1ns / 1ps

module rom_memory #(
    parameter SIZE_BYTES = 16384,
    parameter BASE_ADDR = 32'h80000000
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

    // ROM storage
    reg [31:0] rom_data [0:SIZE_WORDS-1];

    // Address calculation
    wire [ADDR_BITS-1:0] word_addr = (mem_addr - BASE_ADDR) >> 2;
    
    // ROM is always ready for reads, ignores writes
    assign mem_ready = mem_valid;
    
    // Read data
    assign mem_rdata = mem_valid ? rom_data[word_addr] : 32'h0;

    // Initialize ROM with matrix test program
    integer i;
    initial begin
        // Initialize all locations to NOP (addi x0, x0, 0)
        for (i = 0; i < SIZE_WORDS; i = i + 1) begin
            rom_data[i] = 32'h00000013; // NOP instruction
        end
        
        // Load compiled program
        rom_data[   0] = 32'h80008137;  // 0x80000000
        rom_data[   1] = 32'h00010113;  // 0x80000004
        rom_data[   2] = 32'h100002b7;  // 0x80000008
        rom_data[   3] = 32'h00028293;  // 0x8000000c
        rom_data[   4] = 32'h01020337;  // 0x80000010
        rom_data[   5] = 32'h30430313;  // 0x80000014
        rom_data[   6] = 32'h0062a023;  // 0x80000018
        rom_data[   7] = 32'h05060337;  // 0x8000001c
        rom_data[   8] = 32'h70830313;  // 0x80000020
        rom_data[   9] = 32'h0062a223;  // 0x80000024
        rom_data[  10] = 32'h090a1337;  // 0x80000028
        rom_data[  11] = 32'hb0c30313;  // 0x8000002c
        rom_data[  12] = 32'h0062a423;  // 0x80000030
        rom_data[  13] = 32'h0d0e1337;  // 0x80000034
        rom_data[  14] = 32'hf1030313;  // 0x80000038
        rom_data[  15] = 32'h0062a623;  // 0x8000003c
        rom_data[  16] = 32'h11121337;  // 0x80000040
        rom_data[  17] = 32'h31430313;  // 0x80000044
        rom_data[  18] = 32'h0462a023;  // 0x80000048
        rom_data[  19] = 32'h15161337;  // 0x8000004c
        rom_data[  20] = 32'h71830313;  // 0x80000050
        rom_data[  21] = 32'h0462a223;  // 0x80000054
        rom_data[  22] = 32'h191a2337;  // 0x80000058
        rom_data[  23] = 32'hb1c30313;  // 0x8000005c
        rom_data[  24] = 32'h0462a423;  // 0x80000060
        rom_data[  25] = 32'h1d1e2337;  // 0x80000064
        rom_data[  26] = 32'hf2030313;  // 0x80000068
        rom_data[  27] = 32'h0462a623;  // 0x8000006c
        rom_data[  28] = 32'h00100313;  // 0x80000070
        rom_data[  29] = 32'h1062a023;  // 0x80000074
        rom_data[  30] = 32'h000f43b7;  // 0x80000078
        rom_data[  31] = 32'h24038393;  // 0x8000007c
        rom_data[  32] = 32'h1042a303;  // 0x80000080
        rom_data[  33] = 32'h00237e13;  // 0x80000084
        rom_data[  34] = 32'h000e1863;  // 0x80000088
        rom_data[  35] = 32'hfff38393;  // 0x8000008c
        rom_data[  36] = 32'hfe0398e3;  // 0x80000090
        rom_data[  37] = 32'h0400006f;  // 0x80000094
        rom_data[  38] = 32'h0802a303;  // 0x80000098
        rom_data[  39] = 32'h0842a383;  // 0x8000009c
        rom_data[  40] = 32'h0882ae03;  // 0x800000a0
        rom_data[  41] = 32'h08c2ae83;  // 0x800000a4
        rom_data[  42] = 32'h00736f33;  // 0x800000a8
        rom_data[  43] = 32'h01cf6f33;  // 0x800000ac
        rom_data[  44] = 32'h01df6f33;  // 0x800000b0
        rom_data[  45] = 32'h000f0a63;  // 0x800000b4
        rom_data[  46] = 32'h0040006f;  // 0x800000b8
        rom_data[  47] = 32'h800012b7;  // 0x800000bc
        rom_data[  48] = 32'h00028293;  // 0x800000c0
        rom_data[  49] = 32'h00028067;  // 0x800000c4
        rom_data[  50] = 32'h800022b7;  // 0x800000c8
        rom_data[  51] = 32'h00028293;  // 0x800000cc
        rom_data[  52] = 32'h00028067;  // 0x800000d0
        rom_data[  53] = 32'h800032b7;  // 0x800000d4
        rom_data[  54] = 32'h00028293;  // 0x800000d8
        rom_data[  55] = 32'h00028067;  // 0x800000dc
        rom_data[  56] = 32'h0000006f;  // 0x800000e0
        rom_data[  57] = 32'h0000006f;  // 0x800000e4
        rom_data[  58] = 32'h0000006f;  // 0x800000e8
    end

endmodule
