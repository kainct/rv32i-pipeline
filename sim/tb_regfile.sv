`timescale 1ns/1ps           

module tb_regfile;          
    import riscv_pkg::*;       

    // ---------- Clock generation (100 MHz)

    logic clk = 0;             
    always #5 clk = ~clk;      

    // ---------- DUT (Device Under Test) I/O signals

    logic        we3;          // Write enable for write port
    logic [4:0]  a1, a2, a3;   // a1=rs1 read addr, a2=rs2 read addr, a3=rd write addr
    logic [31:0] wd3;          // Write data (RV32 so 32-bit in TB)
    logic [31:0] rd1, rd2;     // Read data outputs

    // ---------- Instantiate the register file

    regfile dut (
        .clk (clk),
        .we3 (we3),
        .a1  (a1),
        .a2  (a2),
        .a3  (a3),
        .wd3 (wd3),
        .rd1 (rd1),
        .rd2 (rd2)
    );

    // ---------- Helper tasks (to keep the main sequence readable)

    // ---------- Write one register (synchronous write on next clock edge)

    task automatic write_reg(input logic [4:0] rd,
                             input logic [31:0] data
                             );
        @(posedge clk);          // Wait for a rising edge to set up signals
        we3 = 1;                 // Enable write
        a3  = rd;                // Destination register index
        wd3 = data;              // Data to write
        @(posedge clk);          // On this edge the DUT performs the write
        we3 = 0;                 // Disable write to avoid accidental extra writes
    endtask

    // ---------- Read two registers (combinational read; returns after a small delay)

    task automatic read_regs(input  logic [4:0] rs1,
                             input logic [4:0] rs2,
                             output logic [31:0] r1, 
                             output logic [31:0] r2
                             );
        a1 = rs1;                // Select read port 1 address
        a2 = rs2;                // Select read port 2 address
        #1;                      // Allow combinational path to settle
        r1 = rd1;                // Capture read data 1
        r2 = rd2;                // Capture read data 2
    endtask

    // ---------- Expect equality checker (prints PASS or kills sim with a message)

    task automatic expect_eq(input string name,
                             input logic [31:0] got, exp
                             );
        if (got !== exp) begin
        $fatal(1, "%s: got 0x%08x, exp 0x%08x", name, got, exp); // Fail fast
        end else begin
        $display("%s: PASS (0x%08x)", name, got);                 // Nice PASS line
        end
    endtask
    
    
    // Local vars to hold readback values
    logic [31:0] r1, r2;
        
    // --------- Main test sequence

    initial begin

        // Initialize TB-driven signals
        we3 = 0; a1 = '0; a2 = '0; a3 = '0; wd3 = '0;

        // ---------- 1. x0 invariants: reads as 0; writes ignored

        read_regs(5'd0, 5'd0, r1, r2);              // Read x0 on both ports
        expect_eq("x0 initial rd1", r1, '0);        // Must be 0
        expect_eq("x0 initial rd2", r2, '0);        // Must be 0

        write_reg(5'd0, 32'hDEAD_BEEF);             // Try to write x0 (should be ignored)
        read_regs(5'd0, 5'd0, r1, r2);              // Read x0 again
        expect_eq("x0 after write rd1", r1, '0);
        expect_eq("x0 after write rd2", r2, '0);

        // ---------- 2. Basic write/read: x5 

        write_reg(5'd5, 32'h1111_1111);             // Write x5
        read_regs(5'd5, 5'd5, r1, r2);              // Read x5 on both ports
        expect_eq("x5 readback rd1", r1, 32'h1111_1111);
        expect_eq("x5 readback rd2", r2, 32'h1111_1111);

        // ---------- 3. Same-cycle write-through (read-during-write)

        // This checks the regfile's internal bypass:
        // During the cycle we assert write enable to x10, the combinational reads
        // from x10 should already reflect wd3 (new value), not the old rf entry.

        @(posedge clk);                                     // Start a fresh cycle
        we3 = 1;  a3 = 5'd10;  wd3 = 32'hFFFF_FFFF;         // Drive write controls/data
        a1  = 5'd10; a2 = 5'd10;                            // Read x10 in the SAME cycle
        #1;                                                 // Let the read mux settle
        expect_eq("x10 same-cycle rd1", rd1, 32'hFFFF_FFFF);
        expect_eq("x10 same-cycle rd2", rd2, 32'hFFFF_FFFF);
        @(posedge clk) we3 = 0;                             // Commit write on this edge, then drop WE

        // ---------- 4. Back-to-back writes: x11 then x12 

        write_reg(5'd11, 32'h1111_1111);
        write_reg(5'd12, 32'h2222_2222);
        read_regs(5'd11, 5'd12, r1, r2);
        expect_eq("x11 readback", r1, 32'h1111_1111);
        expect_eq("x12 readback", r2, 32'h2222_2222);

        // ---------- 5. Independent read ports (different regs)

        write_reg(5'd20, 32'h1234_5678);
        write_reg(5'd21, 32'h89AB_CDEF);
        read_regs(5'd20, 5'd21, r1, r2);
        expect_eq("rd1=x20", r1, 32'h1234_5678);
        expect_eq("rd2=x21", r2, 32'h89AB_CDEF);

        // ---------- 6. Read-after-write next cycle (sanity)

        write_reg(5'd7, 32'h5555_5555);
        read_regs(5'd7, 5'd0, r1, r2);
        expect_eq("x7 next-cycle readback", r1, 32'h5555_5555);

        // ---------- All checks passed

        $display("regfile tests PASS");
        $finish;                                 
    end
endmodule