`timescale 1ns/1ps

module imem #(
    parameter int    XLEN        = riscv_pkg::XLEN,
    parameter int    DEPTH_WORDS = 64,
    parameter string MEMFILE     = ""          // optional: $readmemh file
    )(
    input  logic [XLEN-1:0] addr,              // byte address (PC)
    output logic [31:0]     r_d                // 32-bit instruction
    );
    import riscv_pkg::*;

    // ROM storage
    logic [31:0] mem [0:DEPTH_WORDS-1]; //fill addresses in increasing order

    // Optional preload from file; otherwise, hardcode
    initial begin
        // default NOPs to avoid Xs in sim
        for (int i = 0; i < DEPTH_WORDS; i++) mem[i] = INSTR_NOP;

        if (MEMFILE != "") begin
        $readmemh(MEMFILE, mem);
        end 
        else begin
        
        //OFFICIAL TEST PROGRAM
        mem[0]  = 32'h0050_0113;
        mem[1]  = 32'h00C0_0193;
        mem[2]  = 32'hFF71_8393;
        mem[3]  = 32'h0023_E233;
        mem[4]  = 32'h0041_F2B3;
        mem[5]  = 32'h0042_82B3;
        mem[6]  = 32'h0272_8863;
        mem[7]  = 32'h0041_A233;
        mem[8]  = 32'h0002_0463;
        mem[9]  = 32'h0000_0293;
        mem[10] = 32'h0023_A233;
        mem[11] = 32'h0052_03B3;
        mem[12] = 32'h4023_83B3;
        mem[13] = 32'h0471_AA23;
        mem[14] = 32'h0600_2103;
        mem[15] = 32'h0051_04B3;
        mem[16] = 32'h0080_01EF;
        mem[17] = 32'h0010_0113;
        mem[18] = 32'h0091_0133;
        mem[19] = 32'h0221_A023;
        mem[20] = 32'h0021_0063;
        end
        
        /*
        //HAZARD FREE TEST PROGRAM
        mem[0]  = 32'h0010_0093; // addi x1,  x0, 1
        mem[1]  = 32'h0020_0113; // addi x2,  x0, 2
        mem[2]  = 32'h0030_0193; // addi x3,  x0, 3
        mem[3]  = 32'h0040_0213; // addi x4,  x0, 4
        mem[4]  = 32'h0050_0293; // addi x5,  x0, 5
        mem[5]  = 32'h0060_0313; // addi x6,  x0, 6
        mem[6]  = 32'h0070_0393; // addi x7,  x0, 7
        mem[7]  = 32'h0080_0413; // addi x8,  x0, 8
        mem[8]  = 32'h0090_0493; // addi x9,  x0, 9
        mem[9]  = 32'h00A0_0513; // addi x10, x0, 10

        mem[10] = 32'h0600_0A13; // addi x20, x0, 0x60   ; base addr = 0x60
        mem[11] = 32'h0190_0A93; // addi x21, x0, 25     ; data = 25

        mem[12] = 32'h0000_0013; // addi x0,  x0, 0      ; nop (gap)
        mem[13] = 32'h0000_0013; // addi x0,  x0, 0      ; nop

        mem[14] = 32'h015A_2023; // sw   x21, 0(x20)     ; mem[0x60] = 25
        
        end
        */
    end

    // Word index: use only the address bits you need (avoid over-slicing)

    // Number of address bits needed to index DEPTH_WORDS entries.
    // $clog2(N) returns the smallest k such that 2^k >= N.
    localparam int AW = (DEPTH_WORDS <= 1) ? 1 : $clog2(DEPTH_WORDS);

    // Convert a byte address into a word index.
    // - 32-bit instructions are 4 bytes wide, so word index = addr >> 2.
    // - Drop the two least-significant bits [1:0] (byte offset within a word).
    // - Take exactly AW bits for the memory index so it scales with DEPTH_WORDS.
    wire [AW-1:0] widx = addr[AW+1 : 2]; // drop byte offset bits [1:0]

    // Combinational ROM read
    assign r_d = mem[widx];
endmodule
