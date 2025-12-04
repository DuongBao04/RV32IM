`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2025 05:10:19 PM
// Design Name: 
// Module Name: mux2X1
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
module mux2X1 (
    input [`REG_SIZE:0] a, b,
    input sel,
    
    output [`REG_SIZE:0] data_out    
);
assign data_out = (sel == 0) ? a : b;
endmodule
