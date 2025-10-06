// Set simulation time units/precision: delays like #1 mean 1 ns, precision to 1 ps
`timescale 1ns/1ps

// Testbench has no ports (it’s the simulation top)
module tb_alu;

    // Import types/constants from our package so we can use enums like alu_op_e
    import riscv_pkg::*;

    // Testbench-local signals to drive/observe the DUT (Device Under Test)
    logic [31:0] a, b;     // ALU inputs
    logic [31:0] y;        // ALU output
    logic        zero;     // ALU zero flag
    alu_op_e     op;       // ALU operation select (enum from the package)

    // Instantiate the ALU (DUT) and connect TB signals to its ports
    alu dut(
        .a   (a),
        .b   (b),
        .op  (op),
        .y   (y),
        .zero(zero)
    );

    // Small helper task to check expected result 'exp' against ALU output 'y'
    // - name: a short label printed in logs (e.g., "ADD")
    // If mismatch, $fatal exits the sim with a non-zero code (red test).
    task check(input string name, input logic [31:0] exp);
        if (y !== exp) begin
            $fatal(1, "%s FAIL: got 0x%08x exp 0x%08x", name, y, exp);
        end 
        else begin
            $display("%s PASS: 0x%08x", name, y);
        end
    endtask

    // The main stimulus/verification sequence runs once at time 0
    initial begin
        // Base operands for most tests
        a = 32'd5;
        b = 32'd7;

        // Test 1: ADD — expect 12
        op = ALU_ADD;   // select ADD
        #1;             // wait 1 ns for combinational logic to settle
        check("ADD", 32'd12);

        // Test 2: SUB — expect -2 (two’s complement: 0xFFFF_FFFE)
        op = ALU_SUB;
        #1;
        check("SUB", 32'hFFFF_FFFE);

        // Test 3: AND — expect 5 & 7
        op = ALU_AND;
        #1;
        check("AND", (32'd5 & 32'd7));

        // Test 4: OR — expect 5 | 7
        op = ALU_OR;
        #1;
        check("OR", (32'd5 | 32'd7));

        // Test 5: SLT (signed) — (-1 < 0) should yield 1
        a  = -32'sd1;   // signed literal: minus one
        b  = 32'd0;
        op = ALU_SLT;
        #1;
        check("SLT signed", 32'd1);

        // Test 6: SLT when equal — (5 < 5) is false → 0
        a  = 32'd5;
        b  = 32'd5;
        op = ALU_SLT;
        #1;
        check("SLT equal", 32'd0);

        // If we get here, all checks passed
        $display("ALU tests PASS");
        $finish;        // end simulation cleanly
    end

endmodule
