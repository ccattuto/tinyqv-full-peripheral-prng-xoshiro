// xoshiro128++ (32-bit)
// Implements xoshiro128++ by David Blackman and Sebastiano Vigna: https://prng.di.unimi.it/xoshiro128plusplus.c
// See also: https://prng.di.unimi.it/

module xoshiro128plusplus (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        next,
    output reg  [31:0] rnd,

    input  wire        write,
    input  wire [1:0]  write_addr,
    input  wire [31:0] write_data
);

    // Internal state s[0..3]
    reg [31:0] s0, s1, s2, s3;

    // setup
    reg setup;
    reg [1:0] setup_addr;

    // Rotate-left helper
    function [31:0] rotl32;
        input [31:0] x;
        input [4:0]  k;
        begin
            rotl32 = (x << k) | (x >> (6'd32 - k));
        end
    endfunction

    // Combinational next-state math (https://prng.di.unimi.it/xoshiro128plusplus.c)
    wire [31:0] result_cur = rotl32(s0 + s3, 5'd7) + s0;
    wire [31:0] t          = s1 << 9;

    wire [31:0] a0 = s0;
    wire [31:0] a1 = s1;
    wire [31:0] a2 = s2;
    wire [31:0] a3 = s3;

    wire [31:0] b2_p = a2 ^ a0;
    wire [31:0] b3_p = a3 ^ a1;
    wire [31:0] b1_p = a1 ^ b2_p;
    wire [31:0] b0_p = a0 ^ b3_p;

    wire [31:0] b2 = b2_p ^ t;
    wire [31:0] b3 = rotl32(b3_p, 5'd11);

    wire [31:0] n0 = b0_p;
    wire [31:0] n1 = b1_p;
    wire [31:0] n2 = b2;
    wire [31:0] n3 = b3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s0 <= 0;
            s1 <= 0;
            s2 <= 0;
            s3 <= 0;
            rnd <= 0;
            setup <= 1;
            setup_addr <= 0;
        end else if (setup) begin
            setup_addr <= setup_addr + 1;
            setup <= (setup_addr == 2'b11) ? 0 : 1;
            case (setup_addr)
                2'd0: s0 <= 32'h0D1929D2;
                2'd1: s1 <= 32'h491DFB74;
                2'd2: s2 <= 32'h473E5E7D;
                2'd3: s3 <= 32'hD6CA8A07;
                default: ;
            endcase
        end else begin
            if (write) begin
                case (write_addr)
                    2'd0: s0 <= write_data;
                    2'd1: s1 <= write_data;
                    2'd2: s2 <= write_data;
                    2'd3: s3 <= write_data;
                    default: ;
                endcase
            end else if (next) begin
                rnd <= result_cur;
                s0 <= n0;
                s1 <= n1;
                s2 <= n2;
                s3 <= n3;
            end
        end
    end

endmodule
