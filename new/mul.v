`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/30/2025 04:26:08 PM
// Design Name: 
// Module Name: mul
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
module mul (
    input  wire [`REG_SIZE:0] A,
    input  wire [`REG_SIZE:0] B,
    input  wire [4:0]  ALUCtrl,
    output reg  [`REG_SIZE:0] result
);

    // SIGN-EXTEND và ZERO-EXTEND
    wire signed [63:0] A_s = {{32{A[31]}}, A};
    wire signed [63:0] B_s = {{32{B[31]}}, B};

    wire [63:0]        A_u = {32'b0, A};
    wire [63:0]        B_u = {32'b0, B};

    wire signed [63:0] R_ss  = A_s * B_s;  // signed × signed
    wire signed [63:0] R_su  = A_s * B_u;  // signed × unsigned
    wire        [63:0] R_uu  = A_u * B_u;  // unsigned × unsigned

    always @(*) begin
        case (ALUCtrl)
            `ALU_MUL:     result = R_ss[31:0];   // MUL     ? low 32 bits
            `ALU_MULH:    result = R_ss[63:32];  // MULH    ? high 32 bits (signed×signed)
            `ALU_MULSU:   result = R_su[63:32];  // MULHSU  ? high 32 bits (signed×unsigned)
            `ALU_MULU:    result = R_uu[63:32];  // MULHU   ? high 32 bits (unsigned×unsigned)
            default:      result = 32'b0;
        endcase
    end

endmodule
