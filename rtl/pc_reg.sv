`timescale 1ns/1ps

module pc_reg #(
    parameter int XLEN = riscv_pkg::XLEN
    )(
    input  logic            clk,
    input  logic            rst,         // sync, active-high
    input  logic            StallF,      // 1 = hold PC
    input  logic [XLEN-1:0] PCNextF,
    output logic [XLEN-1:0] PCF
    );
    import riscv_pkg::*;

    flop_en_rst_cl #(
        .WIDTH(XLEN),
        .RESET_VAL(RESET_PC),
        .CLEAR_VAL(RESET_PC)
    ) u_pc (
        .clk(clk),
        .rst(rst),
        .en(~StallF),
        .clr(1'b0),
        .d(PCNextF),
        .q(PCF)
    );
endmodule
