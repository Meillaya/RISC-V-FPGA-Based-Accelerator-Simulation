# RISC-V SoC Makefile

# Tools
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Directories
SRC_DIR = src
TB_DIR = tb
BUILD_DIR = build

# Source files
SOURCES = $(SRC_DIR)/picorv32.v \
          $(SRC_DIR)/riscv_soc.v \
          $(SRC_DIR)/bus_interconnect.v \
          $(SRC_DIR)/rom_memory.v \
          $(SRC_DIR)/ram_memory.v \
          $(SRC_DIR)/matrix_accel_wrapper.v \
          $(SRC_DIR)/matrix_mult.v \
          $(SRC_DIR)/matrix_mult_top.v \
          $(SRC_DIR)/pe.v \
          $(SRC_DIR)/bram.v

# Testbench files
TB_SOURCES = $(TB_DIR)/riscv_soc_tb.v

# Build targets
.PHONY: all clean sim view

all: sim

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Compile the design
$(BUILD_DIR)/riscv_soc_tb: $(SOURCES) $(TB_SOURCES) | $(BUILD_DIR)
	$(IVERILOG) -o $@ -I$(SRC_DIR) $(SOURCES) $(TB_SOURCES)

# Run simulation
sim: $(BUILD_DIR)/riscv_soc_tb
	cd $(BUILD_DIR) && $(VVP) riscv_soc_tb

# View waveforms (if GTKWave is available)
view: $(BUILD_DIR)/riscv_soc_tb.vcd
	$(GTKWAVE) $(BUILD_DIR)/riscv_soc_tb.vcd &

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)

# Check syntax only
check: | $(BUILD_DIR)
	$(IVERILOG) -t null -I$(SRC_DIR) $(SOURCES) $(TB_SOURCES)

# Help
help:
	@echo "Available targets:"
	@echo "  all    - Build and run simulation (default)"
	@echo "  sim    - Run simulation"
	@echo "  view   - Open waveform viewer"
	@echo "  check  - Check syntax only"
	@echo "  clean  - Clean build artifacts"
	@echo "  help   - Show this help" 