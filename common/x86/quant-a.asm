;*****************************************************************************
;* quant-a.asm: x86 quantization and level-run
;*****************************************************************************
;* Copyright (C) 2005-2019 x264 project
;*
;* Authors: Loren Merritt <lorenm@u.washington.edu>
;*          Fiona Glaser <fiona@x264.com>
;*          Christian Heine <sennindemokrit@gmx.net>
;*          Oskar Arvidsson <oskar@irock.se>
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

%macro DQM8D 6
    dd %1, %4, %5, %4, %1, %4, %5, %4
    dd %4, %2, %6, %2, %4, %2, %6, %2
    dd %5, %6, %3, %6, %5, %6, %3, %6
    dd %4, %2, %6, %2, %4, %2, %6, %2
%endmacro

dequant8_scale_dword:
    DQM8D 20, 18, 32, 19, 25, 24
    DQM8D 22, 19, 35, 21, 28, 26
    DQM8D 26, 23, 42, 24, 33, 31
    DQM8D 28, 25, 45, 26, 35, 33
    DQM8D 32, 28, 51, 30, 40, 38
    DQM8D 36, 32, 58, 34, 46, 43

%macro DQM8 6
    dw %1, %4, %5, %4, %1, %4, %5, %4
    dw %4, %2, %6, %2, %4, %2, %6, %2
    dw %5, %6, %3, %6, %5, %6, %3, %6
    dw %4, %2, %6, %2, %4, %2, %6, %2
%endmacro

dequant8_scale:
    DQM8 20, 18, 32, 19, 25, 24
    DQM8 22, 19, 35, 21, 28, 26
    DQM8 26, 23, 42, 24, 33, 31
    DQM8 28, 25, 45, 26, 35, 33
    DQM8 32, 28, 51, 30, 40, 38
    DQM8 36, 32, 58, 34, 46, 43

%macro DQM4 3
    dw %1, %2, %1, %2, %2, %3, %2, %3
%endmacro

dequant4_scale:
    DQM4 10, 13, 16
    DQM4 11, 14, 18
    DQM4 13, 16, 20
    DQM4 14, 18, 23
    DQM4 16, 20, 25
    DQM4 18, 23, 29

chroma_dc_mf_perm:  dd  2, 2, 2, 2, 2, 2, 2, 2
                    dd  2, 3, 2, 3, 2, 3, 2, 3
                    dd  2, 2, 2, 2, 3, 3, 3, 3
                    dd  2, 3, 2, 3, 3, 2, 3, 2
                    dd  2, 2, 3, 3, 3, 3, 2, 2
                    dd  2, 3, 3, 2, 3, 2, 2, 3
                    dd  2, 2, 3, 3, 2, 2, 3, 3
                    dd  2, 3, 3, 2, 2, 3, 3, 2

idct_dequant4_scale:    dw 10, 10, 10, -10
                        dw 11, 11, 11, -11
                        dw 13, 13, 13, -13
                        dw 14, 14, 14, -14
                        dw 16, 16, 16, -16
                        dw 18, 18, 18, -18

chroma_dc_dmf_mask:     dw 1, 1,-1,-1, 1,-1,-1, 1
chroma_dc_dct_mask:     dw 1, 1,-1,-1

chroma_dc_dmf_2x4_mask: dw 1, 1, 1,-1
pd_2080:  dd 2080
pd_7:     dd 7

decimate_table4:    db  3,2,2,1,1,1,0,0,0,0,0,0,0,0,0,0
decimate_table8:	db  3,3,3,3,2,2,2,2,2,2,2,2,1,1,1,1
                    db  1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0
                    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

decimate_mask_table4:
    db  0,3,2,6,2,5,5,9,1,5,4,8,5,8,8,12,1,4,4,8,4,7,7,11,4,8,7,11,8,11,11,15,1,4
    db  3,7,4,7,7,11,3,7,6,10,7,10,10,14,4,7,7,11,7,10,10,14,7,11,10,14,11,14,14
    db 18,0,4,3,7,3,6,6,10,3,7,6,10,7,10,10,14,3,6,6,10,6,9,9,13,6,10,9,13,10,13
    db 13,17,4,7,6,10,7,10,10,14,6,10,9,13,10,13,13,17,7,10,10,14,10,13,13,17,10
    db 14,13,17,14,17,17,21,0,3,3,7,3,6,6,10,2,6,5,9,6,9,9,13,3,6,6,10,6,9,9,13
    db  6,10,9,13,10,13,13,17,3,6,5,9,6,9,9,13,5,9,8,12,9,12,12,16,6,9,9,13,9,12
    db 12,16,9,13,12,16,13,16,16,20,3,7,6,10,6,9,9,13,6,10,9,13,10,13,13,17,6,9
    db  9,13,9,12,12,16,9,13,12,16,13,16,16,20,7,10,9,13,10,13,13,17,9,13,12,16
    db 13,16,16,20,10,13,13,17,13,16,16,20,13,17,16,20,17,20,20,24

coeff_level_shuffle:
    db -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 0
    db  0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 1
    db  2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 2
    db  2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 3
    db  4, 5,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 4
    db  4, 5, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 5
    db  4, 5, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 6
    db  4, 5, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 7
    db  6, 7,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 8
    db  6, 7, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 9
    db  6, 7, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 10
    db  6, 7, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 11
    db  6, 7, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 12
    db  6, 7, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 13
    db  6, 7, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 14
    db  6, 7, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1   ; 15
    db  8, 9,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 16
    db  8, 9, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 17
    db  8, 9, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 18
    db  8, 9, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 19
    db  8, 9, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 20
    db  8, 9, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 21
    db  8, 9, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 22
    db  8, 9, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1   ; 23
    db  8, 9, 6, 7,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 24
    db  8, 9, 6, 7, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 25
    db  8, 9, 6, 7, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 26
    db  8, 9, 6, 7, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1   ; 27
    db  8, 9, 6, 7, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   ; 28
    db  8, 9, 6, 7, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1   ; 29
    db  8, 9, 6, 7, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1   ; 30
    db  8, 9, 6, 7, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1   ; 31
    db 10,11,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 6, 7,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 6, 7, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 6, 7, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 6, 7, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 6, 7, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 6, 7, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 6, 7, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 6, 7, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1
    db 10,11, 8, 9,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 8, 9, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 8, 9, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 8, 9, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 8, 9, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 8, 9, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 8, 9, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 8, 9, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1
    db 10,11, 8, 9, 6, 7,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 8, 9, 6, 7, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 8, 9, 6, 7, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 8, 9, 6, 7, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1
    db 10,11, 8, 9, 6, 7, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1
    db 10,11, 8, 9, 6, 7, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1
    db 10,11, 8, 9, 6, 7, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1
    db 10,11, 8, 9, 6, 7, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1   ; 63
    db 12,13,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 6, 7,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 6, 7, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 6, 7, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 6, 7, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 6, 7, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 6, 7, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 6, 7, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 6, 7, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1
    db 12,13, 8, 9,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 8, 9, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 8, 9, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 8, 9, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 8, 9, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 8, 9, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 8, 9, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 8, 9, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1
    db 12,13, 8, 9, 6, 7,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 8, 9, 6, 7, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 8, 9, 6, 7, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 8, 9, 6, 7, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1
    db 12,13, 8, 9, 6, 7, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13, 8, 9, 6, 7, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1
    db 12,13, 8, 9, 6, 7, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1
    db 12,13, 8, 9, 6, 7, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1
    db 12,13,10,11,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 6, 7,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 6, 7, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 6, 7, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 6, 7, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 6, 7, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 6, 7, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 6, 7, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 6, 7, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1
    db 12,13,10,11, 8, 9,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 8, 9, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 8, 9, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 8, 9, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 8, 9, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 8, 9, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 8, 9, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 8, 9, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1
    db 12,13,10,11, 8, 9, 6, 7,-1,-1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 8, 9, 6, 7, 0, 1,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 8, 9, 6, 7, 2, 3,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 8, 9, 6, 7, 2, 3, 0, 1,-1,-1,-1,-1
    db 12,13,10,11, 8, 9, 6, 7, 4, 5,-1,-1,-1,-1,-1,-1
    db 12,13,10,11, 8, 9, 6, 7, 4, 5, 0, 1,-1,-1,-1,-1
    db 12,13,10,11, 8, 9, 6, 7, 4, 5, 2, 3,-1,-1,-1,-1
    db 12,13,10,11, 8, 9, 6, 7, 4, 5, 2, 3, 0, 1,-1,-1
    db 14,15,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 6, 7,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 6, 7, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 6, 7, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 6, 7, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 6, 7, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 6, 7, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 6, 7, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 6, 7, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15, 8, 9,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 8, 9, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 8, 9, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 8, 9, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 8, 9, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 8, 9, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 8, 9, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 8, 9, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15, 8, 9, 6, 7,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 8, 9, 6, 7, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 8, 9, 6, 7, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 8, 9, 6, 7, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15, 8, 9, 6, 7, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15, 8, 9, 6, 7, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15, 8, 9, 6, 7, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1
    db 14,15, 8, 9, 6, 7, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1
    db 14,15,10,11,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 6, 7,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 6, 7, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 6, 7, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 6, 7, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 6, 7, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 6, 7, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 6, 7, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 6, 7, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1
    db 14,15,10,11, 8, 9,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 8, 9, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 8, 9, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 8, 9, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 8, 9, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 8, 9, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 8, 9, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 8, 9, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1
    db 14,15,10,11, 8, 9, 6, 7,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 8, 9, 6, 7, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 8, 9, 6, 7, 2, 3,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 8, 9, 6, 7, 2, 3, 0, 1,-1,-1,-1,-1
    db 14,15,10,11, 8, 9, 6, 7, 4, 5,-1,-1,-1,-1,-1,-1
    db 14,15,10,11, 8, 9, 6, 7, 4, 5, 0, 1,-1,-1,-1,-1
    db 14,15,10,11, 8, 9, 6, 7, 4, 5, 2, 3,-1,-1,-1,-1
    db 14,15,10,11, 8, 9, 6, 7, 4, 5, 2, 3, 0, 1,-1,-1
    db 14,15,12,13,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 6, 7,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 6, 7, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 6, 7, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 6, 7, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 6, 7, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 6, 7, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 6, 7, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 6, 7, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1
    db 14,15,12,13, 8, 9,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 8, 9, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 8, 9, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 8, 9, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 8, 9, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 8, 9, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 8, 9, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 8, 9, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1
    db 14,15,12,13, 8, 9, 6, 7,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 8, 9, 6, 7, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 8, 9, 6, 7, 2, 3,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 8, 9, 6, 7, 2, 3, 0, 1,-1,-1,-1,-1
    db 14,15,12,13, 8, 9, 6, 7, 4, 5,-1,-1,-1,-1,-1,-1
    db 14,15,12,13, 8, 9, 6, 7, 4, 5, 0, 1,-1,-1,-1,-1
    db 14,15,12,13, 8, 9, 6, 7, 4, 5, 2, 3,-1,-1,-1,-1
    db 14,15,12,13, 8, 9, 6, 7, 4, 5, 2, 3, 0, 1,-1,-1
    db 14,15,12,13,10,11,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 0, 1,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 2, 3,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 2, 3, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 4, 5,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 4, 5, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 4, 5, 2, 3,-1,-1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 4, 5, 2, 3, 0, 1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 6, 7,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 6, 7, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 6, 7, 2, 3,-1,-1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 6, 7, 2, 3, 0, 1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 6, 7, 4, 5,-1,-1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 6, 7, 4, 5, 0, 1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 6, 7, 4, 5, 2, 3,-1,-1,-1,-1
    db 14,15,12,13,10,11, 6, 7, 4, 5, 2, 3, 0, 1,-1,-1
    db 14,15,12,13,10,11, 8, 9,-1,-1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 8, 9, 0, 1,-1,-1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 8, 9, 2, 3,-1,-1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 8, 9, 2, 3, 0, 1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 8, 9, 4, 5,-1,-1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 8, 9, 4, 5, 0, 1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 8, 9, 4, 5, 2, 3,-1,-1,-1,-1
    db 14,15,12,13,10,11, 8, 9, 4, 5, 2, 3, 0, 1,-1,-1
    db 14,15,12,13,10,11, 8, 9, 6, 7,-1,-1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 8, 9, 6, 7, 0, 1,-1,-1,-1,-1
    db 14,15,12,13,10,11, 8, 9, 6, 7, 2, 3,-1,-1,-1,-1
    db 14,15,12,13,10,11, 8, 9, 6, 7, 2, 3, 0, 1,-1,-1
    db 14,15,12,13,10,11, 8, 9, 6, 7, 4, 5,-1,-1,-1,-1
    db 14,15,12,13,10,11, 8, 9, 6, 7, 4, 5, 0, 1,-1,-1
    db 14,15,12,13,10,11, 8, 9, 6, 7, 4, 5, 2, 3,-1,-1
    db 14,15,12,13,10,11, 8, 9, 6, 7, 4, 5, 2, 3, 0, 1   ; 255





%if HIGH_BIT_DEPTH==0
dct_coef_shuffle:
%macro DCT_COEF_SHUFFLE 8
    %assign y x
    %rep 8
        %rep 7
            %rotate (~(y>>7))&1
            %assign y y<<((~(y>>7))&1)
        %endrep
        db %1*2
        %rotate 1
        %assign y y<<1
    %endrep
%endmacro
%assign x 0
%rep 256
    DCT_COEF_SHUFFLE 7, 6, 5, 4, 3, 2, 1, 0
%assign x x+1
%endrep
%endif

SECTION .text

cextern pb_1
cextern pw_1
cextern pw_2
cextern pw_256
cextern pd_1
cextern pb_01
cextern pd_1024
cextern deinterleave_shufd
cextern popcnt_table


;=============================================================================
; dequant
;=============================================================================

%macro DEQUANT16_L 4
;;; %1      dct[y][x]
;;; %2,%3   dequant_mf[i_mf][y][x]
;;; m2      i_qbits
    mova     m0, %2
    packssdw m0, %3
%if mmsize==32
    vpermq   m0, m0, q3120
%endif
    pmullw   m0, %1
    psllw    m0, xm2
    mova     %1, m0
%endmacro

%macro DEQUANT32_R 4
;;; %1      dct[y][x]
;;; %2,%3   dequant_mf[i_mf][y][x]
;;; m2      -i_qbits
;;; m3      f
;;; m4      0
%if mmsize == 32
    pmovzxwd  m0, %1
    pmovzxwd  m1, %4
%else
    mova      m0, %1
    punpckhwd m1, m0, m4
    punpcklwd m0, m4
%endif
    pmadcswd  m0, m0, %2, m3
    pmadcswd  m1, m1, %3, m3
    psrad     m0, xm2
    psrad     m1, xm2
    packssdw  m0, m1
%if mmsize == 32
    vpermq    m0, m0, q3120
%endif
    mova      %1, m0
%endmacro

%macro DEQUANT_LOOP 3
%if 8*(%2-2*%3) > 0
    mov t0d, 8*(%2-2*%3)
%%loop:
    %1 [r0+(t0     )*SIZEOF_PIXEL], [r1+t0*2      ], [r1+t0*2+ 8*%3], [r0+(t0+ 4*%3)*SIZEOF_PIXEL]
    %1 [r0+(t0+8*%3)*SIZEOF_PIXEL], [r1+t0*2+16*%3], [r1+t0*2+24*%3], [r0+(t0+12*%3)*SIZEOF_PIXEL]
    sub t0d, 16*%3
    jge %%loop
    RET
%else
%if mmsize < 32
    %1 [r0+(8*%3)*SIZEOF_PIXEL], [r1+16*%3], [r1+24*%3], [r0+(12*%3)*SIZEOF_PIXEL]
%endif
    %1 [r0+(0   )*SIZEOF_PIXEL], [r1+0    ], [r1+ 8*%3], [r0+( 4*%3)*SIZEOF_PIXEL]
    RET
%endif
%endmacro

%macro DEQUANT16_FLAT 2-5
    mova   m0, %1
    psllw  m0, m4
%assign i %0-2
%rep %0-1
%if i
    mova   m %+ i, [r0+%2]
    pmullw m %+ i, m0
%else
    pmullw m0, [r0+%2]
%endif
    mova   [r0+%2], m %+ i
    %assign i i-1
    %rotate 1
%endrep
%endmacro

%if ARCH_X86_64
    DECLARE_REG_TMP 6,3,2
%else
    DECLARE_REG_TMP 2,0,1
%endif

%macro DEQUANT_START 2
    movifnidn t2d, r2m
    imul t0d, t2d, 0x2b
    shr  t0d, 8     ; i_qbits = i_qp / 6
    lea  t1d, [t0*5]
    sub  t2d, t0d
    sub  t2d, t1d   ; i_mf = i_qp % 6
    shl  t2d, %1
%if ARCH_X86_64
    add  r1, t2     ; dequant_mf[i_mf]
%else
    add  r1, r1mp   ; dequant_mf[i_mf]
    mov  r0, r0mp   ; dct
%endif
    sub  t0d, %2
    jl   .rshift32  ; negative qbits => rightshift
%endmacro

;-----------------------------------------------------------------------------
; void dequant_4x4( dctcoef dct[4][4], int dequant_mf[6][4][4], int i_qp )
;-----------------------------------------------------------------------------
%macro DEQUANT 3
cglobal dequant_%1x%1, 0,3,6
.skip_prologue:
    DEQUANT_START %2+2, %2

.lshift:
    movd xm2, t0d
    DEQUANT_LOOP DEQUANT16_L, %1*%1/4, %3

.rshift32:
    neg   t0d
    mova  m3, [pd_1]
    movd xm2, t0d
    pslld m3, xm2
    pxor  m4, m4
    psrld m3, 1
    DEQUANT_LOOP DEQUANT32_R, %1*%1/4, %3

%if HIGH_BIT_DEPTH == 0 && (notcpuflag(avx) || mmsize == 32)
cglobal dequant_%1x%1_flat16, 0,3
    movifnidn t2d, r2m
%if %1 == 8
    cmp  t2d, 12
    jl dequant_%1x%1 %+ SUFFIX %+ .skip_prologue
    sub  t2d, 12
%endif
    imul t0d, t2d, 0x2b
    shr  t0d, 8     ; i_qbits = i_qp / 6
    lea  t1d, [t0*5]
    sub  t2d, t0d
    sub  t2d, t1d   ; i_mf = i_qp % 6
    shl  t2d, %2
%if ARCH_X86_64
    lea  r1, [dequant%1_scale]
    add  r1, t2
%else
    lea  r1, [dequant%1_scale + t2]
%endif
    movifnidn r0, r0mp
    movd xm4, t0d
%if %1 == 4
%if mmsize == 8
    DEQUANT16_FLAT [r1], 0, 16
    DEQUANT16_FLAT [r1+8], 8, 24
%elif mmsize == 16
    DEQUANT16_FLAT [r1], 0, 16
%else
    vbroadcasti128 m0, [r1]
    psllw  m0, xm4
    pmullw m0, [r0]
    mova [r0], m0
%endif
%elif mmsize == 8
    DEQUANT16_FLAT [r1], 0, 8, 64, 72
    DEQUANT16_FLAT [r1+16], 16, 24, 48, 56
    DEQUANT16_FLAT [r1+16], 80, 88, 112, 120
    DEQUANT16_FLAT [r1+32], 32, 40, 96, 104
%elif mmsize == 16
    DEQUANT16_FLAT [r1], 0, 64
    DEQUANT16_FLAT [r1+16], 16, 48, 80, 112
    DEQUANT16_FLAT [r1+32], 32, 96
%else
    mova   m1, [r1+ 0]
    mova   m2, [r1+32]
    psllw  m1, xm4
    psllw  m2, xm4
    pmullw m0, m1, [r0+ 0]
    pmullw m3, m2, [r0+32]
    pmullw m4, m1, [r0+64]
    pmullw m5, m2, [r0+96]
    mova [r0+ 0], m0
    mova [r0+32], m3
    mova [r0+64], m4
    mova [r0+96], m5
%endif
    RET
%endif ; !HIGH_BIT_DEPTH && !AVX
%endmacro ; DEQUANT


%macro DEQUANT_START_AVX512 1-2 0 ; shift, flat
%if %2 == 0
    movifnidn t2d, r2m
%endif
    imul t0d, t2d, 0x2b
    shr  t0d, 8     ; i_qbits = i_qp / 6
    lea  t1d, [t0*5]
    sub  t2d, t0d
    sub  t2d, t1d   ; i_mf = i_qp % 6
    shl  t2d, %1
%if %2
%if ARCH_X86_64
%define dmf r1+t2
    lea   r1, [dequant8_scale]
%else
%define dmf t2+dequant8_scale
%endif
%elif ARCH_X86_64
%define dmf r1+t2
%else
%define dmf r1
    add  r1, r1mp   ; dequant_mf[i_mf]
%endif
    movifnidn r0, r0mp
%endmacro


%undef dmf

%macro DEQUANT_DC 2
cglobal dequant_4x4dc, 0,3,6
    DEQUANT_START 6, 6

.lshift:
%if cpuflag(avx2)
    vpbroadcastdct m3, [r1]
%else
    movd    xm3, [r1]
    SPLAT%1  m3, xm3
%endif
    movd    xm2, t0d
    pslld    m3, xm2
%assign %%x 0
%rep SIZEOF_PIXEL*32/mmsize
    %2       m0, m3, [r0+%%x]
    mova     [r0+%%x], m0
%assign %%x %%x+mmsize
%endrep
    RET

.rshift32:
    neg      t0d
%if cpuflag(avx2)
    vpbroadcastdct m2, [r1]
%else
    movd     xm2, [r1]
%endif
    mova      m5, [p%1_1]
    movd     xm3, t0d
    pslld     m4, m5, xm3
    psrld     m4, 1
%if notcpuflag(avx2)
    PSHUFLW   m2, m2, 0
%endif
    punpcklwd m2, m4
%assign %%x 0
%rep SIZEOF_PIXEL*32/mmsize
    mova      m0, [r0+%%x]
    punpckhwd m1, m0, m5
    punpcklwd m0, m5
    pmaddwd   m0, m2
    pmaddwd   m1, m2
    psrad     m0, xm3
    psrad     m1, xm3
    packssdw  m0, m1
    mova      [r0+%%x], m0
%assign %%x %%x+mmsize
%endrep
    RET
%endmacro


;-----------------------------------------------------------------------------
; int coeff_last( dctcoef *dct )
;-----------------------------------------------------------------------------

%macro BSR 3
%if cpuflag(lzcnt)
    lzcnt %1, %2
    xor %1, %3
%else
    bsr %1, %2
%endif
%endmacro

%macro LZCOUNT 3
%if cpuflag(lzcnt)
    lzcnt %1, %2
%else
    bsr %1, %2
    xor %1, %3
%endif
%endmacro

%macro LAST_MASK 3-4
%if %1 <= 8
    movq     mm0, [%3+ 0]
%if %1 == 4
    packsswb mm0, mm0
%else
    packsswb mm0, [%3+ 8]
%endif
    pcmpeqb  mm0, mm2
    pmovmskb  %2, mm0
%elif mmsize == 16
    movdqa   xmm0, [%3+ 0]
    packsswb xmm0, [%3+16]
    pcmpeqb  xmm0, xmm2
    pmovmskb   %2, xmm0
%else
    movq     mm0, [%3+ 0]
    movq     mm1, [%3+16]
    packsswb mm0, [%3+ 8]
    packsswb mm1, [%3+24]
    pcmpeqb  mm0, mm2
    pcmpeqb  mm1, mm2
    pmovmskb  %2, mm0
    pmovmskb  %4, mm1
    shl       %4, 8
    or        %2, %4
%endif
%endmacro

%macro COEFF_LAST48 0
%if ARCH_X86_64
cglobal coeff_last4, 1,1
    BSR  rax, [r0], 0x3f
    shr  eax, 4
    RET
%else
cglobal coeff_last4, 0,3
    mov   edx, r0mp
    mov   eax, [edx+4]
    xor   ecx, ecx
    test  eax, eax
    cmovz eax, [edx]
    setnz cl
    BSR   eax, eax, 0x1f
    shr   eax, 4
    lea   eax, [eax+ecx*2]
    RET
%endif

cglobal coeff_last8, 1,3
    pxor m2, m2
    LAST_MASK 8, r1d, r0, r2d
    xor r1d, 0xff
    BSR eax, r1d, 0x1f
    RET
%endmacro

INIT_MMX mmx2
COEFF_LAST48
INIT_MMX lzcnt
COEFF_LAST48

%macro COEFF_LAST 0
cglobal coeff_last15, 1,3
    pxor m2, m2
    LAST_MASK 15, r1d, r0-SIZEOF_DCTCOEF, r2d
    xor r1d, 0xffff
    BSR eax, r1d, 0x1f
    dec eax
    RET

cglobal coeff_last16, 1,3
    pxor m2, m2
    LAST_MASK 16, r1d, r0, r2d
    xor r1d, 0xffff
    BSR eax, r1d, 0x1f
    RET

%if ARCH_X86_64 == 0
cglobal coeff_last64, 1, 4-mmsize/16
    pxor m2, m2
    LAST_MASK 16, r1d, r0+SIZEOF_DCTCOEF* 32, r3d
    LAST_MASK 16, r2d, r0+SIZEOF_DCTCOEF* 48, r3d
    shl r2d, 16
    or  r1d, r2d
    xor r1d, -1
    jne .secondhalf
    LAST_MASK 16, r1d, r0+SIZEOF_DCTCOEF* 0, r3d
    LAST_MASK 16, r2d, r0+SIZEOF_DCTCOEF*16, r3d
    shl r2d, 16
    or  r1d, r2d
    not r1d
    BSR eax, r1d, 0x1f
    RET
.secondhalf:
    BSR eax, r1d, 0x1f
    add eax, 32
    RET
%else
cglobal coeff_last64, 1,3
    pxor m2, m2
    LAST_MASK 16, r1d, r0+SIZEOF_DCTCOEF* 0
    LAST_MASK 16, r2d, r0+SIZEOF_DCTCOEF*16
    shl r2d, 16
    or  r1d, r2d
    LAST_MASK 16, r2d, r0+SIZEOF_DCTCOEF*32
    LAST_MASK 16, r0d, r0+SIZEOF_DCTCOEF*48
    shl r0d, 16
    or  r2d, r0d
    shl  r2, 32
    or   r1, r2
    not  r1
    BSR rax, r1, 0x3f
    RET
%endif
%endmacro

%if ARCH_X86_64 == 0
INIT_MMX mmx2
COEFF_LAST
%endif
INIT_XMM sse2
COEFF_LAST
INIT_XMM lzcnt
COEFF_LAST

%macro LAST_MASK_AVX2 2
    mova     m0, [%2+ 0]
    packsswb m0, [%2+32]
    vpermq   m0, m0, q3120
    pcmpeqb  m0, m2
    pmovmskb %1, m0
%endmacro

%macro COEFF_LAST_AVX512 2 ; num, w/d
cglobal coeff_last%1, 1,2
    mova         m0, [r0-(%1&1)*SIZEOF_DCTCOEF]
    vptestm%2    k0, m0, m0
%if %1 == 15
    mov         eax, 30
    kmovw       r1d, k0
    lzcnt       r1d, r1d
    sub         eax, r1d
%else
    kmovw       eax, k0
    lzcnt       eax, eax
    xor         eax, 31
%endif
    RET
%endmacro

%macro COEFF_LAST64_AVX512 1 ; w/d
cglobal coeff_last64, 1,2
    pxor        xm0, xm0
    vpcmp%1      k0, m0, [r0+0*64], 4
    vpcmp%1      k1, m0, [r0+1*64], 4
%if ARCH_X86_64
    kunpckdq     k0, k1, k0
    kmovq       rax, k0
    lzcnt       rax, rax
    xor         eax, 63
%else
    kmovd       r1d, k1
    kmovd       eax, k0
    lzcnt       r1d, r1d
    lzcnt       eax, eax
    xor         r1d, 32
    cmovnz      eax, r1d
    xor         eax, 31
%endif
    RET
%endmacro

INIT_XMM avx512
COEFF_LAST_AVX512  8, w
INIT_YMM avx512
COEFF_LAST_AVX512 15, w
COEFF_LAST_AVX512 16, w
INIT_ZMM avx512
COEFF_LAST64_AVX512 w

;-----------------------------------------------------------------------------
; int coeff_level_run( dctcoef *dct, run_level_t *runlevel )
;-----------------------------------------------------------------------------

struc levelrun
    .last: resd 1
    .mask: resd 1
    align 16, resb 1
    .level: resw 16
endstruc

; t6 = eax for return, t3 = ecx for shift, t[01] = r[01] for x86_64 args
%if WIN64
    DECLARE_REG_TMP 3,1,2,0,4,5,6
%elif ARCH_X86_64
    DECLARE_REG_TMP 0,1,2,3,4,5,6
%else
    DECLARE_REG_TMP 6,3,2,1,4,5,0
%endif

%macro COEFF_LEVELRUN 1
cglobal coeff_level_run%1,0,7
    movifnidn t0, r0mp
    movifnidn t1, r1mp
    pxor    m2, m2
    xor    t3d, t3d
    LAST_MASK %1, t5d, t0-(%1&1)*SIZEOF_DCTCOEF, t4d
%if %1==15
    shr    t5d, 1
%elif %1==8
    and    t5d, 0xff
%elif %1==4
    and    t5d, 0xf
%endif
    xor    t5d, (1<<%1)-1
    mov [t1+levelrun.mask], t5d
    shl    t5d, 32-%1
    mov    t4d, %1-1
    LZCOUNT t3d, t5d, 0x1f
    xor    t6d, t6d
    add    t5d, t5d
    sub    t4d, t3d
    shl    t5d, t3b
    mov [t1+levelrun.last], t4d
.loop:
    LZCOUNT t3d, t5d, 0x1f
    mov    t2w, [t0+t4*2]
    inc    t3d
    shl    t5d, t3b
    mov   [t1+t6*2+levelrun.level], t2w
    inc    t6d
    sub    t4d, t3d
    jge .loop
    RET
%endmacro

INIT_MMX mmx2
%if ARCH_X86_64 == 0
COEFF_LEVELRUN 15
COEFF_LEVELRUN 16
%endif
COEFF_LEVELRUN 4
COEFF_LEVELRUN 8
INIT_XMM sse2
COEFF_LEVELRUN 15
COEFF_LEVELRUN 16
INIT_MMX lzcnt
COEFF_LEVELRUN 4
COEFF_LEVELRUN 8
INIT_XMM lzcnt
COEFF_LEVELRUN 15
COEFF_LEVELRUN 16

; Similar to the one above, but saves the DCT
; coefficients in m0/m1 so we don't have to load
; them later.
%macro LAST_MASK_LUT 3
    pxor     xm5, xm5
%if %1 <= 8
    mova      m0, [%3]
    packsswb  m2, m0, m0
%else
    mova     xm0, [%3+ 0]
    mova     xm1, [%3+16]
    packsswb xm2, xm0, xm1
%if mmsize==32
    vinserti128 m0, m0, xm1, 1
%endif
%endif
    pcmpeqb  xm2, xm5
    pmovmskb  %2, xm2
%endmacro

%macro COEFF_LEVELRUN_LUT 1
cglobal coeff_level_run%1,2,4+(%1/9)
%if ARCH_X86_64
    lea       r5, [$$]
    %define GLOBAL +r5-$$
%else
    %define GLOBAL
%endif
    LAST_MASK_LUT %1, eax, r0-(%1&1)*SIZEOF_DCTCOEF
%if %1==15
    shr     eax, 1
%elif %1==8
    and     eax, 0xff
%elif %1==4
    and     eax, 0xf
%endif
    xor     eax, (1<<%1)-1
    mov [r1+levelrun.mask], eax
%if %1==15
    add     eax, eax
%endif
%if %1 > 8
%if ARCH_X86_64
    mov     r4d, eax
    shr     r4d, 8
%else
    movzx   r4d, ah ; first 8 bits
%endif
%endif
    movzx   r2d, al ; second 8 bits
    shl     eax, 32-%1-(%1&1)
    LZCOUNT eax, eax, 0x1f
    mov     r3d, %1-1
    sub     r3d, eax
    mov [r1+levelrun.last], r3d
; Here we abuse pshufb, combined with a lookup table, to do a gather
; operation based on a bitmask. For example:
;
; dct 15-8 (input): 0  0  4  0  0 -2  1  0
; dct  7-0 (input): 0  0 -1  0  0  0  0 15
; bitmask 1:        0  0  1  0  0  1  1  0
; bitmask 2:        0  0  1  0  0  0  0  1
; gather 15-8:      4 -2  1 __ __ __ __ __
; gather  7-0:     -1 15 __ __ __ __ __ __
; levels (output):  4 -2  1 -1 15 __ __ __ __ __ __ __ __ __ __ __
;
; The overlapping, dependent stores almost surely cause a mess of
; forwarding issues, but it's still enormously faster.
%if %1 > 8
    movzx   eax, byte [popcnt_table+r4 GLOBAL]
    movzx   r3d, byte [popcnt_table+r2 GLOBAL]
%if mmsize==16
    movh      m3, [dct_coef_shuffle+r4*8 GLOBAL]
    movh      m2, [dct_coef_shuffle+r2*8 GLOBAL]
    mova      m4, [pw_256]
; Storing 8 bytes of shuffle constant and converting it (unpack + or)
; is neutral to slightly faster in local speed measurements, but it
; cuts the table size in half, which is surely a big cache win.
    punpcklbw m3, m3
    punpcklbw m2, m2
    por       m3, m4
    por       m2, m4
    pshufb    m1, m3
    pshufb    m0, m2
    mova [r1+levelrun.level], m1
; This obnoxious unaligned store messes with store forwarding and
; stalls the CPU to no end, but merging the two registers before
; storing requires a variable 128-bit shift. Emulating this does
; work, but requires a lot of ops and the gain is tiny and
; inconsistent, so we'll err on the side of fewer instructions.
    movu [r1+rax*2+levelrun.level], m0
%else ; mmsize==32
    movq     xm2, [dct_coef_shuffle+r4*8 GLOBAL]
    vinserti128 m2, m2, [dct_coef_shuffle+r2*8 GLOBAL], 1
    punpcklbw m2, m2
    por       m2, [pw_256]
    pshufb    m0, m2
    vextracti128 [r1+levelrun.level], m0, 1
    movu [r1+rax*2+levelrun.level], xm0
%endif
    add     eax, r3d
%else
    movzx   eax, byte [popcnt_table+r2 GLOBAL]
    movh m1, [dct_coef_shuffle+r2*8 GLOBAL]
    punpcklbw m1, m1
    por       m1, [pw_256]
    pshufb    m0, m1
    mova [r1+levelrun.level], m0
%endif
    RET
%endmacro

INIT_MMX ssse3
COEFF_LEVELRUN_LUT 4
INIT_XMM ssse3
COEFF_LEVELRUN_LUT 8
COEFF_LEVELRUN_LUT 15
COEFF_LEVELRUN_LUT 16
INIT_MMX ssse3, lzcnt
COEFF_LEVELRUN_LUT 4
INIT_XMM ssse3, lzcnt
COEFF_LEVELRUN_LUT 8
COEFF_LEVELRUN_LUT 15
COEFF_LEVELRUN_LUT 16


;=============================================================================
; quant
;=============================================================================
INIT_YMM avx2
cglobal quant_4x4, 0, 0
    vmovdqu        m0, [r0]
    vpabsw         m1, m0
    vpaddusw       m1, m1, [r2]
    vpmulhuw       m1, m1, [r1]
    vpsignw        m1, m1, m0
    vmovdqu        [r0], m1

    xor            eax, eax
    vptest         m1, m1
    setnz          al
    RET
    
INIT_YMM avx2
cglobal quant_8x8, 0, 0
    vmovdqu        m0, [r0]
    vmovdqu        m1, [r0 + 32]
    vpabsw         m2, m0
    vpabsw         m3, m1
    vpaddusw       m2, m2, [r2]
    vpaddusw       m3, m3, [r2 + 32]
    vpmulhuw       m2, m2, [r1]
    vpmulhuw       m3, m3, [r1 + 32]
    vpsignw        m2, m2, m0
    vpsignw        m3, m3, m1
    vmovdqu        [r0], m2
    vmovdqu        [r0 + 32], m3
    vpor           m4, m2, m3

    vmovdqu        m0, [r0 + 64]
    vmovdqu        m1, [r0 + 96]
    vpabsw         m2, m0
    vpabsw         m3, m1
    vpaddusw       m2, m2, [r2 + 64]
    vpaddusw       m3, m3, [r2 + 96]
    vpmulhuw       m2, m2, [r1 + 64]
    vpmulhuw       m3, m3, [r1 + 96]
    vpsignw        m2, m2, m0
    vpsignw        m3, m3, m1
    vmovdqu        [r0 + 64], m2
    vmovdqu        [r0 + 96], m3
    vpor           m5, m2, m3

    vpor           m4, m4, m5
    xor            eax, eax
    vptest         m4, m4
    setnz          al
    RET

INIT_YMM avx2
cglobal quant_4x4x4, 0, 0
    vmovdqu        m0, [r2]            ; bias
    vmovdqu        m1, [r1]            ; mf

    vmovdqu        m2, [r0]
    vmovdqu        m3, [r0 + 32]
    vpabsw         m4, m2
    vpabsw         m5, m3
    vpaddusw       m4, m4, m0
    vpaddusw       m5, m5, m0
    vpmulhuw       m4, m4, m1
    vpmulhuw       m5, m5, m1
    vpsignw        m4, m4, m2
    vpsignw        m5, m5, m3
    vmovdqu        [r0], m4
    vmovdqu        [r0 + 32], m5
    vpackssdw      m5, m4, m5

    vmovdqu        m2, [r0 + 64]
    vpabsw         m3, m2
    vpaddusw       m3, m3, m0
    vpmulhuw       m3, m3, m1
    vpsignw        m4, m3, m2
    vmovdqu        [r0 + 64], m4
    vmovdqu        m2, [r0 + 96]
    vpabsw         m3, m2
    vpaddusw       m3, m3, m0
    vpmulhuw       m3, m3, m1
    vpsignw        m3, m3, m2
    vmovdqu        [r0 + 96], m3
    vpackssdw      m3, m4, m3

    vpackssdw      m0, m5, m3
    vpxor          m1, m1, m1
    vpcmpeqd       m0, m0, m1
    vmovmskps      eax, m0             ; bit set for zero
    mov            r0d, eax
    shr            eax, 4
    and            eax, r0d            ; zero out high bits, low bits "or" for non-zero
    xor            eax, 0Fh            ; neg low bits, bit set for non-zero
    RET

INIT_XMM avx2
cglobal quant_2x2_dc, 0, 0
    vmovd          m0, r1d             ; mf
    vmovd          m1, r2d             ; bias
    vpbroadcastw   m0, m0
    vpbroadcastw   m1, m1
    vmovq          m2, [r0]
    vpabsw         m3, m2
    vpaddusw       m3, m3, m1
    vpmulhuw       m3, m3, m0
    vpsignw        m3, m3, m2
    vmovq          [r0], m3
    xor            eax, eax
    vmovq          r0, m3
    test           r0, r0
    setnz          al
    ret

INIT_YMM avx2
cglobal quant_4x4_dc, 0, 0
    vmovd          xm0, r1d            ; mf
    vmovd          xm1, r2d            ; bias
    vpbroadcastw   m0, xm0
    vpbroadcastw   m1, xm1
    vmovdqu        m2, [r0]
    vpabsw         m3, m2
    vpaddusw       m3, m3, m1
    vpmulhuw       m3, m3, m0
    vpsignw        m3, m3, m2
    vmovdqu        [r0], m3
    xor            eax, eax
    vptest         m3, m3
    setnz          al
    RET


;=============================================================================
; dequant
;=============================================================================
INIT_YMM avx2
cglobal dequant_4x4, 0, 0
    ; 6 bits are enough for qp, replace div with mul
    imul           r6d, r1d, 43
    shr            r6d, 8              ; i_qp / 6, mulh >> 2
    lea            r3d, [r6 + r6 * 4]
    sub            r1d, r6d
    sub            r1d, r3d            ; i_mf -> i_qp - 6 * quotient
    shl            r1d, 4              ; each row has a stride of 16B
    lea            r2, [dequant4_scale]

    ; mf = scale * 16 = scale << 4, so we can eliminate rshift
    vmovd          xm1, r6d
    vbroadcasti128 m0, [r2 + r1]
    vpsllw         m0, m0, xm1
    vpmullw        m0, m0, [r0]
    vmovdqu        [r0], m0
    RET

INIT_YMM avx2
cglobal dequant_8x8, 0, 0
    ; 6 bits are enough for qp, replace div with mul
    imul           r6d, r1d, 43
    shr            r6d, 8              ; i_qp / 6, mulh >> 2
    lea            r3d, [r6 + r6 * 4]
    sub            r1d, r6d
    sub            r1d, r3d            ; i_mf -> i_qp - 6 * quotient
    sub            r6d, 2              ; may shift right
    jl             .rshift

; lshift
    shl            r1d, 6              ; each row has a stride of 64B
    lea            r2, [dequant8_scale]
    vmovd          xm0, r6d
    vmovdqu        m1, [r2 + r1]
    vmovdqu        m2, [r2 + r1 + 32]
    vpsllw         m1, m1, xm0
    vpsllw         m2, m2, xm0
    vpmullw        m3, m1, [r0]
    vpmullw        m4, m2, [r0 + 32]
    vpmullw        m1, m1, [r0 + 64]
    vpmullw        m2, m2, [r0 + 96]
    vmovdqu        [r0], m3
    vmovdqu        [r0 + 32], m4
    vmovdqu        [r0 + 64], m1
    vmovdqu        [r0 + 96], m2
    RET

.rshift:
    shl            r1d, 7              ; each row has a stride of 128B
    lea            r2, [dequant8_scale_dword]
    neg            r6d
    vmovd          xm0, r6d
    vpcmpeqw       m1, m1, m1
    vpslld         m1, m1, xm0
    vpsrad         m1, m1, 1           ; -f

    ; vpmulld is slow, use vpmaddwd with zero-extend instead
    vpmovzxwd      m4, [r0]
    vpmovzxwd      m5, [r0 + 16]
    vpmaddwd       m4, m4, [r2 + r1]
    vpmaddwd       m5, m5, [r2 + r1 + 32]
    vpsubd         m4, m4, m1
    vpsubd         m5, m5, m1
    vpsrad         m4, m4, xm0
    vpsrad         m5, m5, xm0
    vpackssdw      m4, m4, m5
    vpermq         m4, m4, q3120
    vmovdqu        [r0], m4
    vpmovzxwd      m4, [r0 + 32]
    vpmovzxwd      m5, [r0 + 48]
    vpmaddwd       m4, m4, [r2 + r1 + 64]
    vpmaddwd       m5, m5, [r2 + r1 + 96]
    vpsubd         m4, m4, m1
    vpsubd         m5, m5, m1
    vpsrad         m4, m4, xm0
    vpsrad         m5, m5, xm0
    vpackssdw      m4, m4, m5
    vpermq         m4, m4, q3120
    vmovdqu        [r0 + 32], m4
    vpmovzxwd      m4, [r0 + 64]
    vpmovzxwd      m5, [r0 + 80]
    vpmaddwd       m4, m4, [r2 + r1]
    vpmaddwd       m5, m5, [r2 + r1 + 32]
    vpsubd         m4, m4, m1
    vpsubd         m5, m5, m1
    vpsrad         m4, m4, xm0
    vpsrad         m5, m5, xm0
    vpackssdw      m4, m4, m5
    vpermq         m4, m4, q3120
    vmovdqu        [r0 + 64], m4
    vpmovzxwd      m4, [r0 + 96]
    vpmovzxwd      m5, [r0 + 112]
    vpmaddwd       m4, m4, [r2 + r1 + 64]
    vpmaddwd       m5, m5, [r2 + r1 + 96]
    vpsubd         m4, m4, m1
    vpsubd         m5, m5, m1
    vpsrad         m4, m4, xm0
    vpsrad         m5, m5, xm0
    vpackssdw      m4, m4, m5
    vpermq         m4, m4, q3120
    vmovdqu        [r0 + 96], m4
    RET

INIT_YMM avx2
cglobal dequant_4x4_dc, 0, 0
    ; 6 bits are enough for qp, replace div with mul
    imul           r6d, r1d, 43
    shr            r6d, 8              ; i_qp / 6, mulh >> 2
    lea            r3d, [r6 + r6 * 4]
    sub            r1d, r6d
    sub            r1d, r3d            ; i_mf -> i_qp - 6 * quotient
    shl            r1d, 4              ; each row has a stride of 16B
    lea            r2, [dequant4_scale]
    sub            r6d, 2              ; may shift right
    jl             .rshift

; lshift
    vmovd          xm1, r6d
    vpbroadcastw   m0, [r2 + r1]
    vpsllw         m0, m0, xm1
    vpmullw        m0, m0, [r0]
    vmovdqu        [r0], m0
    RET

.rshift:
    neg            r6d
    vmovd          xm0, r6d
    vpcmpeqw       m1, m1, m1
    vpsllw         m1, m1, xm0
    vpsraw         m1, m1, 1           ; -f
    vpbroadcastw   m2, [r2 + r1]       ; no overflow for dc
    vpmullw        m2, m2, [r0]
    vpsubw         m2, m2, m1
    vpsraw         m2, m2, xm0
    vmovdqu        [r0], m2
    RET


;=============================================================================
; idct_dequant
;=============================================================================
INIT_XMM avx2
cglobal idct_dequant_2x4_dc, 0, 0
    imul           r6d, r2d, 43
    shr            r6d, 8              ; i_qp / 6, mulh >> 2
    lea            r3d, [r6 + r6 * 4]
    sub            r2d, r6d
    sub            r2d, r3d            ; i_mf -> i_qp - 6 * quotient
    lea            r3, [idct_dequant4_scale]

    ; idct last stage
    vmovq          m0, [r0]
    vmovq          m1, [r0 + 8]
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    ; idct middle stage
    vpunpcklqdq    m0, m2, m3          ; a0 a1 a2 a3 a4 a5 a6 a7
    vshufps        m1, m2, m3, 11h     ; a2 a3 a0 a1 a6 a7 a4 a5
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpshufd        m3, m3, 0Ah         ; rearrange for the final result
    ; idct first stage
    vpbroadcastq   m4, [r3 + r2 * 8]
    sub            r6d, 2              ; may shift right
    jl             .rshift

    vmovd          m5, r6d
    vpsllw         m4, m4, m5          ; dmf
    vpmaddwd       m2, m2, m4
    vpmaddwd       m3, m3, m4
    jmp            .end

ALIGN 16
.rshift:
    vpmaddwd       m2, m2, m4
    vpmaddwd       m3, m3, m4
    neg            r6d
    vmovd          m0, r6d
    vpcmpeqd       m1, m1, m1
    vpslld         m1, m1, m0
    vpsrad         m1, m1, 1
    vpsubd         m2, m2, m1
    vpsubd         m3, m3, m1
    vpsrad         m2, m2, m0
    vpsrad         m3, m3, m0
.end:
    vpextrw        [r1], m2, 0
    vpextrw        [r1 + 32], m2, 2
    vpextrw        [r1 + 64], m2, 4
    vpextrw        [r1 + 96], m2, 6
    add            r1, 128
    vpextrw        [r1], m3, 0
    vpextrw        [r1 + 32], m3, 2
    vpextrw        [r1 + 64], m3, 4
    vpextrw        [r1 + 96], m3, 6
    ret

INIT_XMM avx2
cglobal idct_dequant_2x4_dconly, 0, 0
    imul           r6d, r1d, 43
    shr            r6d, 8              ; i_qp / 6, mulh >> 2
    lea            r3d, [r6 + r6 * 4]
    sub            r1d, r6d
    sub            r1d, r3d            ; i_mf -> i_qp - 6 * quotient
    lea            r3, [idct_dequant4_scale]

    ; idct last stage
    vmovq          m0, [r0]
    vmovq          m1, [r0 + 8]
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    ; idct middle stage
    vpunpcklqdq    m0, m2, m3          ; a0 a1 a2 a3 a4 a5 a6 a7
    vshufps        m1, m2, m3, 11h     ; a2 a3 a0 a1 a6 a7 a4 a5
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpshufd        m3, m3, 0Ah         ; rearrange for the final result
    ; idct first stage
    vpbroadcastq   m4, [r3 + r1 * 8]
    sub            r6d, 2              ; may shift right
    jl             .rshift

    vmovd          m5, r6d
    vpsllw         m4, m4, m5          ; dmf
    vpmaddwd       m2, m2, m4
    vpmaddwd       m3, m3, m4
    vpackssdw      m2, m2, m3
    vmovdqu        [r0], m2
    ret

ALIGN 16
.rshift:
    vpmaddwd       m2, m2, m4
    vpmaddwd       m3, m3, m4
    neg            r6d
    vmovd          m0, r6d
    vpcmpeqd       m1, m1, m1
    vpslld         m1, m1, m0
    vpsrad         m1, m1, 1
    vpsubd         m2, m2, m1
    vpsubd         m3, m3, m1
    vpsrad         m2, m2, m0
    vpsrad         m3, m3, m0
    vpackssdw      m2, m2, m3
    vmovdqu        [r0], m2
    ret


;=============================================================================
; optimize_chroma
;=============================================================================
INIT_XMM avx2
cglobal optimize_chroma_2x2_dc, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], m6
%endif
    vpbroadcastq   m0, [r0]            ; dct  0 1 2 3  0 1 2 3
    vmovd          m1, r1d             ; dequant_mf
    vpcmpeqb       m2, m2, m2
    vpslld         m2, m2, 11          ; mask for early skip check
    vpbroadcastw   m1, m1
    vpshufd        m3, m0, q0101       ; dct  2 3 0 1  2 3 0 1
    vpbroadcastd   m4, [pd_1024]       ; 32 << 5
    vpbroadcastq   m5, [chroma_dc_dct_mask]
    vpsignw        m3, m3, m5          ; dct  2 3 -0 -1  2 3 -0 -1
    vpsignw        m1, m1, [chroma_dc_dmf_mask]  ; mf  + + - -  + - - +
    vpaddw         m3, m0, m3          ; dct  0+2 1+3 -(0-2) -(1-3) ...
    vpmaddwd       m3, m3, m1          ; (dct[0] dct[1] dct[2] dct[3]) * mf (without + 32)
    vpaddd         m3, m3, m4          ; dct_orig
    vpunpcklwd     m0, m0, m0          ; dct 0 0 1 1 2 2 3 3
    vpsrad         m1, m1, 16          ; mf + - - +
    xor            r6d, r6d            ; nz = 0
    vptest         m3, m2
    jz             .ret                ; early skip
    mov            r1d, 3              ; coeff = 3
    vmovdqu        m4, m3
.outer_loop:
    movsx          r2d, word [r0 + r1 * 2]  ; dct[coeff]
    vpshufd        m5, m0, q3333       ; take the highest element
    vpshufd        m0, m0, q2100       ; move the next element to high dword
    vpsignd        m5, m1, m5          ; sign * mf, for rounding
    test           r2d, r2d
    jz             .loop_end           ; if (level == 0) goto the next coeff
    mov            r3d, r2d
    sar            r2d, 31
    or             r2d, 1
.inner_loop:
    vpsubd         m4, m4, m5          ; round and then check inner "if"
    vpxor          m6, m4, m3
    vptest         m6, m2
    jnz            .inner_break
    sub            r3d, r2d            ; level -= sign
    mov            [r0 + r1 * 2], r3w
    jnz            .inner_loop
    jmp            .loop_end
.inner_break:
    vpaddd         m4, m4, m5          ; reverse the last rounding
    mov            r6d, 1
.loop_end:
    dec            r1d
    jz             .last_coeff
    vpshufd        m1, m1, q1320       ; mf + - + - / + + - -
    jmp            .outer_loop

ALIGN 16
.last_coeff:
    movsx          r2d, word [r0]
    vpunpcklqdq    m1, m1, m1          ; mf + + + +
    vpsignd        m5, m1, m0
    test           r2d, r2d
    jz             .ret

    mov            r3d, r2d
    sar            r2d, 31
    or             r2d, 1
.inner_loop2:
    vpsubd         m4, m4, m5          ; round and then check inner "if"
    vpxor          m6, m4, m3
    vptest         m6, m2
    jnz            .inner_break2

    sub            r3d, r2d            ; level -= sign
    mov            [r0 + r1 * 2], r3w
    jnz            .inner_loop2
    jmp            .ret
.inner_break2:
    mov            r6d, 1
    
.ret:
%if WIN64
    vmovdqu        m6, [rsp + 8]
%endif
    ret


INIT_YMM avx2
cglobal optimize_chroma_2x4_dc, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 40
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
%endif
    vmovq          xm0, [r0]           ; dct  0 1 2 3
    vmovq          xm1, [r0 + 8]       ; dct  4 5 6 7
    vinserti128    m5, m0, xm1, 1      ; dct  0 1 2 3 | 4 5 6 7
    vpunpcklwd     m5, m5, m5
    vpaddw         xm2, xm0, xm1
    vpsubw         xm3, xm0, xm1
    vpunpckldq     xm0, xm2, xm3
    vpunpckhqdq    xm1, xm0, xm0
    vpaddw         xm2, xm0, xm1
    vpsubw         xm3, xm0, xm1
    vpshufd        xm3, xm3, q0001
    vinserti128    m0, m2, xm3, 1
    vpunpckldq     m0, m0, m0
    vmovd          xm1, r1d            ; dequant_mf
    vpbroadcastw   m1, xm1
    vpbroadcastq   m2, [chroma_dc_dmf_2x4_mask]
    vpsignw        m1, m1, m2          ; mf + + + - ...
    vpmaddwd       m0, m0, m1
    vpbroadcastd   m4, [pd_2080]
    vpaddd         m0, m0, m4          ; dct_orig
    vpunpcklwd     xm1, xm1, xm1
    vpsrad         xm1, xm1, 16        ; mf + + + -
    xor            r6d, r6d            ; nz = 0
    vpcmpeqb       m2, m2, m2
    vpslld         m2, m2, 12          ; mask for early skip check
    vptest         m0, m2
    jz             .ret                ; early skip
    mov            r1d, 7              ; coeff = 7
    vmovdqu        m3, m0
    lea            r4, [chroma_dc_mf_perm]
    vpbroadcastd   m6, [pd_7]
    vpsrld         m7, m6, 2           ; pd_1
.outer_loop:
    movsx          r2d, word [r0 + r1 * 2]  ; dct[coeff]
    vpermd         m4, m6, m5          ; take the highest element
    mov            r5d, r1d
    shl            r5d, 5
    vmovdqu        m8, [r4 + r5]
    vpermd         m8, m8, m1
    vpsignd        m8, m8, m4          ; sign * mf, for rounding
    test           r2d, r2d
    jz             .loop_end           ; if (level == 0) goto the next coeff
    mov            r3d, r2d
    sar            r2d, 31
    or             r2d, 1
.inner_loop:
    vpsubd         m3, m3, m8          ; round and then check inner "if"
    vpxor          m9, m0, m3
    vptest         m9, m2
    jnz            .inner_break
    sub            r3d, r2d            ; level -= sign
    mov            [r0 + r1 * 2], r3w
    jnz            .inner_loop
    jmp            .loop_end
.inner_break:
    vpaddd         m3, m3, m8          ; reverse the last rounding
    mov            r6d, 1
.loop_end:
    dec            r1d
    jl             .ret
    vpsubd         m6, m6, m7
    jmp            .outer_loop

ALIGN 16
.ret:
%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    add            rsp, 40
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    RET


;=============================================================================
; denoise_dct
;=============================================================================
INIT_YMM avx2
cglobal denoise_dct, 0, 0
    vpxor          m3, m3
.loop:
    vmovdqu        m0, [r0 + r3 * 2 - 32]   ; level
    vpabsw         m1, m0                   ; level = abs(level)
    vpsubusw       m2, m1, [r2 + r3 * 2 - 32]  ; level -= offset
    vpermq         m1, m1, q3120
    vpsignw        m2, m2, m0
    vmovdqu        [r0 + r3 * 2 - 32], m2
    vpunpcklwd     m0, m1, m3
    vpunpckhwd     m1, m1, m3
    vpaddd         m0, [r1 + r3 * 4 - 64]
    vpaddd         m1, [r1 + r3 * 4 - 32]
    vmovdqu        [r1 + r3 * 4 - 64], m0
    vmovdqu        [r1 + r3 * 4 - 32], m1
    sub            r3d, 16
    jg             .loop
    RET


;=============================================================================
; decimate_score
;=============================================================================
INIT_XMM avx2
cglobal decimate_score15, 0, 0
    vmovdqu        m0, [r0]
    vpacksswb      m0, m0, [r0 + 16]
    vpcmpeqb       m1, m1, m1
    vpabsb         m1, m1              ; pb_1
    vpabsb         m0, m0
    vptest         m1, m0              ; check > 1
    jnc            .ret9
    vpxor          m3, m3, m3
    vpcmpeqb       m3, m0, m3          ; flag for dct[i] == 0
    vpmovmskb      r6d, m3
    xor            r6d, 0FFFFh         ; not ax, dct[i] != 0 ? bit 1 : bit 0
    jz             .ret
    shr            r6d, 1              ; need to remove the last bit
    lea            r2, [decimate_mask_table4]  ; score lut for a byte
    movzx          r0d, r6b
    mov            r1d, r6d
    movzx          r6d, byte [r2 + r0] ; low byte score
    xor            r1d, r0d            ; check if the high byte is zero, and clear the low byte
    jz             .ret
    ; for low byte, leading zeros y = n - 24
    ; for high byte, trailing zeros x = n - 8
    lzcnt          r0d, r0d
    lea            r3, [decimate_table4 - 32]  ; x + y
    add            r3, r0
    tzcnt          r0d, r1d
    shrx           r1d, r1d, r0d
    shr            r1d, 1
    movzx          r0d, byte [r3 + r0] ; score for the (10*) in both bytes
    movzx          r1d, byte [r2 + r1] ; the score of remaining part in high byte
    add            r6d, r0d
    add            r6d, r1d 
.ret:
    ret
.ret9:
    mov            r6d, 9
    ret

INIT_XMM avx2
cglobal decimate_score16, 0, 0
    vmovdqu        m0, [r0]
    vpacksswb      m0, m0, [r0 + 16]
    vpcmpeqb       m1, m1, m1
    vpabsb         m1, m1              ; pb_1
    vpabsb         m0, m0
    vptest         m1, m0              ; check > 1
    jnc            .ret9
    vpxor          m3, m3, m3
    vpcmpeqb       m3, m0, m3          ; flag for dct[i] == 0
    vpmovmskb      r6d, m3
    xor            r6d, 0FFFFh         ; not ax, dct[i] != 0 ? bit 1 : bit 0
    jz             .ret
    lea            r2, [decimate_mask_table4]  ; score lut for a byte
    movzx          r0d, r6b
    mov            r1d, r6d
    movzx          r6d, byte [r2 + r0] ; low byte score
    xor            r1d, r0d            ; check if the high byte is zero, and clear the low byte
    jz             .ret
    ; for low byte, leading zeros y = n - 24
    ; for high byte, trailing zeros x = n - 8
    lzcnt          r0d, r0d
    lea            r3, [decimate_table4 - 32]  ; x + y
    add            r3, r0
    tzcnt          r0d, r1d
    shrx           r1d, r1d, r0d
    shr            r1d, 1
    movzx          r0d, byte [r3 + r0] ; score for the (10*) in both bytes
    movzx          r1d, byte [r2 + r1] ; the score of remaining part in high byte
    add            r6d, r0d
    add            r6d, r1d 
.ret:
    ret
.ret9:
    mov            r6d, 9
    ret

INIT_YMM avx2
cglobal decimate_score64, 0, 0
    vmovdqu        m0, [r0]
    vpacksswb      m0, m0, [r0 + 32]
    vmovdqu        m1, [r0 + 64]
    vpacksswb      m1, [r0 + 96]
    vpcmpeqb       m4, m4, m4
    vpabsb         m4, m4              ; pb_1
    vpabsb         m2, m0
    vpabsb         m3, m1
    vpor           m2, m2, m3
    vptest         m4, m2              ; check > 1
    jnc            .ret9
    vpermq         m0, m0, q3120
    vpermq         m1, m1, q3120
    vpxor          m4, m4, m4
    vpcmpeqb       m0, m0, m4
    vpcmpeqb       m1, m1, m4
    vpmovmskb      r0d, m0
    vpmovmskb      r6d, m1
    not            r0                  ; 1111... | low dword
    shl            r6, 32              ; high dword(inv) | 0
    xor            r0, r6              ; high dword | low dword
    jz             .ret                ; now eax = 0
    lea            r2, [decimate_table8]
.loop:
    tzcnt          r1, r0
    movzx          r3d, byte [r2 + r1]
    shr            r0, 1
    add            r6d, r3d            ; score
    shrx           r0, r0, r1
    test           r0, r0
    jnz            .loop
.ret:
    RET
.ret9:
    mov            r6d, 9
    RET


;=============================================================================
; coeff_last
;=============================================================================
INIT_XMM avx2
cglobal coeff_last4, 0, 0
    lzcnt          r6, [r0]
    xor            r6d, 3Fh            ; bit index = 63 - lzcnt
    shr            r6d, 4              ; word index
    ret

INIT_XMM avx2
cglobal coeff_last15, 0, 0
    vmovdqu        m0, [r0 - 2]
    vpacksswb      m0, m0, [r0 + 14]
    vpxor          m1, m1, m1
    vpcmpeqb       m0, m0, m1
    vpmovmskb      r6d, m0
    xor            r6d, 0FFFFh         ; invert low word
    lzcnt          r6d, r6d
    xor            r6d, 1Fh            ; bit index = 31 - lzcnt
    dec            r6d
    ret

INIT_XMM avx2
cglobal coeff_last16, 0, 0
    vmovdqu        m0, [r0]
    vpacksswb      m0, m0, [r0 + 16]
    vpxor          m1, m1, m1
    vpcmpeqb       m0, m0, m1
    vpmovmskb      r6d, m0
    xor            r6d, 0FFFFh         ; invert low word
    lzcnt          r6d, r6d
    xor            r6d, 1Fh            ; bit index = 31 - lzcnt
    ret

INIT_YMM avx2
cglobal coeff_last64, 0, 0
    vpxor          m0, m0, m0
    vmovdqu        m1, [r0]
    vpacksswb      m1, m1, [r0 + 32]
    vpermq         m1, m1, q3120
    vpcmpeqb       m1, m1, m0
    vpmovmskb      r6d, m1
    vmovdqu        m1, [r0 + 64]
    vpacksswb      m1, m1, [r0 + 96]
    vpermq         m1, m1, q3120
    vpcmpeqb       m1, m1, m0
    vpmovmskb      r5d, m1
    shl            r5, 32
    or             r6, r5
    not            r6
    lzcnt          r6, r6
    xor            r6d, 3Fh            ; bit index = 63 - lzcnt
    RET


;=============================================================================
; coeff_level_run
;=============================================================================
INIT_XMM avx2
cglobal coeff_level_run4, 0, 0
    vmovq          m0, [r0]
    vpxor          m1, m1, m1
    vpacksswb      m2, m0, m1
    vpcmpeqb       m2, m2, m1
    vpmovmskb      r0d, m2
    xor            r0d, 0FFFFh         ; only care of the lowest 4 bits
    mov            [r1 + 4], r0d       ; runlevel->mask
    lzcnt          r6d, r0d
    xor            r6d, 1Fh            ; bit index = 31 - lzcnt
    mov            [r1], r6d           ; runlevel->last
    lea            r6, [coeff_level_shuffle]
    shl            r0d, 4
    vpshufb        m0, m0, [r6 + r0]
    vmovq          [r1 + 16], m0
    popcnt         r6d, r0d
    ret

INIT_XMM avx2
cglobal coeff_level_run15, 0, 0
    vmovdqu        m0, [r0 - 2]
    vmovdqu        m1, [r0 + 14]
    vpacksswb      m2, m0, m1
    vpxor          m3, m3, m3
    vpcmpeqb       m2, m2, m3
    vpmovmskb      r0d, m2
    xor            r0d, 0FFFFh         ; low word
    shr            r0d, 1
    mov            [r1 + 4], r0d       ; runlevel->mask
    lzcnt          r6d, r0d
    xor            r6d, 1Fh            ; bit index = 31 - lzcnt
    mov            [r1], r6d           ; runlevel->last
    lea            r6, [coeff_level_shuffle]
    mov            r2d, r0d
    movzx          r3d, r0b            ; for m0
    shr            r2d, 8              ; for m1
    shl            r3d, 4
    shl            r2d, 4
    vpalignr       m0, m1, m0, 2
    vpshufb        m0, m0, [r6 + r3]
    vpsrldq        m1, m1, 2
    vpshufb        m1, m1, [r6 + r2]
    vmovdqu        [r1 + 16], m1
    popcnt         r3d, r2d            ; only low 16 bits are valid, shl won't affect it in 32 bits
    vmovdqu        [r1 + r3 * 2 + 16], m0
    popcnt         r6d, r0d
    ret

INIT_XMM avx2
cglobal coeff_level_run16, 0, 0
    vmovdqu        m0, [r0]
    vmovdqu        m1, [r0 + 16]
    vpacksswb      m2, m0, m1
    vpxor          m3, m3, m3
    vpcmpeqb       m2, m2, m3
    vpmovmskb      r0d, m2
    xor            r0d, 0FFFFh         ; low word
    mov            [r1 + 4], r0d       ; runlevel->mask
    lzcnt          r6d, r0d
    xor            r6d, 1Fh            ; bit index = 31 - lzcnt
    mov            [r1], r6d           ; runlevel->last
    lea            r6, [coeff_level_shuffle]
    mov            r2d, r0d
    movzx          r3d, r0b            ; for m0
    shr            r2d, 8              ; for m1
    shl            r3d, 4
    shl            r2d, 4
    vpshufb        m0, m0, [r6 + r3]
    vpshufb        m1, m1, [r6 + r2]
    vmovdqu        [r1 + 16], m1
    popcnt         r3d, r2d            ; only low 16 bits are valid, shl won't affect it in 32 bits
    vmovdqu        [r1 + r3 * 2 + 16], m0
    popcnt         r6d, r0d
    ret
