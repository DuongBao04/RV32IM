`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2025 05:02:19 PM
// Design Name: 
// Module Name: ALU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "defines.vh"
module ALU(
    input   [`REG_SIZE:0]  A, B,
    input   [4:0]   ALUCtrl,
    output  reg [`REG_SIZE:0] ALUResult,
    output  reg     Zero,
    output  reg     LessThan,
    output  reg     LessThanU
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
    wire Cout;

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
    
    assign and_result = A & B;
    assign or_result  = A | B;
    assign xor_result = A ^ B;

    assign lls_result = A << B[4:0];
    assign lrs_result = A >> B[4:0];
    assign ars_result = $signed(A) >>> B[4:0];

    assign {Cout, sub_result} = {1'b0, A} + ~{1'b0, B} + 1'b1;

    wire lt_signed  = ($signed(A) <  $signed(B));
    wire lt_unsigned = (A < B);
    wire zero_flag = (sub_result == 32'b0);

    always @(*) begin
        LessThan  <= lt_signed;
        LessThanU <= lt_unsigned;
        Zero <= zero_flag;

        case(ALUCtrl)
            `ALU_AND:           ALUResult <= and_result;
            `ALU_OR:            ALUResult <= or_result;
            `ALU_ADD:           ALUResult <= add_result;
            `ALU_XOR:           ALUResult <= xor_result;
            `ALU_SUB:           ALUResult <= sub_result;
            `ALU_LSHIFT_LEFT:   ALUResult <= lls_result;
            `ALU_LSHIFT_RIGHT:  ALUResult <= lrs_result;
            `ALU_ASHIFT_RIGHT:  ALUResult <= ars_result;
            `ALU_SLT:           ALUResult <= {31'b0, lt_signed};
            `ALU_SLTU:          ALUResult <= {31'b0, lt_unsigned};
            `ALU_MUL,
            `ALU_MULH,
            `ALU_MULSU,
            `ALU_MULU:          ALUResult <= mul_result;
            default:            ALUResult <= 32'd0;
        endcase
    end
endmodule

