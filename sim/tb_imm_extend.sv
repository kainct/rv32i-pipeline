`timescale 1ns/1ps                 

module tb_imm_extend;              
    import riscv_pkg::*;             

    // ---------- DUT signals ---------
    logic [31:0]   instr;            
    imm_src_e      imm_sel;          
    logic [31:0]   imm_ext;          

    // ---------- DUT ----------
    imm_extend dut (
        .instr   (instr),              // connect TB 'instr' to DUT 'instr'
        .imm_src (imm_sel),            // connect TB 'imm_sel' to DUT 'imm_src'
        .imm_ext (imm_ext)             // read DUT result here
    );

    // ---------- Helper functions to BUILD instructions ----------

    // Build an I-type instruction (e.g., addi/andi/ori)
    function automatic [31:0] build_I(input logic signed [11:0] imm12);

        // [31:20]=imm[11:0], [19:15]=rs1, [14:12]=funct3, [11:7]=rd, [6:0]=opcode
        // We fix rs1=x1, rd=x2, funct3=000 (values don’t matter for imm_extend)
        build_I = {imm12, 5'd1, 3'b000, 5'd2, OP_ITYPE};
    endfunction

    // Build an S-type instruction (e.g., sw)
    function automatic [31:0] build_S(input logic signed [11:0] imm12);

        // [31:25]=imm[11:5], [24:20]=rs2, [19:15]=rs1, [14:12]=funct3, [11:7]=imm[4:0],  [6:0]=opcode
        // We fix rs2=x3, rs1=x1, funct3=010 (word), opcode=OP_STORE.
        build_S = {imm12[11:5], 5'd3, 5'd1, 3'b010, imm12[4:0], OP_STORE};
    endfunction

    // Build a B-type instruction (e.g., beq)
    function automatic [31:0] build_B(input logic signed [12:0] imm13);
        
        // [31]=imm[12], [30:25]=imm[10:5], [24:20]=rs2, [19:15]=rs1, [14:12]=funct3, [11:8]=imm[4:1], [7]=imm[11], [6:0]=opcode
        // We fix rs2=x2, rs1=x1, funct3=000 (beq), opcode=OP_BRANCH.
        build_B = {imm13[12], imm13[10:5], 5'd2, 5'd1, 3'b000, imm13[4:1], imm13[11], OP_BRANCH };
    endfunction

    // Build a J-type instruction (jal)
    function automatic [31:0] build_J(input logic signed [20:0] imm21);

        // [31]=imm[20], [30:21]=imm[10:1], [20]=imm[11], [19:12]=imm[19:12],
        // [11:7]=rd, [6:0]=opcode
        // We set rd=x1 (link register), opcode=OP_JAL.
        build_J = {imm21[20], imm21[10:1], imm21[11], imm21[19:12], 5'd1, OP_JAL};
    endfunction

    // Simple checker: compare 'got' vs 'exp'; FAIL stops sim, PASS prints line
    task automatic expect_eq(input string name, input logic [31:0] got, exp);
        if (got !== exp) $fatal(1, "%s: got 0x%08x, expected 0x%08x", name, got, exp);
        else             $display("%s PASS: 0x%08x", name, got);
    endtask

    // ---------------- Tests ----------------
    
    //B-type and J-type signals 
    logic signed [12:0] b_plus8, b_minus4;
    logic signed [20:0] j_plus16, j_minus8;
    
    initial begin
        // --- I-type tests: check +5 and −9 are sign-extended correctly
        instr   = build_I(12'sd5);      // make an I-type with imm=+5
        imm_sel = IMM_I;                // tell DUT to decode I-type
        #1;                             // allow combinational logic to settle
        expect_eq("I  +5", imm_ext, 32'sd5);    // expect +5

        instr   = build_I(-12'sd9);     // imm=−9 (12-bit signed)
        imm_sel = IMM_I;
        #1;
        expect_eq("I  -9", imm_ext, -32'sd9);   // expect −9 sign-extended to 32 bits

        // --- S-type tests: check store offset packing and sign extension
        instr   = build_S(12'sd84);     // imm=+84 (0x54)
        imm_sel = IMM_S;
        #1;
        expect_eq("S +84", imm_ext, 32'sd84);

        instr   = build_S(-12'sd16);    // imm=−16
        imm_sel = IMM_S;
        #1;
        expect_eq("S -16", imm_ext, -32'sd16);

        // --- B-type tests: branch byte offsets (+8 forward, −4 back)
        // For branches, immediates are multiples of 2 bytes; force imm[0]=0.
        b_plus8  = 13'sd8;  
        b_minus4 = -13'sd4; 

        instr   = build_B(b_plus8);     // encode +8 into B-type fields
        imm_sel = IMM_B;                // decode as B-type
        #1;
        expect_eq("B  +8", imm_ext, 32'sd8);     // expect +8

        instr   = build_B(b_minus4);    // encode −4 into B-type fields
        imm_sel = IMM_B;
        #1;
        expect_eq("B  -4", imm_ext, -32'sd4);    // expect −4

        // --- J-type tests: jump byte offsets (+16 forward, −8 back)
        // J immediates are also multiples of 2; ensure imm[0]=0.
        j_plus16 = 21'sd16;  
        j_minus8 = -21'sd8;

        instr   = build_J(j_plus16);    // encode +16
        imm_sel = IMM_J;                // decode as J-type
        #1;
        expect_eq("J +16", imm_ext, 32'sd16);

        instr   = build_J(j_minus8);    // encode −8
        imm_sel = IMM_J;
        #1;
        expect_eq("J  -8", imm_ext, -32'sd8);

        // All checks done
        $display("imm_extend tests PASS");  // friendly summary line
        $finish;                            // end simulation cleanly
    end

endmodule
