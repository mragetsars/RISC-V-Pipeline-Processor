module InstMemory(input wire [31:0] a, output wire [31:0] rd);
    reg [31:0] RAM[63:0];
    initial $readmemh("program.mem", RAM);

    assign rd = RAM[a[31:2]];
endmodule

module DataMemory(input wire clk, we, input wire [31:0] a, wd, output wire [31:0] rd);
    reg [31:0] RAM[63:0];
    initial $readmemh("data.mem", RAM);

    assign rd = RAM[a[31:2]];

    always @(posedge clk) begin
        if (we) RAM[a[31:2]] <= wd;
    end
endmodule