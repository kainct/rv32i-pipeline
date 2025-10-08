`timescale 1ns/1ps

module tb_controller;
    import riscv_pkg::*;

    // ---------------- DUT I/O ----------------
    logic [6:0] opcode;          // instr[6:0]
    logic [2:0] funct_3;         // instr[14:12]
    logic [6:0] funct7;          // instr[31:25]

    logic [1:0] ResultSrcD;
    logic       RegWriteD, MemWriteD;
    logic       JumpD, BranchD;
    logic       ALUSrcD;
    logic [1:0] ImmSrcD;
    logic [2:0] ALUControlD;

    // Device Under Test
    controller dut (
        .opcode       (opcode),
        .funct_3      (funct_3),
        .funct7       (funct7),
        .ResultSrcD   (ResultSrcD),
        .RegWriteD    (RegWriteD),
        .MemWriteD    (MemWriteD),
        .JumpD        (JumpD),
        .BranchD      (BranchD),
        .ALUSrcD      (ALUSrcD),
        .ImmSrcD      (ImmSrcD),
        .ALUControlD  (ALUControlD)
    );

    // Encodings used by ResultSrcD (matches your decoder)
    localparam logic [1:0]  RSRC_ALU = 2'b00,
                            RSRC_MEM = 2'b01,
                            RSRC_PC4 = 2'b10;

    // -------------- helpers --------------
    
    // Define a text macro named CHECK that takes two arguments:
    //   MSG:  a string label to print (e.g., "R ADD")
    //   COND: a boolean expression we expect to be true
    `define CHECK(MSG, COND) if (!(COND)) $fatal(1, "%s: FAIL", MSG); else $display("%s: PASS", MSG)


    task automatic clear_fields();
        opcode  = 7'h00;
        funct_3 = 3'b000;
        funct7  = 7'b0000000;
        #1; // settle
    endtask

    // ---------------- tests ----------------
    initial begin
        $display("tb_controller: start");
        clear_fields();

        // ---- R-type: ADD ----
        opcode  = OP_RTYPE;
        funct_3 = F3_ADD_SUB;
        funct7  = 7'b0000000;     // ADD
        #1;
        `CHECK("R ADD RegWrite",   RegWriteD == 1);
        `CHECK("R ADD ResultSrc",  ResultSrcD == RSRC_ALU);
        `CHECK("R ADD ALUSrc",     ALUSrcD == 0);
        `CHECK("R ADD ALU_ADD",    ALUControlD == ALU_ADD);
        `CHECK("R ADD no mem/jmp", !MemWriteD && !JumpD && !BranchD);

        // ---- R-type: SUB ----
        funct7  = 7'b0100000;     // SUB pattern (bit5=1)
        #1;
        `CHECK("R SUB ALU_SUB",    ALUControlD == ALU_SUB);

        // ---- R-type: AND/OR/SLT ----
        funct7  = 7'b0000000;     // back to non-sub
        funct_3 = F3_AND; #1; `CHECK("R AND", ALUControlD == ALU_AND);
        funct_3 = F3_OR ; #1; `CHECK("R OR",  ALUControlD == ALU_OR );
        funct_3 = F3_SLT; #1; `CHECK("R SLT", ALUControlD == ALU_SLT);

        // ---- I-type ALU: ORI (ALUSrc=imm, no SUB) ----
        opcode  = OP_ITYPE;
        funct_3 = F3_OR;
        // funct7 is don't-care for I-type; even if bit5=1, opcode[5]=0 prevents R-type SUB detection
        funct7  = 7'b0100000;
        #1;
        `CHECK("I ORI RegWrite",   RegWriteD == 1);
        `CHECK("I ORI ResultSrc",  ResultSrcD == RSRC_ALU);
        `CHECK("I ORI ALUSrc",     ALUSrcD == 1);
        `CHECK("I ORI ImmSrc=I",   ImmSrcD == IMM_I);
        `CHECK("I ORI ALU_OR",     ALUControlD == ALU_OR);

        // ---- LOAD: LW ----
        opcode  = OP_LOAD;
        funct_3 = 3'b010;         // word
        funct7  = 7'b0000000;
        #1;
        `CHECK("LW RegWrite",      RegWriteD == 1);
        `CHECK("LW ResultSrc=MEM", ResultSrcD == RSRC_MEM);
        `CHECK("LW ALUSrc=imm",    ALUSrcD == 1);
        `CHECK("LW ImmSrc=I",      ImmSrcD == IMM_I);
        `CHECK("LW ALU=ADD",       ALUControlD == ALU_ADD);

        // ---- STORE: SW ----
        opcode  = OP_STORE;
        funct_3 = 3'b010;         // word
        #1;
        `CHECK("SW MemWrite",      MemWriteD == 1);
        `CHECK("SW ALUSrc=imm",    ALUSrcD == 1);
        `CHECK("SW ImmSrc=S",      ImmSrcD == IMM_S);
        `CHECK("SW ALU=ADD",       ALUControlD == ALU_ADD);

        // ---- BRANCH: BEQ ----
        opcode  = OP_BRANCH;
        funct_3 = F3_ADD_SUB;     // beq uses funct3=000
        #1;
        `CHECK("BEQ Branch",       BranchD == 1);
        `CHECK("BEQ ALUSrc=rs2",   ALUSrcD == 0);
        `CHECK("BEQ ImmSrc=B",     ImmSrcD == IMM_B);
        `CHECK("BEQ ALU=SUB",      ALUControlD == ALU_SUB);

        // ---- JUMP: JAL ----
        opcode  = OP_JAL;
        funct_3 = 3'b000;
        #1;
        `CHECK("JAL Jump",         JumpD == 1);
        `CHECK("JAL RegWrite",     RegWriteD == 1);
        `CHECK("JAL ResultSrc=PC4",ResultSrcD == RSRC_PC4);
        `CHECK("JAL ImmSrc=J",     ImmSrcD == IMM_J);

        $display("tb_controller: PASS");
        $finish;
    end
endmodule
