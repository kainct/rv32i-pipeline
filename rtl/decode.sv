`timescale 1ns/1ps

`include "config.svh"

module decode #(
    parameter int XLEN = riscv_pkg::XLEN
    )(
    input  logic             clk,
    input  logic             rst,
    input  logic             StallD,
    input  logic             FlushD,
    // from IF
    input  logic [31:0]      InstrF,
    input  logic [XLEN-1:0]  PCF,
    input  logic [XLEN-1:0]  PCPlus4F,
    // WB port
    input  logic             RegWriteW,
    input  logic [4:0]       RdW,
    input  logic [XLEN-1:0]  ResultW,

    // control out
    output logic                 RegWriteD,
    output logic                 MemWriteD,
    output logic [1:0]           ResultSrcD,
    output logic                 JumpD,
    output logic                 BranchD,
    output riscv_pkg::alu_op_e   ALUControlD,   // enum
    output logic                 ALUSrcD,
    // datapath out
    output logic [XLEN-1:0]      RD1D, RD2D, PCD,
    output logic [4:0]           Rs1D, Rs2D, RdD,
    output logic [XLEN-1:0]      ExtImmD, PCPlus4D
    );
    import riscv_pkg::*;

    // ---------- IF/ID register ----------
    logic [31:0] InstrD;
    if_id_reg #(.XLEN(XLEN)) u_ifid (
        .clk(clk), 
        .rst(rst),
        .StallD(StallD), 
        .FlushD(FlushD),
        .PCF(PCF), 
        .PCPlus4F(PCPlus4F), 
        .InstrF(InstrF),
        .PCD(PCD), 
        .PCPlus4D(PCPlus4D), 
        .InstrD(InstrD)
    );

    // ---------- Field decode ----------
    wire [6:0] opcode = InstrD[6:0];
    wire [2:0] funct3 = InstrD[14:12];
    wire [6:0] funct7 = InstrD[31:25];
    
    assign Rs1D = InstrD[19:15];
    assign Rs2D = InstrD[24:20];
    assign RdD  = InstrD[11:7];

    // ---------- Controller ----------
    logic [1:0] ImmSrcD;             // controller outputs bits
    logic [2:0] ALUControlD_bits;   

    controller u_ctrl (
        .opcode      (opcode),
        .funct_3     (funct3),
        .funct7      (funct7),
        .RegWriteD   (RegWriteD),
        .ResultSrcD  (ResultSrcD),
        .MemWriteD   (MemWriteD),
        .JumpD       (JumpD),
        .BranchD     (BranchD),
        .ALUSrcD     (ALUSrcD),
        .ALUControlD (ALUControlD_bits),  // <-- drive bits
        .ImmSrcD     (ImmSrcD)
    );

    // Cast controller outputs to the expected enums
    assign ALUControlD = alu_op_e'(ALUControlD_bits);
    imm_src_e imm_sel;
    assign imm_sel = imm_src_e'(ImmSrcD);

    // ---------- Register file ----------
    regfile u_rf (
        .clk (clk),
        .we3 (RegWriteW),
        .a1  (Rs1D),
        .a2  (Rs2D),
        .a3  (RdW),
        .wd3 (ResultW),
        .rd1 (RD1D),
        .rd2 (RD2D)
    );

    // ---------- Immediate extend ----------
    imm_extend u_imm (
        .instr   (InstrD),      // pass full 32-bit instruction
        .imm_src (imm_sel),
        .imm_ext (ExtImmD)
    );
    
    `ifdef SIM
        always_ff @(posedge clk) begin
            $display("%0t D: pc=%08x op=%02x rs1=%0d rs2=%0d rd=%0d imm=%08x", $time, PCD, InstrD[6:0], InstrD[19:15], InstrD[24:20], InstrD[11:7], ExtImmD);
        end
    `endif
endmodule
