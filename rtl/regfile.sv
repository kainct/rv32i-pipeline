`timescale 1ns / 1ps

module regfile #(
    parameter int XLEN = riscv_pkg::XLEN
)(
    input  logic                 clk,
    input  logic                 we3,          // write enable
    input  logic [4:0]           a1, a2, a3,   // rs1, rs2, rd
    input  logic [XLEN-1:0]      wd3,          // write data
    output logic [XLEN-1:0]      rd1, rd2      // read data
);
    import riscv_pkg::*;
    logic [XLEN-1:0] rf[31:0]; // 32 registers

    // Inititialize value of every register to be 0 at the beginning
    initial begin : init_rf
    integer i;
    for (i = 0; i < 32; i++) rf[i] = '0;
    end

    // COMBINATIONAL reads with write-first bypass in the same cycle (if in the same cycle writing to the same address as reading --> read returns wd3)
    always_comb begin
        rd1 = (a1 == X0) ? '0
            : (we3 && (a1 == a3)) ? wd3
            : rf[a1];

        rd2 = (a2 == X0) ? '0
            : (we3 && (a2 == a3)) ? wd3
            : rf[a2];
    end

    // synchronous write; ignore writes to x0
    always_ff @(posedge clk) 
        if (we3 && (a3 != X0)) rf[a3] <= wd3;

    // helpful debug print in sim
    always_ff @(posedge clk) if (we3)
        $display("RF: x%0d <= 0x%08x", a3, wd3);
endmodule