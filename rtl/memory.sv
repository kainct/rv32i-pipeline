`timescale 1ns/1ps

module memory #(
    parameter int XLEN = riscv_pkg::XLEN
    )(
    input  logic             clk,
    input  logic             rst,

    // -------- from EX stage --------
    input  logic             RegWriteE,
    input  logic             MemWriteE,
    input  logic [1:0]       ResultSrcE,
    input  logic [XLEN-1:0]  ALUResultE,
    input  logic [XLEN-1:0]  WriteDataE,
    input  logic [XLEN-1:0]  PCPlus4E,
    input  logic [4:0]       RdE,
    
    input  logic             IDEX_valid, //MODIFIED

    // -------- to MEM/WB (and for testbench visibility) --------
    output logic             RegWriteM,
    output logic             MemWriteM,
    output logic [1:0]       ResultSrcM,
    output logic [XLEN-1:0]  ALUResultM,
    output logic [XLEN-1:0]  ReadDataM,
    output logic [XLEN-1:0]  PCPlus4M,
    output logic [XLEN-1:0]  WriteDataM,
    output logic [4:0]       RdM,
    
    output logic             EXMEM_valid //MODIFIED
    );
    import riscv_pkg::*;

    // ---------------- EX/MEM pipeline register ----------------
    ex_mem_reg #(.XLEN(XLEN)) u_exmem (
        .clk        (clk),
        .rst        (rst),
        .RegWriteE  (RegWriteE),
        .MemWriteE  (MemWriteE),
        .ResultSrcE (ResultSrcE),
        .ALUResultE (ALUResultE),
        .WriteDataE (WriteDataE),
        .PCPlus4E   (PCPlus4E),
        .RdE        (RdE),
        .IDEX_valid (IDEX_valid), //MODIFIED
        .RegWriteM  (RegWriteM),
        .MemWriteM  (MemWriteM),
        .ResultSrcM (ResultSrcM),
        .ALUResultM (ALUResultM),
        .WriteDataM (WriteDataM),
        .PCPlus4M   (PCPlus4M),
        .RdM        (RdM),
        .EXMEM_valid (EXMEM_valid) //MODIFIED
    );

    // ---------------- Data memory (combinational read, sync write) ----------------
    dmem #(
        .WIDTH (XLEN),
        .DEPTH (64)
    ) u_dmem (
        .clk  (clk),
        .w_en (MemWriteM),
        .addr (ALUResultM),
        .w_d  (WriteDataM),
        .r_d  (ReadDataM)
    );

endmodule
