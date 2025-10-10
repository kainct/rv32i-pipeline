`timescale 1ns/1ps

`include "config.svh"

module fetch #(
    parameter int XLEN = riscv_pkg::XLEN
    )(
    input  logic             clk,
    input  logic             rst,
    input  logic             PCSrcE,          // 1 -> take branch/jump target
    input  logic             StallF,          // 1 -> hold PCF
    input  logic [XLEN-1:0]  PCTargetE,       // branch/jump target from EX
    output logic [31:0]      InstrF,          // 32-bit instruction
    output logic [XLEN-1:0]  PCF,
    output logic [XLEN-1:0]  PCPlus4F
    );
    import riscv_pkg::*;

    logic [XLEN-1:0] PCNextF;

    // Next PC mux: 0=PC+4, 1=target
    mux2 #(.W(XLEN)) u_pc_mux (
        .d0 (PCPlus4F),
        .d1 (PCTargetE),
        .s  (PCSrcE),
        .y  (PCNextF)
    );

    // Program counter register (stall supported)
    pc_reg u_pc (
        .clk     (clk),
        .rst     (rst),
        .StallF  (StallF),
        .PCNextF (PCNextF),
        .PCF     (PCF)
    );

    // Instruction memory (combinational read)
    imem u_imem (
        .addr (PCF),
        .r_d  (InstrF)
    );

    // PC + 4
    adder #(.W(XLEN)) u_pc_plus4 (
        .a (PCF),
        .b (32'd4),        // 4-byte instruction step
        .y (PCPlus4F)
    );
    
    `ifdef SIM
        always_ff @(posedge clk) begin
            $strobe("%0t IF : PC=%08x PC+4=%08x PCTargetE=%08x PCSrcE=%0b -> PCNext=%08x", $time, PCF, PCPlus4F, PCTargetE, PCSrcE, PCNextF);
        end
    `endif
endmodule
