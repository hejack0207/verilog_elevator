# Makefile for Verilog Elevator Controller Project
# Supports Icarus Verilog, Verilator, ModelSim, and Vivado

# Project variables
PROJECT = elevator
RTL_FILES = elevator_controller.v
TB_FILES = elevator_tb.v
VERILATOR_TB = elevator_verilator_tb.cpp
VCD_FILE = elevator.vcd

# Tool detection
IVERILOG ?= iverilog
VVP ?= vvp
GTKWAVE ?= gtkwave
VERILATOR ?= verilator
VLOG ?= vlog
VSIM ?= vsim
VIVADO ?= vivado

# Compiler flags
IVERILOG_FLAGS = -g2012
VERILATOR_FLAGS = -Wall --cc --exe --trace

# Default target
.PHONY: all
all: help

# Help target
.PHONY: help
help:
	@echo "Verilog Elevator Controller Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  iverilog-compile  - Compile with Icarus Verilog"
	@echo "  iverilog-run      - Run simulation with Icarus Verilog"
	@echo "  iverilog-wave     - View waveform with GTKWave"
	@echo "  verilator-compile - Compile with Verilator"
	@echo "  verilator-run     - Run simulation with Verilator"
	@echo "  verilator-wave    - View waveform with GTKWave"
	@echo "  modelsim-compile  - Compile with ModelSim"
	@echo "  modelsim-run      - Run simulation with ModelSim"
	@echo "  vivado-compile    - Compile with Vivado"
	@echo "  vivado-run        - Run simulation with Vivado"
	@echo "  clean             - Remove generated files"
	@echo "  clean-all         - Remove all generated files including obj_dir"
	@echo ""

# Icarus Verilog targets
.PHONY: iverilog-compile
iverilog-compile:
	@echo "Compiling with Icarus Verilog..."
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(PROJECT)_sim $(RTL_FILES) $(TB_FILES)
	@echo "Compilation complete: $(PROJECT)_sim"

.PHONY: iverilog-run
iverilog-run: iverilog-compile
	@echo "Running simulation with Icarus Verilog..."
	$(VVP) $(PROJECT)_sim
	@echo "Simulation complete: $(VCD_FILE)"

.PHONY: iverilog-wave
iverilog-wave: iverilog-run
	@echo "Launching GTKWave..."
	$(GTKWAVE) $(VCD_FILE) &

# Verilator targets
.PHONY: verilator-compile
verilator-compile:
	@echo "Compiling with Verilator..."
	$(VERILATOR) $(VERILATOR_FLAGS) $(RTL_FILES) $(VERILATOR_TB) --top-module elevator_controller
	@echo "Compilation complete"

.PHONY: verilator-run
verilator-run: verilator-compile
	@echo "Building Verilator executable..."
	$(MAKE) -C obj_dir -f Velevator_controller.mk
	@echo "Running simulation with Verilator..."
	obj_dir/Velevator_controller
	@echo "Simulation complete"

.PHONY: verilator-wave
verilator-wave: verilator-run
	@echo "Launching GTKWave..."
	$(GTKWAVE) $(VCD_FILE) &

# ModelSim targets
.PHONY: modelsim-compile
modelsim-compile:
	@echo "Compiling with ModelSim..."
	$(VLOG) $(RTL_FILES) $(TB_FILES)
	@echo "Compilation complete"

.PHONY: modelsim-run
modelsim-run: modelsim-compile
	@echo "Running simulation with ModelSim..."
	$(VSIM) -c -do "run -all; quit" elevator_tb
	@echo "Simulation complete"

# Vivado targets
.PHONY: vivado-compile
vivado-compile:
	@echo "Compiling with Vivado..."
	$(VIVADO) -mode batch -source vivado_compile.tcl
	@echo "Compilation complete"

.PHONY: vivado-run
vivado-run: vivado-compile
	@echo "Running simulation with Vivado..."
	$(VIVADO) -mode batch -source vivado_run.tcl
	@echo "Simulation complete"

# Clean targets
.PHONY: clean
clean:
	@echo "Cleaning generated files..."
	rm -f $(PROJECT)_sim
	rm -f $(VCD_FILE)
	rm -f work
	rm -f transcript
	rm -f vsim.wlf
	@echo "Clean complete"

.PHONY: clean-all
clean-all: clean
	@echo "Cleaning all generated files..."
	rm -rf obj_dir
	@echo "Clean complete"