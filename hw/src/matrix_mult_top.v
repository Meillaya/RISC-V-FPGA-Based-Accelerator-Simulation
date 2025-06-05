`timescale 1ns / 1ps

module matrix_mult_top #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 32,
    parameter M = 4,
    parameter N = 4,
    parameter P = 4
)(
    input clk,
    input rst_n,
    input start,
    output done
);

    // BRAM A for Matrix A
    wire [$clog2(M*N)-1:0] bram_a_addr;
    wire [DATA_WIDTH-1:0]  bram_a_rdata;
    
    bram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH($clog2(M*N))
    ) bram_a_inst (
        .clk(clk),
        .we_a(1'b0), // Read-only
        .addr_a('0),
        .din_a('0),
        .addr_b(bram_a_addr),
        .dout_b(bram_a_rdata)
    );

    // BRAM B for Matrix B
    wire [$clog2(N*P)-1:0] bram_b_addr;
    wire [DATA_WIDTH-1:0]  bram_b_rdata;

    bram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH($clog2(N*P))
    ) bram_b_inst (
        .clk(clk),
        .we_a(1'b0), // Read-only
        .addr_a('0),
        .din_a('0),
        .addr_b(bram_b_addr),
        .dout_b(bram_b_rdata)
    );

    // BRAM C for Matrix C
    wire [$clog2(M*P)-1:0] bram_c_addr;
    wire                   bram_c_we;
    wire [ACC_WIDTH-1:0]   bram_c_wdata;

    bram #(
        .DATA_WIDTH(ACC_WIDTH),
        .ADDR_WIDTH($clog2(M*P))
    ) bram_c_inst (
        .clk(clk),
        .we_a(bram_c_we),
        .addr_a(bram_c_addr),
        .din_a(bram_c_wdata),
        .addr_b('0), // Not read
        .dout_b()
    );

    // Matrix multiplication core
    matrix_mult #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .M(M),
        .N(N),
        .P(P)
    ) matrix_mult_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .done(done),
        .bram_a_addr(bram_a_addr),
        .bram_a_rdata(bram_a_rdata),
        .bram_b_addr(bram_b_addr),
        .bram_b_rdata(bram_b_rdata),
        .bram_c_addr(bram_c_addr),
        .bram_c_we(bram_c_we),
        .bram_c_wdata(bram_c_wdata)
    );

endmodule 