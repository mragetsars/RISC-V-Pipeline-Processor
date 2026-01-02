module RegFile (
    input  wire        clk,
    input  wire        we3,
    input  wire [4:0]  a1, a2, a3,
    input  wire [31:0] wd3,
    output wire [31:0] rd1, rd2
);
    reg [31:0] rf[31:0];

    always @(negedge clk) begin
        if (we3 && a3 != 0) rf[a3] <= wd3;
    end

    assign rd1 = (a1 != 0) ? rf[a1] : 32'b0;
    assign rd2 = (a2 != 0) ? rf[a2] : 32'b0;
endmodule

module ALU (
    input  wire [31:0] srca, srcb,
    input  wire [2:0]  alucontrol,
    output reg  [31:0] aluresult,
    output wire        zero
);
    always @(*) begin
        case (alucontrol)
            3'b000: aluresult = srca + srcb;                                     // Add
            3'b001: aluresult = srca - srcb;                                     // Sub
            3'b010: aluresult = srca & srcb;                                     // And
            3'b011: aluresult = srca | srcb;                                     // Or
            3'b100: aluresult = srca ^ srcb;                                     // Xor
            3'b101: aluresult = ($signed(srca) < $signed(srcb)) ? 32'b1 : 32'b0; // Slt
            3'b110: aluresult = srcb;                                            // Lui
            default: aluresult = 32'bx;
        endcase
    end
    assign zero = (aluresult == 32'b0);
endmodule

module Extend (
    input  wire [31:7] instr,
    input  wire [2:0]  immsrc,
    output reg  [31:0] immext
);
    always @(*) begin
        case (immsrc)
            3'b000: immext = {{20{instr[31]}}, instr[31:20]};                                         // I-type
            3'b001: immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};                            // S-type
            3'b010: immext = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}; // B-type
            3'b011: immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};          // J-type
            3'b100: immext = {instr[31:12], 12'b0};                                                   // U-type
            default: immext = 32'bx;
        endcase
    end
endmodule

module Adder (
    input  wire [31:0] a, b,
    output wire [31:0] y
);
    assign y = a + b;
endmodule

module Mux2 #(parameter WIDTH = 32) (
    input  wire [WIDTH-1:0] d0, d1,
    input  wire             s,
    output wire [WIDTH-1:0] y
);
    assign y = s ? d1 : d0;
endmodule

module Mux3 #(parameter WIDTH = 32) (
    input  wire [WIDTH-1:0] d0, d1, d2,
    input  wire [1:0]       s,
    output wire [WIDTH-1:0] y
);
    assign y = (s == 2'b10) ? d2 : ((s == 2'b01) ? d1 : d0);
endmodule

module FlopRC #(parameter WIDTH = 32) (
    input  wire             clk, reset,
    input  wire             en, clear,
    input  wire [WIDTH-1:0] d,
    output reg  [WIDTH-1:0] q
);
    always @(posedge clk or posedge reset) begin
        if (reset)          q <= 0;
        else if (clear)     q <= 0;
        else if (en)        q <= d;
    end
endmodule

module FlopC #(parameter WIDTH = 32) (
    input  wire             clk, reset,
    input  wire             clear,
    input  wire [WIDTH-1:0] d,
    output reg  [WIDTH-1:0] q
);
    always @(posedge clk or posedge reset) begin
        if (reset)      q <= 0;
        else if (clear) q <= 0;
        else            q <= d;
    end
endmodule