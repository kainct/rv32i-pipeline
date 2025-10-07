`timescale 1ns / 1ps

module imm_extend #(
    parameter int XLEN = riscv_pkg::XLEN
    )(
    input  logic                [31:0]     instr,    // raw instruction
    input  riscv_pkg::imm_src_e            imm_src,  // which immediate to extract (I/S/B/J)
    output logic                [XLEN-1:0] imm_ext   // sign-extended immediate
    );
    import riscv_pkg::*;

    always_comb begin
        unique case (imm_src)
        
        // I-type: imm[11:0] = instr[31:20]
        IMM_I: imm_ext = {{20{instr[31]}}, instr[31:20]};

        // S-type: imm[11:5]=instr[31:25], imm[4:0]=instr[11:7]
        IMM_S: imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]};

        // B-type: imm[12]=instr[31], imm[11]=instr[7], imm[10:5]=instr[30:25],
        //         imm[4:1]=instr[11:8], imm[0]=0
        IMM_B: imm_ext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};

        // J-type: imm[20]=instr[31], imm[19:12]=instr[19:12], imm[11]=instr[20],
        //         imm[10:1]=instr[30:21], imm[0]=0
        IMM_J: imm_ext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

        default: imm_ext = '0;
        endcase
    end
    endmodule
