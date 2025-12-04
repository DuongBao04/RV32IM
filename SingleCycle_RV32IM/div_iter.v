`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2025 08:32:32 AM
// Design Name: 
// Module Name: div_iter
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


module div_iter (
    input  [31:0] remainder_in,
    input  [31:0] divisor,
    input         dividend_bit,
    input  [31:0] quotient_in,
    input  [5:0]  bit_index,      
    output [31:0] remainder_out,
    output [31:0] quotient_out
);
    wire [31:0] rem_shifted = { remainder_in[30:0], dividend_bit };
    
    assign remainder_out = (rem_shifted >= divisor) ? (rem_shifted - divisor) : rem_shifted;

    assign quotient_out = (rem_shifted >= divisor) ? (quotient_in | (32'h1 << bit_index)) 
                             : quotient_in;

endmodule
