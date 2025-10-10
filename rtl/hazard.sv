`timescale 1ns/1ps

module hazard (
    // ---- ID stage uses (for load-use detection) ----
    input  logic [4:0] Rs1D,
    input  logic [4:0] Rs2D,

    // ---- EX stage sources/dest (for fwd + load-use) ----
    input  logic [4:0] Rs1E,
    input  logic [4:0] Rs2E,
    input  logic [4:0] RdE,

    // ---- MEM / WB dests (for forwarding) ----
    input  logic [4:0] RdM,
    input  logic [4:0] RdW,

    // ---- control info ----
    input  logic       PCSrcE,          // branch/jump taken flag from EX (may be X early)
    input  logic       ResultSrcE_b0,   // EX stage: ResultSrc[0] == 1 means "use MEM" -> load in EX
    input  logic       RegWriteM,
    input  logic       RegWriteW,

    // ---- pipeline controls ----
    output logic       StallF,
    output logic       StallD,
    output logic       FlushD,
    output logic       FlushE,

    // ---- forwarding selects (to EX) ----
    // 00 = use RDxE
    // 01 = forward from WB (ResultW)
    // 10 = forward from MEM (ALUResultM)
    output logic [1:0] ForwardAE,
    output logic [1:0] ForwardBE
    );

    // ---------------- Forwarding (prefer MEM over WB), X-safe ----------------
    always_comb begin
        ForwardAE = 2'b00;
        ForwardBE = 2'b00;

        // A operand (uses Rs1E)
        if (Rs1E != 5'd0) begin
        if ((RegWriteM === 1'b1) && (RdM != 5'd0) && (Rs1E == RdM))
            ForwardAE = 2'b10;   // from MEM
        else if ((RegWriteW === 1'b1) && (RdW != 5'd0) && (Rs1E == RdW))
            ForwardAE = 2'b01;   // from WB
        end

        // B operand (uses Rs2E)
        if (Rs2E != 5'd0) begin
        if ((RegWriteM === 1'b1) && (RdM != 5'd0) && (Rs2E == RdM))
            ForwardBE = 2'b10;   // from MEM
        else if ((RegWriteW === 1'b1) && (RdW != 5'd0) && (Rs2E == RdW))
            ForwardBE = 2'b01;   // from WB
        end
    end

    // ---------------- Load-use stall (EX is a load; next instr in ID uses its rd) ----------------
    // ResultSrcE_b0 == 1 → EX will take its result from MEM (i.e., lw)
    logic lwStall;
    assign lwStall = (ResultSrcE_b0 === 1'b1) && (RdE != 5'd0) && ((Rs1D == RdE) || (Rs2D == RdE));

    // ---------------- Control hazard flush (branch/jump taken) ----------------
    // Treat unknown PCSrcE as not-taken to avoid spurious flushes during X-propagation.
    logic  take_branch;
    assign take_branch = (PCSrcE === 1'b1);

    // ---------------- Drive pipeline controls ----------------
    assign StallF = lwStall;                  // freeze PC
    assign StallD = lwStall;                  // freeze IF/ID
    assign FlushD = take_branch;              // squash instr in IF/ID on taken branch/jump
    assign FlushE = lwStall || take_branch;   // squash ID/EX on load-use or taken branch/jump

endmodule
