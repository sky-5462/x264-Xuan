;*****************************************************************************
;* pixel.asm: x86 pixel metrics
;*****************************************************************************
;* Copyright (C) 2003-2019 x264 project
;*
;* Authors: Loren Merritt <lorenm@u.washington.edu>
;*          Holger Lubitz <holger@lubitz.org>
;*          Laurent Aimar <fenrir@via.ecp.fr>
;*          Alex Izvorski <aizvorksi@gmail.com>
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
hmul_16p:  times 16 db 1
           times 8 db 1, -1
hmul_8p:   times 8 db 1
           times 4 db 1, -1
           times 8 db 1
           times 4 db 1, -1
mask_ff:   times 16 db 0xff
           times 16 db 0
mask_ac4:  times 2 dw 0, -1, -1, -1, 0, -1, -1, -1
mask_ac4b: times 2 dw 0, -1, 0, -1, -1, -1, -1, -1
mask_ac8:  times 2 dw 0, -1, -1, -1, -1, -1, -1, -1
ssim_c1:   times 4 dd 416          ; .01*.01*255*255*64
ssim_c2:   times 4 dd 235963       ; .03*.03*255*255*64*63
hmul_4p:   times 4 db 1, 1, 1, 1, 1, -1, 1, -1
mask_10:   times 4 dw 0, -1
pb_pppm:   times 4 db 1,1,1,-1
intrax3_shuf: db 7,6,7,6,5,4,5,4,3,2,3,2,1,0,1,0

ALIGN 32
intrax9a_ddlr1: db  6, 7, 8, 9, 7, 8, 9,10, 4, 5, 6, 7, 3, 4, 5, 6
intrax9a_ddlr2: db  8, 9,10,11, 9,10,11,12, 2, 3, 4, 5, 1, 2, 3, 4
intrax9a_hdu1:  db 15, 4, 5, 6,14, 3,15, 4,14, 2,13, 1,13, 1,12, 0
intrax9a_hdu2:  db 13, 2,14, 3,12, 1,13, 2,12, 0,11,11,11,11,11,11
intrax9a_vrl1:  db 10,11,12,13, 3, 4, 5, 6,11,12,13,14, 5, 6, 7, 8
intrax9a_vrl2:  db  2,10,11,12, 1, 3, 4, 5,12,13,14,15, 6, 7, 8, 9
intrax9a_vh1:   db  6, 7, 8, 9, 6, 7, 8, 9, 4, 4, 4, 4, 3, 3, 3, 3
intrax9a_vh2:   db  6, 7, 8, 9, 6, 7, 8, 9, 2, 2, 2, 2, 1, 1, 1, 1
intrax9a_dc:    db  1, 2, 3, 4, 6, 7, 8, 9,-1,-1,-1,-1,-1,-1,-1,-1
intrax9a_lut:   db 0x60,0x68,0x80,0x00,0x08,0x20,0x40,0x28,0x48,0,0,0,0,0,0,0
pw_s01234567:   dw 0x8000,0x8001,0x8002,0x8003,0x8004,0x8005,0x8006,0x8007
pw_s01234657:   dw 0x8000,0x8001,0x8002,0x8003,0x8004,0x8006,0x8005,0x8007
intrax9_edge:   db  0, 0, 1, 2, 3, 7, 8, 9,10,11,12,13,14,15,15,15

intrax9b_ddlr1: db  6, 7, 8, 9, 4, 5, 6, 7, 7, 8, 9,10, 3, 4, 5, 6
intrax9b_ddlr2: db  8, 9,10,11, 2, 3, 4, 5, 9,10,11,12, 1, 2, 3, 4
intrax9b_hdu1:  db 15, 4, 5, 6,14, 2,13, 1,14, 3,15, 4,13, 1,12, 0
intrax9b_hdu2:  db 13, 2,14, 3,12, 0,11,11,12, 1,13, 2,11,11,11,11
intrax9b_vrl1:  db 10,11,12,13,11,12,13,14, 3, 4, 5, 6, 5, 6, 7, 8
intrax9b_vrl2:  db  2,10,11,12,12,13,14,15, 1, 3, 4, 5, 6, 7, 8, 9
intrax9b_vh1:   db  6, 7, 8, 9, 4, 4, 4, 4, 6, 7, 8, 9, 3, 3, 3, 3
intrax9b_vh2:   db  6, 7, 8, 9, 2, 2, 2, 2, 6, 7, 8, 9, 1, 1, 1, 1
intrax9b_edge2: db  6, 7, 8, 9, 6, 7, 8, 9, 4, 3, 2, 1, 4, 3, 2, 1
intrax9b_v1:    db  0, 1,-1,-1,-1,-1,-1,-1, 4, 5,-1,-1,-1,-1,-1,-1
intrax9b_v2:    db  2, 3,-1,-1,-1,-1,-1,-1, 6, 7,-1,-1,-1,-1,-1,-1
intrax9b_lut:   db 0x60,0x64,0x80,0x00,0x04,0x20,0x40,0x24,0x44,0,0,0,0,0,0,0

ALIGN 32
intra8x9_h1:   db  7, 7, 7, 7, 7, 7, 7, 7, 5, 5, 5, 5, 5, 5, 5, 5
intra8x9_h2:   db  6, 6, 6, 6, 6, 6, 6, 6, 4, 4, 4, 4, 4, 4, 4, 4
intra8x9_h3:   db  3, 3, 3, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1
intra8x9_h4:   db  2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0
intra8x9_ddl1: db  1, 2, 3, 4, 5, 6, 7, 8, 3, 4, 5, 6, 7, 8, 9,10
intra8x9_ddl2: db  2, 3, 4, 5, 6, 7, 8, 9, 4, 5, 6, 7, 8, 9,10,11
intra8x9_ddl3: db  5, 6, 7, 8, 9,10,11,12, 7, 8, 9,10,11,12,13,14
intra8x9_ddl4: db  6, 7, 8, 9,10,11,12,13, 8, 9,10,11,12,13,14,15
intra8x9_vl1:  db  0, 1, 2, 3, 4, 5, 6, 7, 1, 2, 3, 4, 5, 6, 7, 8
intra8x9_vl2:  db  1, 2, 3, 4, 5, 6, 7, 8, 2, 3, 4, 5, 6, 7, 8, 9
intra8x9_vl3:  db  2, 3, 4, 5, 6, 7, 8, 9, 3, 4, 5, 6, 7, 8, 9,10
intra8x9_vl4:  db  3, 4, 5, 6, 7, 8, 9,10, 4, 5, 6, 7, 8, 9,10,11
intra8x9_ddr1: db  8, 9,10,11,12,13,14,15, 6, 7, 8, 9,10,11,12,13
intra8x9_ddr2: db  7, 8, 9,10,11,12,13,14, 5, 6, 7, 8, 9,10,11,12
intra8x9_ddr3: db  4, 5, 6, 7, 8, 9,10,11, 2, 3, 4, 5, 6, 7, 8, 9
intra8x9_ddr4: db  3, 4, 5, 6, 7, 8, 9,10, 1, 2, 3, 4, 5, 6, 7, 8
intra8x9_vr1:  db  8, 9,10,11,12,13,14,15, 7, 8, 9,10,11,12,13,14
intra8x9_vr2:  db  8, 9,10,11,12,13,14,15, 6, 8, 9,10,11,12,13,14
intra8x9_vr3:  db  5, 7, 8, 9,10,11,12,13, 3, 5, 7, 8, 9,10,11,12
intra8x9_vr4:  db  4, 6, 8, 9,10,11,12,13, 2, 4, 6, 8, 9,10,11,12
intra8x9_hd1:  db  3, 8, 9,10,11,12,13,14, 1, 6, 2, 7, 3, 8, 9,10
intra8x9_hd2:  db  2, 7, 3, 8, 9,10,11,12, 0, 5, 1, 6, 2, 7, 3, 8
intra8x9_hd3:  db  7, 8, 9,10,11,12,13,14, 3, 4, 5, 6, 7, 8, 9,10
intra8x9_hd4:  db  5, 6, 7, 8, 9,10,11,12, 1, 2, 3, 4, 5, 6, 7, 8
intra8x9_hu1:  db 13,12,11,10, 9, 8, 7, 6, 9, 8, 7, 6, 5, 4, 3, 2
intra8x9_hu2:  db 11,10, 9, 8, 7, 6, 5, 4, 7, 6, 5, 4, 3, 2, 1, 0
intra8x9_hu3:  db  5, 4, 3, 2, 1, 0,15,15, 1, 0,15,15,15,15,15,15
intra8x9_hu4:  db  3, 2, 1, 0,15,15,15,15,15,15,15,15,15,15,15,15
pw_s00112233:  dw 0x8000,0x8000,0x8001,0x8001,0x8002,0x8002,0x8003,0x8003
pw_s00001111:  dw 0x8000,0x8000,0x8000,0x8000,0x8001,0x8001,0x8001,0x8001

ALIGN 32
sw_f0:     dq 0xfff0, 0
pd_f0:     times 4 dd 0xffff0000
pd_2:      times 4 dd 2

pw_76543210: dw 0, 1, 2, 3, 4, 5, 6, 7

ads_mvs_shuffle:
%macro ADS_MVS_SHUFFLE 8
    %assign y x
    %rep 8
        %rep 7
            %rotate (~y)&1
            %assign y y>>((~y)&1)
        %endrep
        db %1*2, %1*2+1
        %rotate 1
        %assign y y>>1
    %endrep
%endmacro
%assign x 0
%rep 256
    ADS_MVS_SHUFFLE 0, 1, 2, 3, 4, 5, 6, 7
%assign x x+1
%endrep


ALIGN 32
intra_sa8d_8x8_shuf_h:      times 16 db 7
                            times 16 db 3
intra_satd_4x4_shuf:        times 8 db 0
                            times 8 db 1
intra_satd_8x8c_shuf_dc:    times 4 db 0
                            times 4 db 8
                            times 4 db 0
                            times 4 db 8

SECTION .text

cextern pb_0
cextern pb_1
cextern pw_1
cextern pw_8
cextern pw_16
cextern pw_32
cextern pw_00ff
cextern pw_ppppmmmm
cextern pw_ppmmppmm
cextern pw_pmpmpmpm
cextern pw_pmmpzzzz
cextern hsub_mul
cextern popcnt_table

;=============================================================================
; SSD
;=============================================================================
INIT_XMM avx2
cglobal pixel_ssd_4x4, 4, 4
    vmovdqu        m5, [hsub_mul]
    vmovd          m0, [r0]
    vmovd          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r1]
    vmovd          m3, [r2 + r3]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m4, m0, m0
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r6]
    vmovd          m3, [r2 + r4]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0

    vpunpckhqdq    m0, m4, m4
    vpaddd         m0, m0, m4
    vpshufd        m1, m0, 1
    vpaddd         m0, m0, m1
    vmovd          eax, m0
    ret

INIT_XMM avx2
cglobal pixel_ssd_4x8, 4, 4
    vmovdqu        m5, [hsub_mul]
    vmovd          m0, [r0]
    vmovd          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r1]
    vmovd          m3, [r2 + r3]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m4, m0, m0
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r6]
    vmovd          m3, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0

    vmovd          m0, [r0]
    vmovd          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r1]
    vmovd          m3, [r2 + r3]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r6]
    vmovd          m3, [r2 + r4]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0

    vpunpckhqdq    m0, m4, m4
    vpaddd         m0, m0, m4
    vpshufd        m1, m0, 1
    vpaddd         m0, m0, m1
    vmovd          eax, m0
    ret

INIT_XMM avx2
cglobal pixel_ssd_4x16, 4, 4
    vmovdqu        m5, [hsub_mul]
    vmovd          m0, [r0]
    vmovd          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r1]
    vmovd          m3, [r2 + r3]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m4, m0, m0
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r6]
    vmovd          m3, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0

    vmovd          m0, [r0]
    vmovd          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r1]
    vmovd          m3, [r2 + r3]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r6]
    vmovd          m3, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0

    vmovd          m0, [r0]
    vmovd          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r1]
    vmovd          m3, [r2 + r3]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r6]
    vmovd          m3, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0

    vmovd          m0, [r0]
    vmovd          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r1]
    vmovd          m3, [r2 + r3]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r6]
    vmovd          m3, [r2 + r4]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0

    vpunpckhqdq    m0, m4, m4
    vpaddd         m0, m0, m4
    vpshufd        m1, m0, 1
    vpaddd         m0, m0, m1
    vmovd          eax, m0
    ret

INIT_XMM avx2
cglobal pixel_ssd_8x4, 4, 4
    vmovdqu        m5, [hsub_mul]
    vmovq          m0, [r0]
    vmovq          m1, [r2]
    vpunpcklbw     m0, m0, m1
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m2, m0, m0
    vmovq          m0, [r0 + r1]
    vmovq          m1, [r2 + r3]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1 * 2]
    vmovq          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r6]
    vmovq          m1, [r2 + r4]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3

    vpunpckhqdq    m0, m2, m2
    vpaddd         m0, m0, m2
    vpshufd        m1, m0, 1
    vpaddd         m0, m0, m1
    vmovd          eax, m0
    ret

INIT_XMM avx2
cglobal pixel_ssd_8x8, 4, 4
    vmovdqu        m5, [hsub_mul]
    vmovq          m0, [r0]
    vmovq          m1, [r2]
    vpunpcklbw     m0, m0, m1
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m2, m0, m0
    vmovq          m0, [r0 + r1]
    vmovq          m1, [r2 + r3]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1 * 2]
    vmovq          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r6]
    vmovq          m1, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3

    vmovq          m0, [r0]
    vmovq          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1]
    vmovq          m1, [r2 + r3]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1 * 2]
    vmovq          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r6]
    vmovq          m1, [r2 + r4]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3

    vpunpckhqdq    m0, m2, m2
    vpaddd         m0, m0, m2
    vpshufd        m1, m0, 1
    vpaddd         m0, m0, m1
    vmovd          eax, m0
    ret

INIT_XMM avx2
cglobal pixel_ssd_8x16, 4, 4
    vmovdqu        m5, [hsub_mul]
    vmovq          m0, [r0]
    vmovq          m1, [r2]
    vpunpcklbw     m0, m0, m1
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m2, m0, m0
    vmovq          m0, [r0 + r1]
    vmovq          m1, [r2 + r3]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1 * 2]
    vmovq          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r6]
    vmovq          m1, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3

    vmovq          m0, [r0]
    vmovq          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1]
    vmovq          m1, [r2 + r3]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1 * 2]
    vmovq          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r6]
    vmovq          m1, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3

    vmovq          m0, [r0]
    vmovq          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1]
    vmovq          m1, [r2 + r3]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1 * 2]
    vmovq          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r6]
    vmovq          m1, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3

    vmovq          m0, [r0]
    vmovq          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1]
    vmovq          m1, [r2 + r3]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1 * 2]
    vmovq          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r6]
    vmovq          m1, [r2 + r4]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3

    vpunpckhqdq    m0, m2, m2
    vpaddd         m0, m0, m2
    vpshufd        m1, m0, 1
    vpaddd         m0, m0, m1
    vmovd          eax, m0
    ret

INIT_YMM avx2
cglobal pixel_ssd_16x8, 4, 4
    vmovdqu        m5, [hsub_mul]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r2]
    vinserti128    m1, m1, [r2 + r3], 1
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m2, m3
    vmovdqu        xm0, [r0 + r1 * 2]
    vinserti128    m0, m0, [r0 + r6], 1
    vmovdqu        xm1, [r2 + r3 * 2]
    vinserti128    m1, m1, [r2 + r4], 1
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3

    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r2]
    vinserti128    m1, m1, [r2 + r3], 1
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3
    vmovdqu        xm0, [r0 + r1 * 2]
    vinserti128    m0, m0, [r0 + r6], 1
    vmovdqu        xm1, [r2 + r3 * 2]
    vinserti128    m1, m1, [r2 + r4], 1
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3

    vextracti128   xm0, m4, 1
    vpaddd         xm0, xm0, xm4
    vpunpckhqdq    xm1, xm0, xm0
    vpaddd         xm0, xm0, xm1
    vpshufd        xm1, xm0, 1
    vpaddd         xm0, xm0, xm1
    vmovd          eax, xm0
    RET

INIT_YMM avx2
cglobal pixel_ssd_16x16, 4, 4
    vmovdqu        m5, [hsub_mul]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r2]
    vinserti128    m1, m1, [r2 + r3], 1
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m2, m3
    vmovdqu        xm0, [r0 + r1 * 2]
    vinserti128    m0, m0, [r0 + r6], 1
    vmovdqu        xm1, [r2 + r3 * 2]
    vinserti128    m1, m1, [r2 + r4], 1
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3

    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r2]
    vinserti128    m1, m1, [r2 + r3], 1
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3
    vmovdqu        xm0, [r0 + r1 * 2]
    vinserti128    m0, m0, [r0 + r6], 1
    vmovdqu        xm1, [r2 + r3 * 2]
    vinserti128    m1, m1, [r2 + r4], 1
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3

    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r2]
    vinserti128    m1, m1, [r2 + r3], 1
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3
    vmovdqu        xm0, [r0 + r1 * 2]
    vinserti128    m0, m0, [r0 + r6], 1
    vmovdqu        xm1, [r2 + r3 * 2]
    vinserti128    m1, m1, [r2 + r4], 1
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3

    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r2]
    vinserti128    m1, m1, [r2 + r3], 1
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3
    vmovdqu        xm0, [r0 + r1 * 2]
    vinserti128    m0, m0, [r0 + r6], 1
    vmovdqu        xm1, [r2 + r3 * 2]
    vinserti128    m1, m1, [r2 + r4], 1
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3

    vextracti128   xm0, m4, 1
    vpaddd         xm0, xm0, xm4
    vpunpckhqdq    xm1, xm0, xm0
    vpaddd         xm0, xm0, xm1
    vpshufd        xm1, xm0, 1
    vpaddd         xm0, xm0, xm1
    vmovd          eax, xm0
    RET



;=============================================================================
; SSD_NV12_CORE
;=============================================================================
;-----------------------------------------------------------------------------
; void pixel_ssd_nv12_core( uint8_t *pixuv1, intptr_t stride1, uint8_t *pixuv2, intptr_t stride2,
;                           int width, int height, uint64_t *ssd_u, uint64_t *ssd_v )
;
; This implementation can potentially overflow on image widths >= 11008 (or
; 6604 if interlaced), since it is called on blocks of height up to 12 (resp
; 20). At sane distortion levels it will take much more than that though.
;-----------------------------------------------------------------------------
INIT_YMM avx2
cglobal pixel_ssd_nv12_core
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5, [rsp + 48]
%endif
    add            r4d, r4d
    add            r0, r4
    add            r2, r4
    neg            r4
    vpxor          m3, m3, m3
    vpxor          m4, m4, m4
    vmovdqu        m5, [pw_00ff]

.loopy:
    mov            r6, r4
.loopx:
    vmovdqu        m2, [r0 + r6]
    vmovdqu        m1, [r2 + r6]
    vpsubusb       m0, m2, m1
    vpsubusb       m1, m1, m2
    vpor           m0, m0, m1
    vpsrlw         m2, m0, 8
    vpand          m0, m0, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m2
    vpaddd         m3, m3, m0
    add            r6, 32
    jl             .loopx
    je             .no_overread
    vpcmpeqb       xm1, xm1, xm1
    vpandn         m0, m1, m0
    vpandn         m2, m1, m2
    vpsubd         m3, m3, m0
    vpsubd         m4, m4, m2
.no_overread:
    add            r0, r1
    add            r2, r3
    sub            r5d, 1
    jg             .loopy
%if WIN64
    mov            r0, [rsp + 56]
    mov            r1, [rsp + 64]
%else
    mov            r0, [rsp + 8]
    mov            r1, [rsp + 16]
%endif
    vphaddd        m3, m3, m4
    vextracti128   xm4, m3, 1
    vpaddd         xm3, xm3, xm4
    vpsllq         xm4, xm3, 32
    vpaddd         xm3, xm3, xm4
    vpsrlq         xm3, xm3, 32
    vmovq          [r0], xm3
    vmovhps        [r1], xm3
    RET

;=============================================================================
; VAR
;=============================================================================
INIT_YMM avx2
cglobal pixel_var_8x8, 4, 4
    lea            r6d, [r1 + r1 * 2]
    vpxor          m5, m5, m5

    vmovq          xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovq          xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    lea            r0, [r0 + r1 * 4]
    vpunpcklbw     m0, m0, m5
    vpunpcklbw     m1, m1, m5
    vpaddw         m3, m0, m1
    vpmaddwd       m0, m0, m0
    vpmaddwd       m1, m1, m1
    vpaddd         m4, m0, m1
    vmovq          xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovq          xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    vpunpcklbw     m0, m0, m5
    vpunpcklbw     m1, m1, m5
    vpaddw         m3, m3, m0
    vpaddw         m3, m3, m1
    vpmaddwd       m3, m3, [pw_1]
    vpmaddwd       m0, m0, m0
    vpmaddwd       m1, m1, m1
    vpaddd         m4, m4, m0
    vpaddd         m4, m4, m1

    vphaddd        m0, m3, m4
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovq          rax, xm0
    RET

INIT_YMM avx2
cglobal pixel_var_8x16, 4, 4
    lea            r6d, [r1 + r1 * 2]
    vpxor          m5, m5, m5

    vmovq          xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovq          xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    lea            r0, [r0 + r1 * 4]
    vpunpcklbw     m0, m0, m5
    vpunpcklbw     m1, m1, m5
    vpaddw         m3, m0, m1
    vpmaddwd       m0, m0, m0
    vpmaddwd       m1, m1, m1
    vpaddd         m4, m0, m1
    vmovq          xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovq          xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    lea            r0, [r0 + r1 * 4]
    vpunpcklbw     m0, m0, m5
    vpunpcklbw     m1, m1, m5
    vpaddw         m3, m3, m0
    vpaddw         m3, m3, m1
    vpmaddwd       m0, m0, m0
    vpmaddwd       m1, m1, m1
    vpaddd         m4, m4, m0
    vpaddd         m4, m4, m1

    vmovq          xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovq          xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    lea            r0, [r0 + r1 * 4]
    vpunpcklbw     m0, m0, m5
    vpunpcklbw     m1, m1, m5
    vpaddw         m3, m3, m0
    vpaddw         m3, m3, m1
    vpmaddwd       m0, m0, m0
    vpmaddwd       m1, m1, m1
    vpaddd         m4, m4, m0
    vpaddd         m4, m4, m1
    vmovq          xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovq          xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    vpunpcklbw     m0, m0, m5
    vpunpcklbw     m1, m1, m5
    vpaddw         m3, m3, m0
    vpaddw         m3, m3, m1
    vpmaddwd       m3, m3, [pw_1]
    vpmaddwd       m0, m0, m0
    vpmaddwd       m1, m1, m1
    vpaddd         m4, m4, m0
    vpaddd         m4, m4, m1

    vphaddd        m0, m3, m4
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovq          rax, xm0
    RET

INIT_YMM avx2
cglobal pixel_var_16x16, 4, 4
%if WIN64
    vmovdqu        [rsp + 8], xm6
%endif
    lea            r6d, [r1 + r1 * 2]
    vmovdqu        m6, [pw_00ff]

    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    lea            r0, [r0 + r1 * 4]
    vpand          m2, m0, m6
    vpand          m3, m1, m6
    vpsrlw         m0, m0, 8
    vpsrlw         m1, m1, 8
    vpaddw         m4, m2, m3
    vpaddw         m4, m4, m0
    vpaddw         m4, m4, m1
    vpmaddwd       m2, m2, m2
    vpmaddwd       m0, m0, m0
    vpmaddwd       m3, m3, m3
    vpmaddwd       m1, m1, m1
    vpaddd         m5, m2, m0
    vpaddd         m5, m5, m3
    vpaddd         m5, m5, m1
    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    lea            r0, [r0 + r1 * 4]
    vpand          m2, m0, m6
    vpand          m3, m1, m6
    vpsrlw         m0, m0, 8
    vpsrlw         m1, m1, 8
    vpaddw         m4, m4, m2
    vpaddw         m4, m4, m3
    vpaddw         m4, m4, m0
    vpaddw         m4, m4, m1
    vpmaddwd       m2, m2, m2
    vpmaddwd       m0, m0, m0
    vpmaddwd       m3, m3, m3
    vpmaddwd       m1, m1, m1
    vpaddd         m5, m5, m2
    vpaddd         m5, m5, m0
    vpaddd         m5, m5, m3
    vpaddd         m5, m5, m1

    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    lea            r0, [r0 + r1 * 4]
    vpand          m2, m0, m6
    vpand          m3, m1, m6
    vpsrlw         m0, m0, 8
    vpsrlw         m1, m1, 8
    vpaddw         m4, m4, m2
    vpaddw         m4, m4, m3
    vpaddw         m4, m4, m0
    vpaddw         m4, m4, m1
    vpmaddwd       m2, m2, m2
    vpmaddwd       m0, m0, m0
    vpmaddwd       m3, m3, m3
    vpmaddwd       m1, m1, m1
    vpaddd         m5, m5, m2
    vpaddd         m5, m5, m0
    vpaddd         m5, m5, m3
    vpaddd         m5, m5, m1
    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    vpand          m2, m0, m6
    vpand          m3, m1, m6
    vpsrlw         m0, m0, 8
    vpsrlw         m1, m1, 8
    vpaddw         m4, m4, m2
    vpaddw         m4, m4, m3
    vpaddw         m4, m4, m0
    vpaddw         m4, m4, m1
    vpmaddwd       m4, m4, [pw_1]
    vpmaddwd       m2, m2, m2
    vpmaddwd       m0, m0, m0
    vpmaddwd       m3, m3, m3
    vpmaddwd       m1, m1, m1
    vpaddd         m5, m5, m2
    vpaddd         m5, m5, m0
    vpaddd         m5, m5, m3
    vpaddd         m5, m5, m1

%if WIN64
    vmovdqu        xm6, [rsp + 8]
%endif
    vphaddd        m0, m4, m5
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovq          rax, xm0
    RET

;=============================================================================
; VAR2
;=============================================================================
INIT_YMM avx2
cglobal pixel_var2_8x8, 4, 4
    vpxor          m5, m5, m5

    vpmovzxbw      m0, [r0]
    vmovdqu        m1, [r1]
    vpunpcklbw     m1, m1, m5
    vpsubw         m2, m0, m1
    vpmaddwd       m3, m2, m2
    vpmovzxbw      m0, [r0 + 16]
    vmovdqu        m1, [r1 + 32]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 32]
    vmovdqu        m1, [r1 + 64]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 48]
    vmovdqu        m1, [r1 + 96]
    add            r1, 128
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1

    vpmovzxbw      m0, [r0 + 64]
    vmovdqu        m1, [r1]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 80]
    vmovdqu        m1, [r1 + 32]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 96]
    vmovdqu        m1, [r1 + 64]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 112]
    vmovdqu        m1, [r1 + 96]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1

    vpmaddwd       m2, [pw_1]
    vpunpckhqdq    m0, m2, m2
    vpunpckhqdq    m1, m3, m3
    vpaddd         m0, m0, m2
    vpaddd         m1, m1, m3
    vpsrlq         m2, m0, 32
    vpsrlq         m3, m1, 32
    vpaddd         m0, m0, m2
    vpaddd         m1, m1, m3
    vpmaddwd       m0, m0, m0
    vextracti128   xm2, m1, 1
    vpunpckldq     xm2, xm1, xm2
    vmovq          [r2], xm2
    vpsrld         m0, m0, 6
    vpsubd         m0, m1, m0
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovd          eax, xm0
    RET

INIT_YMM avx2
cglobal pixel_var2_8x16, 4, 4
    vpxor          m5, m5, m5

    vpmovzxbw      m0, [r0]
    vmovdqu        m1, [r1]
    vpunpcklbw     m1, m1, m5
    vpsubw         m2, m0, m1
    vpmaddwd       m3, m2, m2
    vpmovzxbw      m0, [r0 + 16]
    vmovdqu        m1, [r1 + 32]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 32]
    vmovdqu        m1, [r1 + 64]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 48]
    vmovdqu        m1, [r1 + 96]
    add            r1, 128
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1

    vpmovzxbw      m0, [r0 + 64]
    vmovdqu        m1, [r1]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 80]
    vmovdqu        m1, [r1 + 32]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 96]
    vmovdqu        m1, [r1 + 64]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 112]
    vmovdqu        m1, [r1 + 96]
    add            r0, 128
    add            r1, 128
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1

    vpmovzxbw      m0, [r0]
    vmovdqu        m1, [r1]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 16]
    vmovdqu        m1, [r1 + 32]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 32]
    vmovdqu        m1, [r1 + 64]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 48]
    vmovdqu        m1, [r1 + 96]
    add            r1, 128
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1

    vpmovzxbw      m0, [r0 + 64]
    vmovdqu        m1, [r1]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 80]
    vmovdqu        m1, [r1 + 32]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 96]
    vmovdqu        m1, [r1 + 64]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 112]
    vmovdqu        m1, [r1 + 96]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1

    vpmaddwd       m2, [pw_1]
    vpunpckhqdq    m0, m2, m2
    vpunpckhqdq    m1, m3, m3
    vpaddd         m0, m0, m2
    vpaddd         m1, m1, m3
    vpsrlq         m2, m0, 32
    vpsrlq         m3, m1, 32
    vpaddd         m0, m0, m2
    vpaddd         m1, m1, m3
    vpmaddwd       m0, m0, m0
    vextracti128   xm2, m1, 1
    vpunpckldq     xm2, xm1, xm2
    vmovq          [r2], xm2
    vpsrld         m0, m0, 7
    vpsubd         m0, m1, m0
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovd          eax, xm0
    RET


;=============================================================================
; SATD
;=============================================================================
INIT_XMM avx2
cglobal pixel_satd_4x4, 4, 4
    vmovdqu        m5, [hmul_4p]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vmovd          m0, [r0]
    vmovd          m1, [r0 + r1]
    vshufps        m0, m0, m1, 0
    vpmaddubsw     m0, m0, m5
    vmovd          m1, [r0 + r1 * 2]
    vmovd          m2, [r0 + r6]
    vshufps        m1, m1, m2, 0
    vpmaddubsw     m1, m1, m5
    vmovd          m2, [r2]
    vmovd          m3, [r2 + r3]
    vshufps        m2, m2, m3, 0
    vpmaddubsw     m2, m2, m5
    vpsubw         m0, m0, m2
    vmovd          m3, [r2 + r3 * 2]
    vmovd          m4, [r2 + r4]
    vshufps        m3, m3, m4, 0
    vpmaddubsw     m3, m3, m5
    vpsubw         m1, m1, m3

    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpunpcklqdq    m0, m2, m3
    vpunpckhqdq    m1, m2, m3
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpblendw       m0, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m1, m2, m3
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpmaxsw        m0, m0, m1
    vpmaddwd       m0, m0, [pw_1]

    vpunpckhqdq    m1, m0, m0
    vpaddd         m0, m0, m1
    vpshufd        m1, m0, 1
    vpaddd         m0, m0, m1
    vmovd          eax, m0
    ret

INIT_YMM avx2
cglobal pixel_satd_4x8, 4, 4
    vmovdqu        m5, [hmul_4p]
    lea            r5, [r0 + r1 * 4]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vmovd          xm0, [r0]
    vmovd          xm1, [r0 + r1]
    vshufps        xm0, xm0, xm1, 0
    vmovd          xm1, [r5]
    vmovd          xm2, [r5 + r1]
    vshufps        xm1, xm1, xm2, 0
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m5
    vmovd          xm1, [r0 + r1 * 2]
    vmovd          xm2, [r0 + r6]
    vshufps        xm1, xm1, xm2, 0
    vmovd          xm2, [r5 + r1 * 2]
    vmovd          xm3, [r5 + r6]
    lea            r5, [r2 + r3 * 4]
    vshufps        xm2, xm2, xm3, 0
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m5
    vmovd          xm2, [r2]
    vmovd          xm3, [r2 + r3]
    vshufps        xm2, xm2, xm3, 0
    vmovd          xm3, [r5]
    vmovd          xm4, [r5 + r3]
    vshufps        xm3, xm3, xm4, 0
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m5
    vpsubw         m0, m0, m2
    vmovd          xm3, [r2 + r3 * 2]
    vmovd          xm4, [r2 + r4]
    vshufps        xm3, xm3, xm4, 0
    vmovd          xm4, [r5 + r3 * 2]
    vmovd          xm2, [r5 + r4]
    vshufps        xm4, xm4, xm2, 0
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m5
    vpsubw         m1, m1, m3

    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpunpcklqdq    m0, m2, m3
    vpunpckhqdq    m1, m2, m3
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpblendw       m0, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m1, m2, m3
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpmaxsw        m0, m0, m1
    vpmaddwd       m0, m0, [pw_1]

    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vpunpckhqdq    xm1, xm0, xm0
    vpaddd         xm0, xm0, xm1
    vpshufd        xm1, xm0, 1
    vpaddd         xm0, xm0, xm1
    vmovd          eax, xm0
    RET

INIT_YMM avx2
cglobal pixel_satd_4x16, 4, 4
%if WIN64
    vmovdqu        [rsp + 8], xm6
%endif
    vmovdqu        m6, [hmul_4p]
    lea            r5, [r0 + r1 * 4]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vmovd          xm0, [r0]
    vmovd          xm1, [r0 + r1]
    vshufps        xm0, xm0, xm1, 0
    vmovd          xm1, [r5]
    vmovd          xm2, [r5 + r1]
    vshufps        xm1, xm1, xm2, 0
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m6
    vmovd          xm1, [r0 + r1 * 2]
    vmovd          xm2, [r0 + r6]
    vshufps        xm1, xm1, xm2, 0
    vmovd          xm2, [r5 + r1 * 2]
    vmovd          xm3, [r5 + r6]
    lea            r5, [r2 + r3 * 4]
    vshufps        xm2, xm2, xm3, 0
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m6
    vmovd          xm2, [r2]
    vmovd          xm3, [r2 + r3]
    vshufps        xm2, xm2, xm3, 0
    vmovd          xm3, [r5]
    vmovd          xm4, [r5 + r3]
    vshufps        xm3, xm3, xm4, 0
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m6
    vpsubw         m0, m0, m2
    vmovd          xm3, [r2 + r3 * 2]
    vmovd          xm4, [r2 + r4]
    vshufps        xm3, xm3, xm4, 0
    vmovd          xm4, [r5 + r3 * 2]
    vmovd          xm2, [r5 + r4]
    vshufps        xm4, xm4, xm2, 0
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m6
    vpsubw         m1, m1, m3

    lea            r0, [r0 + r1 * 8]
    lea            r2, [r2 + r3 * 8]
    lea            r5, [r0 + r1 * 4]
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpunpcklqdq    m0, m2, m3
    vpunpckhqdq    m1, m2, m3
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpblendw       m0, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m1, m2, m3
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpmaxsw        m5, m0, m1

    vmovd          xm0, [r0]
    vmovd          xm1, [r0 + r1]
    vshufps        xm0, xm0, xm1, 0
    vmovd          xm1, [r5]
    vmovd          xm2, [r5 + r1]
    vshufps        xm1, xm1, xm2, 0
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m6
    vmovd          xm1, [r0 + r1 * 2]
    vmovd          xm2, [r0 + r6]
    vshufps        xm1, xm1, xm2, 0
    vmovd          xm2, [r5 + r1 * 2]
    vmovd          xm3, [r5 + r6]
    lea            r5, [r2 + r3 * 4]
    vshufps        xm2, xm2, xm3, 0
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m6
    vmovd          xm2, [r2]
    vmovd          xm3, [r2 + r3]
    vshufps        xm2, xm2, xm3, 0
    vmovd          xm3, [r5]
    vmovd          xm4, [r5 + r3]
    vshufps        xm3, xm3, xm4, 0
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m6
    vpsubw         m0, m0, m2
    vmovd          xm3, [r2 + r3 * 2]
    vmovd          xm4, [r2 + r4]
    vshufps        xm3, xm3, xm4, 0
    vmovd          xm4, [r5 + r3 * 2]
    vmovd          xm2, [r5 + r4]
    vshufps        xm4, xm4, xm2, 0
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m6
    vpsubw         m1, m1, m3

    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpunpcklqdq    m0, m2, m3
    vpunpckhqdq    m1, m2, m3
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpblendw       m0, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m1, m2, m3
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpmaxsw        m0, m0, m1
    vpaddw         m0, m0, m5
    vpmaddwd       m0, m0, [pw_1]

%if WIN64
    vmovdqu        xm6, [rsp + 8]
%endif
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vpunpckhqdq    xm1, xm0, xm0
    vpaddd         xm0, xm0, xm1
    vpshufd        xm1, xm0, 1
    vpaddd         xm0, xm0, xm1
    vmovd          eax, xm0
    RET

INIT_XMM avx2
cglobal pixel_satd_8x4, 4, 4
%if WIN64
    vmovdqu        [rsp + 8], m6
%endif
    vmovdqu        m6, [hmul_8p]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vmovddup       m0, [r0]
    vpmaddubsw     m0, m0, m6
    vmovddup       m1, [r0 + r1]
    vpmaddubsw     m1, m1, m6
    vmovddup       m2, [r2]
    vpmaddubsw     m2, m2, m6
    vmovddup       m3, [r2 + r3]
    vpmaddubsw     m3, m3, m6
    vpsubw         m0, m0, m2
    vpsubw         m1, m1, m3
    vmovddup       m2, [r0 + r1 * 2]
    vpmaddubsw     m2, m2, m6
    vmovddup       m3, [r0 + r6]
    vpmaddubsw     m3, m3, m6
    vmovddup       m4, [r2 + r3 * 2]
    vpmaddubsw     m4, m4, m6
    vmovddup       m5, [r2 + r4]
    vpmaddubsw     m5, m5, m6
    vpsubw         m2, m2, m4
    vpsubw         m3, m3, m5

    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpblendw       m1, m2, m3, 0AAh
    vpblendw       m5, m0, m4, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m2, m2, m3
    vpor           m0, m0, m4
    vpmaxsw        m2, m2, m1
    vpmaxsw        m0, m0, m5
    vpaddw         m2, m2, m0
    vpmaddwd       m2, m2, [pw_1]

%if WIN64
    vmovdqu        m6, [rsp + 8]
%endif
    vpunpckhqdq    m5, m2, m2
    vpaddd         m2, m2, m5
    vpshufd        m5, m2, 1
    vpaddd         m2, m2, m5
    vmovd          eax, m2
    ret

INIT_YMM avx2
cglobal pixel_satd_8x8, 4, 4
%if WIN64
    vmovdqu        [rsp + 8], xm6
%endif
    vmovdqu        m6, [hmul_8p]
    lea            r5, [r0 + r1 * 4]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vmovddup       xm0, [r0]
    vmovddup       xm1, [r5]
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m6
    vmovddup       xm1, [r0 + r1]
    vmovddup       xm2, [r5 + r1]
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m6
    vmovddup       xm2, [r0 + r1 * 2]
    vmovddup       xm3, [r5 + r1 * 2]
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m6
    vmovddup       xm3, [r0 + r6]
    vmovddup       xm4, [r5 + r6]
    lea            r5, [r2 + r3 * 4]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m6
    vmovddup       xm4, [r2]
    vmovddup       xm5, [r5]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m0, m0, m4
    vmovddup       xm4, [r2 + r3]
    vmovddup       xm5, [r5 + r3]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m1, m1, m4
    vmovddup       xm4, [r2 + r3 * 2]
    vmovddup       xm5, [r5 + r3 * 2]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m2, m2, m4
    vmovddup       xm4, [r2 + r4]
    vmovddup       xm5, [r5 + r4]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpblendw       m1, m2, m3, 0AAh
    vpblendw       m5, m0, m4, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m2, m2, m3
    vpor           m0, m0, m4
    vpmaxsw        m2, m2, m1
    vpmaxsw        m0, m0, m5
    vpaddw         m2, m2, m0
    vpmaddwd       m2, m2, [pw_1]

%if WIN64
    vmovdqu        xm6, [rsp + 8]
%endif
    vextracti128   xm1, m2, 1
    vpaddd         xm2, xm2, xm1
    vpunpckhqdq    xm5, xm2, xm2
    vpaddd         xm2, xm2, xm5
    vpshufd        xm5, xm2, 1
    vpaddd         xm2, xm2, xm5
    vmovd          eax, xm2
    RET

INIT_YMM avx2
cglobal pixel_satd_8x16, 4, 4
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
%endif
    vmovdqu        m6, [hmul_8p]
    lea            r5, [r0 + r1 * 4]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vmovddup       xm0, [r0]
    vmovddup       xm1, [r5]
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m6
    vmovddup       xm1, [r0 + r1]
    vmovddup       xm2, [r5 + r1]
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m6
    vmovddup       xm2, [r0 + r1 * 2]
    vmovddup       xm3, [r5 + r1 * 2]
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m6
    vmovddup       xm3, [r0 + r6]
    vmovddup       xm4, [r5 + r6]
    lea            r5, [r2 + r3 * 4]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m6
    vmovddup       xm4, [r2]
    vmovddup       xm5, [r5]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m0, m0, m4
    vmovddup       xm4, [r2 + r3]
    vmovddup       xm5, [r5 + r3]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m1, m1, m4
    vmovddup       xm4, [r2 + r3 * 2]
    vmovddup       xm5, [r5 + r3 * 2]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m2, m2, m4
    vmovddup       xm4, [r2 + r4]
    vmovddup       xm5, [r5 + r4]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    lea            r0, [r0 + r1 * 8]
    lea            r2, [r2 + r3 * 8]
    lea            r5, [r0 + r1 * 4]
    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpblendw       m1, m2, m3, 0AAh
    vpblendw       m5, m0, m4, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m2, m2, m3
    vpor           m0, m0, m4
    vpmaxsw        m2, m2, m1
    vpmaxsw        m0, m0, m5
    vpaddw         m7, m2, m0

    vmovddup       xm0, [r0]
    vmovddup       xm1, [r5]
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m6
    vmovddup       xm1, [r0 + r1]
    vmovddup       xm2, [r5 + r1]
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m6
    vmovddup       xm2, [r0 + r1 * 2]
    vmovddup       xm3, [r5 + r1 * 2]
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m6
    vmovddup       xm3, [r0 + r6]
    vmovddup       xm4, [r5 + r6]
    lea            r5, [r2 + r3 * 4]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m6
    vmovddup       xm4, [r2]
    vmovddup       xm5, [r5]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m0, m0, m4
    vmovddup       xm4, [r2 + r3]
    vmovddup       xm5, [r5 + r3]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m1, m1, m4
    vmovddup       xm4, [r2 + r3 * 2]
    vmovddup       xm5, [r5 + r3 * 2]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m2, m2, m4
    vmovddup       xm4, [r2 + r4]
    vmovddup       xm5, [r5 + r4]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpblendw       m1, m2, m3, 0AAh
    vpblendw       m5, m0, m4, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m2, m2, m3
    vpor           m0, m0, m4
    vpmaxsw        m2, m2, m1
    vpmaxsw        m0, m0, m5
    vpaddw         m2, m2, m0
    vpaddw         m2, m2, m7
    vpmaddwd       m2, m2, [pw_1]

%if WIN64
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vextracti128   xm1, m2, 1
    vpaddd         xm2, xm2, xm1
    vpunpckhqdq    xm5, xm2, xm2
    vpaddd         xm2, xm2, xm5
    vpshufd        xm5, xm2, 1
    vpaddd         xm2, xm2, xm5
    vmovd          eax, xm2
    RET

INIT_YMM avx2
cglobal pixel_satd_16x8, 4, 4
%if WIN64
    vmovdqu        [rsp + 8], xm6
%endif
    vmovups        m6, [hmul_16p]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m6
    vpmaddubsw     m1, m1, m6
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m6
    vpmaddubsw     m2, m2, m6
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m6
    vpmaddubsw     m3, m3, m6
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    vpmaddubsw     m3, m3, m6
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpblendw       m1, m2, m3, 0AAh
    vpblendw       m5, m0, m4, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m2, m2, m3
    vpor           m0, m0, m4
    vpmaxsw        m2, m2, m1
    vpmaxsw        m0, m0, m5
    vpaddw         m5, m2, m0

    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m6
    vpmaddubsw     m1, m1, m6
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m6
    vpmaddubsw     m2, m2, m6
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m6
    vpmaddubsw     m3, m3, m6
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    vpmaddubsw     m3, m3, m6
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    vpaddw         m4, m0, m1
    vpsubw         m6, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m6, m1
    vpsubw         m4, m6, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpblendw       m1, m2, m3, 0AAh
    vpblendw       m6, m0, m4, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m2, m2, m3
    vpor           m0, m0, m4
    vpmaxsw        m2, m2, m1
    vpmaxsw        m0, m0, m6
    vpaddw         m2, m2, m0
    vpaddw         m2, m2, m5
    vpmaddwd       m2, m2, [pw_1]

%if WIN64
    vmovdqu        xm6, [rsp + 8]
%endif
    vextracti128   xm1, m2, 1
    vpaddd         xm2, xm2, xm1
    vpunpckhqdq    xm5, xm2, xm2
    vpaddd         xm2, xm2, xm5
    vpshufd        xm5, xm2, 1
    vpaddd         xm2, xm2, xm5
    vmovd          eax, xm2
    RET

INIT_YMM avx2
cglobal pixel_satd_16x16, 4, 4
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
%endif
    vmovups        m6, [hmul_16p]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m6
    vpmaddubsw     m1, m1, m6
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m6
    vpmaddubsw     m2, m2, m6
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m6
    vpmaddubsw     m3, m3, m6
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    vpmaddubsw     m3, m3, m6
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpblendw       m1, m2, m3, 0AAh
    vpblendw       m5, m0, m4, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m2, m2, m3
    vpor           m0, m0, m4
    vpmaxsw        m2, m2, m1
    vpmaxsw        m0, m0, m5
    vpaddw         m7, m2, m0

    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m6
    vpmaddubsw     m1, m1, m6
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m6
    vpmaddubsw     m2, m2, m6
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m6
    vpmaddubsw     m3, m3, m6
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    vpmaddubsw     m3, m3, m6
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpblendw       m1, m2, m3, 0AAh
    vpblendw       m5, m0, m4, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m2, m2, m3
    vpor           m0, m0, m4
    vpmaxsw        m2, m2, m1
    vpmaxsw        m0, m0, m5
    vpaddw         m2, m2, m0
    vpaddw         m7, m2, m7

    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m6
    vpmaddubsw     m1, m1, m6
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m6
    vpmaddubsw     m2, m2, m6
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m6
    vpmaddubsw     m3, m3, m6
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    vpmaddubsw     m3, m3, m6
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpblendw       m1, m2, m3, 0AAh
    vpblendw       m5, m0, m4, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m2, m2, m3
    vpor           m0, m0, m4
    vpmaxsw        m2, m2, m1
    vpmaxsw        m0, m0, m5
    vpaddw         m2, m2, m0
    vpaddw         m7, m2, m7

    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m6
    vpmaddubsw     m1, m1, m6
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m6
    vpmaddubsw     m2, m2, m6
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m6
    vpmaddubsw     m3, m3, m6
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    vpmaddubsw     m3, m3, m6
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpblendw       m1, m2, m3, 0AAh
    vpblendw       m5, m0, m4, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m2, m2, m3
    vpor           m0, m0, m4
    vpmaxsw        m2, m2, m1
    vpmaxsw        m0, m0, m5
    vpaddw         m2, m2, m0
    vpaddw         m2, m2, m7
    vpmaddwd       m2, m2, [pw_1]

%if WIN64
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vextracti128   xm1, m2, 1
    vpaddd         xm2, xm2, xm1
    vpunpckhqdq    xm5, xm2, xm2
    vpaddd         xm2, xm2, xm5
    vpshufd        xm5, xm2, 1
    vpaddd         xm2, xm2, xm5
    vmovd          eax, xm2
    RET


;=============================================================================
; SATD X3/X4
;=============================================================================
INIT_YMM avx2
cglobal pixel_satd_x3_4x4, 4, 4
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
%endif
    vmovdqu        m6, [hmul_4p]
    lea            r6d, [r4 + r4 * 2]

    vmovd          xm0, [r0]
    vmovd          xm1, [r0 + 16]
    vshufps        xm0, xm0, xm1, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m6
    vmovd          xm1, [r1]
    vinserti128    m1, m1, [r2], 1
    vmovd          xm2, [r1 + r4]
    vinserti128    m2, m2, [r2 + r4], 1
    vshufps        m1, m1, m2, 0
    vpmaddubsw     m1, m1, m6
    vmovd          xm2, [r3]
    vmovd          xm3, [r3 + r4]
    vshufps        xm2, xm2, xm3, 0
    vpmaddubsw     xm2, xm2, xm6
    vpsubw         m1, m0, m1
    vpsubw         xm2, xm0, xm2
    vmovd          xm0, [r0 + 32]
    vmovd          xm3, [r0 + 48]
    vshufps        xm0, xm0, xm3, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m6
    vmovd          xm3, [r1 + r4 * 2]
    vinserti128    m3, m3, [r2 + r4 * 2], 1
    vmovd          xm4, [r1 + r6]
    vinserti128    m4, m4, [r2 + r6], 1
    vshufps        m3, m3, m4, 0
    vpmaddubsw     m3, m3, m6
    vmovd          xm4, [r3 + r4 * 2]
    vmovd          xm5, [r3 + r6]
    vshufps        xm4, xm4, xm5, 0
    vpmaddubsw     xm4, xm4, xm6
    vpsubw         m3, m0, m3
    vpsubw         xm4, xm0, xm4
    
    vpaddw         m5, m1, m3
    vpsubw         m6, m1, m3
    vpaddw         xm0, xm2, xm4
    vpsubw         xm1, xm2, xm4
    vpunpcklqdq    m2, m5, m6
    vpunpckhqdq    m3, m5, m6
    vpunpcklqdq    xm4, xm0, xm1
    vpunpckhqdq    xm5, xm0, xm1
    vpaddw         m0, m2, m3
    vpsubw         m6, m2, m3
    vpaddw         xm2, xm4, xm5
    vpsubw         xm3, xm4, xm5

    vpblendw       m1, m0, m6, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m6, m6, 16
    vpor           m0, m0, m6
    vpabsw         m1, m1
    vpabsw         m0, m0
    vpmaxsw        m0, m0, m1
    vmovdqu        m5, [pw_1]
    vpblendw       xm1, xm2, xm3, 0AAh
    vpsrld         xm2, xm2, 16
    vpslld         xm3, xm3, 16
    vpor           xm2, xm2, xm3
    vpabsw         xm1, xm1
    vpabsw         xm2, xm2
    vpmaxsw        xm1, xm1, xm2
    vpmaddwd       m0, m0, m5
    vpmaddwd       xm1, xm1, xm5

%if WIN64
    vmovdqu        xm6, [rsp + 8]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r5], xm0
    RET

INIT_YMM avx2
cglobal pixel_satd_x3_4x8, 4, 4
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 40
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
%endif
    vmovdqu        m7, [hmul_4p]
    lea            r6d, [r4 + r4 * 2]

    vmovd          xm0, [r0]
    vmovd          xm1, [r0 + 16]
    vshufps        xm0, xm0, xm1, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m7
    vmovd          xm1, [r1]
    vinserti128    m1, m1, [r2], 1
    vmovd          xm2, [r1 + r4]
    vinserti128    m2, m2, [r2 + r4], 1
    vshufps        m1, m1, m2, 0
    vpmaddubsw     m1, m1, m7
    vmovd          xm2, [r3]
    vmovd          xm3, [r3 + r4]
    vshufps        xm2, xm2, xm3, 0
    vpmaddubsw     xm2, xm2, xm7
    vpsubw         m1, m0, m1
    vpsubw         xm2, xm0, xm2
    vmovd          xm0, [r0 + 32]
    vmovd          xm3, [r0 + 48]
    vshufps        xm0, xm0, xm3, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m7
    vmovd          xm3, [r1 + r4 * 2]
    vinserti128    m3, m3, [r2 + r4 * 2], 1
    vmovd          xm4, [r1 + r6]
    vinserti128    m4, m4, [r2 + r6], 1
    vshufps        m3, m3, m4, 0
    vpmaddubsw     m3, m3, m7
    vmovd          xm4, [r3 + r4 * 2]
    vmovd          xm5, [r3 + r6]
    vshufps        xm4, xm4, xm5, 0
    vpmaddubsw     xm4, xm4, xm7
    vpsubw         m3, m0, m3
    vpsubw         xm4, xm0, xm4
    
    lea            r1, [r1 + r4 * 4]
    lea            r2, [r2 + r4 * 4]
    lea            r3, [r3 + r4 * 4]
    vpaddw         m5, m1, m3
    vpsubw         m6, m1, m3
    vpaddw         xm0, xm2, xm4
    vpsubw         xm1, xm2, xm4
    vpunpcklqdq    m2, m5, m6
    vpunpckhqdq    m3, m5, m6
    vpunpcklqdq    xm4, xm0, xm1
    vpunpckhqdq    xm5, xm0, xm1
    vpaddw         m0, m2, m3
    vpsubw         m6, m2, m3
    vpaddw         xm2, xm4, xm5
    vpsubw         xm3, xm4, xm5

    vpblendw       m1, m0, m6, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m6, m6, 16
    vpor           m0, m0, m6
    vpabsw         m1, m1
    vpabsw         m0, m0
    vpmaxsw        m8, m0, m1
    vpblendw       xm1, xm2, xm3, 0AAh
    vpsrld         xm2, xm2, 16
    vpslld         xm3, xm3, 16
    vpor           xm2, xm2, xm3
    vpabsw         xm1, xm1
    vpabsw         xm2, xm2
    vpmaxsw        xm9, xm1, xm2

    vmovd          xm0, [r0 + 64]
    vmovd          xm1, [r0 + 80]
    vshufps        xm0, xm0, xm1, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m7
    vmovd          xm1, [r1]
    vinserti128    m1, m1, [r2], 1
    vmovd          xm2, [r1 + r4]
    vinserti128    m2, m2, [r2 + r4], 1
    vshufps        m1, m1, m2, 0
    vpmaddubsw     m1, m1, m7
    vmovd          xm2, [r3]
    vmovd          xm3, [r3 + r4]
    vshufps        xm2, xm2, xm3, 0
    vpmaddubsw     xm2, xm2, xm7
    vpsubw         m1, m0, m1
    vpsubw         xm2, xm0, xm2
    vmovd          xm0, [r0 + 96]
    vmovd          xm3, [r0 + 112]
    vshufps        xm0, xm0, xm3, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m7
    vmovd          xm3, [r1 + r4 * 2]
    vinserti128    m3, m3, [r2 + r4 * 2], 1
    vmovd          xm4, [r1 + r6]
    vinserti128    m4, m4, [r2 + r6], 1
    vshufps        m3, m3, m4, 0
    vpmaddubsw     m3, m3, m7
    vmovd          xm4, [r3 + r4 * 2]
    vmovd          xm5, [r3 + r6]
    vshufps        xm4, xm4, xm5, 0
    vpmaddubsw     xm4, xm4, xm7
    vpsubw         m3, m0, m3
    vpsubw         xm4, xm0, xm4
    
    vpaddw         m5, m1, m3
    vpsubw         m6, m1, m3
    vpaddw         xm0, xm2, xm4
    vpsubw         xm1, xm2, xm4
    vpunpcklqdq    m2, m5, m6
    vpunpckhqdq    m3, m5, m6
    vpunpcklqdq    xm4, xm0, xm1
    vpunpckhqdq    xm5, xm0, xm1
    vpaddw         m0, m2, m3
    vpsubw         m6, m2, m3
    vpaddw         xm2, xm4, xm5
    vpsubw         xm3, xm4, xm5

    vmovdqu        m5, [pw_1]
    vpblendw       m1, m0, m6, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m6, m6, 16
    vpor           m0, m0, m6
    vpabsw         m1, m1
    vpabsw         m0, m0
    vpmaxsw        m0, m0, m1
    vpaddw         m0, m0, m8
    vpmaddwd       m0, m0, m5
    vpblendw       xm1, xm2, xm3, 0AAh
    vpsrld         xm2, xm2, 16
    vpslld         xm3, xm3, 16
    vpor           xm2, xm2, xm3
    vpabsw         xm1, xm1
    vpabsw         xm2, xm2
    vpmaxsw        xm1, xm1, xm2
    vpaddw         xm1, xm1, xm9
    vpmaddwd       xm1, xm1, xm5

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    add            rsp, 40
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r5], xm0
    RET

INIT_YMM avx2
cglobal pixel_satd_x3_8x4, 4, 4
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 40
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
%endif
    vmovdqu        m9, [hmul_8p]
    lea            r6d, [r4 + r4 * 2]

    vpbroadcastq   m0, [r0]
    vpmaddubsw     m0, m0, m9
    vmovddup       xm1, [r1]
    vmovddup       xm2, [r2]
    vinserti128    m1, m1, xm2, 1
    vmovddup       xm2, [r3]
    vpmaddubsw     m1, m1, m9
    vpmaddubsw     xm2, xm2, xm9
    vpsubw         m1, m0, m1
    vpsubw         xm2, xm0, xm2
    vpbroadcastq   m0, [r0 + 16]
    vpmaddubsw     m0, m0, m9
    vmovddup       xm3, [r1 + r4]
    vmovddup       xm4, [r2 + r4]
    vinserti128    m3, m3, xm4, 1
    vmovddup       xm4, [r3 + r4]
    vpmaddubsw     m3, m3, m9
    vpmaddubsw     xm4, xm4, xm9
    vpsubw         m3, m0, m3
    vpsubw         xm4, xm0, xm4
    vpbroadcastq   m0, [r0 + 32]
    vpmaddubsw     m0, m0, m9
    vmovddup       xm5, [r1 + r4 * 2]
    vmovddup       xm6, [r2 + r4 * 2]
    vinserti128    m5, m5, xm6, 1
    vmovddup       xm6, [r3 + r4 * 2]
    vpmaddubsw     m5, m5, m9
    vpmaddubsw     xm6, xm6, xm9
    vpsubw         m5, m0, m5
    vpsubw         xm6, xm0, xm6
    vpbroadcastq   m0, [r0 + 48]
    vpmaddubsw     m0, m0, m9
    vmovddup       xm7, [r1 + r6]
    vmovddup       xm8, [r2 + r6]
    vinserti128    m7, m7, xm8, 1
    vmovddup       xm8, [r3 + r6]
    vpmaddubsw     m7, m7, m9
    vpmaddubsw     xm8, xm8, xm9
    vpsubw         m7, m0, m7
    vpsubw         xm8, xm0, xm8

    vpaddw         m0, m1, m3
    vpsubw         m9, m1, m3
    vpaddw         m1, m5, m7
    vpsubw         m3, m5, m7
    vpaddw         m5, m0, m1
    vpsubw         m7, m0, m1
    vpaddw         m0, m9, m3
    vpsubw         m1, m9, m3
    vpabsw         m5, m5
    vpabsw         m7, m7
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpblendw       m3, m5, m7, 0AAh
    vpblendw       m9, m0, m1, 0AAh
    vpsrld         m5, m5, 16
    vpslld         m7, m7, 16
    vpsrld         m0, m0, 16
    vpslld         m1, m1, 16
    vpor           m5, m5, m7
    vpor           m0, m0, m1
    vpmaxsw        m5, m5, m3
    vpmaxsw        m0, m0, m9
    vpaddw         m0, m0, m5

    vmovdqu        m9, [pw_1]
    vpaddw         xm1, xm2, xm4
    vpsubw         xm3, xm2, xm4
    vpaddw         xm2, xm6, xm8
    vpsubw         xm4, xm6, xm8
    vpaddw         xm6, xm1, xm2
    vpsubw         xm8, xm1, xm2
    vpaddw         xm1, xm3, xm4
    vpsubw         xm2, xm3, xm4
    vpabsw         xm6, xm6
    vpabsw         xm8, xm8
    vpabsw         xm1, xm1
    vpabsw         xm2, xm2
    vpblendw       xm3, xm6, xm8, 0AAh
    vpblendw       xm5, xm1, xm2, 0AAh
    vpsrld         xm6, xm6, 16
    vpslld         xm8, xm8, 16
    vpsrld         xm1, xm1, 16
    vpslld         xm2, xm2, 16
    vpor           xm6, xm6, xm8
    vpor           xm1, xm1, xm2
    vpmaxsw        xm6, xm6, xm3
    vpmaxsw        xm1, xm1, xm5
    vpaddw         xm6, xm6, xm1
    vpmaddwd       m0, m0, m9
    vpmaddwd       xm1, xm6, xm9

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    add            rsp, 40
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r5], xm0
    RET


INIT_YMM avx2
cglobal pixel_satd_x3_8xN_internal, 4, 4
    vpbroadcastq   m0, [r0]
    vpmaddubsw     m0, m0, m12
    vmovddup       xm1, [r1]
    vmovddup       xm2, [r2]
    vinserti128    m1, m1, xm2, 1
    vmovddup       xm2, [r3]
    vpmaddubsw     m1, m1, m12
    vpmaddubsw     xm2, xm2, xm12
    vpsubw         m1, m0, m1
    vpsubw         xm2, xm0, xm2
    vpbroadcastq   m0, [r0 + 16]
    vpmaddubsw     m0, m0, m12
    vmovddup       xm3, [r1 + r4]
    vmovddup       xm4, [r2 + r4]
    vinserti128    m3, m3, xm4, 1
    vmovddup       xm4, [r3 + r4]
    vpmaddubsw     m3, m3, m12
    vpmaddubsw     xm4, xm4, xm12
    vpsubw         m3, m0, m3
    vpsubw         xm4, xm0, xm4
    vpbroadcastq   m0, [r0 + 32]
    vpmaddubsw     m0, m0, m12
    vmovddup       xm5, [r1 + r4 * 2]
    vmovddup       xm6, [r2 + r4 * 2]
    vinserti128    m5, m5, xm6, 1
    vmovddup       xm6, [r3 + r4 * 2]
    vpmaddubsw     m5, m5, m12
    vpmaddubsw     xm6, xm6, xm12
    vpsubw         m5, m0, m5
    vpsubw         xm6, xm0, xm6
    vpbroadcastq   m0, [r0 + 48]
    vpmaddubsw     m0, m0, m12
    vmovddup       xm7, [r1 + r6]
    vmovddup       xm8, [r2 + r6]
    vinserti128    m7, m7, xm8, 1
    vmovddup       xm8, [r3 + r6]
    vpmaddubsw     m7, m7, m12
    vpmaddubsw     xm8, xm8, xm12
    vpsubw         m7, m0, m7
    vpsubw         xm8, xm0, xm8

    add            r0, 64
    lea            r1, [r1 + r4 * 4]
    lea            r2, [r2 + r4 * 4]
    lea            r3, [r3 + r4 * 4]
    vpaddw         m0, m1, m3
    vpsubw         m9, m1, m3
    vpaddw         m1, m5, m7
    vpsubw         m3, m5, m7
    vpaddw         m5, m0, m1
    vpsubw         m7, m0, m1
    vpaddw         m0, m9, m3
    vpsubw         m1, m9, m3
    vpabsw         m5, m5
    vpabsw         m7, m7
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpblendw       m3, m5, m7, 0AAh
    vpblendw       m9, m0, m1, 0AAh
    vpsrld         m5, m5, 16
    vpslld         m7, m7, 16
    vpsrld         m0, m0, 16
    vpslld         m1, m1, 16
    vpor           m5, m5, m7
    vpor           m0, m0, m1
    vpmaxsw        m5, m5, m3
    vpmaxsw        m0, m0, m9
    vpaddw         m0, m0, m5
    vpaddw         m10, m0, m10

    vpaddw         xm1, xm2, xm4
    vpsubw         xm3, xm2, xm4
    vpaddw         xm2, xm6, xm8
    vpsubw         xm4, xm6, xm8
    vpaddw         xm6, xm1, xm2
    vpsubw         xm8, xm1, xm2
    vpaddw         xm1, xm3, xm4
    vpsubw         xm2, xm3, xm4
    vpabsw         xm6, xm6
    vpabsw         xm8, xm8
    vpabsw         xm1, xm1
    vpabsw         xm2, xm2
    vpblendw       xm3, xm6, xm8, 0AAh
    vpblendw       xm5, xm1, xm2, 0AAh
    vpsrld         xm6, xm6, 16
    vpslld         xm8, xm8, 16
    vpsrld         xm1, xm1, 16
    vpslld         xm2, xm2, 16
    vpor           xm6, xm6, xm8
    vpor           xm1, xm1, xm2
    vpmaxsw        xm6, xm6, xm3
    vpmaxsw        xm1, xm1, xm5
    vpaddw         xm6, xm6, xm1
    vpaddw         xm11, xm6, xm11
    ret

INIT_YMM avx2
cglobal pixel_satd_x3_8x8, 4, 4
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 88
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
%endif
    vmovdqu        m12, [hmul_8p]
    lea            r6d, [r4 + r4 * 2]
    vpxor          m10, m10, m10
    vpxor          m11, m11, m11
    call           pixel_satd_x3_8xN_internal
    call           pixel_satd_x3_8xN_internal
    vmovdqu        m9, [pw_1]
    vpmaddwd       m0, m10, m9
    vpmaddwd       xm1, xm11, xm9

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
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r5], xm0
    RET

INIT_YMM avx2
cglobal pixel_satd_x3_8x16, 4, 4
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 88
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
%endif
    vmovdqu        m12, [hmul_8p]
    lea            r6d, [r4 + r4 * 2]
    vpxor          m10, m10, m10
    vpxor          m11, m11, m11
    call           pixel_satd_x3_8xN_internal
    call           pixel_satd_x3_8xN_internal
    call           pixel_satd_x3_8xN_internal
    call           pixel_satd_x3_8xN_internal
    vmovdqu        m9, [pw_1]
    vpmaddwd       m0, m10, m9
    vpmaddwd       xm1, xm11, xm9

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
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r5], xm0
    RET


INIT_YMM avx2
cglobal pixel_satd_x3_16xN_internal, 4, 4
    vbroadcasti128 m0, [r0]
    vpmaddubsw     m0, m0, m13
    vbroadcasti128 m1, [r0 + 16]
    vpmaddubsw     m1, m1, m13
    vbroadcasti128 m2, [r0 + 32]
    vpmaddubsw     m2, m2, m13
    vbroadcasti128 m3, [r0 + 48]
    vpmaddubsw     m3, m3, m13
    add            r0, 64

    vbroadcasti128 m4, [r1]
    vpmaddubsw     m4, m4, m13
    vpsubw         m4, m0, m4
    vbroadcasti128 m5, [r1 + r4]
    vpmaddubsw     m5, m5, m13
    vpsubw         m5, m1, m5
    vbroadcasti128 m6, [r1 + r4 * 2]
    vpmaddubsw     m6, m6, m13
    vpsubw         m6, m2, m6
    vbroadcasti128 m7, [r1 + r6]
    vpmaddubsw     m7, m7, m13
    vpsubw         m7, m3, m7

    lea            r1, [r1 + r4 * 4]
    vpaddw         m8, m4, m5
    vpsubw         m9, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m4
    vpsubw         m7, m8, m4
    vpaddw         m8, m9, m5
    vpsubw         m4, m9, m5
    vpabsw         m6, m6
    vpabsw         m7, m7
    vpabsw         m8, m8
    vpabsw         m4, m4
    vpblendw       m9, m6, m7, 0AAh
    vpblendw       m5, m8, m4, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m7, m7, 16
    vpsrld         m8, m8, 16
    vpslld         m4, m4, 16
    vpor           m6, m6, m7
    vpor           m8, m8, m4
    vpmaxsw        m6, m6, m9
    vpmaxsw        m8, m8, m5
    vpaddw         m6, m6, m8
    vpaddw         m10, m6, m10

    vbroadcasti128 m4, [r2]
    vpmaddubsw     m4, m4, m13
    vpsubw         m4, m0, m4
    vbroadcasti128 m5, [r2 + r4]
    vpmaddubsw     m5, m5, m13
    vpsubw         m5, m1, m5
    vbroadcasti128 m6, [r2 + r4 * 2]
    vpmaddubsw     m6, m6, m13
    vpsubw         m6, m2, m6
    vbroadcasti128 m7, [r2 + r6]
    vpmaddubsw     m7, m7, m13
    vpsubw         m7, m3, m7

    lea            r2, [r2 + r4 * 4]
    vpaddw         m8, m4, m5
    vpsubw         m9, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m4
    vpsubw         m7, m8, m4
    vpaddw         m8, m9, m5
    vpsubw         m4, m9, m5
    vpabsw         m6, m6
    vpabsw         m7, m7
    vpabsw         m8, m8
    vpabsw         m4, m4
    vpblendw       m9, m6, m7, 0AAh
    vpblendw       m5, m8, m4, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m7, m7, 16
    vpsrld         m8, m8, 16
    vpslld         m4, m4, 16
    vpor           m6, m6, m7
    vpor           m8, m8, m4
    vpmaxsw        m6, m6, m9
    vpmaxsw        m8, m8, m5
    vpaddw         m6, m6, m8
    vpaddw         m11, m6, m11

    vbroadcasti128 m4, [r3]
    vpmaddubsw     m4, m4, m13
    vpsubw         m4, m0, m4
    vbroadcasti128 m5, [r3 + r4]
    vpmaddubsw     m5, m5, m13
    vpsubw         m5, m1, m5
    vbroadcasti128 m6, [r3 + r4 * 2]
    vpmaddubsw     m6, m6, m13
    vpsubw         m6, m2, m6
    vbroadcasti128 m7, [r3 + r6]
    vpmaddubsw     m7, m7, m13
    vpsubw         m7, m3, m7

    lea            r3, [r3 + r4 * 4]
    vpaddw         m8, m4, m5
    vpsubw         m9, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m4
    vpsubw         m7, m8, m4
    vpaddw         m8, m9, m5
    vpsubw         m4, m9, m5
    vpabsw         m6, m6
    vpabsw         m7, m7
    vpabsw         m8, m8
    vpabsw         m4, m4
    vpblendw       m9, m6, m7, 0AAh
    vpblendw       m5, m8, m4, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m7, m7, 16
    vpsrld         m8, m8, 16
    vpslld         m4, m4, 16
    vpor           m6, m6, m7
    vpor           m8, m8, m4
    vpmaxsw        m6, m6, m9
    vpmaxsw        m8, m8, m5
    vpaddw         m6, m6, m8
    vpaddw         m12, m6, m12
    ret

INIT_YMM avx2
cglobal pixel_satd_x3_16x8, 4, 4
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 104
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
    vmovdqu        [rsp + 80], xm13
%endif
    vmovups        m13, [hmul_16p]
    lea            r6d, [r4 + r4 * 2]
    vpxor          m10, m10, m10
    vpxor          m11, m11, m11
    vpxor          m12, m12, m12
    call           pixel_satd_x3_16xN_internal
    call           pixel_satd_x3_16xN_internal
    vmovdqu        m3, [pw_1]
    vpmaddwd       m0, m10, m3
    vpmaddwd       m1, m11, m3
    vpmaddwd       m2, m12, m3

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    vmovdqu        xm13, [rsp + 80]
    add            rsp, 104
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vphaddd        m0, m0, m1
    vpunpckhqdq    m3, m2, m2
    vpaddd         m2, m2, m3
    vphaddd        m0, m0, m2
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovdqu        [r5], xm0
    RET

INIT_YMM avx2
cglobal pixel_satd_x3_16x16, 4, 4
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 104
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
    vmovdqu        [rsp + 80], xm13
%endif
    vmovups        m13, [hmul_16p]
    lea            r6d, [r4 + r4 * 2]
    vpxor          m10, m10, m10
    vpxor          m11, m11, m11
    vpxor          m12, m12, m12
    call           pixel_satd_x3_16xN_internal
    call           pixel_satd_x3_16xN_internal
    call           pixel_satd_x3_16xN_internal
    call           pixel_satd_x3_16xN_internal
    vmovdqu        m3, [pw_1]
    vpmaddwd       m0, m10, m3
    vpmaddwd       m1, m11, m3
    vpmaddwd       m2, m12, m3

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    vmovdqu        xm13, [rsp + 80]
    add            rsp, 104
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vphaddd        m0, m0, m1
    vpunpckhqdq    m3, m2, m2
    vpaddd         m2, m2, m3
    vphaddd        m0, m0, m2
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovdqu        [r5], xm0
    RET


INIT_YMM avx2
cglobal pixel_satd_x4_4x4, 4, 4
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
%endif
    vmovdqu        m6, [hmul_4p]
    lea            r6d, [r5 + r5 * 2]

    vmovd          xm0, [r0]
    vmovd          xm1, [r0 + 16]
    vshufps        xm0, xm0, xm1, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m6
    vmovd          xm1, [r1]
    vinserti128    m1, m1, [r2], 1
    vmovd          xm2, [r1 + r5]
    vinserti128    m2, m2, [r2 + r5], 1
    vshufps        m1, m1, m2, 0
    vpmaddubsw     m1, m1, m6
    vmovd          xm2, [r3]
    vinserti128    m2, m2, [r4], 1
    vmovd          xm3, [r3 + r5]
    vinserti128    m3, m3, [r4 + r5], 1
    vshufps        m2, m2, m3, 0
    vpmaddubsw     m2, m2, m6
    vpsubw         m1, m0, m1
    vpsubw         m2, m0, m2

    vmovd          xm0, [r0 + 32]
    vmovd          xm3, [r0 + 48]
    vshufps        xm0, xm0, xm3, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m6
    vmovd          xm3, [r1 + r5 * 2]
    vinserti128    m3, m3, [r2 + r5 * 2], 1
    vmovd          xm4, [r1 + r6]
    vinserti128    m4, m4, [r2 + r6], 1
    vshufps        m3, m3, m4, 0
    vpmaddubsw     m3, m3, m6
    vmovd          xm4, [r3 + r5 * 2]
    vinserti128    m4, m4, [r4 + r5 * 2], 1
    vmovd          xm5, [r3 + r6]
    vinserti128    m5, m5, [r4 + r6], 1
    vshufps        m4, m4, m5, 0
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m0, m3
    vpsubw         m4, m0, m4
    
    vpaddw         m5, m1, m3
    vpsubw         m6, m1, m3
    vpaddw         m0, m2, m4
    vpsubw         m1, m2, m4
    vpunpcklqdq    m2, m5, m6
    vpunpckhqdq    m3, m5, m6
    vpunpcklqdq    m4, m0, m1
    vpunpckhqdq    m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m6, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5

    vmovdqu        m5, [pw_1]
    vpblendw       m1, m0, m6, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m6, m6, 16
    vpor           m0, m0, m6
    vpabsw         m1, m1
    vpabsw         m0, m0
    vpmaxsw        m0, m0, m1
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m2, m2, m3
    vpabsw         m1, m1
    vpabsw         m2, m2
    vpmaxsw        m1, m1, m2
    vpmaddwd       m0, m0, m5
    vpmaddwd       m1, m1, m5

%if WIN64
    vmovdqu        [rsp + 8], xm6
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r6], xm0
    RET

INIT_YMM avx2
cglobal pixel_satd_x4_4x8, 4, 4
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 40
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
%endif
    vmovdqu        m7, [hmul_4p]
    lea            r6d, [r5 + r5 * 2]

    vmovd          xm0, [r0]
    vmovd          xm1, [r0 + 16]
    vshufps        xm0, xm0, xm1, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m7
    vmovd          xm1, [r1]
    vinserti128    m1, m1, [r2], 1
    vmovd          xm2, [r1 + r5]
    vinserti128    m2, m2, [r2 + r5], 1
    vshufps        m1, m1, m2, 0
    vpmaddubsw     m1, m1, m7
    vmovd          xm2, [r3]
    vinserti128    m2, m2, [r4], 1
    vmovd          xm3, [r3 + r5]
    vinserti128    m3, m3, [r4 + r5], 1
    vshufps        m2, m2, m3, 0
    vpmaddubsw     m2, m2, m7
    vpsubw         m1, m0, m1
    vpsubw         m2, m0, m2
    vmovd          xm0, [r0 + 32]
    vmovd          xm3, [r0 + 48]
    vshufps        xm0, xm0, xm3, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m7
    vmovd          xm3, [r1 + r5 * 2]
    vinserti128    m3, m3, [r2 + r5 * 2], 1
    vmovd          xm4, [r1 + r6]
    vinserti128    m4, m4, [r2 + r6], 1
    vshufps        m3, m3, m4, 0
    vpmaddubsw     m3, m3, m7
    vmovd          xm4, [r3 + r5 * 2]
    vinserti128    m4, m4, [r4 + r5 * 2], 1
    vmovd          xm5, [r3 + r6]
    vinserti128    m5, m5, [r4 + r6], 1
    vshufps        m4, m4, m5, 0
    vpmaddubsw     m4, m4, m7
    vpsubw         m3, m0, m3
    vpsubw         m4, m0, m4
    
    lea            r1, [r1 + r5 * 4]
    lea            r2, [r2 + r5 * 4]
    lea            r3, [r3 + r5 * 4]
    lea            r4, [r4 + r5 * 4]
    vpaddw         m5, m1, m3
    vpsubw         m6, m1, m3
    vpaddw         m0, m2, m4
    vpsubw         m1, m2, m4
    vpunpcklqdq    m2, m5, m6
    vpunpckhqdq    m3, m5, m6
    vpunpcklqdq    m4, m0, m1
    vpunpckhqdq    m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m6, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5

    vpblendw       m1, m0, m6, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m6, m6, 16
    vpor           m0, m0, m6
    vpabsw         m1, m1
    vpabsw         m0, m0
    vpmaxsw        m8, m0, m1
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m2, m2, m3
    vpabsw         m1, m1
    vpabsw         m2, m2
    vpmaxsw        m9, m1, m2

    vmovd          xm0, [r0 + 64]
    vmovd          xm1, [r0 + 80]
    vshufps        xm0, xm0, xm1, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m7
    vmovd          xm1, [r1]
    vinserti128    m1, m1, [r2], 1
    vmovd          xm2, [r1 + r5]
    vinserti128    m2, m2, [r2 + r5], 1
    vshufps        m1, m1, m2, 0
    vpmaddubsw     m1, m1, m7
    vmovd          xm2, [r3]
    vinserti128    m2, m2, [r4], 1
    vmovd          xm3, [r3 + r5]
    vinserti128    m3, m3, [r4 + r5], 1
    vshufps        m2, m2, m3, 0
    vpmaddubsw     m2, m2, m7
    vpsubw         m1, m0, m1
    vpsubw         m2, m0, m2
    vmovd          xm0, [r0 + 96]
    vmovd          xm3, [r0 + 112]
    vshufps        xm0, xm0, xm3, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m7
    vmovd          xm3, [r1 + r5 * 2]
    vinserti128    m3, m3, [r2 + r5 * 2], 1
    vmovd          xm4, [r1 + r6]
    vinserti128    m4, m4, [r2 + r6], 1
    vshufps        m3, m3, m4, 0
    vpmaddubsw     m3, m3, m7
    vmovd          xm4, [r3 + r5 * 2]
    vinserti128    m4, m4, [r4 + r5 * 2], 1
    vmovd          xm5, [r3 + r6]
    vinserti128    m5, m5, [r4 + r6], 1
    vshufps        m4, m4, m5, 0
    vpmaddubsw     m4, m4, m7
    vpsubw         m3, m0, m3
    vpsubw         m4, m0, m4
    
    vpaddw         m5, m1, m3
    vpsubw         m6, m1, m3
    vpaddw         m0, m2, m4
    vpsubw         m1, m2, m4
    vpunpcklqdq    m2, m5, m6
    vpunpckhqdq    m3, m5, m6
    vpunpcklqdq    m4, m0, m1
    vpunpckhqdq    m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m6, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5

    vmovdqu        m5, [pw_1]
    vpblendw       m1, m0, m6, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m6, m6, 16
    vpor           m0, m0, m6
    vpabsw         m1, m1
    vpabsw         m0, m0
    vpmaxsw        m0, m0, m1
    vpaddw         m0, m0, m8
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m2, m2, m3
    vpabsw         m1, m1
    vpabsw         m2, m2
    vpmaxsw        m1, m1, m2
    vpaddw         m1, m1, m9

    vpmaddwd       m0, m0, m5
    vpmaddwd       m1, m1, m5

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    add            rsp, 40
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r6], xm0
    RET

INIT_YMM avx2
cglobal pixel_satd_x4_8x4, 4, 4
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 56
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
%endif
    vmovdqu        m9, [hmul_8p]
    lea            r6d, [r5 + r5 * 2]

    vpbroadcastq   m0, [r0]
    vpmaddubsw     m0, m0, m9
    vmovddup       xm1, [r1]
    vmovddup       xm2, [r2]
    vinserti128    m1, m1, xm2, 1
    vmovddup       xm2, [r3]
    vmovddup       xm3, [r4]
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m1, m1, m9
    vpmaddubsw     m2, m2, m9
    vpsubw         m1, m0, m1
    vpsubw         m2, m0, m2
    vpbroadcastq   m0, [r0 + 16]
    vpmaddubsw     m0, m0, m9
    vmovddup       xm3, [r1 + r5]
    vmovddup       xm4, [r2 + r5]
    vinserti128    m3, m3, xm4, 1
    vmovddup       xm4, [r3 + r5]
    vmovddup       xm5, [r4 + r5]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m3, m3, m9
    vpmaddubsw     m4, m4, m9
    vpsubw         m3, m0, m3
    vpsubw         m4, m0, m4
    vpbroadcastq   m0, [r0 + 32]
    vpmaddubsw     m0, m0, m9
    vmovddup       xm5, [r1 + r5 * 2]
    vmovddup       xm6, [r2 + r5 * 2]
    vinserti128    m5, m5, xm6, 1
    vmovddup       xm6, [r3 + r5 * 2]
    vmovddup       xm7, [r4 + r5 * 2]
    vinserti128    m6, m6, xm7, 1
    vpmaddubsw     m5, m5, m9
    vpmaddubsw     m6, m6, m9
    vpsubw         m5, m0, m5
    vpsubw         m6, m0, m6
    vpbroadcastq   m0, [r0 + 48]
    vpmaddubsw     m0, m0, m9
    vmovddup       xm7, [r1 + r6]
    vmovddup       xm8, [r2 + r6]
    vinserti128    m7, m7, xm8, 1
    vmovddup       xm8, [r3 + r6]
    vmovddup       xm10, [r4 + r6]
    vinserti128    m8, m8, xm10, 1
    vpmaddubsw     m7, m7, m9
    vpmaddubsw     m8, m8, m9
    vpsubw         m7, m0, m7
    vpsubw         m8, m0, m8

    vpaddw         m0, m1, m3
    vpsubw         m9, m1, m3
    vpaddw         m1, m5, m7
    vpsubw         m3, m5, m7
    vpaddw         m5, m0, m1
    vpsubw         m7, m0, m1
    vpaddw         m0, m9, m3
    vpsubw         m1, m9, m3
    vpabsw         m5, m5
    vpabsw         m7, m7
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpblendw       m3, m5, m7, 0AAh
    vpblendw       m9, m0, m1, 0AAh
    vpsrld         m5, m5, 16
    vpslld         m7, m7, 16
    vpsrld         m0, m0, 16
    vpslld         m1, m1, 16
    vpor           m5, m5, m7
    vpor           m0, m0, m1
    vpmaxsw        m5, m5, m3
    vpmaxsw        m0, m0, m9
    vpaddw         m0, m0, m5

    vmovdqu        m9, [pw_1]
    vpaddw         m1, m2, m4
    vpsubw         m3, m2, m4
    vpaddw         m2, m6, m8
    vpsubw         m4, m6, m8
    vpaddw         m6, m1, m2
    vpsubw         m8, m1, m2
    vpaddw         m1, m3, m4
    vpsubw         m2, m3, m4
    vpabsw         m6, m6
    vpabsw         m8, m8
    vpabsw         m1, m1
    vpabsw         m2, m2
    vpblendw       m3, m6, m8, 0AAh
    vpblendw       m5, m1, m2, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m8, m8, 16
    vpsrld         m1, m1, 16
    vpslld         m2, m2, 16
    vpor           m6, m6, m8
    vpor           m1, m1, m2
    vpmaxsw        m6, m6, m3
    vpmaxsw        m1, m1, m5
    vpaddw         m6, m6, m1

    vpmaddwd       m0, m0, m9
    vpmaddwd       m1, m6, m9

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    add            rsp, 56
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r6], xm0
    RET


INIT_YMM avx2
cglobal pixel_satd_x4_8xN_internal, 4, 4
    vpbroadcastq   m0, [r0]
    vpmaddubsw     m0, m0, m12
    vmovddup       xm1, [r1]
    vmovddup       xm2, [r2]
    vinserti128    m1, m1, xm2, 1
    vmovddup       xm2, [r3]
    vmovddup       xm3, [r4]
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m1, m1, m12
    vpmaddubsw     m2, m2, m12
    vpsubw         m1, m0, m1
    vpsubw         m2, m0, m2
    vpbroadcastq   m0, [r0 + 16]
    vpmaddubsw     m0, m0, m12
    vmovddup       xm3, [r1 + r5]
    vmovddup       xm4, [r2 + r5]
    vinserti128    m3, m3, xm4, 1
    vmovddup       xm4, [r3 + r5]
    vmovddup       xm5, [r4 + r5]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m3, m3, m12
    vpmaddubsw     m4, m4, m12
    vpsubw         m3, m0, m3
    vpsubw         m4, m0, m4
    vpbroadcastq   m0, [r0 + 32]
    vpmaddubsw     m0, m0, m12
    vmovddup       xm5, [r1 + r5 * 2]
    vmovddup       xm6, [r2 + r5 * 2]
    vinserti128    m5, m5, xm6, 1
    vmovddup       xm6, [r3 + r5 * 2]
    vmovddup       xm7, [r4 + r5 * 2]
    vinserti128    m6, m6, xm7, 1
    vpmaddubsw     m5, m5, m12
    vpmaddubsw     m6, m6, m12
    vpsubw         m5, m0, m5
    vpsubw         m6, m0, m6
    vpbroadcastq   m0, [r0 + 48]
    vpmaddubsw     m0, m0, m12
    vmovddup       xm7, [r1 + r6]
    vmovddup       xm8, [r2 + r6]
    vinserti128    m7, m7, xm8, 1
    vmovddup       xm8, [r3 + r6]
    vmovddup       xm9, [r4 + r6]
    vinserti128    m8, m8, xm9, 1
    vpmaddubsw     m7, m7, m12
    vpmaddubsw     m8, m8, m12
    vpsubw         m7, m0, m7
    vpsubw         m8, m0, m8

    add            r0, 64
    lea            r1, [r1 + r5 * 4]
    lea            r2, [r2 + r5 * 4]
    lea            r3, [r3 + r5 * 4]
    lea            r4, [r4 + r5 * 4]
    vpaddw         m0, m1, m3
    vpsubw         m9, m1, m3
    vpaddw         m1, m5, m7
    vpsubw         m3, m5, m7
    vpaddw         m5, m0, m1
    vpsubw         m7, m0, m1
    vpaddw         m0, m9, m3
    vpsubw         m1, m9, m3
    vpabsw         m5, m5
    vpabsw         m7, m7
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpblendw       m3, m5, m7, 0AAh
    vpblendw       m9, m0, m1, 0AAh
    vpsrld         m5, m5, 16
    vpslld         m7, m7, 16
    vpsrld         m0, m0, 16
    vpslld         m1, m1, 16
    vpor           m5, m5, m7
    vpor           m0, m0, m1
    vpmaxsw        m5, m5, m3
    vpmaxsw        m0, m0, m9
    vpaddw         m0, m0, m5
    vpaddw         m10, m0, m10

    vpaddw         m1, m2, m4
    vpsubw         m3, m2, m4
    vpaddw         m2, m6, m8
    vpsubw         m4, m6, m8
    vpaddw         m6, m1, m2
    vpsubw         m8, m1, m2
    vpaddw         m1, m3, m4
    vpsubw         m2, m3, m4
    vpabsw         m6, m6
    vpabsw         m8, m8
    vpabsw         m1, m1
    vpabsw         m2, m2
    vpblendw       m3, m6, m8, 0AAh
    vpblendw       m5, m1, m2, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m8, m8, 16
    vpsrld         m1, m1, 16
    vpslld         m2, m2, 16
    vpor           m6, m6, m8
    vpor           m1, m1, m2
    vpmaxsw        m6, m6, m3
    vpmaxsw        m1, m1, m5
    vpaddw         m6, m6, m1
    vpaddw         m11, m6, m11
    ret

INIT_YMM avx2
cglobal pixel_satd_x4_8x8, 4, 4
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 88
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
%endif
    vmovdqu        m12, [hmul_8p]
    lea            r6d, [r5 + r5 * 2]
    vpxor          m10, m10, m10
    vpxor          m11, m11, m11
    call           pixel_satd_x4_8xN_internal
    call           pixel_satd_x4_8xN_internal
    vmovdqu        m9, [pw_1]
    vpmaddwd       m0, m10, m9
    vpmaddwd       m1, m11, m9

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    add            rsp, 88
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r6], xm0
    RET

INIT_YMM avx2
cglobal pixel_satd_x4_8x16, 4, 4
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 88
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
%endif
    vmovdqu        m12, [hmul_8p]
    lea            r6d, [r5 + r5 * 2]
    vpxor          m10, m10, m10
    vpxor          m11, m11, m11
    call           pixel_satd_x4_8xN_internal
    call           pixel_satd_x4_8xN_internal
    call           pixel_satd_x4_8xN_internal
    call           pixel_satd_x4_8xN_internal
    vmovdqu        m9, [pw_1]
    vpmaddwd       m0, m10, m9
    vpmaddwd       m1, m11, m9

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    add            rsp, 88
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r6], xm0
    RET


INIT_YMM avx2
cglobal pixel_satd_x4_16xN_internal, 4, 4
    vbroadcasti128 m0, [r0]
    vpmaddubsw     m0, m0, m13
    vbroadcasti128 m1, [r0 + 16]
    vpmaddubsw     m1, m1, m13
    vbroadcasti128 m2, [r0 + 32]
    vpmaddubsw     m2, m2, m13
    vbroadcasti128 m3, [r0 + 48]
    vpmaddubsw     m3, m3, m13
    add            r0, 64

    vbroadcasti128 m4, [r1]
    vpmaddubsw     m4, m4, m13
    vpsubw         m4, m0, m4
    vbroadcasti128 m5, [r1 + r5]
    vpmaddubsw     m5, m5, m13
    vpsubw         m5, m1, m5
    vbroadcasti128 m6, [r1 + r5 * 2]
    vpmaddubsw     m6, m6, m13
    vpsubw         m6, m2, m6
    vbroadcasti128 m7, [r1 + r6]
    vpmaddubsw     m7, m7, m13
    vpsubw         m7, m3, m7

    lea            r1, [r1 + r5 * 4]
    vpaddw         m8, m4, m5
    vpsubw         m9, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m4
    vpsubw         m7, m8, m4
    vpaddw         m8, m9, m5
    vpsubw         m4, m9, m5
    vpabsw         m6, m6
    vpabsw         m7, m7
    vpabsw         m8, m8
    vpabsw         m4, m4
    vpblendw       m9, m6, m7, 0AAh
    vpblendw       m5, m8, m4, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m7, m7, 16
    vpsrld         m8, m8, 16
    vpslld         m4, m4, 16
    vpor           m6, m6, m7
    vpor           m8, m8, m4
    vpmaxsw        m6, m6, m9
    vpmaxsw        m8, m8, m5
    vpaddw         m6, m6, m8
    vpaddw         m10, m6, m10

    vbroadcasti128 m4, [r2]
    vpmaddubsw     m4, m4, m13
    vpsubw         m4, m0, m4
    vbroadcasti128 m5, [r2 + r5]
    vpmaddubsw     m5, m5, m13
    vpsubw         m5, m1, m5
    vbroadcasti128 m6, [r2 + r5 * 2]
    vpmaddubsw     m6, m6, m13
    vpsubw         m6, m2, m6
    vbroadcasti128 m7, [r2 + r6]
    vpmaddubsw     m7, m7, m13
    vpsubw         m7, m3, m7

    lea            r2, [r2 + r5 * 4]
    vpaddw         m8, m4, m5
    vpsubw         m9, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m4
    vpsubw         m7, m8, m4
    vpaddw         m8, m9, m5
    vpsubw         m4, m9, m5
    vpabsw         m6, m6
    vpabsw         m7, m7
    vpabsw         m8, m8
    vpabsw         m4, m4
    vpblendw       m9, m6, m7, 0AAh
    vpblendw       m5, m8, m4, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m7, m7, 16
    vpsrld         m8, m8, 16
    vpslld         m4, m4, 16
    vpor           m6, m6, m7
    vpor           m8, m8, m4
    vpmaxsw        m6, m6, m9
    vpmaxsw        m8, m8, m5
    vpaddw         m6, m6, m8
    vpaddw         m11, m6, m11

    vbroadcasti128 m4, [r3]
    vpmaddubsw     m4, m4, m13
    vpsubw         m4, m0, m4
    vbroadcasti128 m5, [r3 + r5]
    vpmaddubsw     m5, m5, m13
    vpsubw         m5, m1, m5
    vbroadcasti128 m6, [r3 + r5 * 2]
    vpmaddubsw     m6, m6, m13
    vpsubw         m6, m2, m6
    vbroadcasti128 m7, [r3 + r6]
    vpmaddubsw     m7, m7, m13
    vpsubw         m7, m3, m7

    lea            r3, [r3 + r5 * 4]
    vpaddw         m8, m4, m5
    vpsubw         m9, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m4
    vpsubw         m7, m8, m4
    vpaddw         m8, m9, m5
    vpsubw         m4, m9, m5
    vpabsw         m6, m6
    vpabsw         m7, m7
    vpabsw         m8, m8
    vpabsw         m4, m4
    vpblendw       m9, m6, m7, 0AAh
    vpblendw       m5, m8, m4, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m7, m7, 16
    vpsrld         m8, m8, 16
    vpslld         m4, m4, 16
    vpor           m6, m6, m7
    vpor           m8, m8, m4
    vpmaxsw        m6, m6, m9
    vpmaxsw        m8, m8, m5
    vpaddw         m6, m6, m8
    vpaddw         m12, m6, m12

    vbroadcasti128 m4, [r4]
    vpmaddubsw     m4, m4, m13
    vpsubw         m4, m0, m4
    vbroadcasti128 m5, [r4 + r5]
    vpmaddubsw     m5, m5, m13
    vpsubw         m5, m1, m5
    vbroadcasti128 m6, [r4 + r5 * 2]
    vpmaddubsw     m6, m6, m13
    vpsubw         m6, m2, m6
    vbroadcasti128 m7, [r4 + r6]
    vpmaddubsw     m7, m7, m13
    vpsubw         m7, m3, m7

    lea            r4, [r4 + r5 * 4]
    vpaddw         m8, m4, m5
    vpsubw         m9, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m4
    vpsubw         m7, m8, m4
    vpaddw         m8, m9, m5
    vpsubw         m4, m9, m5
    vpabsw         m6, m6
    vpabsw         m7, m7
    vpabsw         m8, m8
    vpabsw         m4, m4
    vpblendw       m9, m6, m7, 0AAh
    vpblendw       m5, m8, m4, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m7, m7, 16
    vpsrld         m8, m8, 16
    vpslld         m4, m4, 16
    vpor           m6, m6, m7
    vpor           m8, m8, m4
    vpmaxsw        m6, m6, m9
    vpmaxsw        m8, m8, m5
    vpaddw         m6, m6, m8
    vpaddw         m14, m6, m14
    ret

INIT_YMM avx2
cglobal pixel_satd_x4_16x8, 4, 4
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 120
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
    vmovdqu        [rsp + 80], xm13
    vmovdqu        [rsp + 96], xm14
%endif
    vmovups        m13, [hmul_16p]
    lea            r6d, [r5 + r5 * 2]
    vpxor          m10, m10, m10
    vpxor          m11, m11, m11
    vpxor          m12, m12, m12
    vpxor          m14, m14, m14
    call           pixel_satd_x4_16xN_internal
    call           pixel_satd_x4_16xN_internal
    vmovdqu        m4, [pw_1]
    vpmaddwd       m0, m10, m4
    vpmaddwd       m1, m11, m4
    vpmaddwd       m2, m12, m4
    vpmaddwd       m3, m14, m4

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    vmovdqu        xm13, [rsp + 80]
    vmovdqu        xm14, [rsp + 96]
    add            rsp, 120
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m2, m2, m3
    vphaddd        m0, m0, m2
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovdqu        [r6], xm0
    RET

INIT_YMM avx2
cglobal pixel_satd_x4_16x16, 4, 4
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 120
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
    vmovdqu        [rsp + 80], xm13
    vmovdqu        [rsp + 96], xm14
%endif
    vmovups        m13, [hmul_16p]
    lea            r6d, [r5 + r5 * 2]
    vpxor          m10, m10, m10
    vpxor          m11, m11, m11
    vpxor          m12, m12, m12
    vpxor          m14, m14, m14
    call           pixel_satd_x4_16xN_internal
    call           pixel_satd_x4_16xN_internal
    call           pixel_satd_x4_16xN_internal
    call           pixel_satd_x4_16xN_internal
    vmovdqu        m4, [pw_1]
    vpmaddwd       m0, m10, m4
    vpmaddwd       m1, m11, m4
    vpmaddwd       m2, m12, m4
    vpmaddwd       m3, m14, m4

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    vmovdqu        xm13, [rsp + 80]
    vmovdqu        xm14, [rsp + 96]
    add            rsp, 120
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m2, m2, m3
    vphaddd        m0, m0, m2
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovdqu        [r6], xm0
    RET


;=============================================================================
; HADAMARD_AC
;=============================================================================
INIT_YMM avx2
cglobal pixel_hadamard_ac_8x8, 4, 4
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 24
    vmovdqu        [rsp], xm8
%endif
    vmovdqu        m6, [hmul_8p]
    lea            r6d, [r1 + r1 * 2]
    lea            r2, [r0 + r1 * 4]
    
    vmovddup       xm0, [r0]
    vmovddup       xm1, [r2]
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m6
    vmovddup       xm1, [r0 + r1]
    vmovddup       xm2, [r2 + r1]
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m6
    vmovddup       xm2, [r0 + r1 * 2]
    vmovddup       xm3, [r2 + r1 * 2]
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m6
    vmovddup       xm3, [r0 + r6]
    vmovddup       xm4, [r2 + r6]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m6

; dc
    vpaddw         m7, m0, m1
    vpaddw         m4, m2, m3
    vpaddw         m7, m7, m4

; sum4 part
    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m5, m2, 16
    vpslld         m6, m3, 16
    vpor           m5, m5, m6
    vpaddw         m6, m1, m5
    vpabsw         m8, m6
    vpsubw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6
    vpblendw       m1, m0, m4, 0AAh
    vpsrld         m5, m0, 16
    vpslld         m6, m4, 16
    vpor           m5, m5, m6
    vpaddw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6
    vpsubw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6

; sum8 part
    vperm2i128     m1, m2, m0, 31h
    vinserti128    m2, m2, xm0, 1
    vpaddw         m0, m1, m2
    vpsubw         m1, m1, m2
    vperm2i128     m2, m3, m4, 31h
    vinserti128    m3, m3, xm4, 1
    vpaddw         m4, m2, m3
    vpsubw         m5, m2, m3
    vshufps        m2, m0, m1, 0DDh
    vshufps        m3, m0, m1, 88h
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vshufps        m2, m4, m5, 0DDh
    vshufps        m3, m4, m5, 88h
    vpaddw         m4, m2, m3
    vpsubw         m5, m2, m3

    vpblendw       m2, m0, m1, 0AAh
    vpsrld         m3, m0, 16
    vpslld         m6, m1, 16
    vpor           m3, m3, m6
    vpaddw         m6, m2, m3
    vpabsw         m6, m6
    vpsubw         m2, m2, m3
    vpabsw         m2, m2
    vpaddw         m6, m6, m2
    vmovdqu        m0, [pw_1]
    vpblendw       m2, m4, m5, 0AAh
    vpsrld         m3, m4, 16
    vpslld         m1, m5, 16
    vpor           m3, m3, m1
    vpaddw         m4, m2, m3
    vpabsw         m4, m4
    vpaddw         m6, m6, m4
    vpsubw         m4, m2, m3
    vpabsw         m4, m4
    vpaddw         m6, m6, m4

    vpmaddwd       m1, m7, m0      ; dc
    vpmaddwd       m2, m8, m0      ; sum4
    vpmaddwd       m3, m6, m0      ; sum8

%if WIN64
    vmovdqu        xm8, [rsp]
    add            rsp, 24
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vmovddup       m1, m1
    vphaddd        m2, m2, m3
    vpsubd         m2, m2, m1
    vphaddd        m2, m2, m2
    vextracti128   xm3, m2, 1
    vpaddd         xm2, xm2, xm3
    vpsrld         xm3, xm2, 1
    vpsrld         xm4, xm2, 2
    vpblendd       xm2, xm3, xm4, 00000010b
    vmovq          rax, xm2
    RET

INIT_YMM avx2
cglobal pixel_hadamard_ac_8x16, 4, 4
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 40
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
%endif
    vmovdqu        m6, [hmul_8p]
    lea            r6d, [r1 + r1 * 2]
    lea            r2, [r0 + r1 * 4]

    vmovddup       xm0, [r0]
    vmovddup       xm1, [r2]
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m6
    vmovddup       xm1, [r0 + r1]
    vmovddup       xm2, [r2 + r1]
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m6
    vmovddup       xm2, [r0 + r1 * 2]
    vmovddup       xm3, [r2 + r1 * 2]
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m6
    vmovddup       xm3, [r0 + r6]
    vmovddup       xm4, [r2 + r6]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m6
    lea            r0, [r0 + r1 * 8]
    lea            r2, [r2 + r1 * 8]

; dc
    vpaddw         m7, m0, m1
    vpaddw         m4, m2, m3
    vpaddw         m7, m7, m4

; sum4 part
    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m5, m2, 16
    vpslld         m6, m3, 16
    vpor           m5, m5, m6
    vpaddw         m6, m1, m5
    vpabsw         m8, m6
    vpsubw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6
    vpblendw       m1, m0, m4, 0AAh
    vpsrld         m5, m0, 16
    vpslld         m6, m4, 16
    vpor           m5, m5, m6
    vpaddw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6
    vpsubw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6

; sum8 part
    vperm2i128     m1, m2, m0, 31h
    vinserti128    m2, m2, xm0, 1
    vpaddw         m0, m1, m2
    vpsubw         m1, m1, m2
    vperm2i128     m2, m3, m4, 31h
    vinserti128    m3, m3, xm4, 1
    vpaddw         m4, m2, m3
    vpsubw         m5, m2, m3
    vshufps        m2, m0, m1, 0DDh
    vshufps        m3, m0, m1, 88h
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vshufps        m2, m4, m5, 0DDh
    vshufps        m3, m4, m5, 88h
    vpaddw         m4, m2, m3
    vpsubw         m5, m2, m3

    vpblendw       m2, m0, m1, 0AAh
    vpsrld         m3, m0, 16
    vpslld         m6, m1, 16
    vpor           m3, m3, m6
    vpaddw         m6, m2, m3
    vpabsw         m9, m6
    vpsubw         m2, m2, m3
    vpabsw         m2, m2
    vpaddw         m9, m9, m2
    vmovdqu        m6, [hmul_8p]
    vpblendw       m2, m4, m5, 0AAh
    vpsrld         m3, m4, 16
    vpslld         m1, m5, 16
    vpor           m3, m3, m1
    vpaddw         m4, m2, m3
    vpabsw         m4, m4
    vpaddw         m9, m9, m4
    vpsubw         m4, m2, m3
    vpabsw         m4, m4
    vpaddw         m9, m9, m4

    vmovddup       xm0, [r0]
    vmovddup       xm1, [r2]
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m6
    vmovddup       xm1, [r0 + r1]
    vmovddup       xm2, [r2 + r1]
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m6
    vmovddup       xm2, [r0 + r1 * 2]
    vmovddup       xm3, [r2 + r1 * 2]
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m6
    vmovddup       xm3, [r0 + r6]
    vmovddup       xm4, [r2 + r6]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m6

; dc
    vpaddw         m4, m0, m1
    vpaddw         m5, m2, m3
    vpaddw         m7, m7, m4
    vpaddw         m7, m7, m5

; sum4 part
    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m5, m2, 16
    vpslld         m6, m3, 16
    vpor           m5, m5, m6
    vpaddw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6
    vpsubw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6
    vpblendw       m1, m0, m4, 0AAh
    vpsrld         m5, m0, 16
    vpslld         m6, m4, 16
    vpor           m5, m5, m6
    vpaddw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6
    vpsubw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6

; sum8 part
    vperm2i128     m1, m2, m0, 31h
    vinserti128    m2, m2, xm0, 1
    vpaddw         m0, m1, m2
    vpsubw         m1, m1, m2
    vperm2i128     m2, m3, m4, 31h
    vinserti128    m3, m3, xm4, 1
    vpaddw         m4, m2, m3
    vpsubw         m5, m2, m3
    vshufps        m2, m0, m1, 0DDh
    vshufps        m3, m0, m1, 88h
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vshufps        m2, m4, m5, 0DDh
    vshufps        m3, m4, m5, 88h
    vpaddw         m4, m2, m3
    vpsubw         m5, m2, m3

    vpblendw       m2, m0, m1, 0AAh
    vpsrld         m3, m0, 16
    vpslld         m6, m1, 16
    vpor           m3, m3, m6
    vpaddw         m6, m2, m3
    vpabsw         m6, m6
    vpaddw         m9, m9, m6
    vpsubw         m2, m2, m3
    vpabsw         m2, m2
    vpaddw         m9, m9, m2
    vmovdqu        m0, [pw_1]
    vpblendw       m2, m4, m5, 0AAh
    vpsrld         m3, m4, 16
    vpslld         m1, m5, 16
    vpor           m3, m3, m1
    vpaddw         m4, m2, m3
    vpabsw         m4, m4
    vpaddw         m9, m9, m4
    vpsubw         m4, m2, m3
    vpabsw         m4, m4
    vpaddw         m9, m9, m4

    vpmaddwd       m1, m7, m0      ; dc
    vpmaddwd       m2, m8, m0      ; sum4
    vpmaddwd       m3, m9, m0      ; sum8

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    add            rsp, 40
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vmovddup       m1, m1
    vphaddd        m2, m2, m3
    vpsubd         m2, m2, m1
    vphaddd        m2, m2, m2
    vextracti128   xm3, m2, 1
    vpaddd         xm2, xm2, xm3
    vpsrld         xm3, xm2, 1
    vpsrld         xm4, xm2, 2
    vpblendd       xm2, xm3, xm4, 00000010b
    vmovq          rax, xm2
    RET

INIT_YMM avx2
cglobal pixel_hadamard_ac_16x8, 4, 4
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 72
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
%endif
    vmovdqu        m8, [hmul_16p]
    lea            r6d, [r1 + r1 * 2]

    vbroadcasti128 m0, [r0]
    vpmaddubsw     m0, m0, m8
    vbroadcasti128 m1, [r0 + r1]
    vpmaddubsw     m1, m1, m8
    vbroadcasti128 m2, [r0 + r1 * 2]
    vpmaddubsw     m2, m2, m8
    vbroadcasti128 m3, [r0 + r6]
    vpmaddubsw     m3, m3, m8
    lea            r0, [r0 + r1 * 4]
    vbroadcasti128 m4, [r0]
    vpmaddubsw     m4, m4, m8
    vbroadcasti128 m5, [r0 + r1]
    vpmaddubsw     m5, m5, m8
    vbroadcasti128 m6, [r0 + r1 * 2]
    vpmaddubsw     m6, m6, m8
    vbroadcasti128 m7, [r0 + r6]
    vpmaddubsw     m7, m7, m8

; dc
    vpaddw         xm8, xm0, xm1
    vpaddw         xm9, xm2, xm3
    vpaddw         xm10, xm4, xm5
    vpaddw         xm11, xm6, xm7
    vpaddw         xm8, xm8, xm9
    vpaddw         xm10, xm10, xm11
    vpaddw         xm10, xm8, xm10

; sum4 part
    vpaddw         m8, m0, m1
    vpsubw         m9, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m0
    vpsubw         m7, m8, m0
    vpaddw         m0, m9, m1
    vpsubw         m8, m9, m1
    vpaddw         m1, m2, m4
    vpsubw         m9, m2, m4
    vpaddw         m2, m3, m5
    vpsubw         m4, m3, m5

    vpblendw       m3, m6, m0, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m0, m0, 16
    vpor           m5, m6, m0
    vpaddw         m6, m3, m5
    vpsubw         m0, m3, m5
    vpabsw         m11, m6
    vpabsw         m3, m0
    vpaddw         m11, m11, m3
    vpblendw       m3, m7, m8, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m8, m8, 16
    vpor           m5, m7, m8
    vpaddw         m7, m3, m5
    vpsubw         m8, m3, m5
    vpabsw         m3, m7
    vpabsw         m5, m8
    vpaddw         m3, m3, m5
    vpaddw         m11, m11, m3
    vpblendw       m3, m1, m2, 0AAh
    vpsrld         m1, m1, 16
    vpslld         m2, m2, 16
    vpor           m5, m1, m2
    vpaddw         m1, m3, m5
    vpsubw         m2, m3, m5
    vpabsw         m3, m1
    vpabsw         m5, m2
    vpaddw         m3, m3, m5
    vpaddw         m11, m11, m3
    vpblendw       m3, m9, m4, 0AAh
    vpsrld         m9, m9, 16
    vpslld         m4, m4, 16
    vpor           m5, m9, m4
    vpaddw         m9, m3, m5
    vpsubw         m4, m3, m5
    vpabsw         m3, m9
    vpabsw         m5, m4
    vpaddw         m3, m3, m5
    vpaddw         m11, m11, m3

; sum8 part
    vpaddw         m3, m6, m1
    vpsubw         m5, m6, m1
    vpaddw         m1, m0, m2
    vpsubw         m6, m0, m2
    vpaddw         m0, m7, m9
    vpsubw         m2, m7, m9
    vpaddw         m7, m8, m4
    vpsubw         m9, m8, m4

    vpblendd       m4, m3, m1, 10101010b
    vpsrlq         m3, m3, 32
    vpsllq         m1, m1, 32
    vpor           m3, m3, m1
    vpaddw         m8, m4, m3
    vpabsw         m8, m8
    vpsubw         m3, m4, m3
    vpabsw         m3, m3
    vpaddw         m8, m8, m3
    vpblendd       m4, m0, m7, 10101010b
    vpsrlq         m0, m0, 32
    vpsllq         m7, m7, 32
    vpor           m0, m0, m7
    vpaddw         m7, m4, m0
    vpabsw         m7, m7
    vpaddw         m8, m8, m7
    vpsubw         m7, m4, m0
    vpabsw         m7, m7
    vpaddw         m8, m8, m7
    vpblendd       m4, m5, m6, 10101010b
    vpsrlq         m5, m5, 32
    vpsllq         m6, m6, 32
    vpor           m5, m5, m6
    vpaddw         m7, m4, m5
    vpabsw         m7, m7
    vpaddw         m8, m8, m7
    vpsubw         m7, m4, m5
    vpabsw         m7, m7
    vpaddw         m8, m8, m7
    vmovdqu        m5, [pw_1]
    vpblendd       m4, m2, m9, 10101010b
    vpsrlq         m2, m2, 32
    vpsllq         m9, m9, 32
    vpor           m2, m2, m9
    vpaddw         m7, m4, m2
    vpabsw         m7, m7
    vpaddw         m8, m8, m7
    vpsubw         m7, m4, m2
    vpabsw         m7, m7
    vpaddw         m8, m8, m7

    vpmaddwd       xm1, xm10, xm5     ; dc
    vpmaddwd       m2, m11, m5        ; sum4
    vpmaddwd       m3, m8, m5         ; sum8

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    add            rsp, 72
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vextracti128   xm4, m2, 1
    vextracti128   xm5, m3, 1
    vpaddd         xm2, xm2, xm4
    vpaddd         xm3, xm3, xm5
    vpsubd         xm2, xm2, xm1
    vpsubd         xm3, xm3, xm1
    vphaddd        xm2, xm2, xm3
    vphaddd        xm2, xm2, xm2
    vpsrld         xm3, xm2, 1
    vpsrld         xm4, xm2, 2
    vpblendd       xm2, xm3, xm4, 00000010b
    vmovq          rax, xm2
    RET

INIT_YMM avx2
cglobal pixel_hadamard_ac_16x16, 4, 4
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 120
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
    vmovdqu        [rsp + 80], xm13
    vmovdqu        [rsp + 96], xm14
%endif
    vmovdqu        m8, [hmul_16p]
    vmovdqu        m13, [pw_1]
    lea            r6d, [r1 + r1 * 2]

    vbroadcasti128 m0, [r0]
    vpmaddubsw     m0, m0, m8
    vbroadcasti128 m1, [r0 + r1]
    vpmaddubsw     m1, m1, m8
    vbroadcasti128 m2, [r0 + r1 * 2]
    vpmaddubsw     m2, m2, m8
    vbroadcasti128 m3, [r0 + r6]
    vpmaddubsw     m3, m3, m8
    lea            r0, [r0 + r1 * 4]
    vbroadcasti128 m4, [r0]
    vpmaddubsw     m4, m4, m8
    vbroadcasti128 m5, [r0 + r1]
    vpmaddubsw     m5, m5, m8
    vbroadcasti128 m6, [r0 + r1 * 2]
    vpmaddubsw     m6, m6, m8
    vbroadcasti128 m7, [r0 + r6]
    vpmaddubsw     m7, m7, m8
    lea            r0, [r0 + r1 * 4]

; dc
    vpaddw         xm8, xm0, xm1
    vpaddw         xm9, xm2, xm3
    vpaddw         xm10, xm4, xm5
    vpaddw         xm11, xm6, xm7
    vpaddw         xm8, xm8, xm9
    vpaddw         xm10, xm10, xm11
    vpaddw         xm10, xm8, xm10

; sum4 part
    vpaddw         m8, m0, m1
    vpsubw         m9, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m0
    vpsubw         m7, m8, m0
    vpaddw         m0, m9, m1
    vpsubw         m8, m9, m1
    vpaddw         m1, m2, m4
    vpsubw         m9, m2, m4
    vpaddw         m2, m3, m5
    vpsubw         m4, m3, m5

    vpblendw       m3, m6, m0, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m0, m0, 16
    vpor           m5, m6, m0
    vpaddw         m6, m3, m5
    vpsubw         m0, m3, m5
    vpabsw         m11, m6
    vpabsw         m3, m0
    vpaddw         m11, m11, m3
    vpblendw       m3, m7, m8, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m8, m8, 16
    vpor           m5, m7, m8
    vpaddw         m7, m3, m5
    vpsubw         m8, m3, m5
    vpabsw         m3, m7
    vpabsw         m5, m8
    vpaddw         m3, m3, m5
    vpaddw         m11, m11, m3
    vpblendw       m3, m1, m2, 0AAh
    vpsrld         m1, m1, 16
    vpslld         m2, m2, 16
    vpor           m5, m1, m2
    vpaddw         m1, m3, m5
    vpsubw         m2, m3, m5
    vpabsw         m3, m1
    vpabsw         m5, m2
    vpaddw         m3, m3, m5
    vpaddw         m11, m11, m3
    vpblendw       m3, m9, m4, 0AAh
    vpsrld         m9, m9, 16
    vpslld         m4, m4, 16
    vpor           m5, m9, m4
    vpaddw         m9, m3, m5
    vpsubw         m4, m3, m5
    vpabsw         m3, m9
    vpabsw         m5, m4
    vpaddw         m3, m3, m5
    vpaddw         m11, m11, m3

; sum8 part
    vpaddw         m3, m6, m1
    vpsubw         m5, m6, m1
    vpaddw         m1, m0, m2
    vpsubw         m6, m0, m2
    vpaddw         m0, m7, m9
    vpsubw         m2, m7, m9
    vpaddw         m7, m8, m4
    vpsubw         m9, m8, m4

    vpblendd       m4, m3, m1, 10101010b
    vpsrlq         m3, m3, 32
    vpsllq         m1, m1, 32
    vpor           m3, m3, m1
    vpaddw         m12, m4, m3
    vpabsw         m12, m12
    vpsubw         m3, m4, m3
    vpabsw         m3, m3
    vpaddw         m12, m12, m3
    vpblendd       m4, m0, m7, 10101010b
    vpsrlq         m0, m0, 32
    vpsllq         m7, m7, 32
    vpor           m0, m0, m7
    vpaddw         m7, m4, m0
    vpabsw         m7, m7
    vpaddw         m12, m12, m7
    vpsubw         m7, m4, m0
    vpabsw         m7, m7
    vpaddw         m12, m12, m7
    vpblendd       m4, m5, m6, 10101010b
    vpsrlq         m5, m5, 32
    vpsllq         m6, m6, 32
    vpor           m5, m5, m6
    vpaddw         m7, m4, m5
    vpabsw         m7, m7
    vpaddw         m12, m12, m7
    vpsubw         m7, m4, m5
    vpabsw         m7, m7
    vpaddw         m12, m12, m7
    vmovdqu        m8, [hmul_16p]
    vpblendd       m4, m2, m9, 10101010b
    vpsrlq         m2, m2, 32
    vpsllq         m9, m9, 32
    vpor           m2, m2, m9
    vpaddw         m7, m4, m2
    vpabsw         m7, m7
    vpaddw         m12, m12, m7
    vpsubw         m7, m4, m2
    vpabsw         m7, m7
    vpaddw         m12, m12, m7

    vpmaddwd       xm10, xm10, xm13     ; dc
    vpmaddwd       m11, m11, m13        ; sum4
    vpmaddwd       m12, m12, m13        ; sum8

    vbroadcasti128 m0, [r0]
    vpmaddubsw     m0, m0, m8
    vbroadcasti128 m1, [r0 + r1]
    vpmaddubsw     m1, m1, m8
    vbroadcasti128 m2, [r0 + r1 * 2]
    vpmaddubsw     m2, m2, m8
    vbroadcasti128 m3, [r0 + r6]
    vpmaddubsw     m3, m3, m8
    lea            r0, [r0 + r1 * 4]
    vbroadcasti128 m4, [r0]
    vpmaddubsw     m4, m4, m8
    vbroadcasti128 m5, [r0 + r1]
    vpmaddubsw     m5, m5, m8
    vbroadcasti128 m6, [r0 + r1 * 2]
    vpmaddubsw     m6, m6, m8
    vbroadcasti128 m7, [r0 + r6]
    vpmaddubsw     m7, m7, m8

; dc
    vpaddw         xm8, xm0, xm1
    vpaddw         xm9, xm2, xm3
    vpaddw         xm8, xm8, xm4
    vpaddw         xm9, xm9, xm5
    vpaddw         xm8, xm8, xm6
    vpaddw         xm9, xm9, xm7
    vpaddw         xm8, xm8, xm9
    vpmaddwd       xm8, xm8, xm13
    vpaddd         xm10, xm8, xm10

; sum4 part
    vpaddw         m8, m0, m1
    vpsubw         m9, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m0
    vpsubw         m7, m8, m0
    vpaddw         m0, m9, m1
    vpsubw         m8, m9, m1
    vpaddw         m1, m2, m4
    vpsubw         m9, m2, m4
    vpaddw         m2, m3, m5
    vpsubw         m4, m3, m5

    vpblendw       m3, m6, m0, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m0, m0, 16
    vpor           m5, m6, m0
    vpaddw         m6, m3, m5
    vpsubw         m0, m3, m5
    vpabsw         m3, m6
    vpabsw         m5, m0
    vpaddw         m14, m3, m5
    vpblendw       m3, m7, m8, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m8, m8, 16
    vpor           m5, m7, m8
    vpaddw         m7, m3, m5
    vpsubw         m8, m3, m5
    vpabsw         m3, m7
    vpabsw         m5, m8
    vpaddw         m3, m3, m5
    vpaddw         m14, m14, m3
    vpblendw       m3, m1, m2, 0AAh
    vpsrld         m1, m1, 16
    vpslld         m2, m2, 16
    vpor           m5, m1, m2
    vpaddw         m1, m3, m5
    vpsubw         m2, m3, m5
    vpabsw         m3, m1
    vpabsw         m5, m2
    vpaddw         m3, m3, m5
    vpaddw         m14, m14, m3
    vpblendw       m3, m9, m4, 0AAh
    vpsrld         m9, m9, 16
    vpslld         m4, m4, 16
    vpor           m5, m9, m4
    vpaddw         m9, m3, m5
    vpsubw         m4, m3, m5
    vpabsw         m3, m9
    vpabsw         m5, m4
    vpaddw         m3, m3, m5
    vpaddw         m14, m14, m3 
    vpmaddwd       m14, m14, m13
    vpaddd         m11, m11, m14

; sum8 part
    vpaddw         m3, m6, m1
    vpsubw         m5, m6, m1
    vpaddw         m1, m0, m2
    vpsubw         m6, m0, m2
    vpaddw         m0, m7, m9
    vpsubw         m2, m7, m9
    vpaddw         m7, m8, m4
    vpsubw         m9, m8, m4

    vpblendd       m4, m3, m1, 10101010b
    vpsrlq         m3, m3, 32
    vpsllq         m1, m1, 32
    vpor           m3, m3, m1
    vpaddw         m8, m4, m3
    vpabsw         m14, m8
    vpsubw         m3, m4, m3
    vpabsw         m3, m3
    vpaddw         m14, m14, m3
    vpblendd       m4, m0, m7, 10101010b
    vpsrlq         m0, m0, 32
    vpsllq         m7, m7, 32
    vpor           m0, m0, m7
    vpaddw         m7, m4, m0
    vpabsw         m7, m7
    vpaddw         m14, m14, m7
    vpsubw         m7, m4, m0
    vpabsw         m7, m7
    vpaddw         m14, m14, m7
    vpblendd       m4, m5, m6, 10101010b
    vpsrlq         m5, m5, 32
    vpsllq         m6, m6, 32
    vpor           m5, m5, m6
    vpaddw         m7, m4, m5
    vpabsw         m7, m7
    vpaddw         m14, m14, m7
    vpsubw         m7, m4, m5
    vpabsw         m7, m7
    vpaddw         m14, m14, m7
    vmovdqu        m5, [pw_1]
    vpblendd       m4, m2, m9, 10101010b
    vpsrlq         m2, m2, 32
    vpsllq         m9, m9, 32
    vpor           m2, m2, m9
    vpaddw         m7, m4, m2
    vpabsw         m7, m7
    vpaddw         m14, m14, m7
    vpsubw         m7, m4, m2
    vpabsw         m7, m7
    vpaddw         m14, m14, m7
    vpmaddwd       m14, m14, m13
    vpaddd         m12, m12, m14

    vextracti128   xm4, m11, 1
    vextracti128   xm5, m12, 1
    vpaddd         xm2, xm11, xm4
    vpaddd         xm3, xm12, xm5
    vpsubd         xm2, xm2, xm10
    vpsubd         xm3, xm3, xm10
    vphaddd        xm2, xm2, xm3
    vphaddd        xm2, xm2, xm2
    vpsrld         xm3, xm2, 1
    vpsrld         xm4, xm2, 2
    vpblendd       xm2, xm3, xm4, 00000010b
    vmovq          rax, xm2
%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    vmovdqu        xm13, [rsp + 80]
    vmovdqu        xm14, [rsp + 96]
    add            rsp, 120
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    RET


;=============================================================================
; SA8D
;=============================================================================
INIT_YMM avx2
cglobal pixel_sa8d_8x8, 4, 4
%if WIN64
    vmovdqu        [rsp + 8], xm6
%endif
    vmovdqu        m6, [hmul_8p]
    lea            r5, [r0 + r1 * 4]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vmovddup       xm0, [r0]
    vmovddup       xm1, [r5]
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m6
    vmovddup       xm1, [r0 + r1]
    vmovddup       xm2, [r5 + r1]
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m6
    vmovddup       xm2, [r0 + r1 * 2]
    vmovddup       xm3, [r5 + r1 * 2]
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m6
    vmovddup       xm3, [r0 + r6]
    vmovddup       xm4, [r5 + r6]
    lea            r5, [r2 + r3 * 4]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m6
    vmovddup       xm4, [r2]
    vmovddup       xm5, [r5]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m0, m0, m4
    vmovddup       xm4, [r2 + r3]
    vmovddup       xm5, [r5 + r3]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m1, m1, m4
    vmovddup       xm4, [r2 + r3 * 2]
    vmovddup       xm5, [r5 + r3 * 2]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m2, m2, m4
    vmovddup       xm4, [r2 + r4]
    vmovddup       xm5, [r5 + r4]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vperm2i128     m1, m2, m0, 31h
    vinserti128    m2, m2, xm0, 1
    vpaddw         m0, m1, m2
    vpsubw         m1, m1, m2
    vperm2i128     m2, m3, m4, 31h
    vinserti128    m3, m3, xm4, 1
    vpaddw         m4, m2, m3
    vpsubw         m5, m2, m3
    vshufps        m2, m0, m1, 0DDh
    vshufps        m3, m0, m1, 88h
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vshufps        m2, m4, m5, 0DDh
    vshufps        m3, m4, m5, 88h
    vpaddw         m4, m2, m3
    vpsubw         m5, m2, m3

    vpblendw       m2, m0, m1, 0AAh
    vpblendw       m3, m4, m5, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m1, m1, 16
    vpsrld         m4, m4, 16
    vpslld         m5, m5, 16
    vpor           m0, m0, m1
    vpor           m4, m4, m5
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpmaxsw        m2, m2, m0
    vpmaxsw        m3, m3, m4
    vpaddw         m2, m2, m3
    vpmaddwd       m2, m2, [pw_1]

%if WIN64
    vmovdqu        xm6, [rsp + 8]
%endif
    vextracti128   xm1, m2, 1
    vpaddd         xm2, xm2, xm1
    vpunpckhqdq    xm5, xm2, xm2
    vpaddd         xm2, xm2, xm5
    vpshufd        xm5, xm2, 1
    vpaddd         xm2, xm2, xm5
    vpxor          xm0, xm0, xm0
    vpavgw         xm2, xm2, xm0
    vmovd          eax, xm2
    RET

INIT_YMM avx2
cglobal pixel_sa8d_16x16, 4, 4
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 56
    vmovdqu        [rsp + 32], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp], xm10
%endif
    vmovdqu        m9, [hmul_16p]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m9
    vpmaddubsw     m1, m1, m9
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m9
    vpmaddubsw     m2, m2, m9
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m9
    vpmaddubsw     m3, m3, m9
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpmaddubsw     m3, m3, m9
    vpmaddubsw     m4, m4, m9
    vpsubw         m3, m3, m4
    vbroadcasti128 m4, [r0]
    vbroadcasti128 m5, [r2]
    vpmaddubsw     m4, m4, m9
    vpmaddubsw     m5, m5, m9
    vpsubw         m4, m4, m5
    vbroadcasti128 m5, [r0 + r1]
    vbroadcasti128 m6, [r2 + r3]
    vpmaddubsw     m5, m5, m9
    vpmaddubsw     m6, m6, m9
    vpsubw         m5, m5, m6
    vbroadcasti128 m6, [r0 + r1 * 2]
    vbroadcasti128 m7, [r2 + r3 * 2]
    vpmaddubsw     m6, m6, m9
    vpmaddubsw     m7, m7, m9
    vpsubw         m6, m6, m7
    vbroadcasti128 m7, [r0 + r6]
    vbroadcasti128 m8, [r2 + r4]
    vpmaddubsw     m7, m7, m9
    vpmaddubsw     m8, m8, m9
    vpsubw         m7, m7, m8

    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpaddw         m8, m0, m1
    vpsubw         m9, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m0
    vpsubw         m7, m8, m0
    vpaddw         m0, m9, m1
    vpsubw         m8, m9, m1
    vpaddw         m1, m2, m4
    vpsubw         m9, m2, m4
    vpaddw         m2, m3, m5
    vpsubw         m4, m3, m5
    vpaddw         m3, m6, m1
    vpsubw         m5, m6, m1
    vpaddw         m1, m0, m2
    vpsubw         m6, m0, m2
    vpaddw         m0, m7, m9
    vpsubw         m2, m7, m9
    vpaddw         m7, m8, m4
    vpsubw         m9, m8, m4

    vshufps        m4, m3, m5, 0DDh
    vshufps        m8, m3, m5, 88h
    vpaddw         m3, m4, m8
    vpsubw         m5, m4, m8
    vshufps        m4, m1, m6, 0DDh
    vshufps        m8, m1, m6, 88h
    vpaddw         m1, m4, m8
    vpsubw         m6, m4, m8
    vshufps        m4, m0, m2, 0DDh
    vshufps        m8, m0, m2, 88h
    vpaddw         m0, m4, m8
    vpsubw         m2, m4, m8
    vshufps        m4, m7, m9, 0DDh
    vshufps        m8, m7, m9, 88h
    vpaddw         m7, m4, m8
    vpsubw         m9, m4, m8

    vpblendw       m4, m3, m5, 0AAh
    vpblendw       m8, m1, m6, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m5, m5, 16
    vpsrld         m1, m1, 16
    vpslld         m6, m6, 16
    vpor           m3, m3, m5
    vpor           m1, m1, m6
    vpabsw         m4, m4
    vpabsw         m8, m8
    vpabsw         m3, m3
    vpabsw         m1, m1
    vpmaxsw        m4, m4, m3
    vpmaxsw        m8, m8, m1
    vpaddw         m10, m4, m8
    vpblendw       m4, m0, m2, 0AAh
    vpblendw       m8, m7, m9, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m2, m2, 16
    vpsrld         m7, m7, 16
    vpslld         m9, m9, 16
    vpor           m0, m0, m2
    vpor           m7, m7, m9
    vpabsw         m4, m4
    vpabsw         m8, m8
    vpabsw         m0, m0
    vpabsw         m7, m7
    vpmaxsw        m4, m4, m0
    vpmaxsw        m8, m8, m7
    vpaddw         m4, m4, m8
    vpaddw         m10, m4, m10

    vmovdqu        m9, [hmul_16p]
    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m9
    vpmaddubsw     m1, m1, m9
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m9
    vpmaddubsw     m2, m2, m9
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m9
    vpmaddubsw     m3, m3, m9
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpmaddubsw     m3, m3, m9
    vpmaddubsw     m4, m4, m9
    vpsubw         m3, m3, m4
    vbroadcasti128 m4, [r0]
    vbroadcasti128 m5, [r2]
    vpmaddubsw     m4, m4, m9
    vpmaddubsw     m5, m5, m9
    vpsubw         m4, m4, m5
    vbroadcasti128 m5, [r0 + r1]
    vbroadcasti128 m6, [r2 + r3]
    vpmaddubsw     m5, m5, m9
    vpmaddubsw     m6, m6, m9
    vpsubw         m5, m5, m6
    vbroadcasti128 m6, [r0 + r1 * 2]
    vbroadcasti128 m7, [r2 + r3 * 2]
    vpmaddubsw     m6, m6, m9
    vpmaddubsw     m7, m7, m9
    vpsubw         m6, m6, m7
    vbroadcasti128 m7, [r0 + r6]
    vbroadcasti128 m8, [r2 + r4]
    vpmaddubsw     m7, m7, m9
    vpmaddubsw     m8, m8, m9
    vpsubw         m7, m7, m8

    vpaddw         m8, m0, m1
    vpsubw         m9, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m0
    vpsubw         m7, m8, m0
    vpaddw         m0, m9, m1
    vpsubw         m8, m9, m1
    vpaddw         m1, m2, m4
    vpsubw         m9, m2, m4
    vpaddw         m2, m3, m5
    vpsubw         m4, m3, m5
    vpaddw         m3, m6, m1
    vpsubw         m5, m6, m1
    vpaddw         m1, m0, m2
    vpsubw         m6, m0, m2
    vpaddw         m0, m7, m9
    vpsubw         m2, m7, m9
    vpaddw         m7, m8, m4
    vpsubw         m9, m8, m4

    vshufps        m4, m3, m5, 0DDh
    vshufps        m8, m3, m5, 88h
    vpaddw         m3, m4, m8
    vpsubw         m5, m4, m8
    vshufps        m4, m1, m6, 0DDh
    vshufps        m8, m1, m6, 88h
    vpaddw         m1, m4, m8
    vpsubw         m6, m4, m8
    vshufps        m4, m0, m2, 0DDh
    vshufps        m8, m0, m2, 88h
    vpaddw         m0, m4, m8
    vpsubw         m2, m4, m8
    vshufps        m4, m7, m9, 0DDh
    vshufps        m8, m7, m9, 88h
    vpaddw         m7, m4, m8
    vpsubw         m9, m4, m8

    vpblendw       m4, m3, m5, 0AAh
    vpblendw       m8, m1, m6, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m5, m5, 16
    vpsrld         m1, m1, 16
    vpslld         m6, m6, 16
    vpor           m3, m3, m5
    vpor           m1, m1, m6
    vpabsw         m4, m4
    vpabsw         m8, m8
    vpabsw         m3, m3
    vpabsw         m1, m1
    vpmaxsw        m4, m4, m3
    vpmaxsw        m8, m8, m1
    vpaddw         m4, m4, m8
    vpaddw         m10, m4, m10
    vpblendw       m4, m0, m2, 0AAh
    vpblendw       m8, m7, m9, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m2, m2, 16
    vpsrld         m7, m7, 16
    vpslld         m9, m9, 16
    vpor           m0, m0, m2
    vpor           m7, m7, m9
    vpabsw         m4, m4
    vpabsw         m8, m8
    vpabsw         m0, m0
    vpabsw         m7, m7
    vpmaxsw        m4, m4, m0
    vpmaxsw        m8, m8, m7
    vpaddw         m4, m4, m8
    vpaddw         m2, m4, m10
    vpmaddwd       m2, m2, [pw_1]

%if WIN64
    vmovdqu        xm10, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm8, [rsp + 32]
    add            rsp, 56
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vextracti128   xm1, m2, 1
    vpaddd         xm2, xm2, xm1
    vpunpckhqdq    xm5, xm2, xm2
    vpaddd         xm2, xm2, xm5
    vpshufd        xm5, xm2, 1
    vpaddd         xm2, xm2, xm5
    vmovd          eax, xm2
    add            eax, 1
    shr            eax, 1
    RET

;=============================================================================
; SA8D_SATD
;=============================================================================
INIT_YMM avx2
cglobal pixel_sa8d_satd_16x16, 4, 4
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 136
    vmovdqu        [rsp + 112], xm8
    vmovdqu        [rsp + 96], xm9
    vmovdqu        [rsp + 80], xm10
    vmovdqu        [rsp + 64], xm11
    vmovdqu        [rsp + 48], xm12
    vmovdqu        [rsp + 32], xm13
    vmovdqu        [rsp + 16], xm14
    vmovdqu        [rsp], xm15
%endif
    vmovdqu        m9, [hmul_16p]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m9
    vpmaddubsw     m1, m1, m9
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m9
    vpmaddubsw     m2, m2, m9
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m9
    vpmaddubsw     m3, m3, m9
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpmaddubsw     m3, m3, m9
    vpmaddubsw     m4, m4, m9
    vpsubw         m3, m3, m4
    vbroadcasti128 m4, [r0]
    vbroadcasti128 m5, [r2]
    vpmaddubsw     m4, m4, m9
    vpmaddubsw     m5, m5, m9
    vpsubw         m4, m4, m5
    vbroadcasti128 m5, [r0 + r1]
    vbroadcasti128 m6, [r2 + r3]
    vpmaddubsw     m5, m5, m9
    vpmaddubsw     m6, m6, m9
    vpsubw         m5, m5, m6
    vbroadcasti128 m6, [r0 + r1 * 2]
    vbroadcasti128 m7, [r2 + r3 * 2]
    vpmaddubsw     m6, m6, m9
    vpmaddubsw     m7, m7, m9
    vpsubw         m6, m6, m7
    vbroadcasti128 m7, [r0 + r6]
    vbroadcasti128 m8, [r2 + r4]
    vpmaddubsw     m7, m7, m9
    vpmaddubsw     m8, m8, m9
    vpsubw         m7, m7, m8

    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpaddw         m8, m0, m1
    vpsubw         m9, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m0
    vpsubw         m7, m8, m0
    vpaddw         m0, m9, m1
    vpsubw         m8, m9, m1
    vpaddw         m1, m2, m4
    vpsubw         m9, m2, m4
    vpaddw         m2, m3, m5
    vpsubw         m4, m3, m5

; satd part
    vpabsw         m3, m6
    vpabsw         m5, m7
    vpabsw         m12, m0
    vpabsw         m13, m8
    vpblendw       m14, m3, m5, 0AAh
    vpblendw       m15, m12, m13, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m5, m5, 16
    vpsrld         m12, m12, 16
    vpslld         m13, m13, 16
    vpor           m3, m3, m5
    vpor           m12, m12, m13
    vpmaxsw        m3, m3, m14
    vpmaxsw        m12, m12, m15
    vpaddw         m11, m3, m12
    vpabsw         m3, m1
    vpabsw         m5, m9
    vpabsw         m12, m2
    vpabsw         m13, m4
    vpblendw       m14, m3, m5, 0AAh
    vpblendw       m15, m12, m13, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m5, m5, 16
    vpsrld         m12, m12, 16
    vpslld         m13, m13, 16
    vpor           m3, m3, m5
    vpor           m12, m12, m13
    vpmaxsw        m3, m3, m14
    vpmaxsw        m12, m12, m15
    vpaddw         m3, m3, m12
    vpaddw         m11, m3, m11

; sa8d part
    vpaddw         m3, m6, m1
    vpsubw         m5, m6, m1
    vpaddw         m1, m0, m2
    vpsubw         m6, m0, m2
    vpaddw         m0, m7, m9
    vpsubw         m2, m7, m9
    vpaddw         m7, m8, m4
    vpsubw         m9, m8, m4

    vshufps        m4, m3, m5, 0DDh
    vshufps        m8, m3, m5, 88h
    vpaddw         m3, m4, m8
    vpsubw         m5, m4, m8
    vshufps        m4, m1, m6, 0DDh
    vshufps        m8, m1, m6, 88h
    vpaddw         m1, m4, m8
    vpsubw         m6, m4, m8
    vshufps        m4, m0, m2, 0DDh
    vshufps        m8, m0, m2, 88h
    vpaddw         m0, m4, m8
    vpsubw         m2, m4, m8
    vshufps        m4, m7, m9, 0DDh
    vshufps        m8, m7, m9, 88h
    vpaddw         m7, m4, m8
    vpsubw         m9, m4, m8

    vpblendw       m4, m3, m5, 0AAh
    vpblendw       m8, m1, m6, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m5, m5, 16
    vpsrld         m1, m1, 16
    vpslld         m6, m6, 16
    vpor           m3, m3, m5
    vpor           m1, m1, m6
    vpabsw         m4, m4
    vpabsw         m8, m8
    vpabsw         m3, m3
    vpabsw         m1, m1
    vpmaxsw        m4, m4, m3
    vpmaxsw        m8, m8, m1
    vpaddw         m10, m4, m8
    vpblendw       m4, m0, m2, 0AAh
    vpblendw       m8, m7, m9, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m2, m2, 16
    vpsrld         m7, m7, 16
    vpslld         m9, m9, 16
    vpor           m0, m0, m2
    vpor           m7, m7, m9
    vpabsw         m4, m4
    vpabsw         m8, m8
    vpabsw         m0, m0
    vpabsw         m7, m7
    vpmaxsw        m4, m4, m0
    vpmaxsw        m8, m8, m7
    vpaddw         m4, m4, m8
    vpaddw         m10, m4, m10

    vmovdqu        m9, [hmul_16p]
    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m9
    vpmaddubsw     m1, m1, m9
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m9
    vpmaddubsw     m2, m2, m9
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m9
    vpmaddubsw     m3, m3, m9
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpmaddubsw     m3, m3, m9
    vpmaddubsw     m4, m4, m9
    vpsubw         m3, m3, m4
    vbroadcasti128 m4, [r0]
    vbroadcasti128 m5, [r2]
    vpmaddubsw     m4, m4, m9
    vpmaddubsw     m5, m5, m9
    vpsubw         m4, m4, m5
    vbroadcasti128 m5, [r0 + r1]
    vbroadcasti128 m6, [r2 + r3]
    vpmaddubsw     m5, m5, m9
    vpmaddubsw     m6, m6, m9
    vpsubw         m5, m5, m6
    vbroadcasti128 m6, [r0 + r1 * 2]
    vbroadcasti128 m7, [r2 + r3 * 2]
    vpmaddubsw     m6, m6, m9
    vpmaddubsw     m7, m7, m9
    vpsubw         m6, m6, m7
    vbroadcasti128 m7, [r0 + r6]
    vbroadcasti128 m8, [r2 + r4]
    vpmaddubsw     m7, m7, m9
    vpmaddubsw     m8, m8, m9
    vpsubw         m7, m7, m8

    vpaddw         m8, m0, m1
    vpsubw         m9, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m0
    vpsubw         m7, m8, m0
    vpaddw         m0, m9, m1
    vpsubw         m8, m9, m1
    vpaddw         m1, m2, m4
    vpsubw         m9, m2, m4
    vpaddw         m2, m3, m5
    vpsubw         m4, m3, m5

; satd part
    vpabsw         m3, m6
    vpabsw         m5, m7
    vpabsw         m12, m0
    vpabsw         m13, m8
    vpblendw       m14, m3, m5, 0AAh
    vpblendw       m15, m12, m13, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m5, m5, 16
    vpsrld         m12, m12, 16
    vpslld         m13, m13, 16
    vpor           m3, m3, m5
    vpor           m12, m12, m13
    vpmaxsw        m3, m3, m14
    vpmaxsw        m12, m12, m15
    vpaddw         m3, m3, m12
    vpaddw         m11, m3, m11
    vpabsw         m3, m1
    vpabsw         m5, m9
    vpabsw         m12, m2
    vpabsw         m13, m4
    vpblendw       m14, m3, m5, 0AAh
    vpblendw       m15, m12, m13, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m5, m5, 16
    vpsrld         m12, m12, 16
    vpslld         m13, m13, 16
    vpor           m3, m3, m5
    vpor           m12, m12, m13
    vpmaxsw        m3, m3, m14
    vpmaxsw        m12, m12, m15
    vpaddw         m3, m3, m12
    vpaddw         m11, m3, m11

; sa8d part
    vpaddw         m3, m6, m1
    vpsubw         m5, m6, m1
    vpaddw         m1, m0, m2
    vpsubw         m6, m0, m2
    vpaddw         m0, m7, m9
    vpsubw         m2, m7, m9
    vpaddw         m7, m8, m4
    vpsubw         m9, m8, m4

    vshufps        m4, m3, m5, 0DDh
    vshufps        m8, m3, m5, 88h
    vpaddw         m3, m4, m8
    vpsubw         m5, m4, m8
    vshufps        m4, m1, m6, 0DDh
    vshufps        m8, m1, m6, 88h
    vpaddw         m1, m4, m8
    vpsubw         m6, m4, m8
    vshufps        m4, m0, m2, 0DDh
    vshufps        m8, m0, m2, 88h
    vpaddw         m0, m4, m8
    vpsubw         m2, m4, m8
    vshufps        m4, m7, m9, 0DDh
    vshufps        m8, m7, m9, 88h
    vpaddw         m7, m4, m8
    vpsubw         m9, m4, m8

    vpblendw       m4, m3, m5, 0AAh
    vpblendw       m8, m1, m6, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m5, m5, 16
    vpsrld         m1, m1, 16
    vpslld         m6, m6, 16
    vpor           m3, m3, m5
    vpor           m1, m1, m6
    vpabsw         m4, m4
    vpabsw         m8, m8
    vpabsw         m3, m3
    vpabsw         m1, m1
    vpmaxsw        m4, m4, m3
    vpmaxsw        m8, m8, m1
    vpaddw         m4, m4, m8
    vpaddw         m10, m4, m10
    vpblendw       m4, m0, m2, 0AAh
    vpblendw       m8, m7, m9, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m2, m2, 16
    vpsrld         m7, m7, 16
    vpslld         m9, m9, 16
    vpor           m0, m0, m2
    vpor           m7, m7, m9
    vpabsw         m4, m4
    vpabsw         m8, m8
    vpabsw         m0, m0
    vpabsw         m7, m7
    vpmaxsw        m4, m4, m0
    vpmaxsw        m8, m8, m7
    vpaddw         m4, m4, m8
    vpaddw         m10, m4, m10
    vmovdqu        m2, [pw_1]
    vpmaddwd       m0, m10, m2       ; sa8d
    vpmaddwd       m1, m11, m2       ; satd

%if WIN64
    vmovdqu        xm15, [rsp]
    vmovdqu        xm14, [rsp + 16]
    vmovdqu        xm13, [rsp + 32]
    vmovdqu        xm12, [rsp + 48]
    vmovdqu        xm11, [rsp + 64]
    vmovdqu        xm10, [rsp + 80]
    vmovdqu        xm9, [rsp + 96]
    vmovdqu        xm8, [rsp + 112]
    add            rsp, 136
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vphaddd        m0, m0, m1
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vpshufd        xm1, xm0, 00110001b
    vpaddd         xm0, xm0, xm1
    vmovd          eax, xm0
    vpextrd        ecx, xm0, 2
    add            eax, 1
    shl            rcx, 32
    shr            eax, 1
    or             rax, rcx
    RET


;=============================================================================
; INTRA_SAD_X9
;=============================================================================
INIT_XMM avx2
cglobal intra_sad_x9_4x4
%if WIN64
    vmovdqu        [rsp + 8], m6
    vmovdqu        [rsp + 24], m7
    vmovdqu        [rsp - 24], m8
%endif
    sub            rsp, 0B0h
    
    vmovdqu        m1, [r1 - 40]
    vpinsrb        m1, m1, [r1 + 95],0
    vpinsrb        m1, m1, [r1 + 63],1
    vpinsrb        m1, m1, [r1 + 31],2
    vpinsrb        m1, m1, [r1 - 1],3        ; l3 l2 l1 l0 __ __ __ lt t0 t1 t2 t3 t4 t5 t6 t7
    vpshufb        m1, m1, [intrax9_edge]    ; l3 l3 l2 l1 l0 lt t0 t1 t2 t3 t4 t5 t6 t7 t7 __
    vpsrldq        m0,m1,1                   ; l3 l2 l1 l0 lt t0 t1 t2 t3 t4 t5 t6 t7 t7 __ __
    vpsrldq        m2,m1,2                   ; l2 l1 l0 lt t0 t1 t2 t3 t4 t5 t6 t7 t7 __ __ __
    vpavgb         m5, m0, m1                ; Gl3 Gl2 Gl1 Gl0 Glt Gt0 Gt1 Gt2 Gt3 Gt4 Gt5  __  __ __ __ __
    vmovdqu        m8, m1
    vpavgb         m4, m1, m2
    vpxor          m2, m2, m1
    vpand          m2, m2, [pb_1]   
    vpsubusb       m4, m4, m2
    vpavgb         m0, m0, m4                ; Fl3 Fl2 Fl1 Fl0 Flt Ft0 Ft1 Ft2 Ft3 Ft4 Ft5 Ft6 Ft7 __ __ __

    ; ddl               ddr
    ; Ft1 Ft2 Ft3 Ft4   Flt Ft0 Ft1 Ft2
    ; Ft2 Ft3 Ft4 Ft5   Fl0 Flt Ft0 Ft1
    ; Ft3 Ft4 Ft5 Ft6   Fl1 Fl0 Flt Ft0
    ; Ft4 Ft5 Ft6 Ft7   Fl2 Fl1 Fl0 Flt
    vpshufb        m2, m0, [intrax9a_ddlr1]  ; a: ddl row0, ddl row1, ddr row0, ddr row1 / b: ddl row0, ddr row0, ddl row1, ddr row1
    vpshufb        m3, m0, [intrax9a_ddlr2]  ; rows 2,3

    ; hd                hu
    ; Glt Flt Ft0 Ft1   Gl0 Fl1 Gl1 Fl2
    ; Gl0 Fl0 Glt Flt   Gl1 Fl2 Gl2 Fl3
    ; Gl1 Fl1 Gl0 Fl0   Gl2 Fl3 Gl3 Gl3
    ; Gl2 Fl2 Gl1 Fl1   Gl3 Gl3 Gl3 Gl3
    vpslldq        m0, m0, 5                 ; ___ ___ ___ ___ ___ Fl3 Fl2 Fl1 Fl0 Flt Ft0 Ft1 Ft2 Ft3 Ft4 Ft5
    vpalignr       m7, m5, m0, 5             ; Fl3 Fl2 Fl1 Fl0 Flt Ft0 Ft1 Ft2 Ft3 Ft4 Ft5 Gl3 Gl2 Gl1 Gl0 Glt
    vpshufb        m6, m7, [intrax9a_hdu1] 
    vpshufb        m7, m7, [intrax9a_hdu2]

    ; vr                vl
    ; Gt0 Gt1 Gt2 Gt3   Gt1 Gt2 Gt3 Gt4
    ; Flt Ft0 Ft1 Ft2   Ft1 Ft2 Ft3 Ft4
    ; Fl0 Gt0 Gt1 Gt2   Gt2 Gt3 Gt4 Gt5
    ; Fl1 Flt Ft0 Ft1   Ft2 Ft3 Ft4 Ft5
    vpsrldq        m5, m5, 5                 ; Gt0 Gt1 Gt2 Gt3 Gt4 Gt5 ...
    vpalignr       m5, m5, m0, 6             ; ___ Fl1 Fl0 Flt Ft0 Ft1 Ft2 Ft3 Ft4 Ft5 Gt0 Gt1 Gt2 Gt3 Gt4 Gt5
    vpshufb        m4, m5, [intrax9a_vrl1]
    vpshufb        m5, m5, [intrax9a_vrl2]

    vmovdqu        [rsp], m2
    vmovdqu        [rsp + 16], m3
    vmovdqu        [rsp + 32], m4
    vmovdqu        [rsp + 48], m5
    vmovdqu        [rsp + 64], m6
    vmovdqu        [rsp + 80], m7

    vmovd          m0, [r0]
    vpinsrd        m0, m0, [r0 + 16], 1
    vmovd          m1, [r0 + 32]
    vpinsrd        m1, m1, [r0 + 48],1
    vpunpcklqdq    m0, m0, m0
    vpunpcklqdq    m1, m1, m1
    vpsadbw        m2, m2, m0
    vpsadbw        m3, m3, m1
    vpsadbw        m4, m4, m0
    vpsadbw        m5, m5, m1
    vpsadbw        m6, m6, m0
    vpsadbw        m7, m7, m1
    vpaddd         m2, m2, m3
    vpaddd         m4, m4, m5
    vpaddd         m6, m6, m7
    vpxor          m7, m7, m7
    vpshufb        m3, m8, [intrax9a_vh1]    ; t0 t1 t2 t3 t0 t1 t2 t3 l0 l0 l0 l0 l1 l1 l1 l1
    vpshufb        m5, m8, [intrax9a_vh2]    ; t0 t1 t2 t3 t0 t1 t2 t3 l2 l2 l2 l2 l3 l3 l3 l3
    vpshufb        m8, m8, [intrax9a_dc]     ; l3 l2 l1 l0 t0 t1 t2 t3 0  0  0  0  0  0  0  0
    vpsadbw        m8, m8, m7
    vpsrlw         m8, m8, 2
    vpavgw         m8, m8, m7
    vpbroadcastb   m8, m8
    vmovdqu        [rsp + 96], m3
    vmovdqu        [rsp + 112], m5
    vmovq          [rsp + 128], m8
    vmovq          [rsp + 144], m8
    vpsadbw        m3, m3, m0
    vpsadbw        m5, m5, m1
    vpaddd         m3, m3, m5
    vpsadbw        m0, m8, m0
    vpsadbw        m1, m8, m1
    vpaddd         m0, m0, m1
    movzx          r3d, word [r2]
    vmovd          r0d, m3
    add            r3d, r0d
    vpunpckhqdq    m3, m3, m0
    vshufps        m3, m3, m2, 88h
    vpsllq         m6, m6, 32
    vpor           m4, m4, m6
    vmovdqu        m0, [r2 + 2]
    vpackssdw      m3, m3, m4
    vpaddw         m0, m0, m3
    vphminposuw    m0, m0                    ; h,dc,ddl,ddr,vr,hd,vl,hu
    vmovd          eax, m0
    add            eax, 10000h
    cmp            ax, r3w
    cmovge         eax, r3d
    mov            r3d, eax
    shr            r3d, 10h
    lea            r2, [intrax9a_lut]
    movzx          r2d, byte [r2 + r3]
    vmovq          m0,  [rsp + r2]
    vmovq          m1,  [rsp + r2 + 16]
    vmovd          [r1], m0
    vmovd          [r1 + 64], m1
    vpsrlq         m0, 32
    vpsrlq         m1, 32
    vmovd          [r1 + 32], m0
    vmovd          [r1 + 96], m1
    add            rsp, 0B0h

%if WIN64 
    vmovdqu        m8, [rsp - 24]
    vmovdqu        m7, [rsp + 24]
    vmovdqu        m6, [rsp + 8]
%endif
    RET

INIT_YMM avx2
cglobal intra_sad_x9_8x8
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    mov            r4, [rsp + 40]
%endif
    mov            rax, rsp
    sub            rsp, 584

    vmovdqu        m5, [r0]
    vmovdqu        m6, [r0 + 64]
    vpunpcklqdq    m5, m5, [r0 + 32]
    vpunpcklqdq    m6, m6, [r0 + 96]

    ; save instruction size: avoid 4-byte memory offsets
    lea            r0, [intra8x9_h1 + 128]       ; intra8x9_vl1
    vpbroadcastq   m0, [r2 + 16]
    vpsadbw        m4, m0, m5
    vpsadbw        m2, m0, m6
    vmovdqu        [rsp], m0
    vmovdqu        [rsp + 32], m0
    vpaddw         m4, m4, m2

    vpbroadcastq   m1, [r2 + 7]
    vpshufb        m3, m1, [r0 - 128]            ; intra8x9_h1 intra8x9_h2
    vpshufb        m2, m1, [r0 - 96]             ; intra8x9_h3 intra8x9_h4
    vmovdqu        [rsp + 64], m3
    vmovdqu        [rsp + 96], m2
    vpsadbw        m3, m3, m5
    vpsadbw        m2, m2, m6
    vpaddw         m3, m3, m2

    lea            r5, [rsp + 256]

    ; combine the first two
    vpslldq        m3, m3, 2
    vpor           m4, m4, m3

    vpxor          m2, m2, m2
    vpsadbw        m0, m0, m2
    vpsadbw        m1, m1, m2
    vpaddw         m0, m0, m1
    vpsrlw         m0, m0, 3
    vpavgw         m0, m0, m2
    vpshufb        m0, m0, m2
    vmovdqu        [r5 - 128], m0
    vmovdqu        [r5 - 96], m0
    vpsadbw        m3, m0, m5
    vpsadbw        m2, m0, m6
    vpaddw         m3, m3, m2

    vpslldq        m3, m3, 4
    vpor           m4, m4, m3

    vbroadcasti128 m0, [r2 + 16]
    vbroadcasti128 m2, [r2 + 17]
    vpslldq        m1, m0, 1
    vpavgb         m3, m0, m2

    vpavgb         m7, m1, m2
    vpxor          m2, m2, m1
    vpand          m2, m2, [pb_1]
    vpsubusb       m7, m7, m2
    vpavgb         m0, m0, m7

    vpshufb        m1, m0, [r0 - 64]             ; intra8x9_ddl1 intra8x9_ddl2
    vpshufb        m2, m0, [r0 - 32]             ; intra8x9_ddl3 intra8x9_ddl4
    vmovdqu        [r5 - 64], m1
    vmovdqu        [r5 - 32], m2
    vpsadbw        m1, m1, m5
    vpsadbw        m2, m2, m6
    vpaddw         m1, m1, m2

    vpslldq        m1, m1, 6
    vpor           m4, m4, m1
    vextracti128   xm1, m4, 1
    vpaddw         xm4, xm4, xm1
    vmovdqu        [r4], xm4

    ; for later
    vinserti128    m7, m3, xm0, 1

    vbroadcasti128 m2, [r2 + 8]
    vbroadcasti128 m0, [r2 + 7]
    vbroadcasti128 m1, [r2 + 6]
    vpavgb         m3, m2, m0

    vpavgb         m4, m1, m2
    vpxor          m2, m2, m1
    vpand          m2, m2, [pb_1]
    vpsubusb       m4, m4, m2
    vpavgb         m0, m0, m4
    vpshufb        m1, m0, [r0 + 64]             ; intra8x9_ddr1 intra8x9_ddr2
    vpshufb        m2, m0, [r0 + 96]             ; intra8x9_ddr3 intra8x9_ddr4
    vmovdqu        [r5], m1
    vmovdqu        [r5 + 32], m2
    vpsadbw        m4, m1, m5
    vpsadbw        m2, m2, m6
    vpaddw         m4, m4, m2

    add            r0, 256
    add            r5, 192
    vpblendd       m2, m3, m0, 11110011b
    vpshufb        m1, m2, [r0 - 128]            ; intra8x9_vr1 intra8x9_vr2
    vpshufb        m2, m2, [r0 - 96]             ; intra8x9_vr3 intra8x9_vr4
    vmovdqu        [r5 - 128], m1
    vmovdqu        [r5 - 96], m2
    vpsadbw        m1, m1, m5
    vpsadbw        m2, m2, m6
    vpaddw         m1, m1, m2

    vpslldq        m1, m1, 2
    vpor           m4, m4, m1

    vpsrldq        m2, m3, 4
    vpblendw       m2, m2, m0, q3330
    vpunpcklbw     m0, m0, m3
    vpshufb        m1, m2, [r0 - 64]             ; intra8x9_hd1 intra8x9_hd2
    vpshufb        m2, m0, [r0 - 32]             ; intra8x9_hd3 intra8x9_hd4
    vmovdqu        [r5 - 64], m1
    vmovdqu        [r5 - 32], m2
    vpsadbw        m1, m1, m5
    vpsadbw        m2, m2, m6
    vpaddw         m1, m1, m2

    vpslldq        m1, m1, 4
    vpor           m4, m4, m1

    vpshufb        m1, m7, [r0 - 256]            ; intra8x9_vl1 intra8x9_vl2
    vpshufb        m2, m7, [r0 - 224]            ; intra8x9_vl3 intra8x9_vl4
    vmovdqu        [r5], m1
    vmovdqu        [r5 + 32], m2
    vpsadbw        m1, m1, m5
    vpsadbw        m2, m2, m6
    vpaddw         m1, m1, m2

    vpslldq        m1, m1, 6
    vpor           m4, m4, m1
    vextracti128   xm1, m4, 1
    vpaddw         xm4, xm4, xm1
    vmovdqu        xm3, [r4]
    vpunpckhqdq    m7, m3, m4
    vpunpcklqdq    m3, m3, m4
    vpaddw         xm3, xm3, xm7

    vpslldq        m1, m0, 1
    vpbroadcastd   m0, [r2 + 7]
    vpalignr       m0, m0, m1, 1
    vpshufb        m1, m0, [r0]                  ; intra8x9_hu1 intra8x9_hu2
    vpshufb        m2, m0, [r0 + 32]             ; intra8x9_hu3 intra8x9_hu4
    vmovdqu        [r5 + 64], m1
    vmovdqu        [r5 + 96], m2
    vpsadbw        m1, m1, m5
    vpsadbw        m2, m2, m6
    vpaddw         m1, m1, m2
    vextracti128   xm2, m1, 1
    vpaddw         xm1, xm1, xm2
    vpunpckhqdq    xm2, xm1, xm1
    vpaddw         xm1, xm1, xm2
    vmovd          r2d, xm1

    vpaddw         xm3, xm3, [r3]
    vmovdqu        [r4], xm3
    add            r2w, [r3 + 16]
    mov            [r4 + 16], r2w

    vphminposuw    xm3, xm3
    vmovd          r3d, xm3
    add            r2d, 80000h
    cmp            r3w, r2w
    cmovg          r3d, r2d

    mov            r2d, r3d
    shr            r3, 16
    shl            r3, 6
    add            r1, 128
    vmovdqu        xm0, [rsp + r3]
    vmovdqu        xm1, [rsp + r3 + 16]
    vmovdqu        xm2, [rsp + r3 + 32]
    vmovdqu        xm3, [rsp + r3 + 48]
    vmovq          [r1 - 128], xm0
    vmovhps        [r1 - 64], xm0
    vmovq          [r1 - 96], xm1
    vmovhps        [r1 - 32], xm1
    vmovq          [r1], xm2
    vmovhps        [r1 + 64], xm2
    vmovq          [r1 + 32], xm3
    vmovhps        [r1 + 96], xm3
    mov            rsp, rax
    mov            eax, r2d
%if WIN64
    vmovdqu        xm7, [rsp + 24]
    vmovdqu        xm6, [rsp + 8]
%endif
    RET


;=============================================================================
; INTRA_SATD/SA8D_X9
;=============================================================================
INIT_XMM avx2
cglobal intra_satd_x9_4x4
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
    sub            rsp, 0A0h
    
    vmovdqu        m1, [r1 - 40]
    vpinsrb        m1, m1, [r1 + 95], 0
    vpinsrb        m1, m1, [r1 + 63], 1
    vpinsrb        m1, m1, [r1 + 31], 2
    vpinsrb        m1, m1, [r1 - 1], 3       ; l3 l2 l1 l0 __ __ __ lt t0 t1 t2 t3 t4 t5 t6 t7

    vpshufb        m1, m1, [intrax9_edge]    ; l3 l3 l2 l1 l0 lt t0 t1 t2 t3 t4 t5 t6 t7 t7 __
    vpsrldq        m0, m1, 1                 ; l3 l2 l1 l0 lt t0 t1 t2 t3 t4 t5 t6 t7 t7 __ __
    vpsrldq        m2, m1, 2                 ; l2 l1 l0 lt t0 t1 t2 t3 t4 t5 t6 t7 t7 __ __ __
    vpavgb         m5, m0, m1                ; Gl3 Gl2 Gl1 Gl0 Glt Gt0 Gt1 Gt2 Gt3 Gt4 Gt5  __  __ __ __ __
    vmovdqu        m15, m1
    vpavgb         m4, m1, m2
    vpxor          m2, m2, m1
    vpand          m2, m2, [pb_1]   
    vpsubusb       m4, m4, m2
    vpavgb         m0, m0, m4                ; Fl3 Fl2 Fl1 Fl0 Flt Ft0 Ft1 Ft2 Ft3 Ft4 Ft5 Ft6 Ft7 __ __ __

    ; ddl               ddr
    ; Ft1 Ft2 Ft3 Ft4   Flt Ft0 Ft1 Ft2
    ; Ft2 Ft3 Ft4 Ft5   Fl0 Flt Ft0 Ft1
    ; Ft3 Ft4 Ft5 Ft6   Fl1 Fl0 Flt Ft0
    ; Ft4 Ft5 Ft6 Ft7   Fl2 Fl1 Fl0 Flt
    vpshufb        m2, m0, [intrax9b_ddlr1]  ; a: ddl row0, ddl row1, ddr row0, ddr row1 / b: ddl row0, ddr row0, ddl row1, ddr row1
    vpshufb        m3, m0, [intrax9b_ddlr2]  ; rows 2,3

    ; hd                hu
    ; Glt Flt Ft0 Ft1   Gl0 Fl1 Gl1 Fl2
    ; Gl0 Fl0 Glt Flt   Gl1 Fl2 Gl2 Fl3
    ; Gl1 Fl1 Gl0 Fl0   Gl2 Fl3 Gl3 Gl3
    ; Gl2 Fl2 Gl1 Fl1   Gl3 Gl3 Gl3 Gl3
    vpslldq        m0, m0, 5                 ; ___ ___ ___ ___ ___ Fl3 Fl2 Fl1 Fl0 Flt Ft0 Ft1 Ft2 Ft3 Ft4 Ft5
    vpalignr       m7, m5, m0, 5             ; Fl3 Fl2 Fl1 Fl0 Flt Ft0 Ft1 Ft2 Ft3 Ft4 Ft5 Gl3 Gl2 Gl1 Gl0 Glt
    vpshufb        m6, m7, [intrax9b_hdu1] 
    vpshufb        m7, m7, [intrax9b_hdu2]

    ; vr                vl
    ; Gt0 Gt1 Gt2 Gt3   Gt1 Gt2 Gt3 Gt4
    ; Flt Ft0 Ft1 Ft2   Ft1 Ft2 Ft3 Ft4
    ; Fl0 Gt0 Gt1 Gt2   Gt2 Gt3 Gt4 Gt5
    ; Fl1 Flt Ft0 Ft1   Ft2 Ft3 Ft4 Ft5
    vpsrldq        m5, m5, 5                 ; Gt0 Gt1 Gt2 Gt3 Gt4 Gt5 ...
    vpalignr       m5, m5, m0, 6             ; ___ Fl1 Fl0 Flt Ft0 Ft1 Ft2 Ft3 Ft4 Ft5 Gt0 Gt1 Gt2 Gt3 Gt4 Gt5
    vpshufb        m4, m5, [intrax9b_vrl1]
    vpshufb        m5, m5, [intrax9b_vrl2]

    vmovdqu        [rsp], m2
    vmovdqu        [rsp + 16], m3
    vmovdqu        [rsp + 32], m4
    vmovdqu        [rsp + 48], m5
    vmovdqu        [rsp + 64], m6
    vmovdqu        [rsp + 80], m7
    vmovd          m8, [r0]
    vmovd          m9, [r0 + 16]
    vmovd          m10, [r0 + 32]
    vmovd          m11, [r0 + 48]
    vmovdqu        m12, [hmul_8p]

    vpshufd        m8, m8, 0
    vpshufd        m9, m9, 0
    vpshufd        m10, m10, 0
    vpshufd        m11, m11, 0
    vpmaddubsw     m8, m8, m12
    vpmaddubsw     m9, m9, m12
    vpmaddubsw     m10, m10, m12
    vpmaddubsw     m11, m11, m12
    vmovddup       m0, m2
    vpshufd        m1, m2, q3232
    vmovddup       m2, m3
    vpunpckhqdq    m3, m3, m3
    call           .satd_8x4                     ; ddr, ddl
    vmovddup       m2, m5
    vpshufd        m3, m5, q3232
    vmovdqu        m5, m0
    vmovddup       m0, m4
    vpshufd        m1, m4, q3232
    call           .satd_8x4                     ; vr, vl
    vmovddup       m2, m7
    vpshufd        m3, m7, q3232
    vmovdqu        m4, m0
    vmovddup       m0, m6
    vpshufd        m1, m6, q3232
    call           .satd_8x4                     ; hd, hu
    vpunpckldq     m4, m4, m0
    vmovdqu        m1, [pw_ppmmppmm]
    vpsignw        m8, m8, m1
    vpsignw        m10, m10, m1
    vpaddw         m8, m8, m9
    vpaddw         m10, m10, m11

    vpshufb        m2, m15, [intrax9b_vh1]
    vpshufb        m3, m15, [intrax9b_vh2]
    vmovdqu        [rsp + 0x60], m2
    vmovdqu        [rsp + 0x70], m3
    vpshufb        m15, m15, [intrax9b_edge2]    ; t0 t1 t2 t3 t0 t1 t2 t3 l0 l1 l2 l3 l0 l1 l2 l3
    vpmaddubsw     m15, m15, [hmul_4p]
    vpshufhw       m0, m15, q2301
    vpshuflw       m0, m0, q2301
    vpsignw        m15, m15, [pw_pmpmpmpm]
    vpaddw         m0, m15, m0
    vpsllw         m0, m0, 2                     ; hadamard(top), hadamard(left)
    vpunpckhqdq    m3, m0, m0
    vpshufb        m1, m0, [intrax9b_v1]
    vpshufb        m2, m0, [intrax9b_v2]
    vpaddw         m0, m0, m3
    vpsignw        m3, m3, [pw_pmmpzzzz]         ; FIXME could this be eliminated?
    vpavgw         m0, m0, [pw_16]
    vpand          m0, m0, [sw_f0]               ; dc

    vpaddw         m6, m8, m10
    vpsubw         m10, m10, m8
    vpsrld         m8, m6, 16
    vpblendw       m8, m8, m10, 0AAh
    vpslld         m10, m10, 16
    vpblendw       m10, m10, m6, 55h
    vpaddw         m6, m8, m10
    vpsubw         m10, m10, m8
    
    vmovd          r3d, m0
    shr            r3d, 4
    imul           r3d, 0x01010101
    mov            [rsp + 0x80], r3d
    mov            [rsp + 0x88], r3d
    mov            [rsp + 0x90], r3d
    mov            [rsp + 0x98], r3d
    vpsubw         m3, m3, m6
    vpsubw         m0, m0, m6
    vpsubw         m1, m1, m6
    vpsubw         m2, m2, m10
    vpabsw         m10, m10
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpabsw         m2, m2
    vpavgw         m3, m10, m3
    vpavgw         m0, m10, m0
    vpavgw         m1, m1, m2
    vphaddw        m3, m3, m0
    vpunpckhqdq    m2, m1, m1
    vpaddw         m1, m1, m2
    vphaddw        m1, m1, m3
    vpmaddwd       m1, m1, [pw_1]                ; v, _, h, dc

    ; find minimum
    vmovdqu        m0, [r2 + 2]
    vmovd          r3d, m1
    vpalignr       m5, m5, m1, 8
    vpackssdw      m5, m5, m4
    vpaddw         m0, m0, m5
    movzx          r0d, word [r2]
    add            r3d, r0d

    vphminposuw    m0, m0                    ; h,dc,ddl,ddr,vr,hd,vl,hu
    vmovd          eax, m0
    add            eax, 10000h
    cmp            ax, r3w
    cmovge         eax, r3d

    ; output the predicted samples
    mov            r3d, eax
    shr            r3d, 10h
    lea            r2, [intrax9b_lut]
    movzx          r2d, byte [r2 + r3]
    mov            r3d, [rsp + r2]
    mov            [r1], r3d
    mov            r3d, [rsp + r2 + 8]
    mov            [r1 + 32], r3d
    mov            r3d, [rsp + r2 + 16]
    mov            [r1 + 64], r3d
    mov            r3d, [rsp + r2 + 24]
    mov            [r1 + 96], r3d
    add            rsp, 0A0h

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

ALIGN 16
.satd_8x4:
    vpmaddubsw     m0, m0, m12
    vpmaddubsw     m1, m1, m12
    vpmaddubsw     m2, m2, m12
    vpmaddubsw     m3, m3, m12
    vpsubw         m0, m0, m8
    vpsubw         m1, m1, m9
    vpsubw         m2, m2, m10
    vpsubw         m3, m3, m11

    vpaddw         m13, m0, m1
    vpsubw         m1, m1, m0
    vpaddw         m0, m2, m3
    vpsubw         m3, m3, m2
    vpaddw         m2, m13, m0
    vpsubw         m0, m0, m13
    vpaddw         m13, m1, m3
    vpsubw         m3, m3, m1
    vpabsw         m2, m2
    vpabsw         m0, m0
    vpabsw         m13, m13
    vpabsw         m3, m3
    vpblendw       m1, m2, m0, 0AAh
    vpslld         m0, m0, 10h
    vpsrld         m2, m2, 10h
    vpor           m0, m0, m2
    vpmaxsw        m1, m1, m0
    vpblendw       m2, m13, m3, 0AAh
    vpslld         m3, m3, 10h
    vpsrld         m13, m13, 10h
    vpor           m3, m13, m3
    vpmaxsw        m2, m2, m3
    vpaddw         m1, m1, m2

    vpmaddwd       m1, [pw_1]
    vpunpckhqdq    m2, m1, m1
    vpaddd         m0, m1, m2
    ret


INIT_XMM avx2
cglobal intra_sa8d_x9_8x8
%if WIN64
    mov            r4, [rsp + 40]
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
    sub            rsp, 2C0h
    vmovdqa        m15, [hmul_8p]
    vpxor          m8, m8, m8

    vmovddup       m0, [r0]
    vpmaddubsw     m9, m0, m15
    vpunpcklbw     m0, m0, m8
    vmovdqa        [rsp], m9
    vmovddup       m1, [r0 + 10h]
    vpmaddubsw     m9, m1, m15
    vpunpcklbw     m1, m1, m8
    vmovdqa        [rsp + 10h], m9
    vmovddup       m2, [r0 + 20h]
    vpmaddubsw     m9, m2, m15
    vpunpcklbw     m2, m2, m8
    vmovdqa        [rsp + 20h], m9
    vmovddup       m3, [r0 + 30h]
    vpmaddubsw     m9, m3, m15
    vpunpcklbw     m3, m3, m8
    vmovdqa        [rsp + 30h], m9
    vmovddup       m4, [r0 + 40h]
    vpmaddubsw     m9, m4, m15
    vpunpcklbw     m4, m4, m8
    vmovdqa        [rsp + 40h], m9
    vmovddup       m5, [r0 + 50h]
    vpmaddubsw     m9, m5, m15
    vpunpcklbw     m5, m5, m8
    vmovdqa        [rsp + 50h], m9
    vmovddup       m6, [r0 + 60h]
    vpmaddubsw     m9, m6, m15
    vpunpcklbw     m6, m6, m8
    vmovdqa        [rsp + 60h], m9
    vmovddup       m7, [r0 + 70h]
    vpmaddubsw     m9, m7, m15
    vpunpcklbw     m7, m7, m8
    vmovdqa        [rsp + 70h], m9

    ; save instruction size: avoid 4-byte memory offsets
    lea            r0, [intra8x9_h1 + 0x80]
    lea            r5, [rsp + 100h]

; v, h, dc
    vpaddw         m8, m0, m1
    vpsubw         m1, m1, m0
    vpaddw         m0, m2, m3
    vpsubw         m3, m3, m2
    vpunpckhwd     m2, m8, m1
    vpunpcklwd     m8, m8, m1
    vpaddw         m1, m8, m2
    vpsubw         m2, m2, m8
    vpunpckhwd     m8, m0, m3
    vpunpcklwd     m0, m0, m3
    vpaddw         m3, m8, m0
    vpsubw         m8, m8, m0
    vpaddw         m0, m4, m5
    vpsubw         m5, m5, m4
    vpaddw         m4, m6, m7
    vpsubw         m7, m7, m6
    vpunpckhwd     m6, m0, m5
    vpunpcklwd     m0, m0, m5
    vpaddw         m5, m0, m6
    vpsubw         m6, m6, m0
    vpunpckhwd     m0, m4, m7
    vpunpcklwd     m4, m4, m7
    vpaddw         m7, m4, m0
    vpsubw         m0, m0, m4
    vpaddw         m4, m1, m3
    vpsubw         m3, m3, m1
    vpaddw         m1, m8, m2
    vpsubw         m8, m8, m2
    vpunpckhdq     m2, m4, m3
    vpunpckldq     m4, m4, m3
    vpaddw         m3, m4, m2
    vpsubw         m2, m2, m4
    vpunpckhdq     m4, m1, m8
    vpunpckldq     m1, m1, m8
    vpaddw         m8, m1, m4
    vpsubw         m4, m4, m1
    vpaddw         m1, m5, m7
    vpsubw         m7, m7, m5
    vpaddw         m5, m6, m0
    vpsubw         m0, m0, m6
    vpunpckhdq     m6, m1, m7
    vpunpckldq     m1, m1, m7
    vpaddw         m7, m1, m6
    vpsubw         m6, m6, m1
    vpunpckhdq     m1, m5, m0
    vpunpckldq     m5, m5, m0
    vpaddw         m0, m5, m1
    vpsubw         m1, m1, m5
    vpaddw         m5, m3, m7
    vpsubw         m7, m7, m3
    vpaddw         m3, m2, m6
    vpsubw         m6, m6, m2
    vpunpckhqdq    m2, m5, m7
    vpunpcklqdq    m5, m5, m7
    vpaddw         m7, m5, m2
    vpsubw         m2, m2, m5
    vpunpckhqdq    m5, m3, m6
    vpunpcklqdq    m3, m3, m6
    vpaddw         m6, m3, m5
    vpsubw         m5, m5, m3
    vpaddw         m3, m8, m0
    vpsubw         m0, m0, m8
    vpaddw         m8, m4, m1
    vpsubw         m1, m1, m4
    vpunpckhqdq    m4, m3, m0
    vpunpcklqdq    m3, m3, m0
    vpaddw         m0, m3, m4
    vpsubw         m4, m4, m3
    vpunpckhqdq    m3, m8, m1
    vpunpcklqdq    m8, m8, m1
    vpaddw         m1, m8, m3
    vpsubw         m3, m3, m8

    vpabsw         m11, m2
    vpabsw         m8, m6
    vpaddw         m11, m11, m8
    vpabsw         m8, m5
    vpaddw         m11, m11, m8
    vpabsw         m8, m0
    vpaddw         m11, m11, m8
    vpabsw         m8, m4
    vpaddw         m11, m11, m8
    vpabsw         m8, m1
    vpaddw         m11, m11, m8
    vpabsw         m8, m3
    vpaddw         m11, m11, m8

    ; 1D hadamard of edges
    vmovq          m8, [r2 + 7]
    vmovddup       m9, [r2 + 16]
    vmovdqa        [r5 - 80h], m9
    vmovdqa        [r5 - 70h], m9
    vmovdqa        [r5 - 60h], m9
    vmovdqa        [r5 - 50h], m9
    vpunpcklwd     m8, m8, m8
    vpshufb        m9, m9, [intrax3_shuf]
    vpmaddubsw     m8, m8, [pb_pppm]
    vpmaddubsw     m9, m9, [pb_pppm]

    vpshufd        m12, m8, 4Eh
    vpshufd        m13, m9, 4Eh
    vpsignw        m8, m8, [pw_ppppmmmm]
    vpsignw        m9, m9, [pw_ppppmmmm]
    vpaddw         m8, m8, m12
    vpaddw         m9, m9, m13

    vpshufd        m12, m8, 0B1h
    vpshufd        m13, m9, 0B1h
    vpsignw        m8, m8, [pw_ppmmppmm]
    vpsignw        m9, m9, [pw_ppmmppmm]
    vpaddw         m8, m8, m12
    vpaddw         m9, m9, m13

    ; dc
    vpaddw         m10, m8, m9
    vpaddw         m10, m10, [pw_8]
    vpand          m10, m10, [sw_f0]
    vpsrlw         m12, m10, 4
    vpsllw         m10, m10, 2
    vpxor          m13, m13, m13
    vpshufb        m12, m12, m13
    vmovdqa        [r5], m12
    vmovdqa        [r5 + 10h], m12
    vmovdqa        [r5 + 20h], m12
    vmovdqa        [r5 + 30h], m12

    ; differences
    vpsllw         m8, m8, 3                     ; left edge
    vpsubw         m8, m8, m7
    vpsubw         m10, m10, m7
    vpabsw         m8, m8                        ; 1x8 sum
    vpabsw         m10, m10
    vpaddw         m8, m8, m11
    vpaddw         m11, m11, m10
    vpunpcklwd     m7, m7, m2
    vpunpcklwd     m6, m6, m5
    vpunpcklwd     m0, m0, m4
    vpunpcklwd     m1, m1, m3
    vpunpckldq     m7, m7, m6
    vpunpckldq     m0, m0, m1
    vpunpcklqdq    m7, m7, m0                    ; transpose
    vpsllw         m9, m9, 3                     ; top edge
    vpsrldq        m10, m11, 2                   ; 8x7 sum
    vpsubw         m7, m7, m9                    ; 8x1 sum
    vpabsw         m7, m7
    vpaddw         m10, m10, m7

    vphaddd        m10, m10, m8                  ; logically phaddw, but this is faster and it won't overflow
    vpsrlw         m11, m11, 1
    vpsrlw         m10, m10, 1

; store h
    vmovq          m5, [r2 + 7]
    vpshufb        m7, m5, [r0 - 80h]
    vpshufb        m2, m5, [r0 - 70h]
    vpshufb        m6, m5, [r0 - 60h]
    vpshufb        m5, m5, [r0 - 50h]
    vmovdqa        [r5 - 40h], m7
    vmovdqa        [r5 - 30h], m2
    vmovdqa        [r5 - 20h], m6
    vmovdqa        [r5 - 10h], m5

; ddl
    vmovdqa        m8, [r2 + 10h]
    vmovdqu        m6, [r2 + 11h]
    vpslldq        m2, m8, 1
    vpavgb         m9, m8, m6

    vpavgb         m5, m2, m6
    vpxor          m6, m6, m2
    vpand          m6, m6, [pb_1]
    vpsubusb       m5, m5, m6
    vpavgb         m8, m8, m5

    vpshufb        m7, m8, [r0 - 40h]
    vpshufb        m2, m8, [r0 - 30h]
    vpshufb        m6, m8, [r0 - 20h]
    vpshufb        m5, m8, [r0 - 10h]
    add            r5, 40h
    call           .sa8d
    vphaddd        m11, m11, m7

; vl
    vpshufb        m7, m9, [r0]
    vpshufb        m2, m8, [r0 + 10h]
    vpshufb        m6, m9, [r0 + 20h]
    vpshufb        m5, m8, [r0 + 30h]
    add            r5, 100h
    call           .sa8d
    vphaddd        m10, m10, m11
    vmovdqa        m12, m7

; ddr
    vmovdqu        m6, [r2 + 8]
    vmovdqu        m8, [r2 + 7]
    vmovdqu        m2, [r2 + 6]
    vpavgb         m9, m8, m6

    vpavgb         m5, m2, m6
    vpxor          m6, m6, m2
    vpand          m6, m6, [pb_1]
    vpsubusb       m5, m5, m6
    vpavgb         m8, m8, m5

    vpshufb        m7, m8, [r0 + 40h]
    vpshufb        m2, m8, [r0 + 50h]
    vpshufb        m6, m8, [r0 + 60h]
    vpshufb        m5, m8, [r0 + 70h]
    sub            r5, 0C0h
    call           .sa8d
    vmovdqa        m11, m7
    add            rcx, 100h

; vr
    vmovsd         m6, m9, m8
    vpshufb        m7, m6, [r0 - 80h]
    vpshufb        m2, m8, [r0 - 70h]
    vpshufb        m6, m6, [r0 - 60h]
    vpshufb        m5, m8, [r0 - 50h]
    add            r5, 40h
    call           .sa8d
    vphaddd        m11, m11, m7

; hd
    vpshufd        m2, m9, q0001
    vpblendw       m2, m2, m8, q3330
    vpunpcklbw     m8, m8, m9
    vpshufb        m7, m2, [r0 - 40h]
    vpshufb        m2, m2, [r0 - 30h]
    vpshufb        m6, m8, [r0 - 20h]
    vpshufb        m5, m8, [r0 - 10h]
    add            r5, 40h
    call           .sa8d
    vphaddd        m7, m7, m12
    vphaddd        m11, m11, m7

; hu
    vpinsrb        m8, m8, [r2 + 7], 15
    vpshufb        m7, m8, [r0]
    vpshufb        m2, m8, [r0 + 10h]
    vpshufb        m6, m8, [r0 + 20h]
    vpshufb        m5, m8, [r0 + 30h]
    add            r5, 0x80
    call           .sa8d

    vpmaddwd       m7, m7, [pw_1]
    vphaddw        m10, m10, m11
    vpunpckhqdq    m2, m7, m7
    vpaddw         m7, m7, m2
    vpshuflw       m2, m7, q0032
    vpavgw         m7, m7, m2
    vpxor          m6, m6, m6
    vpavgw         m10, m10, m6
    vmovd          r2d, m7

    vmovdqu        m7, [r3]
    vpaddw         m7, m10, m7
    vmovdqa        [r4], m7
    movzx          r5d, word [r3 + 10h]
    add            r2d, r5d
    mov            [r4+16], r2w
    
    vphminposuw    m7, m7
    vmovd          eax, m7
    add            r2d, 8<<16
    cmp            ax, r2w
    cmovg          eax, r2d

    mov            r2d, eax
    shr            r2d, 16
    shl            r2d, 6
    add            r1, 128
    vmovdqa        m7, [rsp + r2 + 80h]
    vmovdqa        m2, [rsp + r2 + 90h]
    vmovdqa        m6, [rsp + r2 + 0A0h]
    vmovdqa        m5, [rsp + r2 + 0B0h]
    vmovq          [r1 - 80h], m7
    vmovhps        [r1 - 40h], m7
    vmovq          [r1 - 60h], m2
    vmovhps        [r1 - 20h], m2
    vmovq          [r1], m6
    vmovhps        [r1 + 40h], m6
    vmovq          [r1 + 20h], m5
    vmovhps        [r1 + 60h], m5
    add            rsp, 2C0h

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

ALIGN 16
.sa8d:
    vmovdqa        [r5], m7
    vmovdqa        [r5 + 10h], m2
    vmovdqa        [r5 + 20h], m6
    vmovdqa        [r5 + 30h], m5
    vmovddup       m0, m7
    vmovddup       m4, m2
    vmovddup       m1, m6
    vmovddup       m3, m5
    vpunpckhqdq    m7, m7, m7
    vpunpckhqdq    m2, m2, m2
    vpunpckhqdq    m6, m6, m6
    vpunpckhqdq    m5, m5, m5

    vpmaddubsw     m0, m0, m15
    vpmaddubsw     m4, m4, m15
    vpsubw         m0, m0, [rsp+8]
    vpsubw         m4, m4, [rsp+18h]
    vpmaddubsw     m7, m7, m15
    vpmaddubsw     m2, m2, m15
    vpsubw         m7, m7, [rsp+28h]
    vpsubw         m2, m2, [rsp+38h]
    vpmaddubsw     m1, m1, m15
    vpmaddubsw     m3, m3, m15
    vpsubw         m1, m1, [rsp+48h]
    vpsubw         m3, m3, [rsp+58h]
    vpmaddubsw     m6, m6, m15
    vpmaddubsw     m5, m5, m15
    vpsubw         m6, m6, [rsp+68h]
    vpsubw         m5, m5, [rsp+78h]

    vpaddw         m13, m0, m4
    vpsubw         m4, m4, m0
    vpaddw         m0, m7, m2
    vpsubw         m2, m2, m7
    vpaddw         m7, m13, m0
    vpsubw         m0, m0, m13
    vpaddw         m13, m4, m2
    vpsubw         m2, m2, m4
    vpaddw         m4, m1, m3
    vpsubw         m3, m3, m1
    vpaddw         m1, m6, m5
    vpsubw         m5, m5, m6
    vpaddw         m6, m4, m1
    vpsubw         m1, m1, m4
    vpaddw         m4, m3, m5
    vpsubw         m5, m5, m3
    vpaddw         m3, m7, m6
    vpsubw         m6, m6, m7
    vpaddw         m7, m13, m4
    vpsubw         m4, m4, m13
    vshufps        m13, m3, m6, 0DDh
    vshufps        m3, m3, m6, 88h
    vpaddw         m6, m13, m3
    vpsubw         m13, m13, m3
    vshufps        m3, m7, m4, 0DDh
    vshufps        m7, m7, m4, 88h
    vpaddw         m4, m7, m3
    vpsubw         m3, m3, m7
    vpaddw         m7, m0, m1
    vpsubw         m1, m1, m0
    vpaddw         m0, m2, m5
    vpsubw         m5, m5, m2
    vshufps        m2, m7, m1, 0DDh
    vshufps        m7, m7, m1, 88h
    vpaddw         m1, m7, m2
    vpsubw         m2, m2, m7
    vshufps        m7, m0, m5, 0DDh
    vshufps        m0, m0, m5, 88h
    vpaddw         m5, m0, m7
    vpsubw         m7, m7, m0
    vpblendw       m0, m6, m13, 0AAh
    vpslld         m13, m13, 10h
    vpsrld         m6, m6, 10h
    vpor           m13, m13, m6
    vpabsw         m0, m0
    vpabsw         m13, m13
    vpmaxsw        m0, m13, m0
    vpblendw       m6, m4, m3, 0AAh
    vpslld         m3, m3, 10h
    vpsrld         m4, m4, 10h
    vpor           m3, m3, m4
    vpabsw         m6, m6
    vpabsw         m3, m3
    vpmaxsw        m6, m6, m3
    vpblendw       m4, m1, m2, 0AAh
    vpslld         m2, m2, 10h
    vpsrld         m1, m1, 10h
    vpor           m2, m2, m1
    vpabsw         m4, m4
    vpabsw         m2, m2
    vpmaxsw        m4, m4, m2
    vpblendw       m1, m5, m7, 0AAh
    vpslld         m7, m7, 10h
    vpsrld         m5, m5, 10h
    vpor           m7, m7, m5
    vpabsw         m1, m1
    vpabsw         m7, m7
    vpmaxsw        m1, m1, m7
    
    vpaddw         m0, m0, m6
    vpaddw         m0, m0, m4
    vpaddw         m7, m0, m1
    ret


;=============================================================================
; INTRA SATD
;=============================================================================
INIT_YMM avx2
cglobal intra_satd_x3_4x4, 4, 4
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 24
    vmovdqu        [rsp], xm8
%endif
    vmovdqu        xm4, [intra_satd_4x4_shuf]
    vmovdqu        m7, [hmul_4p]
    vpbroadcastd   xm0, [r1 - 32]
    vmovd          xm1, [r1 + 92]
    vpinsrb        xm1, xm1, [r1 - 1], 0
    vpinsrb        xm1, xm1, [r1 + 31], 1
    vpinsrb        xm1, xm1, [r1 + 63], 2
    vpunpckldq     xm2, xm0, xm1
    vpxor          xm3, xm3, xm3
    vpsadbw        xm2, xm2, xm3
    vpsrlw         xm2, xm2, 2
    vpavgw         xm2, xm2, xm3
    vpbroadcastb   xm2, xm2
    vinserti128    m0, m0, xm2, 1
    vpmaddubsw     m0, m0, m7                       ; v dc
    vpshufb        xm2, xm1, xm4
    vpmaddubsw     xm2, xm2, xm7                    ; h1
    vpsrld         xm1, xm1, 16
    vpshufb        xm1, xm1, xm4
    vpmaddubsw     xm1, xm1, xm7                    ; h2

    vmovd          xm3, [r0]
    vmovd          xm4, [r0 + 16]
    vshufps        xm3, xm3, xm4, 0
    vinserti128    m3, m3, xm3, 1
    vpmaddubsw     m3, m3, m7
    vmovd          xm4, [r0 + 32]
    vmovd          xm5, [r0 + 48]
    vshufps        xm4, xm4, xm5, 0
    vinserti128    m4, m4, xm4, 1
    vpmaddubsw     m4, m4, m7

; v + dc
    vpsubw         m5, m3, m0
    vpsubw         m6, m4, m0
    vpaddw         m7, m5, m6
    vpsubw         m8, m5, m6
    vpunpcklqdq    m5, m7, m8
    vpunpckhqdq    m6, m7, m8
    vpaddw         m7, m5, m6
    vpsubw         m8, m5, m6
    vpblendw       m5, m7, m8, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m8, m8, 16
    vpor           m7, m7, m8
    vpabsw         m5, m5
    vpabsw         m7, m7
    vpmaxsw        m0, m5, m7

; h
    vpsubw         xm5, xm3, xm2
    vpsubw         xm6, xm4, xm1
    vpaddw         xm7, xm5, xm6
    vpsubw         xm8, xm5, xm6
    vpunpcklqdq    xm5, xm7, xm8
    vpunpckhqdq    xm6, xm7, xm8
    vpaddw         xm7, xm5, xm6
    vpsubw         xm8, xm5, xm6
    vpblendw       xm5, xm7, xm8, 0AAh
    vpsrld         xm7, xm7, 16
    vpslld         xm8, xm8, 16
    vpor           xm7, xm7, xm8
    vpabsw         xm5, xm5
    vpabsw         xm7, xm7
    vpmaxsw        xm1, xm5, xm7
    vextracti128   xm2, m0, 1

%if WIN64
    vmovdqu        xm8, [rsp]
    add            rsp, 24
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vpxor          xm3, xm3, xm3
    vphaddw        xm0, xm0, xm1
    vphaddw        xm2, xm2, xm3
    vphaddw        xm0, xm0, xm2
    vpmaddwd       xm0, xm0, [pw_1]
    vmovdqu        [r2], xm0
    RET


INIT_YMM avx2
cglobal intra_satd_x3_8x8c, 4, 4
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
    vmovdqu        m8, [hmul_8p]
    vbroadcasti128 m7, [intra_satd_8x8c_shuf_dc]
    vpbroadcastq   m0, [r1 - 32]                 ; V0 V1
    lea            r6, [r1 + 127]
    vmovd          xm1, [r1 + 92]
    vmovd          xm2, [r6 + 93]
    vpinsrb        xm1, xm1, [r1 - 1], 0
    vpinsrb        xm2, xm2, [r6], 0
    vpinsrb        xm1, xm1, [r1 + 31], 1
    vpinsrb        xm2, xm2, [r6 + 32], 1
    vpinsrb        xm1, xm1, [r1 + 63], 2        ; H0
    vpinsrb        xm2, xm2, [r6 + 64], 2        ; H1
    vpunpckldq     xm3, xm1, xm2                 ; H0 H1
    vpunpcklqdq    xm3, xm0, xm3                 ; V0 V1 H0 H1
    vinserti128    m1, m1, xm2, 1
    vpunpcklbw     m1, m1, m1
    vpunpcklwd     m1, m1, m1                    ; H0 | H1
    vpshufd        xm2, xm3, q1310               ; V0 V1 H1 V1
    vpshufd        xm3, xm3, q3312               ; H0 V1 H1 H1
    vpmovzxbw      m2, xm2
    vpmovzxbw      m3, xm3
    vpxor          m4, m4, m4
    vpsadbw        m2, m2, m4
    vpsadbw        m3, m3, m4
    vpaddw         m2, m2, m3
    vpsrlw         m2, m2, 2
    vpavgw         m2, m2, m4                    ; DC0 DC1 | DC2 DC3
    vpshufb        m2, m2, m7                    ; DC 0 1 0 1 | 2 3 2 3
    vpmaddubsw     m0, m0, m8                    ; V
    vpmaddubsw     m2, m2, m8                    ; DC

    vmovddup       xm3, [r0]
    vmovddup       xm4, [r0 + 64]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m8
    vmovddup       xm4, [r0 + 16]
    vmovddup       xm5, [r0 + 80]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m8
    vmovddup       xm5, [r0 + 32]
    vmovddup       xm6, [r0 + 96]
    vinserti128    m5, m5, xm6, 1
    vpmaddubsw     m5, m5, m8
    vmovddup       xm6, [r0 + 48]
    vmovddup       xm7, [r0 + 112]
    vinserti128    m6, m6, xm7, 1
    vpmaddubsw     m6, m6, m8

; DC
    vpsubw         m7, m2, m3
    vpsubw         m9, m2, m4
    vpsubw         m10, m2, m5
    vpsubw         m2, m2, m6

    vpaddw         m11, m7, m9
    vpsubw         m12, m7, m9
    vpaddw         m7, m10, m2
    vpsubw         m9, m10, m2
    vpaddw         m10, m11, m7
    vpsubw         m2, m11, m7
    vpaddw         m7, m12, m9
    vpsubw         m11, m12, m9
    vpabsw         m10, m10
    vpabsw         m2, m2
    vpabsw         m7, m7
    vpabsw         m11, m11
    vpblendw       m9, m10, m2, 0AAh
    vpsrld         m10, m10, 16
    vpslld         m2, m2, 16
    vpor           m2, m2, m10
    vpmaxsw        m2, m2, m9
    vpblendw       m9, m7, m11, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m11, m11, 16
    vpor           m7, m7, m11
    vpmaxsw        m7, m7, m9
    vpaddw         m2, m2, m7

; V
    vpsubw         m7, m0, m3
    vpsubw         m9, m0, m4
    vpsubw         m10, m0, m5
    vpsubw         m0, m0, m6

    vpaddw         m11, m7, m9
    vpsubw         m12, m7, m9
    vpaddw         m7, m10, m0
    vpsubw         m9, m10, m0
    vpaddw         m10, m11, m7
    vpsubw         m0, m11, m7
    vpaddw         m7, m12, m9
    vpsubw         m11, m12, m9
    vpabsw         m10, m10
    vpabsw         m0, m0
    vpabsw         m7, m7
    vpabsw         m11, m11
    vpblendw       m9, m10, m0, 0AAh
    vpsrld         m10, m10, 16
    vpslld         m0, m0, 16
    vpor           m0, m0, m10
    vpmaxsw        m0, m0, m9
    vpblendw       m9, m7, m11, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m11, m11, 16
    vpor           m7, m7, m11
    vpmaxsw        m7, m7, m9
    vpaddw         m0, m0, m7

; H
    vpshufd        m7, m1, q0000
    vpmaddubsw     m7, m7, m8
    vpsubw         m3, m7, m3
    vpshufd        m7, m1, q1111
    vpmaddubsw     m7, m7, m8
    vpsubw         m4, m7, m4
    vpshufd        m7, m1, q2222
    vpmaddubsw     m7, m7, m8
    vpsubw         m5, m7, m5
    vpshufd        m7, m1, q3333
    vpmaddubsw     m7, m7, m8
    vpsubw         m6, m7, m6

    vpaddw         m7, m3, m4
    vpsubw         m8, m3, m4
    vpaddw         m3, m5, m6
    vpsubw         m4, m5, m6
    vpaddw         m5, m7, m3
    vpsubw         m6, m7, m3
    vpaddw         m3, m8, m4
    vpsubw         m7, m8, m4
    vpabsw         m5, m5
    vpabsw         m6, m6
    vpabsw         m3, m3
    vpabsw         m7, m7
    vpblendw       m4, m5, m6, 0AAh
    vpsrld         m5, m5, 16
    vpslld         m6, m6, 16
    vpor           m5, m5, m6
    vpmaxsw        m5, m5, m4
    vpblendw       m4, m3, m7, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m7, m7, 16
    vpor           m3, m3, m7
    vpmaxsw        m3, m3, m4
    vpaddw         m1, m3, m5

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
    vpxor          m3, m3, m3
    vphaddw        m2, m2, m1
    vphaddw        m0, m0, m3
    vphaddw        m0, m2, m0
    vextracti128   xm1, m0, 1
    vpaddw         xm0, xm0, xm1
    vpmaddwd       xm0, xm0, [pw_1]
    vmovdqu        [r2], xm0
    RET


INIT_YMM avx2
cglobal intra_satd_x3_8x16c, 4, 4
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
    vmovdqu        m8, [hmul_8p]
    vbroadcasti128 m14, [intra_satd_8x8c_shuf_dc]
    vpbroadcastq   m0, [r1 - 32]                 ; V0 V1
    lea            r6, [r1 + 127]
    vmovd          xm1, [r1 + 92]
    vmovd          xm2, [r6 + 93]
    vpinsrb        xm1, xm1, [r1 - 1], 0
    vpinsrb        xm2, xm2, [r6], 0
    vpinsrb        xm1, xm1, [r1 + 31], 1
    vpinsrb        xm2, xm2, [r6 + 32], 1
    vpinsrb        xm1, xm1, [r1 + 63], 2        ; H0
    vpinsrb        xm2, xm2, [r6 + 64], 2        ; H1
    add            r1, 255
    add            r6, 256
    vpunpckldq     xm3, xm1, xm2                 ; H0 H1
    vpunpcklqdq    xm3, xm0, xm3                 ; V0 V1 H0 H1
    vinserti128    m1, m1, xm2, 1
    vpunpcklbw     m1, m1, m1
    vpunpcklwd     m1, m1, m1                    ; H0 | H1
    vpshufd        xm2, xm3, q1310               ; V0 V1 H1 V1
    vpshufd        xm3, xm3, q3312               ; H0 V1 H1 H1
    vpmovzxbw      m2, xm2
    vpmovzxbw      m3, xm3
    vpxor          m4, m4, m4
    vpsadbw        m2, m2, m4
    vpsadbw        m3, m3, m4
    vpaddw         m2, m2, m3
    vpsrlw         m2, m2, 2
    vpavgw         m2, m2, m4                    ; DC0 DC1 | DC2 DC3
    vpshufb        m2, m2, m14                   ; DC 0 1 0 1 | 2 3 2 3
    vpmaddubsw     m0, m0, m8                    ; V
    vpmaddubsw     m2, m2, m8                    ; DC

    vmovddup       xm3, [r0]
    vmovddup       xm4, [r0 + 64]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m8
    vmovddup       xm4, [r0 + 16]
    vmovddup       xm5, [r0 + 80]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m8
    vmovddup       xm5, [r0 + 32]
    vmovddup       xm6, [r0 + 96]
    vinserti128    m5, m5, xm6, 1
    vpmaddubsw     m5, m5, m8
    vmovddup       xm6, [r0 + 48]
    vmovddup       xm7, [r0 + 112]
    vinserti128    m6, m6, xm7, 1
    vpmaddubsw     m6, m6, m8
    add            r0, 128

; DC
    vpsubw         m7, m2, m3
    vpsubw         m9, m2, m4
    vpsubw         m10, m2, m5
    vpsubw         m2, m2, m6

    vpaddw         m11, m7, m9
    vpsubw         m12, m7, m9
    vpaddw         m7, m10, m2
    vpsubw         m9, m10, m2
    vpaddw         m10, m11, m7
    vpsubw         m2, m11, m7
    vpaddw         m7, m12, m9
    vpsubw         m11, m12, m9
    vpabsw         m10, m10
    vpabsw         m2, m2
    vpabsw         m7, m7
    vpabsw         m11, m11
    vpblendw       m9, m10, m2, 0AAh
    vpsrld         m10, m10, 16
    vpslld         m2, m2, 16
    vpor           m2, m2, m10
    vpmaxsw        m2, m2, m9
    vpblendw       m9, m7, m11, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m11, m11, 16
    vpor           m7, m7, m11
    vpmaxsw        m7, m7, m9
    vpaddw         m13, m2, m7

; V
    vpsubw         m7, m0, m3
    vpsubw         m9, m0, m4
    vpsubw         m10, m0, m5
    vpsubw         m2, m0, m6

    vpaddw         m11, m7, m9
    vpsubw         m12, m7, m9
    vpaddw         m7, m10, m2
    vpsubw         m9, m10, m2
    vpaddw         m10, m11, m7
    vpsubw         m2, m11, m7
    vpaddw         m7, m12, m9
    vpsubw         m11, m12, m9
    vpabsw         m10, m10
    vpabsw         m2, m2
    vpabsw         m7, m7
    vpabsw         m11, m11
    vpblendw       m9, m10, m2, 0AAh
    vpsrld         m10, m10, 16
    vpslld         m2, m2, 16
    vpor           m2, m2, m10
    vpmaxsw        m2, m2, m9
    vpblendw       m9, m7, m11, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m11, m11, 16
    vpor           m7, m7, m11
    vpmaxsw        m7, m7, m9
    vpaddw         m15, m2, m7

; H
    vpshufd        m7, m1, q0000
    vpmaddubsw     m7, m7, m8
    vpsubw         m3, m7, m3
    vpshufd        m7, m1, q1111
    vpmaddubsw     m7, m7, m8
    vpsubw         m4, m7, m4
    vpshufd        m7, m1, q2222
    vpmaddubsw     m7, m7, m8
    vpsubw         m5, m7, m5
    vpshufd        m7, m1, q3333
    vpmaddubsw     m7, m7, m8
    vpsubw         m6, m7, m6

    vpaddw         m7, m3, m4
    vpsubw         m9, m3, m4
    vpaddw         m3, m5, m6
    vpsubw         m4, m5, m6
    vpaddw         m5, m7, m3
    vpsubw         m6, m7, m3
    vpaddw         m3, m9, m4
    vpsubw         m7, m9, m4
    vpabsw         m5, m5
    vpabsw         m6, m6
    vpabsw         m3, m3
    vpabsw         m7, m7
    vpblendw       m4, m5, m6, 0AAh
    vpsrld         m5, m5, 16
    vpslld         m6, m6, 16
    vpor           m5, m5, m6
    vpmaxsw        m5, m5, m4
    vpblendw       m4, m3, m7, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m7, m7, 16
    vpor           m3, m3, m7
    vpmaxsw        m3, m3, m4
    vmovdqu        m7, m14
    vpaddw         m14, m3, m5

    vmovd          xm1, [r1 + 93]
    vmovd          xm2, [r6 + 93]
    vpinsrb        xm1, xm1, [r1], 0
    vpinsrb        xm2, xm2, [r6], 0
    vpinsrb        xm1, xm1, [r1 + 32], 1
    vpinsrb        xm2, xm2, [r6 + 32], 1
    vpinsrb        xm1, xm1, [r1 + 64], 2        ; H2
    vpinsrb        xm2, xm2, [r6 + 64], 2        ; H3
    vpunpckldq     xm3, xm1, xm2                 ; H2 H3
    vpunpcklqdq    xm3, xm0, xm3                 ; V0 V1 H2 H3
    vinserti128    m1, m1, xm2, 1
    vpunpcklbw     m1, m1, m1
    vpunpcklwd     m1, m1, m1                    ; H2 | H3
    vpshufd        xm2, xm3, q1312               ; H2 V1 H3 V1
    vpshufd        xm3, xm3, q3322               ; H2 H2 H3 H3
    vpmovzxbw      m2, xm2
    vpmovzxbw      m3, xm3
    vpxor          m4, m4, m4
    vpsadbw        m2, m2, m4
    vpsadbw        m3, m3, m4
    vpaddw         m2, m2, m3
    vpsrlw         m2, m2, 2
    vpavgw         m2, m2, m4                    ; DC4 DC5 | DC6 DC7
    vpshufb        m2, m2, m7                    ; DC 4 5 4 5 | 6 7 6 7
    vpmaddubsw     m2, m2, m8                    ; DC

    vmovddup       xm3, [r0]
    vmovddup       xm4, [r0 + 64]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m8
    vmovddup       xm4, [r0 + 16]
    vmovddup       xm5, [r0 + 80]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m8
    vmovddup       xm5, [r0 + 32]
    vmovddup       xm6, [r0 + 96]
    vinserti128    m5, m5, xm6, 1
    vpmaddubsw     m5, m5, m8
    vmovddup       xm6, [r0 + 48]
    vmovddup       xm7, [r0 + 112]
    vinserti128    m6, m6, xm7, 1
    vpmaddubsw     m6, m6, m8

; DC
    vpsubw         m7, m2, m3
    vpsubw         m9, m2, m4
    vpsubw         m10, m2, m5
    vpsubw         m2, m2, m6

    vpaddw         m11, m7, m9
    vpsubw         m12, m7, m9
    vpaddw         m7, m10, m2
    vpsubw         m9, m10, m2
    vpaddw         m10, m11, m7
    vpsubw         m2, m11, m7
    vpaddw         m7, m12, m9
    vpsubw         m11, m12, m9
    vpabsw         m10, m10
    vpabsw         m2, m2
    vpabsw         m7, m7
    vpabsw         m11, m11
    vpblendw       m9, m10, m2, 0AAh
    vpsrld         m10, m10, 16
    vpslld         m2, m2, 16
    vpor           m2, m2, m10
    vpmaxsw        m2, m2, m9
    vpblendw       m9, m7, m11, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m11, m11, 16
    vpor           m7, m7, m11
    vpmaxsw        m7, m7, m9
    vpaddw         m2, m2, m7
    vpaddw         m2, m2, m13

; V
    vpsubw         m7, m0, m3
    vpsubw         m9, m0, m4
    vpsubw         m10, m0, m5
    vpsubw         m0, m0, m6

    vpaddw         m11, m7, m9
    vpsubw         m12, m7, m9
    vpaddw         m7, m10, m0
    vpsubw         m9, m10, m0
    vpaddw         m10, m11, m7
    vpsubw         m0, m11, m7
    vpaddw         m7, m12, m9
    vpsubw         m11, m12, m9
    vpabsw         m10, m10
    vpabsw         m0, m0
    vpabsw         m7, m7
    vpabsw         m11, m11
    vpblendw       m9, m10, m0, 0AAh
    vpsrld         m10, m10, 16
    vpslld         m0, m0, 16
    vpor           m0, m0, m10
    vpmaxsw        m0, m0, m9
    vpblendw       m9, m7, m11, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m11, m11, 16
    vpor           m7, m7, m11
    vpmaxsw        m7, m7, m9
    vpaddw         m0, m0, m7
    vpaddw         m0, m0, m15

; H
    vpshufd        m7, m1, q0000
    vpmaddubsw     m7, m7, m8
    vpsubw         m3, m7, m3
    vpshufd        m7, m1, q1111
    vpmaddubsw     m7, m7, m8
    vpsubw         m4, m7, m4
    vpshufd        m7, m1, q2222
    vpmaddubsw     m7, m7, m8
    vpsubw         m5, m7, m5
    vpshufd        m7, m1, q3333
    vpmaddubsw     m7, m7, m8
    vpsubw         m6, m7, m6

    vpaddw         m7, m3, m4
    vpsubw         m9, m3, m4
    vpaddw         m3, m5, m6
    vpsubw         m4, m5, m6
    vpaddw         m5, m7, m3
    vpsubw         m6, m7, m3
    vpaddw         m3, m9, m4
    vpsubw         m7, m9, m4
    vpabsw         m5, m5
    vpabsw         m6, m6
    vpabsw         m3, m3
    vpabsw         m7, m7
    vpblendw       m4, m5, m6, 0AAh
    vpsrld         m5, m5, 16
    vpslld         m6, m6, 16
    vpor           m5, m5, m6
    vpmaxsw        m5, m5, m4
    vpblendw       m4, m3, m7, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m7, m7, 16
    vpor           m3, m3, m7
    vpmaxsw        m3, m3, m4
    vpaddw         m3, m3, m5
    vpaddw         m1, m3, m14

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
    vpxor          m3, m3, m3
    vphaddw        m2, m2, m1
    vphaddw        m0, m0, m3
    vphaddw        m0, m2, m0
    vextracti128   xm1, m0, 1
    vpaddw         xm0, xm0, xm1
    vpmaddwd       xm0, xm0, [pw_1]
    vmovdqu        [r2], xm0
    RET


INIT_YMM avx2
cglobal intra_satd_x3_16x16_internal, 4, 4
    vbroadcasti128 m6, [r0]
    vbroadcasti128 m7, [r0 + 16]
    vbroadcasti128 m8, [r0 + 32]
    vbroadcasti128 m9, [r0 + 48]
    add            r0, 64
    vpmaddubsw     m6, m6, m4
    vpmaddubsw     m7, m7, m4
    vpmaddubsw     m8, m8, m4
    vpmaddubsw     m9, m9, m4

; V
    vpsubw         m10, m0, m6
    vpsubw         m11, m0, m7
    vpsubw         m12, m0, m8
    vpsubw         m13, m0, m9

    vpaddw         m3, m10, m11
    vpsubw         m14, m10, m11
    vpaddw         m10, m12, m13
    vpsubw         m11, m12, m13
    vpaddw         m12, m3, m10
    vpsubw         m13, m3, m10
    vpaddw         m3, m14, m11
    vpsubw         m10, m14, m11
    vpabsw         m12, m12
    vpabsw         m13, m13
    vpabsw         m3, m3
    vpabsw         m10, m10
    vpblendw       m11, m12, m13, 0AAh
    vpsrld         m12, m12, 16
    vpslld         m13, m13, 16
    vpor           m12, m12, m13
    vpmaxsw        m14, m11, m12
    vpblendw       m11, m3, m10, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m10, m10, 16
    vpor           m3, m3, m10
    vpmaxsw        m3, m3, m11
    vpaddw         m14, m14, m3
    vpmaddwd       m14, m14, m5
    vpaddd         m15, m15, m14

; H
    vpxor          m14, m14, m14
    vpshufb        m3, m1, m14
    vpmaddubsw     m3, m3, m4
    vpsubw         m10, m3, m6
    vpsrldq        m1, m1, 1
    vpshufb        m3, m1, m14
    vpmaddubsw     m3, m3, m4
    vpsubw         m11, m3, m7
    vpsrldq        m1, m1, 1
    vpshufb        m3, m1, m14
    vpmaddubsw     m3, m3, m4
    vpsubw         m12, m3, m8
    vpsrldq        m1, m1, 1
    vpshufb        m3, m1, m14
    vpmaddubsw     m3, m3, m4
    vpsubw         m13, m3, m9
    vpsrldq        m1, m1, 1

    vpaddw         m3, m10, m11
    vpsubw         m14, m10, m11
    vpaddw         m10, m12, m13
    vpsubw         m11, m12, m13
    vpaddw         m12, m3, m10
    vpsubw         m13, m3, m10
    vpaddw         m3, m14, m11
    vpsubw         m10, m14, m11
    vpabsw         m12, m12
    vpabsw         m13, m13
    vpabsw         m3, m3
    vpabsw         m10, m10
    vpblendw       m11, m12, m13, 0AAh
    vpsrld         m12, m12, 16
    vpslld         m13, m13, 16
    vpor           m12, m12, m13
    vpmaxsw        m14, m11, m12
    vpblendw       m11, m3, m10, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m10, m10, 16
    vpor           m3, m3, m10
    vpmaxsw        m3, m3, m11
    vpaddw         m14, m14, m3
    vpmaddwd       m14, m14, m5
    vpaddd         m14, m14, [rsp + 8]
    vmovdqu        [rsp + 8], m14

; DC
    vpsubw         m10, m2, m6
    vpsubw         m11, m2, m7
    vpsubw         m12, m2, m8
    vpsubw         m13, m2, m9

    vpaddw         m3, m10, m11
    vpsubw         m14, m10, m11
    vpaddw         m10, m12, m13
    vpsubw         m11, m12, m13
    vpaddw         m12, m3, m10
    vpsubw         m13, m3, m10
    vpaddw         m3, m14, m11
    vpsubw         m10, m14, m11
    vpabsw         m12, m12
    vpabsw         m13, m13
    vpabsw         m3, m3
    vpabsw         m10, m10
    vpblendw       m11, m12, m13, 0AAh
    vpsrld         m12, m12, 16
    vpslld         m13, m13, 16
    vpor           m12, m12, m13
    vpmaxsw        m14, m11, m12
    vpblendw       m11, m3, m10, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m10, m10, 16
    vpor           m3, m3, m10
    vpmaxsw        m3, m3, m11
    vpaddw         m14, m14, m3
    vpmaddwd       m14, m14, m5
    vpaddd         m14, m14, [rsp + 40]
    vmovdqu        [rsp + 40], m14
    ret
    

INIT_YMM avx2
cglobal intra_satd_x3_16x16, 4, 4
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
    vmovdqu        m4, [hmul_16p]
    vmovdqu        m5, [pw_1]
    vbroadcasti128 m0, [r1 - 32]                 ; V
    lea            r6, [r1 + 383]
    add            r1, 127
    vmovd          xm1, [r1 - 35]
    vpinsrb        xm1, xm1, [r1 - 128], 0
    vpinsrb        xm1, xm1, [r1 - 96], 1
    vpinsrb        xm1, xm1, [r1 - 64], 2
    vpinsrb        xm1, xm1, [r1], 4
    vpinsrb        xm1, xm1, [r1 + 32], 5
    vpinsrb        xm1, xm1, [r1 + 64], 6
    vpinsrb        xm1, xm1, [r1 + 96], 7
    vpinsrb        xm1, xm1, [r6 - 128], 8
    vpinsrb        xm1, xm1, [r6 - 96], 9
    vpinsrb        xm1, xm1, [r6 - 64], 10
    vpinsrb        xm1, xm1, [r6 - 32], 11
    vpinsrb        xm1, xm1, [r6], 12
    vpinsrb        xm1, xm1, [r6 + 32], 13
    vpinsrb        xm1, xm1, [r6 + 64], 14
    vpinsrb        xm1, xm1, [r6 + 96], 15       ; H
    vpxor          xm6, xm6, xm6
    vpsadbw        xm2, xm0, xm6
    vpsadbw        xm3, xm1, xm6
    vpaddw         xm2, xm2, xm3
    vpunpckhqdq    xm3, xm2, xm2
    vpaddw         xm2, xm2, xm3
    vpsrlw         xm2, xm2, 4
    vpavgw         xm2, xm2, xm6
    vpbroadcastb   m2, xm2                       ; DC
    vinserti128    m1, m1, xm1, 1                ; H
    vpmaddubsw     m0, m0, m4                    ; V
    vpmaddubsw     m2, m2, m4                    ; DC

%if WIN64
    sub            rsp, 64
%else
    sub            rsp, 72
%endif
    vpxor          m6, m6, m6
    vmovdqu        [rsp], m6
    vmovdqu        [rsp + 32], m6
    call           intra_satd_x3_16x16_internal
    call           intra_satd_x3_16x16_internal
    call           intra_satd_x3_16x16_internal
    call           intra_satd_x3_16x16_internal
    vmovdqu        m1, [rsp]
    vmovdqu        m2, [rsp + 32]

    vpxor          m3, m3, m3
    vphaddd        m0, m15, m1
    vphaddd        m2, m2, m3
    vphaddd        m0, m0, m2
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovdqu        [r2], xm0

%if WIN64
    add            rsp, 64
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
%else
    add            rsp, 72
%endif
    RET


;=============================================================================
; INTRA SA8D
;=============================================================================
INIT_YMM avx2
cglobal intra_sa8d_x3_8x8
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
    vpbroadcastq   m0, [r1 + 16]                 ; V
    vpbroadcastq   m1, [r1 + 7]                  ; H
    vmovdqu        m5, [intra_sa8d_8x8_shuf_h]
    vpxor          xm4, xm4, xm4
    vpsadbw        xm2, xm0, xm4
    vpsadbw        xm3, xm1, xm4
    vpaddw         xm2, xm2, xm3
    vpsrlw         xm2, xm2, 3
    vpavgw         xm2, xm2, xm4
    vpbroadcastb   m2, xm2                       ; DC
    vbroadcasti128 m3, [hmul_8p]
    vpmaddubsw     m0, m0, m3                    ; V
    vpmaddubsw     m2, m2, m3                    ; DC
    vpshufb        m11, m1, m5
    vpmaddubsw     m13, m11, m3
    vpsllq         m1, m1, 8
    vpshufb        m11, m1, m5
    vpmaddubsw     m14, m11, m3
    vpsllq         m1, m1, 8
    vpshufb        m11, m1, m5
    vpmaddubsw     m15, m11, m3
    vpsllq         m1, m1, 8
    vpshufb        m11, m1, m5
    vpmaddubsw     m1, m11, m3                   ; H

    vmovddup       xm4, [r0]
    vmovddup       xm5, [r0 + 64]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m3
    vmovddup       xm5, [r0 + 16]
    vmovddup       xm6, [r0 + 80]
    vinserti128    m5, m5, xm6, 1
    vpmaddubsw     m5, m5, m3
    vmovddup       xm6, [r0 + 32]
    vmovddup       xm7, [r0 + 96]
    vinserti128    m6, m6, xm7, 1
    vpmaddubsw     m6, m6, m3
    vmovddup       xm7, [r0 + 48]
    vmovddup       xm8, [r0 + 112]
    vinserti128    m7, m7, xm8, 1
    vpmaddubsw     m7, m7, m3

; V
    vpsubw         m8, m0, m4
    vpsubw         m9, m0, m5
    vpsubw         m10, m0, m6
    vpsubw         m11, m0, m7

    vpaddw         m0, m8, m9
    vpsubw         m12, m8, m9
    vpaddw         m8, m10, m11
    vpsubw         m9, m10, m11
    vpaddw         m10, m0, m8
    vpsubw         m11, m0, m8
    vpaddw         m0, m12, m9
    vpsubw         m8, m12, m9
    vperm2i128     m12, m10, m11, 31h
    vinserti128    m11, m10, xm11, 1
    vpaddw         m10, m12, m11
    vpsubw         m11, m12, m11
    vperm2i128     m12, m0, m8, 31h
    vinserti128    m8, m0, xm8, 1
    vpaddw         m0, m12, m8
    vpsubw         m8, m12, m8
    vshufps        m12, m10, m11, 0DDh
    vshufps        m11, m10, m11, 88h
    vpaddw         m10, m12, m11
    vpsubw         m11, m12, m11
    vshufps        m12, m0, m8, 0DDh
    vshufps        m8, m0, m8, 88h
    vpaddw         m0, m12, m8
    vpsubw         m8, m12, m8

    vpabsw         m10, m10
    vpabsw         m11, m11
    vpabsw         m0, m0
    vpabsw         m8, m8
    vpblendw       m12, m10, m11, 0AAh
    vpsrld         m10, m10, 16
    vpslld         m11, m11, 16
    vpor           m10, m10, m11
    vpmaxsw        m10, m10, m12
    vpblendw       m12, m0, m8, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m8, m8, 16
    vpor           m0, m0, m8
    vpmaxsw        m0, m0, m12
    vpaddw         m0, m0, m10

; H
    vpsubw         m8, m13, m4
    vpsubw         m9, m14, m5
    vpsubw         m10, m15, m6
    vpsubw         m11, m1, m7

    vpaddw         m1, m8, m9
    vpsubw         m12, m8, m9
    vpaddw         m8, m10, m11
    vpsubw         m9, m10, m11
    vpaddw         m10, m1, m8
    vpsubw         m11, m1, m8
    vpaddw         m1, m12, m9
    vpsubw         m8, m12, m9
    vperm2i128     m12, m10, m11, 31h
    vinserti128    m11, m10, xm11, 1
    vpaddw         m10, m12, m11
    vpsubw         m11, m12, m11
    vperm2i128     m12, m1, m8, 31h
    vinserti128    m8, m1, xm8, 1
    vpaddw         m1, m12, m8
    vpsubw         m8, m12, m8
    vshufps        m12, m10, m11, 0DDh
    vshufps        m11, m10, m11, 88h
    vpaddw         m10, m12, m11
    vpsubw         m11, m12, m11
    vshufps        m12, m1, m8, 0DDh
    vshufps        m8, m1, m8, 88h
    vpaddw         m1, m12, m8
    vpsubw         m8, m12, m8

    vpabsw         m10, m10
    vpabsw         m11, m11
    vpabsw         m1, m1
    vpabsw         m8, m8
    vpblendw       m12, m10, m11, 0AAh
    vpsrld         m10, m10, 16
    vpslld         m11, m11, 16
    vpor           m10, m10, m11
    vpmaxsw        m10, m10, m12
    vpblendw       m12, m1, m8, 0AAh
    vpsrld         m1, m1, 16
    vpslld         m8, m8, 16
    vpor           m1, m1, m8
    vpmaxsw        m1, m1, m12
    vpaddw         m1, m1, m10

; DC
    vpsubw         m8, m2, m4
    vpsubw         m9, m2, m5
    vpsubw         m10, m2, m6
    vpsubw         m11, m2, m7

    vpaddw         m2, m8, m9
    vpsubw         m12, m8, m9
    vpaddw         m8, m10, m11
    vpsubw         m9, m10, m11
    vpaddw         m10, m2, m8
    vpsubw         m11, m2, m8
    vpaddw         m2, m12, m9
    vpsubw         m8, m12, m9
    vperm2i128     m12, m10, m11, 31h
    vinserti128    m11, m10, xm11, 1
    vpaddw         m10, m12, m11
    vpsubw         m11, m12, m11
    vperm2i128     m12, m2, m8, 31h
    vinserti128    m8, m2, xm8, 1
    vpaddw         m2, m12, m8
    vpsubw         m8, m12, m8
    vshufps        m12, m10, m11, 0DDh
    vshufps        m11, m10, m11, 88h
    vpaddw         m10, m12, m11
    vpsubw         m11, m12, m11
    vshufps        m12, m2, m8, 0DDh
    vshufps        m8, m2, m8, 88h
    vpaddw         m2, m12, m8
    vpsubw         m8, m12, m8

    vbroadcasti128 m3, [pw_1]
    vpabsw         m10, m10
    vpabsw         m11, m11
    vpabsw         m2, m2
    vpabsw         m8, m8
    vpblendw       m12, m10, m11, 0AAh
    vpsrld         m10, m10, 16
    vpslld         m11, m11, 16
    vpor           m10, m10, m11
    vpmaxsw        m10, m10, m12
    vpblendw       m12, m2, m8, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m8, m8, 16
    vpor           m2, m2, m8
    vpmaxsw        m2, m2, m12
    vpaddw         m2, m2, m10

    vpmaddwd       m0, m0, m3
    vpmaddwd       m1, m1, m3
    vpmaddwd       m2, m2, m3

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
    vphaddd        m0, m0, m1
    vpunpckhqdq    m3, m2, m2
    vpaddd         m2, m2, m3
    vphaddd        m0, m0, m2
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vpxor          m3, m3, m3
    vpavgw         xm0, xm0, xm3
    vmovdqu        [r2], xm0
    RET


;=============================================================================
; SSIM
;=============================================================================
INIT_XMM avx2
cglobal pixel_ssim_4x4x2_core
%if WIN64
    vmovdqu        [rsp + 8], m6
%endif
    vpmovzxbw      m2, [r0]
    vpmovzxbw      m3, [r2]
    lea            r6, [r1 + r1 * 2]
    lea            r5, [r3 + r3 * 2]
    vpmaddwd       m4, m2, m2
    vpmaddwd       m6, m3, m3
    vpmaddwd       m5, m2, m3
    vpaddd         m4, m4, m6
    vpmovzxbw      m0, [r0 + r1]
    vpmovzxbw      m1, [r2 + r3]
    vpaddw         m2, m2, m0
    vpaddw         m3, m3, m1
    vpmaddwd       m6, m0, m1
    vpmaddwd       m0, m0, m0
    vpmaddwd       m1, m1, m1
    vpaddd         m5, m5, m6
    vpaddd         m4, m4, m0
    vpaddd         m4, m4, m1
    vpmovzxbw      m0, [r0 + r1 * 2]
    vpmovzxbw      m1, [r2 + r3 * 2]
    vpaddw         m2, m2, m0
    vpaddw         m3, m3, m1
    vpmaddwd       m6, m0, m1
    vpmaddwd       m0, m0, m0
    vpmaddwd       m1, m1, m1
    vpaddd         m5, m5, m6
    vpaddd         m4, m4, m0
    vpaddd         m4, m4, m1
    vpmovzxbw      m0, [r0 + r6]
    vpmovzxbw      m1, [r2 + r5]
    vpaddw         m2, m2, m0
    vpaddw         m3, m3, m1
    vpmaddwd       m6, m0, m1
    vpmaddwd       m0, m0, m0
    vpmaddwd       m1, m1, m1
    vpaddd         m5, m5, m6
    vpaddd         m4, m4, m0
    vpaddd         m4, m4, m1

%if WIN64
    mov            r6, [rsp + 40]
    vmovdqu        m6, [rsp + 8]
%endif
    vphaddw        m2, m2, m3
    vpmaddwd       m2, m2, [pw_1]
    vphaddd        m4, m4, m5
    vshufps        m0, m2, m4, 88h
    vshufps        m1, m2, m4, 0DDh
%if WIN64
    vmovdqu        [r6], m0
    vmovdqu        [r6 + 16], m1
%else
    vmovdqu        [r4], m0
    vmovdqu        [r4 + 16], m1
%endif
    RET

INIT_XMM avx2
cglobal pixel_ssim_end4
    vmovdqu        m0, [r0]
    vmovdqu        m1, [r0 + 16]
    vmovdqu        m2, [r0 + 32]
    vmovdqu        m3, [r0 + 48]
    vmovdqu        m4, [r0 + 64]
    vpaddd         m0, m0, [r1]
    vpaddd         m1, m1, [r1 + 16]
    vpaddd         m2, m2, [r1 + 32]
    vpaddd         m3, m3, [r1 + 48]
    vpaddd         m4, m4, [r1 + 64]
    vpaddd         m0, m0, m1
    vpaddd         m1, m1, m2
    vpaddd         m2, m2, m3
    vpaddd         m3, m3, m4
    vpunpckhdq     m4, m0, m1
    vpunpckldq     m0, m0, m1
    vpunpckhdq     m1, m2, m3
    vpunpckldq     m2, m2, m3
    vpunpckhqdq    m3, m0, m2
    vpunpcklqdq    m0, m0, m2
    vpunpckhqdq    m2, m4, m1
    vpunpcklqdq    m4, m4, m1
    vpmaddwd       m1, m3, m0
    vpslld         m3, m3, 16
    vpor           m0, m0, m3
    vpmaddwd       m0, m0, m0
    vpslld         m1, m1, 1
    vpslld         m2, m2, 7
    vpslld         m4, m4, 6
    vpsubd         m2, m2, m1
    vpsubd         m4, m4, m0
    vmovdqu        m3, [ssim_c1]
    vpaddd         m0, m0, m3
    vpaddd         m1, m1, m3
    vmovdqu        m3, [ssim_c2]
    vpaddd         m2, m2,m3
    vpaddd         m4, m4, m3
    vcvtdq2ps      m0, m0
    vcvtdq2ps      m1, m1
    vcvtdq2ps      m2, m2
    vcvtdq2ps      m4, m4
    vmulps         m1, m1, m2
    vmulps         m0, m0, m4
    vdivps         m1, m1, m0
    cmp            r2d,4
    je             .skip
    neg            r2
    lea            r3, [mask_ff + 16]
    vandps         m1, m1, [r3 + r2 * 4]
.skip:
    vmovhlps       m0, m0, m1
    vaddps         m0, m0, m1
    vmovshdup      m1, m0
    vaddss         m0, m0, m1
    RET

;=============================================================================
; ASD8
;=============================================================================
INIT_XMM avx2
cglobal pixel_asd8, 4, 4
%if WIN64
    mov            r6d, [rsp + 40]
%endif
    vpxor          m0, m0, m0
    vpxor          m3, m3, m3
    test           r6d, r6d
    jg             .loop
    xor            eax, eax
    ret

ALIGN 16
.loop:
    vmovq          xm1, [r0]
    vpinsrq        xm1, xm1, [r0 + r1], 1
    vmovq          xm2, [r2]
    vpinsrq        xm2, xm2, [r2 + r3], 1
    vpsadbw        m1, m1, m0
    vpsadbw        m2, m2, m0
    vpsubw         m1, m1, m2
    vpaddw         m3, m3, m1
    lea            r0, [r0 + r1 * 2]
    lea            r2, [r2 + r3 * 2]
    sub            r6d, 2
    jg             .loop

.end:
    vpunpckhqdq    xm0, xm3, xm3
    vpaddw         xm0, xm0, xm3
    vpabsw         xm0, xm0
    vmovd          eax, xm0
    ret

;=============================================================================
; Successive Elimination ADS
;=============================================================================
INIT_YMM avx2
cglobal pixel_ads1
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vpbroadcastw   m5, [rsp + 56]
%else
    vpbroadcastw   m5, [rsp + 8]
%endif
    vpbroadcastw   m4, [r0]
    mov            r0d, r5d
    lea            r6, [r4 + r5 + (mmsize-1)]
    and            r6, ~(mmsize-1)
    shl            r2d, 1

ALIGN 16
.upperLoop:
    vmovdqu        m0, [r1]
    vmovdqu        m1, [r1 + 32]
    vpsubw         m0, m0, m4
    vpsubw         m1, m1, m4
    vmovdqu        m2, [r3]
    vmovdqu        m3, [r3 + 32]
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpaddusw       m0, m0, m2
    vpaddusw       m1, m1, m3
    vpsubusw       m2, m5, m0
    vpsubusw       m3, m5, m1
    vpacksswb      m0, m2, m3
    vpermq         m0, m0, 0D8h
    vmovdqu        [r6], m0
    add            r1, 64
    add            r3, 64
    add            r6, 32
    sub            r0d, 32
    jg             .upperLoop

    lea            r6, [r4 + r5 + (mmsize-1)]
    and            r6, ~(mmsize-1)
    vmovdqu        xm3, [pw_8]
    vmovdqu        xm4, [pw_76543210]
    vpxor          xm5, xm5
    add            r5, r6
    xor            r0d, r0d
    mov            [r5], r0d
    lea            r1, [$$]
    %define        GLOBAL +r1-$$

ALIGN 16
.lowerLoop:
    vmovq          xm0, [r6]
    vpcmpeqb       xm0, xm5
    vpmovmskb      r2d, xm0
    xor            r2d, 0FFFFh
    movzx          r3d, byte [r2 + popcnt_table GLOBAL]
    add            r2d, r2d
    vpshufb        xm2, xm4, [r2 * 8 + ads_mvs_shuffle GLOBAL]
    vmovdqu        [r4 + r0 * 2], xm2
    add            r0d, r3d
    vpaddw         xm4, xm3
    add            r6, 8
    cmp            r6, r5
    jl             .lowerLoop

    mov            r6d, r0d
    RET

INIT_YMM avx2
cglobal pixel_ads2
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vpbroadcastw   m3, [rsp + 56]
%else
    vpbroadcastw   m3, [rsp + 8]
%endif
    vpbroadcastw   m5, [r0]
    vpbroadcastw   m4, [r0 + 4]
    mov            r0d, r5d
    lea            r6, [r4 + r5 + (mmsize-1)]
    and            r6, ~(mmsize-1)
    shl            r2d, 1

ALIGN 16
.upperLoop:
    vmovdqu        m0, [r1]
    vmovdqu        m1, [r1 + r2]
    vmovdqu        m2, [r3]
    vpsubw         m0, m0, m5
    vpsubw         m1, m1, m4
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpaddw         m0, m0, m1
    vpaddusw       m0, m0, m2
    vpsubusw       m1, m3, m0
    vpacksswb      m1, m1, m1
    vpermq         m1, m1, 0D8h
    vmovdqu        [r6], m1
    add            r1, 32
    add            r3, 32
    add            r6, 16
    sub            r0d, 16
    jg             .upperLoop

    lea            r6, [r4 + r5 + (mmsize-1)]
    and            r6, ~(mmsize-1)
    vmovdqu        xm3, [pw_8]
    vmovdqu        xm4, [pw_76543210]
    vpxor          xm5, xm5
    add            r5, r6
    xor            r0d, r0d
    mov            [r5], r0d
    lea            r1, [$$]
    %define        GLOBAL +r1-$$

ALIGN 16
.lowerLoop:
    vmovq          xm0, [r6]
    vpcmpeqb       xm0, xm5
    vpmovmskb      r2d, xm0
    xor            r2d, 0FFFFh
    movzx          r3d, byte [r2 + popcnt_table GLOBAL]
    add            r2d, r2d
    vpshufb        xm2, xm4, [r2 * 8 + ads_mvs_shuffle GLOBAL]
    vmovdqu        [r4 + r0 * 2], xm2
    add            r0d, r3d
    vpaddw         xm4, xm3
    add            r6, 8
    cmp            r6, r5
    jl             .lowerLoop

    mov            r6d, r0d
    RET

INIT_YMM avx2
cglobal pixel_ads4
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vpbroadcastw   m3, [rsp + 56]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
%else
    vpbroadcastw   m3, [rsp + 8]
%endif
    vpbroadcastw   m7, [r0]
    vpbroadcastw   m6, [r0 + 4]
    vpbroadcastw   m5, [r0 + 8]
    vpbroadcastw   m4, [r0 + 12]
    mov            r0d, r5d
    lea            r6, [r4 + r5 + (mmsize-1)]
    and            r6, ~(mmsize-1)
    shl            r2d, 1

ALIGN 16
.upperLoop:
    vmovdqu        m0, [r1]
    vmovdqu        m1, [r1 + 16]
    vpsubw         m0, m0, m7
    vpsubw         m1, m1, m6
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpaddw         m0, m0, m1
    vmovdqu        m1, [r1 + r2]
    vmovdqu        m2, [r1 + r2 + 16]
    vpsubw         m1, m1, m5
    vpsubw         m2, m2, m4
    vpabsw         m1, m1
    vpabsw         m2, m2
    vpaddw         m0, m0, m1
    vpaddw         m0, m0, m2
    vmovdqu        m2, [r3]
    vpaddusw       m0, m0, m2
    vpsubusw       m1, m3, m0
    vpacksswb      m1, m1, m1
    vpermq         m1, m1, 0D8h
    vmovdqu        [r6], m1
    add            r1, 32
    add            r3, 32
    add            r6, 16
    sub            r0d, 16
    jg             .upperLoop

%if WIN64
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    lea            r6, [r4 + r5 + (mmsize-1)]
    and            r6, ~(mmsize-1)
    vmovdqu        xm3, [pw_8]
    vmovdqu        xm4, [pw_76543210]
    vpxor          xm5, xm5
    add            r5, r6
    xor            r0d, r0d
    mov            [r5], r0d
    lea            r1, [$$]
    %define        GLOBAL +r1-$$

ALIGN 16
.lowerLoop:
    vmovq          xm0, [r6]
    vpcmpeqb       xm0, xm5
    vpmovmskb      r2d, xm0
    xor            r2d, 0FFFFh
    movzx          r3d, byte [r2 + popcnt_table GLOBAL]
    add            r2d, r2d
    vpshufb        xm2, xm4, [r2 * 8 + ads_mvs_shuffle GLOBAL]
    vmovdqu        [r4 + r0 * 2], xm2
    add            r0d, r3d
    vpaddw         xm4, xm3
    add            r6, 8
    cmp            r6, r5
    jl             .lowerLoop

    mov            r6d, r0d
    RET
