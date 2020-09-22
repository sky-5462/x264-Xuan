;*****************************************************************************
;* const-a.asm: x86 global constants
;*****************************************************************************
;* Copyright (C) 2010-2019 x264 project
;*
;* Authors: Loren Merritt <lorenm@u.washington.edu>
;*          Fiona Glaser <fiona@x264.com>
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

SECTION_RODATA 32

const pb_1,        times 32 db 1
const hsub_mul,    times 16 db 1, -1
const pw_1,        times 16 dw 1
const pw_32,       times 16 dw 32
const pw_512,      times 16 dw 512
const pw_00ff,     times 16 dw 0x00ff
const pw_0to15,    dw 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
const pd_1,        times 8 dd 1
const pd_0123,     dd 0,1,2,3
const pd_4567,     dd 4,5,6,7
const deinterleave_shufd, dd 0,4,1,5,2,6,3,7
const pb_unpackbd1, times 2 db 0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3
const pb_unpackbd2, times 2 db 4,4,4,4,5,5,5,5,6,6,6,6,7,7,7,7

const pb_a1,       times 16 db 0xa1
const pb_3,        times 16 db 3

const pw_2,        times 8 dw 2
const pw_8,        times 8 dw 8
const pw_8000,     times 8 dw 0x8000
const pw_3fff,     times 8 dw 0x3fff

const pd_8,        times 4 dd 8
const pd_1024,     times 4 dd 1024
