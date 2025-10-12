`timescale 1ns/1ps

`include "config.svh"

module id_ex_reg #(
    parameter int XLEN = riscv_pkg::XLEN
    )(
    input  logic             clk,
    input  logic             rst,
    input  logic             FlushE,        // 1 = bubble (zeros control)
    input  logic             IFID_valid,    // MODIFIED: from IF/ID stage
    input  riscv_pkg::ctrl_s ctrl_d,
    input  riscv_pkg::data_s data_d,
    output riscv_pkg::ctrl_s ctrl_e,
    output riscv_pkg::data_s data_e,

    output logic             IDEX_valid // MODIFIED: to EX
    );
    
    import riscv_pkg::*;

    // Bit-cast packed structs to vectors for the generic flop
    localparam int CTRL_W = $bits(ctrl_s);
    localparam int DATA_W = $bits(data_s);

    logic [CTRL_W-1:0] ctrl_d_bits, ctrl_e_bits;
    logic [DATA_W-1:0] data_d_bits, data_e_bits;

    assign ctrl_d_bits = ctrl_d;
    assign data_d_bits = data_d;
    assign ctrl_e      = ctrl_e_bits;
    assign data_e      = data_e_bits;

    // Control: bubble = zeros
    flop_en_rst_cl #(.WIDTH(CTRL_W), .RESET_VAL('0), .CLEAR_VAL('0)) u_ctrl (
        .clk(clk), 
        .rst(rst), 
        .en(1'b1), 
        .clr(FlushE),
        .d(ctrl_d_bits), 
        .q(ctrl_e_bits)
    );

    // Data: bubble = zeros (safe)
    flop_en_rst_cl #(.WIDTH(DATA_W), .RESET_VAL('0), .CLEAR_VAL('0)) u_data (
        .clk(clk), 
        .rst(rst), 
        .en(1'b1), 
        .clr(FlushE),
        .d(data_d_bits), 
        .q(data_e_bits)
    );

    // MODIFIED: Valid bit — 1 when a real instr enters ID/EX, 0 on reset/flush
    flop_en_rst_cl #(.WIDTH(1), .RESET_VAL(1'b0), .CLEAR_VAL(1'b0)) u_valid (
        .clk(clk), 
        .rst(rst),
        .en(1'b1),              // hold during StallE
        .clr(FlushE),              // bubble on FlushE
        .d(IFID_valid),            // propagate stage validity
        .q(IDEX_valid)
    );
    
    `ifdef SIM
        always_ff @(posedge clk) begin
            $display("%0t ID/EX: Rs1D=%0d Rs2D=%0d RdD=%0d  -->  Rs1E=%0d Rs2E=%0d RdE=%0d", $time, data_d.Rs1, data_d.Rs2, data_d.Rd, data_e.Rs1, data_e.Rs2, data_e.Rd);
        end
    `endif
endmodule
