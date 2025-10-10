`timescale 1ns/1ps

module fpga_top (
    input  logic        CLK100MHZ,   // Basys3 100 MHz clock
    input  logic        rst_BTN,     // active-high reset (center button)
    output logic [15:0] LED          // 16 user LEDs
);
    // -------- DUT (your pipelined core) --------
    logic [31:0] ALUResultM;
    logic [31:0] WriteDataM;
    logic        MemWriteM;

    top u_top (
        .clk        (CLK100MHZ),
        .rst        (rst_BTN),
        .WriteDataM (WriteDataM),
        .ALUResultM (ALUResultM),
        .MemWriteM  (MemWriteM)
    );

    // -------- Latch the last store so LEDs stay readable --------
    logic [7:0] lat_wd;
    logic [7:0] lat_addr;

    always_ff @(posedge CLK100MHZ) begin
        if (rst_BTN) begin
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
