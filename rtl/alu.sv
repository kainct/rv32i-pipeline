`timescale 1ns / 1ps

module alu #(
    parameter int XLEN = riscv_pkg::XLEN
    )(
    input  logic [XLEN-1:0]     a, b,
    input  riscv_pkg::alu_op_e  op,
    output logic [XLEN-1:0]     y,
    output logic                zero
    );

    import riscv_pkg::*;
    
    always_comb begin
        unique case(op)
            ALU_ADD: y = a + b;                                                   //add 
            ALU_SUB: y = a - b;                                                   //sub
            ALU_AND: y = a & b;                                                   //and
            ALU_OR:  y = a | b;                                                   //or
            ALU_SLT: y = ($signed(a) < $signed(b)) ? {{XLEN-1{1'b0}}, 1'b1} : '0; //signed slt (1 or 0, XLEN-wide)
            default: y = '0;
        endcase
    end
   
    assign zero = (y == '0);
endmodule