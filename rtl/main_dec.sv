`timescale 1ns/1ps

module main_dec(
    input  logic [6:0]         opcode,           // instr[6:0]
    output riscv_pkg::ctrl_s   ctrl,             // superset control bundle
    output logic [1:0]         alu_op            // hint to alu_dec
);  

    import riscv_pkg::*;

    // ResultSrc encoding used in ctrl.ResultSrc
    localparam logic [1:0]  RSRC_ALU = 2'b00,
                            RSRC_MEM = 2'b01,
                            RSRC_PC4 = 2'b10;

    // Default: bubble (all zeros)
    always_comb begin
        ctrl   = '0;
        alu_op = 2'b00;

        unique case (opcode)
        // ---------------- R-type: add, sub, and, or, slt ----------------
        OP_RTYPE: begin
            ctrl.RegWrite   = 1'b1;
            ctrl.ResultSrc  = RSRC_ALU;      // ALU result to WB
            ctrl.ALUSrc     = 1'b0;          // use rs2
            alu_op          = 2'b10;         // let alu_dec use funct3/funct7
        end

        // ---------------- I-type ALU: addi/andi/ori ---------------------
        OP_ITYPE: begin
            ctrl.RegWrite   = 1'b1;
            ctrl.ResultSrc  = RSRC_ALU;
            ctrl.ALUSrc     = 1'b1;          // rs1 + imm / logic imm
            ctrl.ImmSrc     = IMM_I;
            alu_op          = 2'b10;         // funct3 selects op in alu_dec
        end

        // ---------------- Load: lw --------------------------------------
        OP_LOAD: begin
            ctrl.RegWrite   = 1'b1;          // write loaded word
            ctrl.ResultSrc  = RSRC_MEM;      // WB from memory
            ctrl.ALUSrc     = 1'b1;          // addr = rs1 + imm
            ctrl.ImmSrc     = IMM_I;         // I-type imm
            alu_op          = 2'b00;         // force ADD for address calc
        end

        // ---------------- Store: sw -------------------------------------
        OP_STORE: begin
            ctrl.MemWrite   = 1'b1;          // do store
            ctrl.ResultSrc  = RSRC_ALU;      // WB ignored
            ctrl.ALUSrc     = 1'b1;          // addr = rs1 + imm
            ctrl.ImmSrc     = IMM_S;         // S-type imm
            alu_op          = 2'b00;         // force ADD
        end

        // ---------------- Branch: beq -----------------------------------
        OP_BRANCH: begin
            ctrl.Branch     = 1'b1;          // PCSrc uses Branch & Zero
            ctrl.ResultSrc  = RSRC_ALU;      // WB ignored
            ctrl.ALUSrc     = 1'b0;          // compare rs1 vs rs2
            ctrl.ImmSrc     = IMM_B;         // B-type imm
            alu_op          = 2'b01;         // force SUB for equality compare
        end

        // ---------------- Jump: jal -------------------------------------
        OP_JAL: begin
            ctrl.Jump       = 1'b1;          // PCSrc uses Jump
            ctrl.RegWrite   = 1'b1;          // rd = PC+4
            ctrl.ResultSrc  = RSRC_PC4;      // select PC+4 in WB
            ctrl.ALUSrc     = 1'b0;
            ctrl.ImmSrc     = IMM_J;         // J-type imm
            alu_op          = 2'b00;         // ALU not used for result
        end

        default: /* bubble */ ;
        endcase
    end
endmodule
