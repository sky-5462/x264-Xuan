;*****************************************************************************
;* deblock-a.asm: x86 deblocking
;*****************************************************************************
;* Copyright (C) 2005-2019 x264 project
;*
;* Authors: Loren Merritt <lorenm@u.washington.edu>
;*          Fiona Glaser <fiona@x264.com>
;*          Oskar Arvidsson <oskar@irock.se>
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

SECTION_RODATA 32

load_bytes_ymm_shuf: dd 0x06050403, 0x0e0d0c1b, 0x07060544, 0x0f0e0d5c
                     dd 0x06050473, 0x0e0d0c2b, 0x07060534, 0x0f0e0d6c
transpose_shuf: db 0,4,8,12,1,5,9,13,2,6,10,14,3,7,11,15

SECTION .text

cextern pb_1
cextern pb_3
cextern pb_a1
cextern pw_2
cextern pb_unpackbd1

;=============================================================================
; deblock_luma
;=============================================================================
INIT_XMM avx2
cglobal deblock_v_luma, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    vmovdqu        [rsp + 8], m6
    vmovdqu        [rsp + 24], m7
    sub            rsp, 88
    vmovdqu        [rsp], m8
    vmovdqu        [rsp + 16], m9
    vmovdqu        [rsp + 32], m10
    vmovdqu        [rsp + 48], m11
    vmovdqu        [rsp + 64], m12
%endif
    vmovd          m0, [r4]
    vpshufb        m0, m0, [pb_unpackbd1]    ; tc0 tc1 tc2 tc3
    lea            r5d, [r1 + r1 * 2]  ; 3 * xstride
    mov            r6, r0              ; pix
    sub            r0, r5              ; pix - 3 * xstride
    vmovd          m5, r2d
    vmovd          m6, r3d
    vmovdqu        m1, [r0 + r1]       ; p1
    vmovdqu        m2, [r0 + r1 * 2]   ; p0
    vmovdqu        m3, [r6]            ; q0
    vmovdqu        m4, [r6 + r1]       ; q1
    vpbroadcastb   m5, m5              ; alpha
    vpbroadcastb   m6, m6              ; beta
    vpbroadcastd   m7, [pb_1]
    ; alpha and beta must > 0, so we can safely -1
    vpsubb         m5, m5, m7          ; alpha - 1
    vpsubb         m6, m6, m7          ; beta - 1

    vpsubusb       m8, m2, m3
    vpsubusb       m9, m3, m2
    vpor           m8, m8, m9          ; abs(p0 - q0)
    vpsubusb       m8, m8, m5          ; abs(p0 - q0) < alpha ? 0 : else
    vpsubusb       m5, m1, m2
    vpsubusb       m9, m2, m1
    vpor           m5, m5, m9          ; abs(p1 - p0)
    vpsubusb       m9, m3, m4
    vpsubusb       m10, m4, m3
    vpor           m9, m9, m10         ; abs(q1 - q0)
    vpmaxub        m5, m5, m9          ; take the bigger one to compare with beta
    vpsubusb       m5, m5, m6          ; abs(val) < beta ? 0 : else
    vpor           m8, m5, m8
    vpxor          m5, m5, m5
    vpcmpeqb       m8, m8, m5          ; mask for the three abs, -1 for true, 0 for false
    vpblendvb      m8, m8, m5, m0      ; set mask to 0 if tc0 is negative
    vpand          m0, m0, m8          ; set tc0 to 0 if mask is 0

    vmovdqu        m9, [r0]            ; p2
    vmovdqu        m10, [r6 + r1 * 2]  ; q2
    vpsubusb       m11, m9, m2
    vpsubusb       m12, m2, m9
    vpor           m11, m11, m12       ; abs(p2 - p0)
    vpsubusb       m12, m10, m3
    vpsubusb       m5, m3, m10
    vpor           m12, m12, m5        ; abs(q2 - q0)
    vpsubusb       m11, m11, m6        ; abs(p2 - p0) < beta ? 0 : else
    vpsubusb       m12, m12, m6        ; abs(q2 - q0) < beta ? 0 : else
    vpxor          m5, m5, m5
    vpcmpeqb       m11, m11, m5        ; abs(p2 - p0) < beta ? -1 : 0
    vpcmpeqb       m12, m12, m5        ; abs(q2 - q0) < beta ? -1 : 0
    vpand          m11, m11, m8        ; mask for p1, -1 for true, 0 for false
    vpand          m12, m12, m8        ; mask for q1, -1 for true, 0 for false
    vpand          m5, m7, m11
    vpaddb         m6, m0, m5
    vpand          m5, m7, m12
    vpaddb         m6, m6, m5          ; masked tc++
    vpand          m11, m11, m0
    vpand          m12, m12, m0        ; masked tc0

    vpavgb         m5, m2, m3          ; Avg(p0, q0)
    vpxor          m0, m5, m9          ; Avg(p0, q0) xor p2
    vpavgb         m9, m5, m9          ; Avg(Avg(p0, q0), p2)
    vpxor          m8, m5, m10         ; Avg(p0, q0) xor q2
    vpavgb         m10, m5, m10        ; Avg(Avg(p0, q0), q2)
    vpand          m0, m0, m7          ; (Avg(p0, q0) xor p2) and 1
    vpand          m8, m8, m7          ; (Avg(p0, q0) xor q2) and 1
    vpsubb         m9, m9, m0          ; (p2 + ((p0 + q0 + 1) >> 1)) >> 1
    vpsubb         m10, m10, m8        ; (q2 + ((p0 + q0 + 1) >> 1)) >> 1
    ; clip the result within the range of [-tc0, tc0], set tc0 to 0 if it is false
    ; need saturated operations to prevent overflow, but it won't affect results
    vpaddusb       m0, m1, m11
    vpsubusb       m5, m1, m11         ; range for p1
    vpaddusb       m8, m4, m12
    vpsubusb       m11, m4, m12        ; range for q1
    vpminub        m9, m9, m0
    vpmaxub        m9, m9, m5
    vpminub        m10, m10, m8
    vpmaxub        m10, m10, m11
    vmovdqu        [r0 + r1], m9
    vmovdqu        [r6 + r1], m10

    ; calculate the delta, but I can't figure out how it works :(
    vpbroadcastd   m0, [pb_3]
    vpbroadcastd   m5, [pb_a1]
    vpxor          m8, m2, m3          ; p0 xor q0
    vpand          m8, m8, m7          ; (p0 xor q0) and 1
    vpcmpeqb       m9, m9, m9
    vpxor          m4, m9, m4
    vpavgb         m4, m4, m1          ; Avg(Not q1, p1) = (p1 - q1 + 256)>>1
    vpavgb         m4, m4, m0          ; (((p1 - q1 + 256)>>1)+4)>>1 = 64+2+(p1-q1)>>2
    vpxor          m9, m9, m2
    vpavgb         m9, m9, m3          ; Avg(Not p0, q0) = (q0 - p0 + 256)>>1
    vpavgb         m4, m4, m8          ; Avg(64+2+(p1-q1)>>2, (p0 xor q0) and 1)
    vpaddusb       m4, m4, m9          ; delta + 161
    vpsubusb       m9, m5, m4          ; negative delta
    vpsubusb       m8, m4, m5          ; positive delta
    vpminub        m9, m9, m6
    vpminub        m8, m8, m6          ; limit range in [-tc, tc]
    vpaddusb       m2, m2, m8
    vpaddusb       m3, m3, m9
    vpsubusb       m2, m2, m9
    vpsubusb       m3, m3, m8
    vmovdqu        [r0 + r1 * 2], m2
    vmovdqu        [r6], m3

%if WIN64
    vmovdqu        m8, [rsp]
    vmovdqu        m9, [rsp + 16]
    vmovdqu        m10, [rsp + 32]
    vmovdqu        m11, [rsp + 48]
    vmovdqu        m12, [rsp + 64]
    add            rsp, 88
    vmovdqu        m6, [rsp + 8]
    vmovdqu        m7, [rsp + 24]
%endif
    ret

INIT_XMM avx2
cglobal deblock_h_luma, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    vmovdqu        [rsp + 8], m6
    vmovdqu        [rsp + 24], m7
    sub            rsp, 104
    vmovdqu        [rsp], m8
    vmovdqu        [rsp + 16], m9
    vmovdqu        [rsp + 32], m10
    vmovdqu        [rsp + 48], m11
    vmovdqu        [rsp + 64], m12
    vmovdqu        [rsp + 80], m13
%endif
    vmovd          m11, [r4]
    vpshufb        m11, m11, [pb_unpackbd1]    ; tc0 tc1 tc2 tc3
    lea            r5, [r1 + r1 * 2]   ; 3 * stride
    sub            r0, 3               ; pix
    lea            r6, [r0 + r1 * 4]   ; pix + 4 * stride
    vmovq          m0, [r0]
    vmovq          m1, [r0 + r1]
    vpunpcklbw     m0, m0, m1          ; 0 1
    vmovq          m1, [r0 + r1 * 2]
    vmovq          m2, [r0 + r5]
    vpunpcklbw     m1, m1, m2          ; 2 3
    vmovq          m2, [r6]
    vmovq          m3, [r6 + r1]
    vpunpcklbw     m2, m2, m3          ; 4 5
    vmovq          m3, [r6 + r1 * 2]
    vmovq          m4, [r6 + r5]
    vpunpcklbw     m3, m3, m4          ; 6 7
    vpunpcklwd     m4, m0, m1          ; 0 -- 3 p2 p1 p0 q0
    vpunpckhwd     m5, m0, m1          ; 0 -- 3 q0 q1
    vpunpcklwd     m6, m2, m3          ; 4 -- 7 p2 p1 p0 q0
    vpunpckhwd     m7, m2, m3          ; 4 -- 7 q0 q1
    vpunpckldq     m3, m4, m6          ; 0 -- 7 p2 p1
    vpunpckhdq     m4, m4, m6          ; 0 -- 7 p0 q0
    vpunpckldq     m5, m5, m7          ; 0 -- 7 q1 q2

    lea            r4, [r0 + r1 * 8]
    lea            r6, [r6 + r1 * 8]
    vmovq          m0, [r4]
    vmovq          m1, [r4 + r1]
    vpunpcklbw     m0, m0, m1          ; 8 9
    vmovq          m1, [r4 + r1 * 2]
    vmovq          m2, [r4 + r5]
    vpunpcklbw     m1, m1, m2          ; 10 11
    vmovq          m2, [r6]
    vmovq          m6, [r6 + r1]
    vpunpcklbw     m2, m2, m6          ; 12 13
    vmovq          m6, [r6 + r1 * 2]
    vmovq          m7, [r6 + r5]
    vpunpcklbw     m6, m6, m7          ; 14 15
    vpunpcklwd     m7, m0, m1          ;  8 -- 11 p2 p1 p0 q0
    vpunpckhwd     m8, m0, m1          ;  8 -- 11 q0 q1
    vpunpcklwd     m9, m2, m6          ; 12 -- 15 p2 p1 p0 q0
    vpunpckhwd     m10, m2, m6         ; 12 -- 15 q0 q1
    vpunpckldq     m6, m7, m9          ;  8 -- 15 p2 p1
    vpunpckhdq     m7, m7, m9          ;  8 -- 15 p0 q0
    vpunpckldq     m8, m8, m10         ;  8 -- 15 q1 q2

    vpunpcklqdq    m0, m3, m6          ; p2
    vpunpckhqdq    m1, m3, m6          ; p1
    vpunpcklqdq    m2, m4, m7          ; p0
    vpunpckhqdq    m3, m4, m7          ; q0
    vpunpcklqdq    m4, m5, m8          ; q1
    vpunpckhqdq    m5, m5, m8          ; q2

    vpbroadcastd   m13, [pb_1]
    vmovd          m6, r2d
    vmovd          m7, r3d
    vpbroadcastb   m6, m6              ; alpha
    vpbroadcastb   m7, m7              ; beta
    ; alpha and beta must > 0, so we can safely -1
    vpsubb         m6, m6, m13         ; alpha - 1
    vpsubb         m7, m7, m13         ; beta - 1

    vpsubusb       m8, m2, m3
    vpsubusb       m9, m3, m2
    vpor           m8, m8, m9          ; abs(p0 - q0)
    vpsubusb       m8, m8, m6          ; abs(p0 - q0) < alpha ? 0 : else
    vpsubusb       m6, m1, m2
    vpsubusb       m9, m2, m1
    vpor           m6, m6, m9          ; abs(p1 - p0)
    vpsubusb       m9, m3, m4
    vpsubusb       m10, m4, m3
    vpor           m9, m9, m10         ; abs(q1 - q0)
    vpmaxub        m6, m6, m9          ; take the bigger one to compare with beta
    vpsubusb       m6, m6, m7          ; abs(val) < beta ? 0 : else
    vpor           m8, m6, m8
    vpxor          m6, m6, m6
    vpcmpeqb       m8, m8, m6          ; mask for the three abs, -1 for true, 0 for false
    vpblendvb      m8, m8, m6, m11     ; set mask to 0 if tc0 is negative
    vpand          m11, m11, m8        ; set tc0 to 0 if mask is 0

    vpsubusb       m9, m0, m2
    vpsubusb       m10, m2, m0
    vpor           m9, m9, m10         ; abs(p2 - p0)
    vpsubusb       m10, m5, m3
    vpsubusb       m12, m3, m5
    vpor           m10, m10, m12       ; abs(q2 - q0)
    vpsubusb       m9, m9, m7          ; abs(p2 - p0) < beta ? 0 : else
    vpsubusb       m10, m10, m7        ; abs(q2 - q0) < beta ? 0 : else
    vpcmpeqb       m9, m9, m6          ; abs(p2 - p0) < beta ? -1 : 0
    vpcmpeqb       m10, m10, m6        ; abs(q2 - q0) < beta ? -1 : 0
    vpand          m9, m9, m8          ; mask for p1, -1 for true, 0 for false
    vpand          m10, m10, m8        ; mask for q1, -1 for true, 0 for false
    vpand          m6, m13, m9
    vpaddb         m6, m6, m11
    vpand          m7, m13, m10
    vpaddb         m6, m6, m7          ; masked tc++
    vpand          m9, m9, m11
    vpand          m10, m10, m11       ; masked tc0

    vpavgb         m7, m2, m3          ; Avg(p0, q0)
    vpxor          m8, m7, m0          ; Avg(p0, q0) xor p2
    vpavgb         m0, m7, m0          ; Avg(Avg(p0, q0), p2)
    vpxor          m11, m7, m5         ; Avg(p0, q0) xor q2
    vpavgb         m5, m7, m5          ; Avg(Avg(p0, q0), q2)
    vpand          m8, m8, m13         ; (Avg(p0, q0) xor p2) and 1
    vpand          m11, m11, m13       ; (Avg(p0, q0) xor q2) and 1
    vpsubb         m0, m0, m8          ; (p2 + ((p0 + q0 + 1) >> 1)) >> 1
    vpsubb         m5, m5, m11         ; (q2 + ((p0 + q0 + 1) >> 1)) >> 1
    ; clip the result within the range of [-tc0, tc0], set tc0 to 0 if it is false
    ; need saturated operations to prevent overflow, but it won't affect results
    vpaddusb       m7, m1, m9
    vpsubusb       m8, m1, m9          ; range for p1
    vpaddusb       m9, m4, m10
    vpsubusb       m10, m4, m10        ; range for q1
    vpminub        m0, m0, m7
    vpmaxub        m0, m0, m8          ; p1
    vpminub        m5, m5, m9          ; q1
    vpmaxub        m5, m5, m10

    ; calculate the delta, but I can't figure out how it works :(
    vpbroadcastd   m7, [pb_3]
    vpbroadcastd   m8, [pb_a1]
    vpxor          m9, m2, m3          ; p0 xor q0
    vpand          m9, m9, m13         ; (p0 xor q0) and 1
    vpcmpeqb       m10, m10, m10
    vpxor          m4, m10, m4
    vpavgb         m4, m4, m1          ; Avg(Not q1, p1) = (p1 - q1 + 256)>>1
    vpavgb         m4, m4, m7          ; (((p1 - q1 + 256)>>1)+4)>>1 = 64+2+(p1-q1)>>2
    vpxor          m10, m10, m2
    vpavgb         m10, m10, m3        ; Avg(Not p0, q0) = (q0 - p0 + 256)>>1
    vpavgb         m4, m4, m9          ; Avg(64+2+(p1-q1)>>2, (p0 xor q0) and 1)
    vpaddusb       m4, m4, m10         ; delta + 161
    vpsubusb       m9, m8, m4          ; negative delta
    vpsubusb       m8, m4, m8          ; positive delta
    vpminub        m9, m9, m6
    vpminub        m8, m8, m6          ; limit range in [-tc, tc]
    vpaddusb       m2, m2, m8
    vpaddusb       m3, m3, m9
    vpsubusb       m6, m2, m9          ; p0
    vpsubusb       m7, m3, m8          ; q0

    ; transpose
    vpunpcklbw     m1, m0, m6
    vpunpckhbw     m2, m0, m6
    vpunpcklbw     m3, m7, m5
    vpunpckhbw     m4, m7, m5
    vpunpcklwd     m5, m1, m3
    vpunpckhwd     m6, m1, m3
    vpunpcklwd     m7, m2, m4
    vpunpckhwd     m8, m2, m4
    ; save
    add            r0, 1               ; p1
    lea            r4, [r0 + r1 * 4]   ; p1 + 4 * stride
    lea            r6, [r0 + r1 * 8]   ; p1 + 8 * stride
    lea            r2, [r4 + r1 * 8]   ; p1 + 12 * stride
    vmovd          [r0], m5
    vpextrd        [r0 + r1], m5, 1
    vpextrd        [r0 + r1 * 2], m5, 2
    vpextrd        [r0 + r5], m5, 3
    vmovd          [r4], m6
    vpextrd        [r4 + r1], m6, 1
    vpextrd        [r4 + r1 * 2], m6, 2
    vpextrd        [r4 + r5], m6, 3
    vmovd          [r6], m7
    vpextrd        [r6 + r1], m7, 1
    vpextrd        [r6 + r1 * 2], m7, 2
    vpextrd        [r6 + r5], m7, 3
    vmovd          [r2], m8
    vpextrd        [r2 + r1], m8, 1
    vpextrd        [r2 + r1 * 2], m8, 2
    vpextrd        [r2 + r5], m8, 3

%if WIN64
    vmovdqu        m8, [rsp]
    vmovdqu        m9, [rsp + 16]
    vmovdqu        m10, [rsp + 32]
    vmovdqu        m11, [rsp + 48]
    vmovdqu        m12, [rsp + 64]
    vmovdqu        m13, [rsp + 80]
    add            rsp, 104
    vmovdqu        m6, [rsp + 8]
    vmovdqu        m7, [rsp + 24]
%endif
    ret


;=============================================================================
; deblock_chroma
;=============================================================================
INIT_XMM avx2
cglobal deblock_v_chroma, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    vmovdqu        [rsp + 8], m6
    vmovdqu        [rsp + 24], m7
    sub            rsp, 24
    vmovdqu        [rsp], m8
%endif
    vmovd          m0, [r4]
    vpshufb        m0, m0, [pb_unpackbd1]    ; tc0 tc1 tc2 tc3
    mov            r6, r0              ; pix
    sub            r0, r1
    sub            r0, r1              ; pix - 2 * xstride
    vmovdqu        m1, [r0]            ; p1
    vmovdqu        m2, [r0 + r1]       ; p0
    vmovdqu        m3, [r6]            ; q0
    vmovdqu        m4, [r6 + r1]       ; q1

    vpsubusb       m5, m1, m2
    vpsubusb       m6, m2, m1
    vpor           m5, m5, m6          ; abs(p1 - p0)
    vpsubusb       m6, m3, m4
    vpsubusb       m7, m4, m3
    vpor           m6, m6, m7          ; abs(q1 - q0)
    vpmaxub        m5, m5, m6          ; take the bigger one to compare with beta
    vpbroadcastd   m7, [pb_1]
    vmovd          m6, r3d
    vpbroadcastb   m6, m6              ; beta
    vpsubb         m6, m6, m7          ; beta - 1
    vpsubusb       m5, m5, m6          ; abs(val) < beta ? 0 : else

    vpsubusb       m6, m2, m3
    vpsubusb       m8, m3, m2
    vpor           m6, m6, m8          ; abs(p0 - q0)
    vmovd          m8, r2d
    vpbroadcastb   m8, m8              ; alpha
    vpsubb         m8, m8, m7          ; alpha - 1
    vpsubusb       m6, m6, m8          ; abs(p0 - q0) < alpha ? 0 : else
    vpor           m6, m5, m6

    vpxor          m5, m5, m5
    vpcmpeqb       m6, m6, m5          ; mask for the three abs, -1 for true, 0 for false
    vpblendvb      m6, m6, m5, m0      ; set mask to 0 if tc0 is negative
    vpand          m6, m0, m6          ; set tc0 to 0 if mask is 0

    ; calculate the delta, but I can't figure out how it works :(
    vpbroadcastd   m0, [pb_3]
    vpbroadcastd   m5, [pb_a1]
    vpxor          m8, m2, m3          ; p0 xor q0
    vpand          m8, m8, m7          ; (p0 xor q0) and 1
    vpcmpeqb       m7, m7, m7
    vpxor          m4, m7, m4
    vpavgb         m4, m4, m1          ; Avg(Not q1, p1) = (p1 - q1 + 256)>>1
    vpavgb         m4, m4, m0          ; (((p1 - q1 + 256)>>1)+4)>>1 = 64+2+(p1-q1)>>2
    vpxor          m7, m7, m2
    vpavgb         m7, m7, m3          ; Avg(Not p0, q0) = (q0 - p0 + 256)>>1
    vpavgb         m4, m4, m8          ; Avg(64+2+(p1-q1)>>2, (p0 xor q0) and 1)
    vpaddusb       m4, m4, m7          ; delta + 161
    vpsubusb       m7, m5, m4          ; negative delta
    vpsubusb       m8, m4, m5          ; positive delta
    vpminub        m7, m7, m6
    vpminub        m8, m8, m6          ; limit range in [-tc, tc]
    vpaddusb       m2, m2, m8
    vpaddusb       m3, m3, m7
    vpsubusb       m2, m2, m7
    vpsubusb       m3, m3, m8
    vmovdqu        [r0 + r1], m2
    vmovdqu        [r6], m3

%if WIN64
    vmovdqu        m8, [rsp]
    add            rsp, 24
    vmovdqu        m6, [rsp + 8]
    vmovdqu        m7, [rsp + 24]
%endif
    ret

INIT_XMM avx2
cglobal deblock_h_chroma, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    vmovdqu        [rsp + 8], m6
    vmovdqu        [rsp + 24], m7
    sub            rsp, 24
    vmovdqu        [rsp], m8
%endif
    vmovd          m0, [r4]
    vpshufb        m0, m0, [pb_unpackbd1]    ; tc0 tc1 tc2 tc3

    ; load and transpose
    lea            r5, [r1 + r1 * 2]   ; 3 * stride
    sub            r0, 4
    lea            r6, [r0 + r1 * 4]
    vmovq          m1, [r0]
    vmovq          m2, [r0 + r1]
    vpunpcklwd     m1, m1, m2          ; row0 row1(p1) row0 row1(p0) row0 row1(q0) row0 row1(q1)
    vmovq          m2, [r0 + r1 * 2]
    vmovq          m3, [r0 + r5]
    vpunpcklwd     m2, m2, m3          ; row2 row3(p1) row2 row3(p0) row2 row3(q0) row2 row3(q1)
    vmovq          m3, [r6]
    vmovq          m4, [r6 + r1]
    vpunpcklwd     m3, m3, m4          ; row4 row5(p1) row4 row5(p0) row4 row5(q0) row4 row5(q1)
    vmovq          m4, [r6 + r1 * 2]
    vmovq          m5, [r6 + r5]
    vpunpcklwd     m4, m4, m5          ; row6 row7(p1) row6 row7(p0) row6 row7(q0) row6 row7(q1)

    vpunpckldq     m5, m1, m2          ; row0 row1 row2 row3(p1) row0 row1 row2 row3(p0)
    vpunpckhdq     m6, m1, m2          ; row0 row1 row2 row3(q0) row0 row1 row2 row3(q1)
    vpunpckldq     m7, m3, m4          ; row4 row5 row6 row7(p1) row4 row5 row6 row7(p0)
    vpunpckhdq     m8, m3, m4          ; row4 row5 row6 row7(q0) row4 row5 row6 row7(q1)

    vpunpcklqdq    m1, m5, m7          ; row0 row1 row2 row3 row4 row5 row6 row7(p1)
    vpunpckhqdq    m2, m5, m7          ; row0 row1 row2 row3 row4 row5 row6 row7(p0)
    vpunpcklqdq    m3, m6, m8          ; row0 row1 row2 row3 row4 row5 row6 row7(q0)
    vpunpckhqdq    m4, m6, m8          ; row0 row1 row2 row3 row4 row5 row6 row7(q1)

    vpsubusb       m5, m1, m2
    vpsubusb       m6, m2, m1
    vpor           m5, m5, m6          ; abs(p1 - p0)
    vpsubusb       m6, m3, m4
    vpsubusb       m7, m4, m3
    vpor           m6, m6, m7          ; abs(q1 - q0)
    vpmaxub        m5, m5, m6          ; take the bigger one to compare with beta
    vpbroadcastd   m7, [pb_1]
    vmovd          m6, r3d
    vpbroadcastb   m6, m6              ; beta
    vpsubb         m6, m6, m7          ; beta - 1
    vpsubusb       m5, m5, m6          ; abs(val) < beta ? 0 : else

    vpsubusb       m6, m2, m3
    vpsubusb       m8, m3, m2
    vpor           m6, m6, m8          ; abs(p0 - q0)
    vmovd          m8, r2d
    vpbroadcastb   m8, m8              ; alpha
    vpsubb         m8, m8, m7          ; alpha - 1
    vpsubusb       m6, m6, m8          ; abs(p0 - q0) < alpha ? 0 : else
    vpor           m6, m5, m6

    vpxor          m5, m5, m5
    vpcmpeqb       m6, m6, m5          ; mask for the three abs, -1 for true, 0 for false
    vpblendvb      m6, m6, m5, m0      ; set mask to 0 if tc0 is negative
    vpand          m6, m0, m6          ; set tc0 to 0 if mask is 0

    ; calculate the delta, but I can't figure out how it works :(
    vpbroadcastd   m0, [pb_3]
    vpbroadcastd   m5, [pb_a1]
    vpxor          m8, m2, m3          ; p0 xor q0
    vpand          m8, m8, m7          ; (p0 xor q0) and 1
    vpcmpeqb       m7, m7, m7
    vpxor          m4, m7, m4
    vpavgb         m4, m4, m1          ; Avg(Not q1, p1) = (p1 - q1 + 256)>>1
    vpavgb         m4, m4, m0          ; (((p1 - q1 + 256)>>1)+4)>>1 = 64+2+(p1-q1)>>2
    vpxor          m7, m7, m2
    vpavgb         m7, m7, m3          ; Avg(Not p0, q0) = (q0 - p0 + 256)>>1
    vpavgb         m4, m4, m8          ; Avg(64+2+(p1-q1)>>2, (p0 xor q0) and 1)
    vpaddusb       m4, m4, m7          ; delta + 161
    vpsubusb       m7, m5, m4          ; negative delta
    vpsubusb       m8, m4, m5          ; positive delta
    vpminub        m7, m7, m6
    vpminub        m8, m8, m6          ; limit range in [-tc, tc]
    vpaddusb       m2, m2, m8
    vpaddusb       m3, m3, m7
    vpsubusb       m2, m2, m7          ; p0
    vpsubusb       m3, m3, m8          ; q0

    ; shuffle and save
    add            r0, 2
    add            r6, 2
    vpunpcklwd     m0, m2, m3          ; row0 row1 row2 row3
    vpunpckhwd     m1, m2, m3          ; row4 row5 row6 row7
    vmovd          [r0], m0
    vpextrd        [r0 + r1], m0, 1
    vpextrd        [r0 + r1 * 2], m0, 2
    vpextrd        [r0 + r5], m0, 3
    vmovd          [r6], m1
    vpextrd        [r6 + r1], m1, 1
    vpextrd        [r6 + r1 * 2], m1, 2
    vpextrd        [r6 + r5], m1, 3

%if WIN64
    vmovdqu        m8, [rsp]
    add            rsp, 24
    vmovdqu        m6, [rsp + 8]
    vmovdqu        m7, [rsp + 24]
%endif
    ret


;=============================================================================
; deblock_luma_intra
;=============================================================================
INIT_YMM avx2
cglobal deblock_v_luma_intra, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 88
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
%endif
    vmovd          xm0, r2d
    vmovd          xm1, r3d
    vpbroadcastw   m0, xm0             ; alpha
    vpbroadcastw   m1, xm1             ; beta
    lea            r5d, [r1 + r1 * 2]  ; 3 * xstride
    mov            r6, r0              ; pix
    sub            r0, r1
    sub            r0, r5              ; pix - 4 * xstride

    vpmovzxbw      m2, [r0 + r1]       ; p2
    vpmovzxbw      m3, [r0 + r1 * 2]   ; p1
    vpmovzxbw      m4, [r0 + r5]       ; p0
    vpmovzxbw      m5, [r6]            ; q0
    vpmovzxbw      m6, [r6 + r1]       ; q1
    vpmovzxbw      m7, [r6 + r1 * 2]   ; q2

    vpsubw         m8, m4, m5
    vpabsw         m8, m8              ; abs(p0 - q0)
    vpcmpgtw       m9, m0, m8          ; abs(p0 - q0) < alpha ? -1 : 0
    vpbroadcastd   m10, [pw_2]
    vpsrlw         m0, m0, 2
    vpaddw         m0, m0, m10         ; (alpha >> 2) + 2
    vpcmpgtw       m0, m0, m8          ; (abs(p0 - q0) < (alpha >> 2) + 2) ? -1 : 0
    vpsubw         m8, m3, m4
    vpabsw         m8, m8              ; abs(p1 - p0)
    vpsubw         m10, m6, m5
    vpabsw         m10, m10            ; abs(q1 - q0)
    vpmaxuw        m8, m8, m10         ; take the bigger one to compare with beta
    vpcmpgtw       m8, m1, m8          ; abs(val) < beta ? -1 : 0
    vpand          m8, m8, m9          ; mask for the outer "if"
    vpand          m0, m0, m8          ; mask for the middle "if"

    vpaddw         m9, m3, m4
    vpaddw         m10, m5, m6
    vpaddw         m9, m9, m10         ; p1 + p0 + q0 + q1
    vpsubw         m10, m3, m5         ; p1 - q0
    vpsubw         m11, m6, m4         ; q1 - p0
    vpaddw         m10, m10, m9        ; 2 * p1 + p0 + q1
    vpaddw         m11, m11, m9        ; 2 * q1 + q0 + p1
    vpsrlw         m10, m10, 1
    vpsrlw         m11, m11, 1
    vpxor          m12, m12, m12
    vpavgw         m10, m10, m12       ; (2 * p1 + p0 + q1 + 2) >> 2
    vpavgw         m11, m11, m12       ; (2 * q1 + q0 + p1 + 2) >> 2
    vpblendvb      m10, m4, m10, m8    ; temp p0'
    vpblendvb      m11, m5, m11, m8    ; temp q0'

    vpsubw         m8, m2, m4
    vpabsw         m8, m8
    vpcmpgtw       m8, m1, m8          ; abs(p2 - p0) < beta ? -1 : 0
    vpand          m8, m8, m0          ; mask for the first inner "if"
    vpsubw         m12, m7, m5
    vpabsw         m12, m12
    vpcmpgtw       m12, m1, m12        ; abs(q2 - q0) < beta ? -1 : 0
    vpand          m0, m0, m12         ; mask for the second inner "if"

    vpxor          m12, m12, m12
    vpsubw         m1, m2, m6          ; p2 - q1
    vpaddw         m4, m9, m9          ; 2 * (p1 + p0 + q0 + q1)
    vpaddw         m4, m4, m1          ; p2 + 2 * p1 + 2 * p0 + 2 * q0 + q1
    vpsrlw         m4, m4, 2
    vpavgw         m4, m4, m12         ; (p2 + 2 * p1 + 2 * p0 + 2 * q0 + q1 + 4) >> 3
    vpblendvb      m10, m10, m4, m8    ; p0'
    vextracti128   xm4, m10, 1
    vpackuswb      xm10, xm10, xm4
    vmovdqu        [r0 + r5], xm10
    vpaddw         m4, m9, m1          ; p2 + p1 + p0 + q0
    vpsrlw         m1, m4, 1
    vpavgw         m1, m1, m12         ; (p2 + p1 + p0 + q0 + 2) >> 2
    vpblendvb      m1, m3, m1, m8      ; p1', keep original p1 for the next part
    vpmovzxbw      m10, [r0]           ; p3
    vpaddw         m10, m10, m2        ; p3 + p2
    vpaddw         m10, m10, m10       ; 2 * (p3 + p2)
    vpaddw         m10, m10, m4        ; 2 * p3 + 3 * p2 + p1 + p0 + q0
    vpsrlw         m10, m10, 2
    vpavgw         m10, m10, m12       ; (2 * p3 + 3 * p2 + p1 + p0 + q0 + 4) >> 3
    vpblendvb      m2, m2, m10, m8     ; p2'
    vinserti128    m8, m2, xm1, 1      ; p2'L | p1'L
    vperm2i128     m2, m2, m1, 31h     ; p2'H | p1'H
    vpackuswb      m8, m8, m2          ; p2' | p1'
    vmovdqu        [r0 + r1], xm8
    vextracti128   [r0 + r1 * 2], m8, 1
    
    vpsubw         m1, m7, m3          ; q2 - p1
    vpaddw         m2, m9, m9          ; 2 * (p1 + p0 + q0 + q1)
    vpaddw         m3, m1, m2          ; p1 + 2 * p0 + 2 * q0 + 2 * q1 + q2
    vpsrlw         m3, m3, 2
    vpavgw         m3, m3, m12         ; (p1 + 2 * p0 + 2 * q0 + 2 * q1 + q2 + 4) >> 3
    vpblendvb      m3, m11, m3, m0     ; q0'
    vextracti128   xm4, m3, 1
    vpackuswb      xm3, xm3, xm4
    vmovdqu        [r6], xm3
    vpaddw         m1, m1, m9          ; p0 + q0 + q1 + q2
    vpsrlw         m2, m1, 1
    vpavgw         m2, m2, m12         ; (p0 + q0 + q1 + q2 + 2) >> 2
    vpblendvb      m6, m6, m2, m0      ; q1'
    vpmovzxbw      m2, [r6 + r5]       ; q3
    vpaddw         m2, m2, m7          ; q3 + q2
    vpaddw         m2, m2, m2          ; 2 * (q3 + q2)
    vpaddw         m2, m2, m1          ; 2 * q3 + 3 * q2 + q1 + q0 + p0
    vpsrlw         m2, m2, 2
    vpavgw         m2, m2, m12         ; (2 * q3 + 3 * q2 + q1 + q0 + p0 + 4) >> 3
    vpblendvb      m7, m7, m2, m0      ; q2'
    vinserti128    m3, m6, xm7, 1      ; q1'L | q2'L
    vperm2i128     m4, m6, m7, 31h     ; q1'H | q2'H
    vpackuswb      m3, m3, m4          ; q1' | q2'
    vmovdqu        [r6 + r1], xm3
    vextracti128   [r6 + r1 * 2], m3, 1

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    add            rsp, 88
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    RET

INIT_YMM avx2
cglobal deblock_h_luma_intra, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 136
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
    vmovdqu        [rsp + 80], xm13
    vmovdqu        [rsp + 96], xm14
    vmovdqu        [rsp + 112], xm15
%endif
    vmovd          xm0, r2d
    vmovd          xm1, r3d
    vpbroadcastw   m0, xm0             ; alpha
    vpbroadcastw   m1, xm1             ; beta
    sub            r0, 4               ; pix
    lea            r5d, [r1 + r1 * 2]  ; 3 * stride
    lea            r2, [r0 + r1 * 4]   ; pix + 4 * stride
    lea            r3, [r0 + r1 * 8]   ; pix + 8 * stride
    lea            r6, [r2 + r1 * 8]   ; pix + 12 * stride

    vmovq          xm2, [r0]
    vinserti128    m2, m2, [r3], 1
    vmovq          xm3, [r0 + r1]
    vinserti128    m3, m3, [r3 + r1], 1
    vpunpcklbw     m2, m2, m3                    ; 0 1 | 8 9
    vmovq          xm3, [r0 + r1 * 2]
    vinserti128    m3, m3, [r3 + r1 * 2], 1
    vmovq          xm4, [r0 + r5]
    vinserti128    m4, m4, [r3 + r5], 1
    vpunpcklbw     m3, m3, m4                    ; 2 3 | 10 11
    vmovq          xm4, [r2]
    vinserti128    m4, m4, [r6], 1
    vmovq          xm5, [r2 + r1]
    vinserti128    m5, m5, [r6 + r1], 1
    vpunpcklbw     m4, m4, m5                    ; 4 5 | 12 13
    vmovq          xm5, [r2 + r1 * 2]
    vinserti128    m5, m5, [r6 + r1 * 2], 1
    vmovq          xm6, [r2 + r5]
    vinserti128    m6, m6, [r6 + r5], 1
    vpunpcklbw     m5, m5, m6                    ; 6 7 | 14 15

    vpunpcklwd     m6, m2, m3          ; 0 1 2 3 (p3 p2 p1 p0) | 8 9 10 11 (p3 p2 p1 p0)
    vpunpckhwd     m7, m2, m3          ; 0 1 2 3 (q0 q1 q2 q3) | 8 9 10 11 (q0 q1 q2 q3)
    vpunpcklwd     m8, m4, m5          ; 4 5 6 7 (p3 p2 p1 p0) | 12 13 14 15 (p3 p2 p1 p0)
    vpunpckhwd     m9, m4, m5          ; 4 5 6 7 (q0 q1 q2 q3) | 12 13 14 15 (q0 q1 q2 q3)
    vpunpckldq     m2, m6, m8          ; p3 p2
    vpunpckhdq     m4, m6, m8          ; p1 p0
    vpunpckldq     m6, m7, m9          ; q0 q1
    vpunpckhdq     m8, m7, m9          ; q2 q3
    vpxor          m15, m15, m15       ; zero-extend to 16bit
    vpunpckhbw     m3, m2, m15         ; p2
    vpunpcklbw     m2, m2, m15         ; p3
    vpunpckhbw     m5, m4, m15         ; p0
    vpunpcklbw     m4, m4, m15         ; p1
    vpunpckhbw     m7, m6, m15         ; q1
    vpunpcklbw     m6, m6, m15         ; q0
    vpunpckhbw     m9, m8, m15         ; q3
    vpunpcklbw     m8, m8, m15         ; q2

    vpsubw         m10, m5, m6
    vpabsw         m10, m10            ; abs(p0 - q0)
    vpcmpgtw       m11, m0, m10        ; abs(p0 - q0) < alpha ? -1 : 0
    vpbroadcastd   m12, [pw_2]
    vpsrlw         m0, m0, 2
    vpaddw         m0, m0, m12         ; (alpha >> 2) + 2
    vpcmpgtw       m0, m0, m10         ; (abs(p0 - q0) < (alpha >> 2) + 2) ? -1 : 0
    vpsubw         m10, m4, m5
    vpabsw         m10, m10            ; abs(p1 - p0)
    vpsubw         m12, m7, m6
    vpabsw         m12, m12            ; abs(q1 - q0)
    vpmaxuw        m10, m10, m12       ; take the bigger one to compare with beta
    vpcmpgtw       m10, m1, m10        ; abs(val) < beta ? -1 : 0
    vpand          m10, m10, m11       ; mask for the outer "if"
    vpand          m0, m0, m10         ; mask for the middle "if"

    vpaddw         m11, m4, m5
    vpaddw         m12, m6, m7
    vpaddw         m11, m11, m12       ; p1 + p0 + q0 + q1
    vpsubw         m12, m4, m6         ; p1 - q0
    vpsubw         m13, m7, m5         ; q1 - p0
    vpaddw         m12, m12, m11       ; 2 * p1 + p0 + q1
    vpaddw         m13, m13, m11       ; 2 * q1 + q0 + p1
    vpsrlw         m12, m12, 1
    vpsrlw         m13, m13, 1
    vpavgw         m12, m12, m15       ; (2 * p1 + p0 + q1 + 2) >> 2
    vpavgw         m13, m13, m15       ; (2 * q1 + q0 + p1 + 2) >> 2
    vpblendvb      m12, m5, m12, m10   ; temp p0'
    vpblendvb      m13, m6, m13, m10   ; temp q0'

    vpsubw         m10, m3, m5
    vpabsw         m10, m10
    vpcmpgtw       m10, m1, m10        ; abs(p2 - p0) < beta ? -1 : 0
    vpand          m10, m10, m0        ; mask for the first inner "if"
    vpsubw         m14, m8, m6
    vpabsw         m14, m14
    vpcmpgtw       m14, m1, m14        ; abs(q2 - q0) < beta ? -1 : 0
    vpand          m0, m0, m14         ; mask for the second inner "if"

    vpsubw         m1, m3, m7          ; p2 - q1
    vpaddw         m14, m11, m11       ; 2 * (p1 + p0 + q0 + q1)
    vpaddw         m14, m14, m1        ; p2 + 2 * p1 + 2 * p0 + 2 * q0 + q1
    vpsrlw         m14, m14, 2
    vpavgw         m14, m14, m15       ; (p2 + 2 * p1 + 2 * p0 + 2 * q0 + q1 + 4) >> 3
    vpblendvb      m5, m12, m14, m10   ; p0'
    vpaddw         m12, m11, m1        ; p2 + p1 + p0 + q0
    vpsrlw         m14, m12, 1
    vpavgw         m14, m14, m15       ; (p2 + p1 + p0 + q0 + 2) >> 2
    vpblendvb      m1, m4, m14, m10    ; p1', keep original p1 for the next part
    vpaddw         m14, m2, m3         ; p3 + p2
    vpaddw         m14, m14, m14       ; 2 * (p3 + p2)
    vpaddw         m14, m14, m12       ; 2 * p3 + 3 * p2 + p1 + p0 + q0
    vpsrlw         m14, m14, 2
    vpavgw         m14, m14, m15       ; (2 * p3 + 3 * p2 + p1 + p0 + q0 + 4) >> 3
    vpblendvb      m3, m3, m14, m10    ; p2'

    vpsubw         m4, m8, m4          ; q2 - p1
    vpaddw         m12, m11, m11       ; 2 * (p1 + p0 + q0 + q1)
    vpaddw         m12, m12, m4        ; p1 + 2 * p0 + 2 * q0 + 2 * q1 + q2
    vpsrlw         m12, m12, 2
    vpavgw         m12, m12, m15       ; (p1 + 2 * p0 + 2 * q0 + 2 * q1 + q2 + 4) >> 3
    vpblendvb      m6, m13, m12, m0    ; q0'
    vpaddw         m11, m11, m4        ; p0 + q0 + q1 + q2
    vpsrlw         m12, m11, 1
    vpavgw         m12, m12, m15       ; (p0 + q0 + q1 + q2 + 2) >> 2
    vpblendvb      m7, m7, m12, m0     ; q1'
    vpaddw         m12, m9, m8         ; q3 + q2
    vpaddw         m12, m12, m12       ; 2 * (q3 + q2)
    vpaddw         m12, m12, m11       ; 2 * q3 + 3 * q2 + q1 + q0 + p0
    vpsrlw         m12, m12, 2
    vpavgw         m12, m12, m15       ; (2 * q3 + 3 * q2 + q1 + q0 + p0 + 4) >> 3
    vpblendvb      m8, m8, m12, m0     ; q2'

    vpunpcklwd     m10, m2, m3         ; 0 1 2 3 | 8 9 10 11 (p3 p2)
    vpunpckhwd     m11, m2, m3         ; 4 5 6 7 | 12 13 14 15 (p3 p2)
    vpunpcklwd     m12, m1, m5         ; 0 1 2 3 | 8 9 10 11 (p1 p0)
    vpunpckhwd     m13, m1, m5         ; 4 5 6 7 | 12 13 14 15 (p1 p0)
    vpunpcklwd     m14, m6, m7         ; 0 1 2 3 | 8 9 10 11 (q0 q1)
    vpunpckhwd     m15, m6, m7         ; 4 5 6 7 | 12 13 14 15 (q0 q1)
    vpunpcklwd     m7, m8, m9          ; 0 1 2 3 | 8 9 10 11 (q2 q3)
    vpunpckhwd     m8, m8, m9          ; 4 5 6 7 | 12 13 14 15 (q2 q3)
    vpunpckldq     m0, m10, m12        ; 0 1 | 8 9 (p3 p2 p1 p0)
    vpunpckhdq     m1, m10, m12        ; 2 3 | 10 11 (p3 p2 p1 p0)
    vpunpckldq     m2, m11, m13        ; 4 5 | 12 13 (p3 p2 p1 p0)
    vpunpckhdq     m3, m11, m13        ; 6 7 | 14 15 (p3 p2 p1 p0)
    vpunpckldq     m4, m14, m7         ; 0 1 | 8 9 (q0 q1 q2 q3)
    vpunpckhdq     m5, m14, m7         ; 2 3 | 10 11 (q0 q1 q2 q3)
    vpunpckldq     m6, m15, m8         ; 4 5 | 12 13 (q0 q1 q2 q3)
    vpunpckhdq     m7, m15, m8         ; 6 7 | 14 15 (q0 q1 q2 q3)
    vpunpcklqdq    m8, m0, m4          ; 0 | 8
    vpunpckhqdq    m9, m0, m4          ; 1 | 9
    vpunpcklqdq    m10, m1, m5         ; 2 | 10
    vpunpckhqdq    m11, m1, m5         ; 3 | 11
    vpunpcklqdq    m12, m2, m6         ; 4 | 12
    vpunpckhqdq    m13, m2, m6         ; 5 | 13
    vpunpcklqdq    m14, m3, m7         ; 6 | 14
    vpunpckhqdq    m15, m3, m7         ; 7 | 15
    vpackuswb      m8, m8, m9          ; 0 1 | 8 9
    vpackuswb      m10, m10, m11       ; 2 3 | 10 11
    vpackuswb      m12, m12, m13       ; 4 5 | 12 13
    vpackuswb      m14, m14, m15       ; 6 7 | 14 15

    vmovq          [r0], xm8
    vmovhps        [r0 + r1], xm8
    vmovq          [r0 + r1 * 2], xm10
    vmovhps        [r0 + r5], xm10
    vmovq          [r2], xm12
    vmovhps        [r2 + r1], xm12
    vmovq          [r2 + r1 * 2], xm14
    vmovhps        [r2 + r5], xm14
    vextracti128   xm0, m8, 1
    vextracti128   xm1, m10, 1
    vextracti128   xm2, m12, 1
    vextracti128   xm3, m14, 1
    vmovq          [r3], xm0
    vmovhps        [r3 + r1], xm0
    vmovq          [r3 + r1 * 2], xm1
    vmovhps        [r3 + r5], xm1
    vmovq          [r6], xm2
    vmovhps        [r6 + r1], xm2
    vmovq          [r6 + r1 * 2], xm3
    vmovhps        [r6 + r5], xm3

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    vmovdqu        xm13, [rsp + 80]
    vmovdqu        xm14, [rsp + 96]
    vmovdqu        xm15, [rsp + 112]
    add            rsp, 136
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    RET


;=============================================================================
; deblock_luma_chroma
;=============================================================================
INIT_XMM avx2
cglobal deblock_v_chroma_intra, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], m6
    vmovdqu        [rsp + 24], m7
    sub            rsp, 24
    vmovdqu        [rsp], m8
%endif
    vmovd          m0, r2d
    vmovd          m1, r3d
    vpbroadcastb   m0, m0              ; alpha
    vpbroadcastb   m1, m1              ; beta
    mov            r6, r0
    sub            r0, r1
    sub            r0, r1
    vpbroadcastd   m2, [pb_1]
    ; alpha and beta must > 0, so we can safely -1
    vpsubb         m0, m0, m2          ; alpha - 1
    vpsubb         m1, m1, m2          ; beta - 1

    vmovdqu        m2, [r0]            ; p1
    vmovdqu        m3, [r0 + r1]       ; p0
    vmovdqu        m4, [r6]            ; q0
    vmovdqu        m5, [r6 + r1]       ; q1

    vpsubusb       m6, m3, m4
    vpsubusb       m7, m4, m3
    vpor           m6, m6, m7          ; abs(p0 - q0)
    vpsubusb       m0, m6, m0          ; abs(p0 - q0) < alpha ? 0 : else
    vpsubusb       m6, m2, m3
    vpsubusb       m7, m3, m2
    vpor           m6, m6, m7          ; abs(p1 - p0)
    vpsubusb       m7, m4, m5
    vpsubusb       m8, m5, m4
    vpor           m7, m7, m8          ; abs(q1 - q0)
    vpmaxub        m6, m6, m7          ; take the bigger one to compare with beta
    vpsubusb       m1, m6, m1          ; abs(val) < beta ? 0 : else
    vpor           m0, m0, m1
    vpxor          m1, m1, m1
    vpcmpeqb       m0, m0, m1          ; mask for the outer "if", -1 for true, 0 for false

    ; (2 * p1 + p0 + q1 + 2) >> 2
    ; -> ((p1 + 1) / 2) + ((p0 + q1) / 2)
    ; -> ((p1 + 1)) / 2) + ((Avg(p0, q1) - (p0 xor q1) and 1) / 2)
    ; -> Avg(p1, Avg(p0, q1) - (p0 xor q1) and 1)
    vpbroadcastd   m8, [pb_1]
    vpavgb         m6, m3, m5          ; Avg(p0, q1)
    vpxor          m7, m3, m5
    vpand          m7, m7, m8          ; (p0 xor q1) and 1
    vpsubb         m6, m6, m7          ; Avg(p0, q1) - (p0 xor q1) and 1
    vpavgb         m6, m2, m6          ; p0'
    vpblendvb      m3, m3, m6, m0
    vmovdqu        [r0 + r1], m3

    ; (2 * q1 + q0 + p1 + 2) >> 2  ->  Avg(q1, Avg(q0, p1) - (q0 xor p1) and 1)
    vpavgb         m6, m4, m2          ; Avg(q0, p1)
    vpxor          m7, m4, m2
    vpand          m7, m7, m8          ; (q0 xor p1) and 1
    vpsubb         m6, m6, m7          ; Avg(q0, p1) - (q0 xor p1) and 1
    vpavgb         m6, m5, m6          ; q0'
    vpblendvb      m4, m4, m6, m0
    vmovdqu        [r6], m4

%if WIN64
    vmovdqu        m8, [rsp]
    add            rsp, 24
    vmovdqu        m6, [rsp + 8]
    vmovdqu        m7, [rsp + 24]
%endif
    ret

INIT_XMM avx2
cglobal deblock_h_chroma_intra, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], m6
    vmovdqu        [rsp + 24], m7
    sub            rsp, 24
    vmovdqu        [rsp], m8
%endif
    lea            r5d, [r1 + r1 * 2]  ; 3 * stride
    sub            r0, 4
    lea            r6, [r0 + r1 * 4]

    ; load and transpose
    vmovq          m0, [r0]
    vmovq          m1, [r0 + r1]
    vpunpcklwd     m0, m0, m1          ; row0 row1(p1) row0 row1(p0) row0 row1(q0) row0 row1(q1)
    vmovq          m1, [r0 + r1 * 2]
    vmovq          m2, [r0 + r5]
    vpunpcklwd     m1, m1, m2          ; row2 row3(p1) row2 row3(p0) row2 row3(q0) row2 row3(q1)
    vmovq          m2, [r6]
    vmovq          m3, [r6 + r1]
    vpunpcklwd     m2, m2, m3          ; row4 row5(p1) row4 row5(p0) row4 row5(q0) row4 row5(q1)
    vmovq          m3, [r6 + r1 * 2]
    vmovq          m4, [r6 + r5]
    vpunpcklwd     m3, m3, m4          ; row6 row7(p1) row6 row7(p0) row6 row7(q0) row6 row7(q1)

    vpunpckldq     m4, m0, m1          ; row0 row1 row2 row3(p1) row0 row1 row2 row3(p0)
    vpunpckhdq     m5, m0, m1          ; row0 row1 row2 row3(q0) row0 row1 row2 row3(q1)
    vpunpckldq     m6, m2, m3          ; row4 row5 row6 row7(p1) row4 row5 row6 row7(p0)
    vpunpckhdq     m7, m2, m3          ; row4 row5 row6 row7(q0) row4 row5 row6 row7(q1)

    vpunpcklqdq    m2, m4, m6          ; row0 row1 row2 row3 row4 row5 row6 row7(p1)
    vpunpckhqdq    m3, m4, m6          ; row0 row1 row2 row3 row4 row5 row6 row7(p0)
    vpunpcklqdq    m4, m5, m7          ; row0 row1 row2 row3 row4 row5 row6 row7(q0)
    vpunpckhqdq    m5, m5, m7          ; row0 row1 row2 row3 row4 row5 row6 row7(q1)

    vmovd          m0, r2d
    vmovd          m1, r3d
    vpbroadcastb   m0, m0              ; alpha
    vpbroadcastb   m1, m1              ; beta
    vpbroadcastd   m6, [pb_1]
    ; alpha and beta must > 0, so we can safely -1
    vpsubb         m0, m0, m6          ; alpha - 1
    vpsubb         m1, m1, m6          ; beta - 1

    vpsubusb       m6, m3, m4
    vpsubusb       m7, m4, m3
    vpor           m6, m6, m7          ; abs(p0 - q0)
    vpsubusb       m0, m6, m0          ; abs(p0 - q0) < alpha ? 0 : else
    vpsubusb       m6, m2, m3
    vpsubusb       m7, m3, m2
    vpor           m6, m6, m7          ; abs(p1 - p0)
    vpsubusb       m7, m4, m5
    vpsubusb       m8, m5, m4
    vpor           m7, m7, m8          ; abs(q1 - q0)
    vpmaxub        m6, m6, m7          ; take the bigger one to compare with beta
    vpsubusb       m1, m6, m1          ; abs(val) < beta ? 0 : else
    vpor           m0, m0, m1
    vpxor          m1, m1, m1
    vpcmpeqb       m0, m0, m1          ; mask for the outer "if", -1 for true, 0 for false

    ; (2 * p1 + p0 + q1 + 2) >> 2
    ; -> ((p1 + 1) / 2) + ((p0 + q1) / 2)
    ; -> ((p1 + 1)) / 2) + ((Avg(p0, q1) - (p0 xor q1) and 1) / 2)
    ; -> Avg(p1, Avg(p0, q1) - (p0 xor q1) and 1)
    vpbroadcastd   m8, [pb_1]
    vpavgb         m6, m3, m5          ; Avg(p0, q1)
    vpxor          m7, m3, m5
    vpand          m7, m7, m8          ; (p0 xor q1) and 1
    vpsubb         m6, m6, m7          ; Avg(p0, q1) - (p0 xor q1) and 1
    vpavgb         m6, m2, m6          ; p0'
    vpblendvb      m3, m3, m6, m0

    ; (2 * q1 + q0 + p1 + 2) >> 2  ->  Avg(q1, Avg(q0, p1) - (q0 xor p1) and 1)
    vpavgb         m6, m4, m2          ; Avg(q0, p1)
    vpxor          m7, m4, m2
    vpand          m7, m7, m8          ; (q0 xor p1) and 1
    vpsubb         m6, m6, m7          ; Avg(q0, p1) - (q0 xor p1) and 1
    vpavgb         m6, m5, m6          ; q0'
    vpblendvb      m4, m4, m6, m0

    ; shuffle and save
    add            r0, 2
    add            r6, 2
    vpunpcklwd     m0, m3, m4          ; row0 row1 row2 row3
    vpunpckhwd     m1, m3, m4          ; row4 row5 row6 row7
    vmovd          [r0], m0
    vpextrd        [r0 + r1], m0, 1
    vpextrd        [r0 + r1 * 2], m0, 2
    vpextrd        [r0 + r5], m0, 3
    vmovd          [r6], m1
    vpextrd        [r6 + r1], m1, 1
    vpextrd        [r6 + r1 * 2], m1, 2
    vpextrd        [r6 + r5], m1, 3

%if WIN64
    vmovdqu        m8, [rsp]
    add            rsp, 24
    vmovdqu        m6, [rsp + 8]
    vmovdqu        m7, [rsp + 24]
%endif
    ret


;=============================================================================
; deblock_strength
;=============================================================================
INIT_YMM avx2
cglobal deblock_strength, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]     ; bframe
    vmovdqu        [rsp + 8], xm6
%endif
    vpxor          m0, m0, m0          ; bs[0] | bs[1]
    vmovdqu        m1, [load_bytes_ymm_shuf]
    vpbroadcastd   m6, [pb_3]

.lists:
    ; check refs
    vpsrld         m2, m1, 4           ; 0 1 4 5 | 7 2 3 6
    vmovdqu        m3, [r1 + 8]        ; ___E FGHI ___J KLMN | ___O PQRS ___T UVWX
    vpshufb        m3, m3, m1          ; EFGH JKLM FGHI KLMN | OPQR TUVW PQRS UVWX
    vpermq         m4, m3, q3131       ; FGHI KLMN PQRS UVWX | FGHI KLMN PQRS UVWX (loc)
    vpbroadcastd   m5, [r1 + 4]        ; ABCD...
    vpblendd       m3, m3, m5, 80h     ; EFGH JKLM FGHI KLMN | OPQR TUVW PQRS ABCD
    vpermd         m3, m2, m3          ; EFGH JKLM OPQR TUVW | ABCD FGHI KLMN PQRS (locn)
    vpxor          m3, m3, m4          ; ref[loc] != ref[locn] ? not 0 : 0
    vpor           m0, m0, m3

    ; check mvs
    vbroadcasti128 m2, [r2 + 48]            ; FGHI | FGHI (loc row0)
    vmovdqu        xm3, [r2 + 44]           ; EFGH
    vinserti128    m3, m3, [r2 + 16], 1     ; EFGH | ABCD (locn row0)
    vpsubw         m3, m2, m3
    vinserti128    m2, m2, [r2 + 76], 0     ; JKLM | FGHI (locn row1)
    vbroadcasti128 m4, [r2 + 80]            ; KLMN | KLMN (loc row1)
    vpsubw         m2, m4, m2
    vpacksswb      m2, m3, m2               ; row0 row1
    vinserti128    m4, m4, [r2 + 108], 0    ; OPQR | KLMN (locn row2)
    vbroadcasti128 m3, [r2 + 112]           ; PQRS | PQRS (loc row2)
    vpsubw         m4, m3, m4
    vinserti128    m3, m3, [r2 + 140], 0    ; TUVW | PQRS (locn row3)
    vbroadcasti128 m5, [r2 + 144]           ; UVWX | UVWX (loc row3)
    vpsubw         m3, m5, m3
    vpacksswb      m3, m4, m3               ; row2 row3
    vpabsb         m2, m2
    vpabsb         m3, m3
    vpsubusb       m2, m2, m6               ; mv[loc] >= mv[locn] ? not 0 : 0
    vpsubusb       m3, m3, m6
    vpacksswb      m2, m2, m3
    vpor           m0, m0, m2
    
    add            r1, 40
    add            r2, 160
    dec            r4d
    jge            .lists

    ; check nnz
    vpsrld         m2, m1, 4           ; 0 1 4 5 | 7 2 3 6
    vmovdqu        m3, [r0 + 8]        ; ___E FGHI ___J KLMN | ___O PQRS ___T UVWX
    vpshufb        m3, m3, m1          ; EFGH JKLM FGHI KLMN | OPQR TUVW PQRS UVWX
    vpermq         m4, m3, q3131       ; FGHI KLMN PQRS UVWX | FGHI KLMN PQRS UVWX (loc)
    vpbroadcastd   m5, [r0 + 4]        ; ABCD...
    vpblendd       m3, m3, m5, 80h     ; EFGH JKLM FGHI KLMN | OPQR TUVW PQRS ABCD
    vpermd         m3, m2, m3          ; EFGH JKLM OPQR TUVW | ABCD FGHI KLMN PQRS (locn)
    vpor           m3, m3, m4          ; nnz[loc] || nnz[locn] ? not 0 : 0

    vpbroadcastd   m2, [pb_1]
    vpminub        m3, m3, m2
    vpaddb         m3, m3, m3          ; nnz[loc] || nnz[locn] ? 2 : 0
    vpminub        m0, m0, m2          ; mv ? 1 : 0
    vpmaxub        m0, m0, m3          ; nnz ? 2 : (mv ? 1 : 0)
    vextracti128   [r3 + 32], m0, 1
    vpshufb        xm0, [transpose_shuf]
    vmovdqu        [r3], xm0

%if WIN64
    vmovdqu        xm6, [rsp + 8]
%endif
    RET
