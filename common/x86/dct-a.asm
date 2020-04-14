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

SECTION_RODATA 64
pw_ppmmmmpp:    dw 1,1,-1,-1,-1,-1,1,1
pb_sub4frame:   db 0,1,4,8,5,2,3,6,9,12,13,10,7,11,14,15
pb_sub4field:   db 0,4,1,8,12,5,9,13,2,6,10,14,3,7,11,15
pb_subacmask:   dw 0,-1,-1,-1,-1,-1,-1,-1
pb_scan4framea: SHUFFLE_MASK_W 6,3,7,0,4,1,2,5
pb_scan4frameb: SHUFFLE_MASK_W 0,4,1,2,5,6,3,7
pb_scan4frame2a: SHUFFLE_MASK_W 0,4,1,2,5,8,12,9
pb_scan4frame2b: SHUFFLE_MASK_W 6,3,7,10,13,14,11,15

pb_scan8framet1: SHUFFLE_MASK_W 0,  1,  6,  7,  8,  9, 13, 14
pb_scan8framet2: SHUFFLE_MASK_W 2 , 3,  4,  7,  9, 15, 10, 14
pb_scan8framet3: SHUFFLE_MASK_W 0,  1,  5,  6,  8, 11, 12, 13
pb_scan8framet4: SHUFFLE_MASK_W 0,  3,  4,  5,  8, 11, 12, 15
pb_scan8framet5: SHUFFLE_MASK_W 1,  2,  6,  7,  9, 10, 13, 14
pb_scan8framet6: SHUFFLE_MASK_W 0,  3,  4,  5, 10, 11, 12, 15
pb_scan8framet7: SHUFFLE_MASK_W 1,  2,  6,  7,  8,  9, 14, 15
pb_scan8framet8: SHUFFLE_MASK_W 0,  1,  2,  7,  8, 10, 11, 14
pb_scan8framet9: SHUFFLE_MASK_W 1,  4,  5,  7,  8, 13, 14, 15

pb_scan8frame1: SHUFFLE_MASK_W  0,  8,  1,  2,  9, 12,  4, 13
pb_scan8frame2: SHUFFLE_MASK_W  4,  0,  1,  5,  8, 10, 12, 14
pb_scan8frame3: SHUFFLE_MASK_W 12, 10,  8,  6,  2,  3,  7,  9
pb_scan8frame4: SHUFFLE_MASK_W  0,  1,  8, 12,  4, 13,  9,  2
pb_scan8frame5: SHUFFLE_MASK_W  5, 14, 10,  3, 11, 15,  6,  7
pb_scan8frame6: SHUFFLE_MASK_W  6,  8, 12, 13,  9,  7,  5,  3
pb_scan8frame7: SHUFFLE_MASK_W  1,  3,  5,  7, 10, 14, 15, 11
pb_scan8frame8: SHUFFLE_MASK_W  10, 3, 11, 14,  5,  6, 15,  7

pb_scan8field1 : SHUFFLE_MASK_W    0,   1,   2,   8,   9,   3,   4,  10
pb_scan8field2a: SHUFFLE_MASK_W 0x80,  11,   5,   6,   7,  12,0x80,0x80
pb_scan8field2b: SHUFFLE_MASK_W    0,0x80,0x80,0x80,0x80,0x80,   1,   8
pb_scan8field3a: SHUFFLE_MASK_W   10,   5,   6,   7,  11,0x80,0x80,0x80
pb_scan8field3b: SHUFFLE_MASK_W 0x80,0x80,0x80,0x80,0x80,   1,   8,   2
pb_scan8field4a: SHUFFLE_MASK_W    4,   5,   6,   7,  11,0x80,0x80,0x80
pb_scan8field6 : SHUFFLE_MASK_W    4,   5,   6,   7,  11,0x80,0x80,  12
pb_scan8field7 : SHUFFLE_MASK_W    5,   6,   7,  11,0x80,0x80,  12,  13

ALIGN 32
dct4x4dc_shuf1:   db 0, 1, 4, 5, 8, 9, 12, 13, 2, 3, 6, 7, 10, 11, 14, 15
dct4x4dc_shuf2:   db 2, 3, 6, 7, 10, 11, 14, 15, 0, 1, 4, 5, 8, 9, 12, 13

SECTION .text

cextern pw_32_0
cextern pw_32
cextern pw_512
cextern pw_8000
cextern pw_pixel_max
cextern hsub_mul
cextern pb_1
cextern pw_1
cextern pd_1
cextern pd_32
cextern pw_ppppmmmm
cextern pw_pmpmpmpm
cextern deinterleave_shufd
cextern pb_unpackbd1
cextern pb_unpackbd2

;-----------------------------------------------------------------------------
; void zigzag_scan_8x8_frame( int16_t level[64], int16_t dct[8][8] )
;-----------------------------------------------------------------------------
%macro SCAN_8x8 0
cglobal zigzag_scan_8x8_frame, 2,2,8
    movdqa    xmm0, [r1]
    movdqa    xmm1, [r1+16]
    movdq2q    mm0, xmm0
    PALIGNR   xmm1, xmm1, 14, xmm2
    movdq2q    mm1, xmm1

    movdqa    xmm2, [r1+32]
    movdqa    xmm3, [r1+48]
    PALIGNR   xmm2, xmm2, 12, xmm4
    movdq2q    mm2, xmm2
    PALIGNR   xmm3, xmm3, 10, xmm4
    movdq2q    mm3, xmm3

    punpckhwd xmm0, xmm1
    punpckhwd xmm2, xmm3

    movq       mm4, mm1
    movq       mm5, mm1
    movq       mm6, mm2
    movq       mm7, mm3
    punpckhwd  mm1, mm0
    psllq      mm0, 16
    psrlq      mm3, 16
    punpckhdq  mm1, mm1
    punpckhdq  mm2, mm0
    punpcklwd  mm0, mm4
    punpckhwd  mm4, mm3
    punpcklwd  mm4, mm2
    punpckhdq  mm0, mm2
    punpcklwd  mm6, mm3
    punpcklwd  mm5, mm7
    punpcklwd  mm5, mm6

    movdqa    xmm4, [r1+64]
    movdqa    xmm5, [r1+80]
    movdqa    xmm6, [r1+96]
    movdqa    xmm7, [r1+112]

    movq [r0+2*00], mm0
    movq [r0+2*04], mm4
    movd [r0+2*08], mm1
    movq [r0+2*36], mm5
    movq [r0+2*46], mm6

    PALIGNR   xmm4, xmm4, 14, xmm3
    movdq2q    mm4, xmm4
    PALIGNR   xmm5, xmm5, 12, xmm3
    movdq2q    mm5, xmm5
    PALIGNR   xmm6, xmm6, 10, xmm3
    movdq2q    mm6, xmm6
%if cpuflag(ssse3)
    PALIGNR   xmm7, xmm7, 8, xmm3
    movdq2q    mm7, xmm7
%else
    movhlps   xmm3, xmm7
    punpcklqdq xmm7, xmm7
    movdq2q    mm7, xmm3
%endif

    punpckhwd xmm4, xmm5
    punpckhwd xmm6, xmm7

    movq       mm0, mm4
    movq       mm1, mm5
    movq       mm3, mm7
    punpcklwd  mm7, mm6
    psrlq      mm6, 16
    punpcklwd  mm4, mm6
    punpcklwd  mm5, mm4
    punpckhdq  mm4, mm3
    punpcklwd  mm3, mm6
    punpckhwd  mm3, mm4
    punpckhwd  mm0, mm1
    punpckldq  mm4, mm0
    punpckhdq  mm0, mm6
    pshufw     mm4, mm4, q1230

    movq [r0+2*14], mm4
    movq [r0+2*25], mm0
    movd [r0+2*54], mm7
    movq [r0+2*56], mm5
    movq [r0+2*60], mm3

    punpckhdq xmm3, xmm0, xmm2
    punpckldq xmm0, xmm2
    punpckhdq xmm7, xmm4, xmm6
    punpckldq xmm4, xmm6
    pshufhw   xmm0, xmm0, q0123
    pshuflw   xmm4, xmm4, q0123
    pshufhw   xmm3, xmm3, q0123
    pshuflw   xmm7, xmm7, q0123

    movlps [r0+2*10], xmm0
    movhps [r0+2*17], xmm0
    movlps [r0+2*21], xmm3
    movlps [r0+2*28], xmm4
    movhps [r0+2*32], xmm3
    movhps [r0+2*39], xmm4
    movlps [r0+2*43], xmm7
    movhps [r0+2*50], xmm7

    RET
%endmacro

%if HIGH_BIT_DEPTH == 0
INIT_XMM sse2
SCAN_8x8
INIT_XMM ssse3
SCAN_8x8
%endif

;-----------------------------------------------------------------------------
; void zigzag_scan_8x8_frame( dctcoef level[64], dctcoef dct[8][8] )
;-----------------------------------------------------------------------------
; Output order:
;  0  8  1  2  9 16 24 17
; 10  3  4 11 18 25 32 40
; 33 26 19 12  5  6 13 20
; 27 34 41 48 56 49 42 35
; 28 21 14  7 15 22 29 36
; 43 50 57 58 51 44 37 30
; 23 31 38 45 52 59 60 53
; 46 39 47 54 61 62 55 63
%macro SCAN_8x8_FRAME 5
cglobal zigzag_scan_8x8_frame, 2,2,8
    mova        m0, [r1]
    mova        m1, [r1+ 8*SIZEOF_DCTCOEF]
    movu        m2, [r1+14*SIZEOF_DCTCOEF]
    movu        m3, [r1+21*SIZEOF_DCTCOEF]
    mova        m4, [r1+28*SIZEOF_DCTCOEF]
    punpckl%4   m5, m0, m1
    psrl%2      m0, %1
    punpckh%4   m6, m1, m0
    punpckl%3   m5, m0
    punpckl%3   m1, m1
    punpckh%4   m1, m3
    mova        m7, [r1+52*SIZEOF_DCTCOEF]
    mova        m0, [r1+60*SIZEOF_DCTCOEF]
    punpckh%4   m1, m2
    punpckl%4   m2, m4
    punpckh%4   m4, m3
    punpckl%3   m3, m3
    punpckh%4   m3, m2
    mova      [r0], m5
    mova  [r0+ 4*SIZEOF_DCTCOEF], m1
    mova  [r0+ 8*SIZEOF_DCTCOEF], m6
    punpckl%4   m6, m0
    punpckl%4   m6, m7
    mova        m1, [r1+32*SIZEOF_DCTCOEF]
    movu        m5, [r1+39*SIZEOF_DCTCOEF]
    movu        m2, [r1+46*SIZEOF_DCTCOEF]
    movu [r0+35*SIZEOF_DCTCOEF], m3
    movu [r0+47*SIZEOF_DCTCOEF], m4
    punpckh%4   m7, m0
    psll%2      m0, %1
    punpckh%3   m3, m5, m5
    punpckl%4   m5, m1
    punpckh%4   m1, m2
    mova [r0+52*SIZEOF_DCTCOEF], m6
    movu [r0+13*SIZEOF_DCTCOEF], m5
    movu        m4, [r1+11*SIZEOF_DCTCOEF]
    movu        m6, [r1+25*SIZEOF_DCTCOEF]
    punpckl%4   m5, m7
    punpckl%4   m1, m3
    punpckh%3   m0, m7
    mova        m3, [r1+ 4*SIZEOF_DCTCOEF]
    movu        m7, [r1+18*SIZEOF_DCTCOEF]
    punpckl%4   m2, m5
    movu [r0+25*SIZEOF_DCTCOEF], m1
    mova        m1, m4
    mova        m5, m6
    punpckl%4   m4, m3
    punpckl%4   m6, m7
    punpckh%4   m1, m3
    punpckh%4   m5, m7
    punpckh%3   m3, m6, m4
    punpckh%3   m7, m5, m1
    punpckl%3   m6, m4
    punpckl%3   m5, m1
    movu        m4, [r1+35*SIZEOF_DCTCOEF]
    movu        m1, [r1+49*SIZEOF_DCTCOEF]
    pshuf%5     m6, m6, q0123
    pshuf%5     m5, m5, q0123
    mova [r0+60*SIZEOF_DCTCOEF], m0
    mova [r0+56*SIZEOF_DCTCOEF], m2
    movu        m0, [r1+42*SIZEOF_DCTCOEF]
    mova        m2, [r1+56*SIZEOF_DCTCOEF]
    movu [r0+17*SIZEOF_DCTCOEF], m3
    mova [r0+32*SIZEOF_DCTCOEF], m7
    movu [r0+10*SIZEOF_DCTCOEF], m6
    movu [r0+21*SIZEOF_DCTCOEF], m5
    punpckh%4   m3, m0, m4
    punpckh%4   m7, m2, m1
    punpckl%4   m0, m4
    punpckl%4   m2, m1
    punpckl%3   m4, m2, m0
    punpckl%3   m1, m7, m3
    punpckh%3   m2, m0
    punpckh%3   m7, m3
    pshuf%5     m2, m2, q0123
    pshuf%5     m7, m7, q0123
    mova [r0+28*SIZEOF_DCTCOEF], m4
    movu [r0+43*SIZEOF_DCTCOEF], m1
    movu [r0+39*SIZEOF_DCTCOEF], m2
    movu [r0+50*SIZEOF_DCTCOEF], m7
    RET
%endmacro

INIT_MMX mmx2
SCAN_8x8_FRAME 16, q , dq , wd, w

;-----------------------------------------------------------------------------
; void zigzag_scan_4x4_frame( dctcoef level[16], dctcoef dct[4][4] )
;-----------------------------------------------------------------------------
%macro SCAN_4x4 4
cglobal zigzag_scan_4x4_frame, 2,2,6
    mova      m0, [r1+ 0*SIZEOF_DCTCOEF]
    mova      m1, [r1+ 4*SIZEOF_DCTCOEF]
    mova      m2, [r1+ 8*SIZEOF_DCTCOEF]
    mova      m3, [r1+12*SIZEOF_DCTCOEF]
    punpckl%4 m4, m0, m1
    psrl%2    m0, %1
    punpckl%3 m4, m0
    mova  [r0+ 0*SIZEOF_DCTCOEF], m4
    punpckh%4 m0, m2
    punpckh%4 m4, m2, m3
    psll%2    m3, %1
    punpckl%3 m2, m2
    punpckl%4 m5, m1, m3
    punpckh%3 m1, m1
    punpckh%4 m5, m2
    punpckl%4 m1, m0
    punpckh%3 m3, m4
    mova [r0+ 4*SIZEOF_DCTCOEF], m5
    mova [r0+ 8*SIZEOF_DCTCOEF], m1
    mova [r0+12*SIZEOF_DCTCOEF], m3
    RET
%endmacro

INIT_MMX mmx
SCAN_4x4 16, q , dq , wd

;-----------------------------------------------------------------------------
; void zigzag_scan_4x4_frame( int16_t level[16], int16_t dct[4][4] )
;-----------------------------------------------------------------------------
%macro SCAN_4x4_FRAME 0
cglobal zigzag_scan_4x4_frame, 2,2
    mova    m1, [r1+16]
    mova    m0, [r1+ 0]
    pshufb  m1, [pb_scan4frameb]
    pshufb  m0, [pb_scan4framea]
    psrldq  m2, m1, 6
    palignr m1, m0, 6
    pslldq  m0, 10
    palignr m2, m0, 10
    mova [r0+ 0], m1
    mova [r0+16], m2
    RET
%endmacro

INIT_XMM ssse3
SCAN_4x4_FRAME
INIT_XMM avx
SCAN_4x4_FRAME


;-----------------------------------------------------------------------------
; void zigzag_scan_4x4_field( int16_t level[16], int16_t dct[4][4] )
;-----------------------------------------------------------------------------
INIT_XMM sse
cglobal zigzag_scan_4x4_field, 2,2
    mova       m0, [r1]
    mova       m1, [r1+16]
    pshufw    mm0, [r1+4], q3102
    mova     [r0], m0
    mova  [r0+16], m1
    movq   [r0+4], mm0
    RET

;-----------------------------------------------------------------------------
; void zigzag_scan_8x8_field( int16_t level[64], int16_t dct[8][8] )
;-----------------------------------------------------------------------------
; Output order:
;  0  1  2  8  9  3  4 10
; 16 11  5  6  7 12 17 24
; 18 13 14 15 19 25 32 26
; 20 21 22 23 27 33 40 34
; 28 29 30 31 35 41 48 42
; 36 37 38 39 43 49 50 44
; 45 46 47 51 56 57 52 53
; 54 55 58 59 60 61 62 63
%undef SCAN_8x8
%macro SCAN_8x8 5
cglobal zigzag_scan_8x8_field, 2,3,8
    mova       m0, [r1+ 0*SIZEOF_DCTCOEF]       ; 03 02 01 00
    mova       m1, [r1+ 4*SIZEOF_DCTCOEF]       ; 07 06 05 04
    mova       m2, [r1+ 8*SIZEOF_DCTCOEF]       ; 11 10 09 08
    pshuf%1    m3, m0, q3333                    ; 03 03 03 03
    movd      r2d, m2                           ; 09 08
    pshuf%1    m2, m2, q0321                    ; 08 11 10 09
    punpckl%2  m3, m1                           ; 05 03 04 03
    pinsr%1    m0, r2d, 3                       ; 08 02 01 00
    punpckl%2  m4, m2, m3                       ; 04 10 03 09
    pshuf%1    m4, m4, q2310                    ; 10 04 03 09
    mova  [r0+ 0*SIZEOF_DCTCOEF], m0            ; 08 02 01 00
    mova  [r0+ 4*SIZEOF_DCTCOEF], m4            ; 10 04 03 09
    mova       m3, [r1+12*SIZEOF_DCTCOEF]       ; 15 14 13 12
    mova       m5, [r1+16*SIZEOF_DCTCOEF]       ; 19 18 17 16
    punpckl%3  m6, m5                           ; 17 16 XX XX
    psrl%4     m1, %5                           ; XX 07 06 05
    punpckh%2  m6, m2                           ; 08 17 11 16
    punpckl%3  m6, m1                           ; 06 05 11 16
    mova  [r0+ 8*SIZEOF_DCTCOEF], m6            ; 06 05 11 16
    psrl%4     m1, %5                           ; XX XX 07 06
    punpckl%2  m1, m5                           ; 17 07 16 06
    mova       m0, [r1+20*SIZEOF_DCTCOEF]       ; 23 22 21 20
    mova       m2, [r1+24*SIZEOF_DCTCOEF]       ; 27 26 25 24
    punpckh%3  m1, m1                           ; 17 07 17 07
    punpckl%2  m6, m3, m2                       ; 25 13 24 12
    pextr%1    r2d, m5, 2
    mova [r0+24*SIZEOF_DCTCOEF], m0             ; 23 22 21 20
    punpckl%2  m1, m6                           ; 24 17 12 07
    mova [r0+12*SIZEOF_DCTCOEF], m1
    pinsr%1    m3, r2d, 0                       ; 15 14 13 18
    mova [r0+16*SIZEOF_DCTCOEF], m3             ; 15 14 13 18
    mova       m7, [r1+28*SIZEOF_DCTCOEF]
    mova       m0, [r1+32*SIZEOF_DCTCOEF]       ; 35 34 33 32
    psrl%4     m5, %5*3                         ; XX XX XX 19
    pshuf%1    m1, m2, q3321                    ; 27 27 26 25
    punpckl%2  m5, m0                           ; 33 XX 32 19
    psrl%4     m2, %5*3                         ; XX XX XX 27
    punpckl%2  m5, m1                           ; 26 32 25 19
    mova [r0+32*SIZEOF_DCTCOEF], m7
    mova [r0+20*SIZEOF_DCTCOEF], m5             ; 26 32 25 19
    mova       m7, [r1+36*SIZEOF_DCTCOEF]
    mova       m1, [r1+40*SIZEOF_DCTCOEF]       ; 43 42 41 40
    pshuf%1    m3, m0, q3321                    ; 35 35 34 33
    punpckl%2  m2, m1                           ; 41 XX 40 27
    mova [r0+40*SIZEOF_DCTCOEF], m7
    punpckl%2  m2, m3                           ; 34 40 33 27
    mova [r0+28*SIZEOF_DCTCOEF], m2
    mova       m7, [r1+44*SIZEOF_DCTCOEF]       ; 47 46 45 44
    mova       m2, [r1+48*SIZEOF_DCTCOEF]       ; 51 50 49 48
    psrl%4     m0, %5*3                         ; XX XX XX 35
    punpckl%2  m0, m2                           ; 49 XX 48 35
    pshuf%1    m3, m1, q3321                    ; 43 43 42 41
    punpckl%2  m0, m3                           ; 42 48 41 35
    mova [r0+36*SIZEOF_DCTCOEF], m0
    pextr%1     r2d, m2, 3                      ; 51
    psrl%4      m1, %5*3                        ; XX XX XX 43
    punpckl%2   m1, m7                          ; 45 XX 44 43
    psrl%4      m2, %5                          ; XX 51 50 49
    punpckl%2   m1, m2                          ; 50 44 49 43
    pshuf%1     m1, m1, q2310                   ; 44 50 49 43
    mova [r0+44*SIZEOF_DCTCOEF], m1
    psrl%4      m7, %5                          ; XX 47 46 45
    pinsr%1     m7, r2d, 3                      ; 51 47 46 45
    mova [r0+48*SIZEOF_DCTCOEF], m7
    mova        m0, [r1+56*SIZEOF_DCTCOEF]      ; 59 58 57 56
    mova        m1, [r1+52*SIZEOF_DCTCOEF]      ; 55 54 53 52
    mova        m7, [r1+60*SIZEOF_DCTCOEF]
    punpckl%3   m2, m0, m1                      ; 53 52 57 56
    punpckh%3   m1, m0                          ; 59 58 55 54
    mova [r0+52*SIZEOF_DCTCOEF], m2
    mova [r0+56*SIZEOF_DCTCOEF], m1
    mova [r0+60*SIZEOF_DCTCOEF], m7
    RET
%endmacro
INIT_MMX mmx2
SCAN_8x8 w, wd, dq , q , 16

;-----------------------------------------------------------------------------
; void zigzag_sub_4x4_frame( int16_t level[16], const uint8_t *src, uint8_t *dst )
;-----------------------------------------------------------------------------
%macro ZIGZAG_SUB_4x4 2
%ifidn %1, ac
cglobal zigzag_sub_4x4%1_%2, 4,4,8
%else
cglobal zigzag_sub_4x4%1_%2, 3,3,8
%endif
    movd      m0, [r1+0*FENC_STRIDE]
    movd      m1, [r1+1*FENC_STRIDE]
    movd      m2, [r1+2*FENC_STRIDE]
    movd      m3, [r1+3*FENC_STRIDE]
    movd      m4, [r2+0*FDEC_STRIDE]
    movd      m5, [r2+1*FDEC_STRIDE]
    movd      m6, [r2+2*FDEC_STRIDE]
    movd      m7, [r2+3*FDEC_STRIDE]
    movd [r2+0*FDEC_STRIDE], m0
    movd [r2+1*FDEC_STRIDE], m1
    movd [r2+2*FDEC_STRIDE], m2
    movd [r2+3*FDEC_STRIDE], m3
    punpckldq  m0, m1
    punpckldq  m2, m3
    punpckldq  m4, m5
    punpckldq  m6, m7
    punpcklqdq m0, m2
    punpcklqdq m4, m6
    mova      m7, [pb_sub4%2]
    pshufb    m0, m7
    pshufb    m4, m7
    mova      m7, [hsub_mul]
    punpckhbw m1, m0, m4
    punpcklbw m0, m4
    pmaddubsw m1, m7
    pmaddubsw m0, m7
%ifidn %1, ac
    movd     r2d, m0
    pand      m0, [pb_subacmask]
%endif
    mova [r0+ 0], m0
    por       m0, m1
    pxor      m2, m2
    mova [r0+16], m1
    pcmpeqb   m0, m2
    pmovmskb eax, m0
%ifidn %1, ac
    mov     [r3], r2w
%endif
    sub      eax, 0xffff
    shr      eax, 31
    RET
%endmacro

%if HIGH_BIT_DEPTH == 0
INIT_XMM ssse3
ZIGZAG_SUB_4x4   , frame
ZIGZAG_SUB_4x4 ac, frame
ZIGZAG_SUB_4x4   , field
ZIGZAG_SUB_4x4 ac, field
INIT_XMM avx
ZIGZAG_SUB_4x4   , frame
ZIGZAG_SUB_4x4 ac, frame
ZIGZAG_SUB_4x4   , field
ZIGZAG_SUB_4x4 ac, field
%endif ; !HIGH_BIT_DEPTH


;-----------------------------------------------------------------------------
; void zigzag_interleave_8x8_cavlc( int16_t *dst, int16_t *src, uint8_t *nnz )
;-----------------------------------------------------------------------------
%macro INTERLEAVE 2
    mova     m0, [r1+(%1*4+ 0)*SIZEOF_PIXEL]
    mova     m1, [r1+(%1*4+ 8)*SIZEOF_PIXEL]
    mova     m2, [r1+(%1*4+16)*SIZEOF_PIXEL]
    mova     m3, [r1+(%1*4+24)*SIZEOF_PIXEL]
    TRANSPOSE4x4%2 0,1,2,3,4
    mova     [r0+(%1+ 0)*SIZEOF_PIXEL], m0
    mova     [r0+(%1+32)*SIZEOF_PIXEL], m1
    mova     [r0+(%1+64)*SIZEOF_PIXEL], m2
    mova     [r0+(%1+96)*SIZEOF_PIXEL], m3
    packsswb m0, m1
    ACCUM   por, 6, 2, %1
    ACCUM   por, 7, 3, %1
    ACCUM   por, 5, 0, %1
%endmacro

%macro ZIGZAG_8x8_CAVLC 1
cglobal zigzag_interleave_8x8_cavlc, 3,3,8
    INTERLEAVE  0, %1
    INTERLEAVE  8, %1
    INTERLEAVE 16, %1
    INTERLEAVE 24, %1
    packsswb   m6, m7
    packsswb   m5, m6
    packsswb   m5, m5
    pxor       m0, m0
%if HIGH_BIT_DEPTH
    packsswb   m5, m5
%endif
    pcmpeqb    m5, m0
    paddb      m5, [pb_1]
    movd      r0d, m5
    mov    [r2+0], r0w
    shr       r0d, 16
    mov    [r2+8], r0w
    RET
%endmacro

INIT_MMX mmx
ZIGZAG_8x8_CAVLC W

%macro INTERLEAVE_XMM 1
    mova   m0, [r1+%1*4+ 0]
    mova   m1, [r1+%1*4+16]
    mova   m4, [r1+%1*4+32]
    mova   m5, [r1+%1*4+48]
    SBUTTERFLY wd, 0, 1, 6
    SBUTTERFLY wd, 4, 5, 7
    SBUTTERFLY wd, 0, 1, 6
    SBUTTERFLY wd, 4, 5, 7
    movh   [r0+%1+  0], m0
    movhps [r0+%1+ 32], m0
    movh   [r0+%1+ 64], m1
    movhps [r0+%1+ 96], m1
    movh   [r0+%1+  8], m4
    movhps [r0+%1+ 40], m4
    movh   [r0+%1+ 72], m5
    movhps [r0+%1+104], m5
    ACCUM por, 2, 0, %1
    ACCUM por, 3, 1, %1
    por    m2, m4
    por    m3, m5
%endmacro

%if HIGH_BIT_DEPTH == 0
%macro ZIGZAG_8x8_CAVLC 0
cglobal zigzag_interleave_8x8_cavlc, 3,3,8
    INTERLEAVE_XMM  0
    INTERLEAVE_XMM 16
    packsswb m2, m3
    pxor     m5, m5
    packsswb m2, m2
    packsswb m2, m2
    pcmpeqb  m5, m2
    paddb    m5, [pb_1]
    movd    r0d, m5
    mov  [r2+0], r0w
    shr     r0d, 16
    mov  [r2+8], r0w
    RET
%endmacro

INIT_XMM sse2
ZIGZAG_8x8_CAVLC
INIT_XMM avx
ZIGZAG_8x8_CAVLC

INIT_YMM avx2
cglobal zigzag_interleave_8x8_cavlc, 3,3,6
    mova   m0, [r1+ 0]
    mova   m1, [r1+32]
    mova   m2, [r1+64]
    mova   m3, [r1+96]
    mova   m5, [deinterleave_shufd]
    SBUTTERFLY wd, 0, 1, 4
    SBUTTERFLY wd, 2, 3, 4
    SBUTTERFLY wd, 0, 1, 4
    SBUTTERFLY wd, 2, 3, 4
    vpermd m0, m5, m0
    vpermd m1, m5, m1
    vpermd m2, m5, m2
    vpermd m3, m5, m3
    mova [r0+  0], xm0
    mova [r0+ 16], xm2
    vextracti128 [r0+ 32], m0, 1
    vextracti128 [r0+ 48], m2, 1
    mova [r0+ 64], xm1
    mova [r0+ 80], xm3
    vextracti128 [r0+ 96], m1, 1
    vextracti128 [r0+112], m3, 1

    packsswb m0, m2          ; nnz0, nnz1
    packsswb m1, m3          ; nnz2, nnz3
    packsswb m0, m1          ; {nnz0,nnz2}, {nnz1,nnz3}
    vpermq   m0, m0, q3120   ; {nnz0,nnz1}, {nnz2,nnz3}
    pxor     m5, m5
    pcmpeqq  m0, m5
    pmovmskb r0d, m0
    not     r0d
    and     r0d, 0x01010101
    mov  [r2+0], r0w
    shr     r0d, 16
    mov  [r2+8], r0w
    RET
%endif ; !HIGH_BIT_DEPTH


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
