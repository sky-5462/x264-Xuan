;*****************************************************************************
;* dct-a.asm: x86 transform and zigzag
;*****************************************************************************
;* Copyright (C) 2003-2019 x264 project
;*
;* Authors: Holger Lubitz <holger@lubitz.org>
;*          Loren Merritt <lorenm@u.washington.edu>
;*          Laurent Aimar <fenrir@via.ecp.fr>
;*          Min Chen <chenm001.163.com>
;*          Fiona Glaser <fiona@x264.com>
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
dct4x4dc_shuf1:      db  0,  1,  4,  5,  8,  9, 12, 13,  2,  3,  6,  7, 10, 11, 14, 15
dct4x4dc_shuf2:      db  2,  3,  6,  7, 10, 11, 14, 15,  0,  1,  4,  5,  8,  9, 12, 13
scan_4x4_shuf:       db  0,  1,  8,  9,  2,  3,  4,  5, 10, 11, 12, 13,  6,  7, 14, 15
sub_4x4_shuf:        db  0,  1,  4,  8,  5,  2,  3,  6,  9, 12, 13, 10,  7, 11, 14, 15
sub_8x8_shuf1_1:     db  0,  1,  8, -1,  9,  2,  3, 10, -1, -1, -1, -1, -1, 11,  4,  5
sub_8x8_shuf1_2:     db -1, -1, -1,  0, -1, -1, -1, -1,  1,  8, -1,  9,  2, -1, -1, -1
sub_8x8_shuf1_3:     db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,  0, -1, -1, -1, -1, -1
sub_8x8_shuf2_1:     db 12, -1, -1, -1, -1, -1, -1, -1, -1, -1, 13,  6,  7, 14, -1, -1
sub_8x8_shuf2_2:     db -1,  3, 10, -1, -1, -1, -1, -1, 11,  4, -1, -1, -1, -1,  5, 12
sub_8x8_shuf2_3:     db -1, -1, -1,  1,  8, -1,  9,  2, -1, -1, -1, -1, -1, -1, -1, -1
sub_8x8_shuf2_4:     db -1, -1, -1, -1, -1,  0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
sub_8x8_shuf3_1:     db -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 15, -1, -1, -1, -1, -1
sub_8x8_shuf3_2:     db -1, -1, -1, -1, -1, -1, -1, -1, 13,  6, -1,  7, 14, -1, -1, -1
sub_8x8_shuf3_3:     db  3, 10, -1, -1, -1, -1, 11,  4, -1, -1, -1, -1, -1,  5, 12, -1
sub_8x8_shuf3_4:     db -1, -1,  1,  8,  9,  2, -1, -1, -1, -1, -1, -1, -1, -1, -1,  3
sub_8x8_shuf4_2:     db -1, -1, -1, -1, -1, 15, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
sub_8x8_shuf4_3:     db -1, -1, -1, 13,  6, -1,  7, 14, -1, -1, -1, -1, 15, -1, -1, -1
sub_8x8_shuf4_4:     db 10, 11,  4, -1, -1, -1, -1, -1,  5, 12, 13,  6, -1,  7, 14, 15

SECTION .text

cextern pw_32
cextern pw_8000
cextern hsub_mul
cextern deinterleave_shufd

;=============================================================================
; SUB_DCT
;=============================================================================
INIT_XMM avx2
cglobal sub4x4_dct, 0, 0
    vpmovzxbw      m1, [r1]
    vpmovzxbw      m2, [r2]
    vpsubw         m1, m1, m2
    vpmovzxbw      m2, [r1 + 16]
    vpmovzxbw      m3, [r2 + 32]
    vpsubw         m2, m2, m3
    vpmovzxbw      m3, [r1 + 32]
    vpmovzxbw      m4, [r2 + 64]
    vpsubw         m3, m3, m4
    vpmovzxbw      m4, [r1 + 48]
    vpmovzxbw      m5, [r2 + 96]
    vpsubw         m4, m4, m5

    vpaddw         m0, m1, m4
    vpsubw         m5, m1, m4
    vpaddw         m1, m2, m3
    vpsubw         m4, m2, m3
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpsubw         m0, m5, m4
    vpsubw         m0, m0, m4
    vpaddw         m1, m5, m5
    vpaddw         m1, m1, m4

    vpunpcklwd     m4, m2, m3
    vpunpcklwd     m5, m1, m0
    vpunpcklwd     m0, m4, m5
    vpunpckhwd     m2, m4, m5
    vpunpckhqdq    m1, m0, m0
    vpunpckhqdq    m3, m2, m2

    vpaddw         m4, m0, m3
    vpsubw         m5, m0, m3
    vpaddw         m0, m1, m2
    vpsubw         m3, m1, m2
    vpaddw         m1, m4, m0
    vpsubw         m2, m4, m0
    vpsubw         m0, m5, m3
    vpsubw         m0, m0, m3
    vpaddw         m4, m5, m5
    vpaddw         m4, m4, m3

    vpunpcklqdq    m1, m1, m4
    vpunpcklqdq    m2, m2, m0
    vmovdqu        [r0], m1
    vmovdqu        [r0 + 16], m2
    ret

INIT_YMM avx2
cglobal sub8x8_dct, 0, 0
    vpxor          m5, m5, m5
    add            r2, 128
    vmovq          xm0, [r1]
    vinserti128    m0, m0, [r1 + 64], 1
    vmovq          xm1, [r2 - 128]
    vinserti128    m1, m1, [r2], 1
    vpunpcklbw     m0, m0, m5
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vmovq          xm1, [r1 + 16]
    vinserti128    m1, m1, [r1 + 80], 1
    vmovq          xm2, [r2 - 96]
    vinserti128    m2, m2, [r2 + 32], 1
    vpunpcklbw     m1, m1, m5
    vpunpcklbw     m2, m2, m5
    vpsubw         m1, m1, m2
    vmovq          xm2, [r1 + 32]
    vinserti128    m2, m2, [r1 + 96], 1
    vmovq          xm3, [r2 - 64]
    vinserti128    m3, m3, [r2 + 64], 1
    vpunpcklbw     m2, m2, m5
    vpunpcklbw     m3, m3, m5
    vpsubw         m2, m2, m3
    vmovq          xm3, [r1 + 48]
    vinserti128    m3, m3, [r1 + 112], 1
    vmovq          xm4, [r2 - 32]
    vinserti128    m4, m4, [r2 + 96], 1
    vpunpcklbw     m3, m3, m5
    vpunpcklbw     m4, m4, m5
    vpsubw         m3, m3, m4

    vpaddw         m4, m0, m3
    vpsubw         m5, m0, m3
    vpaddw         m0, m1, m2
    vpsubw         m3, m1, m2
    vpaddw         m1, m4, m0
    vpsubw         m2, m4, m0
    vpsubw         m0, m5, m3
    vpsubw         m0, m0, m3
    vpaddw         m4, m5, m5
    vpaddw         m4, m4, m3

    vpunpcklwd     m3, m1, m2
    vpunpckhwd     m5, m1, m2
    vpunpcklwd     m1, m4, m0
    vpunpckhwd     m2, m4, m0
    vpunpcklwd     m0, m3, m1
    vpunpckhwd     m4, m3, m1
    vpunpcklwd     m1, m5, m2
    vpunpckhwd     m3, m5, m2
    vpunpcklqdq    m2, m0, m1
    vpunpckhqdq    m5, m0, m1
    vpunpcklqdq    m0, m4, m3
    vpunpckhqdq    m1, m4, m3

    vpaddw         m3, m2, m1
    vpsubw         m4, m2, m1
    vpaddw         m1, m5, m0
    vpsubw         m2, m5, m0
    vpaddw         m0, m3, m1
    vpsubw         m5, m3, m1
    vpsubw         m1, m4, m2
    vpsubw         m1, m1, m2
    vpaddw         m3, m2, m4
    vpaddw         m3, m3, m4

    vpunpcklqdq    m2, m0, m3
    vpunpckhqdq    m4, m0, m3
    vpunpcklqdq    m0, m5, m1
    vpunpckhqdq    m3, m5, m1
    vmovdqu        [r0], xm2
    vmovdqu        [r0 + 16], xm0
    vmovdqu        [r0 + 32], xm4
    vmovdqu        [r0 + 48], xm3
    vextracti128   [r0 + 64], m2, 1
    vextracti128   [r0 + 80], m0, 1
    vextracti128   [r0 + 96], m4, 1
    vextracti128   [r0 + 112], m3, 1
    RET

INIT_YMM avx2
cglobal sub8x8_dct_dc, 0, 0
    vpxor          m0, m0, m0
    add            r2, 128
    vmovdqu        m1, [r1]
    vpunpcklbw     m1, m1, [r1 + 32]
    vpsadbw        m1, m1, m0
    vextracti128   xm2, m1, 1
    vpaddq         xm1, xm1, xm2
    vmovq          xm2, [r2 - 128]
    vpunpcklbw     xm2, xm2, [r2 - 96]
    vpsadbw        xm2, xm2, xm0
    vpsubq         xm1, xm1, xm2
    vmovq          xm2, [r2 - 64]
    vpunpcklbw     xm2, xm2, [r2 - 32]
    vpsadbw        xm2, xm2, xm0
    vpsubq         xm1, xm1, xm2

    vmovdqu        m2, [r1 + 64]
    vpunpcklbw     m2, m2, [r1 + 96]
    vpsadbw        m2, m2, m0
    vextracti128   xm3, m2, 1
    vpaddq         xm2, xm2, xm3
    vmovq          xm3, [r2]
    vpunpcklbw     xm3, xm3, [r2 + 32]
    vpsadbw        xm3, xm3, xm0
    vpsubq         xm2, xm2, xm3
    vmovq          xm3, [r2 + 64]
    vpunpcklbw     xm3, xm3, [r2 + 96]
    vpsadbw        xm3, xm3, xm0
    vpsubq         xm2, xm2, xm3

    vpaddq         xm3, xm1, xm2
    vpsubq         xm4, xm1, xm2
    vpunpcklqdq    xm1, xm3, xm4
    vpunpckhqdq    xm2, xm3, xm4
    vpaddq         xm3, xm1, xm2
    vpsubq         xm4, xm1, xm2

    vpackssdw      xm1, xm3, xm4
    vpackssdw      xm1, xm1, xm1
    vmovq          [r0], xm1
    RET

INIT_YMM avx2
cglobal sub8x16_dct_dc, 0, 0
    vpxor          m0, m0, m0
    add            r2, 128
    vmovdqu        m1, [r1]
    vpunpcklbw     m1, m1, [r1 + 32]
    vpsadbw        m1, m1, m0
    vextracti128   xm2, m1, 1
    vpaddq         xm1, xm1, xm2
    vmovq          xm2, [r2 - 128]
    vpunpcklbw     xm2, xm2, [r2 - 96]
    vpsadbw        xm2, xm2, xm0
    vmovq          xm3, [r2 - 64]
    vpunpcklbw     xm3, xm3, [r2 - 32]
    vpsadbw        xm3, xm3, xm0
    vpaddq         xm2, xm2, xm3
    vpsubq         xm1, xm1, xm2

    vmovdqu        m2, [r1 + 64]
    vpunpcklbw     m2, m2, [r1 + 96]
    vpsadbw        m2, m2, m0
    vextracti128   xm3, m2, 1
    vpaddq         xm2, xm2, xm3
    vmovq          xm3, [r2]
    vpunpcklbw     xm3, xm3, [r2 + 32]
    vpsadbw        xm3, xm3, xm0
    vmovq          xm4, [r2 + 64]
    vpunpcklbw     xm4, xm4, [r2 + 96]
    add            r1, 128
    add            r2, 256
    vpsadbw        xm4, xm4, xm0
    vpaddq         xm3, xm3, xm4
    vpsubq         xm2, xm2, xm3

    vmovdqu        m3, [r1]
    vpunpcklbw     m3, m3, [r1 + 32]
    vpsadbw        m3, m3, m0
    vextracti128   xm4, m3, 1
    vpaddq         xm3, xm3, xm4
    vmovq          xm4, [r2 - 128]
    vpunpcklbw     xm4, xm4, [r2 - 96]
    vpsadbw        xm4, xm4, xm0
    vmovq          xm5, [r2 - 64]
    vpunpcklbw     xm5, xm5, [r2 - 32]
    vpsadbw        xm5, xm5, xm0
    vpaddq         xm4, xm4, xm5
    vpsubq         xm3, xm3, xm4

    vmovdqu        m4, [r1 + 64]
    vpunpcklbw     m4, m4, [r1 + 96]
    vpsadbw        m4, m4, m0
    vextracti128   xm5, m4, 1
    vpaddq         xm4, xm4, xm5
    vmovq          xm5, [r2]
    vpunpcklbw     xm5, xm5, [r2 + 32]
    vpsadbw        xm5, xm5, xm0
    vpsubq         xm4, xm4, xm5
    vmovq          xm5, [r2 + 64]
    vpunpcklbw     xm5, xm5, [r2 + 96]
    vpsadbw        xm5, xm5, xm0
    vpsubq         xm4, xm4, xm5

    vpaddq         xm0, xm1, xm3
    vpsubq         xm5, xm1, xm3
    vpaddq         xm1, xm2, xm4
    vpsubq         xm3, xm2, xm4
    vpaddq         xm2, xm0, xm1
    vpsubq         xm4, xm0, xm1
    vpaddq         xm0, xm5, xm3
    vpsubq         xm1, xm5, xm3
    vpunpcklqdq    xm3, xm2, xm4
    vpunpckhqdq    xm5, xm2, xm4
    vpaddq         xm2, xm3, xm5
    vpsubq         xm4, xm3, xm5
    vpunpcklqdq    xm3, xm0, xm1
    vpunpckhqdq    xm5, xm0, xm1
    vpaddq         xm0, xm3, xm5
    vpsubq         xm1, xm3, xm5
    
    vpackssdw      xm2, xm2, xm4
    vpackssdw      xm0, xm0, xm1
    vshufps        xm4, xm2, xm0, q2020
    vshufps        xm5, xm0, xm2, q3131
    vpackssdw      xm0, xm4, xm5
    vmovdqu        [r0], xm0
    RET

INIT_YMM avx2
cglobal sub16x16_dct, 0, 0
    add            r0, 128
    call           .sub16x4_dct
    add            r0, 64
    add            r1, 64
    add            r2, 128
    call           .sub16x4_dct
    add            r0, 192
    add            r1, 64
    add            r2, 128
    call           .sub16x4_dct
    add            r0, 64
    add            r1, 64
    add            r2, 128
    call           .sub16x4_dct
    RET

ALIGN 16
.sub16x4_dct:
    vpmovzxbw      m0, [r1]
    vpmovzxbw      m1, [r2]
    vpsubw         m0, m0, m1
    vpmovzxbw      m1, [r1 + 16]
    vpmovzxbw      m2, [r2 + 32]
    vpsubw         m1, m1, m2
    vpmovzxbw      m2, [r1 + 32]
    vpmovzxbw      m3, [r2 + 64]
    vpsubw         m2, m2, m3
    vpmovzxbw      m3, [r1 + 48]
    vpmovzxbw      m4, [r2 + 96]
    vpsubw         m3, m3, m4

    vpaddw         m4, m0, m3
    vpsubw         m5, m0, m3
    vpaddw         m0, m1, m2
    vpsubw         m3, m1, m2
    vpaddw         m1, m4, m0
    vpsubw         m2, m4, m0
    vpsubw         m0, m5, m3
    vpsubw         m0, m0, m3
    vpaddw         m4, m3, m5
    vpaddw         m4, m4, m5

    vpunpcklwd     m3, m1, m2
    vpunpckhwd     m5, m1, m2
    vpunpcklwd     m1, m4, m0
    vpunpckhwd     m2, m4, m0
    vpunpcklwd     m0, m3, m1
    vpunpckhwd     m4, m3, m1
    vpunpcklwd     m1, m5, m2
    vpunpckhwd     m3, m5, m2
    vpunpcklqdq    m2, m0, m1
    vpunpckhqdq    m5, m0, m1
    vpunpcklqdq    m0, m4, m3
    vpunpckhqdq    m1, m4, m3

    vpaddw         m3, m2, m1
    vpsubw         m4, m2, m1
    vpaddw         m1, m5, m0
    vpsubw         m2, m5, m0
    vpaddw         m0, m3, m1
    vpsubw         m5, m3, m1
    vpsubw         m1, m4, m2
    vpsubw         m1, m1, m2
    vpaddw         m3, m2, m4
    vpaddw         m3, m3, m4

    vpunpcklqdq    m2, m0, m3
    vpunpckhqdq    m4, m0, m3
    vpunpcklqdq    m0, m5, m1
    vpunpckhqdq    m3, m5, m1
    vmovdqu        [r0 - 128], xm2
    vmovdqu        [r0 - 112], xm0
    vmovdqu        [r0 - 96], xm4
    vmovdqu        [r0 - 80], xm3
    vextracti128   [r0], m2, 1
    vextracti128   [r0 + 16], m0, 1
    vextracti128   [r0 + 32], m4, 1
    vextracti128   [r0 + 48], m3, 1
    ret

INIT_XMM avx2
cglobal sub8x8_dct8, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], m6
    vmovdqu        [rsp + 24], m7
    sub            rsp, 56
    vmovdqu        [rsp], m8
    vmovdqu        [rsp + 16], m9
    vmovdqu        [rsp + 32], m10
%endif
    vpmovzxbw      m0, [r1]
    vpmovzxbw      m1, [r2]
    vpsubw         m0, m0, m1
    vpmovzxbw      m1, [r1 + 16]
    vpmovzxbw      m2, [r2 + 32]
    vpsubw         m1, m1, m2
    vpmovzxbw      m2, [r1 + 32]
    vpmovzxbw      m3, [r2 + 64]
    vpsubw         m2, m2, m3
    vpmovzxbw      m3, [r1 + 48]
    vpmovzxbw      m4, [r2 + 96]
    add            r2, 128
    vpsubw         m3, m3, m4
    vpmovzxbw      m4, [r1 + 64]
    vpmovzxbw      m5, [r2]
    vpsubw         m4, m4, m5
    vpmovzxbw      m5, [r1 + 80]
    vpmovzxbw      m6, [r2 + 32]
    vpsubw         m5, m5, m6
    vpmovzxbw      m6, [r1 + 96]
    vpmovzxbw      m7, [r2 + 64]
    vpsubw         m6, m6, m7
    vpmovzxbw      m7, [r1 + 112]
    vpmovzxbw      m8, [r2 + 96]
    vpsubw         m7, m7, m8

; column transform
    vpaddw         m8, m0, m7
    vpsubw         m9, m0, m7
    vpaddw         m0, m1, m6
    vpsubw         m7, m1, m6
    vpaddw         m1, m2, m5
    vpsubw         m6, m2, m5
    vpaddw         m2, m3, m4
    vpsubw         m5, m3, m4

    vpaddw         m3, m8, m2
    vpsubw         m4, m8, m2
    vpaddw         m2, m0, m1
    vpsubw         m8, m0, m1
    vpaddw         m0, m7, m6
    vpsraw         m1, m9, 1
    vpaddw         m1, m1, m9
    vpaddw         m0, m0, m1
    vpsubw         m1, m7, m6
    vpsraw         m10, m5, 1
    vpaddw         m10, m10, m5
    vpaddw         m1, m1, m10
    vpsraw         m10, m6, 1
    vpaddw         m6, m6, m10
    vpsraw         m10, m7, 1
    vpaddw         m7, m7, m10
    vpaddw         m10, m9, m5
    vpsubw         m7, m10, m7
    vpsubw         m10, m9, m5
    vpsubw         m6, m10, m6

    vpaddw         m5, m3, m2
    vpsubw         m9, m3, m2
    vpsraw         m10, m8, 1
    vpaddw         m3, m4, m10
    vpsraw         m10, m4, 1
    vpsubw         m2, m10, m8
    vpsraw         m10, m7, 2
    vpaddw         m8, m10, m6
    vpsraw         m10, m6, 2
    vpsubw         m4, m7, m10
    vpsraw         m10, m1, 2
    vpaddw         m7, m0, m10
    vpsraw         m10, m0, 2
    vpsubw         m6, m10, m1

; transpose
    vpunpcklwd     m0, m5, m7
    vpunpckhwd     m1, m5, m7
    vpunpcklwd     m5, m3, m8
    vpunpckhwd     m7, m3, m8
    vpunpcklwd     m3, m9, m4
    vpunpckhwd     m8, m9, m4
    vpunpcklwd     m4, m2, m6
    vpunpckhwd     m9, m2, m6

    vpunpckldq     m2, m0, m5
    vpunpckhdq     m6, m0, m5
    vpunpckldq     m0, m1, m7
    vpunpckhdq     m5, m1, m7
    vpunpckldq     m1, m3, m4
    vpunpckhdq     m7, m3, m4
    vpunpckldq     m3, m8, m9
    vpunpckhdq     m4, m8, m9

    vpunpcklqdq    m8, m2, m1
    vpunpckhqdq    m9, m2, m1
    vpunpcklqdq    m1, m6, m7
    vpunpckhqdq    m2, m6, m7
    vpunpcklqdq    m6, m0, m3
    vpunpckhqdq    m7, m0, m3
    vpunpcklqdq    m0, m5, m4
    vpunpckhqdq    m3, m5, m4

; row transform
    vpaddw         m4, m8, m3
    vpsubw         m5, m8, m3
    vpaddw         m3, m9, m0
    vpsubw         m8, m9, m0
    vpaddw         m0, m1, m7
    vpsubw         m9, m1, m7
    vpaddw         m1, m2, m6
    vpsubw         m7, m2, m6

    vpaddw         m2, m4, m1
    vpsubw         m6, m4, m1
    vpaddw         m1, m3, m0
    vpsubw         m4, m3, m0
    vpaddw         m0, m8, m9
    vpsraw         m10, m5, 1
    vpaddw         m10, m10, m5
    vpaddw         m0, m0, m10
    vpsubw         m3, m8, m9
    vpsraw         m10, m7, 1
    vpaddw         m10, m10, m7
    vpaddw         m3, m3, m10
    vpsraw         m10, m8, 1
    vpaddw         m8, m8, m10
    vpsraw         m10, m9, 1
    vpaddw         m9, m9, m10
    vpaddw         m10, m5, m7
    vpsubw         m8, m10, m8
    vpsubw         m10, m5, m7
    vpsubw         m9, m10, m9

    vpaddw         m5, m2, m1
    vpsubw         m7, m2, m1
    vpsraw         m10, m4, 1
    vpaddw         m2, m6, m10
    vpsraw         m10, m6, 1
    vpsubw         m1, m10, m4
    vpsraw         m10, m8, 2
    vpaddw         m6, m10, m9
    vpsraw         m10, m9, 2
    vpsubw         m4, m8, m10
    vpsraw         m10, m3, 2
    vpaddw         m9, m0, m10
    vpsraw         m10, m0, 2
    vpsubw         m8, m10, m3

; output
    vmovdqu        [r0], m5
    vmovdqu        [r0 + 16], m9
    vmovdqu        [r0 + 32], m2
    vmovdqu        [r0 + 48], m6
    vmovdqu        [r0 + 64], m7
    vmovdqu        [r0 + 80], m4
    vmovdqu        [r0 + 96], m1
    vmovdqu        [r0 + 112], m8

%if WIN64
    vmovdqu        m8, [rsp]
    vmovdqu        m9, [rsp + 16]
    vmovdqu        m10, [rsp + 32]
    add            rsp, 56
    vmovdqu        m6, [rsp + 8]
    vmovdqu        m7, [rsp + 24]
%endif
    ret

INIT_YMM avx2
cglobal sub16x16_dct8, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 56
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
%endif
    add            r0, 128
    add            r2, 128
    call           .sub16x8_dct8
    add            r0, 256
    add            r1, 128
    add            r2, 256
    call           .sub16x8_dct8
%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    add            rsp, 56
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    RET

ALIGN 16
.sub16x8_dct8:
    vpmovzxbw      m0, [r1]
    vpmovzxbw      m1, [r2 - 128]
    vpsubw         m0, m0, m1
    vpmovzxbw      m1, [r1 + 16]
    vpmovzxbw      m2, [r2 - 96]
    vpsubw         m1, m1, m2
    vpmovzxbw      m2, [r1 + 32]
    vpmovzxbw      m3, [r2 - 64]
    vpsubw         m2, m2, m3
    vpmovzxbw      m3, [r1 + 48]
    vpmovzxbw      m4, [r2 - 32]
    vpsubw         m3, m3, m4
    vpmovzxbw      m4, [r1 + 64]
    vpmovzxbw      m5, [r2]
    vpsubw         m4, m4, m5
    vpmovzxbw      m5, [r1 + 80]
    vpmovzxbw      m6, [r2 + 32]
    vpsubw         m5, m5, m6
    vpmovzxbw      m6, [r1 + 96]
    vpmovzxbw      m7, [r2 + 64]
    vpsubw         m6, m6, m7
    vpmovzxbw      m7, [r1 + 112]
    vpmovzxbw      m8, [r2 + 96]
    vpsubw         m7, m7, m8

; column transform
    vpaddw         m8, m0, m7
    vpsubw         m9, m0, m7
    vpaddw         m0, m1, m6
    vpsubw         m7, m1, m6
    vpaddw         m1, m2, m5
    vpsubw         m6, m2, m5
    vpaddw         m2, m3, m4
    vpsubw         m5, m3, m4

    vpaddw         m3, m8, m2
    vpsubw         m4, m8, m2
    vpaddw         m2, m0, m1
    vpsubw         m8, m0, m1
    vpaddw         m0, m7, m6
    vpsraw         m1, m9, 1
    vpaddw         m1, m1, m9
    vpaddw         m0, m0, m1
    vpsubw         m1, m7, m6
    vpsraw         m10, m5, 1
    vpaddw         m10, m10, m5
    vpaddw         m1, m1, m10
    vpsraw         m10, m6, 1
    vpaddw         m6, m6, m10
    vpsraw         m10, m7, 1
    vpaddw         m7, m7, m10
    vpaddw         m10, m9, m5
    vpsubw         m7, m10, m7
    vpsubw         m10, m9, m5
    vpsubw         m6, m10, m6

    vpaddw         m5, m3, m2
    vpsubw         m9, m3, m2
    vpsraw         m10, m8, 1
    vpaddw         m3, m4, m10
    vpsraw         m10, m4, 1
    vpsubw         m2, m10, m8
    vpsraw         m10, m7, 2
    vpaddw         m8, m10, m6
    vpsraw         m10, m6, 2
    vpsubw         m4, m7, m10
    vpsraw         m10, m1, 2
    vpaddw         m7, m0, m10
    vpsraw         m10, m0, 2
    vpsubw         m6, m10, m1

; transpose
    vpunpcklwd     m0, m5, m7
    vpunpckhwd     m1, m5, m7
    vpunpcklwd     m5, m3, m8
    vpunpckhwd     m7, m3, m8
    vpunpcklwd     m3, m9, m4
    vpunpckhwd     m8, m9, m4
    vpunpcklwd     m4, m2, m6
    vpunpckhwd     m9, m2, m6

    vpunpckldq     m2, m0, m5
    vpunpckhdq     m6, m0, m5
    vpunpckldq     m0, m1, m7
    vpunpckhdq     m5, m1, m7
    vpunpckldq     m1, m3, m4
    vpunpckhdq     m7, m3, m4
    vpunpckldq     m3, m8, m9
    vpunpckhdq     m4, m8, m9

    vpunpcklqdq    m8, m2, m1
    vpunpckhqdq    m9, m2, m1
    vpunpcklqdq    m1, m6, m7
    vpunpckhqdq    m2, m6, m7
    vpunpcklqdq    m6, m0, m3
    vpunpckhqdq    m7, m0, m3
    vpunpcklqdq    m0, m5, m4
    vpunpckhqdq    m3, m5, m4

; row transform
    vpaddw         m4, m8, m3
    vpsubw         m5, m8, m3
    vpaddw         m3, m9, m0
    vpsubw         m8, m9, m0
    vpaddw         m0, m1, m7
    vpsubw         m9, m1, m7
    vpaddw         m1, m2, m6
    vpsubw         m7, m2, m6

    vpaddw         m2, m4, m1
    vpsubw         m6, m4, m1
    vpaddw         m1, m3, m0
    vpsubw         m4, m3, m0
    vpaddw         m0, m8, m9
    vpsraw         m10, m5, 1
    vpaddw         m10, m10, m5
    vpaddw         m0, m0, m10
    vpsubw         m3, m8, m9
    vpsraw         m10, m7, 1
    vpaddw         m10, m10, m7
    vpaddw         m3, m3, m10
    vpsraw         m10, m8, 1
    vpaddw         m8, m8, m10
    vpsraw         m10, m9, 1
    vpaddw         m9, m9, m10
    vpaddw         m10, m5, m7
    vpsubw         m8, m10, m8
    vpsubw         m10, m5, m7
    vpsubw         m9, m10, m9

    vpaddw         m5, m2, m1
    vpsubw         m7, m2, m1
    vpsraw         m10, m4, 1
    vpaddw         m2, m6, m10
    vpsraw         m10, m6, 1
    vpsubw         m1, m10, m4
    vpsraw         m10, m8, 2
    vpaddw         m6, m10, m9
    vpsraw         m10, m9, 2
    vpsubw         m4, m8, m10
    vpsraw         m10, m3, 2
    vpaddw         m9, m0, m10
    vpsraw         m10, m0, 2
    vpsubw         m8, m10, m3

; output
    vmovdqu        [r0 - 128], xm5
    vmovdqu        [r0 - 112], xm9
    vmovdqu        [r0 - 96], xm2
    vmovdqu        [r0 - 80], xm6
    vmovdqu        [r0 - 64], xm7
    vmovdqu        [r0 - 48], xm4
    vmovdqu        [r0 - 32], xm1
    vmovdqu        [r0 - 16], xm8
    vextracti128   [r0], m5, 1
    vextracti128   [r0 + 16], m9, 1
    vextracti128   [r0 + 32], m2, 1
    vextracti128   [r0 + 48], m6, 1
    vextracti128   [r0 + 64], m7, 1
    vextracti128   [r0 + 80], m4, 1
    vextracti128   [r0 + 96], m1, 1
    vextracti128   [r0 + 112], m8, 1
    ret


;=============================================================================
; ADD_IDCT
;=============================================================================
INIT_XMM avx2
cglobal add4x4_idct, 0, 0
    vmovdqu        m0, [r1]
    vmovdqu        m1, [r1 + 16]
    vpsraw         m2, m0, 1
    vpsraw         m3, m1, 1
    vpblendd       m2, m2, m0, 3
    vpblendd       m3, m3, m1, 3
    vpaddw         m0, m0, m3
    vpsubw         m1, m2, m1
    vpunpcklwd     m2, m0, m1
    vpunpckhwd     m3, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3

    vpshuflw       m2, m1, 10110001b
    vpshufhw       m3, m1, 10110001b
    vpunpckhdq     m1, m0, m3
    vpunpckldq     m0, m0, m2

    vpsraw         m2, m0, 1
    vpsraw         m3, m1, 1
    vpblendd       m2, m2, m0, 3
    vpblendd       m3, m3, m1, 3
    vpaddw         m0, m0, m3
    vpsubw         m1, m2, m1
    vpunpcklqdq    m2, m0, m1
    vpunpckhqdq    m3, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpbroadcastd   m2, [pw_32]
    vpaddw         m0, m0, m2
    vpaddw         m1, m1, m2
    vpsraw         m0, m0, 6
    vpsraw         m1, m1, 6

    vmovd          m2, [r0]
    vpunpckldq     m2, m2, [r0 + 32]
    vmovd          m3, [r0 + 96]
    vpunpckldq     m3, m3, [r0 + 64]
    vpmovzxbw      m2, m2
    vpmovzxbw      m3, m3
    vpaddw         m0, m0, m2
    vpaddw         m1, m1, m3
    vpackuswb      m0, m0, m1
    vmovd          [r0], m0
    vpextrd        [r0 + 32], m0, 1
    vpextrd        [r0 + 64], m0, 3
    vpextrd        [r0 + 96], m0, 2
    ret

INIT_YMM avx2
cglobal add8x8_idct, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
%endif
    add            r0, 128
    vmovdqu        xm0, [r1]
    vmovdqu        xm1, [r1 + 32]
    vmovdqu        xm2, [r1 + 16]
    vmovdqu        xm3, [r1 + 48]
    vinserti128    m0, m0, [r1 + 64],1  
    vinserti128    m1, m1, [r1 + 96],1
    vinserti128    m2, m2, [r1 + 80],1
    vinserti128    m3, m3, [r1 + 112],1
   
    vpunpckhqdq    m4, m0, m1
    vpunpcklqdq    m0, m0, m1
    vpunpckhqdq    m1, m2, m3
    vpunpcklqdq    m2, m2, m3
    vpsraw         m3, m4, 1
    vpsraw         m5, m1, 1
    vpaddw         m5, m5, m4
    vpsubw         m3, m3, m1
    vpaddw         m1, m2, m0
    vpsubw         m0, m0, m2
    vpaddw         m2, m5, m1
    vpsubw         m1, m1, m5
    vpaddw         m5, m3, m0
    vpsubw         m0, m0, m3
    vpunpckhwd     m4, m2, m5
    vpunpcklwd     m2, m2, m5
    vpunpckhwd     m5, m0, m1
    vpunpcklwd     m0, m0, m1
    vpunpckhdq     m1, m2, m0
    vpunpckldq     m2, m2, m0
    vpunpckhdq     m0, m4, m5
    vpunpckldq     m4, m4, m5
    vpunpckhqdq    m5, m2, m4
    vpunpcklqdq    m2, m2, m4
    vpunpckhqdq    m4, m1, m0
    vpunpcklqdq    m1, m1, m0

    vpbroadcastd   m6, [pw_32]
    vpaddw         m2, m2, m6
    vpsraw         m0, m5, 1
    vpsraw         m3, m4, 1
    vpaddw         m3, m3, m5
    vpsubw         m0, m0, m4
    vpaddw         m4, m1, m2
    vpsubw         m2, m2, m1
    vpaddw         m1, m3, m4
    vpsubw         m4, m4, m3
    vpaddw         m3, m0, m2
    vpsubw         m2, m2, m0

    vpxor          xm6, xm6, xm6
    vmovq          xm5, [r0 - 128]
    vinserti128    m5, m5, [r0],1
    vmovq          xm0, [r0 - 96]
    vinserti128    m0, m0, [r0 + 32],1 
    vpunpcklbw     m5, m5, m6
    vpunpcklbw     m0, m0, m6
    vpsraw         m1, m1, 6
    vpsraw         m3, m3, 6
    vpaddsw        m1, m1, m5
    vpaddsw        m3, m3, m0
    vpackuswb      m1, m1, m3
    vextracti128   xm3, m1,1
    vmovq          [r0 - 128], xm1
    vmovq          [r0], xm3
    vmovhps        [r0 - 96], xm1
    vmovhps        [r0 + 32], xm3

    vmovq          xm5, [r0 - 64]
    vinserti128    m5, m5, [r0 + 64],1
    vmovq          xm0, [r0 - 32]
    vinserti128    m0, m0, [r0 + 96],1
    vpunpcklbw     m5, m5, m6
    vpunpcklbw     m0, m0, m6
    vpsraw         m2, m2, 6
    vpsraw         m4, m4, 6
    vpaddsw        m2, m2, m5
    vpaddsw        m4, m4, m0
    vpackuswb      m2, m2, m4
    vextracti128   xm4, m2,1
    vmovq          [r0 - 64], xm2
    vmovq          [r0 + 64], xm4
    vmovhps        [r0 - 32], xm2
    vmovhps        [r0 + 96], xm4

%if WIN64
    vmovdqu        xm6, [rsp + 8]
%endif
    RET

INIT_XMM avx2
cglobal add8x8_idct_dc, 0, 0
    vpbroadcastd   m4, [pw_32]
    vpaddw         m4, m4, [r1]
    vpsraw         m4, m4, 6
    vpacksswb      m4, m4, m4
    add            r0, 128
    vpunpcklbw     m4, m4, m4
    vpunpcklwd     m4, m4, m4
    vpxor          m0, m0, m0
    vpminsb        m5, m4, m0
    vpmaxsb        m4, m4, m0
    vpsubb         m5, m0, m5

    vmovq          m0, [r0 - 128]
    vmovq          m1, [r0 - 96]
    vmovq          m2, [r0 - 64]
    vmovq          m3, [r0 - 32]
    vmovhps        m0, m0, [r0]
    vmovhps        m1, m1, [r0 + 32]
    vmovhps        m2, m2, [r0 + 64]
    vmovhps        m3, m3, [r0 + 96]
    vpaddusb       m0, m0, m4
    vpaddusb       m1, m1, m4
    vpaddusb       m2, m2, m4
    vpaddusb       m3, m3, m4
    vpsubusb       m0, m0, m5
    vpsubusb       m1, m1, m5
    vpsubusb       m2, m2, m5
    vpsubusb       m3, m3, m5
    vmovq          [r0 - 128], m0
    vmovq          [r0 - 96], m1
    vmovq          [r0 - 64], m2
    vmovq          [r0 - 32], m3
    vmovhps        [r0], m0
    vmovhps        [r0 + 32], m1
    vmovhps        [r0 + 64], m2
    vmovhps        [r0 + 96], m3
    ret

INIT_YMM avx2
cglobal add16x16_idct, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
%endif
    vpbroadcastd   m6, [pw_32]
    vpxor          xm7, xm7, xm7
    add            r0, 128
    call           .add8x8_idct
    add            r0, 8
    add            r1, 128
    call           .add8x8_idct
    add            r0, 248
    add            r1, 128
    call           .add8x8_idct
    add            r0, 8
    add            r1, 128
    call           .add8x8_idct
%if WIN64
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    RET

ALIGN 16
.add8x8_idct:
    vmovdqu        xm0, [r1]
    vmovdqu        xm1, [r1 + 32]
    vmovdqu        xm2, [r1 + 16]
    vmovdqu        xm3, [r1 + 48]
    vinserti128    m0, m0, [r1 + 64],1  
    vinserti128    m1, m1, [r1 + 96],1
    vinserti128    m2, m2, [r1 + 80],1
    vinserti128    m3, m3, [r1 + 112],1
   
    vpunpckhqdq    m4, m0, m1
    vpunpcklqdq    m0, m0, m1
    vpunpckhqdq    m1, m2, m3
    vpunpcklqdq    m2, m2, m3
    vpsraw         m3, m4, 1
    vpsraw         m5, m1, 1
    vpaddw         m5, m5, m4
    vpsubw         m3, m3, m1
    vpaddw         m1, m2, m0
    vpsubw         m0, m0, m2
    vpaddw         m2, m5, m1
    vpsubw         m1, m1, m5
    vpaddw         m5, m3, m0
    vpsubw         m0, m0, m3
    vpunpckhwd     m4, m2, m5
    vpunpcklwd     m2, m2, m5
    vpunpckhwd     m5, m0, m1
    vpunpcklwd     m0, m0, m1
    vpunpckhdq     m1, m2, m0
    vpunpckldq     m2, m2, m0
    vpunpckhdq     m0, m4, m5
    vpunpckldq     m4, m4, m5
    vpunpckhqdq    m5, m2, m4
    vpunpcklqdq    m2, m2, m4
    vpunpckhqdq    m4, m1, m0
    vpunpcklqdq    m1, m1, m0

    vpaddw         m2, m2, m6
    vpsraw         m0, m5, 1
    vpsraw         m3, m4, 1
    vpaddw         m3, m3, m5
    vpsubw         m0, m0, m4
    vpaddw         m4, m1, m2
    vpsubw         m2, m2, m1
    vpaddw         m1, m3, m4
    vpsubw         m4, m4, m3
    vpaddw         m3, m0, m2
    vpsubw         m2, m2, m0

    vmovq          xm5, [r0 - 128]
    vinserti128    m5, m5, [r0],1
    vmovq          xm0, [r0 - 96]
    vinserti128    m0, m0, [r0 + 32],1 
    vpunpcklbw     m5, m5, m7
    vpunpcklbw     m0, m0, m7
    vpsraw         m1, m1, 6
    vpsraw         m3, m3, 6
    vpaddsw        m1, m1, m5
    vpaddsw        m3, m3, m0
    vpackuswb      m1, m1, m3
    vextracti128   xm3, m1,1
    vmovq          [r0 - 128], xm1
    vmovq          [r0], xm3
    vmovhps        [r0 - 96], xm1
    vmovhps        [r0 + 32], xm3

    vmovq          xm5, [r0 - 64]
    vinserti128    m5, m5, [r0 + 64],1
    vmovq          xm0, [r0 - 32]
    vinserti128    m0, m0, [r0 + 96],1
    vpunpcklbw     m5, m5, m7
    vpunpcklbw     m0, m0, m7
    vpsraw         m2, m2, 6
    vpsraw         m4, m4, 6
    vpaddsw        m2, m2, m5
    vpaddsw        m4, m4, m0
    vpackuswb      m2, m2, m4
    vextracti128   xm4, m2,1
    vmovq          [r0 - 64], xm2
    vmovq          [r0 + 64], xm4
    vmovhps        [r0 - 32], xm2
    vmovhps        [r0 + 96], xm4
    ret

INIT_YMM avx2
cglobal add16x16_idct_dc, 0, 0
    vpbroadcastd   m4, [pw_32]
    vpaddw         m4, m4, [r1]
    vpsraw         m4, m4, 6
    vpacksswb      m4, m4, m4
    vpunpcklbw     m4, m4, m4
    vpxor          m0, m0, m0
    vpminsb        m5, m4, m0
    vpmaxsb        m4, m4, m0
    vpsubb         m5, m0, m5
    lea            r6, [r0 + 384]
    add            r0, 128

    vpunpcklwd     m2, m4, m4
    vpunpcklwd     m3, m5, m5
    vmovdqu        xm0, [r0 - 128]
    vinserti128    m0, m0, [r6 - 128], 1
    vmovdqu        xm1, [r0 - 96]
    vinserti128    m1, m1, [r6 - 96], 1
    vpaddusb       m0, m0, m2
    vpaddusb       m1, m1, m2
    vpsubusb       m0, m0, m3
    vpsubusb       m1, m1, m3
    vmovdqu        [r0 - 128], xm0
    vextracti128   [r6 - 128], m0, 1
    vmovdqu        [r0 - 96], xm1
    vextracti128   [r6 - 96], m1, 1
    vmovdqu        xm0, [r0 - 64]
    vinserti128    m0, m0, [r6 - 64], 1
    vmovdqu        xm1, [r0 - 32]
    vinserti128    m1, m1, [r6 - 32], 1
    vpaddusb       m0, m0, m2
    vpaddusb       m1, m1, m2
    vpsubusb       m0, m0, m3
    vpsubusb       m1, m1, m3
    vmovdqu        [r0 - 64], xm0
    vextracti128   [r6 - 64], m0, 1
    vmovdqu        [r0 - 32], xm1
    vextracti128   [r6 - 32], m1, 1

    vpunpckhwd     m2, m4, m4
    vpunpckhwd     m3, m5, m5
    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r6], 1
    vmovdqu        xm1, [r0 + 32]
    vinserti128    m1, m1, [r6 + 32], 1
    vpaddusb       m0, m0, m2
    vpaddusb       m1, m1, m2
    vpsubusb       m0, m0, m3
    vpsubusb       m1, m1, m3
    vmovdqu        [r0], xm0
    vextracti128   [r6], m0, 1
    vmovdqu        [r0 + 32], xm1
    vextracti128   [r6 + 32], m1, 1
    vmovdqu        xm0, [r0 + 64]
    vinserti128    m0, m0, [r6 + 64], 1
    vmovdqu        xm1, [r0 + 96]
    vinserti128    m1, m1, [r6 + 96], 1
    vpaddusb       m0, m0, m2
    vpaddusb       m1, m1, m2
    vpsubusb       m0, m0, m3
    vpsubusb       m1, m1, m3
    vmovdqu        [r0 + 64], xm0
    vextracti128   [r6 + 64], m0, 1
    vmovdqu        [r0 + 96], xm1
    vextracti128   [r6 + 96], m1, 1
    RET

INIT_XMM avx2
cglobal add8x8_idct8, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 56
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
%endif
    vmovdqu        m0, [r1]
    vmovdqu        m1, [r1 + 16]
    vmovdqu        m2, [r1 + 32]
    vmovdqu        m3, [r1 + 48]
    vmovdqu        m4, [r1 + 64]
    vmovdqu        m5, [r1 + 80]
    vmovdqu        m6, [r1 + 96]
    vmovdqu        m7, [r1 + 112]
    add            r0, 128

; column transform
    vpaddw         m8, m0, m4
    vpsubw         m9, m0, m4
    vpsraw         m10, m6, 1
    vpaddw         m0, m2, m10
    vpsraw         m10, m2, 1
    vpsubw         m4, m10, m6
    vpsraw         m10, m1, 1
    vpaddw         m10, m10, m1
    vpaddw         m6, m5, m3
    vpaddw         m6, m6, m10
    vpsraw         m10, m7, 1
    vpaddw         m10, m7, m10
    vpsubw         m2, m5, m3
    vpsubw         m2, m2, m10
    vpsraw         m10, m3, 1
    vpaddw         m10, m3, m10
    vpaddw         m3, m7, m1
    vpsubw         m3, m3, m10
    vpsraw         m10, m5, 1
    vpaddw         m10, m10, m5
    vpsubw         m5, m7, m1
    vpaddw         m5, m5, m10

    vpaddw         m1, m8, m0
    vpsubw         m7, m8, m0
    vpaddw         m0, m9, m4
    vpsubw         m8, m9, m4
    vpsraw         m10, m6, 2
    vpaddw         m9, m10, m2
    vpsraw         m10, m2, 2
    vpsubw         m4, m6, m10
    vpsraw         m10, m5, 2
    vpaddw         m6, m3, m10
    vpsraw         m10, m3, 2
    vpsubw         m2, m10, m5

    vpaddw         m3, m1, m4
    vpsubw         m5, m1, m4
    vpaddw         m4, m0, m2
    vpsubw         m1, m0, m2
    vpaddw         m0, m8, m6
    vpsubw         m2, m8, m6
    vpaddw         m6, m7, m9
    vpsubw         m8, m7, m9

; transpose
    vpunpcklwd     m7, m3, m4
    vpunpckhwd     m9, m3, m4
    vpunpcklwd     m3, m0, m6
    vpunpckhwd     m4, m0, m6
    vpunpcklwd     m0, m8, m2
    vpunpckhwd     m6, m8, m2
    vpunpcklwd     m2, m1, m5
    vpunpckhwd     m8, m1, m5
    vpunpckldq     m1, m7, m3
    vpunpckhdq     m5, m7, m3
    vpunpckldq     m3, m9, m4
    vpunpckhdq     m7, m9, m4
    vpunpckldq     m4, m0, m2
    vpunpckhdq     m9, m0, m2
    vpunpckldq     m0, m6, m8
    vpunpckhdq     m2, m6, m8
    vpunpcklqdq    m6, m1, m4
    vpunpckhqdq    m8, m1, m4
    vpunpcklqdq    m1, m5, m9
    vpunpckhqdq    m4, m5, m9
    vpunpcklqdq    m5, m3, m0
    vpunpckhqdq    m9, m3, m0
    vpunpcklqdq    m0, m7, m2
    vpunpckhqdq    m3, m7, m2

; row transform
    vpbroadcastd   m10, [pw_32]
    vpaddw         m6, m6, m10

    vpaddw         m2, m6, m5
    vpsubw         m7, m6, m5
    vpsraw         m10, m0, 1
    vpaddw         m5, m1, m10
    vpsraw         m10, m1, 1
    vpsubw         m6, m10, m0
    vpsraw         m10, m8, 1
    vpaddw         m10, m10, m8
    vpaddw         m1, m9, m4
    vpaddw         m1, m1, m10
    vpsraw         m10, m3, 1
    vpaddw         m10, m3, m10
    vpsubw         m0, m9, m4
    vpsubw         m0, m0, m10
    vpsraw         m10, m4, 1
    vpaddw         m10, m4, m10
    vpaddw         m4, m3, m8
    vpsubw         m4, m4, m10
    vpsraw         m10, m9, 1
    vpaddw         m10, m10, m9
    vpsubw         m9, m3, m8
    vpaddw         m9, m9, m10

    vpaddw         m3, m2, m5
    vpsubw         m8, m2, m5
    vpaddw         m2, m7, m6
    vpsubw         m5, m7, m6
    vpsraw         m10, m1, 2
    vpaddw         m7, m10, m0
    vpsraw         m10, m0, 2
    vpsubw         m6, m1, m10
    vpsraw         m10, m9, 2
    vpaddw         m1, m4, m10
    vpsraw         m10, m4, 2
    vpsubw         m0, m10, m9

    vpaddw         m4, m3, m6
    vpsubw         m9, m3, m6
    vpaddw         m6, m2, m0
    vpsubw         m3, m2, m0
    vpaddw         m0, m5, m1
    vpsubw         m2, m5, m1
    vpaddw         m1, m8, m7
    vpsubw         m5, m8, m7

; add and clip
    vpmovzxbw      m7, [r0 - 128]
    vpsraw         m4, m4, 6
    vpaddsw        m4, m4, m7
    vpmovzxbw      m7, [r0 - 96]
    vpsraw         m6, m6, 6
    vpaddsw        m6, m6, m7
    vpmovzxbw      m7, [r0 - 64]
    vpsraw         m0, m0, 6
    vpaddsw        m0, m0, m7
    vpmovzxbw      m7, [r0 - 32]
    vpsraw         m1, m1, 6
    vpaddsw        m1, m1, m7
    vpmovzxbw      m7, [r0]
    vpsraw         m5, m5, 6
    vpaddsw        m5, m5, m7
    vpmovzxbw      m7, [r0 + 32]
    vpsraw         m2, m2, 6
    vpaddsw        m2, m2, m7
    vpmovzxbw      m7, [r0 + 64]
    vpsraw         m3, m3, 6
    vpaddsw        m3, m3, m7
    vpmovzxbw      m7, [r0 + 96]
    vpsraw         m9, m9, 6
    vpaddsw        m9, m9, m7
    vpackuswb      m4, m4, m6
    vpackuswb      m0, m0, m1
    vpackuswb      m5, m5, m2
    vpackuswb      m3, m3, m9
    vmovq          [r0 - 128], m4
    vmovhps        [r0 - 96], m4
    vmovq          [r0 - 64], m0
    vmovhps        [r0 - 32], m0
    vmovq          [r0], m5
    vmovhps        [r0 + 32], m5
    vmovq          [r0 + 64], m3
    vmovhps        [r0 + 96], m3

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    add            rsp, 56
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    ret

INIT_YMM avx2
cglobal add16x16_idct8, 0, 0
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
    mov            r2, rsp
    sub            rsp, 104
    and            rsp, ~31
; part 0/2
    lea            r6, [r1 + 384]
    add            r1, 128
    vmovdqu        xm0, [r1 - 128]
    vinserti128    m0, m0, [r6 - 128], 1
    vmovdqu        xm1, [r1 - 112]
    vinserti128    m1, m1, [r6 - 112], 1
    vmovdqu        xm2, [r1 - 96]
    vinserti128    m2, m2, [r6 - 96], 1
    vmovdqu        xm3, [r1 - 80]
    vinserti128    m3, m3, [r6 - 80], 1
    vmovdqu        xm4, [r1 - 64]
    vinserti128    m4, m4, [r6 - 64], 1
    vmovdqu        xm5, [r1 - 48]
    vinserti128    m5, m5, [r6 - 48], 1
    vmovdqu        xm6, [r1 - 32]
    vinserti128    m6, m6, [r6 - 32], 1
    vmovdqu        xm7, [r1 - 16]
    vinserti128    m7, m7, [r6 - 16], 1

; column transform
    vpaddw         m8, m0, m4
    vpsubw         m9, m0, m4
    vpsraw         m10, m6, 1
    vpaddw         m0, m2, m10
    vpsraw         m10, m2, 1
    vpsubw         m4, m10, m6
    vpsraw         m10, m1, 1
    vpaddw         m10, m10, m1
    vpaddw         m6, m5, m3
    vpaddw         m6, m6, m10
    vpsraw         m10, m7, 1
    vpaddw         m10, m7, m10
    vpsubw         m2, m5, m3
    vpsubw         m2, m2, m10
    vpsraw         m10, m3, 1
    vpaddw         m10, m3, m10
    vpaddw         m3, m7, m1
    vpsubw         m3, m3, m10
    vpsraw         m10, m5, 1
    vpaddw         m10, m10, m5
    vpsubw         m5, m7, m1
    vpaddw         m5, m5, m10

    vpaddw         m1, m8, m0
    vpsubw         m7, m8, m0
    vpaddw         m0, m9, m4
    vpsubw         m8, m9, m4
    vpsraw         m10, m6, 2
    vpaddw         m9, m10, m2
    vpsraw         m10, m2, 2
    vpsubw         m4, m6, m10
    vpsraw         m10, m5, 2
    vpaddw         m6, m3, m10
    vpsraw         m10, m3, 2
    vpsubw         m2, m10, m5

    vpaddw         m3, m1, m4
    vpsubw         m5, m1, m4
    vpaddw         m4, m0, m2
    vpsubw         m1, m0, m2
    vpaddw         m0, m8, m6
    vpsubw         m2, m8, m6
    vpaddw         m6, m7, m9
    vpsubw         m8, m7, m9

; transpose
    vpunpcklwd     m7, m3, m4
    vpunpckhwd     m9, m3, m4
    vpunpcklwd     m3, m0, m6
    vpunpckhwd     m4, m0, m6
    vpunpcklwd     m0, m8, m2
    vpunpckhwd     m6, m8, m2
    vpunpcklwd     m2, m1, m5
    vpunpckhwd     m8, m1, m5
    vpunpckldq     m1, m7, m3
    vpunpckhdq     m5, m7, m3
    vpunpckldq     m3, m9, m4
    vpunpckhdq     m7, m9, m4
    vpunpckldq     m4, m0, m2
    vpunpckhdq     m9, m0, m2
    vpunpckldq     m0, m6, m8
    vpunpckhdq     m2, m6, m8
    vpunpcklqdq    m6, m1, m4
    vpunpckhqdq    m8, m1, m4
    vpunpcklqdq    m1, m5, m9
    vpunpckhqdq    m4, m5, m9
    vpunpcklqdq    m5, m3, m0
    vpunpckhqdq    m9, m3, m0
    vpunpcklqdq    m0, m7, m2
    vpunpckhqdq    m3, m7, m2

; row transform
    vpbroadcastd   m10, [pw_32]
    vpaddw         m6, m6, m10

    vpaddw         m2, m6, m5
    vpsubw         m7, m6, m5
    vpsraw         m10, m0, 1
    vpaddw         m5, m1, m10
    vpsraw         m10, m1, 1
    vpsubw         m6, m10, m0
    vpsraw         m10, m8, 1
    vpaddw         m10, m10, m8
    vpaddw         m1, m9, m4
    vpaddw         m1, m1, m10
    vpsraw         m10, m3, 1
    vpaddw         m10, m3, m10
    vpsubw         m0, m9, m4
    vpsubw         m0, m0, m10
    vpsraw         m10, m4, 1
    vpaddw         m10, m4, m10
    vpaddw         m4, m3, m8
    vpsubw         m4, m4, m10
    vpsraw         m10, m9, 1
    vpaddw         m10, m10, m9
    vpsubw         m9, m3, m8
    vpaddw         m9, m9, m10

    vpaddw         m3, m2, m5
    vpsubw         m8, m2, m5
    vpaddw         m2, m7, m6
    vpsubw         m5, m7, m6
    vpsraw         m10, m1, 2
    vpaddw         m7, m10, m0
    vpsraw         m10, m0, 2
    vpsubw         m6, m1, m10
    vpsraw         m10, m9, 2
    vpaddw         m1, m4, m10
    vpsraw         m10, m4, 2
    vpsubw         m0, m10, m9

    vpaddw         m4, m3, m6
    vpsubw         m9, m3, m6
    vpaddw         m6, m2, m0
    vpsubw         m3, m2, m0
    vpaddw         m0, m5, m1
    vpsubw         m2, m5, m1
    vpaddw         m1, m8, m7
    vpsubw         m5, m8, m7
    vmovdqu        [rsp], m9
    vmovdqu        [rsp + 32], m3
    vmovdqu        [rsp + 64], m2

; part 1/3
    vmovdqu        xm7, [r1]
    vinserti128    m7, m7, [r6], 1
    vmovdqu        xm8, [r1 + 16]
    vinserti128    m8, m8, [r6 + 16], 1
    vmovdqu        xm2, [r1 + 32]
    vinserti128    m2, m2, [r6 + 32], 1
    vmovdqu        xm3, [r1 + 48]
    vinserti128    m3, m3, [r6 + 48], 1
    vmovdqu        xm9, [r1 + 64]
    vinserti128    m9, m9, [r6 + 64], 1
    vmovdqu        xm10, [r1 + 80]
    vinserti128    m10, m10, [r6 + 80], 1
    vmovdqu        xm11, [r1 + 96]
    vinserti128    m11, m11, [r6 + 96], 1
    vmovdqu        xm12, [r1 + 112]
    vinserti128    m12, m12, [r6 + 112], 1

; column transform
    vpaddw         m13, m7, m9
    vpsubw         m14, m7, m9
    vpsraw         m15, m11, 1
    vpaddw         m7, m2, m15
    vpsraw         m15, m2, 1
    vpsubw         m9, m15, m11
    vpsraw         m15, m8, 1
    vpaddw         m15, m15, m8
    vpaddw         m11, m10, m3
    vpaddw         m11, m11, m15
    vpsraw         m15, m12, 1
    vpaddw         m15, m15, m12
    vpsubw         m2, m10, m3
    vpsubw         m2, m2, m15
    vpsraw         m15, m3, 1
    vpaddw         m15, m15, m3
    vpaddw         m3, m12, m8
    vpsubw         m3, m3, m15
    vpsraw         m15, m10, 1
    vpaddw         m15, m15, m10
    vpsubw         m10, m12, m8
    vpaddw         m10, m10, m15

    vpaddw         m8, m13, m7
    vpsubw         m12, m13, m7
    vpaddw         m7, m14, m9
    vpsubw         m13, m14, m9
    vpsraw         m15, m11, 2
    vpaddw         m14, m15, m2
    vpsraw         m15, m2, 2
    vpsubw         m9, m11, m15
    vpsraw         m15, m10, 2
    vpaddw         m11, m3, m15
    vpsraw         m15, m3, 2
    vpsubw         m2, m15, m10

    vpaddw         m3, m8, m9
    vpsubw         m10, m8, m9
    vpaddw         m9, m7, m2
    vpsubw         m8, m7, m2
    vpaddw         m2, m13, m11
    vpsubw         m7, m13, m11
    vpaddw         m11, m12, m14
    vpsubw         m13, m12, m14

; transpose
    vpunpcklwd     m12, m3, m9
    vpunpckhwd     m14, m3, m9
    vpunpcklwd     m3, m2, m11
    vpunpckhwd     m9, m2, m11
    vpunpcklwd     m2, m13, m7
    vpunpckhwd     m11, m13, m7
    vpunpcklwd     m7, m8, m10
    vpunpckhwd     m13, m8, m10
    vpunpckldq     m8, m12, m3
    vpunpckhdq     m10, m12, m3
    vpunpckldq     m3, m14, m9
    vpunpckhdq     m12, m14, m9
    vpunpckldq     m9, m2, m7
    vpunpckhdq     m14, m2, m7
    vpunpckldq     m2, m11, m13
    vpunpckhdq     m7, m11, m13
    vpunpcklqdq    m11, m8, m9
    vpunpckhqdq    m13, m8, m9
    vpunpcklqdq    m8, m10, m14
    vpunpckhqdq    m9, m10, m14
    vpunpcklqdq    m10, m3, m2
    vpunpckhqdq    m14, m3, m2
    vpunpcklqdq    m2, m12, m7
    vpunpckhqdq    m3, m12, m7

; row transform
    vpbroadcastd   m15, [pw_32]
    vpaddw         m11, m11, m15

    vpaddw         m7, m11, m10
    vpsubw         m12, m11, m10
    vpsraw         m15, m2, 1
    vpaddw         m10, m8, m15
    vpsraw         m15, m8, 1
    vpsubw         m11, m15, m2
    vpsraw         m15, m13, 1
    vpaddw         m15, m15, m13
    vpaddw         m8, m14, m9
    vpaddw         m8, m8, m15
    vpsraw         m15, m3, 1
    vpaddw         m15, m15, m3
    vpsubw         m2, m14, m9
    vpsubw         m2, m2, m15
    vpsraw         m15, m9, 1
    vpaddw         m15, m15, m9
    vpaddw         m9, m3, m13
    vpsubw         m9, m9, m15
    vpsraw         m15, m14, 1
    vpaddw         m15, m15, m14
    vpsubw         m14, m3, m13
    vpaddw         m14, m14, m15

    vpaddw         m3, m7, m10
    vpsubw         m13, m7, m10
    vpaddw         m7, m12, m11
    vpsubw         m10, m12, m11
    vpsraw         m15, m8, 2
    vpaddw         m12, m15, m2
    vpsraw         m15, m2, 2
    vpsubw         m11, m8, m15
    vpsraw         m15, m14, 2
    vpaddw         m8, m9, m15
    vpsraw         m15, m9, 2
    vpsubw         m2, m15, m14

    vpaddw         m9, m3, m11
    vpsubw         m14, m3, m11
    vpaddw         m11, m7, m2
    vpsubw         m3, m7, m2
    vpaddw         m2, m10, m8
    vpsubw         m7, m10, m8
    vpaddw         m8, m13, m12
    vpsubw         m10, m13, m12

; add and clip
    lea            r6, [r0 + 384]
    add            r0, 128
    vpxor          m15, m15, m15
    vmovdqu        xm12, [r0 - 128]
    vinserti128    m12, m12, [r6 - 128], 1
    vpunpckhbw     m13, m12, m15
    vpunpcklbw     m12, m12, m15
    vpsraw         m4, m4, 6
    vpsraw         m9, m9, 6
    vpaddsw        m4, m4, m12
    vpaddsw        m9, m9, m13
    vpackuswb      m4, m4, m9
    vmovdqu        [r0 - 128], xm4
    vextracti128   [r6 - 128], m4, 1
    vmovdqu        xm12, [r0 - 96]
    vinserti128    m12, m12, [r6 - 96], 1
    vpunpckhbw     m13, m12, m15
    vpunpcklbw     m12, m12, m15
    vpsraw         m6, m6, 6
    vpsraw         m11, m11, 6
    vpaddsw        m6, m6, m12
    vpaddsw        m11, m11, m13
    vpackuswb      m6, m6, m11
    vmovdqu        [r0 - 96], xm6
    vextracti128   [r6 - 96], m6, 1
    vmovdqu        xm12, [r0 - 64]
    vinserti128    m12, m12, [r6 - 64], 1
    vpunpckhbw     m13, m12, m15
    vpunpcklbw     m12, m12, m15
    vpsraw         m0, m0, 6
    vpsraw         m2, m2, 6
    vpaddsw        m0, m0, m12
    vpaddsw        m2, m2, m13
    vpackuswb      m0, m0, m2
    vmovdqu        [r0 - 64], xm0
    vextracti128   [r6 - 64], m0, 1
    vmovdqu        xm12, [r0 - 32]
    vinserti128    m12, m12, [r6 - 32], 1
    vpunpckhbw     m13, m12, m15
    vpunpcklbw     m12, m12, m15
    vpsraw         m1, m1, 6
    vpsraw         m8, m8, 6
    vpaddsw        m1, m1, m12
    vpaddsw        m8, m8, m13
    vpackuswb      m1, m1, m8
    vmovdqu        [r0 - 32], xm1
    vextracti128   [r6 - 32], m1, 1
    vmovdqu        xm12, [r0]
    vinserti128    m12, m12, [r6], 1
    vpunpckhbw     m13, m12, m15
    vpunpcklbw     m12, m12, m15
    vpsraw         m5, m5, 6
    vpsraw         m10, m10, 6
    vpaddsw        m5, m5, m12
    vpaddsw        m10, m10, m13
    vpackuswb      m5, m5, m10
    vmovdqu        [r0], xm5
    vextracti128   [r6], m5, 1
    vmovdqu        xm12, [r0 + 32]
    vinserti128    m12, m12, [r6 + 32], 1
    vpunpckhbw     m13, m12, m15
    vpunpcklbw     m12, m12, m15
    vmovdqu        m2, [rsp + 64]
    vpsraw         m2, m2, 6
    vpsraw         m7, m7, 6
    vpaddsw        m2, m2, m12
    vpaddsw        m7, m7, m13
    vpackuswb      m2, m2, m7
    vmovdqu        [r0 + 32], xm2
    vextracti128   [r6 + 32], m2, 1
    vmovdqu        xm12, [r0 + 64]
    vinserti128    m12, m12, [r6 + 64], 1
    vpunpckhbw     m13, m12, m15
    vpunpcklbw     m12, m12, m15
    vmovdqu        m9, [rsp + 32]
    vpsraw         m9, m9, 6
    vpsraw         m3, m3, 6
    vpaddsw        m9, m9, m12
    vpaddsw        m3, m3, m13
    vpackuswb      m9, m9, m3
    vmovdqu        [r0 + 64], xm9
    vextracti128   [r6 + 64], m9, 1
    vmovdqu        xm12, [r0 + 96]
    vinserti128    m12, m12, [r6 + 96], 1
    vpunpckhbw     m13, m12, m15
    vpunpcklbw     m12, m12, m15
    vmovdqu        m9, [rsp]
    vpsraw         m9, m9, 6
    vpsraw         m14, m14, 6
    vpaddsw        m9, m9, m12
    vpaddsw        m14, m14, m13
    vpackuswb      m9, m9, m14
    vmovdqu        [r0 + 96], xm9
    vextracti128   [r6 + 96], m9, 1

    mov            rsp, r2
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
; DCT_DC
;=============================================================================
INIT_XMM avx2
cglobal dct4x4dc, 0, 0
    vmovdqu        m0, [r0]
    vmovdqu        m1, [r0 + 16]
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpunpcklqdq    m0, m2, m3
    vpunpckhqdq    m1, m2, m3
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1

    vshufps        m0, m2, m3, 28h
    vshufps        m2, m2, m3, 7Dh
    vpaddw         m4, m0, m2
    vpsubw         m5, m0, m2
    vpunpcklwd     m0, m4, m5
    vpunpckhwd     m1, m4, m5
    vshufps        m2, m0, m1, 88h
    vshufps        m3, m0, m1, 0DDh
    vmovddup       m5, [pw_8000]                 ; convert to unsigned and back, so that pavgw works
    vpxor          m4, m5, m2
    vpsubw         m1, m5, m3
    vpxor          m0, m5, m3
    vpavgw         m1, m1, m4
    vpavgw         m0, m0, m4
    vpxor          m1, m1, m5
    vpxor          m0, m0, m5
    vpshufb        m0, m0, [dct4x4dc_shuf1]
    vpshufb        m1, m1, [dct4x4dc_shuf2]
    vmovdqu        [r0], m0
    vmovdqu        [r0 + 16], m1
    ret

INIT_XMM avx2
cglobal idct4x4dc, 0, 0
    vmovdqu        m0, [r0]
    vmovdqu        m1, [r0 + 16]
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpunpcklqdq    m0, m2, m3
    vpunpckhqdq    m1, m2, m3
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1

    vshufps        m0, m2, m3, 28h
    vshufps        m2, m2, m3, 7Dh
    vpaddw         m4, m0, m2
    vpsubw         m5, m0, m2
    vpunpcklwd     m0, m4, m5
    vpunpckhwd     m1, m4, m5
    vshufps        m2, m0, m1, 88h
    vshufps        m3, m0, m1, 0DDh
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpshufb        m0, m0, [dct4x4dc_shuf1]
    vpshufb        m1, m1, [dct4x4dc_shuf2]
    vmovdqu        [r0], m0
    vmovdqu        [r0 + 16], m1
    ret

INIT_XMM avx2
cglobal dct2x4dc, 0, 0
    xor            eax, eax
    add            r1, 128
    vmovd          m0, [r1 - 128]
    mov            [r1 - 128], ax
    vmovd          m1, [r1 - 96]
    mov            [r1 - 96], ax
    vpunpcklwd     m0, m0, [r1 - 64]
    mov            [r1 - 64], ax
    vpunpcklwd     m1, m1, [r1 - 32]
    mov            [r1 - 32], ax
    vpunpckldq     m0, m0, [r1]
    mov            [r1], ax
    vpunpckldq     m1, m1, [r1 + 32]
    mov            [r1 + 32], ax
    vpinsrw        m0, m0, [r1 + 64], 3
    mov            [r1 + 64], ax
    vpinsrw        m1, m1, [r1 + 96], 3
    mov            [r1 + 96], ax
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpunpcklwd     m0, m2, m3
    vpunpckhqdq    m1, m0, m0
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpunpckldq     m0, m2, m3
    vpunpckhqdq    m1, m0, m0
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1    
    vshufps        m0, m2, m3, 14h
    vmovdqu        [r0], m0
    ret


;=============================================================================
; INTERLEAVE_8X8_CAVLC
;=============================================================================
INIT_YMM avx2
cglobal zigzag_interleave_8x8_cavlc, 0, 0
    vmovdqu        m0, [r1]
    vmovdqu        m1, [r1 + 32]
    vmovdqu        m2, [r1 + 64]
    vmovdqu        m3, [r1 + 96]
    vmovdqu        m5, [deinterleave_shufd]
    vpunpckhwd     m4, m0, m1
    vpunpcklwd     m0, m0, m1
    vpunpckhwd     m1, m2, m3
    vpunpcklwd     m2, m2, m3
    vpunpckhwd     m3, m0, m4
    vpunpcklwd     m0, m0, m4
    vpunpckhwd     m4, m2, m1
    vpunpcklwd     m2, m2, m1
    vpermd         m0, m5, m0
    vpermd         m3, m5, m3
    vpermd         m2, m5, m2
    vpermd         m4, m5, m4
    vmovdqu        [r0], xm0
    vmovdqu        [r0 + 16], xm2
    vextracti128   [r0 + 32], m0, 1
    vextracti128   [r0 + 48], m2, 1
    vmovdqu        [r0 + 64], xm3
    vmovdqu        [r0 + 80], xm4
    vextracti128   [r0 + 96], m3, 1
    vextracti128   [r0 + 112], m4, 1
    vpacksswb      m0, m0, m2                    ; nnz0, nnz1
    vpacksswb      m3, m3, m4                    ; nnz2, nnz3
    vpacksswb      m0, m0, m3                    ; {nnz0,nnz2}, {nnz1,nnz3}
    vpermq         m0, m0, 0D8h                  ; {nnz0,nnz1}, {nnz2,nnz3}
    vpxor          m5, m5, m5
    vpcmpeqq       m0, m0, m5
    vpmovmskb      r0d, m0
    not            r0d
    and            r0d, 01010101h
    mov            [r2], r0w
    shr            r0d, 16
    mov            [r2 + 8], r0w
    RET


;=============================================================================
; SCAN
;=============================================================================
;  0  2  3  9 10 20 21 35
;  1  4  8 11 19 22 34 36
;  5  7 12 18 23 33 37 48
;  6 13 17 24 32 38 47 49
; 14 16 25 31 39 46 50 57
; 15 26 30 40 45 51 56 58
; 27 29 41 44 52 55 59 62
; 28 42 43 53 54 60 61 63
INIT_XMM avx2
cglobal zigzag_scan_8x8_frame, 0, 0
; 0 - 15
    vmovd          m0, [r1]
    vpunpcklwd     m0, m0, [r1 + 16]
    vmovd          [r0], m0
    mov            eax, [r1 + 2]
    mov            [r0 + 4], eax
    vmovd          m0, [r1 + 18]
    vpunpcklwd     m0, m0, [r1 + 32]
    vmovd          [r0 + 8], m0
    vmovd          m0, [r1 + 48]
    vpunpcklwd     m0, m0, [r1 + 34]
    vmovd          [r0 + 12], m0
    vmovd          m0, [r1 + 20]
    vpunpcklwd     m0, m0, [r1 + 6]
    vmovd          [r0 + 16], m0
    vmovd          m0, [r1 + 8]
    vpunpcklwd     m0, m0, [r1 + 22]
    vmovd          [r0 + 20], m0
    vmovd          m0, [r1 + 36]
    vpinsrw        m0, m0, [r1 + 50], 1
    vmovd          [r0 + 24], m0
    vmovd          m0, [r1 + 64]
    vpunpcklwd     m0, m0, [r1 + 80]
    vmovd          [r0 + 28], m0

; 16 - 31
    vmovd          m0, [r1 + 66]
    vpinsrw        m0, m0, [r1 + 52], 1
    vmovd          [r0 + 32], m0
    vmovd          m0, [r1 + 38]
    vpunpcklwd     m0, m0, [r1 + 24]
    vmovd          [r0 + 36], m0
    mov            eax, [r1 + 10]
    mov            [r0 + 40], eax
    vmovd          m0, [r1 + 26]
    vpunpcklwd     m0, m0, [r1 + 40]
    vmovd          [r0 + 44], m0
    vmovd          m0, [r1 + 54]
    vpunpcklwd     m0, m0, [r1 + 68]
    vmovd          [r0 + 48], m0
    vmovd          m0, [r1 + 82]
    vpunpcklwd     m0, m0, [r1 + 96]
    vmovd          [r0 + 52], m0
    vmovd          m0, [r1 + 112]
    vpunpcklwd     m0, m0, [r1 + 98]
    vmovd          [r0 + 56], m0
    vmovd          m0, [r1 + 84]
    vpunpcklwd     m0, m0, [r1 + 70]
    vmovd          [r0 + 60], m0

; 32 - 47
    vmovd          m0, [r1 + 56]
    vpunpcklwd     m0, m0, [r1 + 42]
    vmovd          [r0 + 64], m0
    vmovd          m0, [r1 + 28]
    vpunpcklwd     m0, m0, [r1 + 14]
    vmovd          [r0 + 68], m0
    vmovd          m0, [r1 + 30]
    vpunpcklwd     m0, m0, [r1 + 44]
    vmovd          [r0 + 72], m0
    vmovd          m0, [r1 + 58]
    vpunpcklwd     m0, m0, [r1 + 72]
    vmovd          [r0 + 76], m0
    vmovd          m0, [r1 + 86]
    vpunpcklwd     m0, m0, [r1 + 100]
    vmovd          [r0 + 80], m0
    mov            eax, [r1 + 114]
    mov            [r0 + 84], eax
    vmovd          m0, [r1 + 102]
    vpunpcklwd     m0, m0, [r1 + 88]
    vmovd          [r0 + 88], m0
    vmovd          m0, [r1 + 74]
    vpinsrw        m0, m0, [r1 + 60], 1
    vmovd          [r0 + 92], m0

; 48 - 63
    vmovd          m0, [r1 + 46]
    vpinsrw        m0, m0, [r1 + 62], 1
    vmovd          [r0 + 96], m0
    vmovd          m0, [r1 + 76]
    vpunpcklwd     m0, m0, [r1 + 90]
    vmovd          [r0 + 100], m0
    vmovd          m0, [r1 + 104]
    vpinsrw        m0, m0, [r1 + 118], 1
    vmovd          [r0 + 104], m0
    vmovd          m0, [r1 + 120]
    vpunpcklwd     m0, m0, [r1 + 106]
    vmovd          [r0 + 108], m0
    vmovd          m0, [r1 + 92]
    vpunpcklwd     m0, m0, [r1 + 78]
    vmovd          [r0 + 112], m0
    vmovd          m0, [r1 + 94]
    vpunpcklwd     m0, m0, [r1 + 108]
    vmovd          [r0 + 116], m0
    mov            eax, [r1 + 122]
    mov            [r0 + 120], eax
    vmovd          m0, [r1 + 110]
    vpinsrw        m0, m0, [r1 + 126], 1
    vmovd          [r0 + 124], m0
    ret

; 0  2  3  9 
; 1  4  8 10 
; 5  7 11 14 
; 6 12 13 15 
INIT_XMM avx2
cglobal zigzag_scan_4x4_frame, 0, 0
    vmovdqu        m0, [r1]
    vmovdqu        m1, [r1 + 16]
    vmovdqu        m2, [scan_4x4_shuf]
    vpshufb        m0, m0, m2
    vpshufb        m1, m1, m2
    vpslldq        m2, m0, 6
    vpalignr       m2, m1, m2, 6
    vmovdqu        [r0], m2
    vpsrldq        m2, m1, 6
    vpalignr       m2, m2, m0, 10
    vmovdqu        [r0 + 16], m2
    ret


;=============================================================================
; SUB
;=============================================================================
; 0  1  5  6 
; 2  4  7 12 
; 3  8 11 13 
; 9 10 14 15 
INIT_XMM avx2
cglobal zigzag_sub_4x4_frame, 0, 0
    vmovd          m0, [r1]
    vmovd          m1, [r1 + 16]
    vmovd          m2, [r1 + 32]
    vmovd          m3, [r1 + 48]
    vmovd          m4, [r2]
    vmovd          m5, [r2 + 32]
    vmovd          [r2], m0
    vmovd          [r2 + 32], m1
    vpunpckldq     m0, m0, m1
    vpunpckldq     m4, m4, m5
    vmovd          m5, [r2 + 64]
    vmovd          m1, [r2 + 96]
    vmovd          [r2 + 64], m2
    vmovd          [r2 + 96], m3
    vpunpckldq     m2, m2, m3
    vpunpckldq     m5, m5, m1
    vpunpcklqdq    m0, m0, m2
    vpunpcklqdq    m4, m4, m5

    vmovdqu        m3, [sub_4x4_shuf]
    vpshufb        m0, m0, m3
    vpshufb        m1, m4, m3
    vpxor          m5, m5, m5
    vpunpcklbw     m2, m0, m5
    vpunpcklbw     m3, m1, m5
    vpsubw         m2, m2, m3
    vmovdqu        [r0], m2
    vpunpckhbw     m3, m0, m5
    vpunpckhbw     m4, m1, m5
    vpsubw         m3, m3, m4
    vmovdqu        [r0 + 16], m3
    vpor           m0, m2, m3
    vpcmpeqq       m0, m0, m5
    vpmovmskb      eax, m0
    sub            eax, 0FFFFh
    shr            eax, 31
    ret

;  0  1  5  6 14 15 27 28
;  2  4  7 13 16 26 29 42
;  3  8 12 17 25 30 41 43
;  9 11 18 24 31 40 44 53
; 10 19 23 32 39 45 52 54
; 20 22 33 38 46 51 55 60
; 21 34 37 47 50 56 59 61
; 35 36 48 49 57 58 62 63
INIT_XMM avx2
cglobal zigzag_sub_8x8_frame, 0, 0
%if WIN64
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
    add            r2, 128
    vmovq          m0, [r1]
    vmovhps        m0, m0, [r1 + 16]
    vmovq          m1, [r1 + 32]
    vmovhps        m1, m1, [r1 + 48]
    vmovq          m2, [r1 + 64]
    vmovhps        m2, m2, [r1 + 80]
    vmovq          m3, [r1 + 96]
    vmovhps        m3, m3, [r1 + 112]
    vmovq          m4, [r2 - 128]
    vmovhps        m4, m4, [r2 - 96]
    vmovq          m5, [r2 - 64]
    vmovhps        m5, m5, [r2 - 32]
    vmovq          m6, [r2]
    vmovhps        m6, m6, [r2 + 32]
    vmovq          m7, [r2 + 64]
    vmovhps        m7, m7, [r2 + 96]

; 0 - 15
    vmovddup       m12, [hsub_mul]
    vmovdqu        m8, [sub_8x8_shuf1_1]
    vpshufb        m9, m0, m8
    vpshufb        m10, m4, m8
    vmovdqu        m8, [sub_8x8_shuf1_2]
    vpshufb        m11, m1, m8
    vpor           m9, m9, m11
    vpshufb        m11, m5, m8
    vpor           m10, m10, m11
    vmovdqu        m8, [sub_8x8_shuf1_3]
    vpshufb        m11, m2, m8
    vpor           m9, m9, m11
    vpshufb        m11, m6, m8
    vpor           m10, m10, m11
    vpunpcklbw     m11, m9, m10
    vpunpckhbw     m9, m9, m10
    vpmaddubsw     m11, m11, m12
    vpmaddubsw     m9, m9, m12
    vmovdqu        [r0], m11
    vmovdqu        [r0 + 16], m9
    vpor           m13, m11, m9

; 16 - 31
    vmovdqu        m8, [sub_8x8_shuf2_1]
    vpshufb        m9, m0, m8
    vpshufb        m10, m4, m8
    vmovdqu        m8, [sub_8x8_shuf2_2]
    vpshufb        m11, m1, m8
    vpor           m9, m9, m11
    vpshufb        m11, m5, m8
    vpor           m10, m10, m11
    vmovdqu        m8, [sub_8x8_shuf2_3]
    vpshufb        m11, m2, m8
    vpor           m9, m9, m11
    vpshufb        m11, m6, m8
    vpor           m10, m10, m11
    vmovdqu        m8, [sub_8x8_shuf2_4]
    vpshufb        m11, m3, m8
    vpor           m9, m9, m11
    vpshufb        m11, m7, m8
    vpor           m10, m10, m11
    vpunpcklbw     m11, m9, m10
    vpunpckhbw     m9, m9, m10
    vpmaddubsw     m11, m11, m12
    vpmaddubsw     m9, m9, m12
    vmovdqu        [r0 + 32], m11
    vmovdqu        [r0 + 48], m9
    vpor           m13, m13, m11
    vpor           m13, m13, m9

; 32 - 47
    vmovdqu        m8, [sub_8x8_shuf3_1]
    vpshufb        m9, m0, m8
    vpshufb        m10, m4, m8
    vmovdqu        m8, [sub_8x8_shuf3_2]
    vpshufb        m11, m1, m8
    vpor           m9, m9, m11
    vpshufb        m11, m5, m8
    vpor           m10, m10, m11
    vmovdqu        m8, [sub_8x8_shuf3_3]
    vpshufb        m11, m2, m8
    vpor           m9, m9, m11
    vpshufb        m11, m6, m8
    vpor           m10, m10, m11
    vmovdqu        m8, [sub_8x8_shuf3_4]
    vpshufb        m11, m3, m8
    vpor           m9, m9, m11
    vpshufb        m11, m7, m8
    vpor           m10, m10, m11
    vpunpcklbw     m11, m9, m10
    vpunpckhbw     m9, m9, m10
    vpmaddubsw     m11, m11, m12
    vpmaddubsw     m9, m9, m12
    vmovdqu        [r0 + 64], m11
    vmovdqu        [r0 + 80], m9
    vpor           m13, m13, m11
    vpor           m13, m13, m9

; 48 - 63
    vmovdqu        m8, [sub_8x8_shuf4_2]
    vpshufb        m9, m1, m8
    vpshufb        m10, m5, m8
    vmovdqu        m8, [sub_8x8_shuf4_3]
    vpshufb        m11, m2, m8
    vpor           m9, m9, m11
    vpshufb        m11, m6, m8
    vpor           m10, m10, m11
    vmovdqu        m8, [sub_8x8_shuf4_4]
    vpshufb        m11, m3, m8
    vpor           m9, m9, m11
    vpshufb        m11, m7, m8
    vpor           m10, m10, m11
    vpunpcklbw     m11, m9, m10
    vpunpckhbw     m9, m9, m10
    vpmaddubsw     m11, m11, m12
    vpmaddubsw     m9, m9, m12
    vmovdqu        [r0 + 96], m11
    vmovdqu        [r0 + 112], m9
    vpor           m13, m13, m11
    vpor           m13, m13, m9

; copy
    vmovq          [r2 - 128], m0
    vmovhps        [r2 - 96], m0
    vmovq          [r2 - 64], m1
    vmovhps        [r2 - 32], m1
    vmovq          [r2], m2
    vmovhps        [r2 + 32], m2
    vmovq          [r2 + 64], m3
    vmovhps        [r2 + 96], m3

; nnz
    vpxor          m0, m0, m0
    vpcmpeqq       m0, m13, m0
    vpmovmskb      eax, m0
    sub            eax, 0FFFFh
    shr            eax, 31

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
; SUB_AC
;=============================================================================
; 0  1  5  6 
; 2  4  7 12 
; 3  8 11 13 
; 9 10 14 15 
INIT_XMM avx2
cglobal zigzag_sub_4x4ac_frame, 0, 0
    vmovd          m0, [r1]
    vmovd          m1, [r1 + 16]
    vmovd          m2, [r1 + 32]
    vmovd          m3, [r1 + 48]
    vmovd          m4, [r2]
    vmovd          m5, [r2 + 32]
    vmovd          [r2], m0
    vmovd          [r2 + 32], m1
    vpunpckldq     m0, m0, m1
    vpunpckldq     m4, m4, m5
    vmovd          m5, [r2 + 64]
    vmovd          m1, [r2 + 96]
    vmovd          [r2 + 64], m2
    vmovd          [r2 + 96], m3
    vpunpckldq     m2, m2, m3
    vpunpckldq     m5, m5, m1
    vpunpcklqdq    m0, m0, m2
    vpunpcklqdq    m4, m4, m5

    vmovdqu        m3, [sub_4x4_shuf]
    vpshufb        m0, m0, m3
    vpshufb        m1, m4, m3
    vpxor          m5, m5, m5
    vpunpcklbw     m2, m0, m5
    vpunpcklbw     m3, m1, m5
    vpsubw         m2, m2, m3
    vmovdqu        [r0], m2
    vmovd          eax, m2
    vpunpckhbw     m3, m0, m5
    vpunpckhbw     m4, m1, m5
    vpsubw         m3, m3, m4
    vmovdqu        [r0 + 16], m3
    mov            [r3], ax
    vpor           m0, m2, m3
    vpcmpeqq       m0, m0, m5
    xor            eax, eax
    mov            [r0], ax
    vpmovmskb      eax, m0
    sub            eax, 0FFFFh
    shr            eax, 31
    ret
