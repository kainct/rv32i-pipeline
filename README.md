# RV32I 5-Stage Pipelined Core (Basys3)

> A clean RV32I 5-stage pipeline (**IF/ID/EX/MEM/WB**) with data forwarding, load-use stall, and branch/jump flush. Runs in sim and on the **Basys3** FPGA. Includes LED debug of stores.

![demo](docs/img/demo.gif) <!-- TODO: replace or remove -->

---

## Highlights

- ISA: **RV32I subset** (addi/andi/ori, add/sub/and/or/slt, beq, jal, lw, sw)
- Hazards: 3-way forwarding, load-use stall, branch/jump flush
- X-safety: pipeline registers reset to NOP; control bundles defaulted
- FPGA: Basys3 @ **50 MHz** (timing met), **100 MHz** WIP
- Debug: `$display` gated behind ``ifdef SIM``; LEDs show `{addr,data}` on stores

---

## Table of Contents

- [Architecture](#architecture)
- [Repo Layout](#repo-layout)
- [Quick Start](#quick-start)
- [Simulation](#simulation)
- [FPGA (Basys3)](#fpga-basys3)
- [Verification](#verification)
- [Results](#results)
- [Design Notes](#design-notes)
- [Troubleshooting](#troubleshooting)
- [License](#license)
- [Credits](#credits)

---

## Architecture

**Pipeline:** IF → ID → EX → MEM → WB

- **Data hazards:** Forward A/B from MEM/WB; load-use stall inserts bubble in ID/EX  
- **Control hazards:** `PCSrcE` determined in EX; **FlushD** (IF/ID) and **FlushE** on taken branch/jump  
- **Memory model:** synchronous BRAM-style for FPGA parity

