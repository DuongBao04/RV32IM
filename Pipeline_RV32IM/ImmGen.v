`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2025 08:39:47 AM
// Design Name: 
// Module Name: ImmGen
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
module ImmGen(
    input [`INST_SIZE:0] inst_from_imem,
    output reg [`REG_SIZE:0] imm_out
);
    
    // components of the instruction
    wire [           6:0] inst_funct7;
    wire [           4:0] inst_rs2;
    wire [           4:0] inst_rs1;
    wire [           2:0] inst_funct3;
    wire [           4:0] inst_rd;
    wire [`OPCODE_SIZE:0] inst_opcode;
    
    // split R-type instruction - see section 2.2 of RiscV spec
    assign {inst_funct7, inst_rs2, inst_rs1, inst_funct3, inst_rd, inst_opcode} = inst_from_imem;
    
    // setup for I, S, B & J type instructions
    // I - short immediates and loads
    wire [11:0] imm_i;
    assign imm_i = inst_from_imem[31:20];
    wire [ 4:0] imm_shamt = inst_from_imem[24:20];
    
    // S - stores
    wire [11:0] imm_s;
    assign imm_s = {inst_funct7, inst_rd};
    
    // B - conditionals
    wire [12:0] imm_b;
    assign {imm_b[12], imm_b[10:1], imm_b[11], imm_b[0]} = {inst_funct7, inst_rd, 1'b0};
    
    // J - unconditional jumps
    wire [20:0] imm_j;
    assign {imm_j[20], imm_j[10:1], imm_j[11], imm_j[19:12], imm_j[0]} = {inst_from_imem[31:12], 1'b0};
    
    
    wire [`REG_SIZE:0] imm_i_sext = {{20{imm_i[11]}}, imm_i[11:0]};
    wire [`REG_SIZE:0] imm_s_sext = {{20{imm_s[11]}}, imm_s[11:0]};
    wire [`REG_SIZE:0] imm_b_sext = {{19{imm_b[12]}}, imm_b[12:0]};
    wire [`REG_SIZE:0] imm_j_sext = {{11{imm_j[20]}}, imm_j[20:0]};   
    wire [`REG_SIZE:0] imm_u_sext = {inst_from_imem[31:12], 12'b0};
    
    always@(*) begin
        imm_out <= 32'd0;
        case (inst_opcode)
            `OpRegImm, `OpLoad, `OpJalr: begin
                imm_out <= imm_i_sext;
            end
            
            `OpStore: begin
                imm_out <= imm_s_sext;
            end
            
            `OpBranch: begin
                imm_out <= imm_b_sext;
            end
            
            `OpLui, `OpAuipc: begin
                imm_out <= imm_u_sext;
            end
            
            `OpJal: begin
                imm_out <= imm_j_sext;
            end
            
            default: begin
                imm_out <= 32'd0;
            end
        endcase
    end 
endmodule
