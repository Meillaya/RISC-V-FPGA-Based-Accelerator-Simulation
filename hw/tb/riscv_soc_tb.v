`timescale 1ns / 1ps

module riscv_soc_tb;

    // Testbench signals
    reg clk;
    reg rst_n;
    wire debug_cpu_trap;
    wire [31:0] debug_cpu_pc;

    // Clock generation - 100MHz clock
    always #5 clk = ~clk;

    // DUT instantiation
    riscv_soc #(
        .DATA_WIDTH(8),
        .ACC_WIDTH(32),
        .M(4),
        .N(4),
        .P(4),
        .ROM_SIZE_BYTES(16384),
        .RAM_SIZE_BYTES(16384)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .debug_cpu_trap(debug_cpu_trap),
        .debug_cpu_pc(debug_cpu_pc)
    );

    // Enhanced monitoring variables
    integer cycle_count;
    integer test_timeout;
    reg [31:0] prev_pc;
    integer pc_stuck_counter;

    // Test sequence
    initial begin
        // Initialize VCD dump
        $dumpfile("riscv_soc_tb.vcd");
        $dumpvars(0, riscv_soc_tb);
        
        // Initialize signals
        clk = 0;
        rst_n = 0;
        cycle_count = 0;
        test_timeout = 200000; // 200k cycles for matrix computation
        prev_pc = 0;
        pc_stuck_counter = 0;
        
        $display("=== RISC-V SoC Matrix Accelerator Integration Test ===");
        $display("Testing with simple assembly program");
        $display("Expected test outcomes:");
        $display("  SUCCESS: PC = 0x80001000 (test passed)");
        $display("  FAILURE: PC = 0x80002000 (test failed)");
        $display("  TIMEOUT: PC = 0x80003000 (accelerator timeout)");
        $display("");
        
        // Reset sequence
        $display("Time: %0t - Applying reset...", $time);
        #100;
        rst_n = 1;
        $display("Time: %0t - Reset released, CPU should start at PC: 0x80000000", $time);
        
        // Wait for CPU initialization
        #200;
        $display("Time: %0t - CPU PC after reset: 0x%08h", $time, debug_cpu_pc);
        
        // Monitor execution
        $display("Time: %0t - Starting matrix accelerator test monitoring...", $time);
        
        // Let the program run
        while (cycle_count < test_timeout) begin
            #10; // One clock cycle
            cycle_count = cycle_count + 1;
            
            // Check for test completion based on PC location
            if (debug_cpu_pc == 32'h80001000) begin
                $display("\n🎉 === TEST SUCCESS ===");
                $display("Time: %0t, Cycle: %0d", $time, cycle_count);
                $display("Matrix accelerator test PASSED!");
                $display("CPU reached success address: 0x%08h", debug_cpu_pc);
                cycle_count = test_timeout; // Exit loop
            end else if (debug_cpu_pc == 32'h80002000) begin
                $display("\n❌ === TEST FAILURE ===");
                $display("Time: %0t, Cycle: %0d", $time, cycle_count);
                $display("Matrix accelerator test FAILED!");
                $display("CPU reached failure address: 0x%08h", debug_cpu_pc);
                cycle_count = test_timeout; // Exit loop
            end else if (debug_cpu_pc == 32'h80003000) begin
                $display("\n⏰ === TEST TIMEOUT ===");
                $display("Time: %0t, Cycle: %0d", $time, cycle_count);
                $display("Matrix accelerator operation timed out!");
                $display("CPU reached timeout address: 0x%08h", debug_cpu_pc);
                cycle_count = test_timeout; // Exit loop
            end
            
            // Check for CPU trap (unexpected)
            if (debug_cpu_trap) begin
                $display("\n⚠️  === UNEXPECTED CPU TRAP ===");
                $display("Time: %0t, Cycle: %0d", $time, cycle_count);
                $display("CPU trap detected at PC: 0x%08h", debug_cpu_pc);
                cycle_count = test_timeout; // Exit loop
            end
            
            // Detect genuine PC stuck (not test completion)
            if (debug_cpu_pc == prev_pc && 
                debug_cpu_pc != 32'h80001000 && 
                debug_cpu_pc != 32'h80002000 && 
                debug_cpu_pc != 32'h80003000) begin
                pc_stuck_counter = pc_stuck_counter + 1;
                if (pc_stuck_counter > 1000) begin
                    $display("\n🔄 === CPU STUCK ===");
                    $display("Time: %0t, Cycle: %0d", $time, cycle_count);
                    $display("PC stuck at: 0x%08h for %0d cycles", debug_cpu_pc, pc_stuck_counter);
                    $display("This may indicate a hardware issue");
                    cycle_count = test_timeout; // Exit loop
                end
            end else begin
                prev_pc = debug_cpu_pc;
                pc_stuck_counter = 0;
            end
            
            // Periodic status updates
            if (cycle_count % 5000 == 0) begin
                $display("Time: %0t, Cycle: %5d, PC: 0x%08h", 
                         $time, cycle_count, debug_cpu_pc);
            end
        end
        
        // Final status
        if (cycle_count >= test_timeout && 
            debug_cpu_pc != 32'h80001000 && 
            debug_cpu_pc != 32'h80002000 && 
            debug_cpu_pc != 32'h80003000) begin
            $display("\n⏳ === SIMULATION TIMEOUT ===");
            $display("Test did not complete within %0d cycles", test_timeout);
            $display("Final PC: 0x%08h", debug_cpu_pc);
        end
        
        $display("\n=== Hardware-Software Integration Test Complete ===");
        $display("Total simulation cycles: %0d", cycle_count);
        $display("Final CPU state:");
        $display("  PC: 0x%08h", debug_cpu_pc);
        $display("  Trap: %b", debug_cpu_trap);
        
        // Additional delay for final analysis
        #1000;
        $display("=== Simulation Finished ===");
        $finish;
    end

    // Memory access monitor
    always @(posedge clk) begin
        if (rst_n) begin
            // Monitor memory accesses to matrix accelerator
            if (dut.cpu_mem_valid && dut.cpu_mem_ready) begin
                if (dut.cpu_mem_addr >= 32'h10000000 && dut.cpu_mem_addr <= 32'h100003FF) begin
                    if (dut.cpu_mem_wstrb != 0) begin
                        $display("Time: %0t - Matrix accel WRITE: Addr=0x%08h, Data=0x%08h", 
                                 $time, dut.cpu_mem_addr, dut.cpu_mem_wdata);
                    end else begin
                        $display("Time: %0t - Matrix accel READ: Addr=0x%08h, Data=0x%08h", 
                                 $time, dut.cpu_mem_addr, dut.cpu_mem_rdata);
                    end
                end
            end
        end
    end

endmodule 