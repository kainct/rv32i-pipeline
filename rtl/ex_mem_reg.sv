`timescale 1ns/1ps

module ex_mem_reg #(
    parameter int XLEN = riscv_pkg::XLEN
    )(
    input  logic             clk,
    input  logic             rst,

    // ---- control from EX ----
    input  logic             RegWriteE,
    input  logic             MemWriteE,
    input  logic [1:0]       ResultSrcE,

    // ---- data from EX ----
    input  logic [XLEN-1:0]  ALUResultE,
    input  logic [XLEN-1:0]  WriteDataE,
    input  logic [XLEN-1:0]  PCPlus4E,
    input  logic [4:0]       RdE,

    // ---- to MEM ----
    output logic             RegWriteM,
    output logic             MemWriteM,
    output logic [1:0]       ResultSrcM,
    output logic [XLEN-1:0]  ALUResultM,
    output logic [XLEN-1:0]  WriteDataM,
    output logic [XLEN-1:0]  PCPlus4M,
    output logic [4:0]       RdM
    );
    
    import riscv_pkg::*;

    // Pack control + data so we can use one flop instance
    localparam int CTRL_W = 1 + 1 + 2;              // RegWrite, MemWrite, ResultSrc
    localparam int DATA_W = (3*XLEN) + 5;           // ALUResult, WriteData, PC+4, Rd

    logic [CTRL_W-1:0] ctrlE, ctrlM;
    logic [DATA_W-1:0] dataE, dataM;

    // pack
    assign ctrlE = {RegWriteE, MemWriteE, ResultSrcE};
    assign dataE = {ALUResultE, WriteDataE, PCPlus4E, RdE};

    // unpack
    assign {RegWriteM, MemWriteM, ResultSrcM}        = ctrlM;
    assign {ALUResultM, WriteDataM, PCPlus4M, RdM}   = dataM;

    // Single pipeline register (reset-only for now; no stall/flush yet)
    flop_en_rst_cl #(
        .WIDTH(CTRL_W + DATA_W),
        .RESET_VAL('0),
        .CLEAR_VAL('0)
    ) u_exmem (
        .clk (clk),
        .rst (rst),
        .en  (1'b1),     
        .clr (1'b0),   
        .d   ({ctrlE, dataE}),
        .q   ({ctrlM, dataM})
    );
endmodule
