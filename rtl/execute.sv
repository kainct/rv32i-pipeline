`timescale 1ns/1ps

module execute #(
    parameter int XLEN = riscv_pkg::XLEN
    )(
    input  logic             clk,
    input  logic             rst,
    input  logic             FlushE,            // bubble ID/EX on control hazard

    // -------- control from Decode (D) --------
    input  logic             RegWriteD,
    input  logic             MemWriteD,
    input  logic             JumpD,
    input  logic             BranchD,
    input  logic [1:0]       ResultSrcD,
    input  logic [2:0]       ALUControlD,
    input  logic             ALUSrcD,

    // -------- data from Decode (D) --------
    input  logic [XLEN-1:0]  RD1D,
    input  logic [XLEN-1:0]  RD2D,
    input  logic [XLEN-1:0]  PCD,
    input  logic [XLEN-1:0]  PCPlus4D,
    input  logic [XLEN-1:0]  ExtImmD,
    input  logic [4:0]       Rs1D, Rs2D, RdD,

    // -------- forwarding sources + selects --------
    input  logic [XLEN-1:0]  ResultW,          // from WB
    input  logic [XLEN-1:0]  ALUResultM,       // from MEM
    input  logic [1:0]       ForwardAE,        // 00=RD1E, 01=ResultW, 10=ALUResultM
    input  logic [1:0]       ForwardBE,        // 00=RD2E, 01=ResultW, 10=ALUResultM

    // -------- branch/jump back to IF --------
    output logic             PCSrcE,
    output logic [XLEN-1:0]  PCTargetE,

    // -------- to MEM stage --------
    output logic             RegWriteE,
    output logic             MemWriteE,
    output logic [1:0]       ResultSrcE,
    output logic [4:0]       RdE,
    output logic [4:0]       Rs1E,
    output logic [4:0]       Rs2E,
    output logic [XLEN-1:0]  ALUResultE,
    output logic [XLEN-1:0]  WriteDataE,       // forwarded RS2 (for stores)
    output logic [XLEN-1:0]  PCPlus4E
    );
    import riscv_pkg::*;

    // ---------------- Pack D-stage bundles to feed ID/EX ----------------
    ctrl_s ctrl_d;
    data_s data_d;

    // Control (cast ALUControl to enum for the bundle)
    always_comb begin
        ctrl_d.RegWrite   = RegWriteD;
        ctrl_d.ResultSrc  = ResultSrcD;
        ctrl_d.MemWrite   = MemWriteD;
        ctrl_d.Jump       = JumpD;
        ctrl_d.Branch     = BranchD;
        ctrl_d.ALUSrc     = ALUSrcD;
        ctrl_d.ALUControl = alu_op_e'(ALUControlD); // bits -> enum
        // ImmSrc unused in EX; assign a legal value
        ctrl_d.ImmSrc     = IMM_I;
    end

    // Datapath
    always_comb begin
        data_d.RD1     = RD1D;
        data_d.RD2     = RD2D;
        data_d.PC      = PCD;
        data_d.PCPlus4 = PCPlus4D;
        data_d.ExtImm  = ExtImmD;
        data_d.Rs1     = Rs1D;
        data_d.Rs2     = Rs2D;
        data_d.Rd      = RdD;
    end

    // ---------------- ID/EX pipeline register ----------------
    ctrl_s ctrl_e;
    data_s data_e;

    id_ex_reg #(.XLEN(XLEN)) u_idex (
        .clk   (clk),
        .rst   (rst),
        .StallE(1'b0),         // no stall yet
        .FlushE(FlushE),       // bubble on control hazard
        .ctrl_d(ctrl_d),
        .data_d(data_d),
        .ctrl_e(ctrl_e),
        .data_e(data_e)
    );

    // ---------------- Forwarding muxes ----------------
    logic [XLEN-1:0] SrcAE;
    logic [XLEN-1:0] RS2_fwd;

    // A-path (operand A): RD1E vs WB vs MEM
    mux3 #(.W(XLEN)) u_fwd_a (
        .d0 (data_e.RD1),
        .d1 (ResultW),
        .d2 (ALUResultM),
        .s  (ForwardAE),
        .y  (SrcAE)
    );

    // B-path (before ALUSrc): RD2E vs WB vs MEM
    mux3 #(.W(XLEN)) u_fwd_b (
        .d0 (data_e.RD2),
        .d1 (ResultW),
        .d2 (ALUResultM),
        .s  (ForwardBE),
        .y  (RS2_fwd)
    );

    // This is the value that goes to data memory on stores
    assign WriteDataE = RS2_fwd;

    // ALUSrc selection: forwarded RS2 vs immediate
    logic [XLEN-1:0] SrcBE;
    mux2 #(.W(XLEN)) u_b_sel (
        .d0 (RS2_fwd),
        .d1 (data_e.ExtImm),
        .s  (ctrl_e.ALUSrc),
        .y  (SrcBE)
    );

    // ---------------- ALU ----------------
    logic ZeroE;
    alu u_alu (
        .a   (SrcAE),
        .b   (SrcBE),
        .op  (ctrl_e.ALUControl),
        .y   (ALUResultE),
        .zero(ZeroE)
    );

    // ---------------- Branch / Jump target + decision ----------------
    // Use your adder module for target = PC + imm
    adder #(.W(XLEN)) u_target_addr (
        .a (data_e.PC),
        .b (data_e.ExtImm),
        .y (PCTargetE)
    );

    // Beq only for now: take when Branch && Zero, or Jump
    // X-safe: only true when both are known '1'
    logic branch_taken = (ctrl_e.Branch === 1'b1) && (ZeroE === 1'b1);
    logic jump_taken   = (ctrl_e.Jump   === 1'b1);
    assign PCSrcE      = branch_taken || jump_taken;

    // ---------------- Pass-through to MEM ----------------
    assign RegWriteE = ctrl_e.RegWrite;
    assign MemWriteE = ctrl_e.MemWrite;
    assign ResultSrcE= ctrl_e.ResultSrc;
    assign RdE       = data_e.Rd;
    assign Rs1E      = data_e.Rs1;
    assign Rs2E      = data_e.Rs2;
    assign PCPlus4E  = data_e.PCPlus4;

endmodule

