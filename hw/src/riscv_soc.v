`timescale 1ns / 1ps

module riscv_soc #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 32,
    parameter M = 4,
    parameter N = 4,
    parameter P = 4,
    parameter ROM_SIZE_BYTES = 16384,  // 16KB ROM
    parameter RAM_SIZE_BYTES = 16384   // 16KB RAM
)(
    input clk,
    input rst_n,
    
    // Optional external interfaces
    output debug_cpu_trap,
    output [31:0] debug_cpu_pc
);

    // Memory map definitions
    localparam ROM_BASE = 32'h80000000;  // RISC-V standard ROM base
    localparam ROM_TOP  = ROM_BASE + ROM_SIZE_BYTES - 1;
    localparam RAM_BASE = 32'h80004000;  // RAM after ROM
    localparam RAM_TOP  = RAM_BASE + RAM_SIZE_BYTES - 1;
    localparam ACCEL_BASE = 32'h10000000;
    localparam ACCEL_TOP  = 32'h100003FF;

    // PicoRV32 memory interface
    wire        cpu_mem_valid;
    wire        cpu_mem_ready;
    wire [31:0] cpu_mem_addr;
    wire [31:0] cpu_mem_wdata;
    wire [3:0]  cpu_mem_wstrb;
    wire [31:0] cpu_mem_rdata;
    wire        cpu_mem_instr;
    
    // CPU instance
    picorv32 #(
        .ENABLE_COUNTERS(1),
        .ENABLE_MUL(1),
        .ENABLE_DIV(1),
        .BARREL_SHIFTER(1),
        .COMPRESSED_ISA(0),
        .ENABLE_IRQ(1),
        .STACKADDR(RAM_BASE + RAM_SIZE_BYTES),
        .PROGADDR_RESET(ROM_BASE)
    ) cpu (
        .clk(clk),
        .resetn(rst_n),
        .mem_valid(cpu_mem_valid),
        .mem_ready(cpu_mem_ready),
        .mem_addr(cpu_mem_addr),
        .mem_wdata(cpu_mem_wdata),
        .mem_wstrb(cpu_mem_wstrb),
        .mem_rdata(cpu_mem_rdata),
        .mem_instr(cpu_mem_instr),
        .irq(32'h0),  // No interrupts for now
        .eoi(),
        .trace_valid(),
        .trace_data()
    );

    // Debug outputs
    assign debug_cpu_trap = !rst_n; // Placeholder
    assign debug_cpu_pc = cpu_mem_addr; // Placeholder

    // Bus interconnect instance
    bus_interconnect #(
        .ROM_BASE(ROM_BASE),
        .ROM_TOP(ROM_TOP),
        .RAM_BASE(RAM_BASE),
        .RAM_TOP(RAM_TOP),
        .ACCEL_BASE(ACCEL_BASE),
        .ACCEL_TOP(ACCEL_TOP)
    ) interconnect (
        .clk(clk),
        .rst_n(rst_n),
        
        // CPU interface
        .cpu_mem_valid(cpu_mem_valid),
        .cpu_mem_ready(cpu_mem_ready),
        .cpu_mem_addr(cpu_mem_addr),
        .cpu_mem_wdata(cpu_mem_wdata),
        .cpu_mem_wstrb(cpu_mem_wstrb),
        .cpu_mem_rdata(cpu_mem_rdata),
        .cpu_mem_instr(cpu_mem_instr)
    );

endmodule 