`timescale 1ns/1ps

module tb_alu_dec;
  import riscv_pkg::*;  // brings in F3_* and alu_op_e (ALU_ADD, ...)

  // ---------------- DUT I/O ----------------
  logic               opcode_b5;   // 1 = R-type, 0 = I-type
  logic [2:0]         funct3;
  logic [6:0]         funct7;
  logic [1:0]         alu_op;      // hint from main_dec
  alu_op_e            alu_ctrl;    // result from DUT

  // Device Under Test
  alu_dec dut (
    .opcode_b5 (opcode_b5),
    .funct3    (funct3),
    .funct7    (funct7),
    .alu_op    (alu_op),
    .alu_ctrl  (alu_ctrl)
  );

  // ---------------- helpers ----------------
  task automatic expect_op(input string name, input alu_op_e exp);
    if (alu_ctrl !== exp) $fatal(1, "%s: got %0d, exp %0d", name, alu_ctrl, exp);
    else                  $display("%s: PASS (%0d)", name, exp);
  endtask

  // Drive some defaults between tests
  task automatic clear_fields();
    opcode_b5 = 1'b0;
    funct3    = 3'b000;
    funct7    = 7'b0000000;
    alu_op    = 2'b00;
    #1;
  endtask

  // ---------------- tests ----------------
  initial begin
    $display("tb_alu_dec: starting");

    // 0. defaults
    clear_fields();

    // 1. ALUOp forcing (main_dec decides)
    //    00 -> ADD (e.g., lw/sw addr calc, jal)
    opcode_b5 = 1'b0; funct3 = 3'b111; funct7 = 7'b0100000; alu_op = 2'b00; 
    #1;
    expect_op("ALUOp=00 forces ADD", ALU_ADD);

    //    01 -> SUB (e.g., beq compare)
    opcode_b5 = 1'b0; funct3 = 3'b110; funct7 = 7'b0000000; alu_op = 2'b01; #1;
    expect_op("ALUOp=01 forces SUB", ALU_SUB);

    // 2. R-type decode via funct3/funct7 when ALUOp=10
    alu_op = 2'b10;

    // 2a. R-type ADD: funct3=000, funct7=0000000, opcode_b5=1
    opcode_b5 = 1'b1; funct3 = F3_ADD_SUB; funct7 = 7'b0000000; #1;
    expect_op("R-type ADD", ALU_ADD);

    // 2b. R-type SUB: funct3=000, funct7=0100000, opcode_b5=1
    opcode_b5 = 1'b1; funct3 = F3_ADD_SUB; funct7 = 7'b0100000; #1;
    expect_op("R-type SUB", ALU_SUB);

    // 2c. AND
    opcode_b5 = 1'b1; funct3 = F3_AND; funct7 = 7'b0000000; #1;
    expect_op("R-type AND", ALU_AND);

    // 2d. OR
    opcode_b5 = 1'b1; funct3 = F3_OR;  funct7 = 7'b0000000; #1;
    expect_op("R-type OR",  ALU_OR);

    // 2e. SLT
    opcode_b5 = 1'b1; funct3 = F3_SLT; funct7 = 7'b0000000; #1;
    expect_op("R-type SLT", ALU_SLT);

    // 3. I-type ADDI path (must NOT be misclassified as SUB)
    //    Set opcode_b5=0 (I-type), funct3=000; funct7 is don't-care for I-type,
    //    but even if bit5 is 1, rtype_sub must be false because opcode_b5=0.
    opcode_b5 = 1'b0; funct3 = F3_ADD_SUB; funct7 = 7'b0100000; alu_op = 2'b10; #1;
    expect_op("I-type ADDI (not SUB)", ALU_ADD);

    // 4. Unknown funct3 default (defensive default to ADD)
    opcode_b5 = 1'b1; funct3 = 3'b101; funct7 = 7'b0000000; alu_op = 2'b10; #1;
    expect_op("Unknown funct3 defaults to ADD", ALU_ADD);

    $display("tb_alu_dec: all tests PASS");
    $finish;
  end
endmodule
