;*****************************************************************************
;* bitstream-a.asm: x86 bitstream functions
;*****************************************************************************
;* Copyright (C) 2010-2019 x264 project
;*
;* Authors: Fiona Glaser <fiona@x264.com>
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

SECTION .text

INIT_YMM avx2
cglobal nal_escape, 0, 0
    movzx          r3d, byte [r1]
    sub            r1, r2              ; r1 = offset of current src pointer from end of src
    vpxor          m0, m0, m0
    mov            [r0], r3b
    sub            r0, r1              ; r0 = projected end of dst, assuming no more escapes
    or             r3d, 0xffffff00     ; ignore data before src

    ; Start off by jumping into the escape loop in case there's an escape at the start.
    ; And do a few more in scalar until dst is aligned.
    jmp .escape_loop

ALIGN 16
.false_check:
    ; Detect false positive to avoid unneccessary escape loop
    xor            r3d, r3d
    cmp            byte [r0 + r1 - 1], 0
    setnz          r3b
    xor            r3, r4
    jnz            .escape
    jmp            .continue

ALIGN 16
.simd:
    vmovdqu        [r0 + r1 + 32], m1
    vpcmpeqb       m1, m1, m0
    vmovdqu        [r0 + r1], m2
    vpcmpeqb       m2, m2, m0
    vpmovmskb      r3d, m1
    vmovdqu        m1, [r1 + r2 + 96]
    vpmovmskb      r4d, m2
    vmovdqu        m2, [r1 + r2 + 64]
    shl            r3, 32
    or             r3, r4
    lea            r4, [r3 + r3]
    inc            r4
    and            r4, r3
    jnz            .false_check
.continue:
    add            r1, 64
    jl             .simd
.ret:
    mov            rax, r0
    RET

.escape:
    ; Skip bytes that are known to be valid
    and            r4, r3
    tzcnt          r4, r4
    xor            r3d, r3d ; the last two bytes are known to be zero
    add            r1, r4
.escape_loop:
    inc            r1
    jge .ret

    movzx          r4d, byte [r1 + r2]
    shl            r3d, 8
    or             r3d, r4d
    test           r3d, 0xfffffc       ; if the last two bytes are 0 and the current byte is <=3
    jz             .add_escape_byte
.escaped:
    lea            r4d, [r0 + r1]
    mov            [r0 + r1], r3b
    test           r4d, 31             ; Do SIMD when dst is aligned
    jnz            .escape_loop
    vmovdqu        m1, [r1 + r2 + 32]
    vmovdqu        m2, [r1 + r2]
    jmp            .simd

ALIGN 16
.add_escape_byte:
    mov            byte [r0 + r1], 3
    inc            r0
    or             r3d, 0x0300
    jmp            .escaped
