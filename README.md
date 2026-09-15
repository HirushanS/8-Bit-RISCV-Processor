# 8-Bit RISC Processor in Verilog

An educational processor project demonstrating instruction decoding, register operations, memory access, and arithmetic using Verilog HDL. The design includes a built-in testbench and waveform generation for simulation-based inspection.

> **Naming note:** Although the repository is named `8-Bit-RISCV-Processor`, the supplied design uses a custom 8-bit instruction set. It is an educational RISC-style processor, not a standard RISC-V implementation.

## Features

- 8-bit datapath and instruction width.
- Eight 8-bit general-purpose registers (`R0`–`R7`).
- Eight 8-bit data-memory locations (`M0`–`M7`).
- Four operations: `LOAD`, `STORE`, `ADD`, and `SUB`.
- 3-bit program counter.
- Positive-edge-triggered execution with an active-high asynchronous reset.
- 8-bit `result` output for observing operation results.
- Built-in simulation testbench with console monitoring and VCD waveform output.
- Optional debug logging using the `DEBUG` macro.

## Repository Contents

| File | Description |
| --- | --- |
| `processor.v` | Processor implementation and the `processor_tb` testbench. |
| `processor.v.out` | Included compiled simulation artifact; regenerate from source before use. |
| `processor.vcd` | Included waveform trace from an earlier simulation. |
| `README.md` | Project documentation and simulation instructions. |

The `.out` and `.vcd` files are generated artifacts and are optional when publishing the source repository.

## Processor Interface

| Signal | Direction | Width | Purpose |
| --- | --- | --- | --- |
| `clk` | Input | 1 bit | Executes an operation on each rising edge while reset is inactive. |
| `rst` | Input | 1 bit | Clears registers, data memory, program counter, and result when asserted. |
| `result` | Output | 8 bits | Exposes the value loaded, stored, or calculated. |

The instruction register is internal. The current testbench writes instructions directly through `uut.instruction`; there is no external instruction input or instruction-fetch memory.

## Instruction Format

Each instruction contains three fields:

| Bits | Field | Meaning |
| --- | --- | --- |
| `[7:6]` | `opcode` | Selects the operation. |
| `[5:3]` | `reg_addr` | Destination register for LOAD/ADD/SUB, or source register for STORE. |
| `[2:0]` | `mem_addr` | Memory address for LOAD/STORE, or source-register index for ADD/SUB. |

### Supported Instructions

Here, `Rd` is selected by `[5:3]`, while `a` or `Rs` is selected by `[2:0]`.

| Opcode | Operation | Behavior | Example encoding |
| --- | --- | --- | --- |
| `00` | `LOAD Rd, [a]` | `Rd ← memory[a]` | `00_000_001`: load M1 into R0. |
| `01` | `STORE Rd, [a]` | `memory[a] ← Rd` | `01_010_011`: store R2 into M3. |
| `10` | `ADD Rd, Rs` | `Rd ← Rd + Rs` | `10_010_001`: add R1 to R2. |
| `11` | `SUB Rd, Rs` | `Rd ← Rd - Rs` | `11_011_001`: subtract R1 from R3. |

Arithmetic results retain the lower eight bits, giving modulo-256 behavior. No carry, borrow, or overflow flags are implemented.

## How It Works

1. Reset clears the register file, data memory, program counter, and result output.
2. The testbench initializes selected memory locations and assigns an instruction.
3. Combinational field assignments decode the instruction.
4. On the next rising clock edge, the processor executes the selected operation and updates `result`.
5. The program counter increments and wraps after seven because it is three bits wide.

The program counter is currently a counter only: it does not select or fetch instructions. An instruction remains active until the testbench changes it, so holding an arithmetic instruction across multiple clock edges repeats that operation.

## Running the Simulation

Use Icarus Verilog (`iverilog` and `vvp`) to compile and run the testbench. GTKWave is optional for viewing waveforms.

From the directory containing `processor.v`:

```bash
iverilog -g2012 -s processor_tb -o processor.v.out processor.v
vvp processor.v.out
```

The testbench prints result changes and register/memory values, and writes `processor.vcd` in the current directory.

To view the waveform:

```bash
gtkwave processor.vcd
```

Useful signals include `clk`, `rst`, `result`, `uut.instruction`, `uut.opcode`, and `uut.pc`.

### Optional Debug Output

```bash
iverilog -g2012 -DDEBUG -s processor_tb -o processor.v.out processor.v
vvp processor.v.out
```

Debug mode prints the instruction, decoded fields, and result at rising clock edges. Because the debug block uses `$display` while processor updates use nonblocking assignments, the displayed result can reflect the value before that edge's update.

## Included Test Sequence

After reset, the testbench initializes M1 to `0x5A` and M2 to `0x3C`.

| Step | Instruction | Expected effect |
| --- | --- | --- |
| 1 | `LOAD R0, [1]` | R0 becomes `0x5A`. |
| 2 | `LOAD R1, [2]` | R1 becomes `0x3C`. |
| 3 | `ADD R2, R0` | R2 becomes `0x5A`. |
| 4 | `ADD R2, R1` | R2 becomes `0x96`. |
| 5 | `STORE R2, [3]` | M3 becomes `0x96`. |
| 6 | `SUB R3, R1` | R3 becomes `0xC4`, because `0x00 - 0x3C` wraps to eight bits. |

At the testbench's final register/memory printout, the expected values are:

| Index | Register value | Memory value |
| --- | --- | --- |
| 0 | `0x5A` | `0x00` |
| 1 | `0x3C` | `0x5A` |
| 2 | `0x96` | `0x3C` |
| 3 | `0xC4` | `0x96` |
| 4–7 | `0x00` | `0x00` |

**Testbench details:**

- The comment describing the subtraction as “R0 minus R1, stored in R3” does not match the implemented instruction. The actual operation is `R3 = R3 - R1`.
- After printing the state, the testbench waits another ten time units before finishing. The subtraction executes again during that interval, changing R3 and `result` to `0x88`. This also appears in the included waveform.
- The source has no explicit `timescale` directive. Its clock period is ten simulation time units; the comment calling these nanoseconds is not enforced. Add a suitable directive, such as `` `timescale 1ns/1ps ``, if nanosecond timing is intended.
- The testbench monitors and prints values but does not contain automated pass/fail assertions.

These expected results are derived from the source, with result transitions cross-checked against the supplied VCD trace. No fresh simulation run is claimed by this documentation.

## Current Scope and Possible Extensions

The supplied project focuses on basic execution and simulation. It does not yet include instruction fetching, branches, jumps, an assembler, or a hardware deployment flow.

Possible extensions include:

- Adding instruction memory and connecting it to the program counter.
- Providing a defined instruction-loading interface.
- Adding immediate, logical, shift, and branch instructions.
- Introducing status flags and a halt mechanism.
- Separating the processor and testbench into individual files.
- Adding self-checking tests for reset, every instruction, arithmetic wraparound, and repeated execution.
- Preparing synthesis constraints and an FPGA-specific top-level module.

## Learning Outcomes

This project demonstrates HDL-based sequential logic, instruction encoding and decoding, register-file and memory operations, fixed-width arithmetic, and waveform-based debugging.
