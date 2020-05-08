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

mbtree_fix8_last_mask:   times 32 db  0
                         times 32 db -1
mbtree_fix8_unpack_shuf: db -1,-1, 1, 0,-1,-1, 3, 2,-1,-1, 5, 4,-1,-1, 7, 6
                         db -1,-1, 9, 8,-1,-1,11,10,-1,-1,13,12,-1,-1,15,14
mbtree_fix8_pack_shuf:   db  1, 0, 3, 2, 5, 4, 7, 6, 9, 8,11,10,13,12,15,14
deinterleave_shuf:       db  0, 2, 4, 6, 8,10,12,14, 1, 3, 5, 7, 9,11,13,15
hpel_shuf:               db  0, 8, 1, 9, 2,10, 3,11, 4,12, 5,13, 6,14, 7,15
mc_chrome_shuf:          db  0, 2, 2, 4, 4, 6, 6, 8, 1, 3, 3, 5, 5, 7, 7, 9
pf_256:                  dd  256.0
pf_inv16777216:          dd  0x1p-24
pb_64:                   times 4 db 64
pw_1024:                 times 2 dw 1024
filt_mul20:              times 4 db 20
filt_mul15:              times 2 db 1, -5
filt_mul51:              times 2 db -5, 1


SECTION .text

cextern pw_1
cextern pw_512
cextern deinterleave_shufd

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
; mbtree_fix8
;=============================================================================
INIT_YMM avx2
cglobal mbtree_fix8_pack, 0, 0
    vbroadcastss   m0, [pf_256]
    vbroadcasti128 m1, [mbtree_fix8_pack_shuf]
    sub            r2d, 16             ; subtract the last block
    jle            .skip
.vector_loop:
    vmulps         m2, m0, [r1]
    vmulps         m3, m0, [r1 + 32]
    vcvttps2dq     m2, m2
    vcvttps2dq     m3, m3
    vpackssdw      m2, m2, m3          ; 0 2 | 1 3
    vpshufb        m2, m2, m1          ; convert to big-endian
    vpermq         m2, m2, q3120       ; 0 1 | 2 3
    vmovdqu        [r0], m2
    add            r0, 32
    add            r1, 64
    sub            r2d, 16
    jg             .vector_loop

.skip:
    vmulps         m2, m0, [r1]
    vmulps         m3, m0, [r1 + 32]
    vcvttps2dq     m2, m2
    vcvttps2dq     m3, m3
    vpackssdw      m2, m2, m3          ; 0 2 | 1 3
    vpshufb        m2, m2, m1          ; convert to big-endian
    vpermq         m2, m2, q3120       ; 0 1 | 2 3
    lea            r1, [mbtree_fix8_last_mask]
    neg            r2d                 ; convert to positive index
    ; load the mask
    vmovdqu        m3, [r1 + r2 * 2]
    ; mask merge
    vpblendvb      m2, m2, [r0], m3
    vmovdqu        [r0], m2
    RET

INIT_YMM avx2
cglobal mbtree_fix8_unpack, 0, 0
    vbroadcastss   m0, [pf_inv16777216]
    vmovdqu        m1, [mbtree_fix8_unpack_shuf]
    sub            r2d, 16             ; subtract the last block
    jle            .skip
.vector_loop:
    vbroadcasti128 m2, [r1]
    vbroadcasti128 m3, [r1 + 16]
    ; convert 16 bit to 32 bit
    ; left-align values to keep signed, equivalent to multiply 65536
    vpshufb        m2, m2, m1
    vpshufb        m3, m3, m1
    vcvtdq2ps      m2, m2
    vcvtdq2ps      m3, m3
    ; multiply 1 / 256 / 65536
    vmulps         m2, m2, m0
    vmulps         m3, m3, m0
    vmovdqu        [r0], m2
    vmovdqu        [r0 + 32], m3
    add            r0, 64
    add            r1, 32
    sub            r2d, 16
    jg             .vector_loop

.skip:
    vbroadcasti128 m2, [r1]
    vbroadcasti128 m3, [r1 + 16]
    vpshufb        m2, m2, m1
    vpshufb        m3, m3, m1
    vcvtdq2ps      m2, m2
    vcvtdq2ps      m3, m3
    vmulps         m2, m2, m0
    vmulps         m3, m3, m0
    lea            r1, [mbtree_fix8_last_mask]
    neg            r2d                 ; upper half index
    mov            r3d, r2d
    ; limit upper index to [0, 8]
    mov            r6d, 8
    cmp            r2d, 8
    cmovg          r2d, r6d
    ; the lower index will fall into [0, 7]
    sub            r3d, r2d
    ; load the mask
    vmovdqu        m4, [r1 + r3 * 4]
    vmovdqu        m5, [r1 + r2 * 4]
    ; mask merge
    vpblendvb      m2, m2, [r0], m4
    vpblendvb      m3, m3, [r0 + 32], m5
    vmovdqu        [r0], m2
    vmovdqu        [r0 + 32], m3
    RET


;=============================================================================
; memcpy/memzero
;=============================================================================
; These functions are not general-use; not only do they require aligned input, but memcpy
; requires size to be a multiple of 16 and memzero requires size to be a multiple of 128.
ALIGN 32
INIT_YMM avx2
cglobal memcpy_aligned, 0, 0
    lea            r6, [r0 + r2]       ; deal with the trailer
    test           r2d, 16             ; end with 16?
    jz             .copy32
    vmovdqu        xm0, [r1 + r2 - 16]
    vmovdqu        [r6 - 16], xm0
    sub            r6, 16
    sub            r2d, 16
    jle            .ret
.copy32:
    test           r2d, 32             ; end with 32?
    jz             .loop
    vmovdqu        m0, [r1 + r2 - 32]
    vmovdqu        [r6 - 32], m0
    sub            r2d, 32
    jle            .ret
ALIGN 16
.loop:
    vmovdqu        m0, [r1]
    vmovdqu        m1, [r1 + 32]
    vmovdqu        [r0], m0
    vmovdqu        [r0 + 32], m1
    add            r0, 64
    add            r1, 64
    sub            r2d, 64
    jg             .loop
.ret:
    RET

INIT_YMM avx2
cglobal memzero_aligned, 0, 0
    vpxor          m0, m0, m0
.loop:
    vmovdqu        [r0 + r1 - 32], m0
    vmovdqu        [r0 + r1 - 64], m0
    vmovdqu        [r0 + r1 - 96], m0
    vmovdqu        [r0 + r1 - 128], m0
    sub            r1d, 128
    jg             .loop
    RET


;=============================================================================
; mc_chroma
;=============================================================================
INIT_YMM avx2
cglobal mc_chroma, 0, 0
    push           r7
    push           r8
%if WIN64
    mov            r4, [rsp + 56]
    movsxd         r5, [rsp + 64]
    movsxd         r6, [rsp + 72]
%else
    movsxd         r5, r5d
    movsxd         r6, [rsp + 24]
%endif
    ; r0: dstu
    ; r1: dstv
    ; r2: dst_stride
    ; r3: src
    ; r4: src_stride
    ; r5: mvx (I don't know if they are non-negtive )
    ; r6: mvy (use 64-bit to ensure correct address generation)
    ; load width and height later

    ; save mvx/y for later use
    mov            r7d, r5d
    mov            r8d, r6d
    ; calculate src
    sar            r5, 3
    sar            r6, 3
    imul           r6, r4              ; (mvy >> 3) * src_stride
    lea            r3, [r3 + r5 * 2]   ; src += (mvx >> 3)*2
    add            r3, r6              ; new src
    ; calculate cX, can hold in unsigned 8-bit
    and            r7d, 7              ; d8x
    and            r8d, 7              ; d8y
    mov            r5d, r7d
    shl            r7d, 8              ; d8x | 0
    sub            r7d, r5d            ; d8x | -d8x
    add            r7d, 8              ; d8x | 8 - d8x
    mov            r6d, 8
    sub            r6d, r8d            ; 8 - d8y
    ; the multiply won't affect high 8-bit since they are small enough
    imul           r6d, r7d            ; cB | cA
    imul           r8d, r7d            ; cD | cC
    vmovd          xm0, r6d
    vmovd          xm1, r8d
    vpbroadcastw   m0, xm0             ; A, B, A, B, ... | A, B, A, B, ...
    vpbroadcastw   m1, xm1             ; C, D, C, D, ... | C, D, C, D, ...
    vpbroadcastd   m2, [pw_512]
    vbroadcasti128 m3, [mc_chrome_shuf]
%if WIN64
    mov            r6d, [rsp + 88]     ; height
    cmp            dword [rsp + 80], 4
%else
    mov            r6d, [rsp + 40]     ; height
    cmp            dword [rsp + 32], 4
%endif
    jg             .width8

.loop4:
    vmovdqu        xm4, [r3]                  ; src
    vmovdqu        xm5, [r3 + r4]             ; srcp
    vinserti128    m4, m4, xm5, 1
    vinserti128    m5, m5, [r3 + r4 * 2], 1   ; srcp + stride
    vpshufb        m4, m4, m3                 ; 0 2 2 4 4 6 6 8, 1 3 3 5 5 7 7 9 -> dstu, dstv
    vpshufb        m5, m5, m3
    vpmaddubsw     m4, m4, m0
    vpmaddubsw     m5, m5, m1
    vpaddw         m4, m4, m5
    ; multiply 512 to shift left and round by using vpmulhrsw
    vpmulhrsw      m4, m4, m2
    ; clip to 8-bit and store
    vpackuswb      m4, m4, m4
    vextracti128   xm5, m4, 1
    vmovd          [r0], xm4
    vpextrd        [r1], xm4, 1
    vmovd          [r0 + r2], xm5
    vpextrd        [r1 + r2], xm5, 1
    lea            r3, [r3 + r4 * 2]
    lea            r0, [r0 + r2 * 2]
    lea            r1, [r1 + r2 * 2]
    sub            r6d, 2
    jg             .loop4
    pop            r8
    pop            r7
    RET

ALIGN 16
.width8:
%if WIN64
    vmovdqu        [rsp + 24], xm6
    vmovdqu        [rsp + 40], xm7
    sub            rsp, 24
    vmovdqu        [rsp], xm8
%endif
    vmovdqu        m8, [deinterleave_shufd]
    vmovdqu        xm4, [r3]                  ; src lower part
    vinserti128    m4, m4, [r3 + 8], 1        ; src upper part
    vpshufb        m4, m4, m3
.loop8:
    vmovdqu        xm5, [r3 + r4]             ; srcp lower part & next iteration src
    vinserti128    m5, m5, [r3 + r4 + 8], 1   ; srcp upper part & next iteration src
    vpshufb        m5, m5, m3
    vpmaddubsw     m4, m4, m0
    vpmaddubsw     m6, m5, m1
    vpaddw         m6, m6, m4
    vmovdqu        xm4, [r3 + r4 * 2]         ; next iteration srcp
    vinserti128    m4, m4, [r3 + r4 * 2 + 8], 1
    vpshufb        m4, m4, m3
    vpmaddubsw     m5, m5, m0
    vpmaddubsw     m7, m4, m1
    vpaddw         m7, m7, m5
    vpmulhrsw      m6, m6, m2
    vpmulhrsw      m7, m7, m2
    vpackuswb      m6, m6, m7                 ; this iter: dstu, dstv -- next iter: dstu, dstv (128-bit lane)
    vpermd         m6, m8, m6
    vextracti128   xm7, m6, 1
    vmovq          [r0], xm6                  ; this iter
    vmovhps        [r1], xm6
    vmovq          [r0 + r2], xm7             ; next iter
    vmovhps        [r1 + r2], xm7
    lea            r0, [r0 + r2 * 2]
    lea            r1, [r1 + r2 * 2]
    lea            r3, [r3 + r4 * 2]
    sub            r6d, 2
    jg             .loop8
%if WIN64
    vmovdqu        xm8, [rsp]
    add            rsp, 24
    vmovdqu        xm6, [rsp + 24]
    vmovdqu        xm7, [rsp + 40]
%endif
    pop            r8
    pop            r7
    RET


;=============================================================================
; mc_copy
;=============================================================================
INIT_XMM avx2
cglobal mc_copy_w4, 0, 0
    lea            r6, [r1 + r1 * 2]
    lea            r5, [r3 + r3 * 2]
%if WIN64
    cmp            dword [rsp + 40], 4       ; height
%else
    cmp            r4d, 4
%endif
    je             .end
    vmovd          m0, [r2]
    vmovd          m1, [r2 + r3]
    vmovd          m2, [r2 + r3 * 2]
    vmovd          m3, [r2 + r5]
    vmovd          [r0], m0
    vmovd          [r0 + r1], m1
    vmovd          [r0 + r1 * 2], m2
    vmovd          [r0 + r6], m3
    lea            r2, [r2 + r3 * 4]
    lea            r0, [r0 + r1 * 4]

ALIGN 16
.end:
    vmovd          m0, [r2]
    vmovd          m1, [r2 + r3]
    vmovd          m2, [r2 + r3 * 2]
    vmovd          m3, [r2 + r5]
    vmovd          [r0], m0
    vmovd          [r0 + r1], m1
    vmovd          [r0 + r1 * 2], m2
    vmovd          [r0 + r6], m3
    ret

INIT_XMM avx2
cglobal mc_copy_w8, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
%endif
    lea            r6, [r1 + r1 * 2]
    lea            r5, [r3 + r3 * 2]
.loop:
    vmovq          m0, [r2]
    vmovq          m1, [r2 + r3]
    vmovq          m2, [r2 + r3 * 2]
    vmovq          m3, [r2 + r5]
    vmovq          [r0], m0
    vmovq          [r0 + r1], m1
    vmovq          [r0 + r1 * 2], m2
    vmovq          [r0 + r6], m3
    lea            r2, [r2 + r3 * 4]
    lea            r0, [r0 + r1 * 4]
    sub            r4d, 4
    jg             .loop
    ret

INIT_XMM avx2
cglobal mc_copy_w16, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
%endif
    lea            r6, [r1 + r1 * 2]
    lea            r5, [r3 + r3 * 2]
.loop:
    vmovdqu        m0, [r2]
    vmovdqu        m1, [r2 + r3]
    vmovdqu        m2, [r2 + r3 * 2]
    vmovdqu        m3, [r2 + r5]
    vmovdqu        [r0], m0
    vmovdqu        [r0 + r1], m1
    vmovdqu        [r0 + r1 * 2], m2
    vmovdqu        [r0 + r6], m3
    lea            r2, [r2 + r3 * 4]
    lea            r0, [r0 + r1 * 4]
    sub            r4d, 4
    jg             .loop
    ret


;=============================================================================
; pixel_avg2
;=============================================================================
INIT_XMM avx2
cglobal pixel_avg2_w4, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    ; since src1 and src2 have a common stride
    ; use src1 + diff to represent src2, can reduce src2 += stride
    sub            r4, r2
    lea            r6, [r4 + r3]
.loop:
    vmovd          m0, [r2]
    vmovd          m1, [r2 + r3]
    vmovd          m2, [r2 + r4]
    vmovd          m3, [r2 + r6]
    lea            r2, [r2 + r3 * 2]
    vpavgb         m0, m0, m2
    vpavgb         m1, m1, m3
    vmovd          [r0], m0
    vmovd          [r0 + r1], m1
    lea            r0, [r0 + r1 * 2]
    sub            r5d, 2
    jg             .loop
    ret

INIT_XMM avx2
cglobal pixel_avg2_w8, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    ; since src1 and src2 have a common stride
    ; use src1 + diff to represent src2, can reduce src2 += stride
    sub            r4, r2
    lea            r6, [r4 + r3]
.loop:
    vmovq          m0, [r2]
    vmovq          m1, [r2 + r3]
    vmovq          m2, [r2 + r4]
    vmovq          m3, [r2 + r6]
    lea            r2, [r2 + r3 * 2]
    vpavgb         m0, m0, m2
    vpavgb         m1, m1, m3
    vmovq          [r0], m0
    vmovq          [r0 + r1], m1
    lea            r0, [r0 + r1 * 2]
    sub            r5d, 2
    jg             .loop
    ret


INIT_XMM avx2
cglobal pixel_avg2_w16, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    ; since src1 and src2 have a common stride
    ; use src1 + diff to represent src2, can reduce src2 += stride
    sub            r4, r2
    lea            r6, [r4 + r3]
.loop:
    vmovdqu        m0, [r2]
    vmovdqu        m1, [r2 + r3]
    vpavgb         m0, m0, [r2 + r4]
    vpavgb         m1, m1, [r2 + r6]
    lea            r2, [r2 + r3 * 2]
    vmovdqu        [r0], m0
    vmovdqu        [r0 + r1], m1
    lea            r0, [r0 + r1 * 2]
    sub            r5d, 2
    jg             .loop
    ret


; we can overwrite in GET_REF but not in MC_LUMA
; use XMM for MC_LUMA, YMM for GET_REF
INIT_XMM avx2
cglobal pixel_avg2_w20, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    sub            r4, r2
    lea            r6, [r4 + r3]
.loop:
    vmovdqu        m0, [r2]
    vpavgb         m0, m0, [r2 + r4]
    vmovd          m1, [r2 + 16]
    vmovd          m2, [r2 + r4 + 16]
    vpavgb         m1, m1, m2
    vmovdqu        m2, [r2 + r3]
    vpavgb         m2, m2, [r2 + r6]
    vmovd          m3, [r2 + r3 + 16]
    vmovd          m4, [r2 + r6 + 16]
    lea            r2, [r2 + r3 * 2]
    vpavgb         m3, m3, m4
    vmovdqu        [r0], m0
    vmovd          [r0 + 16], m1
    vmovdqu        [r0 + r1], m2
    vmovd          [r0 + r1 + 16], m3
    lea            r0, [r0 + r1 * 2]
    sub            r5d, 2
    jg             .loop
    ret

INIT_YMM avx2
cglobal pixel_avg2_w20_get_ref, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    sub            r4, r2
    lea            r6, [r4 + r3]
.loop:
    vmovdqu        m0, [r2]
    vmovdqu        m1, [r2 + r3]
    vpavgb         m0, m0, [r2 + r4]
    vpavgb         m1, m1, [r2 + r6]
    lea            r2, [r2 + r3 * 2]
    vmovdqu        [r0], m0
    vmovdqu        [r0 + r1], m1
    lea            r0, [r0 + r1 * 2]
    sub            r5d, 2
    jg             .loop
    RET
