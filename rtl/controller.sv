`timescale 1ns/1ps

module controller (
    // Instruction fields
    input  logic [6:0] opcode,     // instr[6:0]
    input  logic [2:0] funct_3,    // instr[14:12]
    input  logic [6:0] funct7,     // instr[31:25]

    // Split control outputs (Decode stage)
    output logic       RegWriteD,
    output logic [1:0] ResultSrcD,
    output logic       MemWriteD,
    output logic       JumpD, BranchD,
    output logic [2:0] ALUControlD,
    output logic       ALUSrcD,
    output logic [1:0] ImmSrcD
    );
    import riscv_pkg::*;

    // Internal glue
    ctrl_s      ctrl;        // bundle from main_dec
    logic [1:0] alu_op;      // hint to alu_dec
    alu_op_e    alu_ctrl;    // final ALU ctrl from alu_dec

    // Main decoder: opcode -> high-level control + ALUOp
    main_dec u_main (
        .opcode (opcode),
        .ctrl   (ctrl),
        .alu_op (alu_op)
    );

    // ALU decoder: (ALUOp, funct3, funct7) -> ALUControl
    alu_dec u_alu (
        .opcode_b5 (opcode[5]),  // R-type vs I-type discriminator
        .funct3    (funct_3),
        .funct7    (funct7),
        .alu_op    (alu_op),
        .alu_ctrl  (alu_ctrl)
    );

    // Unpack bundle to your classic D outputs
    always_comb begin
        RegWriteD   = ctrl.RegWrite;
        MemWriteD   = ctrl.MemWrite;
        JumpD       = ctrl.Jump;
        BranchD     = ctrl.Branch;
        ALUSrcD     = ctrl.ALUSrc;
        ResultSrcD  = ctrl.ResultSrc;
        ImmSrcD     = ctrl.ImmSrc;
        ALUControlD = alu_ctrl;     // enum packs into 3 bits as in riscv_pkg
    end
endmodule
