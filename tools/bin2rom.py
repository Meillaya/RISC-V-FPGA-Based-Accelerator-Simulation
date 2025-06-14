#!/usr/bin/env python3
"""
Binary to ROM converter for RISC-V SoC
Converts a binary file to Verilog $readmemh format
"""

import sys
import struct
from pathlib import Path

def binary_to_rom(binary_file, output_file, rom_size_bytes=16384):
    """Convert binary file to Verilog ROM format"""
    
    # Read binary file
    try:
        with open(binary_file, 'rb') as f:
            binary_data = f.read()
    except FileNotFoundError:
        print(f"Error: Binary file {binary_file} not found")
        return False
    
    print(f"Binary file size: {len(binary_data)} bytes")
    
    if len(binary_data) > rom_size_bytes:
        print(f"Error: Binary ({len(binary_data)} bytes) too large for ROM ({rom_size_bytes} bytes)")
        return False
    
    # Pad binary to word boundary
    while len(binary_data) % 4 != 0:
        binary_data += b'\x00'
    
    # Convert to 32-bit words
    words = []
    for i in range(0, len(binary_data), 4):
        word_bytes = binary_data[i:i+4]
        if len(word_bytes) == 4:
            # Little endian conversion (RISC-V is little endian)
            word = struct.unpack('<I', word_bytes)[0]
            words.append(word)
    
    print(f"Generated {len(words)} words")
    
    # Create ROM initialization file
    try:
        with open(output_file, 'w') as f:
            f.write("// ROM initialization data\n")
            f.write("// Generated from: {}\n".format(binary_file))
            f.write("// Size: {} words\n\n".format(len(words)))
            
            for i, word in enumerate(words):
                f.write(f"        rom_data[{i:4d}] = 32'h{word:08x};  // 0x{i*4:04x}: {word:08x}\n")
        
        print(f"ROM initialization written to {output_file}")
        return True
        
    except Exception as e:
        print(f"Error writing output file: {e}")
        return False

def generate_verilog_rom(binary_file, verilog_file, rom_size_bytes=16384):
    """Generate complete Verilog ROM module with embedded binary"""
    
    # Read and process binary
    try:
        with open(binary_file, 'rb') as f:
            binary_data = f.read()
    except FileNotFoundError:
        print(f"Error: Binary file {binary_file} not found")
        return False
    
    print(f"Binary file size: {len(binary_data)} bytes")
    
    if len(binary_data) > rom_size_bytes:
        print(f"Error: Binary ({len(binary_data)} bytes) too large for ROM ({rom_size_bytes} bytes)")
        return False
    
    # Pad binary to word boundary  
    while len(binary_data) % 4 != 0:
        binary_data += b'\x00'
    
    # Convert to 32-bit words
    words = []
    for i in range(0, len(binary_data), 4):
        word_bytes = binary_data[i:i+4]
        if len(word_bytes) == 4:
            word = struct.unpack('<I', word_bytes)[0]
            words.append(word)
    
    # Calculate number of words for ROM
    rom_words = rom_size_bytes // 4
    
    # Generate Verilog module
    verilog_content = f'''\
`timescale 1ns / 1ps

module rom_memory #(
    parameter SIZE_BYTES = {rom_size_bytes},
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
'''
    
    # Add the actual program data
    BASE_ADDR = 0x80000000  # RISC-V base address
    for i, word in enumerate(words):
        verilog_content += f"        rom_data[{i:4d}] = 32'h{word:08x};  // 0x{BASE_ADDR+i*4:08x}\n"
    
    verilog_content += '''\
    end

endmodule
'''
    
    # Write Verilog file
    try:
        with open(verilog_file, 'w') as f:
            f.write(verilog_content)
        print(f"Verilog ROM module written to {verilog_file}")
        return True
    except Exception as e:
        print(f"Error writing Verilog file: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 bin2rom.py <binary_file> <output_file> [rom_size]")
        print("       python3 bin2rom.py <binary_file> <output.v> --verilog [rom_size]")
        sys.exit(1)
    
    binary_file = sys.argv[1]
    output_file = sys.argv[2]
    
    # Check for Verilog mode
    verilog_mode = "--verilog" in sys.argv
    
    # Get ROM size
    rom_size = 16384  # Default 16KB
    for i, arg in enumerate(sys.argv):
        if arg.isdigit():
            rom_size = int(arg)
            break
    
    if verilog_mode:
        success = generate_verilog_rom(binary_file, output_file, rom_size)
    else:
        success = binary_to_rom(binary_file, output_file, rom_size)
    
    sys.exit(0 if success else 1) 