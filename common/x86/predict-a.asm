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

SECTION_RODATA 32

pw_43210123: times 2 dw -3, -2, -1, 0, 1, 2, 3, 4
pw_m3:       times 16 dw -3
pw_m7:       times 16 dw -7
pb_00s_ff:   times 8 db 0
pb_0s_ff:    times 7 db 0
             db 0xff
shuf_fixtr:  db 0, 1, 2, 3, 4, 5, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7
shuf_nop:    db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
shuf_hu:     db 7,6,5,4,3,2,1,0,0,0,0,0,0,0,0,0
shuf_vr:     db 2,4,6,8,9,10,11,12,13,14,15,0,1,3,5,7
pw_reverse:  db 14,15,12,13,10,11,8,9,6,7,4,5,2,3,0,1


predict_chroma_dc_shuf:     times 4 db  0
                            times 4 db  4
                            times 4 db  8
                            times 4 db 12
pb_32101234:                db -3, -2, -1, 0, 1, 2, 3, 4
predict_chroma_dc_top_shuf: times 4 db 0
                            times 4 db 8

SECTION .text

cextern pb_0
cextern pb_1
cextern pb_3
cextern pw_1
cextern pw_2
cextern pw_4
cextern pw_8
cextern pw_16
cextern pw_00ff
cextern pw_pixel_max
cextern pw_0to15

%macro STORE8 1
    mova [r0+0*FDEC_STRIDEB], %1
    mova [r0+1*FDEC_STRIDEB], %1
    add  r0, 4*FDEC_STRIDEB
    mova [r0-2*FDEC_STRIDEB], %1
    mova [r0-1*FDEC_STRIDEB], %1
    mova [r0+0*FDEC_STRIDEB], %1
    mova [r0+1*FDEC_STRIDEB], %1
    mova [r0+2*FDEC_STRIDEB], %1
    mova [r0+3*FDEC_STRIDEB], %1
%endmacro

%macro STORE16 1-4
%if %0 > 1
    mov  r1d, 2*%0
.loop:
    mova [r0+0*FDEC_STRIDEB+0*mmsize], %1
    mova [r0+0*FDEC_STRIDEB+1*mmsize], %2
    mova [r0+1*FDEC_STRIDEB+0*mmsize], %1
    mova [r0+1*FDEC_STRIDEB+1*mmsize], %2
%ifidn %0, 4
    mova [r0+0*FDEC_STRIDEB+2*mmsize], %3
    mova [r0+0*FDEC_STRIDEB+3*mmsize], %4
    mova [r0+1*FDEC_STRIDEB+2*mmsize], %3
    mova [r0+1*FDEC_STRIDEB+3*mmsize], %4
    add  r0, 2*FDEC_STRIDEB
%else ; %0 == 2
    add  r0, 4*FDEC_STRIDEB
    mova [r0-2*FDEC_STRIDEB+0*mmsize], %1
    mova [r0-2*FDEC_STRIDEB+1*mmsize], %2
    mova [r0-1*FDEC_STRIDEB+0*mmsize], %1
    mova [r0-1*FDEC_STRIDEB+1*mmsize], %2
%endif
    dec  r1d
    jg .loop
%else ; %0 == 1
    STORE8 %1
    add  r0, 8*FDEC_STRIDE
    mova [r0-4*FDEC_STRIDE], %1
    mova [r0-3*FDEC_STRIDE], %1
    mova [r0-2*FDEC_STRIDE], %1
    mova [r0-1*FDEC_STRIDE], %1
    mova [r0+0*FDEC_STRIDE], %1
    mova [r0+1*FDEC_STRIDE], %1
    mova [r0+2*FDEC_STRIDE], %1
    mova [r0+3*FDEC_STRIDE], %1
%endif
%endmacro

%macro PRED_H_LOAD 2 ; reg, offset
%if cpuflag(avx2)
    vpbroadcastpix %1, [r0+(%2)*FDEC_STRIDEB-SIZEOF_PIXEL]
%else
    SPLATB_LOAD    %1, r0+(%2)*FDEC_STRIDE-1, m2
%endif
%endmacro

%macro PRED_H_STORE 3 ; reg, offset, width
%assign %%w %3*SIZEOF_PIXEL
%if %%w == 8
    movq [r0+(%2)*FDEC_STRIDEB], %1
%else
    %assign %%i 0
    %rep %%w/mmsize
        mova [r0+(%2)*FDEC_STRIDEB+%%i], %1
    %assign %%i %%i+mmsize
    %endrep
%endif
%endmacro

%macro PRED_H_4ROWS 2 ; width, inc_ptr
    PRED_H_LOAD  m0, 0
    PRED_H_LOAD  m1, 1
    PRED_H_STORE m0, 0, %1
    PRED_H_STORE m1, 1, %1
    PRED_H_LOAD  m0, 2
%if %2
    add          r0, 4*FDEC_STRIDEB
%endif
    PRED_H_LOAD  m1, 3-4*%2
    PRED_H_STORE m0, 2-4*%2, %1
    PRED_H_STORE m1, 3-4*%2, %1
%endmacro

; dest, left, right, src, tmp
; output: %1 = (t[n-1] + t[n]*2 + t[n+1] + 2) >> 2
%macro PRED8x8_LOWPASS 4-5
    mova        %5, %2
    pavgb       %2, %3
    pxor        %3, %5
    pand        %3, [pb_1]
    psubusb     %2, %3
    pavgb       %1, %4, %2
%endmacro

%macro PREDICT_FILTER 4
;-----------------------------------------------------------------------------
;void predict_8x8_filter( pixel *src, pixel edge[36], int i_neighbor, int i_filters )
;-----------------------------------------------------------------------------
cglobal predict_8x8_filter, 4,6,6
    add          r0, 0x58*SIZEOF_PIXEL
%define src r0-0x58*SIZEOF_PIXEL
%if ARCH_X86_64 == 0
    mov          r4, r1
%define t1 r4
%define t4 r1
%else
%define t1 r1
%define t4 r4
%endif
    test       r3b, 1
    je .check_top
    mov        t4d, r2d
    and        t4d, 8
    neg         t4
    mova        m0, [src+0*FDEC_STRIDEB-8*SIZEOF_PIXEL]
    punpckh%1%2 m0, [src+0*FDEC_STRIDEB-8*SIZEOF_PIXEL+t4*(FDEC_STRIDEB/8)]
    mova        m1, [src+2*FDEC_STRIDEB-8*SIZEOF_PIXEL]
    punpckh%1%2 m1, [src+1*FDEC_STRIDEB-8*SIZEOF_PIXEL]
    punpckh%2%3 m1, m0
    mova        m2, [src+4*FDEC_STRIDEB-8*SIZEOF_PIXEL]
    punpckh%1%2 m2, [src+3*FDEC_STRIDEB-8*SIZEOF_PIXEL]
    mova        m3, [src+6*FDEC_STRIDEB-8*SIZEOF_PIXEL]
    punpckh%1%2 m3, [src+5*FDEC_STRIDEB-8*SIZEOF_PIXEL]
    punpckh%2%3 m3, m2
    punpckh%3%4 m3, m1
    mova        m0, [src+7*FDEC_STRIDEB-8*SIZEOF_PIXEL]
    mova        m1, [src-1*FDEC_STRIDEB]
    PALIGNR     m4, m3, m0, 7*SIZEOF_PIXEL, m0
    PALIGNR     m1, m1, m3, 1*SIZEOF_PIXEL, m2
    PRED8x8_LOWPASS m3, m1, m4, m3, m5
    mova        [t1+8*SIZEOF_PIXEL], m3
    movzx      t4d, pixel [src+7*FDEC_STRIDEB-1*SIZEOF_PIXEL]
    movzx      r5d, pixel [src+6*FDEC_STRIDEB-1*SIZEOF_PIXEL]
    lea        t4d, [t4*3+2]
    add        t4d, r5d
    shr        t4d, 2
    mov         [t1+7*SIZEOF_PIXEL], t4%1
    mov         [t1+6*SIZEOF_PIXEL], t4%1
    test       r3b, 2
    je .done
.check_top:
%if SIZEOF_PIXEL==1 && cpuflag(ssse3)
INIT_XMM cpuname
    movu        m3, [src-1*FDEC_STRIDEB]
    movhps      m0, [src-1*FDEC_STRIDEB-8]
    test       r2b, 8
    je .fix_lt_2
.do_top:
    and        r2d, 4
%if ARCH_X86_64
    lea         r3, [shuf_fixtr]
    pshufb      m3, [r3+r2*4]
%else
    pshufb      m3, [shuf_fixtr+r2*4] ; neighbor&MB_TOPRIGHT ? shuf_nop : shuf_fixtr
%endif
    psrldq      m1, m3, 15
    PALIGNR     m2, m3, m0, 15, m0
    PALIGNR     m1, m3, 1, m5
    PRED8x8_LOWPASS m0, m2, m1, m3, m5
    mova        [t1+16*SIZEOF_PIXEL], m0
    psrldq      m0, 15
    movd        [t1+32*SIZEOF_PIXEL], m0
.done:
    REP_RET
.fix_lt_2:
    pslldq      m0, m3, 15
    jmp .do_top

%else
    mova        m0, [src-1*FDEC_STRIDEB-8*SIZEOF_PIXEL]
    mova        m3, [src-1*FDEC_STRIDEB]
    mova        m1, [src-1*FDEC_STRIDEB+8*SIZEOF_PIXEL]
    test       r2b, 8
    je .fix_lt_2
    test       r2b, 4
    je .fix_tr_1
.do_top:
    PALIGNR     m2, m3, m0, 7*SIZEOF_PIXEL, m0
    PALIGNR     m0, m1, m3, 1*SIZEOF_PIXEL, m5
    PRED8x8_LOWPASS m4, m2, m0, m3, m5
    mova        [t1+16*SIZEOF_PIXEL], m4
    test       r3b, 4
    je .done
    PSRLPIX     m5, m1, 7
    PALIGNR     m2, m1, m3, 7*SIZEOF_PIXEL, m3
    PALIGNR     m5, m1, 1*SIZEOF_PIXEL, m4
    PRED8x8_LOWPASS m0, m2, m5, m1, m4
    mova        [t1+24*SIZEOF_PIXEL], m0
    PSRLPIX     m0, m0, 7
    movd        [t1+32*SIZEOF_PIXEL], m0
.done:
    REP_RET
.fix_lt_2:
    PSLLPIX     m0, m3, 7
    test       r2b, 4
    jne .do_top
.fix_tr_1:
    punpckh%1%2 m1, m3, m3
    pshuf%2     m1, m1, q3333
    jmp .do_top
%endif
%endmacro

INIT_MMX mmx2
PREDICT_FILTER b, w, d, q
INIT_MMX ssse3
PREDICT_FILTER b, w, d, q

;-----------------------------------------------------------------------------
; void predict_8x8_v( pixel *src, pixel *edge )
;-----------------------------------------------------------------------------
%macro PREDICT_8x8_V 0
cglobal predict_8x8_v, 2,2
    mova        m0, [r1+16*SIZEOF_PIXEL]
    STORE8      m0
    RET
%endmacro

INIT_MMX mmx2
PREDICT_8x8_V

;-----------------------------------------------------------------------------
; void predict_8x8_h( pixel *src, pixel edge[36] )
;-----------------------------------------------------------------------------
%macro PREDICT_8x8_H 2
cglobal predict_8x8_h, 2,2
    movu      m1, [r1+7*SIZEOF_PIXEL]
    add       r0, 4*FDEC_STRIDEB
    punpckl%1 m2, m1, m1
    punpckh%1 m1, m1
%assign Y 0
%rep 8
%assign i 1+Y/4
    SPLAT%2 m0, m %+ i, (3-Y)&3
    mova [r0+(Y-4)*FDEC_STRIDEB], m0
%assign Y Y+1
%endrep
    RET
%endmacro

INIT_MMX mmx2
PREDICT_8x8_H bw, W

;-----------------------------------------------------------------------------
; void predict_8x8_dc( pixel *src, pixel *edge );
;-----------------------------------------------------------------------------
INIT_MMX mmx2
cglobal predict_8x8_dc, 2,2
    pxor        mm0, mm0
    pxor        mm1, mm1
    psadbw      mm0, [r1+7]
    psadbw      mm1, [r1+16]
    paddw       mm0, [pw_8]
    paddw       mm0, mm1
    psrlw       mm0, 4
    pshufw      mm0, mm0, 0
    packuswb    mm0, mm0
    STORE8      mm0
    RET

;-----------------------------------------------------------------------------
; void predict_8x8_dc_top ( pixel *src, pixel *edge );
; void predict_8x8_dc_left( pixel *src, pixel *edge );
;-----------------------------------------------------------------------------
%macro PREDICT_8x8_DC 2
cglobal %1, 2,2
    pxor        mm0, mm0
    psadbw      mm0, [r1+%2]
    paddw       mm0, [pw_4]
    psrlw       mm0, 3
    pshufw      mm0, mm0, 0
    packuswb    mm0, mm0
    STORE8      mm0
    RET
%endmacro
INIT_MMX
PREDICT_8x8_DC predict_8x8_dc_top_mmx2, 16
PREDICT_8x8_DC predict_8x8_dc_left_mmx2, 7

; sse2 is faster even on amd for 8-bit, so there's no sense in spending exe
; size on the 8-bit mmx functions below if we know sse2 is available.
%macro PREDICT_8x8_DDLR 0
;-----------------------------------------------------------------------------
; void predict_8x8_ddl( pixel *src, pixel *edge )
;-----------------------------------------------------------------------------
cglobal predict_8x8_ddl, 2,2,7
    mova        m0, [r1+16*SIZEOF_PIXEL]
    mova        m1, [r1+24*SIZEOF_PIXEL]
%if cpuflag(cache64)
    movd        m5, [r1+32*SIZEOF_PIXEL]
    palignr     m3, m1, m0, 1*SIZEOF_PIXEL
    palignr     m5, m5, m1, 1*SIZEOF_PIXEL
    palignr     m4, m1, m0, 7*SIZEOF_PIXEL
%else
    movu        m3, [r1+17*SIZEOF_PIXEL]
    movu        m4, [r1+23*SIZEOF_PIXEL]
    movu        m5, [r1+25*SIZEOF_PIXEL]
%endif
    PSLLPIX     m2, m0, 1
    add         r0, FDEC_STRIDEB*4
    PRED8x8_LOWPASS m0, m2, m3, m0, m6
    PRED8x8_LOWPASS m1, m4, m5, m1, m6
    mova        [r0+3*FDEC_STRIDEB], m1
%assign Y 2
%rep 6
    PALIGNR     m1, m0, 7*SIZEOF_PIXEL, m2
    PSLLPIX     m0, m0, 1
    mova        [r0+Y*FDEC_STRIDEB], m1
%assign Y (Y-1)
%endrep
    PALIGNR     m1, m0, 7*SIZEOF_PIXEL, m0
    mova        [r0+Y*FDEC_STRIDEB], m1
    RET

;-----------------------------------------------------------------------------
; void predict_8x8_ddr( pixel *src, pixel *edge )
;-----------------------------------------------------------------------------
cglobal predict_8x8_ddr, 2,2,7
    add         r0, FDEC_STRIDEB*4
    mova        m0, [r1+ 8*SIZEOF_PIXEL]
    mova        m1, [r1+16*SIZEOF_PIXEL]
    ; edge[] is 32byte aligned, so some of the unaligned loads are known to be not cachesplit
    movu        m2, [r1+ 7*SIZEOF_PIXEL]
    movu        m5, [r1+17*SIZEOF_PIXEL]
%if cpuflag(cache64)
    palignr     m3, m1, m0, 1*SIZEOF_PIXEL
    palignr     m4, m1, m0, 7*SIZEOF_PIXEL
%else
    movu        m3, [r1+ 9*SIZEOF_PIXEL]
    movu        m4, [r1+15*SIZEOF_PIXEL]
%endif
    PRED8x8_LOWPASS m0, m2, m3, m0, m6
    PRED8x8_LOWPASS m1, m4, m5, m1, m6
    mova        [r0+3*FDEC_STRIDEB], m0
%assign Y -4
%rep 6
    PALIGNR     m1, m0, 7*SIZEOF_PIXEL, m2
    PSLLPIX     m0, m0, 1
    mova        [r0+Y*FDEC_STRIDEB], m1
%assign Y (Y+1)
%endrep
    PALIGNR     m1, m0, 7*SIZEOF_PIXEL, m0
    mova        [r0+Y*FDEC_STRIDEB], m1
    RET
%endmacro ; PREDICT_8x8_DDLR

%if ARCH_X86_64 == 0
INIT_MMX mmx2
PREDICT_8x8_DDLR
%endif

;-----------------------------------------------------------------------------
; void predict_8x8_hu( pixel *src, pixel *edge )
;-----------------------------------------------------------------------------
%macro PREDICT_8x8_HU 2
cglobal predict_8x8_hu, 2,2,8
    add       r0, 4*FDEC_STRIDEB
    movu      m1, [r1+7*SIZEOF_PIXEL] ; l0 l1 l2 l3 l4 l5 l6 l7
    pshufw    m0, m1, q0123           ; l6 l7 l4 l5 l2 l3 l0 l1
    psllq     m1, 56                  ; l7 .. .. .. .. .. .. ..
    mova      m2, m0
    psllw     m0, 8
    psrlw     m2, 8
    por       m2, m0
    mova      m3, m2
    mova      m4, m2
    mova      m5, m2                  ; l7 l6 l5 l4 l3 l2 l1 l0
    psrlq     m3, 16
    psrlq     m2, 8
    por       m2, m1                  ; l7 l7 l6 l5 l4 l3 l2 l1
    punpckhbw m1, m1
    por       m3, m1                  ; l7 l7 l7 l6 l5 l4 l3 l2
    pavgb     m4, m2
    PRED8x8_LOWPASS m2, m3, m5, m2, m6
    punpckh%2 m0, m4, m2              ; p8 p7 p6 p5
    punpckl%2 m4, m2                  ; p4 p3 p2 p1
    PALIGNR   m5, m0, m4, 2*SIZEOF_PIXEL, m3
    pshuf%1   m1, m0, q3321
    PALIGNR   m6, m0, m4, 4*SIZEOF_PIXEL, m3
    pshuf%1   m2, m0, q3332
    PALIGNR   m7, m0, m4, 6*SIZEOF_PIXEL, m3
    pshuf%1   m3, m0, q3333
    mova      [r0-4*FDEC_STRIDEB], m4
    mova      [r0-3*FDEC_STRIDEB], m5
    mova      [r0-2*FDEC_STRIDEB], m6
    mova      [r0-1*FDEC_STRIDEB], m7
    mova      [r0+0*FDEC_STRIDEB], m0
    mova      [r0+1*FDEC_STRIDEB], m1
    mova      [r0+2*FDEC_STRIDEB], m2
    mova      [r0+3*FDEC_STRIDEB], m3
    RET
%endmacro

%if ARCH_X86_64 == 0
INIT_MMX mmx2
PREDICT_8x8_HU w, bw
%endif

;-----------------------------------------------------------------------------
; void predict_8x8_vr( pixel *src, pixel *edge )
;-----------------------------------------------------------------------------
%macro PREDICT_8x8_VR 1
cglobal predict_8x8_vr, 2,3
    mova        m2, [r1+16*SIZEOF_PIXEL]
%ifidn cpuname, ssse3
    mova        m0, [r1+8*SIZEOF_PIXEL]
    palignr     m3, m2, m0, 7*SIZEOF_PIXEL
    palignr     m1, m2, m0, 6*SIZEOF_PIXEL
%else
    movu        m3, [r1+15*SIZEOF_PIXEL]
    movu        m1, [r1+14*SIZEOF_PIXEL]
%endif
    pavg%1      m4, m3, m2
    add         r0, FDEC_STRIDEB*4
    PRED8x8_LOWPASS m3, m1, m2, m3, m5
    mova        [r0-4*FDEC_STRIDEB], m4
    mova        [r0-3*FDEC_STRIDEB], m3
    mova        m1, [r1+8*SIZEOF_PIXEL]
    PSLLPIX     m0, m1, 1
    PSLLPIX     m2, m1, 2
    PRED8x8_LOWPASS m0, m1, m2, m0, m6

%assign Y -2
%rep 5
    PALIGNR     m4, m0, 7*SIZEOF_PIXEL, m5
    mova        [r0+Y*FDEC_STRIDEB], m4
    PSLLPIX     m0, m0, 1
    SWAP 3, 4
%assign Y (Y+1)
%endrep
    PALIGNR     m4, m0, 7*SIZEOF_PIXEL, m0
    mova        [r0+Y*FDEC_STRIDEB], m4
    RET
%endmacro

%if ARCH_X86_64 == 0
INIT_MMX mmx2
PREDICT_8x8_VR b
%endif

%macro LOAD_PLANE_ARGS 0
%if cpuflag(avx2) && ARCH_X86_64 == 0
    vpbroadcastw m0, r1m
    vpbroadcastw m2, r2m
    vpbroadcastw m4, r3m
%elif mmsize == 8 ; MMX is only used on x86_32
    SPLATW       m0, r1m
    SPLATW       m2, r2m
    SPLATW       m4, r3m
%else
    movd        xm0, r1m
    movd        xm2, r2m
    movd        xm4, r3m
    SPLATW       m0, xm0
    SPLATW       m2, xm2
    SPLATW       m4, xm4
%endif
%endmacro


;-----------------------------------------------------------------------------
; void predict_16x16_p_core( uint8_t *src, int i00, int b, int c )
;-----------------------------------------------------------------------------
%if HIGH_BIT_DEPTH == 0 && ARCH_X86_64 == 0
INIT_MMX mmx2
cglobal predict_16x16_p_core, 1,2
    LOAD_PLANE_ARGS
    movq        mm5, mm2
    movq        mm1, mm2
    pmullw      mm5, [pw_0to15]
    psllw       mm2, 3
    psllw       mm1, 2
    movq        mm3, mm2
    paddsw      mm0, mm5        ; mm0 = {i+ 0*b, i+ 1*b, i+ 2*b, i+ 3*b}
    paddsw      mm1, mm0        ; mm1 = {i+ 4*b, i+ 5*b, i+ 6*b, i+ 7*b}
    paddsw      mm2, mm0        ; mm2 = {i+ 8*b, i+ 9*b, i+10*b, i+11*b}
    paddsw      mm3, mm1        ; mm3 = {i+12*b, i+13*b, i+14*b, i+15*b}

    mov         r1d, 16
ALIGN 4
.loop:
    movq        mm5, mm0
    movq        mm6, mm1
    psraw       mm5, 5
    psraw       mm6, 5
    packuswb    mm5, mm6
    movq        [r0], mm5

    movq        mm5, mm2
    movq        mm6, mm3
    psraw       mm5, 5
    psraw       mm6, 5
    packuswb    mm5, mm6
    movq        [r0+8], mm5

    paddsw      mm0, mm4
    paddsw      mm1, mm4
    paddsw      mm2, mm4
    paddsw      mm3, mm4
    add         r0, FDEC_STRIDE
    dec         r1d
    jg          .loop
    RET
%endif ; !HIGH_BIT_DEPTH && !ARCH_X86_64

%macro PREDICT_16x16_P 0
cglobal predict_16x16_p_core, 1,2,8
    movd     m0, r1m
    movd     m1, r2m
    movd     m2, r3m
    SPLATW   m0, m0, 0
    SPLATW   m1, m1, 0
    SPLATW   m2, m2, 0
    pmullw   m3, m1, [pw_0to15]
    psllw    m1, 3
    paddsw   m0, m3  ; m0 = {i+ 0*b, i+ 1*b, i+ 2*b, i+ 3*b, i+ 4*b, i+ 5*b, i+ 6*b, i+ 7*b}
    paddsw   m1, m0  ; m1 = {i+ 8*b, i+ 9*b, i+10*b, i+11*b, i+12*b, i+13*b, i+14*b, i+15*b}
    paddsw   m7, m2, m2
    mov     r1d, 8
ALIGN 4
.loop:
    psraw    m3, m0, 5
    psraw    m4, m1, 5
    paddsw   m5, m0, m2
    paddsw   m6, m1, m2
    psraw    m5, 5
    psraw    m6, 5
    packuswb m3, m4
    packuswb m5, m6
    mova [r0+FDEC_STRIDE*0], m3
    mova [r0+FDEC_STRIDE*1], m5
    paddsw   m0, m7
    paddsw   m1, m7
    add      r0, FDEC_STRIDE*2
    dec     r1d
    jg .loop
    RET
%endmacro ; PREDICT_16x16_P

INIT_XMM sse2
PREDICT_16x16_P
%if HIGH_BIT_DEPTH == 0
INIT_XMM avx
PREDICT_16x16_P
%endif

INIT_YMM avx2
cglobal predict_16x16_p_core, 1,2,8*HIGH_BIT_DEPTH
    LOAD_PLANE_ARGS
    vbroadcasti128 m1, [pw_0to15]
    mova        xm3, xm4    ; zero high bits
    pmullw       m1, m2
    psllw        m2, 3
    paddsw       m0, m3
    paddsw       m0, m1     ; X+1*C X+0*C
    paddsw       m1, m0, m2 ; Y+1*C Y+0*C
    paddsw       m4, m4
    mov         r1d, 4
.loop:
    psraw        m2, m0, 5
    psraw        m3, m1, 5
    paddsw       m0, m4
    paddsw       m1, m4
    packuswb     m2, m3     ; X+1*C Y+1*C X+0*C Y+0*C
    vextracti128 [r0+0*FDEC_STRIDE], m2, 1
    mova         [r0+1*FDEC_STRIDE], xm2
    psraw        m2, m0, 5
    psraw        m3, m1, 5
    paddsw       m0, m4
    paddsw       m1, m4
    packuswb     m2, m3     ; X+3*C Y+3*C X+2*C Y+2*C
    vextracti128 [r0+2*FDEC_STRIDE], m2, 1
    mova         [r0+3*FDEC_STRIDE], xm2
    add          r0, FDEC_STRIDE*4
    dec         r1d
    jg .loop
    RET

%if HIGH_BIT_DEPTH == 0
%macro PREDICT_8x8 0
;-----------------------------------------------------------------------------
; void predict_8x8_ddl( uint8_t *src, uint8_t *edge )
;-----------------------------------------------------------------------------
cglobal predict_8x8_ddl, 2,2
    mova        m0, [r1+16]
%ifidn cpuname, ssse3
    movd        m2, [r1+32]
    palignr     m2, m0, 1
%else
    movu        m2, [r1+17]
%endif
    pslldq      m1, m0, 1
    add        r0, FDEC_STRIDE*4
    PRED8x8_LOWPASS m0, m1, m2, m0, m3

%assign Y -4
%rep 8
    psrldq      m0, 1
    movq        [r0+Y*FDEC_STRIDE], m0
%assign Y (Y+1)
%endrep
    RET

%ifnidn cpuname, ssse3
;-----------------------------------------------------------------------------
; void predict_8x8_ddr( uint8_t *src, uint8_t *edge )
;-----------------------------------------------------------------------------
cglobal predict_8x8_ddr, 2,2
    movu        m0, [r1+8]
    movu        m1, [r1+7]
    psrldq      m2, m0, 1
    add         r0, FDEC_STRIDE*4
    PRED8x8_LOWPASS m0, m1, m2, m0, m3

    psrldq      m1, m0, 1
%assign Y 3
%rep 3
    movq        [r0+Y*FDEC_STRIDE], m0
    movq        [r0+(Y-1)*FDEC_STRIDE], m1
    psrldq      m0, 2
    psrldq      m1, 2
%assign Y (Y-2)
%endrep
    movq        [r0-3*FDEC_STRIDE], m0
    movq        [r0-4*FDEC_STRIDE], m1
    RET

;-----------------------------------------------------------------------------
; void predict_8x8_vl( uint8_t *src, uint8_t *edge )
;-----------------------------------------------------------------------------
cglobal predict_8x8_vl, 2,2
    mova        m0, [r1+16]
    pslldq      m1, m0, 1
    psrldq      m2, m0, 1
    pavgb       m3, m0, m2
    add         r0, FDEC_STRIDE*4
    PRED8x8_LOWPASS m0, m1, m2, m0, m5
; m0: (t0 + 2*t1 + t2 + 2) >> 2
; m3: (t0 + t1 + 1) >> 1

%assign Y -4
%rep 3
    psrldq      m0, 1
    movq        [r0+ Y   *FDEC_STRIDE], m3
    movq        [r0+(Y+1)*FDEC_STRIDE], m0
    psrldq      m3, 1
%assign Y (Y+2)
%endrep
    psrldq      m0, 1
    movq        [r0+ Y   *FDEC_STRIDE], m3
    movq        [r0+(Y+1)*FDEC_STRIDE], m0
    RET
%endif ; !ssse3

;-----------------------------------------------------------------------------
; void predict_8x8_vr( uint8_t *src, uint8_t *edge )
;-----------------------------------------------------------------------------
cglobal predict_8x8_vr, 2,2
    movu        m2, [r1+8]
    add         r0, 4*FDEC_STRIDE
    pslldq      m1, m2, 2
    pslldq      m0, m2, 1
    pavgb       m3, m2, m0
    PRED8x8_LOWPASS m0, m2, m1, m0, m4
    movhps      [r0-4*FDEC_STRIDE], m3
    movhps      [r0-3*FDEC_STRIDE], m0
%if cpuflag(ssse3)
    punpckhqdq  m3, m3
    pshufb      m0, [shuf_vr]
    palignr     m3, m0, 13
%else
    mova        m2, m0
    mova        m1, [pw_00ff]
    pand        m1, m0
    psrlw       m0, 8
    packuswb    m1, m0
    pslldq      m1, 4
    movhlps     m3, m1
    shufps      m1, m2, q3210
    psrldq      m3, 5
    psrldq      m1, 5
    SWAP         0, 1
%endif
    movq        [r0+3*FDEC_STRIDE], m0
    movq        [r0+2*FDEC_STRIDE], m3
    psrldq      m0, 1
    psrldq      m3, 1
    movq        [r0+1*FDEC_STRIDE], m0
    movq        [r0+0*FDEC_STRIDE], m3
    psrldq      m0, 1
    psrldq      m3, 1
    movq        [r0-1*FDEC_STRIDE], m0
    movq        [r0-2*FDEC_STRIDE], m3
    RET
%endmacro ; PREDICT_8x8

INIT_XMM sse2
PREDICT_8x8
INIT_XMM ssse3
PREDICT_8x8
INIT_XMM avx
PREDICT_8x8

%endif ; !HIGH_BIT_DEPTH

;-----------------------------------------------------------------------------
; void predict_8x8_vl( pixel *src, pixel *edge )
;-----------------------------------------------------------------------------
%macro PREDICT_8x8_VL_10 1
cglobal predict_8x8_vl, 2,2,8
    mova         m0, [r1+16*SIZEOF_PIXEL]
    mova         m1, [r1+24*SIZEOF_PIXEL]
    PALIGNR      m2, m1, m0, SIZEOF_PIXEL*1, m4
    PSRLPIX      m4, m1, 1
    pavg%1       m6, m0, m2
    pavg%1       m7, m1, m4
    add          r0, FDEC_STRIDEB*4
    mova         [r0-4*FDEC_STRIDEB], m6
    PALIGNR      m3, m7, m6, SIZEOF_PIXEL*1, m5
    mova         [r0-2*FDEC_STRIDEB], m3
    PALIGNR      m3, m7, m6, SIZEOF_PIXEL*2, m5
    mova         [r0+0*FDEC_STRIDEB], m3
    PALIGNR      m7, m7, m6, SIZEOF_PIXEL*3, m5
    mova         [r0+2*FDEC_STRIDEB], m7
    PALIGNR      m3, m1, m0, SIZEOF_PIXEL*7, m6
    PSLLPIX      m5, m0, 1
    PRED8x8_LOWPASS m0, m5, m2, m0, m7
    PRED8x8_LOWPASS m1, m3, m4, m1, m7
    PALIGNR      m4, m1, m0, SIZEOF_PIXEL*1, m2
    mova         [r0-3*FDEC_STRIDEB], m4
    PALIGNR      m4, m1, m0, SIZEOF_PIXEL*2, m2
    mova         [r0-1*FDEC_STRIDEB], m4
    PALIGNR      m4, m1, m0, SIZEOF_PIXEL*3, m2
    mova         [r0+1*FDEC_STRIDEB], m4
    PALIGNR      m1, m1, m0, SIZEOF_PIXEL*4, m2
    mova         [r0+3*FDEC_STRIDEB], m1
    RET
%endmacro
INIT_MMX mmx2
PREDICT_8x8_VL_10 b

;-----------------------------------------------------------------------------
; void predict_8x8_hd( pixel *src, pixel *edge )
;-----------------------------------------------------------------------------
%macro PREDICT_8x8_HD 2
cglobal predict_8x8_hd, 2,2
    add       r0, 4*FDEC_STRIDEB
    mova      m0, [r1+ 8*SIZEOF_PIXEL]     ; lt l0 l1 l2 l3 l4 l5 l6
    movu      m1, [r1+ 7*SIZEOF_PIXEL]     ; l0 l1 l2 l3 l4 l5 l6 l7
%ifidn cpuname, ssse3
    mova      m2, [r1+16*SIZEOF_PIXEL]     ; t7 t6 t5 t4 t3 t2 t1 t0
    mova      m4, m2                       ; t7 t6 t5 t4 t3 t2 t1 t0
    palignr   m2, m0, 7*SIZEOF_PIXEL       ; t6 t5 t4 t3 t2 t1 t0 lt
    palignr   m4, m0, 1*SIZEOF_PIXEL       ; t0 lt l0 l1 l2 l3 l4 l5
%else
    movu      m2, [r1+15*SIZEOF_PIXEL]
    movu      m4, [r1+ 9*SIZEOF_PIXEL]
%endif ; cpuflag
    pavg%1    m3, m0, m1
    PRED8x8_LOWPASS m0, m4, m1, m0, m5
    PSRLPIX   m4, m2, 2                    ; .. .. t6 t5 t4 t3 t2 t1
    PSRLPIX   m1, m2, 1                    ; .. t6 t5 t4 t3 t2 t1 t0
    PRED8x8_LOWPASS m1, m4, m2, m1, m5
                                           ; .. p11 p10 p9
    punpckh%2 m2, m3, m0                   ; p8 p7 p6 p5
    punpckl%2 m3, m0                       ; p4 p3 p2 p1
    mova      [r0+3*FDEC_STRIDEB], m3
    PALIGNR   m0, m2, m3, 2*SIZEOF_PIXEL, m5
    mova      [r0+2*FDEC_STRIDEB], m0
    PALIGNR   m0, m2, m3, 4*SIZEOF_PIXEL, m5
    mova      [r0+1*FDEC_STRIDEB], m0
    PALIGNR   m0, m2, m3, 6*SIZEOF_PIXEL, m3
    mova      [r0+0*FDEC_STRIDEB], m0
    mova      [r0-1*FDEC_STRIDEB], m2
    PALIGNR   m0, m1, m2, 2*SIZEOF_PIXEL, m5
    mova      [r0-2*FDEC_STRIDEB], m0
    PALIGNR   m0, m1, m2, 4*SIZEOF_PIXEL, m5
    mova      [r0-3*FDEC_STRIDEB], m0
    PALIGNR   m1, m1, m2, 6*SIZEOF_PIXEL, m2
    mova      [r0-4*FDEC_STRIDEB], m1
    RET
%endmacro

INIT_MMX mmx2
PREDICT_8x8_HD b, bw

;-----------------------------------------------------------------------------
; void predict_8x8_hd( uint8_t *src, uint8_t *edge )
;-----------------------------------------------------------------------------
%macro PREDICT_8x8_HD 0
cglobal predict_8x8_hd, 2,2
    add     r0, 4*FDEC_STRIDE
    movu    m1, [r1+7]
    movu    m3, [r1+8]
    movu    m2, [r1+9]
    pavgb   m4, m1, m3
    PRED8x8_LOWPASS m0, m1, m2, m3, m5
    punpcklbw m4, m0
    movhlps m0, m4

%assign Y 3
%rep 3
    movq   [r0+(Y)*FDEC_STRIDE], m4
    movq   [r0+(Y-4)*FDEC_STRIDE], m0
    psrldq m4, 2
    psrldq m0, 2
%assign Y (Y-1)
%endrep
    movq   [r0+(Y)*FDEC_STRIDE], m4
    movq   [r0+(Y-4)*FDEC_STRIDE], m0
    RET
%endmacro

INIT_XMM sse2
PREDICT_8x8_HD
INIT_XMM avx
PREDICT_8x8_HD

%if HIGH_BIT_DEPTH == 0
;-----------------------------------------------------------------------------
; void predict_8x8_hu( uint8_t *src, uint8_t *edge )
;-----------------------------------------------------------------------------
INIT_MMX
cglobal predict_8x8_hu_sse2, 2,2
    add        r0, 4*FDEC_STRIDE
    movq      mm1, [r1+7]           ; l0 l1 l2 l3 l4 l5 l6 l7
    pshufw    mm0, mm1, q0123       ; l6 l7 l4 l5 l2 l3 l0 l1
    movq      mm2, mm0
    psllw     mm0, 8
    psrlw     mm2, 8
    por       mm2, mm0              ; l7 l6 l5 l4 l3 l2 l1 l0
    psllq     mm1, 56               ; l7 .. .. .. .. .. .. ..
    movq      mm3, mm2
    movq      mm4, mm2
    movq      mm5, mm2
    psrlq     mm2, 8
    psrlq     mm3, 16
    por       mm2, mm1              ; l7 l7 l6 l5 l4 l3 l2 l1
    punpckhbw mm1, mm1
    por       mm3, mm1              ; l7 l7 l7 l6 l5 l4 l3 l2
    pavgb     mm4, mm2
    PRED8x8_LOWPASS mm1, mm3, mm5, mm2, mm6

    movq2dq   xmm0, mm4
    movq2dq   xmm1, mm1
    punpcklbw xmm0, xmm1
    punpckhbw  mm4, mm1
%assign Y -4
%rep 3
    movq     [r0+Y*FDEC_STRIDE], xmm0
    psrldq    xmm0, 2
%assign Y (Y+1)
%endrep
    pshufw     mm5, mm4, q3321
    pshufw     mm6, mm4, q3332
    pshufw     mm7, mm4, q3333
    movq     [r0+Y*FDEC_STRIDE], xmm0
    movq     [r0+0*FDEC_STRIDE], mm4
    movq     [r0+1*FDEC_STRIDE], mm5
    movq     [r0+2*FDEC_STRIDE], mm6
    movq     [r0+3*FDEC_STRIDE], mm7
    RET

INIT_XMM
cglobal predict_8x8_hu_ssse3, 2,2
    add       r0, 4*FDEC_STRIDE
    movq      m3, [r1+7]
    pshufb    m3, [shuf_hu]
    psrldq    m1, m3, 1
    psrldq    m2, m3, 2
    pavgb     m0, m1, m3
    PRED8x8_LOWPASS m1, m3, m2, m1, m4
    punpcklbw m0, m1
%assign Y -4
%rep 3
    movq   [r0+ Y   *FDEC_STRIDE], m0
    movhps [r0+(Y+4)*FDEC_STRIDE], m0
    psrldq    m0, 2
    pshufhw   m0, m0, q2210
%assign Y (Y+1)
%endrep
    movq   [r0+ Y   *FDEC_STRIDE], m0
    movhps [r0+(Y+4)*FDEC_STRIDE], m0
    RET
%endif ; !HIGH_BIT_DEPTH

;-----------------------------------------------------------------------------
; void predict_8x8c_dc( pixel *src )
;-----------------------------------------------------------------------------
%macro LOAD_LEFT 1
    movzx    r1d, pixel [r0+FDEC_STRIDEB*(%1-4)-SIZEOF_PIXEL]
    movzx    r2d, pixel [r0+FDEC_STRIDEB*(%1-3)-SIZEOF_PIXEL]
    add      r1d, r2d
    movzx    r2d, pixel [r0+FDEC_STRIDEB*(%1-2)-SIZEOF_PIXEL]
    add      r1d, r2d
    movzx    r2d, pixel [r0+FDEC_STRIDEB*(%1-1)-SIZEOF_PIXEL]
    add      r1d, r2d
%endmacro

%macro STORE_4LINES 2
    movq [r0+FDEC_STRIDEB*(%2-4)], %1
    movq [r0+FDEC_STRIDEB*(%2-3)], %1
    movq [r0+FDEC_STRIDEB*(%2-2)], %1
    movq [r0+FDEC_STRIDEB*(%2-1)], %1
%endmacro

;-----------------------------------------------------------------------------
; void predict_16x16_v( pixel *src )
;-----------------------------------------------------------------------------

%macro PREDICT_16x16_V 0
cglobal predict_16x16_v, 1,2
%assign %%i 0
%rep 16*SIZEOF_PIXEL/mmsize
    mova m %+ %%i, [r0-FDEC_STRIDEB+%%i*mmsize]
%assign %%i %%i+1
%endrep
%if 16*SIZEOF_PIXEL/mmsize == 4
    STORE16 m0, m1, m2, m3
%elif 16*SIZEOF_PIXEL/mmsize == 2
    STORE16 m0, m1
%else
    STORE16 m0
%endif
    RET
%endmacro

INIT_MMX mmx2
PREDICT_16x16_V
INIT_XMM sse
PREDICT_16x16_V

;-----------------------------------------------------------------------------
; void predict_16x16_h( pixel *src )
;-----------------------------------------------------------------------------
%macro PREDICT_16x16_H 0
cglobal predict_16x16_h, 1,2
%if cpuflag(ssse3) && notcpuflag(avx2)
    mova  m2, [pb_3]
%endif
    mov  r1d, 4
.loop:
    PRED_H_4ROWS 16, 1
    dec  r1d
    jg .loop
    RET
%endmacro

INIT_MMX mmx2
PREDICT_16x16_H
;no SSE2 for 8-bit, it's slower than MMX on all systems that don't support SSSE3
INIT_XMM ssse3
PREDICT_16x16_H

;-----------------------------------------------------------------------------
; void predict_16x16_dc( pixel *src )
;-----------------------------------------------------------------------------
%if WIN64
DECLARE_REG_TMP 6 ; Reduces code size due to fewer REX prefixes
%else
DECLARE_REG_TMP 3
%endif

INIT_XMM
; Returns the sum of the left pixels in r1d+r2d
cglobal predict_16x16_dc_left_internal, 0,4
    movzx r1d, pixel [r0-SIZEOF_PIXEL]
    movzx r2d, pixel [r0+FDEC_STRIDEB-SIZEOF_PIXEL]
%assign i 2*FDEC_STRIDEB
%rep 7
    movzx t0d, pixel [r0+i-SIZEOF_PIXEL]
    add   r1d, t0d
    movzx t0d, pixel [r0+i+FDEC_STRIDEB-SIZEOF_PIXEL]
    add   r2d, t0d
%assign i i+2*FDEC_STRIDEB
%endrep
    RET

%macro PRED16x16_DC 2
    pxor        m0, m0
    psadbw      m0, [r0 - FDEC_STRIDE]
    MOVHL       m1, m0
    paddw       m0, m1
    paddusw     m0, %1
    psrlw       m0, %2              ; dc
    SPLATW      m0, m0
    packuswb    m0, m0              ; dc in bytes
    STORE16     m0
%endmacro

%macro PREDICT_16x16_DC 0
cglobal predict_16x16_dc, 1,3
    call predict_16x16_dc_left_internal
    lea          r1d, [r1+r2+16]
    movd         xm3, r1d
    PRED16x16_DC xm3, 5
    RET

cglobal predict_16x16_dc_top, 1,2
    PRED16x16_DC [pw_8], 4
    RET

cglobal predict_16x16_dc_left, 1,3
    call predict_16x16_dc_left_internal
    lea       r1d, [r1+r2+8]
    shr       r1d, 4
    movd      xm0, r1d
    SPLATW     m0, xm0
%if HIGH_BIT_DEPTH && mmsize == 16
    STORE16    m0, m0
%else
%if HIGH_BIT_DEPTH == 0
    packuswb   m0, m0
%endif
    STORE16    m0
%endif
    RET
%endmacro

INIT_XMM sse2
PREDICT_16x16_DC
INIT_XMM avx2
PREDICT_16x16_DC



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

; (f1 + 2f2 + f3 + 2) >> 4 -> ((f1 + f3) / 2 + f2 + 1) / 2 <==> Avg((f1 + f3) / 2, f2)
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
    vpbroadcastb   m0, [r0 - 129]        ; l8
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
