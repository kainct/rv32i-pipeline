`timescale 1ns/1ps

module dmem #(
    parameter int WIDTH = 32,      // data width (keep 32 for lw/sw)
    parameter int DEPTH = 64       // number of words
    )(
    input  logic             clk,
    input  logic             w_en,
    input  logic [31:0]      addr,
    input  logic [WIDTH-1:0] w_d,
    output logic [WIDTH-1:0] r_d
    );

    // Storage (ascending indices)
    logic [WIDTH-1:0] RAM [0:DEPTH-1];

    // Index width derived from DEPTH
    localparam int AW = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
    wire [AW-1:0] widx = addr[AW+1:2];   // drop byte bits [1:0]

    // Init to avoid Xs in sim
    initial for (int i = 0; i < DEPTH; i++) RAM[i] = '0;

    // Combinational read (easy for sim)
    assign r_d = RAM[widx];

    // Synchronous write
    always_ff @(posedge clk) begin
        if (w_en) RAM[widx] <= w_d;
    end
endmodule
