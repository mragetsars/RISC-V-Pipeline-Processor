module HazardUnit (
    input  wire [4:0] rs1d, rs2d,
    input  wire [4:0] rs1e, rs2e,
    input  wire [4:0] rde, rdm, rdw,
    input  wire       regwritem, regwritew,
    input  wire       resultsrce0, // Bit 0 of ResultSrcE (1 for Load)
    input  wire       pcsrce,      // Branch taken signal
    
    output reg  [1:0] forwardae, forwardbe,
    output wire       stallf, stalld,
    output wire       flushd, flushe
);
    wire lwstall;

    // Forwarding to SrcA
    always @(*) begin
        if ((rs1e == rdm) && regwritem && (rs1e != 0))
            forwardae = 2'b10; // Forward from Memory Stage
        else if ((rs1e == rdw) && regwritew && (rs1e != 0))
            forwardae = 2'b01; // Forward from Writeback Stage
        else
            forwardae = 2'b00;
    end

    // Forwarding to SrcB
    always @(*) begin
        if ((rs2e == rdm) && regwritem && (rs2e != 0))
            forwardbe = 2'b10;
        else if ((rs2e == rdw) && regwritew && (rs2e != 0))
            forwardbe = 2'b01;
        else
            forwardbe = 2'b00;
    end

    // Load Word Stall
    assign lwstall = resultsrce0 & ((rs1d == rde) | (rs2d == rde));

    assign stallf = lwstall;
    assign stalld = lwstall;

    // Control Hazard Flushing
    assign flushd = pcsrce;
    assign flushe = lwstall | pcsrce;

endmodule