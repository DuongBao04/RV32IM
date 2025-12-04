// registers are 32 bits in RV32
`define REG_SIZE 31

// RV opcodes are 7 bits
`define OPCODE_SIZE 6

// Don't forget your previous ALUs
//`include "divider_unsigned.v"
//`include "cla.v"

`define ALU_AND             5'b00000   // Logical AND
`define ALU_OR              5'b00001   // Logical OR
`define ALU_ADD             5'b00010   // Addition
`define ALU_SUB             5'b00011   // Subtraction
`define ALU_LSHIFT_LEFT     5'b00100   // Logical Shift Left
`define ALU_LSHIFT_RIGHT    5'b00101   // Logical Shift Right
`define ALU_ASHIFT_RIGHT    5'b00110   // Arithmetic Shift Right
`define ALU_XOR             5'b00111   // XOR
`define ALU_MUL             5'b01000
`define ALU_MULH            5'b01001
`define ALU_MULSU           5'b01010
`define ALU_MULU            5'b01011
`define ALU_DIV             5'b01100
`define ALU_DIVU            5'b01101
`define ALU_REM             5'b01110
`define ALU_REMU            5'b01111
`define ALU_SLT             5'b10000
`define ALU_SLTU            5'b10001
