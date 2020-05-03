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
