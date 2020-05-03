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
