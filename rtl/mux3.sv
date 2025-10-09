`timescale 1ns/1ps

module mux3 #(
  parameter int W = riscv_pkg::XLEN
)(
  input  logic [W-1:0] d0,
  input  logic [W-1:0] d1,
  input  logic [W-1:0] d2,
  input  logic  [1:0]  s,    // 00→d0, 01→d1, 10→d2
  output logic [W-1:0] y
);
  always_comb begin
    unique case (s)
      2'b00:   y = d0;
      2'b01:   y = d1;
      2'b10:   y = d2;
      default: y = d0;   // hardware-safe fallback
    endcase
  end
endmodule
