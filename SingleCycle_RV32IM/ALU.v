`timescale 1ns / 1ps
`include "defines.vh"

module ALU(
    input   [31:0]  A, B,
    input   [5:0]   ALUCtrl,
    output  reg [31:0]  ALUResult,
    output          Zero,
    output          LessThan,
    output          LessThanU
);
    wire [31:0] and_result;
    wire [31:0] or_result;
    wire [31:0] add_result;
    wire [31:0] sub_result;
    wire [31:0] xor_result;
    wire [31:0] lls_result;
    wire [31:0] lrs_result;
    wire [31:0] ars_result;
    wire [31:0] mul_result;
    wire [31:0] div_result;
    wire [31:0] remainder_result;
    wire Cout, is_signed;

    assign is_signed = (ALUCtrl == `ALU_DIV || ALUCtrl == `ALU_REM);

    cla cla_inst (
        .a(A),
        .b(B),
        .cin(1'b0),
        .sum(add_result)
    );

    mul mul_inst (
        .A(A),
        .B(B),
        .ALUCtrl(ALUCtrl),
        .result(mul_result)
    );

    divider_unit div_inst (
        .A(A),
        .B(B),
        .is_signed(is_signed),
        .Q(div_result),
        .R(remainder_result)
    );

    assign and_result = A & B;
    assign or_result  = A | B;
    assign xor_result = A ^ B;

    assign lls_result = A << B[4:0];
    assign lrs_result = A >> B[4:0];
    assign ars_result = $signed(A) >>> B[4:0];

    assign {Cout, sub_result} = {1'b0, A} + ~{1'b0, B} + 1'b1;

    assign LessThan  = ($signed(A) <  $signed(B));
    assign LessThanU = (A < B);
    assign Zero = (sub_result == 32'b0);

    always @(*) begin
        case(ALUCtrl)
            `ALU_AND:           ALUResult = and_result;
            `ALU_OR:            ALUResult = or_result;
            `ALU_ADD:           ALUResult = add_result;
            `ALU_XOR:           ALUResult = xor_result;
            `ALU_SUB:           ALUResult = sub_result;
            `ALU_LSHIFT_LEFT:   ALUResult = lls_result;
            `ALU_LSHIFT_RIGHT:  ALUResult = lrs_result;
            `ALU_ASHIFT_RIGHT:  ALUResult = ars_result;
            `ALU_SLT:           ALUResult = {31'b0, LessThan};
            `ALU_SLTU:          ALUResult = {31'b0, LessThanU};
            `ALU_MUL,
            `ALU_MULH,
            `ALU_MULSU,
            `ALU_MULU:          ALUResult = mul_result;
            `ALU_DIV,
            `ALU_DIVU:          ALUResult = div_result;
            `ALU_REM,
            `ALU_REMU:          ALUResult = remainder_result;
            default:            ALUResult = 32'hxxxx_xxxx;
        endcase
    end

endmodule
