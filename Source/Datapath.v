module Datapath (
    input  wire        clk, reset,
    input  wire [31:0] instrf, readdatam,
    output wire [31:0] pcf, aluresultm, writedatam,
    output wire        memwritem,

    input  wire        regwrited, memwrited, jumpd, branchd, alusrcd,
    input  wire [1:0]  resultsrcd,
    input  wire [2:0]  alucontrold, immsrcd,

    output wire [6:0]  opd,
    output wire [2:0]  funct3d,
    output wire        funct7b5d,
    output wire        stallf, stalld, flushd, flushe,
    output wire        pcsrce
);
    wire [31:0] pcnext, pcplus4f, pctargete;
    wire [31:0] instrd, pcd, pcplus4d, rd1d, rd2d, immextd;
    wire [31:0] rd1e, rd2e, pce, pcplus4e, immexte;
    wire [31:0] srcae, srcbe, aluresulte, writedatae, srcae_forwarded, writedatae_forwarded;
    wire [31:0] pcplus4m, pcplus4w, aluresultw, readdataw, resultw;
    wire [4:0]  rs1d, rs2d, rd_d, rs1e, rs2e, rde, rdm, rdw;
    wire [2:0]  alucontrole, funct3e;
    wire [1:0]  resultsrce, resultsrcm, resultsrcw;
    wire [1:0]  forwardae, forwardbe;
    wire        regwritee, memwritee, jumpe, branche, alusrce, zeroe;
    wire        regwritem, regwritew, resultsrce0;
    wire        pcsrce_internal;

    // --- FETCH STAGE ---
    Mux2 #(32) pcmux (pcplus4f, pctargete, pcsrce_internal, pcnext);
    FlopRC #(32) pcreg (clk, reset, ~stallf, 1'b0, pcnext, pcf);
    Adder pcadd (pcf, 32'd4, pcplus4f);

    // --- FETCH / DECODE REG ---
    FlopRC #(32) fd_instr (clk, reset, ~stalld, flushd, instrf,   instrd);
    FlopRC #(32) fd_pc    (clk, reset, ~stalld, flushd, pcf,      pcd);
    FlopRC #(32) fd_pc4   (clk, reset, ~stalld, flushd, pcplus4f, pcplus4d);

    // --- DECODE STAGE ---
    assign opd = instrd[6:0];
    assign funct3d = instrd[14:12];
    assign funct7b5d = instrd[30];
    assign rs1d = instrd[19:15];
    assign rs2d = instrd[24:20];
    assign rd_d = instrd[11:7];

    RegFile rf (clk, regwritew, rs1d, rs2d, rdw, resultw, rd1d, rd2d);
    Extend ext (instrd[31:7], immsrcd, immextd);

    // --- DECODE / EXECUTE REG ---
    FlopC #(1)  de_rw  (clk, reset, flushe, regwrited,   regwritee);
    FlopC #(2)  de_rs  (clk, reset, flushe, resultsrcd,  resultsrce);
    FlopC #(1)  de_mw  (clk, reset, flushe, memwrited,   memwritee);
    FlopC #(1)  de_jp  (clk, reset, flushe, jumpd,       jumpe);
    FlopC #(1)  de_br  (clk, reset, flushe, branchd,     branche);
    FlopC #(3)  de_ac  (clk, reset, flushe, alucontrold, alucontrole);
    FlopC #(1)  de_as  (clk, reset, flushe, alusrcd,     alusrce);
    FlopC #(32) de_rd1 (clk, reset, flushe, rd1d,        rd1e);
    FlopC #(32) de_rd2 (clk, reset, flushe, rd2d,        rd2e);
    FlopC #(32) de_pc  (clk, reset, flushe, pcd,         pce);
    FlopC #(5)  de_rs1 (clk, reset, flushe, rs1d,        rs1e);
    FlopC #(5)  de_rs2 (clk, reset, flushe, rs2d,        rs2e);
    FlopC #(5)  de_rd  (clk, reset, flushe, rd_d,        rde);
    FlopC #(32) de_imm (clk, reset, flushe, immextd,     immexte);
    FlopC #(32) de_pc4 (clk, reset, flushe, pcplus4d,    pcplus4e);
    FlopC #(3)  de_f3  (clk, reset, flushe, funct3d,     funct3e); 

    // --- EXECUTE STAGE ---
    Mux3 #(32) fwd_a_mux (rd1e, resultw, aluresultm, forwardae, srcae_forwarded);
    Mux3 #(32) fwd_b_mux (rd2e, resultw, aluresultm, forwardbe, writedatae_forwarded);
    assign srcae = srcae_forwarded;
    assign writedatae = writedatae_forwarded;
    Mux2 #(32) srcb_mux (writedatae, immexte, alusrce, srcbe);
    
    ALU alu (srcae, srcbe, alucontrole, aluresulte, zeroe);
    
    // PC Target Logic
    wire [31:0] branch_target;
    Adder branch_adder (pce, immexte, branch_target);
    assign pctargete = (alucontrole == 3'b000 && jumpe && alusrce) ? aluresulte : branch_target;

    // PCSrc Logic
    reg branch_cond;
    always @(*) begin
        if (funct3e == 3'b001) branch_cond = ~zeroe; // BNE
        else branch_cond = zeroe;                    // BEQ
    end
    assign pcsrce_internal = (branche & branch_cond) | jumpe;
    assign pcsrce = pcsrce_internal;
    assign resultsrce0 = resultsrce[0];

    // Hazard Unit Instantiation
    HazardUnit hu (
        .rs1d(rs1d), .rs2d(rs2d), .rs1e(rs1e), .rs2e(rs2e),
        .rde(rde), .rdm(rdm), .rdw(rdw),
        .regwritem(regwritem), .regwritew(regwritew),
        .resultsrce0(resultsrce0), .pcsrce(pcsrce_internal),
        .forwardae(forwardae), .forwardbe(forwardbe),
        .stallf(stallf), .stalld(stalld), .flushd(flushd), .flushe(flushe)
    );

    // --- EXECUTE / MEMORY REG ---
    FlopRC #(1)  em_rw  (clk, reset, 1'b1, 1'b0, regwritee,  regwritem);
    FlopRC #(2)  em_rs  (clk, reset, 1'b1, 1'b0, resultsrce, resultsrcm);
    FlopRC #(1)  em_mw  (clk, reset, 1'b1, 1'b0, memwritee,  memwritem);
    FlopRC #(32) em_alu (clk, reset, 1'b1, 1'b0, aluresulte, aluresultm);
    FlopRC #(32) em_wd  (clk, reset, 1'b1, 1'b0, writedatae, writedatam);
    FlopRC #(5)  em_rd  (clk, reset, 1'b1, 1'b0, rde,        rdm);
    FlopRC #(32) em_pc4 (clk, reset, 1'b1, 1'b0, pcplus4e,   pcplus4m);

    // --- MEMORY / WRITEBACK REG ---
    FlopRC #(1)  mw_rw   (clk, reset, 1'b1, 1'b0, regwritem,  regwritew);
    FlopRC #(2)  mw_rs   (clk, reset, 1'b1, 1'b0, resultsrcm, resultsrcw);
    FlopRC #(32) mw_alu  (clk, reset, 1'b1, 1'b0, aluresultm, aluresultw);
    FlopRC #(32) mw_rd   (clk, reset, 1'b1, 1'b0, readdatam,  readdataw);
    FlopRC #(5)  mw_rd_r (clk, reset, 1'b1, 1'b0, rdm,        rdw);
    FlopRC #(32) mw_pc4  (clk, reset, 1'b1, 1'b0, pcplus4m,   pcplus4w);

    // --- WRITEBACK STAGE ---
    Mux3 #(32) res_mux (aluresultw, readdataw, pcplus4w, resultsrcw, resultw);

endmodule