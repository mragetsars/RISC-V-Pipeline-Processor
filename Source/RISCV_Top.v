module RISCV_Top (
    input  wire        clk, reset,
    output wire [31:0] writedata, dataadr,
    output wire        memwrite
);
    wire [31:0] pc, instr, readdata;
    wire        regwrited, memwrited, jumpd, branchd, alusrcd;
    wire [1:0]  resultsrcd;
    wire [2:0]  alucontrold, immsrcd;
    wire [6:0]  opd;
    wire [2:0]  funct3d;
    wire        funct7b5d;
    wire        stallf, stalld, flushd, flushe;

    ControlUnit cu (
        .op(opd), .funct3(funct3d), .funct7b5(funct7b5d),
        .resultsrc(resultsrcd), .memwrite(memwrited), .alusrc(alusrcd),
        .immsrc(immsrcd), .regwrite(regwrited), .alucontrol(alucontrold),
        .jump(jumpd), .branch(branchd)
    );

    Datapath dp (
        .clk(clk), .reset(reset),
        .instrf(instr), .readdatam(readdata),
        .pcf(pc), .aluresultm(dataadr), .writedatam(writedata), .memwritem(memwrite),
        .regwrited(regwrited), .memwrited(memwrited), .jumpd(jumpd),
        .branchd(branchd), .alusrcd(alusrcd), .resultsrcd(resultsrcd),
        .alucontrold(alucontrold), .immsrcd(immsrcd),
        .opd(opd), .funct3d(funct3d), .funct7b5d(funct7b5d),
        .stallf(stallf), .stalld(stalld), .flushd(flushd), .flushe(flushe),
        .pcsrce()
    );

    InstMemory imem (.a(pc), .rd(instr));
    DataMemory dmem (.clk(clk), .we(memwrite), .a(dataadr), .wd(writedata), .rd(readdata));

endmodule