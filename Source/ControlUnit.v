module ControlUnit (
    input  wire [6:0] op,
    input  wire [2:0] funct3,
    input  wire       funct7b5,
    output reg  [1:0] resultsrc,
    output reg        memwrite,
    output reg        alusrc,
    output reg  [2:0] immsrc,
    output reg        regwrite,
    output reg  [2:0] alucontrol,
    output reg        jump,
    output reg        branch
);
    reg [1:0] aluop;

    // Main Decoder
    always @(*) begin
        regwrite = 0; immsrc = 3'b000; alusrc = 0; memwrite = 0;
        resultsrc = 2'b00; branch = 0; aluop = 2'b00; jump = 0;

        case (op)
            7'b0110011: begin // R-Type
                regwrite = 1; aluop = 2'b10;
            end
            7'b0010011: begin // I-Type
                regwrite = 1; alusrc = 1; aluop = 2'b10;
            end
            7'b0000011: begin // lw
                regwrite = 1; alusrc = 1; immsrc = 3'b000; aluop = 2'b00; resultsrc = 2'b01;
            end
            7'b0100011: begin // sw
                memwrite = 1; alusrc = 1; immsrc = 3'b001; aluop = 2'b00;
            end
            7'b1100011: begin // beq, bne
                branch = 1; immsrc = 3'b010; aluop = 2'b01;
            end
            7'b1101111: begin // jal
                jump = 1; regwrite = 1; immsrc = 3'b011; resultsrc = 2'b10; aluop = 2'b00;
            end
            7'b1100111: begin // jalr
                jump = 1; regwrite = 1; alusrc = 1; immsrc = 3'b000; resultsrc = 2'b10; aluop = 2'b00;
            end
            7'b0110111: begin // lui
                regwrite = 1; alusrc = 1; immsrc = 3'b100; aluop = 2'b11;
            end
        endcase
    end

    // ALU Decoder
    always @(*) begin
        case (aluop)
            2'b00: alucontrol = 3'b000; // Add
            2'b01: alucontrol = 3'b001; // Sub
            2'b11: alucontrol = 3'b110; // Lui
            2'b10: begin
                case (funct3)
                    3'b000: if (op == 7'b0110011 && funct7b5) alucontrol = 3'b001; // sub
                            else alucontrol = 3'b000;                              // add
                    3'b010: alucontrol = 3'b101;                                   // slt
                    3'b100: alucontrol = 3'b100;                                   // xor
                    3'b110: alucontrol = 3'b011;                                   // or
                    3'b111: alucontrol = 3'b010;                                   // and
                    default: alucontrol = 3'bxxx;
                endcase
            end
            default: alucontrol = 3'bxxx;
        endcase
    end
endmodule