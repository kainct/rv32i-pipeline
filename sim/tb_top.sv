`timescale 1ns/1ps

module tb_top();

    logic        clk;
    logic        rst;

    logic [31:0] WriteDataM, ALUResultM;
    logic        MemWriteM;

  // instantiate device to be tested
    top dut (
        .clk(clk),
        .rst(rst),
        .WriteDataM(WriteDataM),
        .ALUResultM(ALUResultM),
        .MemWriteM(MemWriteM)
        );
  
  // initialize test
    initial begin
        rst <= 1; 
        # 22; 
        rst <= 0;
    end

  // generate clock to sequence tests
    always begin
        clk <= 1; 
        # 5; 
        clk <= 0; 
        # 5;
    end

  // check results
    always @(negedge clk) begin
        if(MemWriteM) begin
            if(ALUResultM === 100 & WriteDataM === 25) begin
                $display("Simulation succeeded");
                $stop;
            end else if (ALUResultM !== 96) begin
                $display("Simulation failed");
                $stop;
            end
        end
    end
    
    // After DUT instantiation
    always_ff @(posedge clk) if (!rst) begin
      $display("%0t PCF=%08x | D: opcode=%02x rs1=%0d rs2=%0d rd=%0d imm=%08x | E: rs1=%0d rs2=%0d rd=%0d ALUSrc=%0b ALUop=%0d A=%08x Bpre=%08x immE=%08x ALUy=%08x | MEM: we=%0b addr=%08x wd=%08x | HZD: lwStall=%0b RSrE_b0=%b StallF=%0b StallD=%0b FlushD=%0b FlushE=%0b",
               $time,
               dut.u_fetch.PCF,
               dut.u_decode.InstrD[6:0],
               dut.u_decode.Rs1D, dut.u_decode.Rs2D, dut.u_decode.RdD, dut.u_decode.ExtImmD,
               dut.u_execute.Rs1E, dut.u_execute.Rs2E, dut.u_execute.RdE,
               dut.u_execute.ctrl_e.ALUSrc,
               dut.u_execute.ctrl_e.ALUControl,
               dut.u_execute.SrcAE,               // if internal, expose or print data_e.RD1
               dut.u_execute.RS2_fwd,             // pre-ALUSrc B (forwarded RS2)
               dut.u_execute.data_e.ExtImm,
               dut.u_execute.ALUResultE,
               dut.u_memory.MemWriteM,
               dut.u_memory.ALUResultM,
               dut.u_memory.WriteDataM,
               ((dut.u_hazard.ResultSrcE_b0===1'b1) && (dut.u_hazard.RdE!=0) &&
                 ((dut.u_hazard.Rs1D==dut.u_hazard.RdE)||(dut.u_hazard.Rs2D==dut.u_hazard.RdE))),
               dut.u_hazard.ResultSrcE_b0,
               dut.u_hazard.StallF, dut.u_hazard.StallD, dut.u_hazard.FlushD, dut.u_hazard.FlushE);
    end
    
    always @(posedge clk) begin
      $display("%0t EX  FwdA=%b FwdB=%b | RD2E=%08x RS2_fwd=%08x SrcBE=%08x ALUSrc=%b",
               $time,
               dut.u_execute.ForwardAE,
               dut.u_execute.ForwardBE,
               dut.u_execute.data_e.RD2,
               dut.u_execute.RS2_fwd,
               dut.u_execute.SrcBE,
               dut.u_execute.ctrl_e.ALUSrc);
    end


endmodule
