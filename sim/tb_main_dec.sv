// sim/tb_main_dec.sv
`timescale 1ns/1ps

module tb_main_dec;
  import riscv_pkg::*;   // OP_* constants, ctrl_s, imm_src_e

  // DUT I/O
  logic  [6:0] opcode;
  ctrl_s       ctrl;
  logic  [1:0] alu_op;

  // Local aliases for ResultSrc encodings used in main_dec
  localparam logic [1:0] RSRC_ALU = 2'b00,
                         RSRC_MEM = 2'b01,
                         RSRC_PC4 = 2'b10;

  // Device Under Test
  main_dec dut (
    .opcode (opcode),
    .ctrl   (ctrl),
    .alu_op (alu_op)
  );

  // ---- tiny helpers ----
  task automatic expect_ok(input string name, input logic cond);
    if (!cond)  $fatal(1, "%s: FAIL", name);
    else        $display("%s: PASS", name);
  endtask

  task automatic clear();
    opcode = 7'h00;
    #1; // allow comb logic to settle
  endtask

  // ---------------- tests ----------------
  initial begin
    $display("tb_main_dec: start");
    clear();

    // R-type
    opcode = OP_RTYPE; #1;
    expect_ok("R: RegWrite",   ctrl.RegWrite == 1);
    expect_ok("R: ResultSrc",  ctrl.ResultSrc == RSRC_ALU);
    expect_ok("R: ALUSrc",     ctrl.ALUSrc == 0);
    expect_ok("R: ALUOp=10",   alu_op == 2'b10);
    expect_ok("R: no mem/jmp", !ctrl.MemWrite && !ctrl.Jump && !ctrl.Branch);

    // I-type ALU (addi/andi/ori)
    opcode = OP_ITYPE; #1;
    expect_ok("I: RegWrite",   ctrl.RegWrite == 1);
    expect_ok("I: ResultSrc",  ctrl.ResultSrc == RSRC_ALU);
    expect_ok("I: ALUSrc",     ctrl.ALUSrc == 1);
    expect_ok("I: ImmSrc=I",   ctrl.ImmSrc == IMM_I);
    expect_ok("I: ALUOp=10",   alu_op == 2'b10);

    // LOAD (lw)
    opcode = OP_LOAD; #1;
    expect_ok("LW: RegWrite",  ctrl.RegWrite == 1);
    expect_ok("LW: ResultSrc", ctrl.ResultSrc == RSRC_MEM);
    expect_ok("LW: ALUSrc",    ctrl.ALUSrc == 1);
    expect_ok("LW: ImmSrc=I",  ctrl.ImmSrc == IMM_I);
    expect_ok("LW: ALUOp=00",  alu_op == 2'b00);

    // STORE (sw)
    opcode = OP_STORE; #1;
    expect_ok("SW: MemWrite",  ctrl.MemWrite == 1);
    expect_ok("SW: ALUSrc",    ctrl.ALUSrc == 1);
    expect_ok("SW: ImmSrc=S",  ctrl.ImmSrc == IMM_S);
    expect_ok("SW: ALUOp=00",  alu_op == 2'b00);

    // BRANCH (beq)
    opcode = OP_BRANCH; #1;
    expect_ok("BEQ: Branch",   ctrl.Branch == 1);
    expect_ok("BEQ: ALUSrc",   ctrl.ALUSrc == 0);
    expect_ok("BEQ: ImmSrc=B", ctrl.ImmSrc == IMM_B);
    expect_ok("BEQ: ALUOp=01", alu_op == 2'b01);

    // JAL
    opcode = OP_JAL; #1;
    expect_ok("JAL: Jump",      ctrl.Jump == 1);
    expect_ok("JAL: RegWrite",  ctrl.RegWrite == 1);
    expect_ok("JAL: ResultSrc", ctrl.ResultSrc == RSRC_PC4);
    expect_ok("JAL: ImmSrc=J",  ctrl.ImmSrc == IMM_J);
    expect_ok("JAL: ALUOp=00",  alu_op == 2'b00);

    $display("tb_main_dec: all tests PASS");
    $finish;
  end
endmodule
