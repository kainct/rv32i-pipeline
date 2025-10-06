package riscv_pkg;

    // ---------- Core width
    localparam int XLEN = 32;

    // ---------- Common constants
    localparam logic [4:0]  X0 = 5'd0;
    localparam logic [XLEN-1:0] INSTR_NOP = 32'h0000_0013; // ADDI x0,x0,0
    localparam logic [XLEN-1:0] RESET_PC  = 32'h0000_0000;

    // ---------- ALU operation encoding
    typedef enum logic [2:0] {
        ALU_ADD = 3'b000,
        ALU_SUB = 3'b001,
        ALU_AND = 3'b010,
        ALU_OR  = 3'b011,
        ALU_SLT = 3'b101
    } alu_op_e;

    // ---------- Immediate source (I/S/B/J)
    typedef enum logic [1:0] {
        IMM_I = 2'b00,
        IMM_S = 2'b01,
        IMM_B = 2'b10,
        IMM_J = 2'b11
    } imm_src_e;

    // ---------- 7-bit opcodes (bits [6:0])
    localparam logic [6:0]
        OP_RTYPE  = 7'b0110011,  // add, sub, and, or, slt, ...
        OP_ITYPE  = 7'b0010011,  // addi, andi, ori, ...
        OP_LOAD   = 7'b0000011,  // lw
        OP_STORE  = 7'b0100011,  // sw
        OP_BRANCH = 7'b1100011,  // beq (and others like bne)
        OP_JAL    = 7'b1101111;  // jal

    // ---------- 3-bit funct3 values (bits [14:12]) for the ops
    localparam logic [2:0]
        F3_ADD_SUB = 3'b000,    // add/sub (R-type) and addi (I-type)
        F3_BEQ     = 3'b000,     // beq
        F3_AND     = 3'b111,    // and / andi
        F3_OR      = 3'b110,    // or  / ori
        F3_SLT     = 3'b010,    // slt
        F3_LW_SW   = 3'b010;     // sw / lw

    // ---------- Superset control bundle; stages ignore what they don't need
    typedef struct packed {
        logic         RegWrite;
        logic   [1:0] ResultSrc;  // 00=ALU 01=Mem 10=PC+4
        logic         MemWrite;
        logic         Jump;
        logic         Branch;
        alu_op_e      ALUControl;
        logic         ALUSrc;
        imm_src_e     ImmSrc;     // I/S/B/J
    } ctrl_s;

    // ---------- Datapath bundle commonly passed ID->EX
    typedef struct packed {
        logic [XLEN-1:0] RD1;
        logic [XLEN-1:0] RD2;
        logic [XLEN-1:0] PC;
        logic [4:0]      Rs1, Rs2, Rd;
        logic [XLEN-1:0] ExtImm;
        logic [XLEN-1:0] PCPlus4;
    } data_s;

endpackage : riscv_pkg