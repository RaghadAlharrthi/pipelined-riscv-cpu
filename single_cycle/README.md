# Single-Cycle RISC-V (RV32I) CPU

A single-cycle 32-bit RISC-V processor implementing a subset of the RV32I base integer instruction set, written in Verilog and verified through simulation with Icarus Verilog and GTKWave.

This is the first stage of a larger project; a 5-stage pipelined version is being developed on top of this design.

## What it does

The CPU fetches, decodes, executes, and writes back RISC-V instructions in a single clock cycle each. It was verified by running a small test program and checking the final register values against the expected results.

### Example program

    addi x1, x0, 5     # x1 = 5
    addi x2, x0, 7     # x2 = 7
    add  x3, x1, x2    # x3 = x1 + x2 = 12
    addi x4, x3, 1     # x4 = x3 + 1  = 13

### Verified output

    x1 = 5
    x2 = 7
    x3 = 12
    x4 = 13

All results match the expected values.

## Architecture

| Module       | Description                                              |
|--------------|----------------------------------------------------------|
| register.v   | 32-bit register with write-enable and clock-edge update  |
| regfile.v    | 32 x 32-bit register file, 2 read ports, 1 write port    |
| alu.v        | ALU (add, sub, and, or, xor, slt, shifts) with zero flag |
| immgen.v     | Immediate generator with sign extension                  |
| control.v    | Main decoder generating control signals from the opcode  |
| cpu_top.v    | Top-level CPU integrating all modules                    |

### Stages
1. Fetch – Program Counter selects the instruction from instruction memory.
2. Decode – Control unit, register file read, and immediate generation.
3. Execute – ALU computes the result.
4. Writeback – Result is written back into the destination register.

## How to run

Requires Icarus Verilog (and optionally GTKWave for waveforms).

    iverilog -o cpu_sim rtl/cpu_top.v rtl/control.v rtl/regfile.v rtl/immgen.v rtl/alu.v tb/cpu_top_tb.v
    vvp cpu_sim

## Tools
- Verilog (RTL design)
- Icarus Verilog (simulation)
- GTKWave (waveform analysis)

## Status & next steps
- [x] Single-cycle RV32I core (this repo)
- [ ] 5-stage pipeline (IF/ID/EX/MEM/WB)
- [ ] Data forwarding and hazard detection
- [ ] Synthesis with Yosys

## Author
Raghad Faleh Alharthi — Computer Engineering graduate