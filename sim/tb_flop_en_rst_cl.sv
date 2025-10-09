`timescale 1ns/1ps
module tb_flop_en_rst_cl;
    localparam int W = 8;

    logic clk=0, rst=0, en=0, clr=0;
    logic [W-1:0] d=0, q;

    // DUT: reset=0xAA, clear=0x55 to see them easily
    flop_en_rst_cl #(
        .WIDTH(W),
        .RESET_VAL(8'hAA),
        .CLEAR_VAL(8'h55)
    ) dut (.clk(clk), .rst(rst), .en(en), .clr(clr), .d(d), .q(q));

    always #5 clk = ~clk;

    task check(string MSG, bit COND); if (!COND) $fatal(1, "%s FAIL", MSG); else $display("%s PASS", MSG); endtask

    initial begin
        // 1. Reset wins
        rst=1; d=8'h11; en=1; clr=0; @(posedge clk); #1;
        check("reset value", q==8'hAA);

        // 2. Clear wins over enable
        rst=0; clr=1; en=1; d=8'h22; @(posedge clk); #1;
        check("clear value", q==8'h55);

        // 3. Enable updates when 1, holds when 0
        clr=0; en=1; d=8'h33; @(posedge clk); #1;
        check("en=1 updates", q==8'h33);
        en=0; d=8'h44; @(posedge clk); #1;
        check("en=0 holds", q==8'h33);

        // 4. Clear during stall (en=0) still clears
        en=0; clr=1; d=8'h77; @(posedge clk); #1; clr=0;
        check("clear during stall", q==8'h55);

        $display("tb_flop_en_rst_cl: PASS"); $finish;
    end
endmodule
