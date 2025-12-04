`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2025 08:26:41 PM
// Design Name: 
// Module Name: RegFile
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
module RegFile (
    input      [        4:0] rd,
    input      [`REG_SIZE:0] rd_data,
    input      [        4:0] rs1,
    output reg [`REG_SIZE:0] rs1_data,
    input      [        4:0] rs2,
    output reg [`REG_SIZE:0] rs2_data,
    input                    clk,
    input                    we,
    input                    rst
);
  localparam NumRegs = 32;  
  
  // TODO: your code here
  integer i;
  reg [`REG_SIZE:0] registers[0:NumRegs-1];
  
  always@(*) begin
    rs1_data <= (rs1 >= 5'd0 ) ? registers[rs1] : 32'd0;
    rs2_data <= (rs2 >= 5'd0 ) ? registers[rs2] : 32'd0;
  end
  
  always@(posedge rst or posedge clk) begin
    if (rst) begin
        for (i = 0; i < NumRegs; i = i + 1) begin
            registers[i] <= 0;
        end    
    end else begin
        if (we && (rd != 5'h0)) begin
            registers[rd] <= rd_data;
        end
    end
end
endmodule
