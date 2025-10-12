`timescale 1ns/1ps

module if_id_reg #(
    parameter int XLEN = riscv_pkg::XLEN
    )(
    input  logic            clk,
    input  logic            rst,
    input  logic            StallD,   // 1 = hold outputs
    input  logic            FlushD,   // 1 = bubble/NOP
    input  logic [XLEN-1:0] PCF,
    input  logic [XLEN-1:0] PCPlus4F,
    input  logic [31:0]     InstrF,
    output logic [XLEN-1:0] PCD,
    output logic [XLEN-1:0] PCPlus4D,
    output logic [31:0]     InstrD,
    //OPTIONAL:
    output logic            IFID_valid // MODIFIED
    );
    
    import riscv_pkg::*;

    // PC
    flop_en_rst_cl #(.WIDTH(XLEN), .RESET_VAL('0), .CLEAR_VAL('0)) u_pc (
        .clk(clk), 
        .rst(rst), 
        .en(~StallD), 
        .clr(FlushD),
        .d(PCF),  
        .q(PCD)
    );

    // PC+4
    flop_en_rst_cl #(.WIDTH(XLEN), .RESET_VAL('0), .CLEAR_VAL('0)) u_pc4 (
        .clk(clk), 
        .rst(rst), 
        .en(~StallD), 
        .clr(FlushD),
        .d(PCPlus4F), 
        .q(PCPlus4D)
    );

    // INSTR (bubble = NOP)
    flop_en_rst_cl #(.WIDTH(32), .RESET_VAL(INSTR_NOP), .CLEAR_VAL(INSTR_NOP)) u_instr (
        .clk(clk), 
        .rst(rst), 
        .en(~StallD), 
        .clr(FlushD),
        .d(InstrF), 
        .q(InstrD)
    );

    //MODIFIED: VALID bit — set to 1 when a new instr is accepted, cleared on reset/flush
    flop_en_rst_cl #(.WIDTH(1), .RESET_VAL(1'b0), .CLEAR_VAL(1'b0)) u_valid (
        .clk(clk), 
        .rst(rst), 
        .en(~StallD), 
        .clr(FlushD),
        .d(1'b1), 
        .q(IFID_valid)
    );

endmodule