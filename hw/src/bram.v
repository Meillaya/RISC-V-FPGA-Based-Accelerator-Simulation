`timescale 1ns / 1ps

module bram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 10,
    parameter DEPTH = 1 << ADDR_WIDTH
)(
    input clk,

    // Port A (Write)
    input we_a,
    input [ADDR_WIDTH-1:0] addr_a,
    input [DATA_WIDTH-1:0] din_a,

    // Port B (Read)
    input [ADDR_WIDTH-1:0] addr_b,
    output reg [DATA_WIDTH-1:0] dout_b
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (we_a) begin
            mem[addr_a] <= din_a;
        end
    end

    always @(posedge clk) begin
        dout_b <= mem[addr_b];
    end

endmodule 