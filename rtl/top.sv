`timescale 1ns/1ps

module top #(
    parameter int XLEN = riscv_pkg::XLEN
    )(
    input  logic             clk,
    input  logic             rst,

    // Visible to testbench
    output logic [XLEN-1:0]  WriteDataM,   // data to store
    output logic [XLEN-1:0]  ALUResultM,   // data memory address (byte)
    output logic             MemWriteM     // data memory write enable
    );
    import riscv_pkg::*;

    // -------- IF <-> ID --------
    logic        StallF, StallD, FlushD, FlushE;
    logic        PCSrcE;
    logic [XLEN-1:0] PCTargetE;

    logic [31:0]     InstrF;
    logic [XLEN-1:0] PCF, PCPlus4F;

    // -------- ID → EX --------
    logic                 RegWriteD, MemWriteD, JumpD, BranchD, ALUSrcD;
    logic [1:0]           ResultSrcD;
    alu_op_e              ALUControlD;
    logic [XLEN-1:0]      RD1D, RD2D, PCD, ExtImmD, PCPlus4D;
    logic [4:0]           Rs1D, Rs2D, RdD;

    // -------- EX → MEM --------
    logic                 RegWriteE, MemWriteE;
    logic [1:0]           ResultSrcE;
    logic [XLEN-1:0]      ALUResultE, WriteDataE, PCPlus4E;
    logic [4:0]           RdE, Rs1E, Rs2E;

    // -------- MEM → WB --------
    logic                 RegWriteM_int;
    logic [1:0]           ResultSrcM;
    logic [XLEN-1:0]      ReadDataM, PCPlus4M;
    logic [4:0]           RdM;

    // -------- WB loopback --------
    logic                 RegWriteW;
    logic [XLEN-1:0]      ResultW;
    logic [4:0]           RdW;

    // -------- forwarding selects --------
    logic [1:0]           ForwardAE, ForwardBE;

    // ================= IF =================
    fetch #(.XLEN(XLEN)) u_fetch (
        .clk       (clk),
        .rst       (rst),
        .PCSrcE    (PCSrcE),
        .StallF    (StallF),
        .PCTargetE (PCTargetE),
        .InstrF    (InstrF),
        .PCF       (PCF),
        .PCPlus4F  (PCPlus4F)
    );

    // ================= ID =================
    decode #(.XLEN(XLEN)) u_decode (
        .clk         (clk),
        .rst         (rst),
        .StallD      (StallD),
        .FlushD      (FlushD),
        // from IF
        .InstrF      (InstrF),
        .PCF         (PCF),
        .PCPlus4F    (PCPlus4F),
        // WB into regfile
        .RegWriteW   (RegWriteW),
        .RdW         (RdW),
        .ResultW     (ResultW),
        // control out
        .RegWriteD   (RegWriteD),
        .MemWriteD   (MemWriteD),
        .ResultSrcD  (ResultSrcD),
        .JumpD       (JumpD),
        .BranchD     (BranchD),
        .ALUControlD (ALUControlD),
        .ALUSrcD     (ALUSrcD),
        // datapath out
        .RD1D        (RD1D),
        .RD2D        (RD2D),
        .PCD         (PCD),
        .Rs1D        (Rs1D),
        .Rs2D        (Rs2D),
        .RdD         (RdD),
        .ExtImmD     (ExtImmD),
        .PCPlus4D    (PCPlus4D)
    );

    // ================= EX =================
    execute #(.XLEN(XLEN)) u_execute (
        .clk         (clk),
        .rst         (rst),
        .FlushE      (FlushE),

        // control (D)
        .RegWriteD   (RegWriteD),
        .MemWriteD   (MemWriteD),
        .JumpD       (JumpD),
        .BranchD     (BranchD),
        .ResultSrcD  (ResultSrcD),
        .ALUControlD (alu_op_e'(ALUControlD)), // benign cast if already enum
        .ALUSrcD     (ALUSrcD),

        // data (D)
        .RD1D        (RD1D),
        .RD2D        (RD2D),
        .PCD         (PCD),
        .PCPlus4D    (PCPlus4D),
        .ExtImmD     (ExtImmD),
        .Rs1D        (Rs1D),
        .Rs2D        (Rs2D),
        .RdD         (RdD),

        // forwarding sources + selects
        .ResultW     (ResultW),
        .ALUResultM  (ALUResultM),
        .ForwardAE   (ForwardAE),
        .ForwardBE   (ForwardBE),

        // to IF
        .PCSrcE      (PCSrcE),
        .PCTargetE   (PCTargetE),

        // to MEM
        .RegWriteE   (RegWriteE),
        .MemWriteE   (MemWriteE),
        .ResultSrcE  (ResultSrcE),
        .RdE         (RdE),
        .Rs1E        (Rs1E),
        .Rs2E        (Rs2E),
        .ALUResultE  (ALUResultE),
        .WriteDataE  (WriteDataE),
        .PCPlus4E    (PCPlus4E)
    );

    // ================= MEM =================
    memory #(.XLEN(XLEN)) u_memory (
        .clk         (clk),
        .rst         (rst),
        .RegWriteE   (RegWriteE),
        .MemWriteE   (MemWriteE),
        .ResultSrcE  (ResultSrcE),
        .ALUResultE  (ALUResultE),
        .WriteDataE  (WriteDataE),
        .PCPlus4E    (PCPlus4E),
        .RdE         (RdE),

        .RegWriteM   (RegWriteM_int),
        .MemWriteM   (MemWriteM),     // exported
        .ResultSrcM  (ResultSrcM),
        .ALUResultM  (ALUResultM),    // exported
        .ReadDataM   (ReadDataM),
        .PCPlus4M    (PCPlus4M),
        .WriteDataM  (WriteDataM),    // exported
        .RdM         (RdM)
    );

    // ================= WB =================
    writeback #(.XLEN(XLEN)) u_writeback (
        .clk        (clk),
        .rst        (rst),
        .RegWriteM  (RegWriteM_int),
        .ResultSrcM (ResultSrcM),
        .ALUResultM (ALUResultM),
        .ReadDataM  (ReadDataM),
        .PCPlus4M   (PCPlus4M),
        .RdM        (RdM),

        .RegWriteW  (RegWriteW),
        .ResultW    (ResultW),
        .RdW        (RdW)
    );

    // ================= Hazard =================
    hazard u_hazard (
        .Rs1D          (Rs1D),
        .Rs2D          (Rs2D),
        .Rs1E          (Rs1E),
        .Rs2E          (Rs2E),
        .RdE           (RdE),
        .RdM           (RdM),
        .RdW           (RdW),
        .PCSrcE        (PCSrcE),
        .ResultSrcE_b0 (ResultSrcE[0]), // load in EX when 1
        .RegWriteM     (RegWriteM_int),
        .RegWriteW     (RegWriteW),

        .StallF        (StallF),
        .StallD        (StallD),
        .FlushD        (FlushD),
        .FlushE        (FlushE),
        .ForwardAE     (ForwardAE),
        .ForwardBE     (ForwardBE)
    );

endmodule

