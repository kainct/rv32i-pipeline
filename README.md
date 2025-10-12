# RV32I 5-Stage Pipelined Core (Basys3)

> A clean RV32I 5-stage pipeline (**IF/ID/EX/MEM/WB**) with data forwarding, load-use stall, and branch/jump flush. Runs in sim and on the **Basys3** FPGA. Includes LED debug of stores.

![demo](docs/img/demo.gif) <!-- TODO: replace or remove -->

---

## Highlights
- **ISA:** RV32I subset (addi/andi/ori, add/sub/and/or/slt, beq, jal, lw, sw)
- **Pipeline:** IF → ID → EX → MEM → WB with **FlushD/FlushE**
- **Hazards:** 3-way forwarding, **load-use stall**, **branch/jump flush**
- **X-safety:** Pipeline regs reset to NOP; control bundles defaulted
- **FPGA:** Basys3 @ **50 MHz** timing met; **100 MHz** in progress
- **Debug:** LEDs show `{addr,data}` on store; `$display` under ``ifdef SIM``

---

## Table of Contents

- [Architecture](#architecture)
- [Repo Layout](#repo-layout)
- [Getting Started](#getting-started)
- [Simulation](#simulation)
- [FPGA (Basys3)](#fpga-basys3)
- [Verification](#verification)
- [Results](#results)
- [Design Notes](#design-notes)
- [Debug Diary](#debug-diary)
- [Roadmap](#roadmap)
- [Troubleshooting](#troubleshooting)
- [License](#license)
- [Credits](#credits)

---

## 🧩 Architecture
- **Structure:** 5 stages — IF/ID/EX/MEM/WB with IF/ID, ID/EX, EX/MEM, MEM/WB regs
- **Control path:** `PCSrcE = (Branch & Zero) | Jump` (continuous assign to avoid X timing)
- **Immediate/types:** I/S/B/J via `ImmSrc`, sign-extended in Decode
- **ALU ops:** add, sub, and, or, slt (+ immediate forms via alu_dec)
- **Forwarding:** Priority MEM > WB on both A/B paths (mux3 with selects `10/01/00`)
- **Stall/flush:** `lwStall` inserts bubble; `FlushD = PCSrcE`; `FlushE = PCSrcE | lwStall`
- **Mem model:** Synchronous BRAM-style read/write to match device timing
- **Reset policy:** IF/ID seeded with NOP (`ADDI x0,x0,0`); all control lines zeroed

---

## Repo Layout

```text
rv32i-pipeline/
├─ README.md
├─ LICENSE                             # TODO: add if you choose a license
├─ docs/
│  ├─ design.md                        # micro-arch & interfaces
│  ├─ verification.md                  # TB strategy, coverage, pass/fail
│  ├─ fpga.md                          # board bring-up notes
│  ├─ bringup_diary.md                 # short dated entries
│  └─ postmortem.md                    # what to improve next
├─ rtl/
│  ├─ *.sv                             # core RTL (pkg, decode, execute, hazard, ...)
│  ├─ riscv_pkg.sv
│  ├─ config.svh                       # `define SIM` for sim-only prints
│  └─ fpga_top.sv                      # LEDs wrapper for Basys3
├─ sim/
│  ├─ tb_top.sv                        # testbench
│  ├─ test_programs/
│  │  └─ final.mem                     # program image (change path if needed)
│  └─ waves/                           # .wcfg /.vcd dumps
├─ fpga/
│  ├─ basys3.xdc                       # pin constraints
│  ├─ bitstreams/                      # exported .bit files
│  └─ mem/                             # BRAM inits for FPGA (optional)
└─ scripts/
   ├─ build_sim.tcl                    # optional Vivado sim script
   └─ build_fpga.tcl                   # optional Vivado synth/impl script

```

---

## ⚙️ Getting Started
- **Tools:** Vivado `TODO:version`; Basys3 (XC7A35T); optional Verilator/Questa for sim
- **Clone:** `git clone https://github.com/<you>/rv32i-pipeline && cd rv32i-pipeline`
- **Filesets:** Add `rtl/*.sv`, `rtl/config.svh`, `rtl/fpga_top.sv`, `fpga/basys3.xdc`
- **Program image:** Place at `sim/test_programs/final.mem` (or update IMEM path)
- **Defines:** `config.svh` contains:
  - ```systemverilog
    `ifndef SYNTHESIS
      `define SIM
    `endif
    ```
- **Build (sim):** Run your sim tcl or Vivado GUI → Elaborate → Simulate
- **Build (fpga):** Synthesis → Implementation → Bitstream → Program device

---

## 🧪 Simulation
- **Entry point:** `sim/tb_top.sv` (drives clock/reset, loads `final.mem`)
- **Checks:** Self-checking scoreboard / signature compare `TODO`
- **Waveforms:** Dump `VCD/WCFG` for hazards (forwarding, stalls, flushes)
- **Prints:** Regfile writes, ALUSrc/ForwardA/ForwardB, branch decisions under ``SIM``
- **Pass criteria:** No X after reset; final memory/register signature matches golden
- **Typical run:** `run 1000ns` completes directed program with expected store

---

## 🛠️ FPGA (Basys3)
- **Top wrapper:** `rtl/fpga_top.sv` (ports: `CLK100MHZ`, `rst_BTN`, `LED[15:0]`)
- **LED mapping:** `{LED[15:8], LED[7:0]} = {ALUResultM[7:0], WriteDataM[7:0]}`; `LED[15] |= MemWriteM`
- **Constraints:** `fpga/basys3.xdc` (W5: CLK100MHZ, U18: rst_BTN, LEDs U16…L1)
- **Clocks:** Operates @ **50 MHz**; review critical path to reach **100 MHz**
- **Mem init:** `$readmemh` path valid for synthesis (relative to project dir)
- **Bring-up tips:** Confirm BRAM inference; ensure synchronous IMEM/DMEM; debounce reset if needed

---

## ✅ Verification
- **Directed tests:** ALU/imm, branches (taken/not), lw/sw, hazards (fwdA/B, load-use)
- **Assertions:** x0 write-protect; control encodings; `FlushD/E` on `PCSrcE/lwStall`
- **Coverage (optional):** Line/Toggle/Branch/Functional `TODO:%` via simulator
- **CPI measurement:** Hazard-free loop + mixed microbench; log cycles/instr `TODO`
- **Pass/fail:** All directed tests pass; final store equals expected (e.g., mem[100]=25)

---

## 📊 Results
- **ISA subset:** RV32I core ops listed above
- **CPI (hazard-free):** `TODO` (e.g., 1.00)
- **CPI (mixed):** `TODO` (e.g., 1.15)
- **Resources (Basys3):** LUT `TODO`, FF `TODO`, BRAM `TODO`
- **Timing @50 MHz:** Met; slack `TODO ns`
- **Timing @100 MHz:** `TODO` (met/fail, bottleneck path)
- **Max Fmax:** `TODO MHz`
- **Artifacts:** Waveforms (`docs/img/*.png`), bitstreams (`fpga/bitstreams/*.bit`)

---

## 📝 Design Notes
- **Continuous `PCSrcE`:** Avoid `===` races by computing on wires, not in `always_comb`
- **Forwarding order:** Prefer MEM result to minimize stalls; WB as secondary
- **Load-use bubble:** One-cycle bubble inserted; store uses forwarded `RS2_fwd`
- **Reset to NOP:** Prevents X-propagation into control; simplifies sim/FPGA parity
- **Synchronous memories:** Match BRAM timing; avoid async sim-only reads
- **SIM guards:** Keep `$display/$strobe` under ``ifdef SIM``; include `config.svh` in both sim & synth filesets

---

## 🐞 Debug Diary
- **Taken branch executes next instr**
  - **Cause:** Missing `FlushD` on `PCSrcE`
  - **Fix:** `FlushD = PCSrcE`; squash IF/ID; insert bubble in ID/EX as needed
  - **Proof:** Branch tests pass; no ghost writebacks
- **Wrong value after `add x7,x4,x5`**
  - **Cause:** `addi x5,0` not flushed; overwrote `x5=11` → `0`
  - **Fix:** Correct flush timing; verify with forwarding traces
  - **Proof:** RF logs show `x5=11` preserved; final result correct
- **X-propagation toggles `PCSrcE`**
  - **Cause:** `===` use inside comb logic with uninitialized signals
  - **Fix:** Continuous assigns / precomputed wires; reset pipeline regs
  - **Proof:** Stable sim/FPGA behavior
- **Store→load mismatch on board**
  - **Cause:** Async dmem in sim vs sync BRAM on FPGA
  - **Fix:** Use synchronous read model
  - **Proof:** Store/load tests now identical

---

## 🧭 Roadmap
- **100 MHz close:** Balance EX/MEM paths; consider ALU cut or tighter placement
- **ISA growth:** bne, lui/auipc, shifts, zero-extend loads
- **Instr prefetch:** Simple queue to hide IMEM latency
- **7-seg display:** Hex address/data for stores; activity indicator
- **Automation:** CI for sim (lint, unit tests); coverage reports export

---

## 🧩 Troubleshooting
- **Param override error (`WIDTH`):** Ensure `top` defines `parameter int WIDTH=32` or remove override
- **`config.svh` ignored:** Add to both Simulation and Synthesis sets; check “Used in” column
- **LEDs flicker:** Latch `{addr,data}` on clock; don’t drive LEDs directly from live bus
- **Program not running:** Verify `$readmemh` path and IMEM depth; check reset polarity; inspect BRAM inference msgs
- **X in waves:** Ensure IF/ID = NOP on reset; initialize control bundles; avoid `===` in critical comb logic

---

## 📄 License
- **Type:** MIT (or choose another)  
- **Files:** See `LICENSE`

---

## 🤝 Credits
- **Author:** `TODO: your name / handle`
- **Board:** Digilent Basys3 (XC7A35T)
- **Spec:** RISC-V RV32I
- **Thanks:** `TODO: mentors/reviewers/tools`

---



