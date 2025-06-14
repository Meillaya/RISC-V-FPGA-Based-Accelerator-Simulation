`timescale 1ns / 1ps

module bus_interconnect #(
    parameter ROM_BASE = 32'h00000000,
    parameter ROM_TOP  = 32'h00003FFF,
    parameter RAM_BASE = 32'h00010000,
    parameter RAM_TOP  = 32'h00013FFF,
    parameter ACCEL_BASE = 32'h10000000,
    parameter ACCEL_TOP  = 32'h100003FF
)(
    input clk,
    input rst_n,
    
    // CPU interface
    input         cpu_mem_valid,
    output        cpu_mem_ready,
    input  [31:0] cpu_mem_addr,
    input  [31:0] cpu_mem_wdata,
    input  [3:0]  cpu_mem_wstrb,
    output [31:0] cpu_mem_rdata,
    input         cpu_mem_instr
);

    // Address decode logic
    wire sel_rom   = (cpu_mem_addr >= ROM_BASE)   && (cpu_mem_addr <= ROM_TOP);
    wire sel_ram   = (cpu_mem_addr >= RAM_BASE)   && (cpu_mem_addr <= RAM_TOP);
    wire sel_accel = (cpu_mem_addr >= ACCEL_BASE) && (cpu_mem_addr <= ACCEL_TOP);
    
    // Invalid address detection
    wire sel_valid = sel_rom | sel_ram | sel_accel;
    
    // ROM interface
    wire        rom_mem_valid;
    wire        rom_mem_ready;
    wire [31:0] rom_mem_rdata;
    
    // RAM interface  
    wire        ram_mem_valid;
    wire        ram_mem_ready;
    wire [31:0] ram_mem_rdata;
    
    // Accelerator interface
    wire        accel_mem_valid;
    wire        accel_mem_ready;
    wire [31:0] accel_mem_rdata;

    // Route valid signal
    assign rom_mem_valid   = cpu_mem_valid & sel_rom;
    assign ram_mem_valid   = cpu_mem_valid & sel_ram;
    assign accel_mem_valid = cpu_mem_valid & sel_accel;

    // Multiplex ready signal
    assign cpu_mem_ready = sel_valid ? (
        (sel_rom   ? rom_mem_ready   : 1'b0) |
        (sel_ram   ? ram_mem_ready   : 1'b0) |
        (sel_accel ? accel_mem_ready : 1'b0)
    ) : 1'b0;  // Invalid address returns not ready

    // Multiplex read data
    assign cpu_mem_rdata = 
        sel_rom   ? rom_mem_rdata   :
        sel_ram   ? ram_mem_rdata   :
        sel_accel ? accel_mem_rdata :
        32'hDEADBEEF;  // Invalid address pattern

    // ROM instance (read-only)
    rom_memory #(
        .SIZE_BYTES(ROM_TOP - ROM_BASE + 1),
        .BASE_ADDR(ROM_BASE)
    ) rom (
        .clk(clk),
        .rst_n(rst_n),
        .mem_valid(rom_mem_valid),
        .mem_ready(rom_mem_ready),
        .mem_addr(cpu_mem_addr),
        .mem_wdata(cpu_mem_wdata),
        .mem_wstrb(cpu_mem_wstrb),
        .mem_rdata(rom_mem_rdata)
    );

    // RAM instance (read-write)
    ram_memory #(
        .SIZE_BYTES(RAM_TOP - RAM_BASE + 1),
        .BASE_ADDR(RAM_BASE)
    ) ram (
        .clk(clk),
        .rst_n(rst_n),
        .mem_valid(ram_mem_valid),
        .mem_ready(ram_mem_ready),
        .mem_addr(cpu_mem_addr),
        .mem_wdata(cpu_mem_wdata),
        .mem_wstrb(cpu_mem_wstrb),
        .mem_rdata(ram_mem_rdata)
    );

    // Matrix accelerator wrapper
    matrix_accel_wrapper #(
        .DATA_WIDTH(8),
        .ACC_WIDTH(32),
        .M(4),
        .N(4),
        .P(4),
        .BASE_ADDR(ACCEL_BASE)
    ) matrix_accel (
        .clk(clk),
        .rst_n(rst_n),
        .mem_valid(accel_mem_valid),
        .mem_ready(accel_mem_ready),
        .mem_addr(cpu_mem_addr),
        .mem_wdata(cpu_mem_wdata),
        .mem_wstrb(cpu_mem_wstrb),
        .mem_rdata(accel_mem_rdata)
    );

endmodule 