;*****************************************************************************
;* mc-a2.asm: x86 motion compensation
;*****************************************************************************
;* Copyright (C) 2005-2019 x264 project
;*
;* Authors: Loren Merritt <lorenm@u.washington.edu>
;*          Fiona Glaser <fiona@x264.com>
;*          Holger Lubitz <holger@lubitz.org>
;*          Mathieu Monnier <manao@melix.net>
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

SECTION_RODATA 64

deinterleave_rgb_shuf: db  0, 3, 6, 9, 0, 3, 6, 9, 1, 4, 7,10, 2, 5, 8,11
                       db  0, 4, 8,12, 0, 4, 8,12, 1, 5, 9,13, 2, 6,10,14
copy_swap_shuf:        db  1, 0, 3, 2, 5, 4, 7, 6, 9, 8,11,10,13,12,15,14
deinterleave_shuf:     db  0, 2, 4, 6, 8,10,12,14, 1, 3, 5, 7, 9,11,13,15
deinterleave_shuf32a: db 0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30
deinterleave_shuf32b: db 1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31

pw_1024: times 16 dw 1024
filt_mul20: times 32 db 20
filt_mul15: times 16 db 1, -5
filt_mul51: times 16 db -5, 1
hpel_shuf: times 2 db 0,8,1,9,2,10,3,11,4,12,5,13,6,14,7,15

mbtree_prop_list_avx512_shuf: dw 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7
mbtree_fix8_unpack_shuf: db -1,-1, 1, 0,-1,-1, 3, 2,-1,-1, 5, 4,-1,-1, 7, 6
                         db -1,-1, 9, 8,-1,-1,11,10,-1,-1,13,12,-1,-1,15,14
; bits 0-3: pshufb, bits 4-7: AVX-512 vpermq
mbtree_fix8_pack_shuf:   db 0x01,0x20,0x43,0x62,0x15,0x34,0x57,0x76,0x09,0x08,0x0b,0x0a,0x0d,0x0c,0x0f,0x0e

pf_256:         times 4 dd 256.0
pf_inv16777216: times 4 dd 0x1p-24

pd_16: times 4 dd 16

pad10: times 8 dw    10*PIXEL_MAX
pad20: times 8 dw    20*PIXEL_MAX
pad30: times 8 dw    30*PIXEL_MAX
depad: times 4 dd 32*20*PIXEL_MAX + 512

tap1: times 4 dw  1, -5
tap2: times 4 dw 20, 20
tap3: times 4 dw -5,  1

pw_0xc000: times 8 dw 0xc000
pw_31: times 8 dw 31
pd_4: times 4 dd 4

SECTION .text

cextern pb_0
cextern pw_1
cextern pw_8
cextern pw_16
cextern pw_32
cextern pw_512
cextern pw_00ff
cextern pw_3fff
cextern pw_pixel_max
cextern pw_0to15
cextern pd_8
cextern pd_0123
cextern pd_ffff
cextern deinterleave_shufd


; These functions are not general-use; not only do they require aligned input, but memcpy
; requires size to be a multiple of 16 and memzero requires size to be a multiple of 128.

;-----------------------------------------------------------------------------
; void *memcpy_aligned( void *dst, const void *src, size_t n );
;-----------------------------------------------------------------------------
%macro MEMCPY 0
cglobal memcpy_aligned, 3,3
%if mmsize == 32
    test r2d, 16
    jz .copy32
    mova xm0, [r1+r2-16]
    mova [r0+r2-16], xm0
    sub  r2d, 16
    jle .ret
.copy32:
%endif
    test r2d, mmsize
    jz .loop
    mova  m0, [r1+r2-mmsize]
    mova [r0+r2-mmsize], m0
    sub      r2d, mmsize
    jle .ret
.loop:
    mova  m0, [r1+r2-1*mmsize]
    mova  m1, [r1+r2-2*mmsize]
    mova [r0+r2-1*mmsize], m0
    mova [r0+r2-2*mmsize], m1
    sub  r2d, 2*mmsize
    jg .loop
.ret:
    RET
%endmacro

;-----------------------------------------------------------------------------
; void *memzero_aligned( void *dst, size_t n );
;-----------------------------------------------------------------------------
%macro MEMZERO 0
cglobal memzero_aligned, 2,2
    xorps m0, m0
.loop:
%assign %%i mmsize
%rep 128 / mmsize
    movaps [r0 + r1 - %%i], m0
%assign %%i %%i+mmsize
%endrep
    sub r1d, 128
    jg .loop
    RET
%endmacro

INIT_XMM sse
MEMCPY
MEMZERO
INIT_YMM avx
MEMCPY
MEMZERO
INIT_ZMM avx512
MEMZERO

cglobal memcpy_aligned, 3,4
    dec      r2d           ; offset of the last byte
    rorx     r3d, r2d, 2
    and      r2d, ~63
    and      r3d, 15       ; n = number of dwords minus one to copy in the tail
    mova      m0, [r1+r2]
    not      r3d           ; bits 0-4: (n^15)+16, bits 16-31: 0xffff
    shrx     r3d, r3d, r3d ; 0xffff >> (n^15)
    kmovw     k1, r3d      ; (1 << (n+1)) - 1
    vmovdqa32 [r0+r2] {k1}, m0
    sub      r2d, 64
    jl .ret
.loop:
    mova      m0, [r1+r2]
    mova [r0+r2], m0
    sub      r2d, 64
    jge .loop
.ret:
    RET

%if HIGH_BIT_DEPTH == 0
;-----------------------------------------------------------------------------
; void integral_init4h( uint16_t *sum, uint8_t *pix, intptr_t stride )
;-----------------------------------------------------------------------------
%macro INTEGRAL_INIT4H 0
cglobal integral_init4h, 3,4
    lea     r3, [r0+r2*2]
    add     r1, r2
    neg     r2
    pxor    m4, m4
.loop:
    mova   xm0, [r1+r2]
    mova   xm1, [r1+r2+16]
%if mmsize==32
    vinserti128 m0, m0, [r1+r2+ 8], 1
    vinserti128 m1, m1, [r1+r2+24], 1
%else
    palignr m1, m0, 8
%endif
    mpsadbw m0, m4, 0
    mpsadbw m1, m4, 0
    paddw   m0, [r0+r2*2]
    paddw   m1, [r0+r2*2+mmsize]
    mova  [r3+r2*2   ], m0
    mova  [r3+r2*2+mmsize], m1
    add     r2, mmsize
    jl .loop
    RET
%endmacro

INIT_XMM sse4
INTEGRAL_INIT4H
INIT_YMM avx2
INTEGRAL_INIT4H

%macro INTEGRAL_INIT8H 0
cglobal integral_init8h, 3,4
    lea     r3, [r0+r2*2]
    add     r1, r2
    neg     r2
    pxor    m4, m4
.loop:
    mova   xm0, [r1+r2]
    mova   xm1, [r1+r2+16]
%if mmsize==32
    vinserti128 m0, m0, [r1+r2+ 8], 1
    vinserti128 m1, m1, [r1+r2+24], 1
    mpsadbw m2, m0, m4, 100100b
    mpsadbw m3, m1, m4, 100100b
%else
    palignr m1, m0, 8
    mpsadbw m2, m0, m4, 100b
    mpsadbw m3, m1, m4, 100b
%endif
    mpsadbw m0, m4, 0
    mpsadbw m1, m4, 0
    paddw   m0, [r0+r2*2]
    paddw   m1, [r0+r2*2+mmsize]
    paddw   m0, m2
    paddw   m1, m3
    mova  [r3+r2*2   ], m0
    mova  [r3+r2*2+mmsize], m1
    add     r2, mmsize
    jl .loop
    RET
%endmacro

INIT_XMM sse4
INTEGRAL_INIT8H
INIT_XMM avx
INTEGRAL_INIT8H
INIT_YMM avx2
INTEGRAL_INIT8H
%endif ; !HIGH_BIT_DEPTH

%macro INTEGRAL_INIT_8V 0
;-----------------------------------------------------------------------------
; void integral_init8v( uint16_t *sum8, intptr_t stride )
;-----------------------------------------------------------------------------
cglobal integral_init8v, 3,3
    add   r1, r1
    add   r0, r1
    lea   r2, [r0+r1*8]
    neg   r1
.loop:
    mova  m0, [r2+r1]
    mova  m1, [r2+r1+mmsize]
    psubw m0, [r0+r1]
    psubw m1, [r0+r1+mmsize]
    mova  [r0+r1], m0
    mova  [r0+r1+mmsize], m1
    add   r1, 2*mmsize
    jl .loop
    RET
%endmacro

INIT_MMX mmx
INTEGRAL_INIT_8V
INIT_XMM sse2
INTEGRAL_INIT_8V
INIT_YMM avx2
INTEGRAL_INIT_8V

;-----------------------------------------------------------------------------
; void integral_init4v( uint16_t *sum8, uint16_t *sum4, intptr_t stride )
;-----------------------------------------------------------------------------
INIT_MMX mmx
cglobal integral_init4v, 3,5
    shl   r2, 1
    lea   r3, [r0+r2*4]
    lea   r4, [r0+r2*8]
    mova  m0, [r0+r2]
    mova  m4, [r4+r2]
.loop:
    mova  m1, m4
    psubw m1, m0
    mova  m4, [r4+r2-8]
    mova  m0, [r0+r2-8]
    paddw m1, m4
    mova  m3, [r3+r2-8]
    psubw m1, m0
    psubw m3, m0
    mova  [r0+r2-8], m1
    mova  [r1+r2-8], m3
    sub   r2, 8
    jge .loop
    RET

INIT_XMM sse2
cglobal integral_init4v, 3,5
    shl     r2, 1
    add     r0, r2
    add     r1, r2
    lea     r3, [r0+r2*4]
    lea     r4, [r0+r2*8]
    neg     r2
.loop:
    mova    m0, [r0+r2]
    mova    m1, [r4+r2]
    mova    m2, m0
    mova    m4, m1
    shufpd  m0, [r0+r2+16], 1
    shufpd  m1, [r4+r2+16], 1
    paddw   m0, m2
    paddw   m1, m4
    mova    m3, [r3+r2]
    psubw   m1, m0
    psubw   m3, m2
    mova  [r0+r2], m1
    mova  [r1+r2], m3
    add     r2, 16
    jl .loop
    RET

INIT_XMM ssse3
cglobal integral_init4v, 3,5
    shl     r2, 1
    add     r0, r2
    add     r1, r2
    lea     r3, [r0+r2*4]
    lea     r4, [r0+r2*8]
    neg     r2
.loop:
    mova    m2, [r0+r2]
    mova    m0, [r0+r2+16]
    mova    m4, [r4+r2]
    mova    m1, [r4+r2+16]
    palignr m0, m2, 8
    palignr m1, m4, 8
    paddw   m0, m2
    paddw   m1, m4
    mova    m3, [r3+r2]
    psubw   m1, m0
    psubw   m3, m2
    mova  [r0+r2], m1
    mova  [r1+r2], m3
    add     r2, 16
    jl .loop
    RET

INIT_YMM avx2
cglobal integral_init4v, 3,5
    add     r2, r2
    add     r0, r2
    add     r1, r2
    lea     r3, [r0+r2*4]
    lea     r4, [r0+r2*8]
    neg     r2
.loop:
    mova    m2, [r0+r2]
    movu    m1, [r4+r2+8]
    paddw   m0, m2, [r0+r2+8]
    paddw   m1, [r4+r2]
    mova    m3, [r3+r2]
    psubw   m1, m0
    psubw   m3, m2
    mova  [r0+r2], m1
    mova  [r1+r2], m3
    add     r2, 32
    jl .loop
    RET

%macro FILT8x4 7
    mova      %3, [r0+%7]
    mova      %4, [r0+r5+%7]
    pavgb     %3, %4
    pavgb     %4, [r0+r5*2+%7]
    PALIGNR   %1, %3, 1, m6
    PALIGNR   %2, %4, 1, m6
%if cpuflag(xop)
    pavgb     %1, %3
    pavgb     %2, %4
%else
    pavgb     %1, %3
    pavgb     %2, %4
    psrlw     %5, %1, 8
    psrlw     %6, %2, 8
    pand      %1, m7
    pand      %2, m7
%endif
%endmacro

%macro FILT32x4U 4
    mova      m1, [r0+r5]
    pavgb     m0, m1, [r0]
    movu      m3, [r0+r5+1]
    pavgb     m2, m3, [r0+1]
    pavgb     m1, [r0+r5*2]
    pavgb     m3, [r0+r5*2+1]
    pavgb     m0, m2
    pavgb     m1, m3

    mova      m3, [r0+r5+mmsize]
    pavgb     m2, m3, [r0+mmsize]
    movu      m5, [r0+r5+1+mmsize]
    pavgb     m4, m5, [r0+1+mmsize]
    pavgb     m3, [r0+r5*2+mmsize]
    pavgb     m5, [r0+r5*2+1+mmsize]
    pavgb     m2, m4
    pavgb     m3, m5

    pshufb    m0, m7
    pshufb    m1, m7
    pshufb    m2, m7
    pshufb    m3, m7
    punpckhqdq m4, m0, m2
    punpcklqdq m0, m0, m2
    punpckhqdq m5, m1, m3
    punpcklqdq m2, m1, m3
    vpermq    m0, m0, q3120
    vpermq    m1, m4, q3120
    vpermq    m2, m2, q3120
    vpermq    m3, m5, q3120
    mova    [%1], m0
    mova    [%2], m1
    mova    [%3], m2
    mova    [%4], m3
%endmacro

%macro FILT16x2 4
    mova      m3, [r0+%4+mmsize]
    mova      m2, [r0+%4]
    pavgb     m3, [r0+%4+r5+mmsize]
    pavgb     m2, [r0+%4+r5]
    PALIGNR   %1, m3, 1, m6
    pavgb     %1, m3
    PALIGNR   m3, m2, 1, m6
    pavgb     m3, m2
%if cpuflag(xop)
    vpperm    m5, m3, %1, m7
    vpperm    m3, m3, %1, m6
%else
    psrlw     m5, m3, 8
    psrlw     m4, %1, 8
    pand      m3, m7
    pand      %1, m7
    packuswb  m3, %1
    packuswb  m5, m4
%endif
    mova    [%2], m3
    mova    [%3], m5
    mova      %1, m2
%endmacro

%macro FILT8x2U 3
    mova      m3, [r0+%3+8]
    mova      m2, [r0+%3]
    pavgb     m3, [r0+%3+r5+8]
    pavgb     m2, [r0+%3+r5]
    mova      m1, [r0+%3+9]
    mova      m0, [r0+%3+1]
    pavgb     m1, [r0+%3+r5+9]
    pavgb     m0, [r0+%3+r5+1]
    pavgb     m1, m3
    pavgb     m0, m2
    psrlw     m3, m1, 8
    psrlw     m2, m0, 8
    pand      m1, m7
    pand      m0, m7
    packuswb  m0, m1
    packuswb  m2, m3
    mova    [%1], m0
    mova    [%2], m2
%endmacro

%macro FILT8xU 3
    mova      m3, [r0+%3+8]
    mova      m2, [r0+%3]
    pavgw     m3, [r0+%3+r5+8]
    pavgw     m2, [r0+%3+r5]
    movu      m1, [r0+%3+10]
    movu      m0, [r0+%3+2]
    pavgw     m1, [r0+%3+r5+10]
    pavgw     m0, [r0+%3+r5+2]
    pavgw     m1, m3
    pavgw     m0, m2
    psrld     m3, m1, 16
    psrld     m2, m0, 16
    pand      m1, m7
    pand      m0, m7
    packssdw  m0, m1
    packssdw  m2, m3
    movu    [%1], m0
    mova    [%2], m2
%endmacro

%macro FILT8xA 4
    mova      m3, [r0+%4+mmsize]
    mova      m2, [r0+%4]
    pavgw     m3, [r0+%4+r5+mmsize]
    pavgw     m2, [r0+%4+r5]
    PALIGNR   %1, m3, 2, m6
    pavgw     %1, m3
    PALIGNR   m3, m2, 2, m6
    pavgw     m3, m2
%if cpuflag(xop)
    vpperm    m5, m3, %1, m7
    vpperm    m3, m3, %1, m6
%else
    psrld     m5, m3, 16
    psrld     m4, %1, 16
    pand      m3, m7
    pand      %1, m7
    packssdw  m3, %1
    packssdw  m5, m4
%endif
    mova    [%2], m3
    mova    [%3], m5
    mova      %1, m2
%endmacro

;-----------------------------------------------------------------------------
; void frame_init_lowres_core( uint8_t *src0, uint8_t *dst0, uint8_t *dsth, uint8_t *dstv, uint8_t *dstc,
;                              intptr_t src_stride, intptr_t dst_stride, int width, int height )
;-----------------------------------------------------------------------------
%macro FRAME_INIT_LOWRES 0
cglobal frame_init_lowres_core, 6,7,(12-4*(BIT_DEPTH/9)) ; 8 for HIGH_BIT_DEPTH, 12 otherwise
%if HIGH_BIT_DEPTH
    shl   dword r6m, 1
    FIX_STRIDES r5
    shl   dword r7m, 1
%endif
%if mmsize >= 16
    add   dword r7m, mmsize-1
    and   dword r7m, ~(mmsize-1)
%endif
    ; src += 2*(height-1)*stride + 2*width
    mov      r6d, r8m
    dec      r6d
    imul     r6d, r5d
    add      r6d, r7m
    lea       r0, [r0+r6*2]
    ; dst += (height-1)*stride + width
    mov      r6d, r8m
    dec      r6d
    imul     r6d, r6m
    add      r6d, r7m
    add       r1, r6
    add       r2, r6
    add       r3, r6
    add       r4, r6
    ; gap = stride - width
    mov      r6d, r6m
    sub      r6d, r7m
    PUSH      r6
    %define dst_gap [rsp+gprsize]
    mov      r6d, r5d
    sub      r6d, r7m
    shl      r6d, 1
    PUSH      r6
    %define src_gap [rsp]
%if HIGH_BIT_DEPTH
%if cpuflag(xop)
    mova      m6, [deinterleave_shuf32a]
    mova      m7, [deinterleave_shuf32b]
%else
    pcmpeqw   m7, m7
    psrld     m7, 16
%endif
.vloop:
    mov      r6d, r7m
%ifnidn cpuname, mmx2
    mova      m0, [r0]
    mova      m1, [r0+r5]
    pavgw     m0, m1
    pavgw     m1, [r0+r5*2]
%endif
.hloop:
    sub       r0, mmsize*2
    sub       r1, mmsize
    sub       r2, mmsize
    sub       r3, mmsize
    sub       r4, mmsize
%ifidn cpuname, mmx2
    FILT8xU r1, r2, 0
    FILT8xU r3, r4, r5
%else
    FILT8xA m0, r1, r2, 0
    FILT8xA m1, r3, r4, r5
%endif
    sub      r6d, mmsize
    jg .hloop
%else ; !HIGH_BIT_DEPTH
%if cpuflag(avx2)
    vbroadcasti128 m7, [deinterleave_shuf]
%elif cpuflag(xop)
    mova      m6, [deinterleave_shuf32a]
    mova      m7, [deinterleave_shuf32b]
%else
    pcmpeqb   m7, m7
    psrlw     m7, 8
%endif
.vloop:
    mov      r6d, r7m
%ifnidn cpuname, mmx2
%if mmsize <= 16
    mova      m0, [r0]
    mova      m1, [r0+r5]
    pavgb     m0, m1
    pavgb     m1, [r0+r5*2]
%endif
%endif
.hloop:
    sub       r0, mmsize*2
    sub       r1, mmsize
    sub       r2, mmsize
    sub       r3, mmsize
    sub       r4, mmsize
%if mmsize==32
    FILT32x4U r1, r2, r3, r4
%elifdef m8
    FILT8x4   m0, m1, m2, m3, m10, m11, mmsize
    mova      m8, m0
    mova      m9, m1
    FILT8x4   m2, m3, m0, m1, m4, m5, 0
%if cpuflag(xop)
    vpperm    m4, m2, m8, m7
    vpperm    m2, m2, m8, m6
    vpperm    m5, m3, m9, m7
    vpperm    m3, m3, m9, m6
%else
    packuswb  m2, m8
    packuswb  m3, m9
    packuswb  m4, m10
    packuswb  m5, m11
%endif
    mova    [r1], m2
    mova    [r2], m4
    mova    [r3], m3
    mova    [r4], m5
%elifidn cpuname, mmx2
    FILT8x2U  r1, r2, 0
    FILT8x2U  r3, r4, r5
%else
    FILT16x2  m0, r1, r2, 0
    FILT16x2  m1, r3, r4, r5
%endif
    sub      r6d, mmsize
    jg .hloop
%endif ; HIGH_BIT_DEPTH
.skip:
    mov       r6, dst_gap
    sub       r0, src_gap
    sub       r1, r6
    sub       r2, r6
    sub       r3, r6
    sub       r4, r6
    dec    dword r8m
    jg .vloop
    ADD      rsp, 2*gprsize
    emms
    RET
%endmacro ; FRAME_INIT_LOWRES

INIT_MMX mmx2
FRAME_INIT_LOWRES
%if ARCH_X86_64 == 0
INIT_MMX cache32, mmx2
FRAME_INIT_LOWRES
%endif
INIT_XMM sse2
FRAME_INIT_LOWRES
INIT_XMM ssse3
FRAME_INIT_LOWRES
INIT_XMM avx
FRAME_INIT_LOWRES
INIT_XMM xop
FRAME_INIT_LOWRES
%if HIGH_BIT_DEPTH==0
INIT_YMM avx2
FRAME_INIT_LOWRES
%endif

;-----------------------------------------------------------------------------
; void mbtree_propagate_cost( int *dst, uint16_t *propagate_in, uint16_t *intra_costs,
;                             uint16_t *inter_costs, uint16_t *inv_qscales, float *fps_factor, int len )
;-----------------------------------------------------------------------------
%macro MBTREE 0
cglobal mbtree_propagate_cost, 6,6,7
    movss     m6, [r5]
    mov      r5d, r6m
    lea       r0, [r0+r5*2]
    add      r5d, r5d
    add       r1, r5
    add       r2, r5
    add       r3, r5
    add       r4, r5
    neg       r5
    pxor      m4, m4
    shufps    m6, m6, 0
    mova      m5, [pw_3fff]
.loop:
    movq      m2, [r2+r5] ; intra
    movq      m0, [r4+r5] ; invq
    movq      m3, [r3+r5] ; inter
    movq      m1, [r1+r5] ; prop
    pand      m3, m5
    pminsw    m3, m2
    punpcklwd m2, m4
    punpcklwd m0, m4
    pmaddwd   m0, m2
    punpcklwd m1, m4
    punpcklwd m3, m4
%if cpuflag(fma4)
    cvtdq2ps  m0, m0
    cvtdq2ps  m1, m1
    fmaddps   m0, m0, m6, m1
    cvtdq2ps  m1, m2
    psubd     m2, m3
    cvtdq2ps  m2, m2
    rcpps     m3, m1
    mulps     m1, m3
    mulps     m0, m2
    addps     m2, m3, m3
    fnmaddps  m3, m1, m3, m2
    mulps     m0, m3
%else
    cvtdq2ps  m0, m0
    mulps     m0, m6    ; intra*invq*fps_factor>>8
    cvtdq2ps  m1, m1    ; prop
    addps     m0, m1    ; prop + (intra*invq*fps_factor>>8)
    cvtdq2ps  m1, m2    ; intra
    psubd     m2, m3    ; intra - inter
    cvtdq2ps  m2, m2    ; intra - inter
    rcpps     m3, m1    ; 1 / intra 1st approximation
    mulps     m1, m3    ; intra * (1/intra 1st approx)
    mulps     m1, m3    ; intra * (1/intra 1st approx)^2
    mulps     m0, m2    ; (prop + (intra*invq*fps_factor>>8)) * (intra - inter)
    addps     m3, m3    ; 2 * (1/intra 1st approx)
    subps     m3, m1    ; 2nd approximation for 1/intra
    mulps     m0, m3    ; / intra
%endif
    cvtps2dq  m0, m0
    packssdw  m0, m0
    movh [r0+r5], m0
    add       r5, 8
    jl .loop
    RET
%endmacro

INIT_XMM sse2
MBTREE
; Bulldozer only has a 128-bit float unit, so the AVX version of this function is actually slower.
INIT_XMM fma4
MBTREE

%macro INT16_UNPACK 1
    punpckhwd   xm6, xm%1, xm7
    punpcklwd  xm%1, xm7
    vinsertf128 m%1, m%1, xm6, 1
%endmacro

; FIXME: align loads to 16 bytes
%macro MBTREE_AVX 0
cglobal mbtree_propagate_cost, 6,6,8-2*cpuflag(avx2)
    vbroadcastss m5, [r5]
    mov         r5d, r6m
    lea          r2, [r2+r5*2]
    add         r5d, r5d
    add          r4, r5
    neg          r5
    sub          r1, r5
    sub          r3, r5
    sub          r0, r5
    mova        xm4, [pw_3fff]
%if notcpuflag(avx2)
    pxor        xm7, xm7
%endif
.loop:
%if cpuflag(avx2)
    pmovzxwd     m0, [r2+r5]      ; intra
    pmovzxwd     m1, [r4+r5]      ; invq
    pmovzxwd     m2, [r1+r5]      ; prop
    pand        xm3, xm4, [r3+r5] ; inter
    pmovzxwd     m3, xm3
    pmaddwd      m1, m0
    psubusw      m3, m0, m3
    cvtdq2ps     m0, m0
    cvtdq2ps     m1, m1
    cvtdq2ps     m2, m2
    cvtdq2ps     m3, m3
    fmaddps      m1, m1, m5, m2
    rcpps        m2, m0
    mulps        m0, m2
    mulps        m1, m3
    addps        m3, m2, m2
    fnmaddps     m2, m2, m0, m3
    mulps        m1, m2
%else
    movu        xm0, [r2+r5]
    movu        xm1, [r4+r5]
    movu        xm2, [r1+r5]
    pand        xm3, xm4, [r3+r5]
    psubusw     xm3, xm0, xm3
    INT16_UNPACK 0
    INT16_UNPACK 1
    INT16_UNPACK 2
    INT16_UNPACK 3
    cvtdq2ps     m0, m0
    cvtdq2ps     m1, m1
    cvtdq2ps     m2, m2
    cvtdq2ps     m3, m3
    mulps        m1, m0
    mulps        m1, m5         ; intra*invq*fps_factor>>8
    addps        m1, m2         ; prop + (intra*invq*fps_factor>>8)
    rcpps        m2, m0         ; 1 / intra 1st approximation
    mulps        m0, m2         ; intra * (1/intra 1st approx)
    mulps        m0, m2         ; intra * (1/intra 1st approx)^2
    mulps        m1, m3         ; (prop + (intra*invq*fps_factor>>8)) * (intra - inter)
    addps        m2, m2         ; 2 * (1/intra 1st approx)
    subps        m2, m0         ; 2nd approximation for 1/intra
    mulps        m1, m2         ; / intra
%endif
    cvtps2dq     m1, m1
    vextractf128 xm2, m1, 1
    packssdw    xm1, xm2
    mova    [r0+r5], xm1
    add          r5, 16
    jl .loop
    RET
%endmacro

INIT_YMM avx
MBTREE_AVX
INIT_YMM avx2
MBTREE_AVX

INIT_ZMM avx512
cglobal mbtree_propagate_cost, 6,6
    vbroadcastss  m5, [r5]
    mov          r5d, 0x3fff3fff
    vpbroadcastd ym4, r5d
    mov          r5d, r6m
    lea           r2, [r2+r5*2]
    add          r5d, r5d
    add           r1, r5
    neg           r5
    sub           r4, r5
    sub           r3, r5
    sub           r0, r5
.loop:
    pmovzxwd      m0, [r2+r5]      ; intra
    pmovzxwd      m1, [r1+r5]      ; prop
    pmovzxwd      m2, [r4+r5]      ; invq
    pand         ym3, ym4, [r3+r5] ; inter
    pmovzxwd      m3, ym3
    psubusw       m3, m0, m3
    cvtdq2ps      m0, m0
    cvtdq2ps      m1, m1
    cvtdq2ps      m2, m2
    cvtdq2ps      m3, m3
    vdivps        m1, m0, {rn-sae}
    fmaddps       m1, m2, m5, m1
    mulps         m1, m3
    cvtps2dq      m1, m1
    vpmovsdw [r0+r5], m1
    add           r5, 32
    jl .loop
    RET

%macro MBTREE_PROPAGATE_LIST 0
;-----------------------------------------------------------------------------
; void mbtree_propagate_list_internal( int16_t (*mvs)[2], int16_t *propagate_amount, uint16_t *lowres_costs,
;                                      int16_t *output, int bipred_weight, int mb_y, int len )
;-----------------------------------------------------------------------------
cglobal mbtree_propagate_list_internal, 4,6,8
    movh     m6, [pw_0to15] ; mb_x
    movd     m7, r5m
    pshuflw  m7, m7, 0
    punpcklwd m6, m7       ; 0 y 1 y 2 y 3 y
    movd     m7, r4m
    SPLATW   m7, m7        ; bipred_weight
    psllw    m7, 9         ; bipred_weight << 9

    mov     r5d, r6m
    xor     r4d, r4d
.loop:
    mova     m3, [r1+r4*2]
    movu     m4, [r2+r4*2]
    mova     m5, [pw_0xc000]
    pand     m4, m5
    pcmpeqw  m4, m5
    pmulhrsw m5, m3, m7    ; propagate_amount = (propagate_amount * bipred_weight + 32) >> 6
%if cpuflag(avx)
    pblendvb m5, m3, m5, m4
%else
    pand     m5, m4
    pandn    m4, m3
    por      m5, m4        ; if( lists_used == 3 )
                           ;     propagate_amount = (propagate_amount * bipred_weight + 32) >> 6
%endif

    movu     m0, [r0+r4*4] ; x,y
    movu     m1, [r0+r4*4+mmsize]

    psraw    m2, m0, 5
    psraw    m3, m1, 5
    mova     m4, [pd_4]
    paddw    m2, m6        ; {mbx, mby} = ({x,y}>>5)+{h->mb.i_mb_x,h->mb.i_mb_y}
    paddw    m6, m4        ; {mbx, mby} += {4, 0}
    paddw    m3, m6        ; {mbx, mby} = ({x,y}>>5)+{h->mb.i_mb_x,h->mb.i_mb_y}
    paddw    m6, m4        ; {mbx, mby} += {4, 0}

    mova [r3+mmsize*0], m2
    mova [r3+mmsize*1], m3

    mova     m3, [pw_31]
    pand     m0, m3        ; x &= 31
    pand     m1, m3        ; y &= 31
    packuswb m0, m1
    psrlw    m1, m0, 3
    pand     m0, m3        ; x
    SWAP      1, 3
    pandn    m1, m3        ; y premultiplied by (1<<5) for later use of pmulhrsw

    mova     m3, [pw_32]
    psubw    m3, m0        ; 32 - x
    mova     m4, [pw_1024]
    psubw    m4, m1        ; (32 - y) << 5

    pmullw   m2, m3, m4    ; idx0weight = (32-y)*(32-x) << 5
    pmullw   m4, m0        ; idx1weight = (32-y)*x << 5
    pmullw   m0, m1        ; idx3weight = y*x << 5
    pmullw   m1, m3        ; idx2weight = y*(32-x) << 5

    ; avoid overflow in the input to pmulhrsw
    psrlw    m3, m2, 15
    psubw    m2, m3        ; idx0weight -= (idx0weight == 32768)

    pmulhrsw m2, m5        ; idx0weight * propagate_amount + 512 >> 10
    pmulhrsw m4, m5        ; idx1weight * propagate_amount + 512 >> 10
    pmulhrsw m1, m5        ; idx2weight * propagate_amount + 512 >> 10
    pmulhrsw m0, m5        ; idx3weight * propagate_amount + 512 >> 10

    SBUTTERFLY wd, 2, 4, 3
    SBUTTERFLY wd, 1, 0, 3
    mova [r3+mmsize*2], m2
    mova [r3+mmsize*3], m4
    mova [r3+mmsize*4], m1
    mova [r3+mmsize*5], m0
    add     r4d, mmsize/2
    add      r3, mmsize*6
    cmp     r4d, r5d
    jl .loop
    REP_RET
%endmacro

INIT_XMM ssse3
MBTREE_PROPAGATE_LIST
INIT_XMM avx
MBTREE_PROPAGATE_LIST

INIT_YMM avx2
cglobal mbtree_propagate_list_internal, 4+2*UNIX64,5+UNIX64,8
    mova          xm4, [pw_0xc000]
%if UNIX64
    shl           r4d, 9
    shl           r5d, 16
    movd          xm5, r4d
    movd          xm6, r5d
    vpbroadcastw  xm5, xm5
    vpbroadcastd   m6, xm6
%else
    vpbroadcastw  xm5, r4m
    vpbroadcastd   m6, r5m
    psllw         xm5, 9             ; bipred_weight << 9
    pslld          m6, 16
%endif
    mov           r4d, r6m
    lea            r1, [r1+r4*2]
    lea            r2, [r2+r4*2]
    lea            r0, [r0+r4*4]
    neg            r4
    por            m6, [pd_0123]     ; 0 y 1 y 2 y 3 y 4 y 5 y 6 y 7 y
    vbroadcasti128 m7, [pw_31]
.loop:
    mova          xm3, [r1+r4*2]
    pand          xm0, xm4, [r2+r4*2]
    pmulhrsw      xm1, xm3, xm5      ; bipred_amount = (propagate_amount * bipred_weight + 32) >> 6
    pcmpeqw       xm0, xm4
    pblendvb      xm3, xm3, xm1, xm0 ; (lists_used == 3) ? bipred_amount : propagate_amount
    vpermq         m3, m3, q1100

    movu           m0, [r0+r4*4]     ; {x, y}
    vbroadcasti128 m1, [pd_8]
    psraw          m2, m0, 5
    paddw          m2, m6            ; {mbx, mby} = ({x, y} >> 5) + {h->mb.i_mb_x, h->mb.i_mb_y}
    paddw          m6, m1            ; i_mb_x += 8
    mova         [r3], m2

    mova           m1, [pw_32]
    pand           m0, m7
    psubw          m1, m0
    packuswb       m1, m0            ; {32-x, 32-y} {x, y} {32-x, 32-y} {x, y}
    psrlw          m0, m1, 3
    pand           m1, [pw_00ff]     ; 32-x x 32-x x
    pandn          m0, m7, m0        ; (32-y y 32-y y) << 5
    pshufd         m2, m1, q1032
    pmullw         m1, m0            ; idx0 idx3 idx0 idx3
    pmullw         m2, m0            ; idx1 idx2 idx1 idx2

    pmulhrsw       m0, m1, m3        ; (idx0 idx3 idx0 idx3) * propagate_amount + 512 >> 10
    pmulhrsw       m2, m3            ; (idx1 idx2 idx1 idx2) * propagate_amount + 512 >> 10
    psignw         m0, m1            ; correct potential overflow in the idx0 input to pmulhrsw
    punpcklwd      m1, m0, m2        ; idx01weight
    punpckhwd      m2, m0            ; idx23weight
    mova      [r3+32], m1
    mova      [r3+64], m2
    add            r3, 3*mmsize
    add            r4, 8
    jl .loop
    RET

%if ARCH_X86_64
;-----------------------------------------------------------------------------
; void x264_mbtree_propagate_list_internal_avx512( size_t len, uint16_t *ref_costs, int16_t (*mvs)[2], int16_t *propagate_amount,
;                                                  uint16_t *lowres_costs, int bipred_weight, int mb_y,
;                                                  int width, int height, int stride, int list_mask );
;-----------------------------------------------------------------------------
INIT_ZMM avx512
cglobal mbtree_propagate_list_internal, 5,7,21
    mova          xm16, [pw_0xc000]
    vpbroadcastw  xm17, r5m            ; bipred_weight << 9
    vpbroadcastw  ym18, r10m           ; 1 << (list+LOWRES_COST_SHIFT)
    vbroadcasti32x8 m5, [mbtree_prop_list_avx512_shuf]
    vbroadcasti32x8 m6, [pd_0123]
    vpord           m6, r6m {1to16}    ; 0 y 1 y 2 y 3 y 4 y 5 y 6 y 7 y
    vbroadcasti128  m7, [pd_8]
    vbroadcasti128  m8, [pw_31]
    vbroadcasti128  m9, [pw_32]
    psllw          m10, m9, 4
    pcmpeqw       ym19, ym19           ; pw_m1
    vpbroadcastw  ym20, r7m            ; width
    psrld          m11, m7, 3          ; pd_1
    psrld          m12, m8, 16         ; pd_31
    vpbroadcastd   m13, r8m            ; height
    vpbroadcastd   m14, r9m            ; stride
    pslld          m15, m14, 16
    por            m15, m11            ; {1, stride, 1, stride} ...
    lea             r4, [r4+2*r0]      ; lowres_costs
    lea             r3, [r3+2*r0]      ; propagate_amount
    lea             r2, [r2+4*r0]      ; mvs
    neg             r0
    mov            r6d, 0x5555ffff
    kmovd           k4, r6d
    kshiftrd        k5, k4, 16         ; 0x5555
    kshiftlw        k6, k4, 8          ; 0xff00
.loop:
    vbroadcasti128 ym1, [r4+2*r0]
    mova           xm4, [r3+2*r0]
    vpcmpuw         k1, xm1, xm16, 5   ; if (lists_used == 3)
    vpmulhrsw      xm4 {k1}, xm17      ;     propagate_amount = (propagate_amount * bipred_weight + 32) >> 6
    vptestmw        k1, ym1, ym18
    vpermw          m4, m5, m4

    vbroadcasti32x8 m3, [r2+4*r0]      ; {mvx, mvy}
    psraw           m0, m3, 5
    paddw           m0, m6             ; {mbx, mby} = ({x, y} >> 5) + {h->mb.i_mb_x, h->mb.i_mb_y}
    paddd           m6, m7             ; i_mb_x += 8
    pand            m3, m8             ; {x, y}
    vprold          m1, m3, 20         ; {y, x} << 4
    vpsubw          m3 {k4}, m9, m3    ; {32-x, 32-y}, {32-x, y}
    vpsubw          m1 {k5}, m10, m1   ; ({32-y, x}, {y, x}) << 4
    pmullw          m3, m1
    paddsw          m3, m3             ; prevent signed overflow in idx0 (32*32<<5 == 0x8000)
    pmulhrsw        m2, m3, m4         ; idx01weight idx23weightp

    pslld          ym1, ym0, 16
    psubw          ym1, ym19
    vmovdqu16      ym1 {k5}, ym0
    vpcmpuw         k2, ym1, ym20, 1    ; {mbx, mbx+1} < width
    kunpckwd        k2, k2, k2
    psrad           m1, m0, 16
    vpaddd          m1 {k6}, m11
    vpcmpud         k1 {k1}, m1, m13, 1 ; mby < height | mby+1 < height

    pmaddwd         m0, m15
    vpaddd          m0 {k6}, m14        ; idx0 | idx2
    vmovdqu16       m2 {k2}{z}, m2      ; idx01weight | idx23weight
    vptestmd        k1 {k1}, m2, m2     ; mask out offsets with no changes

    ; We're handling dwords, but the offsets are in words so there may be partial overlaps.
    ; We can work around this by handling dword-aligned and -unaligned offsets separately.
    vptestmd        k0, m0, m11
    kandnw          k2, k0, k1          ; dword-aligned offsets
    kmovw           k3, k2
    vpgatherdd      m3 {k2}, [r1+2*m0]

    ; If there are conflicts in the offsets we have to handle them before storing the results.
    ; By creating a permutation index using vplzcntd we can resolve all conflicts in parallel
    ; in ceil(log2(n)) iterations where n is the largest number of duplicate offsets.
    vpconflictd     m4, m0
    vpbroadcastmw2d m1, k1
    vptestmd        k2, m1, m4
    ktestw          k2, k2
    jz .no_conflicts
    pand            m1, m4              ; mask away unused offsets to avoid false positives
    vplzcntd        m1, m1
    pxor            m1, m12             ; lzcnt gives us the distance from the msb, we want it from the lsb
.conflict_loop:
    vpermd          m4 {k2}{z}, m1, m2
    vpermd          m1 {k2}, m1, m1     ; shift the index one step forward
    paddsw          m2, m4              ; add the weights of conflicting offsets
    vpcmpd          k2, m1, m12, 2
    ktestw          k2, k2
    jnz .conflict_loop
.no_conflicts:
    paddsw          m3, m2
    vpscatterdd [r1+2*m0] {k3}, m3
    kandw           k1, k0, k1          ; dword-unaligned offsets
    kmovw           k2, k1
    vpgatherdd      m1 {k1}, [r1+2*m0]
    paddsw          m1, m2              ; all conflicts have already been resolved
    vpscatterdd [r1+2*m0] {k2}, m1
    add             r0, 8
    jl .loop
    RET
%endif

%macro MBTREE_FIX8 0
;-----------------------------------------------------------------------------
; void mbtree_fix8_pack( uint16_t *dst, float *src, int count )
;-----------------------------------------------------------------------------
cglobal mbtree_fix8_pack, 3,4
%if mmsize == 32
    vbroadcastf128 m2, [pf_256]
    vbroadcasti128 m3, [mbtree_fix8_pack_shuf]
%else
    movaps       m2, [pf_256]
    mova         m3, [mbtree_fix8_pack_shuf]
%endif
    sub         r2d, mmsize/2
    movsxdifnidn r2, r2d
    lea          r1, [r1+4*r2]
    lea          r0, [r0+2*r2]
    neg          r2
    jg .skip_loop
.loop:
    mulps        m0, m2, [r1+4*r2]
    mulps        m1, m2, [r1+4*r2+mmsize]
    cvttps2dq    m0, m0
    cvttps2dq    m1, m1
    packssdw     m0, m1
    pshufb       m0, m3
%if mmsize == 32
    vpermq       m0, m0, q3120
%endif
    mova  [r0+2*r2], m0
    add          r2, mmsize/2
    jle .loop
.skip_loop:
    sub          r2, mmsize/2
    jz .end
    ; Do the remaining values in scalar in order to avoid overreading src.
.scalar:
    mulss       xm0, xm2, [r1+4*r2+2*mmsize]
    cvttss2si   r3d, xm0
    rol         r3w, 8
    mov [r0+2*r2+mmsize], r3w
    inc          r2
    jl .scalar
.end:
    RET

;-----------------------------------------------------------------------------
; void mbtree_fix8_unpack( float *dst, uint16_t *src, int count )
;-----------------------------------------------------------------------------
cglobal mbtree_fix8_unpack, 3,4
%if mmsize == 32
    vbroadcastf128 m2, [pf_inv16777216]
%else
    movaps       m2, [pf_inv16777216]
    mova         m4, [mbtree_fix8_unpack_shuf+16]
%endif
    mova         m3, [mbtree_fix8_unpack_shuf]
    sub         r2d, mmsize/2
    movsxdifnidn r2, r2d
    lea          r1, [r1+2*r2]
    lea          r0, [r0+4*r2]
    neg          r2
    jg .skip_loop
.loop:
%if mmsize == 32
    vbroadcasti128 m0, [r1+2*r2]
    vbroadcasti128 m1, [r1+2*r2+16]
    pshufb       m0, m3
    pshufb       m1, m3
%else
    mova         m1, [r1+2*r2]
    pshufb       m0, m1, m3
    pshufb       m1, m4
%endif
    cvtdq2ps     m0, m0
    cvtdq2ps     m1, m1
    mulps        m0, m2
    mulps        m1, m2
    movaps [r0+4*r2], m0
    movaps [r0+4*r2+mmsize], m1
    add          r2, mmsize/2
    jle .loop
.skip_loop:
    sub          r2, mmsize/2
    jz .end
.scalar:
    movzx       r3d, word [r1+2*r2+mmsize]
    bswap       r3d
    ; Use 3-arg cvtsi2ss as a workaround for the fact that the instruction has a stupid dependency on
    ; dst which causes terrible performance when used in a loop otherwise. Blame Intel for poor design.
    cvtsi2ss    xm0, xm2, r3d
    mulss       xm0, xm2
    movss [r0+4*r2+2*mmsize], xm0
    inc          r2
    jl .scalar
.end:
    RET
%endmacro

INIT_XMM ssse3
MBTREE_FIX8
INIT_YMM avx2
MBTREE_FIX8

%macro MBTREE_FIX8_AVX512_END 0
    add      r2, mmsize/2
    jle .loop
    cmp     r2d, mmsize/2
    jl .tail
    RET
.tail:
    ; Do the final loop iteration with partial masking to handle the remaining elements.
    shrx    r3d, r3d, r2d ; (1 << count) - 1
    kmovd    k1, r3d
    kshiftrd k2, k1, 16
    jmp .loop
%endmacro

INIT_ZMM avx512
cglobal mbtree_fix8_pack, 3,4
    vbroadcastf32x4 m2, [pf_256]
    vbroadcasti32x4 m3, [mbtree_fix8_pack_shuf]
    psrld       xm4, xm3, 4
    pmovzxbq     m4, xm4
    sub         r2d, mmsize/2
    mov         r3d, -1
    movsxdifnidn r2, r2d
    lea          r1, [r1+4*r2]
    lea          r0, [r0+2*r2]
    neg          r2
    jg .tail
    kmovd        k1, r3d
    kmovw        k2, k1
.loop:
    vmulps       m0 {k1}{z}, m2, [r1+4*r2]
    vmulps       m1 {k2}{z}, m2, [r1+4*r2+mmsize]
    cvttps2dq    m0, m0
    cvttps2dq    m1, m1
    packssdw     m0, m1
    pshufb       m0, m3
    vpermq       m0, m4, m0
    vmovdqu16 [r0+2*r2] {k1}, m0
    MBTREE_FIX8_AVX512_END

cglobal mbtree_fix8_unpack, 3,4
    vbroadcasti32x8 m3, [mbtree_fix8_unpack_shuf]
    vbroadcastf32x4 m2, [pf_inv16777216]
    sub         r2d, mmsize/2
    mov         r3d, -1
    movsxdifnidn r2, r2d
    lea          r1, [r1+2*r2]
    lea          r0, [r0+4*r2]
    neg          r2
    jg .tail
    kmovw        k1, r3d
    kmovw        k2, k1
.loop:
    mova         m1, [r1+2*r2]
    vshufi32x4   m0, m1, m1, q1100
    vshufi32x4   m1, m1, m1, q3322
    pshufb       m0, m3
    pshufb       m1, m3
    cvtdq2ps     m0, m0
    cvtdq2ps     m1, m1
    mulps        m0, m2
    mulps        m1, m2
    vmovaps [r0+4*r2] {k1}, m0
    vmovaps [r0+4*r2+mmsize] {k2}, m1
    MBTREE_FIX8_AVX512_END
