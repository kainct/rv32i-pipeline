`timescale 1ns/1ps

// Synchronous, active-high reset; active-high enable; synchronous clear.
// Priority: reset > clear > enable > hold

module flop_en_rst_cl #(
    parameter int WIDTH = 32,
    // Value after reset (e.g., 0 or INSTR_NOP for instruction regs)
    parameter logic [WIDTH-1:0] RESET_VAL = '0,
    // Value to load on clear/flush (often same as reset; for IF/ID instr use INSTR_NOP)
    parameter logic [WIDTH-1:0] CLEAR_VAL = '0
    )(
    input  logic             clk,
    input  logic             rst,     // synchronous, active-high
    input  logic             en,      // active-high enable: 1=update, 0=hold
    input  logic             clr,     // synchronous clear/flush (wins over en)
    input  logic [WIDTH-1:0] d,       // input data
    output logic [WIDTH-1:0] q        // registered output
    );

    always_ff @(posedge clk) begin
        if (rst)       q <= RESET_VAL;   // highest priority
        else if (clr)  q <= CLEAR_VAL;   // inject bubble even during stalls
        else if (en)   q <= d;           // CE maps to FF's native enable on FPGA
        // else: hold previous value
    end

endmodule
