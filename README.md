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

## Architecture
- **Structure:** 5 stages — IF/ID/EX/MEM/WB with IF/ID, ID/EX, EX/MEM, MEM/WB regs
- **Control path:** `PCSrcE = (Branch & Zero) | Jump` (continuous assign to avoid X timing)
- **Immediate/types:** I/S/B/J via `ImmSrc`, sign-extended in Decode
- **ALU ops:** add, sub, and, or, slt (+ immediate forms via alu_dec)
- **Forwarding:** Priority MEM > WB on both A/B paths (mux3 with selects `10/01/00`)
- **Stall/flush:** `lwStall` inserts bubble; `FlushD = PCSrcE`; `FlushE = PCSrcE | lwStall`
- **Instruction memory:** Combinational ROM (LUT-based) with optional `$readmemh` preload via `MEMFILE` parameter; defaults to a small hard-coded program for bring-up
- **Data memory:** **Synchronous, currently inferred as LUTRAM** (64 words) for small depth; BRAM-ready (switch to `(* ram_style="block" *)` and keep **registered read** when scaling)
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
│  ├─ riscv_pkg.sv                     # RISC-V constants + decode/ALU enums + control/pipe bundle typedefs 
│  ├─ include
│  │  └─ config.svh                    # `define SIM` for sim-only prints
│  └─ fpga_top.sv                      # LEDs wrapper for Basys3
├─ sim/
│  ├─ tb_top.sv                        # testbench
│  ├─ final.hex                        # program image
│  ├─ *.sv                             # testbenches for modules                     
│  └─ waves/                           # .wcfg /.vcd dumps
├─ fpga/
│  ├─ basys3.xdc                       # pin constraints
│  ├─ ip/
│  │  └─ clk_wiz_0/clk_wiz_0.xci       # Clocking Wizard (100 MHz → 50 MHz)
│  ├─ bitstreams/                      # exported .bit files
│  └─ mem/                             # BRAM inits for FPGA (optional)
└─ scripts/
   ├─ build_sim.tcl                    # optional Vivado sim script
   └─ build_fpga.tcl                   # optional Vivado synth/impl script

```

---

## Getting Started
- **Tools:** Vivado 2022.1; Basys3 (XC7A35T)
- **Clone:** `git clone https://github.com/kainct/rv32i-pipeline && cd rv32i-pipeline`
- **Filesets (add to project):**
  - RTL: `rtl/*.sv`, `rtl/include/config.svh`, `rtl/fpga_top.sv`
  - Constraints: `fpga/basys3.xdc`
  - **IP:** `fpga/ip/clk_wiz_0/clk_wiz_0.xci` (Clocking Wizard 100 MHz → 50 MHz)
- **Program image:** `sim/final.hex`
- **Defines:** in `config.svh`
  ```systemverilog
  `ifndef SYNTHESIS
    `define SIM
  `endif
    ```
- **Build (sim):** Vivado GUI → Flow Navigator → Simulation
- **Build (fpga):** Vivado GUI → Flow Navigator → Synthesis → Implementation → Bitstream → Program device

---

## Simulation
- **Entry:** `sim/tb_top.sv` (instantiates `top`, clock/reset, connects IMEM/DMEM)
- **Clock/Reset:** `CLK_PERIOD = 20 ns` (50 MHz). Reset asserted ~22 ns then de-asserted.
- **Program load:** IMEM is a LUT-ROM with `$readmemh` via the `MEMFILE` parameter. If empty, a small hard-coded bring-up program runs.
- **Stop rule:** Testbench watches for a terminating store (e.g., `mem[0x00000064] = 32'd25`) → `$finish`; otherwise `$fatal("TIMEOUT")`.
- **Checks & Asserts:** x0 write-protect; no **X** after reset on `PCSrcE`, `FlushD`, `FlushE`, `MemWriteM`; control encoding sanity.
- **Debug:** `$display` traces for IF/ID/EX/MEM/WB and hazard unit under ``SIM``.
- **Waveforms:** VCD via `$dumpfile/$dumpvars` or XSim `.wcfg` focused on forwarding, stalls, and flushes.

---

## FPGA (Basys3)
- **Top wrapper:** `rtl/fpga_top.sv`  
  Ports: `CLK100MHZ` (W5), `rst_BTN` (U18), `LED[15:0]` (U16…L1).
- **Clocking:** `clk_wiz_0` generates **50 MHz** from the board 100 MHz.  
  *Tip:* In Vivado, **Generate Output Products** for the IP and add `fpga/ip/clk_wiz_0/clk_wiz_0.xci` to the project (and repo).
- **LEDs:** `{LED[15:8], LED[7:0]} = {ALUResultM[7:0], WriteDataM[7:0]}`; `LED[15] |= MemWriteM` (blink on store).
- **IMEM:** LUT-ROM (async) for bring-up. For higher Fmax or bigger images, switch to **BRAM/XPM** (sync, 1-cycle latency).
- **DMEM:** **LUTRAM (64 words)** with **registered read**. To force BRAM later, increase depth and/or add `(* ram_style="block" *)`.
- **Timing @50 MHz:** Met comfortably (see Results).  
  **@100 MHz:** Work-in-progress; expect improvement with BRAM IMEM and minor path balancing.

---

## Verification
- **Directed tests:** ALU/immediates, branches (taken/not), `lw/sw`, hazard paths (fwdA/B), load-use stall, branch/jump flush.
- **Assertions:** x0 write-protect; valid control encodings; `FlushD = PCSrcE`; `FlushE = PCSrcE | lwStall`.
- **Retirement:** Instruction “retires” at **WB** when `MEMWB_valid == 1`.
- **CPI:**  
  - **Raw:** `cycles / retired`  
  - **Startup-adjusted:** `(cycles − 4) / retired` (subtract 4-cycle pipe fill)
- **Pass/fail:** All directed tests pass; x0 always 0; no **X** after reset; terminating store observed and value matches.

---

## Results
- **ISA subset:** RV32I (addi, R-type, `beq`, `lw/sw`, `jal`)

**CPI**
- *Hazard-free microbench:* `cycles = 17`, `retired = 13` → **CPI_raw = 1.3077**, **CPI_adj = 1.0000** ✅
- *Mixed program:* `cycles = 25`, `retired = 16` → **CPI_raw = 1.5625**, **CPI_adj = 1.3125**

**Utilization (Basys3, post-synthesis)**
- **Slice LUTs:** **358** (≈ **278 logic + 80 LUTRAM**)
- **Slice Registers:** **261**
- **BRAM:** **0** (IMEM/DMEM are LUT-based at current sizes)
- **DSP:** **0**
- **IOBs:** **17**
- **Clocking:** `clk_wiz_0` present (shows **MMCM/BUFG** once IP output products are generated; otherwise reported as a black box)

**Timing**
- **@50 MHz (20 ns):** Met, **WNS = +11.458 ns** (critical path ≈ **8.542 ns**)
- **Max Fmax (≈ 1 / crit-path):** **~117 MHz**
- **@100 MHz:** WIP (close with BRAM IMEM + minor path cleanup)

**Artifacts**
- Waveforms: `docs/img/*.png`  
- Bitstreams: `fpga/bitstreams/*.bit`

---

## Design Notes
- **Forwarding priority:** MEM > WB on both A/B paths (mux3: `10 / 01 / 00`).
- **Load-use:** Single bubble; stores source RS2 via forwarded `RS2_fwd`.
- **Flush policy:** `FlushD = PCSrcE`; `FlushE = PCSrcE | lwStall`.
- **Reset hygiene:** IF/ID seeded with NOP (`ADDI x0,x0,0`); control bundles defaulted to safe values.
- **Memory inference:** Use synchronous reads for BRAM parity; add `(* ram_style="block" *)` when growing memories.
- **Comb vs procedural:** Prefer `assign` for `PCSrcE`/comparators; avoid `===` races in large `always_comb`.

---

## Debug Diary (highlights)
- **Taken branch executed next instr** → Added `FlushD` on `PCSrcE` (squash IF/ID); verified no ghost WB.
- **Reg clobber after `addi`** → Fixed flush timing; forwarding traces confirm correctness.
- **Sim vs FPGA load timing mismatch** → Switched DMEM read to synchronous; parity restored.

---

## Roadmap
- Close timing at **100 MHz** (BRAM IMEM, reduce fanout, minor placement/retiming).
- ISA growth: `bne`, `lui/auipc`, shifts, zero-extend loads.
- Simple prefetch queue to hide IMEM latency.
- 7-seg HEX for `{addr,data}`; optional UART print.
- CI for sim (lint, unit tests) and coverage export.

---

## Troubleshooting
- **Clock IP is “black box”:** Right-click `clk_wiz_0` → *Generate Output Products* → *Out-of-context per IP*. Ensure `fpga/ip/clk_wiz_0/clk_wiz_0.xci` is added to the project & repo.
- **BRAM not inferred:** Use synchronous read, sufficient depth/width, optional `(* ram_style="block" *)`.
- **LEDs flicker:** Latch outputs; avoid driving LEDs from live busses.
- **Program doesn’t run:** Check `$readmemh` path/format, IMEM depth, reset polarity; scan synth messages for RAM inference.
- **Xs after reset:** Seed IF/ID with NOP; initialize control bundles; avoid `===` in critical comb logic.

---

## License
MIT — see `LICENSE`.

---

## Credits
- **Author:** Kai Nguyen (kainct)  
- **Board:** Digilent Basys3 (XC7A35T)  
- **Spec:** RISC-V RV32I


---



