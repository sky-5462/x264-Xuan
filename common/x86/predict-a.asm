;*****************************************************************************
;* predict-a.asm: x86 intra prediction
;*****************************************************************************
;* Copyright (C) 2005-2019 x264 project
;*
;* Authors: Loren Merritt <lorenm@u.washington.edu>
;*          Holger Lubitz <holger@lubitz.org>
;*          Fiona Glaser <fiona@x264.com>
;*          Henrik Gramner <henrik@gramner.com>
;*
;* This program is free software; you can redistribute it and/or modify
;* it under the terms of the GNU General Public License as published by
;* the Free Software Foundation; either version 2 of the License, or
;* (at your option) any later version.
;*
;* This program is distributed in the hope that it will be useful,
;* but WITHOUT ANY WARRANTY; without even the implied warranty of
;* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;* GNU General Public License for more details.
;*
;* You should have received a copy of the GNU General Public License
;* along with this program; if not, write to the Free Software
;* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02111, USA.
;*
;* This program is also available under a commercial proprietary license.
;* For more information, contact us at licensing@x264.com.
;*****************************************************************************

%include "x86inc.asm"
%include "x86util.asm"

SECTION_RODATA 16
predict_chroma_dc_shuf:     times 4 db  0
                            times 4 db  4
                            times 4 db  8
                            times 4 db 12
predict_8x8_vr_shuf:        db  2, 4, 6, 8, 9,10,11,12,13,14,15,-1, 1, 3, 5, 7
predict_8x8_hu_shuf:        db 15,14,13,12,11,10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0
pb_32101234:                db -3,-2,-1, 0, 1, 2, 3, 4
pb_87654321:                db -8,-7,-6,-5,-4,-3,-2,-1
pb_12345678:                db  1, 2, 3, 4, 5, 6, 7, 8
predict_chroma_dc_top_shuf: times 4 db 0
                            times 4 db 8

SECTION .text

cextern pb_1
cextern pw_0to15

;=============================================================================
; predict_4x4
;=============================================================================
INIT_XMM avx2
cglobal predict_4x4_dc, 0, 0
    vmovd          m0, [r0 - 32]        ; top
    vpinsrb        m0, m0, [r0 - 1], 4  ; l0
    vpinsrb        m0, m0, [r0 + 31], 5 ; l1
    vpinsrb        m0, m0, [r0 + 63], 6 ; l2
    vpinsrb        m0, m0, [r0 + 95], 7 ; l3
    vpxor          m2, m2, m2
    vpsadbw        m0, m0, m2           ; add up all
    vpsrlw         m0, m0, 2
    vpavgw         m0, m0, m2
    vpbroadcastb   m0, m0
    vmovd          [r0], m0
    vmovd          [r0 + 32], m0
    vmovd          [r0 + 64], m0
    vmovd          [r0 + 96], m0
    ret

INIT_XMM avx2
cglobal predict_4x4_h, 0, 0
    vpbroadcastb   m0, [r0 - 1]        ; l0
    vpbroadcastb   m1, [r0 + 31]       ; l1
    vpbroadcastb   m2, [r0 + 63]       ; l2
    vpbroadcastb   m3, [r0 + 95]       ; l3
    vmovd          [r0], m0
    vmovd          [r0 + 32], m1
    vmovd          [r0 + 64], m2
    vmovd          [r0 + 96], m3
    ret

; (f1 + 2f2 + f3 + 2) >> 2 -> ((f1 + f3) / 2 + f2 + 1) / 2 <==> Avg((f1 + f3) / 2, f2)
; (f1 + f3) / 2 <==> Avg(f1, f3) - ((f1 xor f3) and 1)
; when f1 has different parity with f3, (f1 + f3) / 2 <==> Avg(f1, f3) - 1, so we need to correct it
; Avg and bit operations can help avoid converting to 16-bit and back
INIT_XMM avx2
cglobal predict_4x4_ddl, 0, 0
    vmovq          m0, [r0 - 32]       ; 0 1 2 3 4 5 6 7
    vpbroadcastd   m5, [pb_1]
    vpsrlq         m1, m0, 8           ; 1 2 3 4 5 6 7 x
    vpsrlq         m2, m0, 16          ; 2 3 4 5 6 7 x x
    vpblendw       m2, m2, m1, 08h     ; 2 3 4 5 6 7 7 x
    vpavgb         m3, m0, m2          ; Avg(f1, f3)
    vpxor          m4, m0, m2          ; f1 xor f3
    vpand          m4, m4, m5          ; (f1 xor f3) and 1
    vpsubb         m3, m3, m4          ; Avg(f1, f3) - ((f1 xor f3) and 1)
    vpavgb         m0, m1, m3          ; Avg(Avg(f1, f3) - ((f1 xor f3) and 1), f2)
    vmovd          [r0], m0
    vpsrlq         m0, m0, 8
    vmovd          [r0 + 32], m0
    vpsrlq         m0, m0, 8
    vmovd          [r0 + 64], m0
    vpsrlq         m0, m0, 8
    vmovd          [r0 + 96], m0
    ret

INIT_XMM avx2
cglobal predict_4x4_ddr, 0, 0
    vpbroadcastd   m5, [pb_1]
    vmovq          m1, [r0 - 36]         ;  x  x  x lt t0 t1 t2 t3
    vpinsrb        m1, m1, [r0 - 1], 2   ;  x  x l0 lt t0 t1 t2 t3
    vpinsrb        m1, m1, [r0 + 31], 1  ;  x l1 l0 lt t0 t1 t2 t3
    vpinsrb        m1, m1, [r0 + 63], 0  ; l2 l1 l0 lt t0 t1 t2 t3
    vpsllq         m0, m1, 8             ;  x l2 l1 l0 lt t0 t1
    vpsrlq         m2, m1, 8             ; l1 l0 lt t0 t1 t2 t3
    vpinsrb        m0, m0, [r0 + 95], 0  ; l3 l2 l1 l0 lt t0 t1
    ; m0 -> f1, m1 -> f2, m2 -> f3
    vpavgb         m3, m0, m2          ; Avg(f1, f3)
    vpxor          m4, m0, m2          ; f1 xor f3
    vpand          m4, m4, m5          ; (f1 xor f3) and 1
    vpsubb         m3, m3, m4          ; Avg(f1, f3) - ((f1 xor f3) and 1)
    vpavgb         m0, m1, m3          ; Avg(Avg(f1, f3) - ((f1 xor f3) and 1), f2)
    vmovd          [r0 + 96], m0
    vpsrlq         m0, m0, 8
    vmovd          [r0 + 64], m0
    vpsrlq         m0, m0, 8
    vmovd          [r0 + 32], m0
    vpsrlq         m0, m0, 8
    vmovd          [r0], m0
    ret

; l2   l1 l0 ->          S(0, 3)|
;                                  l1 l0 lt ->          S(0, 2)|
; l0 | lt t0 -> |S(0, 1) S(1, 3)|     lt t0 -> |S(0, 0) S(1, 2)|
; lt | t0 t1 -> |S(1, 1) S(2, 3)|     t0 t1 -> |S(1, 0) S(2, 2)|
; t0 | t1 t2 -> |S(2, 1) S(3, 3)|     t1 t2 -> |S(2, 0) S(3, 2)|
; t1 | t2 t3 -> |S(3, 1)              t2 t3 -> |S(3, 0)
INIT_XMM avx2
cglobal predict_4x4_vr, 0, 0
    vpbroadcastd   m5, [pb_1]
    vmovq          m0, [r0 - 36]         ;  x  x  x lt t0 t1 t2 t3
    vpinsrb        m0, m0, [r0 - 1], 2   ;  x  x l0 lt t0 t1 t2 t3
    vpinsrb        m0, m0, [r0 + 31], 1  ;  x l1 l0 lt t0 t1 t2 t3
    vpinsrb        m0, m0, [r0 + 63], 0  ; l2 l1 l0 lt t0 t1 t2 t3
    vpsrlq         m1, m0, 8             ; l1 l0 lt t0 t1 t2 t3
    vpsrlq         m2, m0, 16            ; l0 lt t0 t1 t2 t3
    ; m0 -> f1, m1 -> f2, m2 -> f3
    vpavgb         m3, m0, m2          ; Avg(f1, f3)
    vpxor          m4, m0, m2          ; f1 xor f3
    vpand          m4, m4, m5          ; (f1 xor f3) and 1
    vpsubb         m3, m3, m4          ; Avg(f1, f3) - ((f1 xor f3) and 1)
    vpavgb         m0, m1, m3          ; S(03) S(02) S(01) S(11) S(21) S(31)
    vpavgb         m1, m1, m2          ;     x    x  S(00) S(10) S(20) S(30)
    vpblendw       m2, m1, m0, 01h
    vpsrlq         m2, m2, 8           ; S(02) S(00) S(10) S(20) S(30)
    vpsllw         m3, m0, 8
    vpblendw       m3, m0, m3, 01h
    vpsrlq         m3, m3, 8           ; S(03) S(01) S(11) S(21) S(31)
    vmovd          [r0 + 64], m2
    vmovd          [r0 + 96], m3
    vpsrlq         m2, m2, 8
    vpsrlq         m3, m3, 8
    vmovd          [r0], m2
    vmovd          [r0 + 32], m3
    ret

; l3 l2 | l1 -> S(1, 3)               l3 l2 -> S(0, 3)
; l2 l1 | l0 -> S(1, 2) S(3, 3)       l2 l1 -> S(0, 2) S(2, 3)
; l1 l0 | lt -> S(1, 1) S(3, 2)       l1 l0 -> S(0, 1) S(2, 2)
; l0 lt | l0 -> S(1, 0) S(3, 1)       l0 lt -> S(0, 0) S(2, 1)
; lt l0 l1 -> S(2, 0)
; l0 l1 l2 -> S(3, 0)
; use vpunpcklbw to perform "transpose"
; S(0, 3)
; S(1, 3)
; S(2, 3) | S(0, 2)
; S(3, 3) | S(1, 2)
; S(0, 1) | S(2, 2)
; S(1, 1) | S(3, 2)
; S(2, 1) | S(0, 0)
; S(3, 1) | S(1, 0)
;           S(2, 0) -> need to move to the right firstly
;           S(3, 0) -> then move upwards
INIT_XMM avx2
cglobal predict_4x4_hd, 0, 0
    vpbroadcastd   m5, [pb_1]
    vmovq          m2, [r0 - 35]         ;  x  x lt t0 t1 t2
    vpinsrb        m2, m2, [r0 - 1], 1   ;  x l0 lt t0 t1 t2
    vpinsrb        m2, m2, [r0 + 31], 0  ; l1 l0 lt t0 t1 t2
    vpsllq         m1, m2, 8
    vpinsrb        m1, m1, [r0 + 63], 0  ; l2 l1 l0 lt t0 t1 t2
    vpsllq         m0, m1, 8
    vpinsrb        m0, m0, [r0 + 95], 0  ; l3 l2 l1 l0 lt t0 t1 t2
    ; m0 -> f1, m1 -> f2, m2 -> f3
    vpavgb         m3, m0, m2          ; Avg(f1, f3)
    vpxor          m4, m0, m2          ; f1 xor f3
    vpand          m4, m4, m5          ; (f1 xor f3) and 1
    vpsubb         m3, m3, m4          ; Avg(f1, f3) - ((f1 xor f3) and 1)
    vpavgb         m2, m1, m3          ; S(13) S(12) S(11) S(10) S(20) S(30)
    vpavgb         m1, m1, m0          ; S(03) S(02) S(01) S(00)
    vpblendd       m1, m1, m2, 02h     ; S(03) S(02) S(01) S(00) S(20)
    vpsrlw         m0, m2, 8
    vpblendd       m2, m2, m0, 02h     ; S(13) S(12) S(11) S(10) S(30)
    vpunpcklbw     m0, m1, m2
    vmovd          [r0 + 96], m0
    vpsrldq        m0, m0, 2
    vmovd          [r0 + 64], m0
    vpsrlq         m0, m0, 16
    vmovd          [r0 + 32], m0
    vpsrlq         m0, m0, 16
    vmovd          [r0], m0
    ret

; t0 t1 | t2 -> S(0, 1)               t0 t1 -> S(0, 0)
; t1 t2 | t3 -> S(1, 1) S(0, 3)       t1 t2 -> S(1, 0) S(0, 2)
; t2 t3 | t4 -> S(2, 1) S(1, 3)       t2 t3 -> S(2, 0) S(1, 2)
; t3 t4 | t5 -> S(3, 1) S(2, 3)       t3 t4 -> S(3, 0) S(2, 2)
; t4 t5 | t6 -> S(3, 3)               t4 t5 -> S(3, 2)
INIT_XMM avx2
cglobal predict_4x4_vl, 0, 0
    vpbroadcastd   m5, [pb_1]
    vmovq          m0, [r0 - 32]         ; t0 t1 t2 t3 t4 t5 t6
    vpsrlq         m1, m0, 8             ; t1 t2 t3 t4 t5 t6
    vpsrlq         m2, m0, 16            ; t2 t3 t4 t5 t6
    ; m0 -> f1, m1 -> f2, m2 -> f3
    vpavgb         m3, m0, m2          ; Avg(f1, f3)
    vpxor          m4, m0, m2          ; f1 xor f3
    vpand          m4, m4, m5          ; (f1 xor f3) and 1
    vpsubb         m3, m3, m4          ; Avg(f1, f3) - ((f1 xor f3) and 1)
    vpavgb         m2, m1, m3          ; S(01) S(11) S(21) S(31) S(33)
    vpavgb         m1, m1, m0          ; S(00) S(10) S(20) S(30) S(32)
    vmovd          [r0], m1
    vmovd          [r0 + 32], m2
    vpsrlq         m1, m1, 8
    vpsrlq         m2, m2, 8
    vmovd          [r0 + 64], m1
    vmovd          [r0 + 96], m2
    ret

; l0 l1 | l2 -> S(1, 0)               l0 l1 -> S(0, 0)
; l1 l2 | l3 -> S(3, 0) S(1, 1)       l1 l2 -> S(2, 0) S(0, 1)
; l2 l3 | l3 -> S(3, 1) S(1, 2)       l2 l3 -> S(2, 1) S(0, 2)
; l3 -> S(3, 2) S(1, 3) S(0, 3) S(2, 2) S(2, 3) S(3, 3)
; use vpunpcklbw to perform "transpose"
; S(0, 0)
; S(1, 0)
; S(2, 0) | S(0, 1)
; S(3, 0) | S(1, 1)
; S(0, 2) | S(2, 1)
; S(1, 2) | S(3, 1)
; S(2, 2)
; S(3, 2)
INIT_XMM avx2
cglobal predict_4x4_hu, 0, 0
    vpbroadcastd   m5, [pb_1]
    vpbroadcastb   m2, [r0 + 95]         ; l3 l3 l3 l3 ...
    vmovd          [r0 + 96], m2         ; only l3 in the last row
    vpinsrb        m2, m2, [r0 + 63], 0  ; l2 l3 l3 l3 ...
    vpsllq         m1, m2, 8
    vpinsrb        m1, m1, [r0 + 31], 0  ; l1 l2 l3 l3 ...
    vpsllq         m0, m1, 8
    vpinsrb        m0, m0, [r0 - 1], 0   ; l0 l1 l2 l3 ...
    ; m0 -> f1, m1 -> f2, m2 -> f3
    vpavgb         m3, m0, m2          ; Avg(f1, f3)
    vpxor          m4, m0, m2          ; f1 xor f3
    vpand          m4, m4, m5          ; (f1 xor f3) and 1
    vpsubb         m3, m3, m4          ; Avg(f1, f3) - ((f1 xor f3) and 1)
    vpavgb         m2, m1, m3          ; S(10) S(30) S(31)
    vpavgb         m1, m1, m0          ; S(00) S(20) S(21)
    vpunpcklbw     m0, m1, m2
    vmovd          [r0], m0
    vpsrlq         m0, m0, 16
    vmovd          [r0 + 32], m0
    vpsrlq         m0, m0, 16
    vmovd          [r0 + 64], m0
    ret


;=============================================================================
; predict_8x8c
;=============================================================================
INIT_XMM avx2
cglobal predict_8x8c_h, 0, 0
    vpbroadcastb   m0, [r0 - 1]        ; l0
    vpbroadcastb   m1, [r0 + 31]       ; l1
    vpbroadcastb   m2, [r0 + 63]       ; l2
    vpbroadcastb   m3, [r0 + 95]       ; l3
    vmovq          [r0], m0
    vmovq          [r0 + 32], m1
    vmovq          [r0 + 64], m2
    vmovq          [r0 + 96], m3
    add            r0, 128
    vpbroadcastb   m0, [r0 - 1]        ; l4
    vpbroadcastb   m1, [r0 + 31]       ; l5
    vpbroadcastb   m2, [r0 + 63]       ; l6
    vpbroadcastb   m3, [r0 + 95]       ; l7
    vmovq          [r0], m0
    vmovq          [r0 + 32], m1
    vmovq          [r0 + 64], m2
    vmovq          [r0 + 96], m3
    ret

INIT_XMM avx2
cglobal predict_8x8c_dc, 0, 0
    vpmovzxbw      m0, [r0 - 32]       ; t0 -- t7
    vpxor          m5, m5, m5
    vpsadbw        m0, m0, m5          ; s0 x s1 x
    ; use GPR to reach maximum load-and-expand throughput
    movzx          r1d, byte [r0 - 1]  ; l0
    movzx          r6d, byte [r0 + 31] ; l1
    add            r1d, r6d
    movzx          r6d, byte [r0 + 63] ; l2
    add            r1d, r6d
    movzx          r6d, byte [r0 + 95] ; l3
    add            r1d, r6d            ; s2
    vpinsrd        m0, m0, r1d, 1      ; s0 s2 s1 x
    add            r0, 128
    movzx          r6d, byte [r0 - 1]  ; l4
    movzx          r2d, byte [r0 + 31] ; l5
    add            r6d, r2d
    movzx          r2d, byte [r0 + 63] ; l6
    add            r6d, r2d
    movzx          r2d, byte [r0 + 95] ; l7
    add            r6d, r2d            ; s3
    vpinsrd        m0, m0, r6d, 3      ; s0 s2 s1 s3
    vpshufd        m1, m0, q2320       ; s0 s1 s3 s1
    vpshufd        m2, m0, q3321       ; s2 s1 s3 s3
    vpaddw         m0, m1, m2
    vpsrlw         m0, m0, 2
    vpavgw         m0, m0, m5          ; dc0 dc1 dc2 dc3
    vpshufb        m0, m0, [predict_chroma_dc_shuf]
    vmovq          [r0 - 128], m0
    vmovq          [r0 - 96], m0
    vmovq          [r0 - 64], m0
    vmovq          [r0 - 32], m0
    vmovhps        [r0], m0
    vmovhps        [r0 + 32], m0
    vmovhps        [r0 + 64], m0
    vmovhps        [r0 + 96], m0
    ret

INIT_YMM avx2
cglobal predict_8x8c_p, 0, 0
    movzx          r1d, byte [r0 - 25]      ; t7
    movzx          r2d, byte [r0 - 33]      ; lt
    movzx          r6d, byte [r0 + 223]     ; l7
    add            r1d, r6d
    shl            r1d, 4                   ; a
    add            r1d, 16                  ; a + 16
    shl            r2d, 2                   ; 4 * lt
    vmovd          xm4, r2d
    vmovq          xm0, [r0 - 32]           ; t0 t1 t2 t3 t4 t5 t6 t7
    vmovq          xm5, [pb_32101234]       ; kernel [-3 -2 -1 0 1 2 3 4]
    vpmaddubsw     xm0, xm0, xm5
    vpshufd        xm1, xm0, q0001
    vpaddw         xm0, xm0, xm1
    vpshuflw       xm1, xm0, q0001
    vpaddw         xm0, xm0, xm1
    vpsubw         xm0, xm0, xm4            ; H
    mov            r3d, 17408               ; 17 * 1024
    vmovd          xm5, r3d
    vpmulhrsw      xm0, xm0, xm5            ; b

    add            r0, 128
    shl            r6d, 2                   ; 4 * l7
    sub            r6d, r2d                 ; [-4] [4]
    movzx          r3d, byte [r0 - 129]     ; l0
    movzx          r4d, byte [r0 + 63]      ; l6
    sub            r4d, r3d
    lea            r4d, [r4 + r4 * 2]
    add            r6d, r4d                 ; [-3] [3]
    movzx          r3d, byte [r0 - 97]      ; l1
    movzx          r4d, byte [r0 + 31]      ; l5
    sub            r4d, r3d
    lea            r6d, [r6 + r4 * 2]       ; [-2] [2]
    movzx          r3d, byte [r0 - 65]      ; l2
    movzx          r4d, byte [r0 - 1]       ; l4
    sub            r4d, r3d
    add            r6d, r4d                 ; [-1] [1], V

    imul           r6d, r6d, 17
    add            r6d, 16
    sar            r6d, 5                   ; c
    vmovd          xm1, r6d
    lea            r6d, [r6 + r6 * 2]       ; 3 * c
    sub            r1d, r6d                 ; a - 3 * c + 16
    vmovd          xm2, r1d
    vpaddw         xm3, xm0, xm0
    vpaddw         xm3, xm3, xm0            ; 3 * b
    vpsubw         xm2, xm2, xm3            ; i00
    vpbroadcastw   m2, xm2
    vpbroadcastw   m0, xm0
    vpbroadcastw   m1, xm1
    vbroadcasti128 m5, [pw_0to15]
    vpmullw        m0, m0, m5               ; 0 b 2b 3b 4b 5b 6b 7b
    vpaddw         m2, m2, m0               ; row0
    vmovdqu        xm3, xm1                 ; c | 0
    vpaddw         m1, m1, m1               ; 2 * c
    vpaddw         m2, m2, m3               ; row1 | row0
    vpaddw         m0, m2, m1               ; row3 | row2
    vpaddw         m1, m1, m1               ; 4 * c
    vpsraw         m4, m2, 5
    vpsraw         m5, m0, 5
    vpackuswb      m3, m4, m5               ; row1 row3 | row0 row2
    vextracti128   xm4, m3, 1
    vmovq          [r0 - 96], xm3
    vmovhps        [r0 - 32], xm3
    vmovq          [r0 - 128], xm4
    vmovhps        [r0 - 64], xm4
    vpaddw         m2, m2, m1               ; row5 | row4
    vpaddw         m0, m0, m1               ; row7 | row6
    vpsraw         m4, m2, 5
    vpsraw         m5, m0, 5
    vpackuswb      m3, m4, m5               ; row5 row7 | row4 row6
    vextracti128   xm4, m3, 1
    vmovq          [r0 + 32], xm3
    vmovhps        [r0 + 96], xm3
    vmovq          [r0], xm4
    vmovhps        [r0 + 64], xm4
    RET

INIT_XMM avx2
cglobal predict_8x8c_dc_top, 0, 0
    vpmovzxbw      m0, [r0 - 32]
    vmovq          m5, [predict_chroma_dc_top_shuf]
    vpxor          m1, m1, m1
    vpsadbw        m0, m0, m1               ; dc0 dc1
    vpsrlw         m0, m0, 1
    vpavgw         m0, m0, m1
    vpshufb        m0, m0, m5
    vmovq          [r0], m0
    vmovq          [r0 + 32], m0
    vmovq          [r0 + 64], m0
    vmovq          [r0 + 96], m0
    add            r0, 128
    vmovq          [r0], m0
    vmovq          [r0 + 32], m0
    vmovq          [r0 + 64], m0
    vmovq          [r0 + 96], m0
    ret


;=============================================================================
; predict_8x16c
;=============================================================================
INIT_XMM avx2
cglobal predict_8x16c_h, 0, 0
    vpbroadcastb   m0, [r0 - 1]        ; l0
    vpbroadcastb   m1, [r0 + 31]       ; l1
    vpbroadcastb   m2, [r0 + 63]       ; l2
    vpbroadcastb   m3, [r0 + 95]       ; l3
    vmovq          [r0], m0
    vmovq          [r0 + 32], m1
    vmovq          [r0 + 64], m2
    vmovq          [r0 + 96], m3
    add            r0, 128
    vpbroadcastb   m0, [r0 - 1]        ; l4
    vpbroadcastb   m1, [r0 + 31]       ; l5
    vpbroadcastb   m2, [r0 + 63]       ; l6
    vpbroadcastb   m3, [r0 + 95]       ; l7
    vmovq          [r0], m0
    vmovq          [r0 + 32], m1
    vmovq          [r0 + 64], m2
    vmovq          [r0 + 96], m3
    add            r0, 256
    vpbroadcastb   m0, [r0 - 129]      ; l8
    vpbroadcastb   m1, [r0 - 97]       ; l9
    vpbroadcastb   m2, [r0 - 65]       ; l10
    vpbroadcastb   m3, [r0 - 33]       ; l11
    vmovq          [r0 - 128], m0
    vmovq          [r0 - 96], m1
    vmovq          [r0 - 64], m2
    vmovq          [r0 - 32], m3
    vpbroadcastb   m0, [r0 - 1]        ; l12
    vpbroadcastb   m1, [r0 + 31]       ; l13
    vpbroadcastb   m2, [r0 + 63]       ; l14
    vpbroadcastb   m3, [r0 + 95]       ; l15
    vmovq          [r0], m0
    vmovq          [r0 + 32], m1
    vmovq          [r0 + 64], m2
    vmovq          [r0 + 96], m3
    ret

INIT_XMM avx2
cglobal predict_8x16c_dc, 0, 0
    vpmovzxbw      m0, [r0 - 32]       ; t0 -- t7
    vpxor          m5, m5, m5
    vpsadbw        m0, m0, m5          ; s0 x s1 x
    ; use GPR to reach maximum load-and-expand throughput
    movzx          r1d, byte [r0 - 1]  ; l0
    movzx          r6d, byte [r0 + 31] ; l1
    add            r1d, r6d
    movzx          r6d, byte [r0 + 63] ; l2
    add            r1d, r6d
    movzx          r6d, byte [r0 + 95] ; l3
    add            r1d, r6d            ; s2
    vpinsrd        m0, m0, r1d, 1      ; s0 s2 s1 x
    add            r0, 128
    lea            r3, [r0 + 256]
    movzx          r6d, byte [r0 - 1]  ; l4
    movzx          r2d, byte [r0 + 31] ; l5
    add            r6d, r2d
    movzx          r2d, byte [r0 + 63] ; l6
    add            r6d, r2d
    movzx          r2d, byte [r0 + 95] ; l7
    add            r6d, r2d            ; s3
    vpinsrd        m0, m0, r6d, 3      ; s0 s2 s1 s3
    movzx          r1d, byte [r3 - 129]; l8
    movzx          r6d, byte [r3 - 97] ; l9
    add            r1d, r6d
    movzx          r6d, byte [r3 - 65] ; l10
    add            r1d, r6d
    movzx          r6d, byte [r3 - 33] ; l11
    add            r1d, r6d            ; s4
    vpinsrd        m1, m0, r1d, 1      ; s0 s4 s1 x
    movzx          r6d, byte [r3 - 1]  ; l12
    movzx          r2d, byte [r3 + 31] ; l13
    add            r6d, r2d
    movzx          r2d, byte [r3 + 63] ; l14
    add            r6d, r2d
    movzx          r2d, byte [r3 + 95] ; l15
    add            r6d, r2d            ; s5
    vpinsrd        m1, m1, r6d, 3      ; s0 s4 s1 s5

    vpshufd        m2, m0, q2320       ; s0 s1 s3 s1
    vpshufd        m3, m0, q3321       ; s2 s1 s3 s3
    vpaddw         m2, m2, m3
    vpshufd        m3, m1, q2321       ; s4 s1 s5 s1
    vpshufd        m4, m1, q3311       ; s4 s4 s5 s5
    vpaddw         m3, m3, m4
    vpsrlw         m2, m2, 2
    vpsrlw         m3, m3, 2
    vpavgw         m2, m2, m5          ; dc0 dc1 dc2 dc3
    vpavgw         m3, m3, m5          ; dc4 dc5 dc6 dc7
    vmovdqu        m5, [predict_chroma_dc_shuf]
    vpshufb        m2, m2, m5
    vpshufb        m3, m3, m5
    vmovq          [r0 - 128], m2
    vmovq          [r0 - 96], m2
    vmovq          [r0 - 64], m2
    vmovq          [r0 - 32], m2
    vmovhps        [r0], m2
    vmovhps        [r0 + 32], m2
    vmovhps        [r0 + 64], m2
    vmovhps        [r0 + 96], m2
    vmovq          [r3 - 128], m3
    vmovq          [r3 - 96], m3
    vmovq          [r3 - 64], m3
    vmovq          [r3 - 32], m3
    vmovhps        [r3], m3
    vmovhps        [r3 + 32], m3
    vmovhps        [r3 + 64], m3
    vmovhps        [r3 + 96], m3
    ret

INIT_YMM avx2
cglobal predict_8x16c_p, 0, 0
    movzx          r1d, byte [r0 - 25]      ; t7
    movzx          r2d, byte [r0 - 33]      ; lt
    movzx          r6d, byte [r0 + 479]     ; l15
    add            r1d, r6d
    shl            r1d, 4                   ; a
    add            r1d, 16                  ; a + 16
    shl            r2d, 2                   ; 4 * lt
    vmovd          xm4, r2d
    vmovq          xm0, [r0 - 32]           ; t0 t1 t2 t3 t4 t5 t6 t7
    vmovq          xm5, [pb_32101234]       ; kernel [-3 -2 -1 0 1 2 3 4]
    vpmaddubsw     xm0, xm0, xm5
    vpshufd        xm1, xm0, q0001
    vpaddw         xm0, xm0, xm1
    vpshuflw       xm1, xm0, q0001
    vpaddw         xm0, xm0, xm1
    vpsubw         xm0, xm0, xm4            ; H
    mov            r3d, 17408               ; 17 * 1024
    vmovd          xm5, r3d
    vpmulhrsw      xm0, xm0, xm5            ; b

    lea            r5, [r0 + 384]
    add            r2d, r2d                 ; 8 * lt
    shl            r6d, 3                   ; 8 * l15
    sub            r6d, r2d                 ; [-8] [8]
    movzx          r3d, byte [r0 - 1]       ; l0
    movzx          r4d, byte [r5 + 63]      ; l14
    sub            r4d, r3d
    lea            r6d, [r6 + r4 * 8]
    sub            r6d, r4d                 ; [-7] [7]
    movzx          r3d, byte [r0 + 31]      ; l1
    movzx          r4d, byte [r5 + 31]      ; l13
    sub            r4d, r3d
    lea            r6d, [r6 + r4 * 4]
    lea            r6d, [r6 + r4 * 2]       ; [-6] [6]
    movzx          r3d, byte [r0 + 63]      ; l2
    movzx          r4d, byte [r5 - 1]       ; l12
    sub            r4d, r3d
    lea            r4d, [r4 + r4 * 4]
    add            r6d, r4d                 ; [-5] [5]
    movzx          r3d, byte [r0 + 95]      ; l3
    movzx          r4d, byte [r5 - 33]      ; l11
    add            r0, 128
    sub            r4d, r3d
    lea            r6d, [r6 + r4 * 4]       ; [-4] [4]
    movzx          r3d, byte [r0 - 1]       ; l4
    movzx          r4d, byte [r5 - 65]      ; l10
    sub            r4d, r3d
    lea            r4, [r4 + r4 * 2]
    add            r6d, r4d                 ; [-3] [3]
    movzx          r3d, byte [r0 + 31]      ; l5
    movzx          r4d, byte [r5 - 97]      ; l9
    sub            r4d, r3d
    lea            r6d, [r6 + r4 * 2]       ; [-2] [2]
    movzx          r3d, byte [r0 + 63]      ; l6
    movzx          r4d, byte [r5 - 129]     ; l8
    sub            r4d, r3d
    add            r6d, r4d                 ; [-1] [1], V

    imul           r6d, r6d, 5
    add            r6d, 32
    sar            r6d, 6                   ; c
    vmovd          xm1, r6d
    add            r1d, r6d
    shl            r6d, 3
    sub            r1d, r6d                 ; a - 7 * c + 16
    vmovd          xm2, r1d
    vpaddw         xm3, xm0, xm0
    vpaddw         xm3, xm3, xm0            ; 3 * b
    vpsubw         xm2, xm2, xm3            ; i00
    vpbroadcastw   m2, xm2
    vpbroadcastw   m0, xm0
    vpbroadcastw   m1, xm1
    vbroadcasti128 m5, [pw_0to15]
    vpmullw        m0, m0, m5               ; 0 b 2b 3b 4b 5b 6b 7b
    vpaddw         m2, m2, m0               ; row0
    vmovdqu        xm3, xm1                 ; c | 0
    vpaddw         m1, m1, m1               ; 2 * c
    vpaddw         m2, m2, m3               ; row1 | row0
    vpaddw         m0, m2, m1               ; row3 | row2
    vpaddw         m1, m1, m1               ; 4 * c
    vpsraw         m4, m2, 5
    vpsraw         m5, m0, 5
    vpackuswb      m3, m4, m5               ; row1 row3 | row0 row2
    vextracti128   xm4, m3, 1
    vmovq          [r0 - 96], xm3
    vmovhps        [r0 - 32], xm3
    vmovq          [r0 - 128], xm4
    vmovhps        [r0 - 64], xm4
    vpaddw         m2, m2, m1               ; row5 | row4
    vpaddw         m0, m0, m1               ; row7 | row6
    vpsraw         m4, m2, 5
    vpsraw         m5, m0, 5
    vpackuswb      m3, m4, m5               ; row5 row7 | row4 row6
    vextracti128   xm4, m3, 1
    vmovq          [r0 + 32], xm3
    vmovhps        [r0 + 96], xm3
    vmovq          [r0], xm4
    vmovhps        [r0 + 64], xm4
    vpaddw         m2, m2, m1               ; row9 | row8
    vpaddw         m0, m0, m1               ; row11 | row10
    vpsraw         m4, m2, 5
    vpsraw         m5, m0, 5
    vpackuswb      m3, m4, m5               ; row9 row11 | row8 row10
    vextracti128   xm4, m3, 1
    vmovq          [r5 - 96], xm3
    vmovhps        [r5 - 32], xm3
    vmovq          [r5 - 128], xm4
    vmovhps        [r5 - 64], xm4
    vpaddw         m2, m2, m1               ; row13 | row12
    vpaddw         m0, m0, m1               ; row15 | row14
    vpsraw         m4, m2, 5
    vpsraw         m5, m0, 5
    vpackuswb      m3, m4, m5               ; row13 row15 | row12 row14
    vextracti128   xm4, m3, 1
    vmovq          [r5 + 32], xm3
    vmovhps        [r5 + 96], xm3
    vmovq          [r5], xm4
    vmovhps        [r5 + 64], xm4
    RET

INIT_XMM avx2
cglobal predict_8x16c_dc_top, 0, 0
    vpmovzxbw      m0, [r0 - 32]
    vmovq          m5, [predict_chroma_dc_top_shuf]
    vpxor          m1, m1, m1
    vpsadbw        m0, m0, m1               ; dc0 dc1
    vpsrlw         m0, m0, 1
    vpavgw         m0, m0, m1
    vpshufb        m0, m0, m5
    vmovq          [r0], m0
    vmovq          [r0 + 32], m0
    vmovq          [r0 + 64], m0
    vmovq          [r0 + 96], m0
    lea            r1, [r0 + 384]
    add            r0, 128
    vmovq          [r0], m0
    vmovq          [r0 + 32], m0
    vmovq          [r0 + 64], m0
    vmovq          [r0 + 96], m0
    vmovq          [r1 - 128], m0
    vmovq          [r1 - 96], m0
    vmovq          [r1 - 64], m0
    vmovq          [r1 - 32], m0
    vmovq          [r1], m0
    vmovq          [r1 + 32], m0
    vmovq          [r1 + 64], m0
    vmovq          [r1 + 96], m0
    ret


;=============================================================================
; predict_16x16
;=============================================================================
INIT_XMM avx2
cglobal predict_16x16_v, 0, 0
    vmovdqu        m0, [r0 - 32]
    vmovdqu        [r0], m0
    vmovdqu        [r0 + 32], m0
    vmovdqu        [r0 + 64], m0
    vmovdqu        [r0 + 96], m0
    add            r0, 128
    vmovdqu        [r0], m0
    vmovdqu        [r0 + 32], m0
    vmovdqu        [r0 + 64], m0
    vmovdqu        [r0 + 96], m0
    add            r0, 256
    vmovdqu        [r0 - 128], m0
    vmovdqu        [r0 - 96], m0
    vmovdqu        [r0 - 64], m0
    vmovdqu        [r0 - 32], m0
    vmovdqu        [r0], m0
    vmovdqu        [r0 + 32], m0
    vmovdqu        [r0 + 64], m0
    vmovdqu        [r0 + 96], m0
    ret

INIT_XMM avx2
cglobal predict_16x16_h, 0, 0
    vpbroadcastb   m0, [r0 - 1]        ; l0
    vpbroadcastb   m1, [r0 + 31]       ; l1
    vpbroadcastb   m2, [r0 + 63]       ; l2
    vpbroadcastb   m3, [r0 + 95]       ; l3
    vmovdqu        [r0], m0
    vmovdqu        [r0 + 32], m1
    vmovdqu        [r0 + 64], m2
    vmovdqu        [r0 + 96], m3
    add            r0, 128
    vpbroadcastb   m0, [r0 - 1]        ; l4
    vpbroadcastb   m1, [r0 + 31]       ; l5
    vpbroadcastb   m2, [r0 + 63]       ; l6
    vpbroadcastb   m3, [r0 + 95]       ; l7
    vmovdqu        [r0], m0
    vmovdqu        [r0 + 32], m1
    vmovdqu        [r0 + 64], m2
    vmovdqu        [r0 + 96], m3
    add            r0, 256
    vpbroadcastb   m0, [r0 - 129]      ; l8
    vpbroadcastb   m1, [r0 - 97]       ; l9
    vpbroadcastb   m2, [r0 - 65]       ; l10
    vpbroadcastb   m3, [r0 - 33]       ; l11
    vmovdqu        [r0 - 128], m0
    vmovdqu        [r0 - 96], m1
    vmovdqu        [r0 - 64], m2
    vmovdqu        [r0 - 32], m3
    vpbroadcastb   m0, [r0 - 1]        ; l12
    vpbroadcastb   m1, [r0 + 31]       ; l13
    vpbroadcastb   m2, [r0 + 63]       ; l14
    vpbroadcastb   m3, [r0 + 95]       ; l15
    vmovdqu        [r0], m0
    vmovdqu        [r0 + 32], m1
    vmovdqu        [r0 + 64], m2
    vmovdqu        [r0 + 96], m3
    ret

INIT_XMM avx2
cglobal predict_16x16_dc, 0, 0
    vpxor          m5, m5, m5
    vpsadbw        m0, m5, [r0 - 32]   ; sum of top
    ; use GPR to reach maximum load-and-expand throughput
    movzx          r1d, byte [r0 - 1]  ; l0
    movzx          r6d, byte [r0 + 31] ; l1
    movzx          r2d, byte [r0 + 63] ; l2
    movzx          r3d, byte [r0 + 95] ; l3
    add            r1d, r2d
    add            r6d, r3d
    lea            r5, [r0 + 384]
    add            r0, 128
    movzx          r2d, byte [r0 - 1]  ; l4
    movzx          r3d, byte [r0 + 31] ; l5
    add            r1d, r2d
    add            r6d, r3d
    movzx          r2d, byte [r0 + 63] ; l6
    movzx          r3d, byte [r0 + 95] ; l7
    add            r1d, r2d
    add            r6d, r3d
    movzx          r2d, byte [r5 - 129]; l8
    movzx          r3d, byte [r5 - 97] ; l9
    add            r1d, r2d
    add            r6d, r3d
    movzx          r2d, byte [r5 - 65] ; l10
    movzx          r3d, byte [r5 - 33] ; l11
    add            r1d, r2d
    add            r6d, r3d
    movzx          r2d, byte [r5 - 1]  ; l12
    movzx          r3d, byte [r5 + 31] ; l13
    add            r1d, r2d
    add            r6d, r3d
    movzx          r2d, byte [r5 + 63] ; l14
    movzx          r3d, byte [r5 + 95] ; l15
    add            r1d, r2d
    add            r6d, r3d

    add            r1d, r6d
    vpunpckhqdq    m1, m0, m0
    vpaddw         m0, m0, m1
    vmovd          m1, r1d
    vpaddw         m0, m0, m1          ; dc
    vpsrlw         m0, m0, 4
    vpavgw         m0, m0, m5          ; dcsplat
    vpbroadcastb   m0, m0
    
    vmovdqu        [r0 - 128], m0
    vmovdqu        [r0 - 96], m0
    vmovdqu        [r0 - 64], m0
    vmovdqu        [r0 - 32], m0
    vmovdqu        [r0], m0
    vmovdqu        [r0 + 32], m0
    vmovdqu        [r0 + 64], m0
    vmovdqu        [r0 + 96], m0
    vmovdqu        [r5 - 128], m0
    vmovdqu        [r5 - 96], m0
    vmovdqu        [r5 - 64], m0
    vmovdqu        [r5 - 32], m0
    vmovdqu        [r5], m0
    vmovdqu        [r5 + 32], m0
    vmovdqu        [r5 + 64], m0
    vmovdqu        [r5 + 96], m0
    ret

INIT_YMM avx2
cglobal predict_16x16_p, 0, 0
    movzx          r1d, byte [r0 - 17]      ; t15
    movzx          r2d, byte [r0 - 33]      ; lt
    movzx          r6d, byte [r0 + 479]     ; l15
    add            r1d, r6d
    shl            r1d, 4                   ; a
    add            r1d, 16                  ; a + 16
    vmovq          xm0, [r0 - 33]           ; lt t0 ... t6
    vmovq          xm1, [r0 - 24]           ; t8 t9 ... t15
    vmovq          xm4, [pb_87654321]
    vmovq          xm5, [pb_12345678]
    vpmaddubsw     xm0, xm0, xm4            ; [-8 -7 -6 -5 -4 -3 -2 -1]
    vpmaddubsw     xm1, xm1, xm5            ; [1 2 3 4 5 6 7 8]
    vpaddw         xm0, xm0, xm1
    vpshufd        xm1, xm0, q0001
    vpaddw         xm0, xm0, xm1
    vpshuflw       xm1, xm0, q0001
    vpaddw         xm0, xm0, xm1            ; H
    mov            r3d, 2560                ; 5 * 512
    vmovd          xm5, r3d
    vpmulhrsw      xm0, xm0, xm5            ; b

    lea            r5, [r0 + 384]
    sub            r6d, r2d
    shl            r6d, 3                   ; [-8] [8]
    movzx          r3d, byte [r0 - 1]       ; l0
    movzx          r4d, byte [r5 + 63]      ; l14
    sub            r4d, r3d
    lea            r6d, [r6 + r4 * 8]
    sub            r6d, r4d                 ; [-7] [7]
    movzx          r3d, byte [r0 + 31]      ; l1
    movzx          r4d, byte [r5 + 31]      ; l13
    sub            r4d, r3d
    lea            r6d, [r6 + r4 * 4]
    lea            r6d, [r6 + r4 * 2]       ; [-6] [6]
    movzx          r3d, byte [r0 + 63]      ; l2
    movzx          r4d, byte [r5 - 1]       ; l12
    sub            r4d, r3d
    lea            r4d, [r4 + r4 * 4]
    add            r6d, r4d                 ; [-5] [5]
    movzx          r3d, byte [r0 + 95]      ; l3
    movzx          r4d, byte [r5 - 33]      ; l11
    add            r0, 128
    sub            r4d, r3d
    lea            r6d, [r6 + r4 * 4]       ; [-4] [4]
    movzx          r3d, byte [r0 - 1]       ; l4
    movzx          r4d, byte [r5 - 65]      ; l10
    sub            r4d, r3d
    lea            r4, [r4 + r4 * 2]
    add            r6d, r4d                 ; [-3] [3]
    movzx          r3d, byte [r0 + 31]      ; l5
    movzx          r4d, byte [r5 - 97]      ; l9
    sub            r4d, r3d
    lea            r6d, [r6 + r4 * 2]       ; [-2] [2]
    movzx          r3d, byte [r0 + 63]      ; l6
    movzx          r4d, byte [r5 - 129]     ; l8
    sub            r4d, r3d
    add            r6d, r4d                 ; [-1] [1], V

    imul           r6d, r6d, 5
    add            r6d, 32
    sar            r6d, 6                   ; c
    vmovd          xm1, r6d
    add            r1d, r6d
    shl            r6d, 3
    sub            r1d, r6d                 ; a - 7 * c + 16
    vmovd          xm2, r1d
    vpsllw         xm4, xm0, 3              ; 8 * b
    vpsubw         xm3, xm4, xm0            ; 7 * b
    vpsubw         xm2, xm2, xm3            ; i00
    vpbroadcastw   m2, xm2
    vpbroadcastw   m0, xm0
    vpbroadcastw   m1, xm1
    vpbroadcastw   m4, xm4
    vbroadcasti128 m5, [pw_0to15]
    vpmullw        m0, m0, m5               ; 0 -- 7b | 0 -- 7b
    vpaddw         m2, m2, m0               ; row0a | row0a
    vpaddw         m3, m2, m4               ; row0b | row0b
    vmovdqu        xm0, xm1                 ; c | 0
    vpaddw         m2, m2, m0               ; row1a | row0a
    vpaddw         m3, m3, m0               ; row1b | row0b
    vpaddw         m1, m1, m1               ; 2 * c
    vpsraw         m4, m2, 5
    vpsraw         m5, m3, 5
    vpackuswb      m4, m4, m5               ; row1 | row0
    vextracti128   [r0 - 128], m4, 1
    vmovdqu        [r0 - 96], xm4

    add            r0, 384                  ; move to the end
    mov            r1, -448
.loop:
    vpaddw         m2, m2, m1
    vpaddw         m3, m3, m1
    vpsraw         m4, m2, 5
    vpsraw         m5, m3, 5
    vpackuswb      m4, m4, m5               ; row3 | row2 ...
    vextracti128   [r0 + r1], m4, 1
    vmovdqu        [r0 + r1 + 32], xm4
    add            r1, 64
    jl             .loop
    RET

INIT_XMM avx2
cglobal predict_16x16_dc_left, 0, 0
    movzx          r1d, byte [r0 - 1]
    movzx          r2d, byte [r0 + 31]
    movzx          r6d, byte [r0 + 63]
    add            r1d, r6d
    movzx          r3d, byte [r0 + 95]
    add            r2d, r3d
    lea            r5, [r0 + 383]
    add            r0, 127
    movzx          r6d, byte [r0]
    add            r1d, r6d
    movzx          r3d, byte [r0 + 32]
    add            r2d, r3d
    movzx          r6d, byte [r0 + 64]
    add            r1d, r6d
    movzx          r3d, byte [r0 + 96]
    add            r2d, r3d
    movzx          r6d, byte [r5 - 128]
    add            r1d, r6d
    movzx          r3d, byte [r5 - 96]
    add            r2d, r3d
    movzx          r6d, byte [r5 - 64]
    add            r1d, r6d
    movzx          r3d, byte [r5 - 32]
    add            r2d, r3d
    movzx          r6d, byte [r5]
    add            r1d, r6d
    movzx          r3d, byte [r5 + 32]
    add            r2d, r3d
    movzx          r6d, byte [r5 + 64]
    add            r1d, r6d
    movzx          r3d, byte [r5 + 96]
    add            r2d, r3d
    add            r1d, r2d

    add            r1d, 8
    shr            r1d, 4
    vmovd          m0, r1d
    vpbroadcastb   m0, m0
    vmovdqu        [r0 - 127], m0
    vmovdqu        [r0 - 95], m0
    vmovdqu        [r0 - 63], m0
    vmovdqu        [r0 - 31], m0
    vmovdqu        [r0 + 1], m0
    vmovdqu        [r0 + 33], m0
    vmovdqu        [r0 + 65], m0
    vmovdqu        [r0 + 97], m0
    vmovdqu        [r5 - 127], m0
    vmovdqu        [r5 - 95], m0
    vmovdqu        [r5 - 63], m0
    vmovdqu        [r5 - 31], m0
    vmovdqu        [r5 + 1], m0
    vmovdqu        [r5 + 33], m0
    vmovdqu        [r5 + 65], m0
    vmovdqu        [r5 + 97], m0
    ret

INIT_XMM avx2
cglobal predict_16x16_dc_top, 0, 0
    vpxor          m2, m2, m2
    vpsadbw        m0, m2, [r0 - 32]
    vpunpckhqdq    m1, m0, m0
    vpaddw         m0, m0, m1
    vpsrlw         m0, m0, 3
    vpavgw         m0, m0, m2
    vpbroadcastb   m0, m0
    vmovdqu        [r0], m0
    vmovdqu        [r0 + 32], m0
    vmovdqu        [r0 + 64], m0
    vmovdqu        [r0 + 96], m0
    lea            r1, [r0 + 384]
    add            r0, 128
    vmovdqu        [r0], m0
    vmovdqu        [r0 + 32], m0
    vmovdqu        [r0 + 64], m0
    vmovdqu        [r0 + 96], m0
    vmovdqu        [r1 - 128], m0
    vmovdqu        [r1 - 96], m0
    vmovdqu        [r1 - 64], m0
    vmovdqu        [r1 - 32], m0
    vmovdqu        [r1], m0
    vmovdqu        [r1 + 32], m0
    vmovdqu        [r1 + 64], m0
    vmovdqu        [r1 + 96], m0
    ret

INIT_XMM avx2
cglobal predict_16x16_dc_128, 0, 0
    mov            r1d, 128
    vmovd          m0, r1d
    vpbroadcastb   m0, m0
    vmovdqu        [r0], m0
    vmovdqu        [r0 + 32], m0
    vmovdqu        [r0 + 64], m0
    vmovdqu        [r0 + 96], m0
    lea            r1, [r0 + 384]
    add            r0, 128
    vmovdqu        [r0], m0
    vmovdqu        [r0 + 32], m0
    vmovdqu        [r0 + 64], m0
    vmovdqu        [r0 + 96], m0
    vmovdqu        [r1 - 128], m0
    vmovdqu        [r1 - 96], m0
    vmovdqu        [r1 - 64], m0
    vmovdqu        [r1 - 32], m0
    vmovdqu        [r1], m0
    vmovdqu        [r1 + 32], m0
    vmovdqu        [r1 + 64], m0
    vmovdqu        [r1 + 96], m0
    ret


;=============================================================================
; predict_8x8
;=============================================================================
INIT_XMM avx2
cglobal predict_8x8_h, 0, 0
    vmovq          m0, [r1 + 7]        ; l7 l6 l5 l4 l3 l2 l1 l0
    add            r0, 128
    vpunpcklbw     m0, m0, m0
    vpunpckhwd     m1, m0, m0          ; l3 l2 l1 l0
    vpunpcklwd     m0, m0, m0          ; l7 l6 l5 l4
    vpunpckhdq     m2, m1, m1
    vmovhps        [r0 - 128], m2
    vmovq          [r0 - 96], m2
    vpunpckldq     m1, m1, m1
    vmovhps        [r0 - 64], m1
    vmovq          [r0 - 32], m1
    vpunpckhdq     m1, m0, m0
    vmovhps        [r0], m1
    vmovq          [r0 + 32], m1
    vpunpckldq     m0, m0, m0
    vmovhps        [r0 + 64], m0
    vmovq          [r0 + 96], m0
    ret

INIT_XMM avx2
cglobal predict_8x8_dc, 0, 0
    vpxor          m2, m2, m2
    vpsadbw        m0, m2, [r1 + 7]    ; left
    vpsadbw        m1, m2, [r1 + 16]   ; top
    vpaddw         m0, m0, m1
    vpsrlw         m0, m0, 3
    vpavgw         m0, m0, m2
    vpbroadcastb   m0, m0
    add            r0, 128
    vmovq          [r0 - 128], m0
    vmovq          [r0 - 96], m0
    vmovq          [r0 - 64], m0
    vmovq          [r0 - 32], m0
    vmovq          [r0], m0
    vmovq          [r0 + 32], m0
    vmovq          [r0 + 64], m0
    vmovq          [r0 + 96], m0
    ret

INIT_XMM avx2
cglobal predict_8x8_dc_left, 0, 0
    vpxor          m2, m2, m2
    vpsadbw        m0, m2, [r1 + 7]    ; left
    vpsrlw         m0, m0, 2
    vpavgw         m0, m0, m2
    vpbroadcastb   m0, m0
    vmovq          [r0], m0
    vmovq          [r0 + 32], m0
    vmovq          [r0 + 64], m0
    vmovq          [r0 + 96], m0
    add            r0, 128
    vmovq          [r0], m0
    vmovq          [r0 + 32], m0
    vmovq          [r0 + 64], m0
    vmovq          [r0 + 96], m0
    ret

INIT_XMM avx2
cglobal predict_8x8_dc_top, 0, 0
    vpxor          m2, m2, m2
    vpsadbw        m0, m2, [r1 + 16]    ; top
    vpsrlw         m0, m0, 2
    vpavgw         m0, m0, m2
    vpbroadcastb   m0, m0
    vmovq          [r0], m0
    vmovq          [r0 + 32], m0
    vmovq          [r0 + 64], m0
    vmovq          [r0 + 96], m0
    add            r0, 128
    vmovq          [r0], m0
    vmovq          [r0 + 32], m0
    vmovq          [r0 + 64], m0
    vmovq          [r0 + 96], m0
    ret

INIT_XMM avx2
cglobal predict_8x8_ddl, 0, 0
    vmovdqu        m0, [r1 + 16]       ; 0 -- 14 15
    vmovdqu        m1, [r1 + 17]       ; 1 -- 15  x
    vmovdqu        m2, [r1 + 18]       ; 2 --  x  x
    vpbroadcastd   m5, [pb_1]
    vpblendw       m2, m2, m1, 80h     ; 2 -- 15  x
    ; m0 -> f1, m1 -> f2, m2 -> f3
    vpavgb         m3, m0, m2          ; Avg(f1, f3)
    vpxor          m4, m0, m2          ; f1 xor f3
    vpand          m4, m4, m5          ; (f1 xor f3) and 1
    vpsubb         m3, m3, m4          ; Avg(f1, f3) - ((f1 xor f3) and 1)
    vpavgb         m0, m1, m3          ; Avg(Avg(f1, f3) - ((f1 xor f3) and 1), f2)
    vmovq          [r0], m0
    vpsrldq        m0, m0, 1
    vmovq          [r0 + 32], m0
    vpsrldq        m0, m0, 1
    vmovq          [r0 + 64], m0
    vpsrldq        m0, m0, 1
    vmovq          [r0 + 96], m0
    vpsrldq        m0, m0, 1
    add            r0, 128
    vmovq          [r0], m0
    vpsrldq        m0, m0, 1
    vmovq          [r0 + 32], m0
    vpsrldq        m0, m0, 1
    vmovq          [r0 + 64], m0
    vpsrldq        m0, m0, 1
    vmovq          [r0 + 96], m0
    ret

INIT_XMM avx2
cglobal predict_8x8_ddr, 0, 0
    vmovdqu        m0, [r1 + 7]        ; l7 -- t5
    vmovdqu        m1, [r1 + 8]        ; l6 -- t6
    vmovdqu        m2, [r1 + 9]        ; l5 -- t7
    vpbroadcastd   m5, [pb_1]
    ; m0 -> f1, m1 -> f2, m2 -> f3
    vpavgb         m3, m0, m2          ; Avg(f1, f3)
    vpxor          m4, m0, m2          ; f1 xor f3
    vpand          m4, m4, m5          ; (f1 xor f3) and 1
    vpsubb         m3, m3, m4          ; Avg(f1, f3) - ((f1 xor f3) and 1)
    vpavgb         m0, m1, m3          ; Avg(Avg(f1, f3) - ((f1 xor f3) and 1), f2)
    add            r0, 128
    vmovq          [r0 + 96], m0
    vpsrldq        m0, m0, 1
    vmovq          [r0 + 64], m0
    vpsrldq        m0, m0, 1
    vmovq          [r0 + 32], m0
    vpsrldq        m0, m0, 1
    vmovq          [r0], m0
    vpsrldq        m0, m0, 1
    vmovq          [r0 - 32], m0
    vpsrldq        m0, m0, 1
    vmovq          [r0 - 64], m0
    vpsrldq        m0, m0, 1
    vmovq          [r0 - 96], m0
    vpsrldq        m0, m0, 1
    vmovq          [r0 - 128], m0
    ret

; l6   l5 l4 ->                            |S(0, 7)
; l5   l4 l3 ->                                                                           |S(0, 6)
; l4   l3 l2 ->                   |S(0, 5) |S(1, 7)
; l3   l2 l1 ->                                                                  |S(0, 4) |S(1, 6)
; l2   l1 l0 ->          |S(0, 3) |S(1, 5) |S(2, 7)
; l1   l0 lt ->                                                         |S(0, 2) |S(1, 4) |S(2, 6)
; l0 | lt t0 -> |S(0, 1) |S(1, 3) |S(2, 5) |S(3, 7)   lt t0 -> |S(0, 0) |S(1, 2) |S(2, 4) |S(3, 6)
; lt | t0 t1 -> |S(1, 1) |S(2, 3) |S(3, 5) |S(4, 7)   t0 t1 -> |S(1, 0) |S(2, 2) |S(3, 4) |S(4, 6)
; t0 | t1 t2 -> |S(2, 1) |S(3, 3) |S(4, 5) |S(5, 7)   t1 t2 -> |S(2, 0) |S(3, 2) |S(4, 4) |S(5, 6)
; t1 | t2 t3 -> |S(3, 1) |S(4, 3) |S(5, 5) |S(6, 7)   t2 t3 -> |S(3, 0) |S(4, 2) |S(5, 4) |S(6, 6)
; t2 | t3 t4 -> |S(4, 1) |S(5, 3) |S(6, 5) |S(7, 7)   t3 t4 -> |S(4, 0) |S(5, 2) |S(6, 4) |S(7, 6)
; t3 | t4 t5 -> |S(5, 1) |S(6, 3) |S(7, 5)            t4 t5 -> |S(5, 0) |S(6, 2) |S(7, 4)
; t4 | t5 t6 -> |S(6, 1) |S(7, 3)                     t5 t6 -> |S(6, 0) |S(7, 2)
; t5 | t6 t7 -> |S(7, 1)                              t6 t7 -> |S(7, 0)
INIT_XMM avx2
cglobal predict_8x8_vr, 0, 0
    vmovdqu        m2, [r1 + 8]        ; l4 -- t7
    vmovdqu        m1, [r1 + 7]        ; l5 -- t6
    vmovdqu        m0, [r1 + 6]        ; l6 -- t5
    vpbroadcastd   m5, [pb_1]
    ; m0 -> f1, m1 -> f2, m2 -> f3
    vpavgb         m3, m0, m2          ; Avg(f1, f3)
    vpxor          m4, m0, m2          ; f1 xor f3
    vpand          m4, m4, m5          ; (f1 xor f3) and 1
    vpsubb         m3, m3, m4          ; Avg(f1, f3) - ((f1 xor f3) and 1)
    vpavgb         m0, m1, m3          ; F2
    vpavgb         m1, m1, m2          ; F1
    vmovhps        [r0], m1
    vmovhps        [r0 + 32], m0
    vpshufb        m0, m0, [predict_8x8_vr_shuf]   ; left part + head of right part
    vpunpckhqdq    m1, m1, m1
    vpalignr       m1, m1, m0, 13      ; right part
    add            r0, 128
    vmovq          [r0 + 64], m1
    vmovq          [r0 + 96], m0
    vpsrldq        m1, m1, 1
    vpsrldq        m0, m0, 1
    vmovq          [r0], m1
    vmovq          [r0 + 32], m0
    vpsrldq        m1, m1, 1
    vpsrldq        m0, m0, 1
    vmovq          [r0 - 64], m1
    vmovq          [r0 - 32], m0
    ret

; l7 l6 | l5 -> |S(1, 7)                                l7 l6 -> |S(0, 7)
; l6 l5 | l4 -> |S(3, 7) |S(1, 6)                       l6 l5 -> |S(2, 7) |S(0, 6)
; l5 l4 | l3 -> |S(5, 7) |S(3, 6) |S(1, 5)              l5 l4 -> |S(4, 7) |S(2, 6) |S(0, 5)
; l4 l3 | l2 -> |S(7, 7) |S(5, 6) |S(3, 5) |S(1, 4)     l4 l3 -> |S(6, 7) |S(4, 6) |S(2, 5) |S(0, 4)
; l3 l2 | l1 -> S(1, 3)| |S(7, 6) |S(5, 5) |S(3, 4)     l3 l2 -> S(0, 3)| |S(6, 6) |S(4, 5) |S(2, 4)
; l2 l1 | l0 -> S(3, 3)| S(1, 2)| |S(7, 5) |S(5, 4)     l2 l1 -> S(2, 3)| S(0, 2)| |S(6, 5) |S(4, 4)
; l1 l0 | lt -> S(5, 3)| S(3, 2)| S(1, 1)| |S(7, 4)     l1 l0 -> S(4, 3)| S(2, 2)| S(0, 1)| |S(6, 4)
; l0 lt | t0 -> S(7, 3)| S(5, 2)| S(3, 1)| S(1, 0)|     l0 lt -> S(6, 3)| S(4, 2)| S(2, 1)|  S(0, 0)|
; lt t0   t1 ->                                                           S(6, 2)| S(4, 1)|  S(2, 0)|
; t0 t1   t2 ->          S(7, 2)| S(5, 1)| S(3, 0)|
; t1 t2   t3 ->                                                                    S(6, 1)|  S(4, 0)|
; t2 t3   t4 ->                   S(7, 1)| S(5, 0)|
; t3 t4   t5 ->                                                                              S(6, 0)|
; t4 t5   t6 ->                            S(7, 0)|
INIT_XMM avx2
cglobal predict_8x8_hd, 0, 0
    vmovdqu        m0, [r1 + 7]          ; l7 -- t4
    vmovdqu        m1, [r1 + 8]          ; l6 -- t5
    vmovdqu        m2, [r1 + 9]          ; l5 -- t6
    vpbroadcastd   m5, [pb_1]
    add            r0, 128
    ; m0 -> f1, m1 -> f2, m2 -> f3
    vpavgb         m3, m0, m2          ; Avg(f1, f3)
    vpxor          m4, m0, m2          ; f1 xor f3
    vpand          m4, m4, m5          ; (f1 xor f3) and 1
    vpsubb         m3, m3, m4          ; Avg(f1, f3) - ((f1 xor f3) and 1)
    vpavgb         m2, m1, m3          ; F2
    vpavgb         m1, m1, m0          ; F1
    vpunpcklbw     m0, m1, m2          ; merge upper part, [7, 4]
    vpunpckhqdq    m1, m0, m2          ; merge lower part, [3, 0]
    vmovq          [r0 + 96], m0
    vmovq          [r0 - 32], m1
    vpsrldq        m0, m0, 2
    vpsrldq        m1, m1, 2
    vmovq          [r0 + 64], m0
    vmovq          [r0 - 64], m1
    vpsrldq        m0, m0, 2
    vpsrldq        m1, m1, 2
    vmovq          [r0 + 32], m0
    vmovq          [r0 - 96], m1
    vpsrldq        m0, m0, 2
    vpsrldq        m1, m1, 2
    vmovq          [r0], m0
    vmovq          [r0 - 128], m1
    ret

;  t0  t1 |  t2 -> S(0, 1)                              t0  t1 -> S(0, 0)
;  t1  t2 |  t3 -> S(1, 1) S(0, 3)                      t1  t2 -> S(1, 0) S(0, 2)
;  t2  t3 |  t4 -> S(2, 1) S(1, 3) S(0, 5)              t2  t3 -> S(2, 0) S(1, 2) S(0, 4)
;  t3  t4 |  t5 -> S(3, 1) S(2, 3) S(1, 5) S(0, 7)      t3  t4 -> S(3, 0) S(2, 2) S(1, 4) S(0, 6)
;  t4  t5 |  t6 -> S(4, 1) S(3, 3) S(2, 5) S(1, 7)      t4  t5 -> S(4, 0) S(3, 2) S(2, 4) S(1, 6)
;  t5  t6 |  t7 -> S(5, 1) S(4, 3) S(3, 5) S(2, 7)      t5  t6 -> S(5, 0) S(4, 2) S(3, 4) S(2, 6)
;  t6  t7 |  t8 -> S(6, 1) S(5, 3) S(4, 5) S(3, 7)      t6  t7 -> S(6, 0) S(5, 2) S(4, 4) S(3, 6)
;  t7  t8 |  t9 -> S(7, 1) S(6, 3) S(5, 5) S(4, 7)      t7  t8 -> S(7, 0) S(6, 2) S(5, 4) S(4, 6)
;  t8  t9 | t10 ->         S(7, 3) S(6, 5) S(5, 7)      t8  t9 ->         S(7, 2) S(6, 4) S(5, 6)
;  t9 t10 | t11 ->                 S(7, 5) S(6, 7)      t9 t10 ->                 S(7, 4) S(6, 6)
; t10 t11 | t12 ->                         S(7, 7)     t10 t11 ->                         S(7, 6)
INIT_XMM avx2
cglobal predict_8x8_vl, 0, 0
    vmovdqu        m0, [r1 + 16]       ; t0 -- t10
    vmovdqu        m1, [r1 + 17]       ; t1 -- t11
    vmovdqu        m2, [r1 + 18]       ; t2 -- t12
    vpbroadcastd   m5, [pb_1]
    ; m0 -> f1, m1 -> f2, m2 -> f3
    vpavgb         m3, m0, m2          ; Avg(f1, f3)
    vpxor          m4, m0, m2          ; f1 xor f3
    vpand          m4, m4, m5          ; (f1 xor f3) and 1
    vpsubb         m3, m3, m4          ; Avg(f1, f3) - ((f1 xor f3) and 1)
    vpavgb         m2, m1, m3          ; F2
    vpavgb         m1, m1, m0          ; F1
    vmovq          [r0], m1
    vmovq          [r0 + 32], m2
    vpsrldq        m1, m1, 1
    vpsrldq        m2, m2, 1
    vmovq          [r0 + 64], m1
    vmovq          [r0 + 96], m2
    add            r0, 128
    vpsrldq        m1, m1, 1
    vpsrldq        m2, m2, 1
    vmovq          [r0], m1
    vmovq          [r0 + 32], m2
    vpsrldq        m1, m1, 1
    vpsrldq        m2, m2, 1
    vmovq          [r0 + 64], m1
    vmovq          [r0 + 96], m2
    ret

; l0 l1 | l2 -> |S(1, 0)                                l0 l1 -> |S(0, 0)
; l1 l2 | l3 -> |S(3, 0) |S(1, 1)                       l1 l2 -> |S(2, 0) |S(0, 1)
; l2 l3 | l4 -> |S(5, 0) |S(3, 1) |S(1, 2)              l2 l3 -> |S(4, 0) |S(2, 1) |S(0, 2)
; l3 l4 | l5 -> |S(7, 0) |S(5, 1) |S(3, 2) |S(1, 3)     l3 l4 -> |S(6, 0) |S(4, 1) |S(2, 2) |S(0, 3)
; l4 l5 | l6 -> S(1, 4)| |S(7, 1) |S(5, 2) |S(3, 3)     l4 l5 -> S(0, 4)| |S(6, 1) |S(4, 2) |S(2, 3)
; l5 l6 | l7 -> S(3, 4)| S(1, 5)| |S(7, 2) |S(5, 3)     l5 l6 -> S(2, 4)| S(0, 5)| |S(6, 2) |S(4, 3)
; l6 l7 | l7 -> S(5, 4)| S(3, 5)| S(1, 6)| |S(7, 3)     l6 l7 -> S(4, 4)| S(2, 5)| S(0, 6)| |S(6, 3)
; l7 l7      -> S(7, 4)|          S(3, 6)|                       S(6, 4)|          S(2, 6)|
; l7 l7      -> ... 
INIT_XMM avx2
cglobal predict_8x8_hu, 0, 0
    vmovq          m0, [r1 + 7]        ; l7 l6 l5 l4 l3 l2 l1 l0
    vpbroadcastb   m3, m0              ; l7...
    vpalignr       m1, m0, m3, 15      ; l7 l7 l6 l5 l4 l3 l2 l1
    vpalignr       m2, m0, m3, 14      ; l7 l7 l7 l6 l5 l4 l3 l2
    vpbroadcastd   m5, [pb_1]
    add            r0, 128
    vmovq          [r0 + 96], m3
    ; m0 -> f1, m1 -> f2, m2 -> f3
    vpavgb         m4, m0, m2          ; Avg(f1, f3)
    vpxor          m2, m0, m2          ; f1 xor f3
    vpand          m2, m2, m5          ; (f1 xor f3) and 1
    vpsubb         m4, m4, m2          ; Avg(f1, f3) - ((f1 xor f3) and 1)
    vpavgb         m2, m1, m4          ; F2
    vpavgb         m1, m1, m0          ; F1
    vpunpcklbw     m0, m2, m1
    vpshufb        m0, m0, [predict_8x8_hu_shuf]
    vmovq          [r0 - 128], m0
    vmovhps        [r0], m0
    vpalignr       m0, m3, m0, 2
    vmovq          [r0 - 96], m0
    vmovhps        [r0 + 32], m0
    vpalignr       m0, m3, m0, 2
    vmovq          [r0 - 64], m0
    vmovhps        [r0 + 64], m0
    vpsrldq        m0, m0, 2
    vmovq          [r0 - 32], m0
    ret

; The above functions only use [7, 31], 
; but [6] and [32] play a role somewhere,
; need to check it
INIT_XMM avx2
cglobal predict_8x8_filter, 0, 0
    vpbroadcastd   m5, [pb_1]
    test           r3b, 1
    jz             .check_top               ; MB_LEFT

    lea            r6, [r0 + 128]
    vmovq          m0, [r6 + 56]            ;  x l6 |
    vpinsrb        m0, m0, [r6 + 95], 6     ; l7 l6 |
    vpinsrb        m0, m0, [r6 + 31], 8     ; l7 l6 | l5
    vpinsrb        m0, m0, [r6 - 1], 9      ; l7 l6 | l5 l4
    vpinsrb        m0, m0, [r0 + 95], 10    ; l7 l6 | l5 l4 l3
    vpinsrb        m0, m0, [r0 + 63], 11    ; l7 l6 | l5 l4 l3 l2
    vpinsrb        m0, m0, [r0 + 31], 12    ; l7 l6 | l5 l4 l3 l2 l1
    vpinsrb        m0, m0, [r0 - 1], 13     ; l7 l6 | l5 l4 l3 l2 l1 l0
    vpinsrw        m0, m0, [r0 - 33], 7     ; l7 l6 | l5 l4 l3 l2 l1 l0 lt t0
    vpslldq        m1, m0, 1                ;    l7 | l6 l5 l4 l3 l2 l1 l0 lt
    vpslldq        m2, m0, 2
    vpblendd       m2, m2, m1, 03h          ;    l7 | l7 l6 l5 l4 l3 l2 l1 l0
    lea            r6, [r0 - 1]             ; l0
    lea            r4, [r0 - 33]            ; lt
    test           r2b, 8
    cmovnz         r6, r4
    vpinsrb        m0, m0, [r6], 14         ; have_lt
    ; m0 -> f1, m1 -> f2, m2 -> f3
    vpavgb         m4, m0, m2               ; Avg(f1, f3)
    vpxor          m2, m0, m2               ; f1 xor f3
    vpand          m2, m2, m5               ; (f1 xor f3) and 1
    vpsubb         m4, m4, m2               ; Avg(f1, f3) - ((f1 xor f3) and 1)
    vpavgb         m2, m1, m4               ; F2
    vmovdqu        [r1], m2
    vpextrb        [r1 + 6], m2, 7

.check_top:
    test           r3b, 2
    jz             .end                     ; MB_TOP

    vmovdqu        m0, [r0 - 33]            ;  x t0 -- t13 t14
    vmovdqu        m1, [r0 - 32]            ; t0 t1 -- t14 t15
    vmovdqu        m2, [r0 - 31]            ; t1 t2 -- t15   x
    lea            r6, [r0 - 32]            ; t0
    lea            r4, [r0 - 33]            ; lt
    test           r2b, 8
    cmovnz         r6, r4
    vpinsrb        m0, m0, [r6], 0          ; have_lt
    test           r2b, 4
    jz             .no_tr                   ; have_tr
    
    vpinsrb        m2, m2, [r0 - 17], 15    ; t1 t2 -- t15 t15
    vpavgb         m4, m0, m2               ; Avg(f1, f3)
    vpxor          m2, m0, m2               ; f1 xor f3
    vpand          m2, m2, m5               ; (f1 xor f3) and 1
    vpsubb         m4, m4, m2               ; Avg(f1, f3) - ((f1 xor f3) and 1)
    vpavgb         m2, m1, m4               ; F2
    test           r3b, 4
    jz             .no_topright             ; MB_TOPRIGHT
    vmovdqu        [r1 + 16], m2
    vpextrb        [r1 + 32], m2, 15
    ret

.no_tr:
    vpbroadcastb   m3, [r0 - 25]            ; t7
    vpblendw       m2, m2, m3, 08h          ; t1 t2 t3 t4 t5 t6 t7 t7
    vpavgb         m4, m0, m2               ; Avg(f1, f3)
    vpxor          m2, m0, m2               ; f1 xor f3
    vpand          m2, m2, m5               ; (f1 xor f3) and 1
    vpsubb         m4, m4, m2               ; Avg(f1, f3) - ((f1 xor f3) and 1)
    vpavgb         m2, m1, m4               ; F2
    test           r3b, 4
    jz             .no_topright             ; MB_TOPRIGHT
    vpblendd       m2, m2, m3, 0Ch
    vmovdqu        [r1 + 16], m2
    vpextrb        [r1 + 32], m3, 0
    ret

.no_topright:
    vmovq          [r1 + 16], m2
.end:
    ret

