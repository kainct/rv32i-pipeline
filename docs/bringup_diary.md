# Reflection: Building a RV32I 5-Stage Pipelined Core (Basys3)

> Notes on the journey — design choices, bugs, fixes, and lessons learned — while taking an RV32I core from simulation to FPGA.

---

## Why I Built This
I wanted a hands-on understanding of CPU microarchitecture beyond lectures:
- Implement a classic 5-stage pipeline (IF/ID/EX/MEM/WB).
- Handle real hazards (forwarding, load-use stall, branch/jump flush).
- Match simulation behavior on real hardware (Basys3).
- Practice verification discipline and debug hygiene.

---

## What I Shipped
- **ISA subset:** RV32I core ops — add/sub/and/or/slt (+ immediates), beq, jal, lw/sw.
- **Pipeline:** 5 stages with IF/ID, ID/EX, EX/MEM, MEM/WB regs.
- **Hazards:** 3-way forwarding (MEM > WB), load-use stall bubble, branch/jump flush.
- **X-safety:** IF/ID seeded with NOP; control bundles defaulted.
- **FPGA:** Runs on Basys3 @ 50 MHz; 100 MHz timing work in progress.
- **Observability:** `$display` under `SIM`; LEDs show `{addr,data}` on stores in MEM.

---

## Timeline (High Level)
1. **Week 1–2:** ALU + register file + single-cycle skeleton; basic tests.
2. **Week 3:** 5-stage split, immediate decode, pipeline regs, WB path.
3. **Week 4:** Hazard unit — forwarding, load-use detection; directed hazard tests.
4. **Week 5:** Control hazards (beq/jal), PCSrcE, flush mechanics; X-safety cleanup.
5. **Week 6:** FPGA bring-up — constraints, BRAM inference, LED debug.
6. **Week 7+:** Fix race in branch decision; stabilize simulation defines/filesets; README/docs.

---

## Major Challenges & Fixes

### 1) “Ghost instruction” after taken branches
- **Symptom:** Next instruction after a taken `beq` still executed (e.g., `addi x5,0` clobbered `x5=11`).
- **Cause:** IF/ID not flushed on `PCSrcE` → stale instruction slipped through.
- **Fix:** `FlushD = PCSrcE; FlushE = PCSrcE | lwStall;` ensure bubble in ID/EX when redirecting PC.
- **Proof:** RF logs show no spurious writeback; final state matches golden.

### 2) PCSrcE race due to X-propagation
- **Symptom:** Pass/fail depended on how PCSrcE was computed; `===` comparisons caused timing dependency.
- **Cause:** Used `=== 1'b1` inside mixed comb logic; uninitialized signals temporarily X.
- **Fix:** Move to **continuous wires**:
  ```systemverilog
  assign PCSrcE = (ctrl_e.Branch & ZeroE) | ctrl_e.Jump; ```
  or precompute `branch_taken`, `jump_taken` on wires and OR them.
- **Proof:** Stable behavior across runs; no X-driven flushes.

### 3) Forwarding correctness vs. load-use stalls

**Symptom:** Wrong operand **B** for `add x7, x4, x5` when the preceding instruction overwrote `x5`.  
**Cause:** Branch flush timing allowed an `addi x5, 0` to survive one stage; forwarding alone couldn’t fix the logic hazard.  
**Fix:** Corrected flush timing; verified forwarding priority **MEM > WB**; added `lwStall` bubble:

```systemverilog
lwStall = load_in_EX && (RdE != 5'd0) && ((RdE == Rs1D) || (RdE == Rs2D));
```

### 4) Simulation ≠ FPGA (memory timing)

**Symptom:** Store→load sequences behaved differently on board vs. sim.  
**Cause:** Sim model used **asynchronous** reads; FPGA BRAM is **synchronous**.  
**Fix:** Switched IMEM/DMEM to **synchronous** models to match BRAM behavior.

### 5) Tooling friction: `ifdef` and filesets

**Symptom:** `$display` either missing in sim or leaked into synth; sometimes `SIM` macro ignored.  
**Cause:** `config.svh` not included in **both** *Simulation* and *Synthesis* filesets.  
**Fix:** Central header:

```systemverilog
`ifndef SYNTHESIS
  `define SIM
`endif
```
...add this header to both filesets in Vivado. Wrap prints:
```systemverilog
`ifndef SYNTHESIS
  `define SIM
`endif
```

---

## Debug Techniques That Helped

- **Stage-scoped prints:** One-line “EX/MEM/WB snapshot” per cycle — especially `ForwardA/ForwardB` selects and `RS2_fwd`.
- **PC/flush tracing:** Log `PCF`, `instrD.pc`, `PCTargetE`, and `PCSrcE` together to see redirects and squashes.
- **X hygiene:** Reset pipeline regs to known values (NOP); avoid `===` in timing-critical combinational logic.
- **Small directed programs:** A ~20-instruction test that touches every hazard path.
- **LED latch (FPGA):** Latch `{ALUResultM[7:0], WriteDataM[7:0]}` on writes to avoid flicker and make stores human-readable.

---

## What I Learned

### Microarchitecture
- **Forwarding** fixes many hazards, but **not** load-use — you need a **bubble**.
- **Branching** has two parts: decision timing **and** the mechanics of squashing.
- **X-safety is a feature:** initialize everything; prefer **wires** for critical decisions.

### Verification
- **Directed tests** are cheap and effective — one per hazard is gold.
- Make the TB **self-identifying:** prints that read like a pipeline trace.
- Keep sim models **realistic** (synchronous memories) to avoid board surprises.

### Tooling / Project Hygiene
- Gate sim-only code (`$display`, assertions) behind a single **`SIM` macro**.
- Ensure headers (`config.svh`) are in **both** filesets — Vivado doesn’t guess.
- Keep constraints readable; **name top-level ports** to match the XDC.
- Good docs pay off — a clear **README** shortens future bring-up time.

---

## What I’d Do Differently Next Time

- Add **assertions early** (x0 write-protect, one-hot control, valid opcodes).
- Build a tiny **scoreboard** or **golden-signature** check for the test program.
- **Script** Vivado builds (Tcl) and add **CI** to run smoke simulations on commits.
- Consider a simple **prefetch buffer** to hide IMEM latency and improve CPI.

---

## Outcome & Next Steps

- **Outcome:** RV32I 5-stage pipeline running on **Basys3 @ 50 MHz**, correct hazard handling, and visible store activity on LEDs.  
- **Next:** Close **100 MHz** timing (analyze EX/MEM critical paths), expand ISA (bne, shifts), add **7-seg** display for `{addr,data}`, and publish **coverage numbers**.

---

## Selected Snippets (for future me)

**PC redirect (X-safe):**
```systemverilog
assign PCSrcE = (ctrl_e.Branch & ZeroE) | ctrl_e.Jump;
```
**PC redirect (X-safe):**
```systemverilog
assign lwStall = ResultSrcE_b0
              && (RdE != 5'd0)
              && ((RdE == Rs1D) || (RdE == Rs2D));
```
**Forwarding priority:**
```systemverilog
// prefer MEM (10) over WB (01)
```
**IF/ID reset to NOP:**
```systemverilog
localparam logic [31:0] INSTR_NOP = 32'h0000_0013; // ADDI x0,x0,0
```

---

## Thanks

- Folks who publish open **RV32I** references and **Basys3 XDCs**.
- Everyone who documents the “**sim ≠ FPGA**” memory-timing gotchas.
- **Future me**, for writing this down.



