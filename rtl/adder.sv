`timescale 1ns/1ps

module adder #(
  parameter int W = riscv_pkg::XLEN
)(
  input  logic [W-1:0] a,
  input  logic [W-1:0] b,
  output logic [W-1:0] y
);
  assign y = a + b;
endmodule
