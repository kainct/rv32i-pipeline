`timescale 1ns/1ps

module writeback #(
    parameter int XLEN = riscv_pkg::XLEN
    )(
    input  logic             clk,
    input  logic             rst,

    // from MEM stage
    input  logic             RegWriteM,
    input  logic [1:0]       ResultSrcM,       // 00=ALU, 01=Mem, 10=PC+4
    input  logic [XLEN-1:0]  ALUResultM,
    input  logic [XLEN-1:0]  ReadDataM,
    input  logic [XLEN-1:0]  PCPlus4M,
    input  logic [4:0]       RdM,
    
    input  logic             EXMEM_valid, //MODIFIED

    // to RF + back into pipeline
    output logic             RegWriteW,
    output logic [XLEN-1:0]  ResultW,
    output logic [4:0]       RdW,
    
    output logic             MEMWB_valid //MODIFIED
    );
    import riscv_pkg::*;

    // MEM/WB pipeline regs
    logic [1:0]       ResultSrcW;
    logic [XLEN-1:0]  ALUResultW, ReadDataW, PCPlus4W;

    mem_wb_reg #(.XLEN(XLEN)) u_memwb (
        .clk        (clk),
        .rst        (rst),
        .RegWriteM  (RegWriteM),
        .ResultSrcM (ResultSrcM),
        .ALUResultM (ALUResultM),
        .ReadDataM  (ReadDataM),
        .PCPlus4M   (PCPlus4M),
        .RdM        (RdM),
        .EXMEM_valid (EXMEM_valid),
        .RegWriteW  (RegWriteW),
        .ResultSrcW (ResultSrcW),
        .ALUResultW (ALUResultW),
        .ReadDataW  (ReadDataW),
        .PCPlus4W   (PCPlus4W),
        .RdW        (RdW),
        .MEMWB_valid (MEMWB_valid)
    );

    // 3-way result mux: ALU / Mem / PC+4
    mux3 #(.W(XLEN)) u_wb_mux (
        .d0 (ALUResultW),
        .d1 (ReadDataW),
        .d2 (PCPlus4W),
        .s  (ResultSrcW),
        .y  (ResultW)
    );
endmodule
