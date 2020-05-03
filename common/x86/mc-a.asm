;*****************************************************************************
;* mc-a.asm: x86 motion compensation
;*****************************************************************************
;* Copyright (C) 2003-2019 x264 project
;*
;* Authors: Loren Merritt <lorenm@u.washington.edu>
;*          Fiona Glaser <fiona@x264.com>
;*          Laurent Aimar <fenrir@via.ecp.fr>
;*          Dylan Yudaken <dyudaken@gmail.com>
;*          Holger Lubitz <holger@lubitz.org>
;*          Min Chen <chenm001.163.com>
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

ch_shuf: times 2 db 0,2,2,4,4,6,6,8,1,3,3,5,5,7,7,9
ch_shuf_adj: times 8 db 0
             times 8 db 2
             times 8 db 4
             times 8 db 6
sq_1: times 1 dq 1

ALIGN 32
deinterleave_shuf:           db  0, 2, 4, 6, 8,10,12,14, 1, 3, 5, 7, 9,11,13,15
copy_swap_shuf:              db  1, 0, 3, 2, 5, 4, 7, 6, 9, 8,11,10,13,12,15,14
hpel_shuf:                   db  0, 8, 1, 9, 2,10, 3,11, 4,12, 5,13, 6,14, 7,15
pb_64:               times 4 db 64
pw_1024:             times 2 dw 1024
filt_mul20:          times 4 db 20
filt_mul15:          times 2 db 1, -5
filt_mul51:          times 2 db -5, 1


SECTION .text

cextern pb_0
cextern pw_1
cextern pw_4
cextern pw_8
cextern pw_32
cextern pw_64
cextern pw_512
cextern pw_00ff
cextern pw_pixel_max
cextern sw_64
cextern pd_32
cextern deinterleave_shufd
cextern pw_3fff

;=============================================================================
; pixel avg2
;=============================================================================
%if HIGH_BIT_DEPTH == 0
;-----------------------------------------------------------------------------
; void pixel_avg2_w4( uint8_t *dst,  intptr_t dst_stride,
;                     uint8_t *src1, intptr_t src_stride,
;                     uint8_t *src2, int height );
;-----------------------------------------------------------------------------
%macro AVG2_W8 2
cglobal pixel_avg2_w%1_mmx2, 6,7
    sub    r4, r2
    lea    r6, [r4+r3]
.height_loop:
    %2     mm0, [r2]
    %2     mm1, [r2+r3]
    pavgb  mm0, [r2+r4]
    pavgb  mm1, [r2+r6]
    lea    r2, [r2+r3*2]
    %2     [r0], mm0
    %2     [r0+r1], mm1
    lea    r0, [r0+r1*2]
    sub    r5d, 2
    jg     .height_loop
    RET
%endmacro

INIT_MMX
AVG2_W8 4, movd
AVG2_W8 8, movq

%macro AVG2_W16 2
cglobal pixel_avg2_w%1_mmx2, 6,7
    sub    r2, r4
    lea    r6, [r2+r3]
.height_loop:
    movq   mm0, [r4]
    %2     mm1, [r4+8]
    movq   mm2, [r4+r3]
    %2     mm3, [r4+r3+8]
    pavgb  mm0, [r4+r2]
    pavgb  mm1, [r4+r2+8]
    pavgb  mm2, [r4+r6]
    pavgb  mm3, [r4+r6+8]
    lea    r4, [r4+r3*2]
    movq   [r0], mm0
    %2     [r0+8], mm1
    movq   [r0+r1], mm2
    %2     [r0+r1+8], mm3
    lea    r0, [r0+r1*2]
    sub    r5d, 2
    jg     .height_loop
    RET
%endmacro

AVG2_W16 12, movd
AVG2_W16 16, movq

cglobal pixel_avg2_w20_mmx2, 6,7
    sub    r2, r4
    lea    r6, [r2+r3]
.height_loop:
    movq   mm0, [r4]
    movq   mm1, [r4+8]
    movd   mm2, [r4+16]
    movq   mm3, [r4+r3]
    movq   mm4, [r4+r3+8]
    movd   mm5, [r4+r3+16]
    pavgb  mm0, [r4+r2]
    pavgb  mm1, [r4+r2+8]
    pavgb  mm2, [r4+r2+16]
    pavgb  mm3, [r4+r6]
    pavgb  mm4, [r4+r6+8]
    pavgb  mm5, [r4+r6+16]
    lea    r4, [r4+r3*2]
    movq   [r0], mm0
    movq   [r0+8], mm1
    movd   [r0+16], mm2
    movq   [r0+r1], mm3
    movq   [r0+r1+8], mm4
    movd   [r0+r1+16], mm5
    lea    r0, [r0+r1*2]
    sub    r5d, 2
    jg     .height_loop
    RET

INIT_XMM
cglobal pixel_avg2_w16_sse2, 6,7
    sub    r4, r2
    lea    r6, [r4+r3]
.height_loop:
    movu   m0, [r2]
    movu   m2, [r2+r3]
    movu   m1, [r2+r4]
    movu   m3, [r2+r6]
    lea    r2, [r2+r3*2]
    pavgb  m0, m1
    pavgb  m2, m3
    mova [r0], m0
    mova [r0+r1], m2
    lea    r0, [r0+r1*2]
    sub   r5d, 2
    jg .height_loop
    RET

cglobal pixel_avg2_w20_sse2, 6,7
    sub    r2, r4
    lea    r6, [r2+r3]
.height_loop:
    movu   m0, [r4]
    movu   m2, [r4+r3]
    movu   m1, [r4+r2]
    movu   m3, [r4+r6]
    movd  mm4, [r4+16]
    movd  mm5, [r4+r3+16]
    pavgb  m0, m1
    pavgb  m2, m3
    pavgb mm4, [r4+r2+16]
    pavgb mm5, [r4+r6+16]
    lea    r4, [r4+r3*2]
    mova [r0], m0
    mova [r0+r1], m2
    movd [r0+16], mm4
    movd [r0+r1+16], mm5
    lea    r0, [r0+r1*2]
    sub   r5d, 2
    jg .height_loop
    RET

INIT_YMM avx2
cglobal pixel_avg2_w20, 6,7
    sub    r2, r4
    lea    r6, [r2+r3]
.height_loop:
    movu   m0, [r4]
    movu   m1, [r4+r3]
    pavgb  m0, [r4+r2]
    pavgb  m1, [r4+r6]
    lea    r4, [r4+r3*2]
    mova [r0], m0
    mova [r0+r1], m1
    lea    r0, [r0+r1*2]
    sub    r5d, 2
    jg     .height_loop
    RET

; Cacheline split code for processors with high latencies for loads
; split over cache lines.  See sad-a.asm for a more detailed explanation.
; This particular instance is complicated by the fact that src1 and src2
; can have different alignments.  For simplicity and code size, only the
; MMX cacheline workaround is used.  As a result, in the case of SSE2
; pixel_avg, the cacheline check functions calls the SSE2 version if there
; is no cacheline split, and the MMX workaround if there is.

%macro INIT_SHIFT 2
    and    eax, 7
    shl    eax, 3
    movd   %1, [sw_64]
    movd   %2, eax
    psubw  %1, %2
%endmacro

%macro AVG_CACHELINE_START 0
    %assign stack_offset 0
    INIT_SHIFT mm6, mm7
    mov    eax, r4m
    INIT_SHIFT mm4, mm5
    PROLOGUE 6,6
    and    r2, ~7
    and    r4, ~7
    sub    r4, r2
.height_loop:
%endmacro

%macro AVG_CACHELINE_LOOP 2
    movq   mm1, [r2+%1]
    movq   mm0, [r2+8+%1]
    movq   mm3, [r2+r4+%1]
    movq   mm2, [r2+r4+8+%1]
    psrlq  mm1, mm7
    psllq  mm0, mm6
    psrlq  mm3, mm5
    psllq  mm2, mm4
    por    mm0, mm1
    por    mm2, mm3
    pavgb  mm2, mm0
    %2 [r0+%1], mm2
%endmacro

%macro AVG_CACHELINE_FUNC 2
pixel_avg2_w%1_cache_mmx2:
    AVG_CACHELINE_START
    AVG_CACHELINE_LOOP 0, movq
%if %1>8
    AVG_CACHELINE_LOOP 8, movq
%if %1>16
    AVG_CACHELINE_LOOP 16, movd
%endif
%endif
    add    r2, r3
    add    r0, r1
    dec    r5d
    jg .height_loop
    RET
%endmacro

%macro AVG_CACHELINE_CHECK 3 ; width, cacheline, instruction set
%if %1 == 12
;w12 isn't needed because w16 is just as fast if there's no cacheline split
%define cachesplit pixel_avg2_w16_cache_mmx2
%else
%define cachesplit pixel_avg2_w%1_cache_mmx2
%endif
cglobal pixel_avg2_w%1_cache%2_%3
    mov    eax, r2m
    and    eax, %2-1
    cmp    eax, (%2-%1-(%1 % 8))
%if %1==12||%1==20
    jbe pixel_avg2_w%1_%3
%else
    jb pixel_avg2_w%1_%3
%endif
%if 0 ; or %1==8 - but the extra branch seems too expensive
    ja cachesplit
%if ARCH_X86_64
    test      r4b, 1
%else
    test byte r4m, 1
%endif
    jz pixel_avg2_w%1_%3
%else
    or     eax, r4m
    and    eax, 7
    jz pixel_avg2_w%1_%3
    mov    eax, r2m
%endif
%if mmsize==16 || (%1==8 && %2==64)
    AVG_CACHELINE_FUNC %1, %2
%else
    jmp cachesplit
%endif
%endmacro

INIT_MMX
AVG_CACHELINE_CHECK  8, 64, mmx2
AVG_CACHELINE_CHECK 12, 64, mmx2
%if ARCH_X86_64 == 0
AVG_CACHELINE_CHECK 16, 64, mmx2
AVG_CACHELINE_CHECK 20, 64, mmx2
AVG_CACHELINE_CHECK  8, 32, mmx2
AVG_CACHELINE_CHECK 12, 32, mmx2
AVG_CACHELINE_CHECK 16, 32, mmx2
AVG_CACHELINE_CHECK 20, 32, mmx2
%endif
INIT_XMM
AVG_CACHELINE_CHECK 16, 64, sse2
AVG_CACHELINE_CHECK 20, 64, sse2

; computed jump assumes this loop is exactly 48 bytes
%macro AVG16_CACHELINE_LOOP_SSSE3 2 ; alignment
ALIGN 16
avg_w16_align%1_%2_ssse3:
%if %1==0 && %2==0
    movdqa  xmm1, [r2]
    pavgb   xmm1, [r2+r4]
    add    r2, r3
%elif %1==0
    movdqa  xmm1, [r2+r4+16]
    palignr xmm1, [r2+r4], %2
    pavgb   xmm1, [r2]
    add    r2, r3
%elif %2&15==0
    movdqa  xmm1, [r2+16]
    palignr xmm1, [r2], %1
    pavgb   xmm1, [r2+r4]
    add    r2, r3
%else
    movdqa  xmm1, [r2+16]
    movdqa  xmm2, [r2+r4+16]
    palignr xmm1, [r2], %1
    palignr xmm2, [r2+r4], %2&15
    add    r2, r3
    pavgb   xmm1, xmm2
%endif
    movdqa  [r0], xmm1
    add    r0, r1
    dec    r5d
    jg     avg_w16_align%1_%2_ssse3
    ret
%if %1==0
    ; make sure the first ones don't end up short
    ALIGN 16
    times (48-($-avg_w16_align%1_%2_ssse3))>>4 nop
%endif
%endmacro

cglobal pixel_avg2_w16_cache64_ssse3
%if 0 ; seems both tests aren't worth it if src1%16==0 is optimized
    mov   eax, r2m
    and   eax, 0x3f
    cmp   eax, 0x30
    jb pixel_avg2_w16_sse2
    or    eax, r4m
    and   eax, 7
    jz pixel_avg2_w16_sse2
%endif
    PROLOGUE 6, 8
    lea    r6, [r4+r2]
    and    r4, ~0xf
    and    r6, 0x1f
    and    r2, ~0xf
    lea    r6, [r6*3]    ;(offset + align*2)*3
    sub    r4, r2
    shl    r6, 4         ;jump = (offset + align*2)*48
%define avg_w16_addr avg_w16_align1_1_ssse3-(avg_w16_align2_2_ssse3-avg_w16_align1_1_ssse3)
%if ARCH_X86_64
    lea    r7, [avg_w16_addr]
    add    r6, r7
%else
    lea    r6, [avg_w16_addr + r6]
%endif
    TAIL_CALL r6, 1

%assign j 0
%assign k 1
%rep 16
AVG16_CACHELINE_LOOP_SSSE3 j, j
AVG16_CACHELINE_LOOP_SSSE3 j, k
%assign j j+1
%assign k k+1
%endrep
%endif ; !HIGH_BIT_DEPTH

;=============================================================================
; pixel copy
;=============================================================================

%macro COPY1 2
    movu  m0, [r2]
    movu  m1, [r2+r3]
    movu  m2, [r2+r3*2]
    movu  m3, [r2+%2]
    mova  [r0],      m0
    mova  [r0+r1],   m1
    mova  [r0+r1*2], m2
    mova  [r0+%1],   m3
%endmacro

%macro COPY2 2-4 0, 1
    movu  m0, [r2+%3*mmsize]
    movu  m1, [r2+%4*mmsize]
    movu  m2, [r2+r3+%3*mmsize]
    movu  m3, [r2+r3+%4*mmsize]
    mova  [r0+%3*mmsize],      m0
    mova  [r0+%4*mmsize],      m1
    mova  [r0+r1+%3*mmsize],   m2
    mova  [r0+r1+%4*mmsize],   m3
    movu  m0, [r2+r3*2+%3*mmsize]
    movu  m1, [r2+r3*2+%4*mmsize]
    movu  m2, [r2+%2+%3*mmsize]
    movu  m3, [r2+%2+%4*mmsize]
    mova  [r0+r1*2+%3*mmsize], m0
    mova  [r0+r1*2+%4*mmsize], m1
    mova  [r0+%1+%3*mmsize],   m2
    mova  [r0+%1+%4*mmsize],   m3
%endmacro

%macro COPY4 2
    COPY2 %1, %2, 0, 1
    COPY2 %1, %2, 2, 3
%endmacro

;-----------------------------------------------------------------------------
; void mc_copy_w4( uint8_t *dst, intptr_t i_dst_stride,
;                  uint8_t *src, intptr_t i_src_stride, int i_height )
;-----------------------------------------------------------------------------
INIT_MMX
cglobal mc_copy_w4_mmx, 4,6
    FIX_STRIDES r1, r3
    cmp dword r4m, 4
    lea     r5, [r3*3]
    lea     r4, [r1*3]
    je .end
%if HIGH_BIT_DEPTH == 0
    %define mova movd
    %define movu movd
%endif
    COPY1   r4, r5
    lea     r2, [r2+r3*4]
    lea     r0, [r0+r1*4]
.end:
    COPY1   r4, r5
    RET

%macro MC_COPY 1
%assign %%w %1*SIZEOF_PIXEL/mmsize
%if %%w > 0
cglobal mc_copy_w%1, 5,7
    FIX_STRIDES r1, r3
    lea     r6, [r3*3]
    lea     r5, [r1*3]
.height_loop:
    COPY %+ %%w r5, r6
    lea     r2, [r2+r3*4]
    lea     r0, [r0+r1*4]
    sub    r4d, 4
    jg .height_loop
    RET
%endif
%endmacro

INIT_MMX mmx
MC_COPY  8
MC_COPY 16
INIT_XMM sse
MC_COPY  8
MC_COPY 16
INIT_XMM aligned, sse
MC_COPY 16

;=============================================================================
; prefetch
;=============================================================================
; assumes 64 byte cachelines
; FIXME doesn't cover all pixels in high depth and/or 4:4:4

;-----------------------------------------------------------------------------
; void prefetch_fenc( pixel *pix_y,  intptr_t stride_y,
;                     pixel *pix_uv, intptr_t stride_uv, int mb_x )
;-----------------------------------------------------------------------------

%macro PREFETCH_FENC 1
%if ARCH_X86_64
cglobal prefetch_fenc_%1, 5,5
    FIX_STRIDES r1, r3
    and    r4d, 3
    mov    eax, r4d
    imul   r4d, r1d
    lea    r0,  [r0+r4*4+64*SIZEOF_PIXEL]
    prefetcht0  [r0]
    prefetcht0  [r0+r1]
    lea    r0,  [r0+r1*2]
    prefetcht0  [r0]
    prefetcht0  [r0+r1]

    imul   eax, r3d
    lea    r2,  [r2+rax*2+64*SIZEOF_PIXEL]
    prefetcht0  [r2]
    prefetcht0  [r2+r3]
%ifidn %1, 422
    lea    r2,  [r2+r3*2]
    prefetcht0  [r2]
    prefetcht0  [r2+r3]
%endif
    RET

%else
cglobal prefetch_fenc_%1, 0,3
    mov    r2, r4m
    mov    r1, r1m
    mov    r0, r0m
    FIX_STRIDES r1
    and    r2, 3
    imul   r2, r1
    lea    r0, [r0+r2*4+64*SIZEOF_PIXEL]
    prefetcht0 [r0]
    prefetcht0 [r0+r1]
    lea    r0, [r0+r1*2]
    prefetcht0 [r0]
    prefetcht0 [r0+r1]

    mov    r2, r4m
    mov    r1, r3m
    mov    r0, r2m
    FIX_STRIDES r1
    and    r2, 3
    imul   r2, r1
    lea    r0, [r0+r2*2+64*SIZEOF_PIXEL]
    prefetcht0 [r0]
    prefetcht0 [r0+r1]
%ifidn %1, 422
    lea    r0,  [r0+r1*2]
    prefetcht0  [r0]
    prefetcht0  [r0+r1]
%endif
    ret
%endif ; ARCH_X86_64
%endmacro

INIT_MMX mmx2
PREFETCH_FENC 420
PREFETCH_FENC 422

%if ARCH_X86_64
    DECLARE_REG_TMP 4
%else
    DECLARE_REG_TMP 2
%endif

cglobal prefetch_fenc_400, 2,3
    movifnidn  t0d, r4m
    FIX_STRIDES r1
    and        t0d, 3
    imul       t0d, r1d
    lea         r0, [r0+t0*4+64*SIZEOF_PIXEL]
    prefetcht0 [r0]
    prefetcht0 [r0+r1]
    lea         r0, [r0+r1*2]
    prefetcht0 [r0]
    prefetcht0 [r0+r1]
    RET

;-----------------------------------------------------------------------------
; void prefetch_ref( pixel *pix, intptr_t stride, int parity )
;-----------------------------------------------------------------------------
INIT_MMX mmx2
cglobal prefetch_ref, 3,3
    FIX_STRIDES r1
    dec    r2d
    and    r2d, r1d
    lea    r0,  [r0+r2*8+64*SIZEOF_PIXEL]
    lea    r2,  [r1*3]
    prefetcht0  [r0]
    prefetcht0  [r0+r1]
    prefetcht0  [r0+r1*2]
    prefetcht0  [r0+r2]
    lea    r0,  [r0+r1*4]
    prefetcht0  [r0]
    prefetcht0  [r0+r1]
    prefetcht0  [r0+r1*2]
    prefetcht0  [r0+r2]
    RET



;=============================================================================
; chroma MC
;=============================================================================

%if ARCH_X86_64
    DECLARE_REG_TMP 6,7,8
%else
    DECLARE_REG_TMP 0,1,2
%endif

%macro MC_CHROMA_START 1
%if ARCH_X86_64
    PROLOGUE 0,9,%1
%else
    PROLOGUE 0,6,%1
%endif
    movifnidn r3,  r3mp
    movifnidn r4d, r4m
    movifnidn r5d, r5m
    movifnidn t0d, r6m
    mov       t2d, t0d
    mov       t1d, r5d
    sar       t0d, 3
    sar       t1d, 3
    imul      t0d, r4d
    lea       t0d, [t0+t1*2]
    FIX_STRIDES t0d
    movsxdifnidn t0, t0d
    add       r3,  t0            ; src += (dx>>3) + (dy>>3) * src_stride
%endmacro

%macro UNPACK_UNALIGNED 3
%if mmsize == 8
    punpcklwd  %1, %3
%else
    movh       %2, %3
    punpcklwd  %1, %2
%endif
%endmacro

;-----------------------------------------------------------------------------
; void mc_chroma( uint8_t *dstu, uint8_t *dstv, intptr_t dst_stride,
;                 uint8_t *src, intptr_t src_stride,
;                 int dx, int dy,
;                 int width, int height )
;-----------------------------------------------------------------------------
%macro MC_CHROMA 0
cglobal mc_chroma
    MC_CHROMA_START 0
    FIX_STRIDES r4
    and       r5d, 7
%if ARCH_X86_64
    jz .mc1dy
%endif
    and       t2d, 7
%if ARCH_X86_64
    jz .mc1dx
%endif
    shl       r5d, 16
    add       t2d, r5d
    mov       t0d, t2d
    shl       t2d, 8
    sub       t2d, t0d
    add       t2d, 0x80008 ; (x<<24) + ((8-x)<<16) + (y<<8) + (8-y)
    cmp dword r7m, 4
%if mmsize==8
.skip_prologue:
%else
    jl mc_chroma_mmx2 %+ .skip_prologue
    WIN64_SPILL_XMM 9
%endif
    movd       m5, t2d
    movifnidn  r0, r0mp
    movifnidn  r1, r1mp
    movifnidn r2d, r2m
    movifnidn r5d, r8m
    pxor       m6, m6
    punpcklbw  m5, m6
%if mmsize==8
    pshufw     m7, m5, q3232
    pshufw     m6, m5, q0000
    pshufw     m5, m5, q1111
    jge .width4
%else
%if WIN64
    cmp dword r7m, 4 ; flags were clobbered by WIN64_SPILL_XMM
%endif
    pshufd     m7, m5, q1111
    punpcklwd  m5, m5
    pshufd     m6, m5, q0000
    pshufd     m5, m5, q1111
    jg .width8
%endif
%if HIGH_BIT_DEPTH
    add        r2, r2
    UNPACK_UNALIGNED m0, m1, m2, r3
%else
    movu       m0, [r3]
    UNPACK_UNALIGNED m0, m1, [r3+2]
    mova       m1, m0
    pand       m0, [pw_00ff]
    psrlw      m1, 8
%endif ; HIGH_BIT_DEPTH
    pmaddwd    m0, m7
    pmaddwd    m1, m7
    packssdw   m0, m1
    SWAP        3, 0
ALIGN 4
.loop2:
%if HIGH_BIT_DEPTH
    UNPACK_UNALIGNED m0, m1, m2, r3+r4
    pmullw     m3, m6
%else ; !HIGH_BIT_DEPTH
    movu       m0, [r3+r4]
    UNPACK_UNALIGNED m0, m1, [r3+r4+2]
    pmullw     m3, m6
    mova       m1, m0
    pand       m0, [pw_00ff]
    psrlw      m1, 8
%endif ; HIGH_BIT_DEPTH
    pmaddwd    m0, m7
    pmaddwd    m1, m7
    mova       m2, [pw_32]
    packssdw   m0, m1
    paddw      m2, m3
    mova       m3, m0
    pmullw     m0, m5
    paddw      m0, m2
    psrlw      m0, 6
%if HIGH_BIT_DEPTH
    movh     [r0], m0
%if mmsize == 8
    psrlq      m0, 32
    movh     [r1], m0
%else
    movhps   [r1], m0
%endif
%else ; !HIGH_BIT_DEPTH
    packuswb   m0, m0
    movd     [r0], m0
%if mmsize==8
    psrlq      m0, 16
%else
    psrldq     m0, 4
%endif
    movd     [r1], m0
%endif ; HIGH_BIT_DEPTH
    add        r3, r4
    add        r0, r2
    add        r1, r2
    dec       r5d
    jg .loop2
    RET

%if mmsize==8
.width4:
%if ARCH_X86_64
    mov        t0, r0
    mov        t1, r1
    mov        t2, r3
%if WIN64
    %define multy0 r4m
%else
    %define multy0 [rsp-8]
%endif
    mova    multy0, m5
%else
    mov       r3m, r3
    %define multy0 r4m
    mova    multy0, m5
%endif
%else
.width8:
%if ARCH_X86_64
    %define multy0 m8
    SWAP        8, 5
%else
    %define multy0 r0m
    mova    multy0, m5
%endif
%endif
    FIX_STRIDES r2
.loopx:
%if HIGH_BIT_DEPTH
    UNPACK_UNALIGNED m0, m2, m4, r3
    UNPACK_UNALIGNED m1, m3, m5, r3+mmsize
%else
    movu       m0, [r3]
    movu       m1, [r3+mmsize/2]
    UNPACK_UNALIGNED m0, m2, [r3+2]
    UNPACK_UNALIGNED m1, m3, [r3+2+mmsize/2]
    psrlw      m2, m0, 8
    psrlw      m3, m1, 8
    pand       m0, [pw_00ff]
    pand       m1, [pw_00ff]
%endif
    pmaddwd    m0, m7
    pmaddwd    m2, m7
    pmaddwd    m1, m7
    pmaddwd    m3, m7
    packssdw   m0, m2
    packssdw   m1, m3
    SWAP        4, 0
    SWAP        5, 1
    add        r3, r4
ALIGN 4
.loop4:
%if HIGH_BIT_DEPTH
    UNPACK_UNALIGNED m0, m1, m2, r3
    pmaddwd    m0, m7
    pmaddwd    m1, m7
    packssdw   m0, m1
    UNPACK_UNALIGNED m1, m2, m3, r3+mmsize
    pmaddwd    m1, m7
    pmaddwd    m2, m7
    packssdw   m1, m2
%else ; !HIGH_BIT_DEPTH
    movu       m0, [r3]
    movu       m1, [r3+mmsize/2]
    UNPACK_UNALIGNED m0, m2, [r3+2]
    UNPACK_UNALIGNED m1, m3, [r3+2+mmsize/2]
    psrlw      m2, m0, 8
    psrlw      m3, m1, 8
    pand       m0, [pw_00ff]
    pand       m1, [pw_00ff]
    pmaddwd    m0, m7
    pmaddwd    m2, m7
    pmaddwd    m1, m7
    pmaddwd    m3, m7
    packssdw   m0, m2
    packssdw   m1, m3
%endif ; HIGH_BIT_DEPTH
    pmullw     m4, m6
    pmullw     m5, m6
    mova       m2, [pw_32]
    paddw      m3, m2, m5
    paddw      m2, m4
    mova       m4, m0
    mova       m5, m1
    pmullw     m0, multy0
    pmullw     m1, multy0
    paddw      m0, m2
    paddw      m1, m3
    psrlw      m0, 6
    psrlw      m1, 6
%if HIGH_BIT_DEPTH
    movh     [r0], m0
    movh     [r0+mmsize/2], m1
%if mmsize==8
    psrlq      m0, 32
    psrlq      m1, 32
    movh     [r1], m0
    movh     [r1+mmsize/2], m1
%else
    movhps   [r1], m0
    movhps   [r1+mmsize/2], m1
%endif
%else ; !HIGH_BIT_DEPTH
    packuswb   m0, m1
%if mmsize==8
    pshufw     m1, m0, q0020
    pshufw     m0, m0, q0031
    movd     [r0], m1
    movd     [r1], m0
%else
    pshufd     m0, m0, q3120
    movq     [r0], m0
    movhps   [r1], m0
%endif
%endif ; HIGH_BIT_DEPTH
    add        r3, r4
    add        r0, r2
    add        r1, r2
    dec       r5d
    jg .loop4
%if mmsize!=8
    RET
%else
    sub dword r7m, 4
    jg .width8
    RET
.width8:
%if ARCH_X86_64
    lea        r3, [t2+8*SIZEOF_PIXEL]
    lea        r0, [t0+4*SIZEOF_PIXEL]
    lea        r1, [t1+4*SIZEOF_PIXEL]
%else
    mov        r3, r3m
    mov        r0, r0m
    mov        r1, r1m
    add        r3, 8*SIZEOF_PIXEL
    add        r0, 4*SIZEOF_PIXEL
    add        r1, 4*SIZEOF_PIXEL
%endif
    mov       r5d, r8m
    jmp .loopx
%endif

%if ARCH_X86_64 ; too many regs for x86_32
    RESET_MM_PERMUTATION
%if WIN64
    %assign stack_offset stack_offset - stack_size_padded
    %assign stack_size_padded 0
    %assign xmm_regs_used 0
%endif
.mc1dy:
    and       t2d, 7
    movd       m5, t2d
    mov       r6d, r4d ; pel_offset = dx ? 2 : src_stride
    jmp .mc1d
.mc1dx:
    movd       m5, r5d
    mov       r6d, 2*SIZEOF_PIXEL
.mc1d:
%if HIGH_BIT_DEPTH && mmsize == 16
    WIN64_SPILL_XMM 8
%endif
    mova       m4, [pw_8]
    SPLATW     m5, m5
    psubw      m4, m5
    movifnidn  r0, r0mp
    movifnidn  r1, r1mp
    movifnidn r2d, r2m
    FIX_STRIDES r2
    movifnidn r5d, r8m
    cmp dword r7m, 4
    jg .mc1d_w8
    mov        r7, r2
    mov        r8, r4
%if mmsize!=8
    shr       r5d, 1
%endif
.loop1d_w4:
%if HIGH_BIT_DEPTH
%if mmsize == 8
    movq       m0, [r3+0]
    movq       m2, [r3+8]
    movq       m1, [r3+r6+0]
    movq       m3, [r3+r6+8]
%else
    movu       m0, [r3]
    movu       m1, [r3+r6]
    add        r3, r8
    movu       m2, [r3]
    movu       m3, [r3+r6]
%endif
    SBUTTERFLY wd, 0, 2, 6
    SBUTTERFLY wd, 1, 3, 7
    SBUTTERFLY wd, 0, 2, 6
    SBUTTERFLY wd, 1, 3, 7
%if mmsize == 16
    SBUTTERFLY wd, 0, 2, 6
    SBUTTERFLY wd, 1, 3, 7
%endif
%else ; !HIGH_BIT_DEPTH
    movq       m0, [r3]
    movq       m1, [r3+r6]
%if mmsize!=8
    add        r3, r8
    movhps     m0, [r3]
    movhps     m1, [r3+r6]
%endif
    psrlw      m2, m0, 8
    psrlw      m3, m1, 8
    pand       m0, [pw_00ff]
    pand       m1, [pw_00ff]
%endif ; HIGH_BIT_DEPTH
    pmullw     m0, m4
    pmullw     m1, m5
    pmullw     m2, m4
    pmullw     m3, m5
    paddw      m0, [pw_4]
    paddw      m2, [pw_4]
    paddw      m0, m1
    paddw      m2, m3
    psrlw      m0, 3
    psrlw      m2, 3
%if HIGH_BIT_DEPTH
%if mmsize == 8
    xchg       r4, r8
    xchg       r2, r7
%endif
    movq     [r0], m0
    movq     [r1], m2
%if mmsize == 16
    add        r0, r7
    add        r1, r7
    movhps   [r0], m0
    movhps   [r1], m2
%endif
%else ; !HIGH_BIT_DEPTH
    packuswb   m0, m2
%if mmsize==8
    xchg       r4, r8
    xchg       r2, r7
    movd     [r0], m0
    psrlq      m0, 32
    movd     [r1], m0
%else
    movhlps    m1, m0
    movd     [r0], m0
    movd     [r1], m1
    add        r0, r7
    add        r1, r7
    psrldq     m0, 4
    psrldq     m1, 4
    movd     [r0], m0
    movd     [r1], m1
%endif
%endif ; HIGH_BIT_DEPTH
    add        r3, r4
    add        r0, r2
    add        r1, r2
    dec       r5d
    jg .loop1d_w4
    RET
.mc1d_w8:
    sub       r2, 4*SIZEOF_PIXEL
    sub       r4, 8*SIZEOF_PIXEL
    mov       r7, 4*SIZEOF_PIXEL
    mov       r8, 8*SIZEOF_PIXEL
%if mmsize==8
    shl       r5d, 1
%endif
    jmp .loop1d_w4
%endif ; ARCH_X86_64
%endmacro ; MC_CHROMA

%macro MC_CHROMA_SSSE3 0
cglobal mc_chroma
    MC_CHROMA_START 10-cpuflag(avx2)
    and       r5d, 7
    and       t2d, 7
    mov       t0d, r5d
    shl       t0d, 8
    sub       t0d, r5d
    mov       r5d, 8
    add       t0d, 8
    sub       r5d, t2d
    imul      t2d, t0d ; (x*255+8)*y
    imul      r5d, t0d ; (x*255+8)*(8-y)
    movd      xm6, t2d
    movd      xm7, r5d
%if cpuflag(cache64)
    mov       t0d, r3d
    and       t0d, 7
%if ARCH_X86_64
    lea        t1, [ch_shuf_adj]
    movddup   xm5, [t1 + t0*4]
%else
    movddup   xm5, [ch_shuf_adj + t0*4]
%endif
    paddb     xm5, [ch_shuf]
    and        r3, ~7
%else
    mova       m5, [ch_shuf]
%endif
    movifnidn  r0, r0mp
    movifnidn  r1, r1mp
    movifnidn r2d, r2m
    movifnidn r5d, r8m
%if cpuflag(avx2)
    vpbroadcastw m6, xm6
    vpbroadcastw m7, xm7
%else
    SPLATW     m6, m6
    SPLATW     m7, m7
%endif
%if ARCH_X86_64
    %define shiftround m8
    mova       m8, [pw_512]
%else
    %define shiftround [pw_512]
%endif
    cmp dword r7m, 4
    jg .width8

%if cpuflag(avx2)
.loop4:
    movu      xm0, [r3]
    movu      xm1, [r3+r4]
    vinserti128 m0, m0, [r3+r4], 1
    vinserti128 m1, m1, [r3+r4*2], 1
    pshufb     m0, m5
    pshufb     m1, m5
    pmaddubsw  m0, m7
    pmaddubsw  m1, m6
    paddw      m0, m1
    pmulhrsw   m0, shiftround
    packuswb   m0, m0
    vextracti128 xm1, m0, 1
    movd     [r0], xm0
    movd  [r0+r2], xm1
    psrldq    xm0, 4
    psrldq    xm1, 4
    movd     [r1], xm0
    movd  [r1+r2], xm1
    lea        r3, [r3+r4*2]
    lea        r0, [r0+r2*2]
    lea        r1, [r1+r2*2]
    sub       r5d, 2
    jg .loop4
    RET
.width8:
    movu      xm0, [r3]
    vinserti128 m0, m0, [r3+8], 1
    pshufb     m0, m5
.loop8:
    movu      xm3, [r3+r4]
    vinserti128 m3, m3, [r3+r4+8], 1
    pshufb     m3, m5
    pmaddubsw  m1, m0, m7
    pmaddubsw  m2, m3, m6
    pmaddubsw  m3, m3, m7

    movu      xm0, [r3+r4*2]
    vinserti128 m0, m0, [r3+r4*2+8], 1
    pshufb     m0, m5
    pmaddubsw  m4, m0, m6

    paddw      m1, m2
    paddw      m3, m4
    pmulhrsw   m1, shiftround
    pmulhrsw   m3, shiftround
    packuswb   m1, m3
    mova       m2, [deinterleave_shufd]
    vpermd     m1, m2, m1
    vextracti128 xm2, m1, 1
    movq      [r0], xm1
    movhps    [r1], xm1
    movq   [r0+r2], xm2
    movhps [r1+r2], xm2
%else
    movu       m0, [r3]
    pshufb     m0, m5
.loop4:
    movu       m1, [r3+r4]
    pshufb     m1, m5
    movu       m3, [r3+r4*2]
    pshufb     m3, m5
    mova       m4, m3
    pmaddubsw  m0, m7
    pmaddubsw  m2, m1, m7
    pmaddubsw  m1, m6
    pmaddubsw  m3, m6
    paddw      m1, m0
    paddw      m3, m2
    pmulhrsw   m1, shiftround
    pmulhrsw   m3, shiftround
    mova       m0, m4
    packuswb   m1, m3
    movd     [r0], m1
%if cpuflag(sse4)
    pextrd    [r1], m1, 1
    pextrd [r0+r2], m1, 2
    pextrd [r1+r2], m1, 3
%else
    movhlps    m3, m1
    movd  [r0+r2], m3
    psrldq     m1, 4
    psrldq     m3, 4
    movd     [r1], m1
    movd  [r1+r2], m3
%endif
    lea        r3, [r3+r4*2]
    lea        r0, [r0+r2*2]
    lea        r1, [r1+r2*2]
    sub       r5d, 2
    jg .loop4
    RET
.width8:
    movu       m0, [r3]
    pshufb     m0, m5
    movu       m1, [r3+8]
    pshufb     m1, m5
%if ARCH_X86_64
    SWAP        9, 6
    %define  mult1 m9
%else
    mova      r0m, m6
    %define  mult1 r0m
%endif
.loop8:
    movu       m2, [r3+r4]
    pshufb     m2, m5
    movu       m3, [r3+r4+8]
    pshufb     m3, m5
    mova       m4, m2
    mova       m6, m3
    pmaddubsw  m0, m7
    pmaddubsw  m1, m7
    pmaddubsw  m2, mult1
    pmaddubsw  m3, mult1
    paddw      m0, m2
    paddw      m1, m3
    pmulhrsw   m0, shiftround ; x + 32 >> 6
    pmulhrsw   m1, shiftround
    packuswb   m0, m1
    pshufd     m0, m0, q3120
    movq     [r0], m0
    movhps   [r1], m0

    movu       m2, [r3+r4*2]
    pshufb     m2, m5
    movu       m3, [r3+r4*2+8]
    pshufb     m3, m5
    mova       m0, m2
    mova       m1, m3
    pmaddubsw  m4, m7
    pmaddubsw  m6, m7
    pmaddubsw  m2, mult1
    pmaddubsw  m3, mult1
    paddw      m2, m4
    paddw      m3, m6
    pmulhrsw   m2, shiftround
    pmulhrsw   m3, shiftround
    packuswb   m2, m3
    pshufd     m2, m2, q3120
    movq   [r0+r2], m2
    movhps [r1+r2], m2
%endif
    lea        r3, [r3+r4*2]
    lea        r0, [r0+r2*2]
    lea        r1, [r1+r2*2]
    sub       r5d, 2
    jg .loop8
    RET
%endmacro

INIT_MMX mmx2
MC_CHROMA
INIT_XMM sse2
MC_CHROMA
INIT_XMM ssse3
MC_CHROMA_SSSE3
INIT_XMM cache64, ssse3
MC_CHROMA_SSSE3
INIT_XMM avx
MC_CHROMA_SSSE3 ; No known AVX CPU will trigger CPU_CACHELINE_64
INIT_YMM avx2
MC_CHROMA_SSSE3



;=============================================================================
; PIXEL_AVG_WEIGHT/PIXEL_AVG
;=============================================================================
INIT_XMM avx2
cglobal pixel_avg_2x2, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    mov            r6d, [rsp + 56]
%else
    mov            r6d, [rsp + 8]
%endif
    cmp            r6d, 32
    je             .avg_2x2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
    vmovd          m0, r6d
    vpbroadcastb   m0, m0
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....

    vmovd          m2, [r2]
    vmovd          m4, [r2 + r3]
    vpunpcklwd     m2, m2, m4
    vmovd          m3, [r4]
    vmovd          m4, [r4 + r5]
    vpunpcklwd     m3, m3, m4
    vpunpcklbw     m2, m2, m3
    vpmaddubsw     m2, m2, m0
    vpmulhrsw      m2, m2, m5
    vpackuswb      m2, m2, m2
    vpextrw        [r0], m2, 0
    vpextrw        [r0 + r1], m2, 1
    ret

ALIGN 16
.avg_2x2:
    vmovd          m0, [r2]
    vmovd          m1, [r2 + r3]
    vmovd          m2, [r4]
    vmovd          m3, [r4 + r5]
    vpavgb         m0, m0, m2
    vpavgb         m1, m1, m3
    vpextrw        [r0], m0, 0
    vpextrw        [r0 + r1], m1, 0
    ret


INIT_XMM avx2
cglobal avg_weight_2xN, 0, 0
    vmovd          m2, [r2]
    vmovd          m4, [r2 + r3]
    lea            r2, [r2 + r3 * 2]
    vpunpcklwd     m2, m2, m4
    vmovd          m3, [r4]
    vmovd          m4, [r4 + r5]
    lea            r4, [r4 + r5 * 2]
    vpunpcklwd     m3, m3, m4
    vmovd          m1, [r2]
    vmovd          m4, [r2 + r3]
    lea            r2, [r2 + r3 * 2]
    vpunpcklwd     m1, m1, m4
    vpunpckldq     m2, m2, m1
    vmovd          m1, [r4]
    vmovd          m4, [r4 + r5]
    lea            r4, [r4 + r5 * 2]
    vpunpcklwd     m1, m1, m4
    vpunpckldq     m3, m3, m1
    vpunpcklbw     m2, m2, m3
    vpmaddubsw     m2, m2, m0
    vpmulhrsw      m2, m2, m5
    vpackuswb      m2, m2, m2

    vpextrw        [r0], m2, 0
    vpextrw        [r0 + r1], m2, 1
    lea            r0, [r0 + r1 * 2]
    vpextrw        [r0], m2, 2
    vpextrw        [r0 + r1], m2, 3
    lea            r0, [r0 + r1 * 2]
    sub            r6d, 2
    jg             avg_weight_2xN_avx2
    ret

INIT_XMM avx2
cglobal avg_2xN, 0, 0
    vmovd          m0, [r2]
    vmovd          m1, [r2 + r3]
    lea            r2, [r2 + r3 * 2]
    vmovd          m2, [r4]
    vmovd          m3, [r4 + r5]
    lea            r4, [r4 + r5 * 2]
    vpavgb         m0, m0, m2
    vpavgb         m1, m1, m3
    vpextrw        [r0], m0, 0
    vpextrw        [r0 + r1], m1, 0
    lea            r0, [r0 + r1 * 2]
    dec            r6d
    jg             avg_2xN_avx2
    ret

INIT_XMM avx2
cglobal pixel_avg_2x4, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    cmp            dword [rsp + 56], 32
%else
    cmp            dword [rsp + 8], 32
%endif
    mov            r6d, 2
    je             avg_2xN_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_2xN_avx2

INIT_XMM avx2
cglobal pixel_avg_2x8, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    cmp            dword [rsp + 56], 32
%else
    cmp            dword [rsp + 8], 32
%endif
    mov            r6d, 4
    je             avg_2xN_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_2xN_avx2



INIT_XMM avx2
cglobal pixel_avg_4x2, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    mov            r6d, [rsp + 56]
%else
    mov            r6d, [rsp + 8]
%endif
    cmp            r6d, 32
    je             .avg_4x2

; avg_weight_4x2
    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
    vmovd          m0, r6d
    vpbroadcastb   m0, m0
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....

    vmovd          m2, [r2]
    vmovd          m4, [r2 + r3]
    vpunpckldq     m2, m2, m4
    vmovd          m3, [r4]
    vmovd          m4, [r4 + r5]
    vpunpckldq     m3, m3, m4
    vpunpcklbw     m2, m2, m3
    vpmaddubsw     m2, m2, m0
    vpmulhrsw      m2, m2, m5
    vpackuswb      m2, m2, m2

    vmovd          [r0], m2
    vpextrd        [r0 + r1], m2, 1
    ret

ALIGN 16
.avg_4x2:
    vmovd          m0, [r2]
    vmovd          m1, [r2 + r3]
    vmovd          m2, [r4]
    vmovd          m3, [r4 + r5]
    vpavgb         m0, m0, m2
    vpavgb         m1, m1, m3
    vmovd          [r0], m0
    vmovd          [r0 + r1], m1
    ret


INIT_XMM avx2
cglobal avg_weight_4xN, 0, 0
    vmovd          m2, [r2]
    vmovd          m4, [r2 + r3]
    lea            r2, [r2 + r3 * 2]
    vpunpckldq     m2, m2, m4
    vmovd          m3, [r4]
    vmovd          m4, [r4 + r5]
    lea            r4, [r4 + r5 * 2]
    vpunpckldq     m3, m3, m4
    vpunpcklbw     m2, m2, m3
    vpmaddubsw     m2, m2, m0
    vpmulhrsw      m2, m2, m5
    vpackuswb      m2, m2, m2

    vmovd          [r0], m2
    vpextrd        [r0 + r1], m2, 1
    lea            r0, [r0 + r1 * 2]
    dec            r6d
    jg             avg_weight_4xN_avx2
    ret

INIT_XMM avx2
cglobal avg_4xN, 0, 0
    vmovd          m0, [r2]
    vmovd          m1, [r2 + r3]
    lea            r2, [r2 + r3 * 2]
    vmovd          m2, [r4]
    vmovd          m3, [r4 + r5]
    lea            r4, [r4 + r5 * 2]
    vpavgb         m0, m0, m2
    vpavgb         m1, m1, m3
    vmovd          [r0], m0
    vmovd          [r0 + r1], m1
    lea            r0, [r0 + r1 * 2]
    dec            r6d
    jg             avg_4xN_avx2
    ret

INIT_XMM avx2
cglobal pixel_avg_4x4, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    cmp            dword [rsp + 56], 32
%else
    cmp            dword [rsp + 8], 32
%endif
    mov            r6d, 2
    je             avg_4xN_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_4xN_avx2

INIT_XMM avx2
cglobal pixel_avg_4x8, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    cmp            dword [rsp + 56], 32
%else
    cmp            dword [rsp + 8], 32
%endif
    mov            r6d, 4
    je             avg_4xN_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_4xN_avx2

INIT_XMM avx2
cglobal pixel_avg_4x16, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    cmp            dword [rsp + 56], 32
%else
    cmp            dword [rsp + 8], 32
%endif
    mov            r6d, 8
    je             avg_4xN_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_4xN_avx2


INIT_XMM avx2
cglobal avg_weight_8xN, 0, 0
    vmovq          m2, [r2]
    vmovq          m4, [r4]
    vpunpcklbw     m2, m2, m4
    vmovq          m3, [r2 + r3]
    vmovq          m4, [r4 + r5]
    vpunpcklbw     m3, m3, m4
    lea            r2, [r2 + r3 * 2]
    lea            r4, [r4 + r5 * 2]
    vpmaddubsw     m2, m2, m0
    vpmaddubsw     m3, m3, m0
    vpmulhrsw      m2, m2, m5
    vpmulhrsw      m3, m3, m5
    vpackuswb      m2, m2, m3
    vmovq          [r0], m2
    vmovhps        [r0 + r1], m2
    lea            r0, [r0 + r1 * 2]
    dec            r6d
    jg             avg_weight_8xN_avx2
    ret

INIT_XMM avx2
cglobal avg_8xN, 0, 0
    vmovq          m0, [r2]
    vmovq          m1, [r2 + r3]
    lea            r2, [r2 + r3 * 2]
    vmovq          m2, [r4]
    vmovq          m3, [r4 + r5]
    lea            r4, [r4 + r5 * 2]
    vpavgb         m0, m0, m2
    vpavgb         m1, m1, m3
    vmovq          [r0], m0
    vmovq          [r0 + r1], m1
    lea            r0, [r0 + r1 * 2]
    dec            r6d
    jg             avg_8xN_avx2
    ret

INIT_XMM avx2
cglobal pixel_avg_8x4, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    cmp            dword [rsp + 56], 32
%else
    cmp            dword [rsp + 8], 32
%endif
    mov            r6d, 2
    je             avg_8xN_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_8xN_avx2

INIT_XMM avx2
cglobal pixel_avg_8x8, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    cmp            dword [rsp + 56], 32
%else
    cmp            dword [rsp + 8], 32
%endif
    mov            r6d, 4
    je             avg_8xN_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_8xN_avx2

INIT_XMM avx2
cglobal pixel_avg_8x16, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    cmp            dword [rsp + 56], 32
%else
    cmp            dword [rsp + 8], 32
%endif
    mov            r6d, 8
    je             avg_8xN_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_8xN_avx2


INIT_YMM avx2
cglobal avg_weight_16xN, 0, 0
    vmovdqu        xm2, [r2]
    vinserti128    m2, m2, [r2 + r3], 1
    vmovdqu        xm3, [r4]
    vinserti128    m3, m3, [r4 + r5], 1
    lea            r2, [r2 + r3 * 2]
    lea            r4, [r4 + r5 * 2]
    vpunpckhbw     m4, m2, m3
    vpunpcklbw     m2, m2, m3
    vpmaddubsw     m2, m2, m0
    vpmaddubsw     m4, m4, m0
    vpmulhrsw      m2, m2, m5
    vpmulhrsw      m4, m4, m5
    vpackuswb      m2, m2, m4
    vmovdqu        [r0], xm2
    vextracti128   [r0 + r1], m2, 1
    lea            r0, [r0 + r1 * 2]
    dec            r6d
    jg             avg_weight_16xN_avx2
    RET

INIT_XMM avx2
cglobal avg_16xN, 0, 0
    vmovdqu        xm0, [r2]
    vmovdqu        xm1, [r2 + r3]
    lea            r2, [r2 + r3 * 2]
    vpavgb         xm0, xm0, [r4]
    vpavgb         xm1, xm1, [r4 + r5]
    lea            r4, [r4 + r5 * 2]
    vmovdqu        [r0], xm0
    vmovdqu        [r0 + r1], xm1
    lea            r0, [r0 + r1 * 2]
    dec            r6d
    jg             avg_16xN_avx2
    ret

INIT_YMM avx2
cglobal pixel_avg_16x8, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    cmp            dword [rsp + 56], 32
%else
    cmp            dword [rsp + 8], 32
%endif
    mov            r6d, 4
    je             avg_16xN_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_16xN_avx2

INIT_YMM avx2
cglobal pixel_avg_16x16, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    cmp            dword [rsp + 56], 32
%else
    cmp            dword [rsp + 8], 32
%endif
    mov            r6d, 8
    je             avg_16xN_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_16xN_avx2


;=============================================================================
; MC_WEIGHT/MC_OFFSET
;=============================================================================
INIT_XMM avx2
cglobal mc_offsetadd_w4, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    vmovd          m2, [r4]

.loop:
    vmovd          m0, [r2]
    vmovd          m1, [r2 + r3]
    vpaddusb       m0, m0, m2
    vpaddusb       m1, m1, m2
    vmovd          [r0], m0
    vmovd          [r0 + r1], m1
    lea            r0, [r0 + r1 * 2]
    lea            r2, [r2 + r3 * 2]
    sub            r5d, 2
    jg             .loop
    ret

INIT_XMM avx2
cglobal mc_offsetsub_w4, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    vmovd          m2, [r4]

.loop:
    vmovd          m0, [r2]
    vmovd          m1, [r2 + r3]
    vpsubusb       m0, m0, m2
    vpsubusb       m1, m1, m2
    vmovd          [r0], m0
    vmovd          [r0 + r1], m1
    lea            r0, [r0 + r1 * 2]
    lea            r2, [r2 + r3 * 2]
    sub            r5d, 2
    jg             .loop
    ret

INIT_XMM avx2
cglobal mc_weight_w4, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    vpbroadcastd   m2, [r4]
    vpbroadcastd   m3, [r4 + 16]
    vpxor          m4, m4, m4
    ; we can merge the shift step into the scale factor
    ; if (m3<<7) doesn't overflow an int16_t
    xor            r6d, r6d
    cmp            [r4 + 1], r6b
    je             .fast

.loop:
    vmovd          m0, [r2]
    vmovd          m1, [r2 + r3]
    vpunpckldq     m0, m0, m1
    vpunpcklbw     m0, m0, m4
    vpsllw         m0, m0, 7
    vpmulhrsw      m0, m0, m2
    vpaddw         m0, m0, m3
    vpackuswb      m0, m0, m0
    vmovd          [r0], m0
    vpextrd        [r0 + r1], m0, 1
    lea            r0, [r0 + r1 * 2]
    lea            r2, [r2 + r3 * 2]
    sub            r5d, 2
    jg             .loop
    ret

ALIGN 16
.fast:
    vpsllw         m2, m2, 7
.fastloop:
    vmovd          m0, [r2]
    vmovd          m1, [r2 + r3]
    vpunpckldq     m0, m0, m1
    vpunpcklbw     m0, m0, m4
    vpmulhrsw      m0, m0, m2
    vpaddw         m0, m0, m3
    vpackuswb      m0, m0, m0
    vmovd          [r0], m0
    vpextrd        [r0 + r1], m0, 1
    lea            r0, [r0 + r1 * 2]
    lea            r2, [r2 + r3 * 2]
    sub            r5d, 2
    jg             .fastloop
    ret

INIT_XMM avx2
cglobal mc_offsetadd_w8, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    vpbroadcastd   m2, [r4]

.loop:
    vmovq          m0, [r2]
    vmovq          m1, [r2 + r3]
    vpaddusb       m0, m0, m2
    vpaddusb       m1, m1, m2
    vmovq          [r0], m0
    vmovq          [r0 + r1], m1
    lea            r0, [r0 + r1 * 2]
    lea            r2, [r2 + r3 * 2]
    sub            r5d, 2
    jg             .loop
    ret

INIT_XMM avx2
cglobal mc_offsetsub_w8, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    vpbroadcastd   m2, [r4]

.loop:
    vmovq          m0, [r2]
    vmovq          m1, [r2 + r3]
    vpsubusb       m0, m0, m2
    vpsubusb       m1, m1, m2
    vmovq          [r0], m0
    vmovq          [r0 + r1], m1
    lea            r0, [r0 + r1 * 2]
    lea            r2, [r2 + r3 * 2]
    sub            r5d, 2
    jg             .loop
    ret


INIT_XMM avx2
cglobal mc_weight_w8, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    vpbroadcastd   m2, [r4]
    vpbroadcastd   m3, [r4 + 16]
    ; we can merge the shift step into the scale factor
    ; if (m3<<7) doesn't overflow an int16_t
    xor            r6d, r6d
    cmp            [r4 + 1], r6b
    je             .fast

.loop:
    vpmovzxbw      m0, [r2]
    vpmovzxbw      m1, [r2 + r3]
    vpsllw         m0, m0, 7
    vpsllw         m1, m1, 7
    vpmulhrsw      m0, m0, m2
    vpmulhrsw      m1, m1, m2
    vpaddw         m0, m0, m3
    vpaddw         m1, m1, m3
    vpackuswb      m0, m0, m1
    vmovq          [r0], m0
    vmovhps        [r0 + r1], m0
    lea            r0, [r0 + r1 * 2]
    lea            r2, [r2 + r3 * 2]
    sub            r5d, 2
    jg             .loop
    ret

ALIGN 16
.fast:
    vpsllw         m2, m2, 7
.fastloop:
    vpmovzxbw      m0, [r2]
    vpmovzxbw      m1, [r2 + r3]
    vpmulhrsw      m0, m0, m2
    vpmulhrsw      m1, m1, m2
    vpaddw         m0, m0, m3
    vpaddw         m1, m1, m3
    vpackuswb      m0, m0, m1
    vmovq          [r0], m0
    vmovhps        [r0 + r1], m0
    lea            r0, [r0 + r1 * 2]
    lea            r2, [r2 + r3 * 2]
    sub            r5d, 2
    jg             .fastloop
    ret

INIT_XMM avx2
cglobal mc_offsetadd_w16, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    vpbroadcastd   m2, [r4]

.loop:
    vmovdqu        m0, [r2]
    vmovdqu        m1, [r2 + r3]
    vpaddusb       m0, m0, m2
    vpaddusb       m1, m1, m2
    vmovdqu        [r0], m0
    vmovdqu        [r0 + r1], m1
    lea            r0, [r0 + r1 * 2]
    lea            r2, [r2 + r3 * 2]
    sub            r5d, 2
    jg             .loop
    ret

INIT_XMM avx2
cglobal mc_offsetsub_w16, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    vpbroadcastd   m2, [r4]

.loop:
    vmovdqu        m0, [r2]
    vmovdqu        m1, [r2 + r3]
    vpsubusb       m0, m0, m2
    vpsubusb       m1, m1, m2
    vmovdqu        [r0], m0
    vmovdqu        [r0 + r1], m1
    lea            r0, [r0 + r1 * 2]
    lea            r2, [r2 + r3 * 2]
    sub            r5d, 2
    jg             .loop
    ret


INIT_YMM avx2
cglobal mc_weight_w16, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    vpbroadcastd   m2, [r4]
    vpbroadcastd   m3, [r4 + 16]
    vpxor          m4, m4, m4
    ; we can merge the shift step into the scale factor
    ; if (m3<<7) doesn't overflow an int16_t
    xor            r6d, r6d
    cmp            [r4 + 1], r6b
    je             .fast

.loop:
    vmovdqu        xm0, [r2]
    vinserti128    m0, m0, [r2 + r3], 1
    vpunpckhbw     m1, m0, m4
    vpunpcklbw     m0, m0, m4
    vpsllw         m1, m1, 7
    vpsllw         m0, m0, 7
    vpmulhrsw      m1, m1, m2
    vpmulhrsw      m0, m0, m2
    vpaddw         m1, m1, m3
    vpaddw         m0, m0, m3
    vpackuswb      m0, m0, m1
    vmovdqu        [r0], xm0
    vextracti128   [r0 + r1], m0, 1
    lea            r0, [r0 + r1 * 2]
    lea            r2, [r2 + r3 * 2]
    sub            r5d, 2
    jg             .loop
    ret

ALIGN 16
.fast:
    vpsllw         m2, m2, 7
.fastloop:
    vmovdqu        xm0, [r2]
    vinserti128    m0, m0, [r2 + r3], 1
    vpunpckhbw     m1, m0, m4
    vpunpcklbw     m0, m0, m4
    vpmulhrsw      m1, m1, m2
    vpmulhrsw      m0, m0, m2
    vpaddw         m1, m1, m3
    vpaddw         m0, m0, m3
    vpackuswb      m0, m0, m1
    vmovdqu        [r0], xm0
    vextracti128   [r0 + r1], m0, 1
    lea            r0, [r0 + r1 * 2]
    lea            r2, [r2 + r3 * 2]
    sub            r5d, 2
    jg             .fastloop
    ret

INIT_XMM avx2
cglobal mc_offsetadd_w20, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    vpbroadcastd   m2, [r4]

.loop:
    vmovdqu        m0, [r2]
    vmovdqu        m1, [r2 + r3]
    vpaddusb       m0, m0, m2
    vpaddusb       m1, m1, m2
    vmovdqu        [r0], m0
    vmovdqu        [r0 + r1], m1
    vmovd          m0, [r2 + 16]
    vmovd          m1, [r2 + r3 + 16]
    vpaddusb       m0, m0, m2
    vpaddusb       m1, m1, m2
    vmovd          [r0 + 16], m0
    vmovd          [r0 + r1 + 16], m1
    lea            r0, [r0 + r1 * 2]
    lea            r2, [r2 + r3 * 2]
    sub            r5d, 2
    jg             .loop
    ret

INIT_XMM avx2
cglobal mc_offsetsub_w20, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    vpbroadcastd   m2, [r4]

.loop:
    vmovdqu        m0, [r2]
    vmovdqu        m1, [r2 + r3]
    vpsubusb       m0, m0, m2
    vpsubusb       m1, m1, m2
    vmovdqu        [r0], m0
    vmovdqu        [r0 + r1], m1
    vmovd          m0, [r2 + 16]
    vmovd          m1, [r2 + r3 + 16]
    vpsubusb       m0, m0, m2
    vpsubusb       m1, m1, m2
    vmovd          [r0 + 16], m0
    vmovd          [r0 + r1 + 16], m1
    lea            r0, [r0 + r1 * 2]
    lea            r2, [r2 + r3 * 2]
    sub            r5d, 2
    jg             .loop
    ret


INIT_YMM avx2
cglobal mc_weight_w20, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    vpbroadcastd   m2, [r4]
    vpbroadcastd   m3, [r4 + 16]
    vpxor          m4, m4, m4
    ; we can merge the shift step into the scale factor
    ; if (m3<<7) doesn't overflow an int16_t
    xor            r6d, r6d
    cmp            [r4 + 1], r6b
    je             .fast

.loop:
    vmovdqu        xm0, [r2]
    vinserti128    m0, m0, [r2 + r3], 1
    vpunpckhbw     m1, m0, m4
    vpunpcklbw     m0, m0, m4
    vpsllw         m1, m1, 7
    vpsllw         m0, m0, 7
    vpmulhrsw      m1, m1, m2
    vpmulhrsw      m0, m0, m2
    vpaddw         m1, m1, m3
    vpaddw         m0, m0, m3
    vpackuswb      m0, m0, m1
    vmovdqu        [r0], xm0
    vextracti128   [r0 + r1], m0, 1
    vmovd          xm0, [r2 + 16]
    vmovd          xm1, [r2 + r3 + 16]
    vpunpckldq     xm0, xm0, xm1
    vpunpcklbw     xm0, xm0, xm4
    vpsllw         xm0, xm0, 7
    vpmulhrsw      xm0, xm0, xm2
    vpaddw         xm0, xm0, xm3
    vpackuswb      xm0, xm0, xm0
    vmovd          [r0 + 16], xm0
    vpextrd        [r0 + r1 + 16], xm0, 1
    lea            r0, [r0 + r1 * 2]
    lea            r2, [r2 + r3 * 2]
    sub            r5d, 2
    jg             .loop
    ret

ALIGN 16
.fast:
    vpsllw         m2, m2, 7
.fastloop:
    vmovdqu        xm0, [r2]
    vinserti128    m0, m0, [r2 + r3], 1
    vpunpckhbw     m1, m0, m4
    vpunpcklbw     m0, m0, m4
    vpmulhrsw      m1, m1, m2
    vpmulhrsw      m0, m0, m2
    vpaddw         m1, m1, m3
    vpaddw         m0, m0, m3
    vpackuswb      m0, m0, m1
    vmovdqu        [r0], xm0
    vextracti128   [r0 + r1], m0, 1
    vmovd          xm0, [r2 + 16]
    vmovd          xm1, [r2 + r3 + 16]
    vpunpckldq     xm0, xm0, xm1
    vpunpcklbw     xm0, xm0, xm4
    vpmulhrsw      xm0, xm0, xm2
    vpaddw         xm0, xm0, xm3
    vpackuswb      xm0, xm0, xm0
    vmovd          [r0 + 16], xm0
    vpextrd        [r0 + r1 + 16], xm0, 1
    lea            r0, [r0 + r1 * 2]
    lea            r2, [r2 + r3 * 2]
    sub            r5d, 2
    jg             .fastloop
    ret


;=============================================================================
; INTERLEAVE/DEINTERLEAVE_CHROMA
;=============================================================================
INIT_XMM avx2
cglobal store_interleave_chroma, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
%endif
.loop:
    vmovq          m0, [r2]
    vpunpcklbw     m0, m0, [r3]
    vmovdqu        [r0], m0
    vmovq          m1, [r2 + 32]
    vpunpcklbw     m1, m1, [r3 + 32]
    vmovdqu        [r0 + r1], m1
    add            r2, 64
    add            r3, 64
    lea            r0, [r0 + r1 * 2]
    sub            r4d, 2
    jg             .loop
    ret

INIT_YMM avx2
cglobal load_deinterleave_chroma_fenc, 0, 0
    vbroadcasti128 m0, [deinterleave_shuf]
    lea            r6d, [r2 + r2 * 2]
.loop:
    vmovdqu        xm1, [r1]
    vinserti128    m1, m1, [r1 + r2], 1
    vmovdqu        xm2, [r1 + r2 * 2]
    vinserti128    m2, m2, [r1 + r6], 1
    lea            r1, [r1 + r2 * 4]
    vpshufb        m1, m1, m0
    vpshufb        m2, m2, m0
    vmovdqu        [r0], m1
    vmovdqu        [r0 + 32], m2
    add            r0, 64
    sub            r3d, 4
    jg             .loop
    RET

INIT_XMM avx2
cglobal load_deinterleave_chroma_fdec, 0, 0
    vmovdqu        m4, [deinterleave_shuf]
.loop:
    vmovdqu        m0, [r1]
    vmovdqu        m1, [r1 + r2]
    vpshufb        m0, m0, m4
    vpshufb        m1, m1, m4
    vmovq          [r0], m0
    vmovhps        [r0 + 16], m0
    vmovq          [r0 + 32], m1
    vmovhps        [r0 + 48], m1
    add            r0, 64
    lea            r1, [r1 + r2 * 2]
    sub            r3d, 2
    jg             .loop
    ret


;=============================================================================
; PLANE_COPY
;=============================================================================
INIT_YMM avx2
cglobal plane_copy, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    add            r0, r4
    add            r2, r4
    neg            r4
    mov            r6, r4

.loop:
    vmovdqu        m0, [r2 + r6]
    vmovdqu        m1, [r2 + r6 + 32]
    vmovntdq       [r0 + r6], m0
    vmovntdq       [r0 + r6 + 32], m1
    add            r6, 64
    jl             .loop

    add            r0, r1
    add            r2, r3
    mov            r6, r4
    sub            r5d, 1
    jg             .loop
    sfence
    RET

INIT_YMM avx2
cglobal plane_copy_interleave, 0, 0
%if WIN64
    mov            [rsp + 8], r7
    mov            [rsp + 16], r8
    mov            r4, [rsp + 40]
    mov            r5, [rsp + 48]
    mov            r6d, [rsp + 56]
    mov            r7d, [rsp + 64]
%else
    mov            [rsp - 8], r7
    mov            [rsp - 16], r8
    mov            r6d, [rsp + 8]
    mov            r7d, [rsp + 16]
%endif
    lea            r0, [r0 + r6 * 2]
    add            r2, r6
    add            r4, r6
    neg            r6
    mov            r8, r6

.loop:
    vmovdqu        m0, [r2 + r8]
    vmovdqu        m1, [r4 + r8]
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vinserti128    m0, m2, xm3, 1
    vperm2i128     m1, m2, m3, 31h
    vmovntdq       [r0 + r8 * 2], m0
    vmovntdq       [r0 + r8 * 2 + 32], m1
    add            r8, 32
    jl             .loop

    add            r0, r1
    add            r2, r3
    add            r4, r5
    mov            r8, r6
    sub            r7d, 1
    jg             .loop
    sfence
%if WIN64
    mov            r7, [rsp + 8]
    mov            r8, [rsp + 16]
%else
    mov            r7, [rsp - 8]
    mov            r8, [rsp - 16]
%endif
    RET

INIT_YMM avx2
cglobal plane_copy_deinterleave, 0, 0
%if WIN64
    mov            [rsp + 8], r7
    mov            [rsp + 16], r8
    mov            r4, [rsp + 40]
    mov            r5, [rsp + 48]
    mov            r6d, [rsp + 56]
    mov            r7d, [rsp + 64]
%else
    mov            [rsp - 8], r7
    mov            [rsp - 16], r8
    mov            r6d, [rsp + 8]
    mov            r7d, [rsp + 16]
%endif
    vbroadcasti128 m5, [deinterleave_shuf]
    add            r0, r6
    add            r2, r6
    lea            r4, [r4 + r6 * 2]
    neg            r6
    mov            r8, r6

.loop:
    vmovdqu        m0, [r4 + r8 * 2]
    vmovdqu        m1, [r4 + r8 * 2 + 32]
    vpshufb        m0, m0, m5
    vpshufb        m1, m1, m5
    vpermq         m0, m0, 0D8h
    vpermq         m1, m1, 0D8h
    vmovdqu        [r0 + r8], xm0
    vextracti128   [r2 + r8], m0, 1
    vmovdqu        [r0 + r8 + 16], xm1
    vextracti128   [r2 + r8 + 16], m1, 1
    add            r8, 32
    jl             .loop

    add            r0, r1
    add            r2, r3
    add            r4, r5
    mov            r8, r6
    sub            r7d, 1
    jg             .loop
%if WIN64
    mov            r7, [rsp + 8]
    mov            r8, [rsp + 16]
%else
    mov            r7, [rsp - 8]
    mov            r8, [rsp - 16]
%endif
    RET


;=============================================================================
; HPEL_FILTER
;=============================================================================
;The hpel_filter routines use non-temporal writes for output.
;The following defines may be uncommented for testing.
;Doing the hpel_filter temporal may be a win if the last level cache
;is big enough (preliminary benching suggests on the order of 4* framesize).
INIT_YMM avx2
cglobal hpel_filter, 0, 0
    push           r7
    push           r8
%if WIN64
    mov            r4, [rsp + 56]
    mov            r5d, [rsp + 64]
    mov            r6d, [rsp + 72]
    vmovdqu        [rsp + 24], xm6
    vmovdqu        [rsp + 40], xm7
    sub            rsp, 136
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
    vmovdqu        [rsp + 80], xm13
    vmovdqu        [rsp + 96], xm14
    vmovdqu        [rsp + 112], xm15
%else
    mov            r6d, [rsp + 24]
%endif
    ; r0 -> dsth
    ; r1 -> dstv
    ; r2 -> dstc
    ; r3 -> src
    ; r4 -> stride
    ; r5d -> width
    ; r6d -> height
    sub            r5d, 32       ; width*
    ; align src to 32B, this is the offset
    mov            r7d, r3d
    and            r7d, 31
    ; src aligned to 32B
    sub            r3, r7
    ; set the base to the end of array
    add            r0, r5
    add            r1, r5
    add            r2, r5
    ; array index
    add            r7, r5
    neg            r7
    mov            r8, r7
    ; row bases for filter_v
    lea            r5, [r3 + r4]
    sub            r3, r4
    sub            r3, r4
    ; r0 -> dsth + width*
    ; r1 -> dstv + width*
    ; r2 -> dstc + width*
    ; r3 -> src_aligned - 2 * stride
    ; r4 -> stride
    ; r5 -> src_aligned + stride
    ; r6d -> height
    ; r7 -> -(src_offset + width*)
    ; r8 -> -(src_offset + width*)
    vpbroadcastd   m0, [filt_mul15]
    vpbroadcastd   m1, [filt_mul51]
    vpbroadcastd   m2, [filt_mul20]
    vpbroadcastd   m3, [pw_1024]

; for each y, filter_v is one step advance
; we need to deal with the head and the tail specially
; this can leave enough regs for remaining process
; regs:
; m15: current raw
; m14: next raw
; m13: last raw
; m12: last v_ed
; m4, m5: current v_ed
; m6, m7: next v_ed
.loopy:
    ; first filter_v
    vmovdqu        m4, [r3]            ; line -2
    vmovdqu        m5, [r3 + r4]       ; line -1
    vmovdqu        m15, [r3 + r4 * 2]  ; line  0
    vmovdqu        m7, [r5]            ; line  1
    vmovdqu        m8, [r5 + r4]       ; line  2
    vmovdqu        m9, [r5 + r4 * 2]   ; line  3
    ; interleave corresponding rows
    ; (-2, -1)  (2, 3)  (0, 1)
    vpunpckhbw     m10, m4, m5
    vpunpcklbw     m4, m4, m5
    vpunpckhbw     m5, m8, m9
    vpunpcklbw     m8, m8, m9
    vpunpckhbw     m9, m15, m7
    vpunpcklbw     m6, m15, m7
    ; row(-2) - 5 * row(-1)
    ; -5 * row(2) + row(3)
    ; 20 * row(0) + 20 * row(1)
    vpmaddubsw     m10, m10, m0
    vpmaddubsw     m4, m4, m0
    vpmaddubsw     m5, m5, m1
    vpmaddubsw     m8, m8, m1
    vpmaddubsw     m9, m9, m2
    vpmaddubsw     m6, m6, m2
    ; add up the result  [1, -5, 20, 20, -5, 1]
    vpaddw         m4, m4, m8
    vpaddw         m4, m4, m6
    vpaddw         m10, m10, m5
    vpaddw         m10, m10, m9
    add            r3, 32
    add            r5, 32
    ; round and clip to 8-bit
    vpmulhrsw      m6, m4, m3
    vpmulhrsw      m7, m10, m3
    vpackuswb      m6, m6, m7
    vmovntps       [r1 + r7], m6
    ; permulate 128-bit lanes
    ; e.g. m4: 0 -- 7  | 16 -- 23   -->    m4:   0 -- 7 | 8 -- 15
    ;     m10: 8 -- 15 | 24 -- 31   -->    m5: 16 -- 23 | 24 -- 31
    vperm2i128     m5, m4, m10, 31h
    vinserti128    m4, m4, xm10, 1
.loopx:
    ; filter_v
    ; load the next piece(right side)
    vmovdqu        m6, [r3]
    vmovdqu        m7, [r3 + r4]
    vmovdqu        m14, [r3 + r4 * 2]
    vmovdqu        m8, [r5]
    vmovdqu        m9, [r5 + r4]
    vmovdqu        m10, [r5 + r4 * 2]
    vpunpckhbw     m11, m6, m7
    vpunpcklbw     m6, m6, m7
    vpunpckhbw     m7, m9, m10
    vpunpcklbw     m9, m9, m10
    vpunpckhbw     m10, m14, m8
    vpunpcklbw     m8, m14, m8
    vpmaddubsw     m11, m11, m0
    vpmaddubsw     m6, m6, m0
    vpmaddubsw     m7, m7, m1
    vpmaddubsw     m9, m9, m1
    vpmaddubsw     m10, m10, m2
    vpmaddubsw     m8, m8, m2
    vpaddw         m6, m6, m9
    vpaddw         m6, m6, m8
    vpaddw         m8, m11, m7
    vpaddw         m8, m8, m10
    add            r3, 32
    add            r5, 32
    vpmulhrsw      m7, m6, m3
    vpmulhrsw      m9, m8, m3
    vpackuswb      m7, m7, m9
    vmovntps       [r1 + r7 + 32], m7
    vperm2i128     m7, m6, m8, 31h
    vinserti128    m6, m6, xm8, 1
.lastx:
    ; filter_c
    vpsrlw         m3, m3, 1         ; pw_512
    ; concatenate and shift each lane, each element is 16-bit
    vperm2i128     m12, m4, m12, 3   ; -8 -- -1 | 0 -- 7
    vpalignr       m8, m4, m12, 12   ; -2 -- 5  | 6 -- 13
    vpalignr       m9, m4, m12, 14   ; -1 -- 6  | 7 -- 14
    vperm2i128     m12, m5, m4, 3    ;  8 -- 15 | 16 -- 23
    vpalignr       m10, m12, m4, 4   ;  2 -- 9  | 10 -- 17
    vpalignr       m11, m12, m4, 6   ;  3 -- 10 | 11 -- 18
    ; apply the kernel [1, -5, 20, 20, -5, 1]
    ; use appropriate shift operations to finish the job while avoid overflow
    ; use vpmulhrsw to do the final round
    ; this instruction let us ignore those bits being cut off when rounding
    vpaddw         m8, m8, m11       ; -2 + 3
    vpaddw         m9, m9, m10       ; -1 + 2
    vpsubw         m8, m8, m9        ; (-2 + 3) - (-1 + 2)
    vpsraw         m8, m8, 2         ; ((-2 + 3) - (-1 + 2)) / 4
    vpsubw         m8, m8, m9        ; ((-2 + 3) - (-1 + 2)) / 4 - (-1 + 2)
    vpalignr       m10, m12, m4, 2   ;  1 -- 8  | 9 -- 16
    vpaddw         m10, m4, m10      ; 0 + 1
    vpaddw         m8, m8, m10       ;((-2 + 3) - (-1 + 2)) / 4 - (-1 + 2) + (0 + 1)
    vpsraw         m8, m8, 2         ;(((-2 + 3) - (-1 + 2)) / 4 - (-1 + 2) + (0 + 1)) / 4
    vpaddw         m8, m8, m10       ;(((-2 + 3) - (-1 + 2)) / 4 - (-1 + 2) + (0 + 1)) / 4 + (0 + 1)
    ; now we have: expecting result / 16
    ; apply vpmulhrsw with pw_512
    vpmulhrsw      m8, m8, m3

    ; 0 -- 15 done, do the save with 16 -- 31
    vpalignr       m4, m5, m12, 12   ; 14 -- 21 | 22 -- 29
    vpalignr       m9, m5, m12, 14   ; 15 -- 22 | 22 -- 30
    vperm2i128     m12, m6, m5, 3    ; 24 -- 31 | 32 -- 39
    vpalignr       m10, m12, m5, 4   ; 18 -- 25 | 26 -- 33
    vpalignr       m11, m12, m5, 6   ; 19 -- 26 | 27 -- 34
    vpaddw         m4, m4, m11       ; -2 + 3
    vpaddw         m9, m9, m10       ; -1 + 2
    vpsubw         m4, m4, m9
    vpsraw         m4, m4, 2
    vpsubw         m4, m4, m9
    vpalignr       m10, m12, m5, 2   ; 17 -- 24 | 25 -- 32
    vpaddw         m10, m5, m10      ; 0 + 1
    vpaddw         m4, m4, m10
    vpsraw         m4, m4, 2
    vpaddw         m4, m4, m10
    vpmulhrsw      m4, m4, m3

    ; clip to 8-bit and store
    vpackuswb      m8, m8, m4        ; 0 -- 7, 16 -- 23 | 8 -- 15, 24 -- 31
    vpermq         m8, m8, q3120     ; 0 -- 15 | 16 -- 31
    vmovntps       [r2 + r7], m8
    ; setup regs for next iteration
    vpaddw         m3, m3, m3        ; pw_1024
    vmovdqu        m12, m5
    vmovdqu        m4, m6
    vmovdqu        m5, m7

    ; filter_h
    ; each element is 8-bit
    vperm2i128     m6, m15, m13, 3   ; -16 -- -1 | 0 -- 15
    vpalignr       m7, m15, m6, 14   ;  -2 -- 13 | 14 -- 29
    vpalignr       m8, m15, m6, 15   ;  -1 -- 14 | 15 -- 30
    vpmaddubsw     m7, m7, m0        ; [1 -5]
    vpmaddubsw     m8, m8, m0        ; [1 -5]
    vperm2i128     m6, m14, m15, 3   ;  16 -- 31 | 32 -- 47
    vpalignr       m9, m6, m15, 2    ;   2 -- 17 | 18 -- 33
    vpalignr       m10, m6, m15, 3   ;   3 -- 18 | 19 -- 34
    vpmaddubsw     m9, m9, m1        ; [-5, 1]
    vpmaddubsw     m10, m10, m1      ; [-5, 1]
    vpalignr       m11, m6, m15, 1   ;   1 -- 16 | 17 -- 32
    vpmaddubsw     m6, m15, m2       ; [20, 20]
    vpmaddubsw     m11, m11, m2      ; [20, 20]
    vpaddw         m7, m7, m9
    vpaddw         m8, m8, m10
    vpaddw         m7, m7, m6
    vpaddw         m8, m8, m11
    vpmulhrsw      m7, m7, m3
    vpmulhrsw      m8, m8, m3
    ; m7: 0, 2, 4, 6, 8, 10, 12, 14 | 16, 18, 20, 22, 24, 26, 28, 30
    ; m8: 1, 3, 5, 7, 9, 11, 13, 15 | 17, 19, 21, 23, 25, 27, 29, 31
    vpackuswb      m7, m7, m8
    vbroadcasti128 m8, [hpel_shuf]
    vpshufb        m7, m7, m8
    vmovntps       [r0 + r7], m7
    ; setup regs for next iteration
    vmovdqu        m13, m15
    vmovdqu        m15, m14
    add            r7, 32
    jl             .loopx
    cmp            r7, 32
    jl             .lastx

    ; at this moment, some regs:
    ; r7 -> 32 * N -(src_offset + width*)
    ; r3 -> 32 * N + src_aligned - 2 * stride
    ; r5 -> 32 * N + src_aligned + stride
    sub            r7, r8            ; 32 * N
    sub            r7, r4            ; 32 * N - stride
    sub            r3, r7            ; (src_aligned + stride) - 2 * stride
    sub            r5, r7            ; (src_aligned + stride) + stride
    add            r0, r4
    add            r1, r4
    add            r2, r4
    mov            r7, r8
    sub            r6d, 1
    jg             .loopy
    sfence

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
    vmovdqu        xm6, [rsp + 24]
    vmovdqu        xm7, [rsp + 40]
%endif
    pop            r8
    pop            r7
    RET


;=============================================================================
; frame_init_lowres_core
;=============================================================================
INIT_YMM avx2
cglobal frame_init_lowres_core, 0, 0
    push           r7
    push           r8
    push           r9
%if WIN64
    vmovdqu        [rsp + 32], xm6
    mov            r4, [rsp + 64]
    mov            r5, [rsp + 72]
    mov            r6, [rsp + 80]
    mov            r7d, [rsp + 88]
    mov            r8d, [rsp + 96]
%else
    mov            r6, [rsp + 32]
    mov            r7d, [rsp + 40]
    mov            r8d, [rsp + 48]
%endif
    ; setup base and index
    ; r0 -> src0
    ; r1 -> dst0 + width
    ; r2 -> dsth + width
    ; r3 -> dstv + width
    ; r4 -> dstc + width
    ; r5 -> src_stride
    ; r6 -> dst_stride
    ; r7 -> -width
    ; r8 -> height
    ; r9 -> -width
    add            r1, r7
    add            r2, r7
    add            r3, r7
    add            r4, r7
    neg            r7
    mov            r9, r7
    vbroadcasti128 m6, [deinterleave_shuf]

.loop:
    ; load two 32B blocks each iteration to produce 32B result
    ; vertical average: dst0, dstv
    vmovdqu        m1, [r0 + r5]
    vpavgb         m0, m1, [r0]
    vpavgb         m1, m1, [r0 + r5 * 2]
    ; vertical average: dsth, dstc
    vmovdqu        m3, [r0 + r5 + 1]
    vpavgb         m2, m3, [r0 + 1]
    vpavgb         m3, m3, [r0 + r5 * 2 + 1]
    ; horizontal average
    vpavgb         m0, m0, m2          ; dst0, dsth, dst0, dsth, ...
    vpavgb         m1, m1, m3          ; dstv, dstc, dstv, dstc, ...

    ; vertical average: dst0 + 32, dstv + 32
    vmovdqu        m3, [r0 + r5 + 32]
    vpavgb         m2, m3, [r0 + 32]
    vpavgb         m3, m3, [r0 + r5 * 2 + 32]
    ; vertical average: dsth + 32, dstc + 32
    vmovdqu        m5, [r0 + r5 + 33]
    vpavgb         m4, m5, [r0 + 33]
    vpavgb         m5, m5, [r0 + r5 * 2 + 33]
    ; horizontal average
    vpavgb         m2, m2, m4          ; dst0 + 32, dsth + 32, dst0 + 32, dsth + 32, ...
    vpavgb         m3, m3, m5          ; dstv + 32, dstc + 32, dstv + 32, dstc + 32, ...

    vpshufb        m0, m0, m6          ; dst0..., dsth... | dst0..., dsth...
    vpshufb        m1, m1, m6          ; dstv..., dstc... | dstv..., dstc...
    vpshufb        m2, m2, m6
    vpshufb        m3, m3, m6
    vpunpcklqdq    m4, m0, m2          ; dst0, dst0 + 32 | dst0, dst0 + 32
    vpunpckhqdq    m5, m0, m2          ; dsth, dsth + 32 | dsth, dsth + 32
    vpunpcklqdq    m0, m1, m3          ; dstv, dstv + 32 | dstv, dstv + 32
    vpunpckhqdq    m1, m1, m3          ; dstc, dstc + 32 | dstc, dstc + 32
    vpermq         m4, m4, q3120       ; dst0 | dst0 + 32
    vpermq         m5, m5, q3120       ; dsth | dsth + 32
    vpermq         m0, m0, q3120       ; dstv | dstv + 32
    vpermq         m1, m1, q3120       ; dstc | dstc + 32
    vmovdqu        [r1 + r7], m4
    vmovdqu        [r2 + r7], m5
    vmovdqu        [r3 + r7], m0
    vmovdqu        [r4 + r7], m1
    add            r0, 64
    add            r7, 32
    jl             .loop

    sub            r7, r9          ; N * 16
    add            r7, r7          ; N * 32
    lea            r0, [r0 + r5 * 2] ; src + N * 32 + 2 * src_stride
    sub            r0, r7          ; src + 2 * src_stride
    add            r1, r6          ; dst + dst_stride
    add            r2, r6
    add            r3, r6
    add            r4, r6
    mov            r7, r9
    sub            r8d, 1
    jg             .loop

%if WIN64
    vmovdqu        xm6, [rsp + 32]
%endif
    pop            r9
    pop            r8
    pop            r7
    RET


;=============================================================================
; integral_init
;=============================================================================
INIT_YMM avx2
cglobal integral_init4h, 0, 0
    mov            r6, r0    ; sum[x-stride + stride], set the base to the end of array
    add            r1, r2
    neg            r2
    vpxor          m2, m2, m2
.loop:
    ; vmpsadbw can only process 8 blocks once
    ; load a 32B block and split to 2 processing lanes
    vpermq         m0, [r1 + r2], q2110
    vpermq         m1, [r1 + r2 + 16], q2110
    vmpsadbw       m0, m0, m2, 0
    vmpsadbw       m1, m1, m2, 0
    vpaddw         m0, m0, [r6 + r2 * 2]
    vpaddw         m1, m1, [r6 + r2 * 2 + 32]
    vmovdqu        [r0], m0
    vmovdqu        [r0 + 32], m1
    add            r0, 64
    add            r2, 32
    jl             .loop
    RET

INIT_YMM avx2
cglobal integral_init8h, 0, 0
    mov            r6, r0    ; sum[x-stride + stride], set the base to the end of array
    add            r1, r2
    neg            r2
    vpxor          m4, m4, m4
.loop:
    vmovdqu        xm0, [r1 + r2]
    vmovdqu        xm1, [r1 + r2 + 16]
    vinserti128    m0, m0, [r1 + r2 + 8], 1
    vinserti128    m1, m1, [r1 + r2 + 24], 1
    ; use 2 vmpsadbw to add up 8 elements
    vmpsadbw       m2, m0, m4, 0
    vmpsadbw       m3, m1, m4, 0
    vmpsadbw       m0, m0, m4, 24h
    vmpsadbw       m1, m1, m4, 24h
    vpaddw         m2, m2, [r6 + r2 * 2]
    vpaddw         m3, m3, [r6 + r2 * 2 + 32]
    vpaddw         m0, m0, m2
    vpaddw         m1, m1, m3
    vmovdqu        [r0], m0
    vmovdqu        [r0 + 32], m1
    add            r0, 64
    add            r2, 32
    jl             .loop
    RET

INIT_YMM avx2
cglobal integral_init4v, 0, 0
    lea            r3, [r0 + r2 * 2]       ; set the base of sum8 to the end of array(copy it)
    add            r2, r2                  ; double the counter since each element is 2B
    lea            r6, [r3 + r2 * 8]       ; sum8[x+8*stride]
    lea            r3, [r3 + r2 * 4]       ; sum8[x+4*stride]
    neg            r2
.loop:
    vmovdqu        m0, [r0]                ; sum8[x]
    vmovdqa        m1, [r3 + r2]           ; sum8[x+4*stride]
    vpsubw         m1, m1, m0
    vmovdqu        [r1], m1                ; sum4
    vpaddw         m0, m0, [r0 + 8]        ; sum8[x] + sum8[x+4]
    vmovdqu        m1, [r6 + r2]           ; sum8[x+8*stride]
    vpaddw         m1, m1, [r6 + r2 + 8]   ; sum8[x+8*stride] + sum8[x+8*stride+4]
    vpsubw         m1, m1, m0
    vmovdqu        [r0], m1                ; sum8
    add            r0, 32
    add            r1, 32
    add            r2, 32
    jl             .loop
    RET

INIT_YMM avx2
cglobal integral_init8v, 0, 0
    lea            r6, [r0 + r1 * 2]  ; set the base of sum8 to the end of array(copy it)
    add            r1, r1             ; double the counter since each element is 2B
    lea            r6, [r6 + r1 * 8]  ; sum8[x+8*stride]
    neg            r1
.loop:
    vmovdqu        m0, [r6 + r1]
    vmovdqu        m1, [r6 + r1 + 32]
    vmovdqu        m2, [r6 + r1 + 64]
    vpsubw         m0, m0, [r0]
    vpsubw         m1, m1, [r0 + 32]
    vpsubw         m2, m2, [r0 + 64]
    vmovdqu        [r0], m0
    vmovdqu        [r0 + 32], m1
    vmovdqu        [r0 + 64], m2
    add            r0, 96
    add            r1, 96
    jl             .loop
    RET


;=============================================================================
; mbtree_propagate
;=============================================================================
INIT_YMM avx2
cglobal mbtree_propagate_cost, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r6, [rsp + 48]
    vbroadcastss   m5, [r6]            ; fps
    mov            r6d, [rsp + 56]
%else
    mov            r6d, [rsp + 8]
    vbroadcastss   m5, [r5]            ; fps
%endif
    vpbroadcastd   xm4, [pw_3fff]      ; low 14-bit mask(LOWRES_COST_MASK)
    lea            r1, [r1 + r6 * 2]   ; double the length for 16-bit elements addressing
    lea            r2, [r2 + r6 * 2]
    add            r6d, r6d
    add            r3, r6
    add            r4, r6
    neg            r6
.loop:
    ; convert 16-bit to 32bit for int-to-float conversion
    vpmovzxwd      m0, [r2 + r6]       ; intra_cost
    vpand          xm1, xm4, [r3 + r6]
    vpmovzxwd      m2, [r4 + r6]       ; inv_qscales
    vpmovzxwd      m3, [r1 + r6]       ; propagate_in
    vpmovzxwd      m1, xm1
    vpsubusw       m1, m0, m1          ; intra_cost - inter_cost, combine MIN and SUB
    vpmaddwd       m2, m2, m0          ; propagate_intra
    ; convert to float
    vcvtdq2ps      m0, m0              ; propagate_denom
    vcvtdq2ps      m1, m1              ; propagate_num
    vcvtdq2ps      m2, m2
    vcvtdq2ps      m3, m3
    vfmadd231ps    m3, m2, m5          ; propagate_amount
    vmulps         m3, m3, m1          ; propagate_amount * propagate_num
    ; calculate the reciprocal of propagate_denom to avoid division
    ; the result of rcp have a precision of 12 bits, which is not enough
    ; we use the Newton-Raphson method to increase precision
    ; let input = a, then we have:
    ; b = rcp(a)
    ; output = b * (2 - a * b) = 2 * b - a * b * b
    vrcpps         m1, m0              ; b = rcp(propagate_denom)
    vmulps         m0, m0, m1          ; a * b
    vaddps         m2, m1, m1          ; 2 * b
    vfnmadd132ps   m0, m2, m1          ; -((a * b) * b) + (2 * b)
    vmulps         m0, m0, m3          ; propagate_amount * propagate_num / propagate_denom
    vcvtps2dq      m0, m0              ; round to int, equivalent to (int)(result + 0.5f)
    vextracti128   xm1, m0, 1
    vpackssdw      xm0, xm0, xm1       ; clip to int_16
    vmovdqu        [r0], xm0
    add            r0, 16
    add            r6, 16
    jl             .loop
    RET

