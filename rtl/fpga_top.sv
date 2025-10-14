`timescale 1ns/1ps


module fpga_top (
    input  logic        CLK100MHZ,   // Basys3 100 MHz clock
    input  logic        rst_BTN,     // active-high reset (center button)
    output logic [15:0] LED          // 16 user LEDs
);
    
    // ---- 50 MHz PLL/MMCM ----
    logic clk50, pll_locked;
    
    // If your IP instance name is clk_wiz_0 and ports are clk_in1, clk_out1, reset, locked:
    clk_wiz_0 u_clk (
        .clk_in1 (CLK100MHZ),
        .reset   (rst_BTN),      // async ext reset to the wizard (active high)
        .clk_out1(clk50),        // 50 MHz
        .locked  (pll_locked)
      );
    
    // Hold system in reset until the MMCM locks; also let the button force reset.
    logic rst_sync;
    assign rst_sync = rst_BTN | ~pll_locked;
    
    // -------- DUT (your pipelined core) --------
    logic [31:0] ALUResultM;
    logic [31:0] WriteDataM;
    logic        MemWriteM;

    top u_top (
        .clk        (clk50),
        .rst        (rst_sync),
        .WriteDataM (WriteDataM),
        .ALUResultM (ALUResultM),
        .MemWriteM  (MemWriteM)
    );

    // -------- Latch the last store so LEDs stay readable --------
    logic [7:0] lat_wd;
    logic [7:0] lat_addr;

    always_ff @(posedge clk50) begin
        if (rst_sync) begin
            lat_wd   <= 8'h00;
            lat_addr <= 8'h00;
        end 
        else if (MemWriteM) begin
            lat_wd   <= WriteDataM[7:0];
            lat_addr <= ALUResultM[7:0];
        end
    end

    // Show {addr,data}; also blink MSB on write for activity
    always_comb begin
        LED        = {lat_addr, lat_wd};
        LED[15]    = LED[15] | MemWriteM;
    end

endmodule


