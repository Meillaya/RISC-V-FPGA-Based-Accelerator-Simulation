`timescale 1ns/1ps

module matrix_mult_tb;

    // Parameters
    localparam DATA_WIDTH = 8;
    localparam ACC_WIDTH = 32;
    localparam M = 2;
    localparam N = 2;
    localparam P = 2;
    localparam CLK_PERIOD = 10;

    // Signals
    reg clk;
    reg rst_n;
    reg start;
    wire done;

    // DUT instantiation
    matrix_mult_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .M(M),
        .N(N),
        .P(P)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .done(done)
    );

    // Clock generator
    always #(CLK_PERIOD/2) clk = ~clk;

    // Main test sequence
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        start = 0;

        // Initialize BRAMs
        // Matrix A: [[1, 2], [3, 4]] -> row-major: [1, 2, 3, 4]
        dut.bram_a_inst.mem[0] = 1;
        dut.bram_a_inst.mem[1] = 2;
        dut.bram_a_inst.mem[2] = 3;
        dut.bram_a_inst.mem[3] = 4;

        // Matrix B: [[5, 6], [7, 8]] -> col-major: [5, 7, 6, 8]
        dut.bram_b_inst.mem[0] = 5;
        dut.bram_b_inst.mem[1] = 7;
        dut.bram_b_inst.mem[2] = 6;
        dut.bram_b_inst.mem[3] = 8;
        
        // Reset sequence
        #CLK_PERIOD;
        rst_n = 1;
        
        // Start multiplication
        #CLK_PERIOD;
        start = 1;
        
        // Wait for done
        wait(done);
        start = 0;
        
        #CLK_PERIOD;

        // Check results
        // Expected C: [[19, 22], [43, 50]] -> row-major: [19, 22, 43, 50]
        if (dut.bram_c_inst.mem[0] == 19 &&
            dut.bram_c_inst.mem[1] == 22 &&
            dut.bram_c_inst.mem[2] == 43 &&
            dut.bram_c_inst.mem[3] == 50) begin
            $display("Test Passed!");
        end else begin
            $display("Test Failed!");
            $display("Result C: [%d, %d, %d, %d]", 
                dut.bram_c_inst.mem[0], dut.bram_c_inst.mem[1],
                dut.bram_c_inst.mem[2], dut.bram_c_inst.mem[3]);
        end
        
        $finish;
    end

endmodule 