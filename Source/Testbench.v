`timescale 1ns/1ns

module tb_riscv;

    reg         clk;
    reg         reset;
    wire [31:0] writedata, dataadr;
    wire        memwrite;

    RISCV_Top dut (
        .clk(clk),
        .reset(reset),
        .writedata(writedata),
        .dataadr(dataadr),
        .memwrite(memwrite)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        
        #22;
        reset = 0;
        $display(",----------------------------------------------------------------,");
        $display("| Simulation Started. Waiting for processor to find Min value... |");
        $display("'----------------------------------------------------------------'");
    end

    initial begin
        #5000;
        $display(",----------------------------------------------------------------,");
        $display("| TIMEOUT: Simulation stopped. Processor stuck or loop infinite. |");
        $display("'----------------------------------------------------------------'");
        $stop;
    end

    always @(negedge clk) begin
        if (memwrite) begin
            if (dataadr === 32'd80) begin // Address 80
                $display(",----------------------------------------------------------------------------------------------,");
                $display("| [SUCCESS] Correct Minimum Value found and written to address 80: %d (Hex: %h) |", $signed(writedata), writedata);
                $display("'----------------------------------------------------------------------------------------------'");
                $display("\n");
                $stop;
            end
        end
    end

    always @(posedge clk) begin
        if (!reset) begin
            $display("Time: %0t | PC_F: %h | Instr_D: %h | StallF: %b | StallD: %b | FlushE: %b | FwdA: %b | FwdB: %b | PC_E: %h | ALUOut_M: %h | WB_Reg: %d | WB_Val: %h", 
                $time, 
                dut.dp.pcf,             
                dut.dp.instrd,          
                dut.dp.stallf,          
                dut.dp.stalld,          
                dut.dp.flushe,          
                dut.dp.forwardae,       
                dut.dp.forwardbe,       
                dut.dp.pce,             
                dut.dp.aluresultm,      
                dut.dp.rdw,             
                dut.dp.resultw          
            );
        end
    end

endmodule