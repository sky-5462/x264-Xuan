;*****************************************************************************
;* cabac-a.asm: x86 cabac
;*****************************************************************************
;* Copyright (C) 2008-2019 x264 project
;*
;* Authors: Loren Merritt <lorenm@u.washington.edu>
;*          Fiona Glaser <fiona@x264.com>
;*          Holger Lubitz <holger@lubitz.org>
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

SECTION_RODATA 8

cextern coeff_last4_avx2
cextern coeff_last15_avx2
cextern coeff_last16_avx2
cextern coeff_last64_avx2

%macro COEFF_LAST_TABLE 0-14 16, 15, 16, 4, 15, 64, 16, 15, 16, 64, 16, 15, 16, 64
    coeff_last_avx2:
    %rep 14
        dq mangle(private_prefix %+ _coeff_last%1_avx2)
        %rotate 1
    %endrep
%endmacro

COEFF_LAST_TABLE

bypass_lut:     dd        -1,     0x2,     0x14,     0x68,     0x1d0,     0x7a0,     0x1f40,     0x7e80
                dd   0x1fd00, 0x7fa00, 0x1ff400, 0x7fe800, 0x1ffd000, 0x7ffa000, 0x1fff4000, 0x7ffe8000

coeff_abs_level1_ctx:       db 1, 2, 3, 4, 0, 0, 0, 0
coeff_abs_levelgt1_ctx:     db 5, 5, 5, 5, 6, 7, 8, 9
coeff_abs_level_transition: db 1, 2, 3, 3, 4, 5, 6, 7
                            db 4, 4, 4, 4, 5, 6, 7, 7


SECTION .text

cextern_common cabac_range_lps
cextern_common cabac_transition
cextern_common cabac_entropy
cextern cabac_size_unary
cextern cabac_transition_unary
cextern_common significant_coeff_flag_offset
cextern_common significant_coeff_flag_offset_8x8
cextern_common last_coeff_flag_offset
cextern_common last_coeff_flag_offset_8x8
cextern_common coeff_abs_level_m1_offset
cextern_common count_cat_m1

struc cb
    .low: resd 1
    .range: resd 1
    .queue: resd 1
    .bytes_outstanding: resd 1
    .start: resq 1
    .p: resq 1
    .end: resq 1
    align 64, resb 1
    .bits_encoded: resd 1
    .state: resb 1024
endstruc

;=============================================================================
; cabac_encode
;=============================================================================
INIT_XMM avx2
cglobal cabac_encode_decision, 0, 0
%if WIN64
    push           r7
%endif
    lea            r7, [$$]
    %define        GLOBAL +r7-$$

    movzx          r3d, byte [r0 + r1 + cb.state]
    mov            r4d, [r0 + cb.range]
    mov            r5d, r3d                      ; i_state
    shr            r3d, 1                        ; i_state >> 1
    mov            r6d, r4d                      ; i_range
    sar            r4d, 6                        ; i_range >> 6
    lea            r3d, [r4 + r3 * 4]            ; index for i_range_lps
    movzx          r3d, byte [cabac_range_lps + r3 - 4 GLOBAL]  ; i_range_lps
    sub            r6d, r3d                      ; i_range -= i_range_lps

    lea            r4d, [r2 + r5 * 2]            ; index for cabac_transition
    and            r5d, 1                        ; i_state & 1
    movzx          r4d, byte [cabac_transition + r4 GLOBAL]
    mov            [r0 + r1 + cb.state], r4b     ; write back state[i_ctx]
    mov            r1d, [r0 + cb.low]            ; i_low
    lea            r4d, [r1 + r6]                ; i_low += i_range
    cmp            r2d, r5d                      ; if( b != (i_state & 1) )
    cmovne         r1d, r4d                      ; i_low
    cmovne         r6d, r3d                      ; i_range

    mov            r3d, r6d                      ; i_range
    or             r6d, 7
    lzcnt          r6d, r6d
    sub            r6d, 23                       ; shift
    shlx           r3d, r3d, r6d
    shlx           r2d, r1d, r6d                 ; i_low
    mov            [r0 + cb.range], r3d          ; write back i_range
%if WIN64
    pop            r7
%endif
    mov            r1d, [r0 + cb.queue]
    add            r1d, r6d                      ; i_queue
    jge            cabac_putbyte

    mov            [r0 + cb.low], r2d            ; write back i_low
    mov            [r0 + cb.queue], r1d          ; write back i_queue
    ret


INIT_XMM avx2
cglobal cabac_encode_bypass, 0, 0
    mov            r6d, [r0 + cb.low]            ; i_low
    and            r1d, [r0 + cb.range]
    lea            r2d, [r1 + r6 * 2]
    mov            r1d, [r0 + cb.queue]
    inc            r1d
    jge            cabac_putbyte

    mov            [r0 + cb.low], r2d            ; write back i_low
    mov            [r0 + cb.queue], r1d          ; write back i_queue
    ret


; shortcut: the renormalization shift in terminal
; can only be 0 or 1 and is zero over 99% of the time.
INIT_XMM avx2
cglobal cabac_encode_terminal, 0, 0
    mov            r6d, [r0 + cb.range]          ; i_range
    sub            r6d, 2
    test           r6d, 100h
    jz             .renorm
    mov            [r0 + cb.range], r6d
    ret

ALIGN 16
.renorm:
    shl            r6d, 1
    mov            [r0 + cb.range], r6d
    mov            r1d, [r0 + cb.queue]
    mov            r2d, [r0 + cb.low]
    shl            r2d, 1
    inc            r1d
    jge            cabac_putbyte

    mov            [r0 + cb.low], r2d            ; write back i_low
    mov            [r0 + cb.queue], r1d          ; write back i_queue
    ret


; r0: cb
; r1: queue
; r2: low
ALIGN 16
cabac_putbyte:
    add            r1d, 10
    shrx           r3d, r2d, r1d                 ; out
    bzhi           r2d, r2d, r1d                 ; i_low
    sub            r1d, 18                       ; i_queue
    mov            r6d, [r0 + cb.bytes_outstanding]
    cmp            r3b, 0FFh
    jnz            .clear_outstanding

    inc            r6d
    mov            [r0 + cb.bytes_outstanding], r6d
    jmp            .update_queue_low

ALIGN 16
.clear_outstanding:
    mov            r5d, r3d                      ; out
    sar            r3d, 8                        ; carry
    mov            r4, [r0 + cb.p]
    add            [r4 - 1], r3b                 ; cb->p[-1] += carry
    dec            r3d                           ; carry - 1
    test           r6d, r6d
    jle            .end
.loop:
    mov            [r4], r3b
    inc            r4
    dec            r6d
    jg             .loop
.end:
    mov            [r4], r5b
    inc            r4
    mov            [r0 + cb.p], r4
    mov            [r0 + cb.bytes_outstanding], r6d  ; bytes_outstanding must be 0
.update_queue_low:
    mov            [r0 + cb.low], r2d            ; write back i_low
    mov            [r0 + cb.queue], r1d          ; write back i_queue
    ret


;=============================================================================
; cabac_block_residual
;=============================================================================
INIT_XMM avx2
cglobal cabac_block_residual_internal, 0, 0
%if WIN64
    push           r7
    push           r8
%endif
    push           r9
    push           r10
    push           r11
    push           r12
    push           r13
    push           r14
    lea            r7, [$$]
    %define        GLOBAL +r7-$$

    ; modified coeff_last functions will keep r0-r2 safe
    call           [coeff_last_avx2 + r1 * 8 GLOBAL]  ; r6 = last
    movzx          r3d, word [significant_coeff_flag_offset + r1 * 2 GLOBAL]  ; ctx_sig
    movzx          r4d, word [last_coeff_flag_offset + r1 * 2 GLOBAL]  ; ctx_last
    movzx          r5d, word [coeff_abs_level_m1_offset + r1 * 2 GLOBAL]
    push           r5                            ; ctx_level
    or             r5, -1                        ; coeff_idx
    movzx          r8d, byte [count_cat_m1 + r1 GLOBAL]  ; count_m1
    xor            r1d, r1d                      ; i = 0
    sub            rsp, 128                      ; coeffs[64]
    cmp            r8d, 63
    jne            .sigmap2_loop

.sigmap1_loop:
    movzx          r9d, byte [significant_coeff_flag_offset_8x8 + r1 GLOBAL]  ; sig_off
    add            r9d, r3d                      ; ctx_sig + sig_off
    xor            r10d, r10d
    cmp            word [r0 + r1 * 2], 0         ; if (l[i])
    setnz          r10b
    call           .encode_decision
    movsx          r9d, word [r0 + r1 * 2]       ; l[i]
    test           r9d, r9d
    jz             .sigmap1_end

    mov            [rsp + r5 * 2 + 2], r9w       ; coeffs[++coeff_idx] = l[i]
    inc            r5d
    movzx          r9d, byte [last_coeff_flag_offset_8x8 + r1 GLOBAL]  ; last_off
    add            r9d, r4d                      ; ctx_last + last_off
    xor            r10d, r10d
    cmp            r1d, r6d                      ; if (i == last)
    sete           r10b                          ; b = 0/1
    call           .encode_decision
    cmp            r1d, r6d
    je             .break_out

.sigmap1_end:
    inc            r1d                           ; ++i
    cmp            r1d, r8d                      ; if (++i == count_m1)
    jne            .sigmap1_loop
    jmp            .break_out_pre

ALIGN 16
.sigmap2_loop:
    lea            r9d, [r3 + r1]                ; ctx_sig + i
    xor            r10d, r10d
    cmp            word [r0 + r1 * 2], 0         ; if (l[i])
    setnz          r10b
    call           .encode_decision
    movsx          r9d, word [r0 + r1 * 2]       ; l[i]
    test           r9d, r9d
    jz             .sigmap2_end

    mov            [rsp + r5 * 2 + 2], r9w       ; coeffs[++coeff_idx] = l[i]
    inc            r5d
    lea            r9d, [r4 + r1]                ; ctx_last + i
    xor            r10d, r10d
    cmp            r1d, r6d                      ; if (i == last)
    sete           r10b                          ; b = 0/1
    call           .encode_decision
    cmp            r1d, r6d
    je             .break_out

.sigmap2_end:
    inc            r1d                           ; ++i
    cmp            r1d, r8d                      ; if (++i == count_m1)
    jne            .sigmap2_loop

.break_out_pre:
    movsx          r9d, word [r0 + r1 * 2]
    inc            r5d
    mov            [rsp + r5 * 2], r9w
.break_out:
    mov            r3d, [rsp + 128]              ; ctx_level
    xor            r4d, r4d                      ; node_ctx
.outer_loop:
    movsx          r0d, word [rsp + r5 * 2]      ; coeff
    mov            r6d, r0d
    sar            r0d, 31                       ; coeff_sign
    xor            r6d, r0d
    sub            r6d, r0d                      ; abs_coeff
    movzx          r9d, byte [coeff_abs_level1_ctx + r4 GLOBAL]
    add            r9d, r3d                      ; ctx
    xor            r10d, r10d
    cmp            r6d, 1
    setg           r10b
    movzx          r8d, byte [coeff_abs_levelgt1_ctx + r4 GLOBAL]  ; new ctx (without +ctx_level)
    lea            r4d, [r4 + r10 * 8]           ; index for new node_ctx
    movzx          r4d, byte [coeff_abs_level_transition + r4 GLOBAL]  ; new node_ctx
    call           .encode_decision
    cmp            r6d, 1
    jle            .outer_loop_end

    add            r8d, r3d                      ; new ctx
    mov            r1d, 15
    cmp            r6d, 15
    cmovl          r1d, r6d
    sub            r1d, 2                        ; i
    jle            .inner_loop_end
.inner_loop:
    mov            r9d, r8d
    mov            r10d, 1
    call           .encode_decision
    dec            r1d                           ; i--
    jg             .inner_loop

.inner_loop_end:
    sub            r6d, 15                       ; if (abs_coeff < 15)
    jge            .ue_bypass

    mov            r9d, r8d
    xor            r10d, r10d
    call           .encode_decision
    jmp            .outer_loop_end

; r2: cb
; r6: val
ALIGN 16
.ue_bypass:
    inc            r6d                           ; v
    mov            r1d, 31                       ; r1 is 0 now
    lzcnt          r8d, r6d
    sub            r1d, r8d                      ; k
    add            r6d, [bypass_lut + r1 * 4 GLOBAL]  ; x
    shl            r1d, 1
    lea            r8d, [r1 + 1]                 ; new k
    and            r1d, 7
    inc            r1d                           ; i
.ue_bypass_loop:
    sub            r8d, r1d                      ; k -= i
    shlx           r10d, [r2 + cb.low], r1d      ; i_low <<= i
    shrx           r9d, r6d, r8d                 ; x >> k
    and            r9d, 0FFh
    imul           r9d, [r2 + cb.range]
    add            r10d, r9d                     ; i_low
    mov            r9d, [r2 + cb.queue]
    add            r9d, r1d                      ; i_queue
    call           .putbyte
    mov            r1d, 8
    test           r8d, r8d
    jg             .ue_bypass_loop

.outer_loop_end:
    mov            r10d, [r2 + cb.low]
    and            r0d, [r2 + cb.range]
    shl            r10d, 1
    mov            r9d, [r2 + cb.queue]
    add            r10d, r0d                     ; i_low
    inc            r9d                           ; i_queue
    call           .putbyte
    dec            r5d
    jge            .outer_loop

    add            rsp, 136
    pop            r14
    pop            r13
    pop            r12
    pop            r11
    pop            r10
    pop            r9
%if WIN64
    pop            r8
    pop            r7
%endif
    ret


; modified version to share register with caller
; r2: cb
; r9: i_ctx
; r10: b
ALIGN 16
.encode_decision:
    movzx          r11d, byte [r2 + r9 + cb.state]
    mov            r12d, [r2 + cb.range]
    mov            r13d, r11d                    ; i_state
    shr            r11d, 1                       ; i_state >> 1
    mov            r14d, r12d                    ; i_range
    sar            r12d, 6                       ; i_range >> 6
    lea            r11d, [r12 + r11 * 4]         ; index for i_range_lps
    movzx          r11d, byte [cabac_range_lps + r11 - 4 GLOBAL]  ; i_range_lps
    sub            r14d, r11d                    ; i_range -= i_range_lps

    lea            r12d, [r10 + r13 * 2]         ; index for cabac_transition
    and            r13d, 1                       ; i_state & 1
    movzx          r12d, byte [cabac_transition + r12 GLOBAL]
    mov            [r2 + r9 + cb.state], r12b    ; write back state[i_ctx]
    mov            r9d, [r2 + cb.low]            ; i_low
    lea            r12d, [r9 + r14]              ; i_low += i_range
    cmp            r10d, r13d                    ; if( b != (i_state & 1) )
    cmovne         r9d, r12d                     ; i_low
    cmovne         r14d, r11d                    ; i_range

    mov            r11d, r14d                    ; i_range
    lzcnt          r14d, r14d                    ; in cabac_block_residual don't need to or 7
    sub            r14d, 23
    shlx           r11d, r11d, r14d
    shlx           r10d, r9d, r14d               ; i_low
    mov            [r2 + cb.range], r11d         ; write back i_range
    mov            r9d, [r2 + cb.queue]
    add            r9d, r14d                     ; i_queue
    jmp            .putbyte

; r2: cb
; r9: queue
; r10: low
; require preceding instruction is add i_queue, to skip cmp
ALIGN 16
.putbyte:
    jl             .update_queue_low
    add            r9d, 10
    shrx           r11d, r10d, r9d               ; out
    bzhi           r10d, r10d, r9d               ; i_low
    sub            r9d, 18                       ; i_queue
    mov            r14d, [r2 + cb.bytes_outstanding]
    cmp            r11b, 0FFh
    jnz            .clear_outstanding

    inc            r14d
    mov            [r2 + cb.bytes_outstanding], r14d
    jmp            .update_queue_low

ALIGN 16
.clear_outstanding:
    mov            r13d, r11d                    ; out
    sar            r11d, 8                       ; carry
    mov            r12, [r2 + cb.p]
    add            [r12 - 1], r11b               ; cb->p[-1] += carry
    dec            r11d                          ; carry - 1
    test           r14d, r14d
    jle            .end
.loop:
    mov            [r12], r11b
    inc            r12
    dec            r14d
    jg             .loop
.end:
    mov            [r12], r13b
    inc            r12
    mov            [r2 + cb.p], r12
    mov            [r2 + cb.bytes_outstanding], r14d  ; bytes_outstanding must be 0
.update_queue_low:
    mov            [r2 + cb.low], r10d           ; write back i_low
    mov            [r2 + cb.queue], r9d          ; write back i_queue
    ret


INIT_XMM avx2
cglobal cabac_block_residual_rd_internal, 0, 0
%if WIN64
    push           r7
    push           r8
%endif
    push           r9
    push           r10
    push           r11
    push           r12
    lea            r7, [$$]
    %define        GLOBAL +r7-$$

    ; modified coeff_last functions will keep parameters safe
    call           [coeff_last_avx2 + r1 * 8 GLOBAL]  ; r6 = last
    movzx          r3d, word [significant_coeff_flag_offset + r1 * 2 GLOBAL]  ; ctx_sig
    movzx          r4d, word [last_coeff_flag_offset + r1 * 2 GLOBAL]  ; ctx_last
    movzx          r5d, word [coeff_abs_level_m1_offset + r1 * 2 GLOBAL]  ; ctx_level
    mov            r11d, [r2 + cb.bits_encoded]  ; f8_bits_encoded
    cmp            byte [count_cat_m1 + r1 GLOBAL], r6b
    je             .skip1

    ; first size_decision
    lea            r8d, [r3 + r6]                ; ctx_sig + last
    movzx          r9d, byte [r2 + r8 + cb.state]  ; i_state
    movzx          r10d, byte [cabac_transition + r9 * 2 + 1 GLOBAL]
    mov            [r2 + r8 + cb.state], r10b    ; cb->state[i_ctx] = ...
    xor            r9d, 1
    movzx          r10d, word [cabac_entropy + r9 * 2 GLOBAL]
    add            r11d, r10d
    ; second size_decision
    lea            r8d, [r4 + r6]                ; ctx_last + last
    movzx          r9d, byte [r2 + r8 + cb.state]  ; i_state
    movzx          r10d, byte [cabac_transition + r9 * 2 + 1 GLOBAL]
    mov            [r2 + r8 + cb.state], r10b    ; cb->state[i_ctx] = ...
    xor            r9d, 1
    movzx          r10d, word [cabac_entropy + r9 * 2 GLOBAL]
    add            r11d, r10d
.skip1:
    movsx          r8d, word [r0 + r6 * 2]       ; l[last]
    mov            r1d, r8d
    neg            r8d
    cmovg          r1d, r8d                      ; coeff_abs
    movzx          r8d, byte [coeff_abs_level1_ctx]
    add            r8d, r5d                      ; ctx
    cmp            r1d, 1
    jle            .le1

    movzx          r9d, byte [r2 + r8 + cb.state]  ; i_state
    movzx          r10d, byte [cabac_transition + r9 * 2 + 1 GLOBAL]
    mov            [r2 + r8 + cb.state], r10b    ; cb->state[i_ctx] = ...
    xor            r9d, 1
    movzx          r10d, word [cabac_entropy + r9 * 2 GLOBAL]
    add            r11d, r10d
    movzx          r8d, byte [coeff_abs_levelgt1_ctx]
    add            r8d, r5d                      ; ctx
    movzx          r12d, byte [coeff_abs_level_transition + 8]  ; node_ctx
    movzx          r9d, byte [r2 + r8 + cb.state]  ; cb->state[ctx]
    cmp            r1d, 15
    jge            .ge15

    dec            r1d                             ; coeff_abs - 1
    shl            r1d, 7
    add            r1d, r9d                        ; index
    movzx          r9d, word [cabac_size_unary + r1 * 2 GLOBAL]
    movzx          r10d, byte [cabac_transition_unary + r1 GLOBAL]
    add            r11d, r9d
    mov            [r2 + r8 + cb.state], r10b
    jmp            .loop_setup

ALIGN 16
.ge15:
    movzx          r10d, byte [cabac_transition_unary + r9 + 14*128 GLOBAL]
    movzx          r9d, word [cabac_size_unary + r9 * 2 + 14*256 GLOBAL]
    add            r11d, r9d
    mov            [r2 + r8 + cb.state], r10b
    ; bs_size_ue_big
    sub            r1d, 14
    lzcnt          r1d, r1d
    xor            r1d, 1Fh
    shl            r1d, 9
    add            r1d, 256
    add            r11d, r1d
    jmp            .loop_setup

ALIGN 16
.le1:
    movzx          r9d, byte [r2 + r8 + cb.state]  ; i_state
    movzx          r10d, byte [cabac_transition + r9 * 2 GLOBAL]
    mov            [r2 + r8 + cb.state], r10b    ; cb->state[i_ctx] = ...
    movzx          r10d, word [cabac_entropy + r9 * 2 GLOBAL]
    add            r11d, r10d
    movzx          r12d, byte [coeff_abs_level_transition]  ; node_ctx
    add            r11d, 256

.loop_setup:
    dec            r6d                           ; i
    jl             .loop_out

.loop:
    movsx          r8d, word [r0 + r6 * 2]       ; l[i]
    test           r8d, r8d
    jz             .zero

    mov            r1d, r8d
    neg            r8d
    cmovg          r1d, r8d                      ; coeff_abs
    ; first size_decision
    lea            r8d, [r3 + r6]                ; ctx_sig + i
    movzx          r9d, byte [r2 + r8 + cb.state]  ; i_state
    movzx          r10d, byte [cabac_transition + r9 * 2 + 1 GLOBAL]
    mov            [r2 + r8 + cb.state], r10b    ; cb->state[i_ctx] = ...
    xor            r9d, 1
    movzx          r10d, word [cabac_entropy + r9 * 2 GLOBAL]
    add            r11d, r10d
    ; second size_decision
    lea            r8d, [r4 + r6]                ; ctx_last + i
    movzx          r9d, byte [r2 + r8 + cb.state]  ; i_state
    movzx          r10d, byte [cabac_transition + r9 * 2 GLOBAL]
    mov            [r2 + r8 + cb.state], r10b    ; cb->state[i_ctx] = ...
    movzx          r10d, word [cabac_entropy + r9 * 2 GLOBAL]
    add            r11d, r10d

    movzx          r8d, byte [coeff_abs_level1_ctx + r12 GLOBAL]
    add            r8d, r5d                      ; ctx
    cmp            r1d, 1
    jle            .loop_le1

    movzx          r9d, byte [r2 + r8 + cb.state]  ; i_state
    movzx          r10d, byte [cabac_transition + r9 * 2 + 1 GLOBAL]
    mov            [r2 + r8 + cb.state], r10b    ; cb->state[i_ctx] = ...
    xor            r9d, 1
    movzx          r10d, word [cabac_entropy + r9 * 2 GLOBAL]
    add            r11d, r10d
    movzx          r8d, byte [coeff_abs_levelgt1_ctx + r12 GLOBAL]
    add            r8d, r5d                      ; ctx
    movzx          r12d, byte [coeff_abs_level_transition + r12 + 8 GLOBAL]
    movzx          r9d, byte [r2 + r8 + cb.state]  ; cb->state[ctx]
    cmp            r1d, 15
    jge            .loop_ge15

    dec            r1d                             ; coeff_abs - 1
    shl            r1d, 7
    add            r1d, r9d                        ; index
    movzx          r9d, word [cabac_size_unary + r1 * 2 GLOBAL]
    movzx          r10d, byte [cabac_transition_unary + r1 GLOBAL]
    add            r11d, r9d
    mov            [r2 + r8 + cb.state], r10b
    jmp            .loop_end

ALIGN 16
.loop_ge15:
    movzx          r10d, byte [cabac_transition_unary + r9 + 14*128 GLOBAL]
    movzx          r9d, word [cabac_size_unary + r9 * 2 + 14*256 GLOBAL]
    add            r11d, r9d
    mov            [r2 + r8 + cb.state], r10b
    ; bs_size_ue_big
    sub            r1d, 14
    lzcnt          r1d, r1d
    xor            r1d, 1Fh
    shl            r1d, 9
    add            r1d, 256
    add            r11d, r1d
    jmp            .loop_end

ALIGN 16
.loop_le1:
    movzx          r9d, byte [r2 + r8 + cb.state]  ; i_state
    movzx          r10d, byte [cabac_transition + r9 * 2 GLOBAL]
    mov            [r2 + r8 + cb.state], r10b    ; cb->state[i_ctx] = ...
    movzx          r10d, word [cabac_entropy + r9 * 2 GLOBAL]
    add            r11d, r10d
    movzx          r12d, byte [coeff_abs_level_transition + r12 GLOBAL]
    add            r11d, 256
    jmp            .loop_end

ALIGN 16
.zero:
    lea            r8d, [r6 + r3]                ; ctx_sig + i
    movzx          r9d, byte [r2 + r8 + cb.state]  ; i_state
    movzx          r10d, byte [cabac_transition + r9 * 2 GLOBAL]
    mov            [r2 + r8 + cb.state], r10b    ; cb->state[i_ctx] = ...
    movzx          r10d, word [cabac_entropy + r9 * 2 GLOBAL]
    add            r11d, r10d

.loop_end:
    dec            r6d
    jge            .loop
.loop_out:
    mov            [r2 + cb.bits_encoded], r11d
    pop            r12
    pop            r11
    pop            r10
    pop            r9
%if WIN64
    pop            r8
    pop            r7
%endif
    ret


INIT_XMM avx2
cglobal cabac_block_residual_8x8_rd_internal, 0, 0
%if WIN64
    push           r7
    push           r8
%endif
    push           r9
    push           r10
    push           r11
    push           r12
    lea            r7, [$$]
    %define        GLOBAL +r7-$$

    ; modified coeff_last functions will keep parameters safe
    call           [coeff_last_avx2 + r1 * 8 GLOBAL]  ; r6 = last
    movzx          r3d, word [significant_coeff_flag_offset + r1 * 2 GLOBAL]  ; ctx_sig
    movzx          r4d, word [last_coeff_flag_offset + r1 * 2 GLOBAL]  ; ctx_last
    movzx          r5d, word [coeff_abs_level_m1_offset + r1 * 2 GLOBAL]  ; ctx_level
    mov            r11d, [r2 + cb.bits_encoded]  ; f8_bits_encoded
    cmp            r6d, 63
    je             .skip1

    ; first size_decision
    movzx          r8d, byte [significant_coeff_flag_offset_8x8 + r6 GLOBAL]
    add            r8d, r3d
    movzx          r9d, byte [r2 + r8 + cb.state]  ; i_state
    movzx          r10d, byte [cabac_transition + r9 * 2 + 1 GLOBAL]
    mov            [r2 + r8 + cb.state], r10b    ; cb->state[i_ctx] = ...
    xor            r9d, 1
    movzx          r10d, word [cabac_entropy + r9 * 2 GLOBAL]
    add            r11d, r10d
    ; second size_decision
    movzx          r8d, byte [last_coeff_flag_offset_8x8 + r6 GLOBAL]
    add            r8d, r4d
    movzx          r9d, byte [r2 + r8 + cb.state]  ; i_state
    movzx          r10d, byte [cabac_transition + r9 * 2 + 1 GLOBAL]
    mov            [r2 + r8 + cb.state], r10b    ; cb->state[i_ctx] = ...
    xor            r9d, 1
    movzx          r10d, word [cabac_entropy + r9 * 2 GLOBAL]
    add            r11d, r10d

.skip1:
    movsx          r8d, word [r0 + r6 * 2]       ; l[last]
    mov            r1d, r8d
    neg            r8d
    cmovg          r1d, r8d                      ; coeff_abs
    movzx          r8d, byte [coeff_abs_level1_ctx]
    add            r8d, r5d                      ; ctx
    cmp            r1d, 1
    jle            .le1

    movzx          r9d, byte [r2 + r8 + cb.state]  ; i_state
    movzx          r10d, byte [cabac_transition + r9 * 2 + 1 GLOBAL]
    mov            [r2 + r8 + cb.state], r10b    ; cb->state[i_ctx] = ...
    xor            r9d, 1
    movzx          r10d, word [cabac_entropy + r9 * 2 GLOBAL]
    add            r11d, r10d
    movzx          r8d, byte [coeff_abs_levelgt1_ctx]
    add            r8d, r5d                      ; ctx
    movzx          r12d, byte [coeff_abs_level_transition + 8]  ; node_ctx
    movzx          r9d, byte [r2 + r8 + cb.state]  ; cb->state[ctx]
    cmp            r1d, 15
    jge            .ge15

    dec            r1d                             ; coeff_abs - 1
    shl            r1d, 7
    add            r1d, r9d                        ; index
    movzx          r9d, word [cabac_size_unary + r1 * 2 GLOBAL]
    movzx          r10d, byte [cabac_transition_unary + r1 GLOBAL]
    add            r11d, r9d
    mov            [r2 + r8 + cb.state], r10b
    jmp            .loop_setup

ALIGN 16
.ge15:
    movzx          r10d, byte [cabac_transition_unary + r9 + 14*128 GLOBAL]
    movzx          r9d, word [cabac_size_unary + r9 * 2 + 14*256 GLOBAL]
    add            r11d, r9d
    mov            [r2 + r8 + cb.state], r10b
    ; bs_size_ue_big
    sub            r1d, 14
    lzcnt          r1d, r1d
    xor            r1d, 1Fh
    shl            r1d, 9
    add            r1d, 256
    add            r11d, r1d
    jmp            .loop_setup

ALIGN 16
.le1:
    movzx          r9d, byte [r2 + r8 + cb.state]  ; i_state
    movzx          r10d, byte [cabac_transition + r9 * 2 GLOBAL]
    mov            [r2 + r8 + cb.state], r10b    ; cb->state[i_ctx] = ...
    movzx          r10d, word [cabac_entropy + r9 * 2 GLOBAL]
    add            r11d, r10d
    movzx          r12d, byte [coeff_abs_level_transition]  ; node_ctx
    add            r11d, 256

.loop_setup:
    dec            r6d                           ; i
    jl             .loop_out

.loop:
    movsx          r8d, word [r0 + r6 * 2]       ; l[i]
    test           r8d, r8d
    jz             .zero

    mov            r1d, r8d
    neg            r8d
    cmovg          r1d, r8d                      ; coeff_abs
    ; first size_decision
    movzx          r8d, byte [significant_coeff_flag_offset_8x8 + r6 GLOBAL]
    add            r8d, r3d
    movzx          r9d, byte [r2 + r8 + cb.state]  ; i_state
    movzx          r10d, byte [cabac_transition + r9 * 2 + 1 GLOBAL]
    mov            [r2 + r8 + cb.state], r10b    ; cb->state[i_ctx] = ...
    xor            r9d, 1
    movzx          r10d, word [cabac_entropy + r9 * 2 GLOBAL]
    add            r11d, r10d
    ; second size_decision
    movzx          r8d, byte [last_coeff_flag_offset_8x8 + r6 GLOBAL]
    add            r8d, r4d
    movzx          r9d, byte [r2 + r8 + cb.state]  ; i_state
    movzx          r10d, byte [cabac_transition + r9 * 2 GLOBAL]
    mov            [r2 + r8 + cb.state], r10b    ; cb->state[i_ctx] = ...
    movzx          r10d, word [cabac_entropy + r9 * 2 GLOBAL]
    add            r11d, r10d

    movzx          r8d, byte [coeff_abs_level1_ctx + r12 GLOBAL]
    add            r8d, r5d                      ; ctx
    cmp            r1d, 1
    jle            .loop_le1

    movzx          r9d, byte [r2 + r8 + cb.state]  ; i_state
    movzx          r10d, byte [cabac_transition + r9 * 2 + 1 GLOBAL]
    mov            [r2 + r8 + cb.state], r10b    ; cb->state[i_ctx] = ...
    xor            r9d, 1
    movzx          r10d, word [cabac_entropy + r9 * 2 GLOBAL]
    add            r11d, r10d
    movzx          r8d, byte [coeff_abs_levelgt1_ctx + r12 GLOBAL]
    add            r8d, r5d                      ; ctx
    movzx          r12d, byte [coeff_abs_level_transition + r12 + 8 GLOBAL]
    movzx          r9d, byte [r2 + r8 + cb.state]  ; cb->state[ctx]
    cmp            r1d, 15
    jge            .loop_ge15

    dec            r1d                             ; coeff_abs - 1
    shl            r1d, 7
    add            r1d, r9d                        ; index
    movzx          r9d, word [cabac_size_unary + r1 * 2 GLOBAL]
    movzx          r10d, byte [cabac_transition_unary + r1 GLOBAL]
    add            r11d, r9d
    mov            [r2 + r8 + cb.state], r10b
    jmp            .loop_end

ALIGN 16
.loop_ge15:
    movzx          r10d, byte [cabac_transition_unary + r9 + 14*128 GLOBAL]
    movzx          r9d, word [cabac_size_unary + r9 * 2 + 14*256 GLOBAL]
    add            r11d, r9d
    mov            [r2 + r8 + cb.state], r10b
    ; bs_size_ue_big
    sub            r1d, 14
    lzcnt          r1d, r1d
    xor            r1d, 1Fh
    shl            r1d, 9
    add            r1d, 256
    add            r11d, r1d
    jmp            .loop_end

.loop_le1:
    movzx          r9d, byte [r2 + r8 + cb.state]  ; i_state
    movzx          r10d, byte [cabac_transition + r9 * 2 GLOBAL]
    mov            [r2 + r8 + cb.state], r10b    ; cb->state[i_ctx] = ...
    movzx          r10d, word [cabac_entropy + r9 * 2 GLOBAL]
    add            r11d, r10d
    movzx          r12d, byte [coeff_abs_level_transition + r12 GLOBAL]
    add            r11d, 256
    jmp            .loop_end

ALIGN 16
.zero:
    movzx          r8d, byte [significant_coeff_flag_offset_8x8 + r6 GLOBAL]
    add            r8d, r3d
    movzx          r9d, byte [r2 + r8 + cb.state]  ; i_state
    movzx          r10d, byte [cabac_transition + r9 * 2 GLOBAL]
    mov            [r2 + r8 + cb.state], r10b    ; cb->state[i_ctx] = ...
    movzx          r10d, word [cabac_entropy + r9 * 2 GLOBAL]
    add            r11d, r10d

.loop_end:
    dec            r6d
    jge            .loop
.loop_out:
    mov            [r2 + cb.bits_encoded], r11d
    pop            r12
    pop            r11
    pop            r10
    pop            r9
%if WIN64
    pop            r8
    pop            r7
%endif
    ret
