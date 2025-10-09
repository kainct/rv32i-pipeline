`timescale 1ns/1ps

module mux2 #(
    parameter int W = riscv_pkg::XLEN
    )(
    input  logic [W-1:0] d0,
    input  logic [W-1:0] d1,
    input  logic         s,     // 0→d0, 1→d1
    output logic [W-1:0] y
    );
    assign y = s ? d1 : d0;
endmodule
