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
1. **Week 1–2 - Module bring-up (single-cycle path):**
  Build Flip-flops, IMEM/DMEM, ALU, adder, muxes, controller, immediate-extend; Write testbenches for unit modules; Unit tests pass; Single-cycle top runs a test program.
2. **Week 3 - Pipeline cut:**
  Refactor to 5 stages; add IF/ID, ID/EX, EX/MEM, MEM/WB registers. Core runs without hazard handling.
3. **Week 4 - Hazards & tests:**
  Implement forwarding and load-use stall; add directed tests for fwdA/fwdB, stall/flush behavior. 
4. **Week 5 - Stabilization:**
  Debug control/branch timing; eliminate race in branch decision.
5. **Week 6 - FPGA bring-up:**
  Basys3 constraints, clocking (clk_wiz), LED debug wiring; bitstream boots and shows expected LED activity.
6. **Week 7 - Documentation:**
  Write README, block diagrams, timing/utilization notes; capture waveforms and results. 

---

## Major Challenges & Fixes

### 1) “Ghost instruction” after taken branches

- **Symptom:** The instruction after a taken `beq` still executed (e.g., `addi x5,0` clobbered `x5=11`).
- **Cause:**  
  - **Flush wasn’t armed**: `IF/ID` wasn’t flushed on a PC redirect.  
  - **X-masking bug:** I incorrectly gated the flush with  
    ```systemverilog
    // BAD: treats unknown as not-taken and can race
    wire take_branch = (PCSrcE === 1'b1);
    ```  
    During the brief X-propagation window, `PCSrcE` was `X`, so `take_branch` evaluated to `0` and the stale instruction slipped through.
- **Fix:**  
  - Compute branch/jump decision as a pure combinational **wire** (no `===`):  
    ```systemverilog
    logic  take_branch;
    assign take_branch = (PCSrcE === 1'b1);
    ```  
  - Flush on redirect and bubble EX when needed:  
    ```systemverilog
    assign FlushD = take_branch;
    assign FlushE = take_branch | lwStall;
    ```  
  - Ensure the ID/EX register inserts a NOP on `FlushE`.
- **Proof:** Regfile logs show no spurious writeback; final architectural state matches the golden result.


### 2) Forwarding correctness vs. load-use stalls

**Symptom:** Wrong operand **B** for `add x7, x4, x5` when the preceding instruction overwrote `x5`.  
**Cause:** Branch flush timing allowed an `addi x5, x0, 0` to survive one stage; forwarding alone couldn’t fix the logic hazard.  
**Fix:** Corrected flush timing; verified forwarding priority **MEM > WB**; added `lwStall` bubble:

```systemverilog
assign lwStall = (ResultSrcE_b0 === 1'b1) && (RdE != 5'd0) && ((Rs1D == RdE) || (Rs2D == RdE));
```

---

## Debug Techniques That Helped

- **Stage-scoped prints:** One-line “EX/MEM/WB snapshot” per cycle — especially `ForwardA/ForwardB` selects and `RS2_fwd`.
- **PC/flush tracing:** Log `PCF`, `instrD.pc`, `PCTargetE`, and `PCSrcE` together to see redirects and squashes.
- **X hygiene:** Reset pipeline regs to known values (NOP).
- **Small directed programs:** A ~20-instruction test that touches every hazard path.
- **LED latch (FPGA):** Latch `{ALUResultM[7:0], WriteDataM[7:0]}` on writes to avoid flicker and make stores human-readable.

---

## What I Learned

### Microarchitecture
- **Forwarding** fixes many hazards, but **not** load-use — you need to **stall**.
- **X-safety is a feature:** initialize everything.

### Verification
- **Directed tests** are cheap and effective — one per hazard is gold.
- Make the TB **self-identifying:** prints that read like a pipeline trace.
  
### Tooling / Project Hygiene
- Gate sim-only code (`$display`, assertions) behind a single **`SIM` macro**.
- Ensure headers (`config.svh`) are in **both** filesets.
- Keep constraints readable; **name top-level ports** to match the XDC.
- Good docs pay off — a clear **README** shortens future bring-up time.

---

## What I’d Do Differently Next Time

- Build a tiny **scoreboard** or **golden-signature** check for the test program.
- **Script** Vivado builds (Tcl) and add **CI** to run smoke simulations on commits.
---

## Outcome & Next Steps

- **Outcome:** RV32I 5-stage pipeline running on **Basys3 @ 50 MHz**, hazards handled (forwarding + load-use stall + branch/jump flush), and store activity visible on LEDs. Reproducible FPGA build via `scripts/build_fpga.tcl`.
- **Next:** Close **100 MHz** timing (move IMEM/DMEM to BRAM/XPM, analyze EX→MEM critical path), expand ISA **(BNE/BGE/BLT, shifts, LUI/AUIPC)**, add 7-seg display for `{addr,data}`, publish coverage numbers, and stage follow-ons (minimal M-mode CSRs + trap handler, optional cache/AXI-Lite/Wishbone prep).

---

## Thanks

- Folks who publish open **RV32I** references and **Basys3 XDCs**.
- Everyone who documents the “**sim ≠ FPGA**” memory-timing gotchas.
- **Future me**, for writing this down.



