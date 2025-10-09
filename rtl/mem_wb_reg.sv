`timescale 1ns/1ps

module mem_wb_reg #(
    parameter int XLEN = riscv_pkg::XLEN
    )(
    input  logic             clk,
    input  logic             rst,

    // from MEM
    input  logic             RegWriteM,
    input  logic [1:0]       ResultSrcM,
    input  logic [XLEN-1:0]  ALUResultM,
    input  logic [XLEN-1:0]  ReadDataM,
    input  logic [XLEN-1:0]  PCPlus4M,
    input  logic [4:0]       RdM,

    // to WB
    output logic             RegWriteW,
    output logic [1:0]       ResultSrcW,
    output logic [XLEN-1:0]  ALUResultW,
    output logic [XLEN-1:0]  ReadDataW,
    output logic [XLEN-1:0]  PCPlus4W,
    output logic [4:0]       RdW
    );
    import riscv_pkg::*;

    // Pack widths: 1 (RegWrite) + 2 (ResultSrc) + 5 (Rd) + 3*XLEN = 3*XLEN + 8
    localparam int PACK_W = (3*XLEN) + 8;

    flop_en_rst_cl #(
        .WIDTH(PACK_W),
        .RESET_VAL('0),
        .CLEAR_VAL('0)
    ) u_memwb (
        .clk (clk),
        .rst (rst),
        .en  (1'b1),   // no WB stall in basic pipeline
        .clr (1'b0),   // no WB flush; upstream flushes suffice
        .d   ({RegWriteM, ResultSrcM, ALUResultM, ReadDataM, RdM, PCPlus4M}),
        .q   ({RegWriteW, ResultSrcW, ALUResultW, ReadDataW, RdW, PCPlus4W})
    );
endmodule
