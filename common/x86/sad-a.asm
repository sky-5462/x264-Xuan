;*****************************************************************************
;* sad-a.asm: x86 sad functions
;*****************************************************************************
;* Copyright (C) 2003-2019 x264 project
;*
;* Authors: Loren Merritt <lorenm@u.washington.edu>
;*          Fiona Glaser <fiona@x264.com>
;*          Laurent Aimar <fenrir@via.ecp.fr>
;*          Alex Izvorski <aizvorksi@gmail.com>
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

intra_sad_8x8_shuf_h:       times 8 db 7
                            times 8 db 5
                            times 8 db 6
                            times 8 db 4
intra_sad_8x8c_shuf_h:      times 8 db 0
                            times 8 db 2
                            times 8 db 1
                            times 8 db 3
intra_sad_8x16c_shuf_h:     db 0,0,2,2,8,8,10,10,1,1,3,3,9,9,11,11
intra_sad_8x16c_shuf_dc:    db 0,0,0,0,8,8,8,8,-1,-1,-1,-1,-1,-1,-1,-1
intra_sad_8x8c_shuf_dc:     times 4 db 0
                            times 4 db 8
intra_sad_4x4_shuf_h:       times 4 db 0
                            times 4 db 1

SECTION .text

;=============================================================================
; SAD
;=============================================================================
INIT_XMM avx2
cglobal pixel_sad_4x4, 0, 0
    vmovd          m0, [r0]
    vmovd          m1, [r2]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vpsadbw        m2, m0, m1
    vmovd          m0, [r0 + r1]
    vmovd          m1, [r2 + r3]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          m0, [r0 + r6]
    vmovd          m1, [r2 + r4]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          eax, m2
    ret

INIT_XMM avx2
cglobal pixel_sad_4x8, 0, 0
    vmovd          m0, [r0]
    vmovd          m1, [r2]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vpsadbw        m2, m0, m1
    vmovd          m0, [r0 + r1]
    vmovd          m1, [r2 + r3]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          m0, [r0 + r6]
    vmovd          m1, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3

    vmovd          m0, [r0]
    vmovd          m1, [r2]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          m0, [r0 + r1]
    vmovd          m1, [r2 + r3]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          m0, [r0 + r6]
    vmovd          m1, [r2 + r4]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          eax, m2
    ret

INIT_XMM avx2
cglobal pixel_sad_4x16, 0, 0
    vmovd          m0, [r0]
    vmovd          m1, [r2]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vpsadbw        m2, m0, m1
    vmovd          m0, [r0 + r1]
    vmovd          m1, [r2 + r3]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          m0, [r0 + r6]
    vmovd          m1, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3

    vmovd          m0, [r0]
    vmovd          m1, [r2]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          m0, [r0 + r1]
    vmovd          m1, [r2 + r3]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          m0, [r0 + r6]
    vmovd          m1, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3

    vmovd          m0, [r0]
    vmovd          m1, [r2]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          m0, [r0 + r1]
    vmovd          m1, [r2 + r3]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          m0, [r0 + r6]
    vmovd          m1, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3

    vmovd          m0, [r0]
    vmovd          m1, [r2]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          m0, [r0 + r1]
    vmovd          m1, [r2 + r3]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3
    vmovd          m0, [r0 + r6]
    vmovd          m1, [r2 + r4]
    vpsadbw        m3, m0, m1
    vpaddw         m2, m2, m3

    vmovd          eax, m2
    ret

INIT_XMM avx2
cglobal pixel_sad_8x4, 0, 0
    vmovq          m0, [r2]
    vpsadbw        m1, m0, [r0]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vmovq          m0, [r2 + r3]
    vpsadbw        m0, m0, [r0 + r1]
    vpaddw         m1, m1, m0
    vmovq          m0, [r2 + r3 * 2]
    vpsadbw        m0, m0, [r0 + r1 * 2]
    vpaddw         m1, m1, m0
    vmovq          m0, [r2 + r4]
    vpsadbw        m0, m0, [r0 + r6]
    vpaddw         m1, m1, m0
    vmovd          eax, m1
    ret

INIT_XMM avx2
cglobal pixel_sad_8x8, 0, 0
    vmovq          m0, [r2]
    vpsadbw        m1, m0, [r0]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vmovq          m0, [r2 + r3]
    vpsadbw        m0, m0, [r0 + r1]
    vpaddw         m1, m1, m0
    vmovq          m0, [r2 + r3 * 2]
    vpsadbw        m0, m0, [r0 + r1 * 2]
    vpaddw         m1, m1, m0
    vmovq          m0, [r2 + r4]
    vpsadbw        m0, m0, [r0 + r6]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpaddw         m1, m1, m0

    vmovq          m0, [r2]
    vpsadbw        m0, m0, [r0]
    vpaddw         m1, m1, m0
    vmovq          m0, [r2 + r3]
    vpsadbw        m0, m0, [r0 + r1]
    vpaddw         m1, m1, m0
    vmovq          m0, [r2 + r3 * 2]
    vpsadbw        m0, m0, [r0 + r1 * 2]
    vpaddw         m1, m1, m0
    vmovq          m0, [r2 + r4]
    vpsadbw        m0, m0, [r0 + r6]
    vpaddw         m1, m1, m0
    vmovd          eax, m1
    ret

INIT_XMM avx2
cglobal pixel_sad_8x16, 0, 0
    vmovq          m0, [r2]
    vpsadbw        m1, m0, [r0]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vmovq          m0, [r2 + r3]
    vpsadbw        m0, m0, [r0 + r1]
    vpaddw         m1, m1, m0
    vmovq          m0, [r2 + r3 * 2]
    vpsadbw        m0, m0, [r0 + r1 * 2]
    vpaddw         m1, m1, m0
    vmovq          m0, [r2 + r4]
    vpsadbw        m0, m0, [r0 + r6]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpaddw         m1, m1, m0

    vmovq          m0, [r2]
    vpsadbw        m0, m0, [r0]
    vpaddw         m1, m1, m0
    vmovq          m0, [r2 + r3]
    vpsadbw        m0, m0, [r0 + r1]
    vpaddw         m1, m1, m0
    vmovq          m0, [r2 + r3 * 2]
    vpsadbw        m0, m0, [r0 + r1 * 2]
    vpaddw         m1, m1, m0
    vmovq          m0, [r2 + r4]
    vpsadbw        m0, m0, [r0 + r6]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpaddw         m1, m1, m0

    vmovq          m0, [r2]
    vpsadbw        m0, m0, [r0]
    vpaddw         m1, m1, m0
    vmovq          m0, [r2 + r3]
    vpsadbw        m0, m0, [r0 + r1]
    vpaddw         m1, m1, m0
    vmovq          m0, [r2 + r3 * 2]
    vpsadbw        m0, m0, [r0 + r1 * 2]
    vpaddw         m1, m1, m0
    vmovq          m0, [r2 + r4]
    vpsadbw        m0, m0, [r0 + r6]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpaddw         m1, m1, m0

    vmovq          m0, [r2]
    vpsadbw        m0, m0, [r0]
    vpaddw         m1, m1, m0
    vmovq          m0, [r2 + r3]
    vpsadbw        m0, m0, [r0 + r1]
    vpaddw         m1, m1, m0
    vmovq          m0, [r2 + r3 * 2]
    vpsadbw        m0, m0, [r0 + r1 * 2]
    vpaddw         m1, m1, m0
    vmovq          m0, [r2 + r4]
    vpsadbw        m0, m0, [r0 + r6]
    vpaddw         m1, m1, m0
    vmovd          eax, m1
    ret


; the 128-bits part suffers from uop unlamination with VEX encoding, 
; but most of the time the 256-bits part is used, so 128-bits with 
; VEX is just OK, and maybe don't need to care about it in the future
INIT_YMM avx2
cglobal pixel_sad_16x8, 0, 0
    cmp            r1d, 16
    jne            .rollback

    lea            r6d, [r3 + r3 * 2]
    lea            r1, [r2 + r3 * 4]
    vmovdqu        xm0, [r2]
    vinserti128    m0, m0, [r2 + r3], 1
    vpsadbw        m0, [r0]
    vmovdqu        xm1, [r2 + r3 * 2]
    vinserti128    m1, m1, [r2 + r6], 1
    vpsadbw        m1, [r0 + 32]
    vmovdqu        xm2, [r1]
    vinserti128    m2, m2, [r1 + r3], 1
    vpsadbw        m2, [r0 + 64]
    vmovdqu        xm3, [r1 + r3 * 2]
    vinserti128    m3, m3, [r1 + r6], 1
    vpsadbw        m3, [r0 + 96]

    vpaddw         m0, m0, m1
    vpaddw         m2, m2, m3
    vpaddw         m0, m0, m2
    vextracti128   xm1, m0, 1
    vpaddw         xm0, xm0, xm1
    vpunpckhqdq    xm1, xm0, xm0
    vpaddw         xm0, xm0, xm1
    vmovd          eax, xm0
    RET

ALIGN 16
.rollback:
    vmovdqu        xm0, [r2]
    vpsadbw        xm1, xm0, [r0]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vmovdqu        xm0, [r2 + r3]
    vpsadbw        xm0, xm0, [r0 + r1]
    vpaddw         xm1, xm1, xm0
    vmovdqu        xm0, [r2 + r3 * 2]
    vpsadbw        xm0, xm0, [r0 + r1 * 2]
    vpaddw         xm1, xm1, xm0
    vmovdqu        xm0, [r2 + r4]
    vpsadbw        xm0, xm0, [r0 + r6]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpaddw         xm1, xm1, xm0

    vmovdqu        xm0, [r2]
    vpsadbw        xm0, xm0, [r0]
    vpaddw         xm1, xm1, xm0
    vmovdqu        xm0, [r2 + r3]
    vpsadbw        xm0, xm0, [r0 + r1]
    vpaddw         xm1, xm1, xm0
    vmovdqu        xm0, [r2 + r3 * 2]
    vpsadbw        xm0, xm0, [r0 + r1 * 2]
    vpaddw         xm1, xm1, xm0
    vmovdqu        xm0, [r2 + r4]
    vpsadbw        xm0, xm0, [r0 + r6]
    vpaddw         xm1, xm1, xm0

    vpunpckhqdq    xm0, xm1, xm1
    vpaddw         xm1, xm1, xm0
    vmovd          eax, xm1
    ret

INIT_YMM avx2
cglobal pixel_sad_16x16, 0, 0
    cmp            r1d, 16
    jne            .rollback

    lea            r6d, [r3 + r3 * 2]
    lea            r1, [r2 + r3 * 4]
    vmovdqu        xm0, [r2]
    vinserti128    m0, m0, [r2 + r3], 1
    vpsadbw        m0, [r0]
    vmovdqu        xm1, [r2 + r3 * 2]
    vinserti128    m1, m1, [r2 + r6], 1
    vpsadbw        m1, [r0 + 32]
    vmovdqu        xm2, [r1]
    vinserti128    m2, m2, [r1 + r3], 1
    vpsadbw        m2, [r0 + 64]
    vmovdqu        xm3, [r1 + r3 * 2]
    vinserti128    m3, m3, [r1 + r6], 1
    vpsadbw        m3, [r0 + 96]
    vpaddw         m0, m0, m1
    vpaddw         m2, m2, m3
    vpaddw         m4, m0, m2

    add            r0, 128
    lea            r2, [r2 + r3 * 8]
    lea            r1, [r1 + r3 * 8]
    vmovdqu        xm0, [r2]
    vinserti128    m0, m0, [r2 + r3], 1
    vpsadbw        m0, [r0]
    vmovdqu        xm1, [r2 + r3 * 2]
    vinserti128    m1, m1, [r2 + r6], 1
    vpsadbw        m1, [r0 + 32]
    vmovdqu        xm2, [r1]
    vinserti128    m2, m2, [r1 + r3], 1
    vpsadbw        m2, [r0 + 64]
    vmovdqu        xm3, [r1 + r3 * 2]
    vinserti128    m3, m3, [r1 + r6], 1
    vpsadbw        m3, [r0 + 96]
    vpaddw         m0, m0, m1
    vpaddw         m2, m2, m3
    vpaddw         m0, m0, m2

    vpaddw         m0, m0, m4
    vextracti128   xm1, m0, 1
    vpaddw         xm0, xm0, xm1
    vpunpckhqdq    xm1, xm0, xm0
    vpaddw         xm0, xm0, xm1
    vmovd          eax, xm0
    RET

ALIGN 16
.rollback:
    vmovdqu        xm0, [r2]
    vpsadbw        xm1, xm0, [r0]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vmovdqu        xm0, [r2 + r3]
    vpsadbw        xm0, xm0, [r0 + r1]
    vpaddw         xm1, xm1, xm0
    vmovdqu        xm0, [r2 + r3 * 2]
    vpsadbw        xm0, xm0, [r0 + r1 * 2]
    vpaddw         xm1, xm1, xm0
    vmovdqu        xm0, [r2 + r4]
    vpsadbw        xm0, xm0, [r0 + r6]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpaddw         xm1, xm1, xm0

    vmovdqu        xm0, [r2]
    vpsadbw        xm0, xm0, [r0]
    vpaddw         xm1, xm1, xm0
    vmovdqu        xm0, [r2 + r3]
    vpsadbw        xm0, xm0, [r0 + r1]
    vpaddw         xm1, xm1, xm0
    vmovdqu        xm0, [r2 + r3 * 2]
    vpsadbw        xm0, xm0, [r0 + r1 * 2]
    vpaddw         xm1, xm1, xm0
    vmovdqu        xm0, [r2 + r4]
    vpsadbw        xm0, xm0, [r0 + r6]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpaddw         xm1, xm1, xm0

    vmovdqu        xm0, [r2]
    vpsadbw        xm0, xm0, [r0]
    vpaddw         xm1, xm1, xm0
    vmovdqu        xm0, [r2 + r3]
    vpsadbw        xm0, xm0, [r0 + r1]
    vpaddw         xm1, xm1, xm0
    vmovdqu        xm0, [r2 + r3 * 2]
    vpsadbw        xm0, xm0, [r0 + r1 * 2]
    vpaddw         xm1, xm1, xm0
    vmovdqu        xm0, [r2 + r4]
    vpsadbw        xm0, xm0, [r0 + r6]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpaddw         xm1, xm1, xm0

    vmovdqu        xm0, [r2]
    vpsadbw        xm0, xm0, [r0]
    vpaddw         xm1, xm1, xm0
    vmovdqu        xm0, [r2 + r3]
    vpsadbw        xm0, xm0, [r0 + r1]
    vpaddw         xm1, xm1, xm0
    vmovdqu        xm0, [r2 + r3 * 2]
    vpsadbw        xm0, xm0, [r0 + r1 * 2]
    vpaddw         xm1, xm1, xm0
    vmovdqu        xm0, [r2 + r4]
    vpsadbw        xm0, xm0, [r0 + r6]
    vpaddw         xm1, xm1, xm0

    vpunpckhqdq    xm0, xm1, xm1
    vpaddw         xm1, xm1, xm0
    vmovd          eax, xm1
    ret


;=============================================================================
; SAD x3/x4
;=============================================================================
INIT_XMM avx2
cglobal pixel_sad_x3_4x4, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
%endif
    lea            r6d, [r4 + r4 * 2]

    vmovd          m0, [r0]
    vmovd          m1, [r1]
    vmovd          m2, [r2]
    vmovd          m3, [r3]
    vpsadbw        m1, m0, m1
    vpsadbw        m2, m0, m2
    vpsadbw        m3, m0, m3
    vmovd          m0, [r0 + 16]
    vmovd          m4, [r1 + r4]
    vmovd          m5, [r2 + r4]
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovd          m4, [r3 + r4]
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4
    vmovd          m0, [r0 + 32]
    vmovd          m4, [r1 + r4 * 2]
    vmovd          m5, [r2 + r4 * 2]
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovd          m4, [r3 + r4 * 2]
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4
    vmovd          m0, [r0 + 48]
    vmovd          m4, [r1 + r6]
    vmovd          m5, [r2 + r6]
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovd          m4, [r3 + r6]
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4

    vpunpckldq     m1, m1, m2
    vpunpcklqdq    m1, m1, m3
    vmovdqu        [r5], m1
    ret

INIT_XMM avx2
cglobal pixel_sad_x3_4x8, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
%endif
    lea            r6d, [r4 + r4 * 2]

    vmovd          m0, [r0]
    vmovd          m1, [r1]
    vmovd          m2, [r2]
    vmovd          m3, [r3]
    vpsadbw        m1, m0, m1
    vpsadbw        m2, m0, m2
    vpsadbw        m3, m0, m3
    vmovd          m0, [r0 + 16]
    vmovd          m4, [r1 + r4]
    vmovd          m5, [r2 + r4]
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovd          m4, [r3 + r4]
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4
    vmovd          m0, [r0 + 32]
    vmovd          m4, [r1 + r4 * 2]
    vmovd          m5, [r2 + r4 * 2]
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovd          m4, [r3 + r4 * 2]
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4
    vmovd          m0, [r0 + 48]
    vmovd          m4, [r1 + r6]
    vmovd          m5, [r2 + r6]
    lea            r1, [r1 + r4 * 4]
    lea            r2, [r2 + r4 * 4]
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovd          m4, [r3 + r6]
    lea            r3, [r3 + r4 * 4]
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4

    vmovd          m0, [r0 + 64]
    vmovd          m4, [r1]
    vmovd          m5, [r2]
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovd          m4, [r3]
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4
    vmovd          m0, [r0 + 80]
    vmovd          m4, [r1 + r4]
    vmovd          m5, [r2 + r4]
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovd          m4, [r3 + r4]
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4
    vmovd          m0, [r0 + 96]
    vmovd          m4, [r1 + r4 * 2]
    vmovd          m5, [r2 + r4 * 2]
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovd          m4, [r3 + r4 * 2]
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4
    vmovd          m0, [r0 + 112]
    vmovd          m4, [r1 + r6]
    vmovd          m5, [r2 + r6]
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovd          m4, [r3 + r6]
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4

    vpunpckldq     m1, m1, m2
    vpunpcklqdq    m1, m1, m3
    vmovdqu        [r5], m1
    ret

INIT_YMM avx2
cglobal pixel_sad_x3_8x4, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
%endif
    lea            r6d, [r4 + r4 * 2]

    vmovdqu        m0, [r0]
    vmovq          xm1, [r1]
    vinserti128    m1, m1, [r1 + r4], 1
    vmovq          xm2, [r2]
    vinserti128    m2, m2, [r2 + r4], 1
    vmovq          xm3, [r3]
    vinserti128    m3, m3, [r3 + r4], 1
    vpsadbw        m1, m0, m1
    vpsadbw        m2, m0, m2
    vpsadbw        m3, m0, m3
    vmovdqu        m0, [r0 + 32]
    vmovq          xm4, [r1 + r4 * 2]
    vinserti128    m4, m4, [r1 + r6], 1
    vmovq          xm5, [r2 + r4 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovq          xm4, [r3 + r4 * 2]
    vinserti128    m4, m4, [r3 + r6], 1
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4

    vpunpckldq     m1, m1, m2
    vpunpcklqdq    m1, m1, m3
    vextracti128   xm2, m1, 1
    vpaddd         xm1, xm1, xm2
    vmovdqu        [r5], xm1
    RET

INIT_YMM avx2
cglobal pixel_sad_x3_8x8, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
%endif
    lea            r6d, [r4 + r4 * 2]

    vmovdqu        m0, [r0]
    vmovq          xm1, [r1]
    vinserti128    m1, m1, [r1 + r4], 1
    vmovq          xm2, [r2]
    vinserti128    m2, m2, [r2 + r4], 1
    vmovq          xm3, [r3]
    vinserti128    m3, m3, [r3 + r4], 1
    vpsadbw        m1, m0, m1
    vpsadbw        m2, m0, m2
    vpsadbw        m3, m0, m3
    vmovdqu        m0, [r0 + 32]
    vmovq          xm4, [r1 + r4 * 2]
    vinserti128    m4, m4, [r1 + r6], 1
    vmovq          xm5, [r2 + r4 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    lea            r1, [r1 + r4 * 4]
    lea            r2, [r2 + r4 * 4]
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovq          xm4, [r3 + r4 * 2]
    vinserti128    m4, m4, [r3 + r6], 1
    lea            r3, [r3 + r4 * 4]
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4

    vmovdqu        m0, [r0 + 64]
    vmovq          xm4, [r1]
    vinserti128    m4, m4, [r1 + r4], 1
    vmovq          xm5, [r2]
    vinserti128    m5, m5, [r2 + r4], 1
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovq          xm4, [r3]
    vinserti128    m4, m4, [r3 + r4], 1
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4
    vmovdqu        m0, [r0 + 96]
    vmovq          xm4, [r1 + r4 * 2]
    vinserti128    m4, m4, [r1 + r6], 1
    vmovq          xm5, [r2 + r4 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovq          xm4, [r3 + r4 * 2]
    vinserti128    m4, m4, [r3 + r6], 1
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4

    vpunpckldq     m1, m1, m2
    vpunpcklqdq    m1, m1, m3
    vextracti128   xm2, m1, 1
    vpaddd         xm1, xm1, xm2
    vmovdqu        [r5], xm1
    RET

INIT_YMM avx2
cglobal pixel_sad_x3_8x16, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
%endif
    lea            r6d, [r4 + r4 * 2]

    vmovdqu        m0, [r0]
    vmovq          xm1, [r1]
    vinserti128    m1, m1, [r1 + r4], 1
    vmovq          xm2, [r2]
    vinserti128    m2, m2, [r2 + r4], 1
    vmovq          xm3, [r3]
    vinserti128    m3, m3, [r3 + r4], 1
    vpsadbw        m1, m0, m1
    vpsadbw        m2, m0, m2
    vpsadbw        m3, m0, m3
    vmovdqu        m0, [r0 + 32]
    vmovq          xm4, [r1 + r4 * 2]
    vinserti128    m4, m4, [r1 + r6], 1
    vmovq          xm5, [r2 + r4 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    lea            r1, [r1 + r4 * 4]
    lea            r2, [r2 + r4 * 4]
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovq          xm4, [r3 + r4 * 2]
    vinserti128    m4, m4, [r3 + r6], 1
    lea            r3, [r3 + r4 * 4]
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4

    vmovdqu        m0, [r0 + 64]
    vmovq          xm4, [r1]
    vinserti128    m4, m4, [r1 + r4], 1
    vmovq          xm5, [r2]
    vinserti128    m5, m5, [r2 + r4], 1
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovq          xm4, [r3]
    vinserti128    m4, m4, [r3 + r4], 1
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4
    vmovdqu        m0, [r0 + 96]
    vmovq          xm4, [r1 + r4 * 2]
    vinserti128    m4, m4, [r1 + r6], 1
    vmovq          xm5, [r2 + r4 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    lea            r1, [r1 + r4 * 4]
    lea            r2, [r2 + r4 * 4]
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovq          xm4, [r3 + r4 * 2]
    vinserti128    m4, m4, [r3 + r6], 1
    add            r0, 128
    lea            r3, [r3 + r4 * 4]
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4

    vmovdqu        m0, [r0]
    vmovq          xm4, [r1]
    vinserti128    m4, m4, [r1 + r4], 1
    vmovq          xm5, [r2]
    vinserti128    m5, m5, [r2 + r4], 1
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovq          xm4, [r3]
    vinserti128    m4, m4, [r3 + r4], 1
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4
    vmovdqu        m0, [r0 + 32]
    vmovq          xm4, [r1 + r4 * 2]
    vinserti128    m4, m4, [r1 + r6], 1
    vmovq          xm5, [r2 + r4 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    lea            r1, [r1 + r4 * 4]
    lea            r2, [r2 + r4 * 4]
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovq          xm4, [r3 + r4 * 2]
    vinserti128    m4, m4, [r3 + r6], 1
    lea            r3, [r3 + r4 * 4]
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4

    vmovdqu        m0, [r0 + 64]
    vmovq          xm4, [r1]
    vinserti128    m4, m4, [r1 + r4], 1
    vmovq          xm5, [r2]
    vinserti128    m5, m5, [r2 + r4], 1
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovq          xm4, [r3]
    vinserti128    m4, m4, [r3 + r4], 1
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4
    vmovdqu        m0, [r0 + 96]
    vmovq          xm4, [r1 + r4 * 2]
    vinserti128    m4, m4, [r1 + r6], 1
    vmovq          xm5, [r2 + r4 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovq          xm4, [r3 + r4 * 2]
    vinserti128    m4, m4, [r3 + r6], 1
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4

    vpunpckldq     m1, m1, m2
    vpunpcklqdq    m1, m1, m3
    vextracti128   xm2, m1, 1
    vpaddd         xm1, xm1, xm2
    vmovdqu        [r5], xm1
    RET

INIT_YMM avx2
cglobal pixel_sad_x3_16x8, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
%endif
    lea            r6d, [r4 + r4 * 2]

    vmovdqu        m0, [r0]
    vmovdqu        xm1, [r1]
    vinserti128    m1, m1, [r1 + r4], 1
    vmovdqu        xm2, [r2]
    vinserti128    m2, m2, [r2 + r4], 1
    vmovdqu        xm3, [r3]
    vinserti128    m3, m3, [r3 + r4], 1
    vpsadbw        m1, m0, m1
    vpsadbw        m2, m0, m2
    vpsadbw        m3, m0, m3
    vmovdqu        m0, [r0 + 32]
    vmovdqu        xm4, [r1 + r4 * 2]
    vinserti128    m4, m4, [r1 + r6], 1
    vmovdqu        xm5, [r2 + r4 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    lea            r1, [r1 + r4 * 4]
    lea            r2, [r2 + r4 * 4]
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovdqu        xm4, [r3 + r4 * 2]
    vinserti128    m4, m4, [r3 + r6], 1
    lea            r3, [r3 + r4 * 4]
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4

    vmovdqu        m0, [r0 + 64]
    vmovdqu        xm4, [r1]
    vinserti128    m4, m4, [r1 + r4], 1
    vmovdqu        xm5, [r2]
    vinserti128    m5, m5, [r2 + r4], 1
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovdqu        xm4, [r3]
    vinserti128    m4, m4, [r3 + r4], 1
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4
    vmovdqu        m0, [r0 + 96]
    vmovdqu        xm4, [r1 + r4 * 2]
    vinserti128    m4, m4, [r1 + r6], 1
    vmovdqu        xm5, [r2 + r4 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovdqu        xm4, [r3 + r4 * 2]
    vinserti128    m4, m4, [r3 + r6], 1
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4

    vpackusdw      m1, m1, m2
    vpackusdw      m3, m3, m3
    vphaddd        m0, m1, m3
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovdqu        [r5], xm0
    RET

INIT_YMM avx2
cglobal pixel_sad_x3_16x16, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
%endif
    lea            r6d, [r4 + r4 * 2]

    vmovdqu        m0, [r0]
    vmovdqu        xm1, [r1]
    vinserti128    m1, m1, [r1 + r4], 1
    vmovdqu        xm2, [r2]
    vinserti128    m2, m2, [r2 + r4], 1
    vmovdqu        xm3, [r3]
    vinserti128    m3, m3, [r3 + r4], 1
    vpsadbw        m1, m0, m1
    vpsadbw        m2, m0, m2
    vpsadbw        m3, m0, m3
    vmovdqu        m0, [r0 + 32]
    vmovdqu        xm4, [r1 + r4 * 2]
    vinserti128    m4, m4, [r1 + r6], 1
    vmovdqu        xm5, [r2 + r4 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    lea            r1, [r1 + r4 * 4]
    lea            r2, [r2 + r4 * 4]
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovdqu        xm4, [r3 + r4 * 2]
    vinserti128    m4, m4, [r3 + r6], 1
    lea            r3, [r3 + r4 * 4]
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4

    vmovdqu        m0, [r0 + 64]
    vmovdqu        xm4, [r1]
    vinserti128    m4, m4, [r1 + r4], 1
    vmovdqu        xm5, [r2]
    vinserti128    m5, m5, [r2 + r4], 1
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovdqu        xm4, [r3]
    vinserti128    m4, m4, [r3 + r4], 1
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4
    vmovdqu        m0, [r0 + 96]
    vmovdqu        xm4, [r1 + r4 * 2]
    vinserti128    m4, m4, [r1 + r6], 1
    vmovdqu        xm5, [r2 + r4 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    lea            r1, [r1 + r4 * 4]
    lea            r2, [r2 + r4 * 4]
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovdqu        xm4, [r3 + r4 * 2]
    vinserti128    m4, m4, [r3 + r6], 1
    add            r0, 128
    lea            r3, [r3 + r4 * 4]
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4

    vmovdqu        m0, [r0]
    vmovdqu        xm4, [r1]
    vinserti128    m4, m4, [r1 + r4], 1
    vmovdqu        xm5, [r2]
    vinserti128    m5, m5, [r2 + r4], 1
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovdqu        xm4, [r3]
    vinserti128    m4, m4, [r3 + r4], 1
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4
    vmovdqu        m0, [r0 + 32]
    vmovdqu        xm4, [r1 + r4 * 2]
    vinserti128    m4, m4, [r1 + r6], 1
    vmovdqu        xm5, [r2 + r4 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    lea            r1, [r1 + r4 * 4]
    lea            r2, [r2 + r4 * 4]
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovdqu        xm4, [r3 + r4 * 2]
    vinserti128    m4, m4, [r3 + r6], 1
    lea            r3, [r3 + r4 * 4]
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4

    vmovdqu        m0, [r0 + 64]
    vmovdqu        xm4, [r1]
    vinserti128    m4, m4, [r1 + r4], 1
    vmovdqu        xm5, [r2]
    vinserti128    m5, m5, [r2 + r4], 1
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovdqu        xm4, [r3]
    vinserti128    m4, m4, [r3 + r4], 1
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4
    vmovdqu        m0, [r0 + 96]
    vmovdqu        xm4, [r1 + r4 * 2]
    vinserti128    m4, m4, [r1 + r6], 1
    vmovdqu        xm5, [r2 + r4 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    vpsadbw        m4, m0, m4
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m4
    vpaddw         m2, m2, m5
    vmovdqu        xm4, [r3 + r4 * 2]
    vinserti128    m4, m4, [r3 + r6], 1
    vpsadbw        m4, m0, m4
    vpaddw         m3, m3, m4

    vpackusdw      m1, m1, m2
    vpackusdw      m3, m3, m3
    vphaddd        m0, m1, m3
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovdqu        [r5], xm0
    RET


INIT_XMM avx2
cglobal pixel_sad_x4_4x4, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    lea            r6d, [r5 + r5 * 2]

    vmovd          m0, [r0]
    vmovd          m1, [r1]
    vpsadbw        m1, m0, m1
    vmovd          m2, [r2]
    vpsadbw        m2, m0, m2
    vmovd          m3, [r3]
    vpsadbw        m3, m0, m3
    vmovd          m4, [r4]
    vpsadbw        m4, m0, m4
    vmovd          m0, [r0 + 16]
    vmovd          m5, [r1 + r5]
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovd          m5, [r2 + r5]
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovd          m5, [r3 + r5]
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovd          m5, [r4 + r5]
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5
    vmovd          m0, [r0 + 32]
    vmovd          m5, [r1 + r5 * 2]
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovd          m5, [r2 + r5 * 2]
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovd          m5, [r3 + r5 * 2]
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovd          m5, [r4 + r5 * 2]
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5
    vmovd          m0, [r0 + 48]
    vmovd          m5, [r1 + r6]
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovd          m5, [r2 + r6]
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovd          m5, [r3 + r6]
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovd          m5, [r4 + r6]
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5

%if WIN64
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vpunpckldq     m1, m1, m2
    vpunpckldq     m3, m3, m4
    vpunpcklqdq    m1, m1, m3
    vmovdqu        [r6], m1
    ret

INIT_XMM avx2
cglobal pixel_sad_x4_4x8, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    lea            r6d, [r5 + r5 * 2]

    vmovd          m0, [r0]
    vmovd          m1, [r1]
    vpsadbw        m1, m0, m1
    vmovd          m2, [r2]
    vpsadbw        m2, m0, m2
    vmovd          m3, [r3]
    vpsadbw        m3, m0, m3
    vmovd          m4, [r4]
    vpsadbw        m4, m0, m4
    vmovd          m0, [r0 + 16]
    vmovd          m5, [r1 + r5]
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovd          m5, [r2 + r5]
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovd          m5, [r3 + r5]
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovd          m5, [r4 + r5]
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5
    vmovd          m0, [r0 + 32]
    vmovd          m5, [r1 + r5 * 2]
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovd          m5, [r2 + r5 * 2]
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovd          m5, [r3 + r5 * 2]
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovd          m5, [r4 + r5 * 2]
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5
    vmovd          m0, [r0 + 48]
    vmovd          m5, [r1 + r6]
    lea            r1, [r1 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovd          m5, [r2 + r6]
    lea            r2, [r2 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovd          m5, [r3 + r6]
    lea            r3, [r3 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovd          m5, [r4 + r6]
    lea            r4, [r4 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5

    vmovd          m0, [r0 + 64]
    vmovd          m5, [r1]
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovd          m5, [r2]
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovd          m5, [r3]
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovd          m5, [r4]
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5
    vmovd          m0, [r0 + 80]
    vmovd          m5, [r1 + r5]
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovd          m5, [r2 + r5]
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovd          m5, [r3 + r5]
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovd          m5, [r4 + r5]
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5
    vmovd          m0, [r0 + 96]
    vmovd          m5, [r1 + r5 * 2]
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovd          m5, [r2 + r5 * 2]
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovd          m5, [r3 + r5 * 2]
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovd          m5, [r4 + r5 * 2]
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5
    vmovd          m0, [r0 + 112]
    vmovd          m5, [r1 + r6]
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovd          m5, [r2 + r6]
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovd          m5, [r3 + r6]
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovd          m5, [r4 + r6]
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5

%if WIN64
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vpunpckldq     m1, m1, m2
    vpunpckldq     m3, m3, m4
    vpunpcklqdq    m1, m1, m3
    vmovdqu        [r6], m1
    ret

INIT_YMM avx2
cglobal pixel_sad_x4_8x4, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    lea            r6d, [r5 + r5 * 2]

    vmovdqu        m0, [r0]
    vmovq          xm1, [r1]
    vinserti128    m1, m1, [r1 + r5], 1
    vmovq          xm2, [r2]
    vinserti128    m2, m2, [r2 + r5], 1
    vmovq          xm3, [r3]
    vinserti128    m3, m3, [r3 + r5], 1
    vmovq          xm4, [r4]
    vinserti128    m4, m4, [r4 + r5], 1
    vpsadbw        m1, m0, m1
    vpsadbw        m2, m0, m2
    vpsadbw        m3, m0, m3
    vpsadbw        m4, m0, m4
    vmovdqu        m0, [r0 + 32]
    vmovq          xm5, [r1 + r5 * 2]
    vinserti128    m5, m5, [r1 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovq          xm5, [r2 + r5 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovq          xm5, [r3 + r5 * 2]
    vinserti128    m5, m5, [r3 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovq          xm5, [r4 + r5 * 2]
    vinserti128    m5, m5, [r4 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5

%if WIN64
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vpunpckldq     m1, m1, m2
    vpunpckldq     m3, m3, m4
    vpunpcklqdq    m1, m1, m3
    vextracti128   xm2, m1, 1
    vpaddd         xm1, xm1, xm2
    vmovdqu        [r6], xm1
    RET

INIT_YMM avx2
cglobal pixel_sad_x4_8x8, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    lea            r6d, [r5 + r5 * 2]

    vmovdqu        m0, [r0]
    vmovq          xm1, [r1]
    vinserti128    m1, m1, [r1 + r5], 1
    vmovq          xm2, [r2]
    vinserti128    m2, m2, [r2 + r5], 1
    vmovq          xm3, [r3]
    vinserti128    m3, m3, [r3 + r5], 1
    vmovq          xm4, [r4]
    vinserti128    m4, m4, [r4 + r5], 1
    vpsadbw        m1, m0, m1
    vpsadbw        m2, m0, m2
    vpsadbw        m3, m0, m3
    vpsadbw        m4, m0, m4
    vmovdqu        m0, [r0 + 32]
    vmovq          xm5, [r1 + r5 * 2]
    vinserti128    m5, m5, [r1 + r6], 1
    lea            r1, [r1 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovq          xm5, [r2 + r5 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    lea            r2, [r2 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovq          xm5, [r3 + r5 * 2]
    vinserti128    m5, m5, [r3 + r6], 1
    lea            r3, [r3 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovq          xm5, [r4 + r5 * 2]
    vinserti128    m5, m5, [r4 + r6], 1
    lea            r4, [r4 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5

    vmovdqu        m0, [r0 + 64]
    vmovq          xm5, [r1]
    vinserti128    m5, m5, [r1 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovq          xm5, [r2]
    vinserti128    m5, m5, [r2 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovq          xm5, [r3]
    vinserti128    m5, m5, [r3 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovq          xm5, [r4]
    vinserti128    m5, m5, [r4 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5
    vmovdqu        m0, [r0 + 96]
    vmovq          xm5, [r1 + r5 * 2]
    vinserti128    m5, m5, [r1 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovq          xm5, [r2 + r5 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovq          xm5, [r3 + r5 * 2]
    vinserti128    m5, m5, [r3 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovq          xm5, [r4 + r5 * 2]
    vinserti128    m5, m5, [r4 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5

%if WIN64
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vpunpckldq     m1, m1, m2
    vpunpckldq     m3, m3, m4
    vpunpcklqdq    m1, m1, m3
    vextracti128   xm2, m1, 1
    vpaddd         xm1, xm1, xm2
    vmovdqu        [r6], xm1
    RET

INIT_YMM avx2
cglobal pixel_sad_x4_8x16, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    lea            r6d, [r5 + r5 * 2]

    vmovdqu        m0, [r0]
    vmovq          xm1, [r1]
    vinserti128    m1, m1, [r1 + r5], 1
    vmovq          xm2, [r2]
    vinserti128    m2, m2, [r2 + r5], 1
    vmovq          xm3, [r3]
    vinserti128    m3, m3, [r3 + r5], 1
    vmovq          xm4, [r4]
    vinserti128    m4, m4, [r4 + r5], 1
    vpsadbw        m1, m0, m1
    vpsadbw        m2, m0, m2
    vpsadbw        m3, m0, m3
    vpsadbw        m4, m0, m4
    vmovdqu        m0, [r0 + 32]
    vmovq          xm5, [r1 + r5 * 2]
    vinserti128    m5, m5, [r1 + r6], 1
    lea            r1, [r1 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovq          xm5, [r2 + r5 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    lea            r2, [r2 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovq          xm5, [r3 + r5 * 2]
    vinserti128    m5, m5, [r3 + r6], 1
    lea            r3, [r3 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovq          xm5, [r4 + r5 * 2]
    vinserti128    m5, m5, [r4 + r6], 1
    lea            r4, [r4 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5

    vmovdqu        m0, [r0 + 64]
    vmovq          xm5, [r1]
    vinserti128    m5, m5, [r1 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovq          xm5, [r2]
    vinserti128    m5, m5, [r2 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovq          xm5, [r3]
    vinserti128    m5, m5, [r3 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovq          xm5, [r4]
    vinserti128    m5, m5, [r4 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5
    vmovdqu        m0, [r0 + 96]
    add            r0, 128
    vmovq          xm5, [r1 + r5 * 2]
    vinserti128    m5, m5, [r1 + r6], 1
    lea            r1, [r1 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovq          xm5, [r2 + r5 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    lea            r2, [r2 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovq          xm5, [r3 + r5 * 2]
    vinserti128    m5, m5, [r3 + r6], 1
    lea            r3, [r3 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovq          xm5, [r4 + r5 * 2]
    vinserti128    m5, m5, [r4 + r6], 1
    lea            r4, [r4 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5

    vmovdqu        m0, [r0]
    vmovq          xm5, [r1]
    vinserti128    m5, m5, [r1 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovq          xm5, [r2]
    vinserti128    m5, m5, [r2 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovq          xm5, [r3]
    vinserti128    m5, m5, [r3 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovq          xm5, [r4]
    vinserti128    m5, m5, [r4 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5
    vmovdqu        m0, [r0 + 32]
    vmovq          xm5, [r1 + r5 * 2]
    vinserti128    m5, m5, [r1 + r6], 1
    lea            r1, [r1 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovq          xm5, [r2 + r5 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    lea            r2, [r2 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovq          xm5, [r3 + r5 * 2]
    vinserti128    m5, m5, [r3 + r6], 1
    lea            r3, [r3 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovq          xm5, [r4 + r5 * 2]
    vinserti128    m5, m5, [r4 + r6], 1
    lea            r4, [r4 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5

    vmovdqu        m0, [r0 + 64]
    vmovq          xm5, [r1]
    vinserti128    m5, m5, [r1 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovq          xm5, [r2]
    vinserti128    m5, m5, [r2 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovq          xm5, [r3]
    vinserti128    m5, m5, [r3 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovq          xm5, [r4]
    vinserti128    m5, m5, [r4 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5
    vmovdqu        m0, [r0 + 96]
    vmovq          xm5, [r1 + r5 * 2]
    vinserti128    m5, m5, [r1 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovq          xm5, [r2 + r5 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovq          xm5, [r3 + r5 * 2]
    vinserti128    m5, m5, [r3 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovq          xm5, [r4 + r5 * 2]
    vinserti128    m5, m5, [r4 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5

%if WIN64
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vpunpckldq     m1, m1, m2
    vpunpckldq     m3, m3, m4
    vpunpcklqdq    m1, m1, m3
    vextracti128   xm2, m1, 1
    vpaddd         xm1, xm1, xm2
    vmovdqu        [r6], xm1
    RET


INIT_YMM avx2
cglobal pixel_sad_x4_16x8, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    lea            r6d, [r5 + r5 * 2]

    vmovdqu        m0, [r0]
    vmovdqu        xm1, [r1]
    vinserti128    m1, m1, [r1 + r5], 1
    vmovdqu        xm2, [r2]
    vinserti128    m2, m2, [r2 + r5], 1
    vmovdqu        xm3, [r3]
    vinserti128    m3, m3, [r3 + r5], 1
    vmovdqu        xm4, [r4]
    vinserti128    m4, m4, [r4 + r5], 1
    vpsadbw        m1, m0, m1
    vpsadbw        m2, m0, m2
    vpsadbw        m3, m0, m3
    vpsadbw        m4, m0, m4
    vmovdqu        m0, [r0 + 32]
    vmovdqu        xm5, [r1 + r5 * 2]
    vinserti128    m5, m5, [r1 + r6], 1
    lea            r1, [r1 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovdqu        xm5, [r2 + r5 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    lea            r2, [r2 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovdqu        xm5, [r3 + r5 * 2]
    vinserti128    m5, m5, [r3 + r6], 1
    lea            r3, [r3 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovdqu        xm5, [r4 + r5 * 2]
    vinserti128    m5, m5, [r4 + r6], 1
    lea            r4, [r4 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5

    vmovdqu        m0, [r0 + 64]
    vmovdqu        xm5, [r1]
    vinserti128    m5, m5, [r1 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovdqu        xm5, [r2]
    vinserti128    m5, m5, [r2 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovdqu        xm5, [r3]
    vinserti128    m5, m5, [r3 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovdqu        xm5, [r4]
    vinserti128    m5, m5, [r4 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5
    vmovdqu        m0, [r0 + 96]
    vmovdqu        xm5, [r1 + r5 * 2]
    vinserti128    m5, m5, [r1 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovdqu        xm5, [r2 + r5 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovdqu        xm5, [r3 + r5 * 2]
    vinserti128    m5, m5, [r3 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovdqu        xm5, [r4 + r5 * 2]
    vinserti128    m5, m5, [r4 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5

%if WIN64
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vpackusdw      m1, m1, m2
    vpackusdw      m3, m3, m4
    vphaddd        m0, m1, m3
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovdqu        [r6], xm0
    RET

INIT_YMM avx2
cglobal pixel_sad_x4_16x16, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    lea            r6d, [r5 + r5 * 2]

    vmovdqu        m0, [r0]
    vmovdqu        xm1, [r1]
    vinserti128    m1, m1, [r1 + r5], 1
    vmovdqu        xm2, [r2]
    vinserti128    m2, m2, [r2 + r5], 1
    vmovdqu        xm3, [r3]
    vinserti128    m3, m3, [r3 + r5], 1
    vmovdqu        xm4, [r4]
    vinserti128    m4, m4, [r4 + r5], 1
    vpsadbw        m1, m0, m1
    vpsadbw        m2, m0, m2
    vpsadbw        m3, m0, m3
    vpsadbw        m4, m0, m4
    vmovdqu        m0, [r0 + 32]
    vmovdqu        xm5, [r1 + r5 * 2]
    vinserti128    m5, m5, [r1 + r6], 1
    lea            r1, [r1 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovdqu        xm5, [r2 + r5 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    lea            r2, [r2 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovdqu        xm5, [r3 + r5 * 2]
    vinserti128    m5, m5, [r3 + r6], 1
    lea            r3, [r3 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovdqu        xm5, [r4 + r5 * 2]
    vinserti128    m5, m5, [r4 + r6], 1
    lea            r4, [r4 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5

    vmovdqu        m0, [r0 + 64]
    vmovdqu        xm5, [r1]
    vinserti128    m5, m5, [r1 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovdqu        xm5, [r2]
    vinserti128    m5, m5, [r2 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovdqu        xm5, [r3]
    vinserti128    m5, m5, [r3 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovdqu        xm5, [r4]
    vinserti128    m5, m5, [r4 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5
    vmovdqu        m0, [r0 + 96]
    add            r0, 128
    vmovdqu        xm5, [r1 + r5 * 2]
    vinserti128    m5, m5, [r1 + r6], 1
    lea            r1, [r1 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovdqu        xm5, [r2 + r5 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    lea            r2, [r2 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovdqu        xm5, [r3 + r5 * 2]
    vinserti128    m5, m5, [r3 + r6], 1
    lea            r3, [r3 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovdqu        xm5, [r4 + r5 * 2]
    vinserti128    m5, m5, [r4 + r6], 1
    lea            r4, [r4 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5

    vmovdqu        m0, [r0]
    vmovdqu        xm5, [r1]
    vinserti128    m5, m5, [r1 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovdqu        xm5, [r2]
    vinserti128    m5, m5, [r2 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovdqu        xm5, [r3]
    vinserti128    m5, m5, [r3 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovdqu        xm5, [r4]
    vinserti128    m5, m5, [r4 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5
    vmovdqu        m0, [r0 + 32]
    vmovdqu        xm5, [r1 + r5 * 2]
    vinserti128    m5, m5, [r1 + r6], 1
    lea            r1, [r1 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovdqu        xm5, [r2 + r5 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    lea            r2, [r2 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovdqu        xm5, [r3 + r5 * 2]
    vinserti128    m5, m5, [r3 + r6], 1
    lea            r3, [r3 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovdqu        xm5, [r4 + r5 * 2]
    vinserti128    m5, m5, [r4 + r6], 1
    lea            r4, [r4 + r5 * 4]
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5

    vmovdqu        m0, [r0 + 64]
    vmovdqu        xm5, [r1]
    vinserti128    m5, m5, [r1 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovdqu        xm5, [r2]
    vinserti128    m5, m5, [r2 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovdqu        xm5, [r3]
    vinserti128    m5, m5, [r3 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovdqu        xm5, [r4]
    vinserti128    m5, m5, [r4 + r5], 1
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5
    vmovdqu        m0, [r0 + 96]
    vmovdqu        xm5, [r1 + r5 * 2]
    vinserti128    m5, m5, [r1 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m1, m1, m5
    vmovdqu        xm5, [r2 + r5 * 2]
    vinserti128    m5, m5, [r2 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m2, m2, m5
    vmovdqu        xm5, [r3 + r5 * 2]
    vinserti128    m5, m5, [r3 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m3, m3, m5
    vmovdqu        xm5, [r4 + r5 * 2]
    vinserti128    m5, m5, [r4 + r6], 1
    vpsadbw        m5, m0, m5
    vpaddw         m4, m4, m5

%if WIN64
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vpackusdw      m1, m1, m2
    vpackusdw      m3, m3, m4
    vphaddd        m0, m1, m3
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovdqu        [r6], xm0
    RET


;=============================================================================
; INTRA_SAD
;=============================================================================
INIT_YMM avx2
cglobal intra_sad_x3_4x4, 0, 0
    vpbroadcastq   m5, [intra_sad_4x4_shuf_h]
    vpbroadcastd   m0, [r1 - 32]                 ; v
    vmovd          xm1, [r1 - 1]
    vmovd          xm2, [r1 + 31]
    vpinsrb        xm1, xm1, [r1 + 63], 1
    vpinsrb        xm2, xm2, [r1 + 95], 1
    vpunpcklbw     xm3, xm1, xm2
    vinserti128    m1, m1, xm2, 1
    vpunpckldq     xm2, xm3, xm0
    vpxor          xm4, xm4, xm4
    vpsadbw        xm2, xm2, xm4
    vpsrlw         xm2, xm2, 2
    vpavgw         xm2, xm2, xm4
    vpbroadcastb   m2, xm2                       ; dc
    vpshufb        m1, m1, m5                    ; h

    vmovdqu        m3, [r0]
    vpunpckldq     m3, m3, [r0 + 32]
    vpsadbw        m0, m0, m3
    vpsadbw        m1, m1, m3
    vpsadbw        m2, m2, m3
    vpsllq         m1, m1, 32
    vpaddw         m0, m0, m1
    vpunpcklqdq    m0, m0, m2
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovdqu        [r2], xm0
    RET

INIT_YMM avx2
cglobal intra_sad_x3_8x8, 0, 0
    vmovdqu        m5, [intra_sad_8x8_shuf_h]
    vpbroadcastq   m0, [r1 + 16]                 ; V
    vpbroadcastq   m1, [r1 + 7]                  ; H
    vpxor          xm4, xm4, xm4
    vpsadbw        xm2, xm0, xm4
    vpsadbw        xm3, xm1, xm4
    vpaddw         xm2, xm2, xm3
    vpsrlw         xm2, xm2, 3
    vpavgw         xm2, xm2, xm4
    vpbroadcastb   m2, xm2                       ; DC
    vpshufb        m3, m1, m5                    ; H 0 2 1 3
    vpsllq         m1, m1, 32
    vpshufb        m1, m1, m5                    ; H 4 6 5 7

    vmovdqu        m4, [r0]
    vpunpcklqdq    m4, [r0 + 32]
    vmovdqu        m5, [r0 + 64]
    vpunpcklqdq    m5, [r0 + 96]
    vpsadbw        m3, m3, m4
    vpsadbw        m1, m1, m5
    vpaddw         m1, m1, m3                    ; H
    vpsadbw        m3, m0, m4
    vpsadbw        m0, m0, m5
    vpaddw         m0, m0, m3                    ; V
    vpsadbw        m3, m2, m4
    vpsadbw        m2, m2, m5
    vpaddw         m2, m2, m3                    ; DC

    vpsllq         m1, m1, 16
    vpsllq         m2, m2, 32
    vpaddw         m2, m2, m1
    vpaddw         m2, m2, m0                    ; V H DC
    vextracti128   xm0, m2, 1
    vpaddw         xm0, xm0, xm2
    vpunpckhqdq    xm1, xm0, xm0
    vpaddw         xm0, xm0, xm1
    vpmovzxwd      xm0, xm0
    vmovdqu        [r2], xm0
    RET

INIT_YMM avx2
cglobal intra_sad_x3_8x8c, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
%endif
    vpbroadcastq   m5, [intra_sad_8x8c_shuf_dc]
    vpbroadcastq   m0, [r1 - 32]                  ; V
    vmovd          xm1, [r1 + 92]
    vpinsrb        xm1, xm1, [r1 - 1], 0
    vpinsrb        xm1, xm1, [r1 + 31], 1
    vpinsrb        xm1, xm1, [r1 + 63], 2
    add            r1, 127
    vpinsrb        xm1, xm1, [r1], 4
    vpinsrb        xm1, xm1, [r1 + 32], 5
    vpinsrb        xm1, xm1, [r1 + 64], 6
    vpinsrb        xm1, xm1, [r1 + 96], 7
    vpunpcklqdq    xm2, xm0, xm1                  ; V0 V1 H0 H1
    vinserti128    m1, m1, xm1, 1
    vpshufd        xm3, xm2, 01110100b            ; V0 V1 H1 V1
    vpshufd        xm2, xm2, 11110110b            ; H0 V1 H1 H1
    vpmovzxbw      m3, xm3
    vpmovzxbw      m2, xm2
    vpxor          m4, m4, m4
    vpsadbw        m3, m3, m4
    vpsadbw        m2, m2, m4
    vpaddw         m2, m2, m3
    vpsrlw         m2, m2, 2
    vpavgw         m2, m2, m4                    ; DC0 DC1 DC2 DC3
    vpshufb        m2, m2, m5                    ; DC 0 1 0 1 2 3 2 3
    vmovdqu        m5, [intra_sad_8x8c_shuf_h]
    vinserti128    m3, m2, xm2, 1                ; DC 0 1 0 1 0 1 0 1
    vperm2i128     m2, m2, m2, 00010001b         ; DC 2 3 2 3 2 3 2 3
    vpshufb        m4, m1, m5                    ; H0
    vpsrlq         m1, m1, 32
    vpshufb        m1, m1, m5                    ; H1

    vmovdqu        m5, [r0]
    vpunpcklqdq    m5, [r0 + 32]
    vpsadbw        m3, m5, m3
    vpsadbw        m4, m5, m4
    vpsadbw        m6, m5, m0
    vmovdqu        m5, [r0 + 64]
    vpunpcklqdq    m5, [r0 + 96]
    vpsadbw        m2, m5, m2
    vpaddw         m2, m2, m3                    ; DC
    vpsadbw        m1, m5, m1
    vpaddw         m1, m1, m4                    ; H
    vpsadbw        m0, m5, m0
    vpaddw         m0, m0, m6                    ; V

%if WIN64
    vmovdqu        xm6, [rsp + 8]
%endif
    vpsllq         m1, m1, 16
    vpsllq         m0, m0, 32
    vpaddw         m2, m2, m1
    vpaddw         m2, m2, m0                    ; DC H V
    vextracti128   xm0, m2, 1
    vpaddw         xm0, xm0, xm2
    vpunpckhqdq    xm1, xm0, xm0
    vpaddw         xm0, xm0, xm1
    vpmovzxwd      xm0, xm0
    vmovdqu        [r2], xm0
    RET

INIT_YMM avx2
cglobal intra_sad_x3_8x16c, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 40
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
%endif
    vpbroadcastq   m4, [r1 - 32]                 ; V
    vmovdqu        xm3, [intra_sad_8x16c_shuf_h]
    add            r1, 127
    vpxor          m7, m7, m7
    vpunpckldq     xm6, xm4, xm7                 ; V0 _ V1 _
    vmovd          xm0, [r1 - 35]
    vmovd          xm1, [r1 + 93]
    vpinsrb        xm0, xm0, [r1 - 128], 0
    vpinsrb        xm1, xm1, [r1], 0
    vpinsrb        xm0, xm0, [r1 - 96], 1
    vpinsrb        xm1, xm1, [r1 + 32], 1
    vpinsrb        xm0, xm0, [r1 - 64], 2
    vpinsrb        xm1, xm1, [r1 + 64], 2
    vpunpcklqdq    xm0, xm0, xm1                 ; H0 _ H1 _
    vinserti128    m5, m6, xm0, 1                ; V0 V1 H0 H1
    vpshufb        xm0, xm0, xm3                 ; H00224466 H11335577
    add            r1, 256
    vmovd          xm1, [r1 - 35]
    vmovd          xm2, [r1 + 93]
    vpinsrb        xm1, [r1 - 128], 0
    vpinsrb        xm2, [r1], 0
    vpinsrb        xm1, [r1 - 96], 1
    vpinsrb        xm2, [r1 + 32], 1
    vpinsrb        xm1, [r1 - 64], 2
    vpinsrb        xm2, [r1 + 64], 2
    vpunpcklqdq    xm1, xm1, xm2                 ; H2 _ H3 _
    vinserti128    m6, m6, xm1, 1                ; V0 V1 H2 H3
    vpshufb        xm1, xm1, xm3                 ; H88101012121414 H99111113131515
    vpsadbw        m5, m5, m7                    ; s0 s1 s2 s3
    vpsadbw        m6, m6, m7                    ; s0 s1 s4 s5
    vpermq         m2, m5, q3312                 ; s2 s1 s3 s3
    vpermq         m3, m5, q1310                 ; s0 s1 s3 s1
    vpaddw         m2, m2, m3
    vpermq         m3, m6, q1312                 ; s4 s1 s5 s1
    vpermq         m5, m6, q3322                 ; s4 s4 s5 s5
    vpaddw         m3, m3, m5
    vbroadcasti128 m6, [intra_sad_8x16c_shuf_dc]
    vpsrlw         m2, m2, 2
    vpsrlw         m3, m3, 2
    vpavgw         m2, m2, m7                    ; s0+s2 s1 s3 s1+s3
    vpavgw         m3, m3, m7                    ; s4 s1+s4 s5 s1+s5
    vpshufb        m2, m2, m6                    ; DC0 _ DC1 _
    vpshufb        m3, m3, m6                    ; DC2 _ DC3 _
    vpblendd       m2, m2, m4, 11001100b         ; DC0 V DC1 V
    vpblendd       m3, m3, m4, 11001100b         ; DC2 V DC3 V
    vinserti128    m4, m2, xm2, 1                ; DC0 V DC0 V
    vinserti128    m6, m3, xm3, 1                ; DC2 V DC2 V
    vperm2i128     m5, m2, m2, q0101             ; DC1 V DC1 V
    vperm2i128     m7, m3, m3, q0101             ; DC3 V DC3 V
    vpermq         m0, m0, q3120                 ; H00224466 _ H11335577 _
    vpermq         m1, m1, q3120                 ; H88101012121414 _ H99111113131515 _
    vmovddup       m2, [r0]
    vpshuflw       m3, m0, q0000
    vpsadbw        m8, m4, m2
    vpsadbw        m9, m3, m2
    vmovddup       m2, [r0 + 32]
    vpshuflw       m3, m0, q1111
    vpsadbw        m4, m4, m2
    vpaddw         m8, m8, m4
    vpsadbw        m4, m3, m2
    vpaddw         m9, m9, m4
    vmovddup       m2, [r0 + 64]
    vpshuflw       m3, m0, q2222
    vpsadbw        m4, m5, m2
    vpaddw         m8, m8, m4
    vpsadbw        m4, m3, m2
    vpaddw         m9, m9, m4
    vmovddup       m2, [r0 + 96]
    vpshuflw       m3, m0, q3333
    vpsadbw        m4, m5, m2
    vpaddw         m8, m8, m4
    vpsadbw        m4, m3, m2
    vpaddw         m9, m9, m4
    add            r0, 128
    vmovddup       m2, [r0]
    vpshuflw       m3, m1, q0000
    vpsadbw        m4, m6, m2
    vpaddw         m8, m8, m4
    vpsadbw        m4, m3, m2
    vpaddw         m9, m9, m4
    vmovddup       m2, [r0 + 32]
    vpshuflw       m3, m1, q1111
    vpsadbw        m4, m6, m2
    vpaddw         m8, m8, m4
    vpsadbw        m4, m3, m2
    vpaddw         m9, m9, m4
    vmovddup       m2, [r0 + 64]
    vpshuflw       m3, m1, q2222
    vpsadbw        m4, m7, m2
    vpaddw         m8, m8, m4
    vpsadbw        m4, m3, m2
    vpaddw         m9, m9, m4
    vmovddup       m2, [r0 + 96]
    vpshuflw       m3, m1, q3333
    vpsadbw        m4, m7, m2
    vpaddw         m8, m8, m4
    vpsadbw        m4, m3, m2
    vpaddw         m9, m9, m4
    vextracti128   xm0, m8, 1
    vextracti128   xm1, m9, 1
    vpaddw         xm0, xm8, xm0                 ; DC V
    vpaddw         xm1, xm9, xm1                 ; H
    vpsllq         xm1, xm1, 32
    vpblendd       xm1, xm1, xm0, 1101b
    vmovdqu        [r2], xm1
%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    add            rsp, 40
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    RET

INIT_YMM avx2
cglobal intra_sad_x3_16x16, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 40
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
%endif
    vbroadcasti128 m4, [r1 - 32]                 ; V
    lea            r6, [r1 + 383]
    add            r1, 127
    vmovd          xm0, [r1 + 61]
    vmovd          xm1, [r1 + 93]
    vpinsrb        xm0, xm0, [r1 - 128], 0
    vpinsrb        xm1, xm1, [r1 - 96], 0
    vpinsrb        xm0, xm0, [r1 - 64], 1
    vpinsrb        xm1, xm1, [r1 - 32], 1
    vpinsrb        xm0, xm0, [r1], 2
    vpinsrb        xm1, xm1, [r1 + 32], 2
    vpinsrb        xm0, xm0, [r6 - 128], 4
    vpinsrb        xm1, xm1, [r6 - 96], 4
    vpinsrb        xm0, xm0, [r6 - 64], 5
    vpinsrb        xm1, xm1, [r6 - 32], 5
    vpinsrb        xm0, xm0, [r6], 6
    vpinsrb        xm1, xm1, [r6 + 32], 6
    vpinsrb        xm0, xm0, [r6 + 64], 7
    vpinsrb        xm1, xm1, [r6 + 96], 7
    vpunpcklbw     xm3, xm0, xm1
    vinserti128    m0, m0, xm1, 1
    vpunpcklbw     m0, m0, m0
    vpunpckhwd     m1, m0, m0                    ; H 8 10 12 14 9 11 13 15
    vpunpcklwd     m0, m0, m0                    ; H 0 2 4 6 1 3 5 7
    vpxor          xm5, xm5, xm5
    vpsadbw        xm2, xm4, xm5
    vpsadbw        xm3, xm3, xm5
    vpaddw         xm2, xm2, xm3
    vpunpckhqdq    xm3, xm2, xm2
    vpaddw         xm2, xm2, xm3
    vpsrlw         xm2, xm2, 4
    vpavgw         xm2, xm2, xm5
    vpbroadcastb   m2, xm2                       ; DC

    vmovdqu        m5, [r0]
    vpshufd        m3, m0, q0000
    vpsadbw        m6, m4, m5                    ; V
    vpsadbw        m7, m3, m5                    ; H
    vpsadbw        m8, m2, m5                    ; DC
    vmovdqu        m5, [r0 + 32]
    vpshufd        m3, m0, q1111
    vpsadbw        m9, m4, m5
    vpaddw         m6, m6, m9
    vpsadbw        m9, m3, m5
    vpaddw         m7, m7, m9
    vpsadbw        m9, m2, m5
    vpaddw         m8, m8, m9
    vmovdqu        m5, [r0 + 64]
    vpshufd        m3, m0, q2222
    vpsadbw        m9, m4, m5
    vpaddw         m6, m6, m9
    vpsadbw        m9, m3, m5
    vpaddw         m7, m7, m9
    vpsadbw        m9, m2, m5
    vpaddw         m8, m8, m9
    vmovdqu        m5, [r0 + 96]
    add            r0, 128
    vpshufd        m3, m0, q3333
    vpsadbw        m9, m4, m5
    vpaddw         m6, m6, m9
    vpsadbw        m9, m3, m5
    vpaddw         m7, m7, m9
    vpsadbw        m9, m2, m5
    vpaddw         m8, m8, m9
    
    vmovdqu        m5, [r0]
    vpshufd        m3, m1, q0000
    vpsadbw        m9, m4, m5
    vpaddw         m6, m6, m9
    vpsadbw        m9, m3, m5
    vpaddw         m7, m7, m9
    vpsadbw        m9, m2, m5
    vpaddw         m8, m8, m9
    vmovdqu        m5, [r0 + 32]
    vpshufd        m3, m1, q1111
    vpsadbw        m9, m4, m5
    vpaddw         m6, m6, m9
    vpsadbw        m9, m3, m5
    vpaddw         m7, m7, m9
    vpsadbw        m9, m2, m5
    vpaddw         m8, m8, m9
    vmovdqu        m5, [r0 + 64]
    vpshufd        m3, m1, q2222
    vpsadbw        m9, m4, m5
    vpaddw         m6, m6, m9
    vpsadbw        m9, m3, m5
    vpaddw         m7, m7, m9
    vpsadbw        m9, m2, m5
    vpaddw         m8, m8, m9
    vmovdqu        m5, [r0 + 96]
    vpshufd        m3, m1, q3333
    vpsadbw        m9, m4, m5
    vpaddw         m6, m6, m9
    vpsadbw        m9, m3, m5
    vpaddw         m7, m7, m9
    vpsadbw        m9, m2, m5
    vpaddw         m8, m8, m9
    
    vpsllq         m7, m7, 16
    vpsllq         m8, m8, 32
    vpaddw         m6, m6, m7
    vpaddw         m6, m6, m8
    vextracti128   xm0, m6, 1
    vpaddw         xm0, xm0, xm6
    vpunpckhqdq    xm1, xm0, xm0
    vpaddw         xm0, xm0, xm1
    vpmovzxwd      xm0, xm0
    vmovdqu        [r2], xm0
%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    add            rsp, 40
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    RET


