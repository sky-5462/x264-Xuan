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
pb_64:     times 4 db 64

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
cglobal avg_weight_2x2, 0, 0
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
    jg             avg_weight_2x2_avx2
    ret

INIT_XMM avx2
cglobal avg_2x2, 0, 0
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
    jg             avg_2x2_avx2
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
    je             avg_2x2_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_2x2_avx2

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
    je             avg_2x2_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_2x2_avx2



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
cglobal avg_weight_4x2, 0, 0
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
    jg             avg_weight_4x2_avx2
    ret

INIT_XMM avx2
cglobal avg_4x2, 0, 0
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
    jg             avg_4x2_avx2
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
    je             avg_4x2_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_4x2_avx2

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
    je             avg_4x2_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_4x2_avx2

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
    je             avg_4x2_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_4x2_avx2


INIT_XMM avx2
cglobal avg_weight_8x2, 0, 0
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
    jg             avg_weight_8x2_avx2
    ret

INIT_XMM avx2
cglobal avg_8x2, 0, 0
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
    jg             avg_8x2_avx2
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
    je             avg_8x2_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_8x2_avx2

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
    je             avg_8x2_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_8x2_avx2

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
    je             avg_8x2_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_8x2_avx2


INIT_YMM avx2
cglobal avg_weight_16x2, 0, 0
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
    jg             avg_weight_16x2_avx2
    RET

INIT_XMM avx2
cglobal avg_16x2, 0, 0
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
    jg             avg_16x2_avx2
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
    je             avg_16x2_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_16x2_avx2

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
    je             avg_16x2_avx2

    vpbroadcastd   m5, [pw_512]
    vpbroadcastd   m1, [pb_64]
%if WIN64
    vpbroadcastb   m0, [rsp + 56]
%else
    vpbroadcastb   m0, [rsp + 8]
%endif
    vpsubb         m1, m1, m0
    vpunpcklbw     m0, m0, m1                    ; w1 w2 w1 w2 ....
    jmp            avg_weight_16x2_avx2


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


