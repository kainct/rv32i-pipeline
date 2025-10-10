`timescale 1ns/1ps
module tb_rv32i_top;
    import riscv_pkg::*;

    logic clk = 0;
    logic rst = 1;

    // DUT
    logic [31:0] WriteDataM;
    logic [31:0] ALUResultM;
    logic        MemWriteM;

    top #(.XLEN(32)) dut (
        .clk        (clk),
        .rst        (rst),
        .WriteDataM (WriteDataM),
        .ALUResultM (ALUResultM),
        .MemWriteM  (MemWriteM)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    // Reset
    initial begin
        rst = 1;
        repeat (4) @(posedge clk);
        rst = 0;
    end

    // Debug print each cycle
    always_ff @(posedge clk) begin
        $display("%0t MEM: we=%0b addr=%0d data=%0d", $time, MemWriteM, ALUResultM, WriteDataM);
    end

    // Check stores
    initial begin
        int cycles = 0;
        wait (!rst);

        forever begin
        @(negedge clk);
        cycles++;

        if (MemWriteM) begin
            if (ALUResultM == 32'd96) begin
                if (WriteDataM !== 32'd7)
                    $fatal(1, "Store @96 expected 7, got %0d (0x%08x)", WriteDataM, WriteDataM);
                    $display("Saw store @96 = 7 OK");
            end
            else if (ALUResultM == 32'd100 && WriteDataM == 32'd25) begin
                $display("Simulation succeeded: mem[100] = 25");
                $finish;
            end
            else begin
                $fatal(1, "Unexpected store: addr=%0d data=%0d (0x%08x)", ALUResultM, WriteDataM, WriteDataM);
            end
        end

        // safety timeout
        if (cycles > 20000) begin
            $fatal(1, "Timeout waiting for expected stores.");
        end
        end
    end
endmodule
