`timescale 1ns / 1ps

module pe #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 32
) (
    input clk,
    input rst_n,

    input signed [DATA_WIDTH-1:0] in_a,
    input signed [DATA_WIDTH-1:0] in_b,
    input signed [ACC_WIDTH-1:0]  in_c,
    input                         in_valid,

    output signed [ACC_WIDTH-1:0] out_d,
    output                        out_valid
);

    reg signed [ACC_WIDTH-1:0] d_reg;
    reg                        valid_reg;

    wire signed [2*DATA_WIDTH-1:0] mult_res;

    assign mult_res = in_a * in_b;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_reg <= 0;
            valid_reg <= 0;
        end else begin
            if (in_valid) begin
                d_reg <= mult_res + in_c;
                valid_reg <= 1'b1;
            end else begin
                valid_reg <= 1'b0;
            end
        end
    end

    assign out_d = d_reg;
    assign out_valid = valid_reg;

endmodule 