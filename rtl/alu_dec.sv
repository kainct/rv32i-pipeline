`timescale 1ns / 1ps

// ALU decoder: turns opcode/funct fields + ALUOp hint into a concrete ALU operation.
// Output is riscv_pkg::alu_op_e (ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_SLT).

module alu_dec(
    // Quick discriminator between R-type and I-type ALU instructions.
    // R-type opcode = 0110011 → opcode[5]=1
    // I-type  opcode = 0010011 → opcode[5]=0
    input  logic               opcode_b5,

    // funct3 field from the instruction (bits [14:12])
    input  logic [2:0]         funct3,

    // funct7 field from the instruction (bits [31:25]).
    // We look at bit 5 (i.e., instruction bit 30) to tell ADD vs SUB when funct3==000:
    //   ADD: funct7 = 0000000 → funct7[5]=0
    //   SUB: funct7 = 0100000 → funct7[5]=1
    input  logic [6:0]         funct7,

    // 2-bit hint from the main decoder telling how to decide:
    //   00 → force ADD (address lw, sw, JAL)
    //   01 → force SUB (BEQ compare)
    //   10 → decode using funct3/funct7 (R/I-type ALU)
    input  logic [1:0]         alu_op,

    // Final ALU control sent to the ALU (enum from riscv_pkg)
    output riscv_pkg::alu_op_e alu_ctrl
  );
    import riscv_pkg::*;

    // True only for R-type SUB (not ADDI). We AND the SUB pattern with opcode_b5
    // so I-type encodings (where funct7 is unrelated) won’t be misread as SUB.
    logic rtype_sub;
    assign rtype_sub = opcode_b5 && (funct7[5] == 1'b1);

    // Choose the ALU Control.
    // If main_dec already knows the answer (00/01), force it.
    // Otherwise (10), look at funct3/funct7.
    always_comb begin
      unique case (alu_op)
        2'b00:   alu_ctrl = ALU_ADD; // e.g., lw/sw address = rs1 + imm, jal not using ALU result
        2'b01:   alu_ctrl = ALU_SUB; // e.g., beq uses (rs1 - rs2) == 0
        default: begin               // 2'b10: ALU op determined by funct fields
          unique case (funct3)
            F3_ADD_SUB: alu_ctrl = (rtype_sub) ? ALU_SUB : ALU_ADD; // ADD/SUB family
            F3_AND    : alu_ctrl = ALU_AND;                         // AND / ANDI
            F3_OR     : alu_ctrl = ALU_OR;                          // OR  / ORI
            F3_SLT    : alu_ctrl = ALU_SLT;                         // SLT / SLTI
            default   : alu_ctrl = ALU_ADD;                         // safe default
          endcase
        end
      endcase
    end
endmodule
