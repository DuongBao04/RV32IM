`timescale 1ns / 1ps
`include "defines.vh"

module divider_unit (
    input  [31:0] A,
    input  [31:0] B,
    input         is_signed,
    output [31:0] Q,
    output [31:0] R
);

    wire sign_A = A[31];
    wire sign_B = B[31];

    wire sign_Q = sign_A ^ sign_B;
    wire sign_R = sign_A;

    wire [31:0] absA = (is_signed && sign_A) ? (~A + 1) : A;
    wire [31:0] absB = (is_signed && sign_B) ? (~B + 1) : B;

    wire [31:0] rem  [0:32];
    wire [31:0] quot [0:32];

    assign rem[0]  = 0;
    assign quot[0] = 0;

    genvar i;
    generate
        for (i = 31; i >= 0; i = i - 1) begin : div_stage
            div_iter iter (
                .remainder_in(rem[31-i]),
                .divisor(absB),
                .dividend_bit(absA[i]),
                .quotient_in(quot[31-i]),
                .bit_index(i),
                .remainder_out(rem[31-i+1]),
                .quotient_out(quot[31-i+1])
            );
        end
    endgenerate

    wire [31:0] unsigned_Q = quot[32];
    wire [31:0] unsigned_R = rem[32];

    //Đặt lại dấu theo signed rule
    assign Q = (is_signed && sign_Q) ? (~unsigned_Q + 1) : unsigned_Q;
    assign R = (is_signed && sign_R) ? (~unsigned_R + 1) : unsigned_R;  

endmodule
