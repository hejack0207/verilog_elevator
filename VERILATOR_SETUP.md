# Verilator Setup for Elevator Controller

## Overview

This document describes how to use Verilator to simulate the elevator controller project.

## Prerequisites

- Verilator 3.922 (or compatible version)
- C++ compiler (g++)
- Standard Verilog files: `elevator_controller.v`

## Files Created

1. **elevator_verilator_tb.cpp** - C++ testbench for Verilator simulation
2. **obj_dir/** - Directory containing generated Verilator files and executable

## Compilation Steps

### 1. Compile Verilog with Verilator

```bash
verilator -Wno-fatal -cc elevator_controller.v --exe elevator_verilator_tb.cpp -CFLAGS "-I/usr/include/verilated"
```

**Options explained:**
- `-Wno-fatal` - Treat warnings as warnings (not errors)
- `-cc` - Generate C++ code
- `--exe` - Link with executable testbench
- `-CFLAGS` - Additional C compiler flags

### 2. Build the executable

```bash
make -C obj_dir -f Velevator_controller.mk
```

This creates the executable: `obj_dir/Velevator_controller`

### 3. Run the simulation

```bash
./obj_dir/Velevator_controller
```

## Code Modifications Made to Support Verilator

### elevator_controller.v

The following changes were made to make the design Verilator-compatible:

#### 1. Fixed Blocking/Non-Blocking Assignment Conflict

**Problem:** The `direction_up` signal was being assigned in both combinational (`always @(*)`) and sequential (`always @(posedge clk)`) blocks, which Verilator doesn't allow.

**Solution:** Moved all `direction_up` assignments to the sequential block:

```verilog
// In sequential always block:
if (state == IDLE && next_state == MOVING_UP) begin
    direction_up <= 1;
end else if (state == IDLE && next_state == MOVING_DOWN) begin
    direction_up <= 0;
end
else if (state == MOVING_UP && next_state == IDLE) begin
    direction_up <= 0;
end else if (state == MOVING_DOWN && next_state == IDLE) begin
    direction_up <= 1;
end
```

#### 2. Removed Combinational Direction Updates

Removed `direction_up = 1` and `direction_up = 0` assignments from the `next_state` combinational logic in the IDLE, MOVING_UP, and MOVING_DOWN states.

#### 3. Fixed Current Floor Assignment

Changed the floor detection to avoid width mismatch warnings:

```verilog
// Before:
current_floor = i[FLOOR_BITS-1:0];

// After:
current_floor = i;
```

## Verilator Warnings

The following warnings are expected and can be safely ignored:

- **WIDTH warnings**: Bit width mismatches in arithmetic operations (harmless in this design)
- **CASEINCOMPLETE warnings**: Some case states not explicitly covered (handled by default behavior)
- **VARHIDDEN warnings**: Variable `i` declared in multiple scopes (harmless)

## Testbench Features

The C++ testbench (`elevator_verilator_tb.cpp`) includes:

1. **Four test scenarios:**
   - Test 1: Internal request to floor 2
   - Test 2: External up request from floor 1
   - Test 3: External down request from floor 3
   - Test 4: Multiple requests (floor 1 and 3)

2. **Timeout protection:** Each test has a maximum cycle count (100,000 cycles) to prevent infinite loops

3. **Status monitoring:** Prints current floor, motor status, and door status every 10 clock cycles

4. **Floor simulation:** Manually controls `floor_sensors` to simulate elevator movement between floors

## Advantages of Verilator

1. **Fast execution:** Verilator compiles Verilog to optimized C++, making simulations much faster than traditional event-driven simulators

2. **Better debugging:** C++ debugger (gdb) can be used for step-through debugging

3. **Integration:** Easy to integrate with other C/C++ test infrastructure

4. **Performance:** Suitable for large-scale simulations and regression testing

## Limitations

- **No VCD tracing in this version:** The older Verilator 3.922 has issues with VCD tracing in this setup
- **Internal state not accessible:** The `state` signal is internal and not exposed to the C++ testbench
- **No SystemVerilog support:** This version has limited SystemVerilog support

## Comparison with Icarus Verilog

| Feature | Icarus Verilog | Verilator |
|---------|----------------|-----------|
| Speed | Slower (event-driven) | Faster (compiled) |
| Debugging | Limited | Full C++ debugging |
| VCD output | Native | Requires --trace flag |
| SystemVerilog | Limited (-g2005-sv) | Limited |
| Ease of use | Simple | Requires C++ wrapper |

## Future Improvements

1. **Add VCD tracing:** Update to newer Verilator version for better waveform support
2. **Expose internal signals:** Use Verilator directives to make internal state accessible
3. **Add assertions:** Implement Verilator-compatible assertions for verification
4. **Performance optimization:** Use Verilator's optimization flags for faster simulation
5. **Coverage analysis:** Add code coverage support using Verilator's coverage features