`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2025 05:59:45 PM
// Design Name: 
// Module Name: ControlUnit
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
module ControlUnit(
    input [`OPCODE_SIZE:0] inst_opcode,
    input [           2:0] inst_funct3,
    input [           6:0] inst_funct7,
    
    output reg is_div_op,
    output reg [4:0] ALUCtrl,
    output reg RegWrite, ALUSrc, MemWrite, MemToReg, MemRead, Branch, halt, Jal, Jalr, Auipc, Lui,
    output reg [2:0] BranchType, StoreType, LoadType,
    output reg illegal_inst
);
    wire inst_lui    = (inst_opcode == `OpLui    );
    wire inst_auipc  = (inst_opcode == `OpAuipc  );
    wire inst_jal    = (inst_opcode == `OpJal    );
    wire inst_jalr   = (inst_opcode == `OpJalr   );
    
    wire inst_beq    = (inst_opcode == `OpBranch ) & (inst_funct3 == 3'b000);
    wire inst_bne    = (inst_opcode == `OpBranch ) & (inst_funct3 == 3'b001);
    wire inst_blt    = (inst_opcode == `OpBranch ) & (inst_funct3 == 3'b100);
    wire inst_bge    = (inst_opcode == `OpBranch ) & (inst_funct3 == 3'b101);
    wire inst_bltu   = (inst_opcode == `OpBranch ) & (inst_funct3 == 3'b110);
    wire inst_bgeu   = (inst_opcode == `OpBranch ) & (inst_funct3 == 3'b111);
    
    wire inst_lb     = (inst_opcode == `OpLoad   ) & (inst_funct3 == 3'b000);
    wire inst_lh     = (inst_opcode == `OpLoad   ) & (inst_funct3 == 3'b001);
    wire inst_lw     = (inst_opcode == `OpLoad   ) & (inst_funct3 == 3'b010);
    wire inst_lbu    = (inst_opcode == `OpLoad   ) & (inst_funct3 == 3'b100);
    wire inst_lhu    = (inst_opcode == `OpLoad   ) & (inst_funct3 == 3'b101);
    
    wire inst_sb     = (inst_opcode == `OpStore  ) & (inst_funct3 == 3'b000);
    wire inst_sh     = (inst_opcode == `OpStore  ) & (inst_funct3 == 3'b001);
    wire inst_sw     = (inst_opcode == `OpStore  ) & (inst_funct3 == 3'b010);
    
    wire inst_addi   = (inst_opcode == `OpRegImm ) & (inst_funct3 == 3'b000);
    wire inst_slti   = (inst_opcode == `OpRegImm ) & (inst_funct3 == 3'b010);
    wire inst_sltiu  = (inst_opcode == `OpRegImm ) & (inst_funct3 == 3'b011);
    wire inst_xori   = (inst_opcode == `OpRegImm ) & (inst_funct3 == 3'b100);
    wire inst_ori    = (inst_opcode == `OpRegImm ) & (inst_funct3 == 3'b110);
    wire inst_andi   = (inst_opcode == `OpRegImm ) & (inst_funct3 == 3'b111);
    
    wire inst_slli   = (inst_opcode == `OpRegImm ) & (inst_funct3 == 3'b001) & (inst_funct7 == 7'd0      );
    wire inst_srli   = (inst_opcode == `OpRegImm ) & (inst_funct3 == 3'b101) & (inst_funct7 == 7'd0      );
    wire inst_srai   = (inst_opcode == `OpRegImm ) & (inst_funct3 == 3'b101) & (inst_funct7 == 7'b0100000);
    
    wire inst_add    = (inst_opcode == `OpRegReg ) & (inst_funct3 == 3'b000) & (inst_funct7 == 7'd0      );
    wire inst_sub    = (inst_opcode == `OpRegReg ) & (inst_funct3 == 3'b000) & (inst_funct7 == 7'b0100000);
    wire inst_sll    = (inst_opcode == `OpRegReg ) & (inst_funct3 == 3'b001) & (inst_funct7 == 7'd0      );
    wire inst_slt    = (inst_opcode == `OpRegReg ) & (inst_funct3 == 3'b010) & (inst_funct7 == 7'd0      );
    wire inst_sltu   = (inst_opcode == `OpRegReg ) & (inst_funct3 == 3'b011) & (inst_funct7 == 7'd0      );
    wire inst_xor    = (inst_opcode == `OpRegReg ) & (inst_funct3 == 3'b100) & (inst_funct7 == 7'd0      );
    wire inst_srl    = (inst_opcode == `OpRegReg ) & (inst_funct3 == 3'b101) & (inst_funct7 == 7'd0      );
    wire inst_sra    = (inst_opcode == `OpRegReg ) & (inst_funct3 == 3'b101) & (inst_funct7 == 7'b0100000);
    wire inst_or     = (inst_opcode == `OpRegReg ) & (inst_funct3 == 3'b110) & (inst_funct7 == 7'd0      );
    wire inst_and    = (inst_opcode == `OpRegReg ) & (inst_funct3 == 3'b111) & (inst_funct7 == 7'd0      );
    
    wire inst_mul    = (inst_opcode == `OpRegReg ) & (inst_funct3 == 3'b000  ) & (inst_funct7 == 7'd1    );
    wire inst_mulh   = (inst_opcode == `OpRegReg ) & (inst_funct3 == 3'b001  ) & (inst_funct7 == 7'd1    );
    wire inst_mulhsu = (inst_opcode == `OpRegReg ) & (inst_funct3 == 3'b010  ) & (inst_funct7 == 7'd1    );
    wire inst_mulhu  = (inst_opcode == `OpRegReg ) & (inst_funct3 == 3'b011  ) & (inst_funct7 == 7'd1    );
    wire inst_div    = (inst_opcode == `OpRegReg ) & (inst_funct3 == 3'b100  ) & (inst_funct7 == 7'd1    );
    wire inst_divu   = (inst_opcode == `OpRegReg ) & (inst_funct3 == 3'b101  ) & (inst_funct7 == 7'd1    );
    wire inst_rem    = (inst_opcode == `OpRegReg ) & (inst_funct3 == 3'b110  ) & (inst_funct7 == 7'd1    );
    wire inst_remu   = (inst_opcode == `OpRegReg ) & (inst_funct3 == 3'b111  ) & (inst_funct7 == 7'd1    );
    
    wire inst_ecall  = (inst_opcode == `OpEnviron) & (inst_funct3 == 3'b000) & (inst_funct7 == 7'd0      );
    wire inst_fence  = (inst_opcode == `OpMiscMem);
    always@(*) begin
        illegal_inst <= 1'b0;
        halt         <= 1'b0;
        ALUCtrl      <= `NOP;
        MemWrite     <= 1'b0;
        RegWrite     <= 1'b0;
        MemToReg     <= 1'b0;
        ALUSrc       <= 1'b0;
        Jal          <= 1'b0;
        Jalr         <= 1'b0;
        Lui          <= 1'b0;
        Auipc        <= 1'b0;
        Branch       <= 1'b0;
        BranchType   <= 3'b0;
        MemRead      <= 1'b0;
        StoreType    <= 3'b0;
        LoadType     <= 3'b0;
        is_div_op    <= (inst_div | inst_divu | inst_rem | inst_remu);

        case (inst_opcode)
            // R-type (OpRegReg)
            `OpRegReg: begin
                RegWrite <= 1'b1;
                if      (inst_add)    ALUCtrl <= `ALU_ADD;
                else if (inst_sub)    ALUCtrl <= `ALU_SUB;
                else if (inst_sll)    ALUCtrl <= `ALU_LSHIFT_LEFT;
                else if (inst_slt)    ALUCtrl <= `ALU_SLT;    
                else if (inst_sltu)   ALUCtrl <= `ALU_SLTU;   
                else if (inst_xor)    ALUCtrl <= `ALU_XOR;
                else if (inst_srl)    ALUCtrl <= `ALU_LSHIFT_RIGHT;
                else if (inst_sra)    ALUCtrl <= `ALU_ASHIFT_RIGHT;
                else if (inst_or)     ALUCtrl <= `ALU_OR;
                else if (inst_and)    ALUCtrl <= `ALU_AND;
                else if (inst_mul)    ALUCtrl <= `ALU_MUL;
                else if (inst_mulh)   ALUCtrl <= `ALU_MULH;
                else if (inst_mulhsu) ALUCtrl <= `ALU_MULSU;
                else if (inst_mulhu)  ALUCtrl <= `ALU_MULU;
                else if (inst_div)    ALUCtrl <= `ALU_DIV;
                else if (inst_divu)   ALUCtrl <= `ALU_DIVU;
                else if (inst_rem)    ALUCtrl <= `ALU_REM;
                else if (inst_remu)   ALUCtrl <= `ALU_REMU;
              
                else illegal_inst <= 1'b1;
            end

            // I-type arithmetic
            `OpRegImm: begin
                RegWrite <= 1'b1;
                ALUSrc  <= 1'b1;
                if      (inst_addi)  ALUCtrl <= `ALU_ADD  ;
                else if (inst_slti)  ALUCtrl <= `ALU_SLT  ;
                else if (inst_sltiu) ALUCtrl <= `ALU_SLTU ;
                else if (inst_xori)  ALUCtrl <= `ALU_XOR  ;
                else if (inst_ori)   ALUCtrl <= `ALU_OR   ;
                else if (inst_andi)  ALUCtrl <= `ALU_AND  ;
                else if (inst_slli)  ALUCtrl <= `ALU_LSHIFT_LEFT  ;
                else if (inst_srli)  ALUCtrl <= `ALU_LSHIFT_RIGHT ;
                else if (inst_srai)  ALUCtrl <= `ALU_ASHIFT_RIGHT ;
                else illegal_inst <= 1'b1;
            end

            // Load
            `OpLoad: begin
                ALUCtrl  <= `ALU_ADD;
                RegWrite <= 1'b1;
                MemToReg <= 1'b1;
                ALUSrc   <= 1'b1;
                MemRead  <= 1'b1;
            
                case(inst_funct3)
                    3'b000: LoadType <= `LB;
                    3'b001: LoadType <= `LH;
                    3'b010: LoadType <= `LW;
                    3'b100: LoadType <= `LBU;
                    3'b101: LoadType <= `LHU;
                    default: illegal_inst <= 1'b1;
                endcase
            end


            // Store
            `OpStore: begin
                ALUCtrl  <= `ALU_ADD;
                MemWrite <= 1'b1;
                ALUSrc   <= 1'b1;
            
                case(inst_funct3)
                    3'b000: StoreType <= `SB;
                    3'b001: StoreType <= `SH;
                    3'b010: StoreType <= `SW;
                    default: illegal_inst <= 1'b1;
                endcase
            end

            // Branch
            `OpBranch: begin
                ALUCtrl <= `ALU_SUB;
                Branch  <= 1'b1;
            
                case(inst_funct3)
                    3'b000: BranchType <= `BEQ;
                    3'b001: BranchType <= `BNE;
                    3'b100: BranchType <= `BLT;
                    3'b101: BranchType <= `BGE;
                    3'b110: BranchType <= `BLTU;
                    3'b111: BranchType <= `BGEU;
                    default: illegal_inst <= 1'b1;
                endcase
            end

            // JAL
            `OpJal: begin
                Jal      <= 1'b1;
                RegWrite <= 1'b1;
                ALUCtrl  <= `NOP;
            end
        
            // JALR
            `OpJalr: begin
                Jalr     <= 1'b1;
                RegWrite <= 1'b1;
                ALUCtrl  <= `NOP;            
            end
            
            // AUIPC
            `OpAuipc: begin
                Auipc    <= 1'b1;
                RegWrite <= 1'b1;
                ALUCtrl  <= `ALU_ADD;             // rd = PC + immU
                ALUSrc   <= 1'b1;
            end 
        
            // LUI
            `OpLui: begin
                Lui      <= 1'b1;
                RegWrite <= 1'b1;
                ALUSrc   <= 1'b1;
                ALUCtrl  <= `ALU_ADD;             // rd = imm << 12
            end        

            // ECALL
            `OpEnviron: begin
                halt <= 1'b1;
            end 
        
            default: begin
                illegal_inst <= 1'b1;
            end
        endcase
    end
endmodule
