;*****************************************************************************
;* pixel.asm: x86 pixel metrics
;*****************************************************************************
;* Copyright (C) 2003-2019 x264 project
;*
;* Authors: Loren Merritt <lorenm@u.washington.edu>
;*          Holger Lubitz <holger@lubitz.org>
;*          Laurent Aimar <fenrir@via.ecp.fr>
;*          Alex Izvorski <aizvorksi@gmail.com>
;*          Fiona Glaser <fiona@x264.com>
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
hmul_16p:  times 16 db 1
           times 8 db 1, -1
mask_ff:   times 16 db 0xff
           times 16 db 0
hmul_8p:   times 8 db 1
           times 4 db 1, -1
hmul_4p:   db 1, 1, 1, 1, 1, -1, 1, -1
ssim_c1:   dd 416          ; .01*.01*255*255*64
ssim_c2:   dd 235963       ; .03*.03*255*255*64*63
intra_sa8d_8x8_shuf_h:      times 16 db 7
                            times 16 db 3
intra_satd_4x4_shuf:        times 8 db 0
                            times 8 db 1
pw_76543210:                dw 0, 1, 2, 3, 4, 5, 6, 7

intrax9a_ddlr1: db  6, 7, 8, 9, 7, 8, 9,10, 4, 5, 6, 7, 3, 4, 5, 6
intrax9a_ddlr2: db  8, 9,10,11, 9,10,11,12, 2, 3, 4, 5, 1, 2, 3, 4
intrax9a_hdu1:  db 15, 4, 5, 6,14, 3,15, 4,14, 2,13, 1,13, 1,12, 0
intrax9a_hdu2:  db 13, 2,14, 3,12, 1,13, 2,12, 0,11,11,11,11,11,11
intrax9a_vrl1:  db 10,11,12,13, 3, 4, 5, 6,11,12,13,14, 5, 6, 7, 8
intrax9a_vrl2:  db  2,10,11,12, 1, 3, 4, 5,12,13,14,15, 6, 7, 8, 9
intrax9a_vh1:   db  6, 7, 8, 9, 6, 7, 8, 9, 4, 4, 4, 4, 3, 3, 3, 3
intrax9a_vh2:   db  6, 7, 8, 9, 6, 7, 8, 9, 2, 2, 2, 2, 1, 1, 1, 1
intrax9a_dc:    db  1, 2, 3, 4, 6, 7, 8, 9,-1,-1,-1,-1,-1,-1,-1,-1
intrax9a_lut:   db 0x60,0x68,0x80,0x00,0x08,0x20,0x40,0x28,0x48,0,0,0,0,0,0,0

intrax9b_ddlr1: db  6, 7, 8, 9, 4, 5, 6, 7, 7, 8, 9,10, 3, 4, 5, 6
intrax9b_ddlr2: db  8, 9,10,11, 2, 3, 4, 5, 9,10,11,12, 1, 2, 3, 4
intrax9b_hdu1:  db 15, 4, 5, 6,14, 2,13, 1,14, 3,15, 4,13, 1,12, 0
intrax9b_hdu2:  db 13, 2,14, 3,12, 0,11,11,12, 1,13, 2,11,11,11,11
intrax9b_vrl1:  db 10,11,12,13,11,12,13,14, 3, 4, 5, 6, 5, 6, 7, 8
intrax9b_vrl2:  db  2,10,11,12,12,13,14,15, 1, 3, 4, 5, 6, 7, 8, 9
intrax9b_vh1:   db  6, 7, 8, 9, 4, 4, 4, 4, 6, 7, 8, 9, 3, 3, 3, 3
intrax9b_vh2:   db  6, 7, 8, 9, 2, 2, 2, 2, 6, 7, 8, 9, 1, 1, 1, 1
intrax9b_dc:    db  6, 7, 8, 9, 4, 3, 2, 1,-1,-1,-1,-1,-1,-1,-1,-1
intrax9b_lut:   db 0x60,0x64,0x80,0x00,0x04,0x20,0x40,0x24,0x44,0,0,0,0,0,0,0
intrax9_edge:   db  0, 0, 1, 2, 3, 7, 8, 9,10,11,12,13,14,15,15,15
intra_satd_8x8c_shuf_dc:    times 4 db 0
                            times 4 db 8

ALIGN 32
intra8x9_h1:   db  7, 7, 7, 7, 7, 7, 7, 7, 5, 5, 5, 5, 5, 5, 5, 5
intra8x9_h2:   db  6, 6, 6, 6, 6, 6, 6, 6, 4, 4, 4, 4, 4, 4, 4, 4
intra8x9_h3:   db  3, 3, 3, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1
intra8x9_h4:   db  2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0
intra8x9_ddl1: db  1, 2, 3, 4, 5, 6, 7, 8, 3, 4, 5, 6, 7, 8, 9,10
intra8x9_ddl2: db  2, 3, 4, 5, 6, 7, 8, 9, 4, 5, 6, 7, 8, 9,10,11
intra8x9_ddl3: db  5, 6, 7, 8, 9,10,11,12, 7, 8, 9,10,11,12,13,14
intra8x9_ddl4: db  6, 7, 8, 9,10,11,12,13, 8, 9,10,11,12,13,14,15
intra8x9_vl1:  db  0, 1, 2, 3, 4, 5, 6, 7, 1, 2, 3, 4, 5, 6, 7, 8
intra8x9_vl2:  db  1, 2, 3, 4, 5, 6, 7, 8, 2, 3, 4, 5, 6, 7, 8, 9
intra8x9_vl3:  db  2, 3, 4, 5, 6, 7, 8, 9, 3, 4, 5, 6, 7, 8, 9,10
intra8x9_vl4:  db  3, 4, 5, 6, 7, 8, 9,10, 4, 5, 6, 7, 8, 9,10,11
intra8x9_ddr1: db  8, 9,10,11,12,13,14,15, 6, 7, 8, 9,10,11,12,13
intra8x9_ddr2: db  7, 8, 9,10,11,12,13,14, 5, 6, 7, 8, 9,10,11,12
intra8x9_ddr3: db  4, 5, 6, 7, 8, 9,10,11, 2, 3, 4, 5, 6, 7, 8, 9
intra8x9_ddr4: db  3, 4, 5, 6, 7, 8, 9,10, 1, 2, 3, 4, 5, 6, 7, 8
intra8x9_vr1:  db  8, 9,10,11,12,13,14,15, 7, 8, 9,10,11,12,13,14
intra8x9_vr2:  db  8, 9,10,11,12,13,14,15, 6, 8, 9,10,11,12,13,14
intra8x9_vr3:  db  5, 7, 8, 9,10,11,12,13, 3, 5, 7, 8, 9,10,11,12
intra8x9_vr4:  db  4, 6, 8, 9,10,11,12,13, 2, 4, 6, 8, 9,10,11,12
intra8x9_hd1:  db  3, 8, 9,10,11,12,13,14, 1, 6, 2, 7, 3, 8, 9,10
intra8x9_hd2:  db  2, 7, 3, 8, 9,10,11,12, 0, 5, 1, 6, 2, 7, 3, 8
intra8x9_hd3:  db  7, 8, 9,10,11,12,13,14, 3, 4, 5, 6, 7, 8, 9,10
intra8x9_hd4:  db  5, 6, 7, 8, 9,10,11,12, 1, 2, 3, 4, 5, 6, 7, 8
intra8x9_hu1:  db 13,12,11,10, 9, 8, 7, 6, 9, 8, 7, 6, 5, 4, 3, 2
intra8x9_hu2:  db 11,10, 9, 8, 7, 6, 5, 4, 7, 6, 5, 4, 3, 2, 1, 0
intra8x9_hu3:  db  5, 4, 3, 2, 1, 0,15,15, 1, 0,15,15,15,15,15,15
intra8x9_hu4:  db  3, 2, 1, 0,15,15,15,15,15,15,15,15,15,15,15,15

ALIGN 32
ads_shuf_000:      db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_001:      db  0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_002:      db  2, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_003:      db  0, 1, 2, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_004:      db  4, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_005:      db  0, 1, 4, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_006:      db  2, 3, 4, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_007:      db  0, 1, 2, 3, 4, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_008:      db  6, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_009:      db  0, 1, 6, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_010:      db  2, 3, 6, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_011:      db  0, 1, 2, 3, 6, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_012:      db  4, 5, 6, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_013:      db  0, 1, 4, 5, 6, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_014:      db  2, 3, 4, 5, 6, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_015:      db  0, 1, 2, 3, 4, 5, 6, 7, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_016:      db  8, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_017:      db  0, 1, 8, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_018:      db  2, 3, 8, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_019:      db  0, 1, 2, 3, 8, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_020:      db  4, 5, 8, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_021:      db  0, 1, 4, 5, 8, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_022:      db  2, 3, 4, 5, 8, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_023:      db  0, 1, 2, 3, 4, 5, 8, 9, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_024:      db  6, 7, 8, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_025:      db  0, 1, 6, 7, 8, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_026:      db  2, 3, 6, 7, 8, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_027:      db  0, 1, 2, 3, 6, 7, 8, 9, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_028:      db  4, 5, 6, 7, 8, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_029:      db  0, 1, 4, 5, 6, 7, 8, 9, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_030:      db  2, 3, 4, 5, 6, 7, 8, 9, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_031:      db  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 0, 0, 0, 0, 0
ads_shuf_032:      db  10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_033:      db  0, 1, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_034:      db  2, 3, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_035:      db  0, 1, 2, 3, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_036:      db  4, 5, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_037:      db  0, 1, 4, 5, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_038:      db  2, 3, 4, 5, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_039:      db  0, 1, 2, 3, 4, 5, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_040:      db  6, 7, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_041:      db  0, 1, 6, 7, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_042:      db  2, 3, 6, 7, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_043:      db  0, 1, 2, 3, 6, 7, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_044:      db  4, 5, 6, 7, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_045:      db  0, 1, 4, 5, 6, 7, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_046:      db  2, 3, 4, 5, 6, 7, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_047:      db  0, 1, 2, 3, 4, 5, 6, 7, 10, 11, 0, 0, 0, 0, 0, 0
ads_shuf_048:      db  8, 9, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_049:      db  0, 1, 8, 9, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_050:      db  2, 3, 8, 9, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_051:      db  0, 1, 2, 3, 8, 9, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_052:      db  4, 5, 8, 9, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_053:      db  0, 1, 4, 5, 8, 9, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_054:      db  2, 3, 4, 5, 8, 9, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_055:      db  0, 1, 2, 3, 4, 5, 8, 9, 10, 11, 0, 0, 0, 0, 0, 0
ads_shuf_056:      db  6, 7, 8, 9, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_057:      db  0, 1, 6, 7, 8, 9, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_058:      db  2, 3, 6, 7, 8, 9, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_059:      db  0, 1, 2, 3, 6, 7, 8, 9, 10, 11, 0, 0, 0, 0, 0, 0
ads_shuf_060:      db  4, 5, 6, 7, 8, 9, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_061:      db  0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 0, 0, 0, 0, 0, 0
ads_shuf_062:      db  2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0, 0, 0, 0, 0, 0
ads_shuf_063:      db  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0, 0, 0, 0
ads_shuf_064:      db  12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_065:      db  0, 1, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_066:      db  2, 3, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_067:      db  0, 1, 2, 3, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_068:      db  4, 5, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_069:      db  0, 1, 4, 5, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_070:      db  2, 3, 4, 5, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_071:      db  0, 1, 2, 3, 4, 5, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_072:      db  6, 7, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_073:      db  0, 1, 6, 7, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_074:      db  2, 3, 6, 7, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_075:      db  0, 1, 2, 3, 6, 7, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_076:      db  4, 5, 6, 7, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_077:      db  0, 1, 4, 5, 6, 7, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_078:      db  2, 3, 4, 5, 6, 7, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_079:      db  0, 1, 2, 3, 4, 5, 6, 7, 12, 13, 0, 0, 0, 0, 0, 0
ads_shuf_080:      db  8, 9, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_081:      db  0, 1, 8, 9, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_082:      db  2, 3, 8, 9, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_083:      db  0, 1, 2, 3, 8, 9, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_084:      db  4, 5, 8, 9, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_085:      db  0, 1, 4, 5, 8, 9, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_086:      db  2, 3, 4, 5, 8, 9, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_087:      db  0, 1, 2, 3, 4, 5, 8, 9, 12, 13, 0, 0, 0, 0, 0, 0
ads_shuf_088:      db  6, 7, 8, 9, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_089:      db  0, 1, 6, 7, 8, 9, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_090:      db  2, 3, 6, 7, 8, 9, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_091:      db  0, 1, 2, 3, 6, 7, 8, 9, 12, 13, 0, 0, 0, 0, 0, 0
ads_shuf_092:      db  4, 5, 6, 7, 8, 9, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_093:      db  0, 1, 4, 5, 6, 7, 8, 9, 12, 13, 0, 0, 0, 0, 0, 0
ads_shuf_094:      db  2, 3, 4, 5, 6, 7, 8, 9, 12, 13, 0, 0, 0, 0, 0, 0
ads_shuf_095:      db  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 12, 13, 0, 0, 0, 0
ads_shuf_096:      db  10, 11, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_097:      db  0, 1, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_098:      db  2, 3, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_099:      db  0, 1, 2, 3, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_100:      db  4, 5, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_101:      db  0, 1, 4, 5, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_102:      db  2, 3, 4, 5, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_103:      db  0, 1, 2, 3, 4, 5, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0
ads_shuf_104:      db  6, 7, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_105:      db  0, 1, 6, 7, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_106:      db  2, 3, 6, 7, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_107:      db  0, 1, 2, 3, 6, 7, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0
ads_shuf_108:      db  4, 5, 6, 7, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_109:      db  0, 1, 4, 5, 6, 7, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0
ads_shuf_110:      db  2, 3, 4, 5, 6, 7, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0
ads_shuf_111:      db  0, 1, 2, 3, 4, 5, 6, 7, 10, 11, 12, 13, 0, 0, 0, 0
ads_shuf_112:      db  8, 9, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_113:      db  0, 1, 8, 9, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_114:      db  2, 3, 8, 9, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_115:      db  0, 1, 2, 3, 8, 9, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0
ads_shuf_116:      db  4, 5, 8, 9, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_117:      db  0, 1, 4, 5, 8, 9, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0
ads_shuf_118:      db  2, 3, 4, 5, 8, 9, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0
ads_shuf_119:      db  0, 1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 13, 0, 0, 0, 0
ads_shuf_120:      db  6, 7, 8, 9, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_121:      db  0, 1, 6, 7, 8, 9, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0
ads_shuf_122:      db  2, 3, 6, 7, 8, 9, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0
ads_shuf_123:      db  0, 1, 2, 3, 6, 7, 8, 9, 10, 11, 12, 13, 0, 0, 0, 0
ads_shuf_124:      db  4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0
ads_shuf_125:      db  0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 0, 0, 0, 0
ads_shuf_126:      db  2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 0, 0, 0, 0
ads_shuf_127:      db  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 0, 0
ads_shuf_128:      db  14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_129:      db  0, 1, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_130:      db  2, 3, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_131:      db  0, 1, 2, 3, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_132:      db  4, 5, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_133:      db  0, 1, 4, 5, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_134:      db  2, 3, 4, 5, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_135:      db  0, 1, 2, 3, 4, 5, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_136:      db  6, 7, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_137:      db  0, 1, 6, 7, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_138:      db  2, 3, 6, 7, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_139:      db  0, 1, 2, 3, 6, 7, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_140:      db  4, 5, 6, 7, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_141:      db  0, 1, 4, 5, 6, 7, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_142:      db  2, 3, 4, 5, 6, 7, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_143:      db  0, 1, 2, 3, 4, 5, 6, 7, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_144:      db  8, 9, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_145:      db  0, 1, 8, 9, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_146:      db  2, 3, 8, 9, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_147:      db  0, 1, 2, 3, 8, 9, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_148:      db  4, 5, 8, 9, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_149:      db  0, 1, 4, 5, 8, 9, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_150:      db  2, 3, 4, 5, 8, 9, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_151:      db  0, 1, 2, 3, 4, 5, 8, 9, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_152:      db  6, 7, 8, 9, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_153:      db  0, 1, 6, 7, 8, 9, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_154:      db  2, 3, 6, 7, 8, 9, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_155:      db  0, 1, 2, 3, 6, 7, 8, 9, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_156:      db  4, 5, 6, 7, 8, 9, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_157:      db  0, 1, 4, 5, 6, 7, 8, 9, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_158:      db  2, 3, 4, 5, 6, 7, 8, 9, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_159:      db  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 14, 15, 0, 0, 0, 0
ads_shuf_160:      db  10, 11, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_161:      db  0, 1, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_162:      db  2, 3, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_163:      db  0, 1, 2, 3, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_164:      db  4, 5, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_165:      db  0, 1, 4, 5, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_166:      db  2, 3, 4, 5, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_167:      db  0, 1, 2, 3, 4, 5, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_168:      db  6, 7, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_169:      db  0, 1, 6, 7, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_170:      db  2, 3, 6, 7, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_171:      db  0, 1, 2, 3, 6, 7, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_172:      db  4, 5, 6, 7, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_173:      db  0, 1, 4, 5, 6, 7, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_174:      db  2, 3, 4, 5, 6, 7, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_175:      db  0, 1, 2, 3, 4, 5, 6, 7, 10, 11, 14, 15, 0, 0, 0, 0
ads_shuf_176:      db  8, 9, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_177:      db  0, 1, 8, 9, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_178:      db  2, 3, 8, 9, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_179:      db  0, 1, 2, 3, 8, 9, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_180:      db  4, 5, 8, 9, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_181:      db  0, 1, 4, 5, 8, 9, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_182:      db  2, 3, 4, 5, 8, 9, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_183:      db  0, 1, 2, 3, 4, 5, 8, 9, 10, 11, 14, 15, 0, 0, 0, 0
ads_shuf_184:      db  6, 7, 8, 9, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_185:      db  0, 1, 6, 7, 8, 9, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_186:      db  2, 3, 6, 7, 8, 9, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_187:      db  0, 1, 2, 3, 6, 7, 8, 9, 10, 11, 14, 15, 0, 0, 0, 0
ads_shuf_188:      db  4, 5, 6, 7, 8, 9, 10, 11, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_189:      db  0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 14, 15, 0, 0, 0, 0
ads_shuf_190:      db  2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 14, 15, 0, 0, 0, 0
ads_shuf_191:      db  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 14, 15, 0, 0
ads_shuf_192:      db  12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_193:      db  0, 1, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_194:      db  2, 3, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_195:      db  0, 1, 2, 3, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_196:      db  4, 5, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_197:      db  0, 1, 4, 5, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_198:      db  2, 3, 4, 5, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_199:      db  0, 1, 2, 3, 4, 5, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_200:      db  6, 7, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_201:      db  0, 1, 6, 7, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_202:      db  2, 3, 6, 7, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_203:      db  0, 1, 2, 3, 6, 7, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_204:      db  4, 5, 6, 7, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_205:      db  0, 1, 4, 5, 6, 7, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_206:      db  2, 3, 4, 5, 6, 7, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_207:      db  0, 1, 2, 3, 4, 5, 6, 7, 12, 13, 14, 15, 0, 0, 0, 0
ads_shuf_208:      db  8, 9, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_209:      db  0, 1, 8, 9, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_210:      db  2, 3, 8, 9, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_211:      db  0, 1, 2, 3, 8, 9, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_212:      db  4, 5, 8, 9, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_213:      db  0, 1, 4, 5, 8, 9, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_214:      db  2, 3, 4, 5, 8, 9, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_215:      db  0, 1, 2, 3, 4, 5, 8, 9, 12, 13, 14, 15, 0, 0, 0, 0
ads_shuf_216:      db  6, 7, 8, 9, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_217:      db  0, 1, 6, 7, 8, 9, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_218:      db  2, 3, 6, 7, 8, 9, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_219:      db  0, 1, 2, 3, 6, 7, 8, 9, 12, 13, 14, 15, 0, 0, 0, 0
ads_shuf_220:      db  4, 5, 6, 7, 8, 9, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_221:      db  0, 1, 4, 5, 6, 7, 8, 9, 12, 13, 14, 15, 0, 0, 0, 0
ads_shuf_222:      db  2, 3, 4, 5, 6, 7, 8, 9, 12, 13, 14, 15, 0, 0, 0, 0
ads_shuf_223:      db  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 12, 13, 14, 15, 0, 0
ads_shuf_224:      db  10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_225:      db  0, 1, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_226:      db  2, 3, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_227:      db  0, 1, 2, 3, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_228:      db  4, 5, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_229:      db  0, 1, 4, 5, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_230:      db  2, 3, 4, 5, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_231:      db  0, 1, 2, 3, 4, 5, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0
ads_shuf_232:      db  6, 7, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_233:      db  0, 1, 6, 7, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_234:      db  2, 3, 6, 7, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_235:      db  0, 1, 2, 3, 6, 7, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0
ads_shuf_236:      db  4, 5, 6, 7, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_237:      db  0, 1, 4, 5, 6, 7, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0
ads_shuf_238:      db  2, 3, 4, 5, 6, 7, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0
ads_shuf_239:      db  0, 1, 2, 3, 4, 5, 6, 7, 10, 11, 12, 13, 14, 15, 0, 0
ads_shuf_240:      db  8, 9, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0
ads_shuf_241:      db  0, 1, 8, 9, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_242:      db  2, 3, 8, 9, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_243:      db  0, 1, 2, 3, 8, 9, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0
ads_shuf_244:      db  4, 5, 8, 9, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_245:      db  0, 1, 4, 5, 8, 9, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0
ads_shuf_246:      db  2, 3, 4, 5, 8, 9, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0
ads_shuf_247:      db  0, 1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 13, 14, 15, 0, 0
ads_shuf_248:      db  6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0
ads_shuf_249:      db  0, 1, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0
ads_shuf_250:      db  2, 3, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0
ads_shuf_251:      db  0, 1, 2, 3, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0, 0
ads_shuf_252:      db  4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0
ads_shuf_253:      db  0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0, 0
ads_shuf_254:      db  2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0, 0
ads_shuf_255:      db  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15


SECTION .text

cextern pb_1
cextern pw_1
cextern pw_8
cextern pw_00ff
cextern hsub_mul

;=============================================================================
; SSD
;=============================================================================
INIT_XMM avx2
cglobal pixel_ssd_4x4, 0, 0
    vpbroadcastd   m5, [hsub_mul]
    vmovd          m0, [r0]
    vmovd          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r1]
    vmovd          m3, [r2 + r3]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m4, m0, m0
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r6]
    vmovd          m3, [r2 + r4]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0

    vpunpckhqdq    m0, m4, m4
    vpaddd         m0, m0, m4
    vpshufd        m1, m0, 1
    vpaddd         m0, m0, m1
    vmovd          eax, m0
    ret

INIT_XMM avx2
cglobal pixel_ssd_4x8, 0, 0
    vpbroadcastd   m5, [hsub_mul]
    vmovd          m0, [r0]
    vmovd          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r1]
    vmovd          m3, [r2 + r3]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m4, m0, m0
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r6]
    vmovd          m3, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0

    vmovd          m0, [r0]
    vmovd          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r1]
    vmovd          m3, [r2 + r3]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r6]
    vmovd          m3, [r2 + r4]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0

    vpunpckhqdq    m0, m4, m4
    vpaddd         m0, m0, m4
    vpshufd        m1, m0, 1
    vpaddd         m0, m0, m1
    vmovd          eax, m0
    ret

INIT_XMM avx2
cglobal pixel_ssd_4x16, 0, 0
    vpbroadcastd   m5, [hsub_mul]
    vmovd          m0, [r0]
    vmovd          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r1]
    vmovd          m3, [r2 + r3]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m4, m0, m0
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r6]
    vmovd          m3, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0

    vmovd          m0, [r0]
    vmovd          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r1]
    vmovd          m3, [r2 + r3]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r6]
    vmovd          m3, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0

    vmovd          m0, [r0]
    vmovd          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r1]
    vmovd          m3, [r2 + r3]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r6]
    vmovd          m3, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0

    vmovd          m0, [r0]
    vmovd          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r1]
    vmovd          m3, [r2 + r3]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0
    vmovd          m0, [r0 + r1 * 2]
    vmovd          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vmovd          m2, [r0 + r6]
    vmovd          m3, [r2 + r4]
    vpunpcklbw     m2, m2, m3
    vpunpcklqdq    m0, m0, m2
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m0

    vpunpckhqdq    m0, m4, m4
    vpaddd         m0, m0, m4
    vpshufd        m1, m0, 1
    vpaddd         m0, m0, m1
    vmovd          eax, m0
    ret

INIT_XMM avx2
cglobal pixel_ssd_8x4, 0, 0
    vpbroadcastd   m5, [hsub_mul]
    vmovq          m0, [r0]
    vmovq          m1, [r2]
    vpunpcklbw     m0, m0, m1
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m2, m0, m0
    vmovq          m0, [r0 + r1]
    vmovq          m1, [r2 + r3]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1 * 2]
    vmovq          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r6]
    vmovq          m1, [r2 + r4]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3

    vpunpckhqdq    m0, m2, m2
    vpaddd         m0, m0, m2
    vpshufd        m1, m0, 1
    vpaddd         m0, m0, m1
    vmovd          eax, m0
    ret

INIT_XMM avx2
cglobal pixel_ssd_8x8, 0, 0
    vpbroadcastd   m5, [hsub_mul]
    vmovq          m0, [r0]
    vmovq          m1, [r2]
    vpunpcklbw     m0, m0, m1
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m2, m0, m0
    vmovq          m0, [r0 + r1]
    vmovq          m1, [r2 + r3]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1 * 2]
    vmovq          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r6]
    vmovq          m1, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3

    vmovq          m0, [r0]
    vmovq          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1]
    vmovq          m1, [r2 + r3]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1 * 2]
    vmovq          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r6]
    vmovq          m1, [r2 + r4]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3

    vpunpckhqdq    m0, m2, m2
    vpaddd         m0, m0, m2
    vpshufd        m1, m0, 1
    vpaddd         m0, m0, m1
    vmovd          eax, m0
    ret

INIT_XMM avx2
cglobal pixel_ssd_8x16, 0, 0
    vpbroadcastd   m5, [hsub_mul]
    vmovq          m0, [r0]
    vmovq          m1, [r2]
    vpunpcklbw     m0, m0, m1
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m2, m0, m0
    vmovq          m0, [r0 + r1]
    vmovq          m1, [r2 + r3]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1 * 2]
    vmovq          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r6]
    vmovq          m1, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3

    vmovq          m0, [r0]
    vmovq          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1]
    vmovq          m1, [r2 + r3]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1 * 2]
    vmovq          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r6]
    vmovq          m1, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3

    vmovq          m0, [r0]
    vmovq          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1]
    vmovq          m1, [r2 + r3]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1 * 2]
    vmovq          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r6]
    vmovq          m1, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3

    vmovq          m0, [r0]
    vmovq          m1, [r2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1]
    vmovq          m1, [r2 + r3]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r1 * 2]
    vmovq          m1, [r2 + r3 * 2]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3
    vmovq          m0, [r0 + r6]
    vmovq          m1, [r2 + r4]
    vpunpcklbw     m0, m0, m1
    vpmaddubsw     m0, m0, m5
    vpmaddwd       m3, m0, m0
    vpaddd         m2, m2, m3

    vpunpckhqdq    m0, m2, m2
    vpaddd         m0, m0, m2
    vpshufd        m1, m0, 1
    vpaddd         m0, m0, m1
    vmovd          eax, m0
    ret

INIT_YMM avx2
cglobal pixel_ssd_16x8, 0, 0
    vpbroadcastd   m5, [hsub_mul]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r2]
    vinserti128    m1, m1, [r2 + r3], 1
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m2, m3
    vmovdqu        xm0, [r0 + r1 * 2]
    vinserti128    m0, m0, [r0 + r6], 1
    vmovdqu        xm1, [r2 + r3 * 2]
    vinserti128    m1, m1, [r2 + r4], 1
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3

    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r2]
    vinserti128    m1, m1, [r2 + r3], 1
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3
    vmovdqu        xm0, [r0 + r1 * 2]
    vinserti128    m0, m0, [r0 + r6], 1
    vmovdqu        xm1, [r2 + r3 * 2]
    vinserti128    m1, m1, [r2 + r4], 1
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3

    vextracti128   xm0, m4, 1
    vpaddd         xm0, xm0, xm4
    vpunpckhqdq    xm1, xm0, xm0
    vpaddd         xm0, xm0, xm1
    vpshufd        xm1, xm0, 1
    vpaddd         xm0, xm0, xm1
    vmovd          eax, xm0
    RET

INIT_YMM avx2
cglobal pixel_ssd_16x16, 0, 0
    vpbroadcastd   m5, [hsub_mul]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]
    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r2]
    vinserti128    m1, m1, [r2 + r3], 1
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m2, m3
    vmovdqu        xm0, [r0 + r1 * 2]
    vinserti128    m0, m0, [r0 + r6], 1
    vmovdqu        xm1, [r2 + r3 * 2]
    vinserti128    m1, m1, [r2 + r4], 1
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3

    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r2]
    vinserti128    m1, m1, [r2 + r3], 1
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3
    vmovdqu        xm0, [r0 + r1 * 2]
    vinserti128    m0, m0, [r0 + r6], 1
    vmovdqu        xm1, [r2 + r3 * 2]
    vinserti128    m1, m1, [r2 + r4], 1
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3

    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r2]
    vinserti128    m1, m1, [r2 + r3], 1
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3
    vmovdqu        xm0, [r0 + r1 * 2]
    vinserti128    m0, m0, [r0 + r6], 1
    vmovdqu        xm1, [r2 + r3 * 2]
    vinserti128    m1, m1, [r2 + r4], 1
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3

    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r2]
    vinserti128    m1, m1, [r2 + r3], 1
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3
    vmovdqu        xm0, [r0 + r1 * 2]
    vinserti128    m0, m0, [r0 + r6], 1
    vmovdqu        xm1, [r2 + r3 * 2]
    vinserti128    m1, m1, [r2 + r4], 1
    vpunpcklbw     m2, m0, m1
    vpunpckhbw     m3, m0, m1
    vpmaddubsw     m2, m2, m5
    vpmaddubsw     m3, m3, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m3, m3, m3
    vpaddd         m4, m4, m2
    vpaddd         m4, m4, m3

    vextracti128   xm0, m4, 1
    vpaddd         xm0, xm0, xm4
    vpunpckhqdq    xm1, xm0, xm0
    vpaddd         xm0, xm0, xm1
    vpshufd        xm1, xm0, 1
    vpaddd         xm0, xm0, xm1
    vmovd          eax, xm0
    RET



;=============================================================================
; SSD_NV12_CORE
;=============================================================================
;-----------------------------------------------------------------------------
; void pixel_ssd_nv12_core( uint8_t *pixuv1, intptr_t stride1, uint8_t *pixuv2, intptr_t stride2,
;                           int width, int height, uint64_t *ssd_u, uint64_t *ssd_v )
;
; This implementation can potentially overflow on image widths >= 11008 (or
; 6604 if interlaced), since it is called on blocks of height up to 12 (resp
; 20). At sane distortion levels it will take much more than that though.
;-----------------------------------------------------------------------------
INIT_YMM avx2
cglobal pixel_ssd_nv12_core, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5d, [rsp + 48]
%endif
    add            r4d, r4d
    add            r0, r4
    add            r2, r4
    neg            r4
    vpxor          m3, m3, m3
    vpxor          m4, m4, m4
    vpbroadcastd   m5, [pw_00ff]

.loopy:
    mov            r6, r4
.loopx:
    vmovdqu        m2, [r0 + r6]
    vmovdqu        m1, [r2 + r6]
    vpsubusb       m0, m2, m1
    vpsubusb       m1, m1, m2
    vpor           m0, m0, m1
    vpsrlw         m2, m0, 8
    vpand          m0, m0, m5
    vpmaddwd       m2, m2, m2
    vpmaddwd       m0, m0, m0
    vpaddd         m4, m4, m2
    vpaddd         m3, m3, m0
    add            r6, 32
    jl             .loopx
    je             .no_overread
    vpcmpeqb       xm1, xm1, xm1
    vpandn         m0, m1, m0
    vpandn         m2, m1, m2
    vpsubd         m3, m3, m0
    vpsubd         m4, m4, m2
.no_overread:
    add            r0, r1
    add            r2, r3
    sub            r5d, 1
    jg             .loopy
%if WIN64
    mov            r0, [rsp + 56]
    mov            r1, [rsp + 64]
%else
    mov            r0, [rsp + 8]
    mov            r1, [rsp + 16]
%endif
    vphaddd        m3, m3, m4
    vextracti128   xm4, m3, 1
    vpaddd         xm3, xm3, xm4
    vpsllq         xm4, xm3, 32
    vpaddd         xm3, xm3, xm4
    vpsrlq         xm3, xm3, 32
    vmovq          [r0], xm3
    vmovhps        [r1], xm3
    RET

;=============================================================================
; VAR
;=============================================================================
INIT_YMM avx2
cglobal pixel_var_8x8, 0, 0
    lea            r6d, [r1 + r1 * 2]
    vpxor          m5, m5, m5

    vmovq          xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovq          xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    lea            r0, [r0 + r1 * 4]
    vpunpcklbw     m0, m0, m5
    vpunpcklbw     m1, m1, m5
    vpaddw         m3, m0, m1
    vpmaddwd       m0, m0, m0
    vpmaddwd       m1, m1, m1
    vpaddd         m4, m0, m1
    vmovq          xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovq          xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    vpunpcklbw     m0, m0, m5
    vpunpcklbw     m1, m1, m5
    vpaddw         m3, m3, m0
    vpaddw         m3, m3, m1

    vpbroadcastd   m5, [pw_1]
    vpmaddwd       m3, m3, m5
    vpmaddwd       m0, m0, m0
    vpmaddwd       m1, m1, m1
    vpaddd         m4, m4, m0
    vpaddd         m4, m4, m1

    vphaddd        m0, m3, m4
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovq          rax, xm0
    RET

INIT_YMM avx2
cglobal pixel_var_8x16, 0, 0
    lea            r6d, [r1 + r1 * 2]
    vpxor          m5, m5, m5

    vmovq          xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovq          xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    lea            r0, [r0 + r1 * 4]
    vpunpcklbw     m0, m0, m5
    vpunpcklbw     m1, m1, m5
    vpaddw         m3, m0, m1
    vpmaddwd       m0, m0, m0
    vpmaddwd       m1, m1, m1
    vpaddd         m4, m0, m1
    vmovq          xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovq          xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    lea            r0, [r0 + r1 * 4]
    vpunpcklbw     m0, m0, m5
    vpunpcklbw     m1, m1, m5
    vpaddw         m3, m3, m0
    vpaddw         m3, m3, m1
    vpmaddwd       m0, m0, m0
    vpmaddwd       m1, m1, m1
    vpaddd         m4, m4, m0
    vpaddd         m4, m4, m1

    vmovq          xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovq          xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    lea            r0, [r0 + r1 * 4]
    vpunpcklbw     m0, m0, m5
    vpunpcklbw     m1, m1, m5
    vpaddw         m3, m3, m0
    vpaddw         m3, m3, m1
    vpmaddwd       m0, m0, m0
    vpmaddwd       m1, m1, m1
    vpaddd         m4, m4, m0
    vpaddd         m4, m4, m1
    vmovq          xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovq          xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    vpunpcklbw     m0, m0, m5
    vpunpcklbw     m1, m1, m5
    vpaddw         m3, m3, m0
    vpaddw         m3, m3, m1

    vpbroadcastd   m5, [pw_1]
    vpmaddwd       m3, m3, m5
    vpmaddwd       m0, m0, m0
    vpmaddwd       m1, m1, m1
    vpaddd         m4, m4, m0
    vpaddd         m4, m4, m1

    vphaddd        m0, m3, m4
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovq          rax, xm0
    RET

INIT_YMM avx2
cglobal pixel_var_16x16, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
%endif
    lea            r6d, [r1 + r1 * 2]
    vpbroadcastd   m6, [pw_00ff]

    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    lea            r0, [r0 + r1 * 4]
    vpand          m2, m0, m6
    vpand          m3, m1, m6
    vpsrlw         m0, m0, 8
    vpsrlw         m1, m1, 8
    vpaddw         m4, m2, m3
    vpaddw         m4, m4, m0
    vpaddw         m4, m4, m1
    vpmaddwd       m2, m2, m2
    vpmaddwd       m0, m0, m0
    vpmaddwd       m3, m3, m3
    vpmaddwd       m1, m1, m1
    vpaddd         m5, m2, m0
    vpaddd         m5, m5, m3
    vpaddd         m5, m5, m1
    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    lea            r0, [r0 + r1 * 4]
    vpand          m2, m0, m6
    vpand          m3, m1, m6
    vpsrlw         m0, m0, 8
    vpsrlw         m1, m1, 8
    vpaddw         m4, m4, m2
    vpaddw         m4, m4, m3
    vpaddw         m4, m4, m0
    vpaddw         m4, m4, m1
    vpmaddwd       m2, m2, m2
    vpmaddwd       m0, m0, m0
    vpmaddwd       m3, m3, m3
    vpmaddwd       m1, m1, m1
    vpaddd         m5, m5, m2
    vpaddd         m5, m5, m0
    vpaddd         m5, m5, m3
    vpaddd         m5, m5, m1

    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    lea            r0, [r0 + r1 * 4]
    vpand          m2, m0, m6
    vpand          m3, m1, m6
    vpsrlw         m0, m0, 8
    vpsrlw         m1, m1, 8
    vpaddw         m4, m4, m2
    vpaddw         m4, m4, m3
    vpaddw         m4, m4, m0
    vpaddw         m4, m4, m1
    vpmaddwd       m2, m2, m2
    vpmaddwd       m0, m0, m0
    vpmaddwd       m3, m3, m3
    vpmaddwd       m1, m1, m1
    vpaddd         m5, m5, m2
    vpaddd         m5, m5, m0
    vpaddd         m5, m5, m3
    vpaddd         m5, m5, m1
    vmovdqu        xm0, [r0]
    vinserti128    m0, m0, [r0 + r1], 1
    vmovdqu        xm1, [r0 + r1 * 2]
    vinserti128    m1, m1, [r0 + r6], 1
    vpand          m2, m0, m6
    vpand          m3, m1, m6
    vpsrlw         m0, m0, 8
    vpsrlw         m1, m1, 8
    vpaddw         m4, m4, m2
    vpaddw         m4, m4, m3
    vpaddw         m4, m4, m0
    vpaddw         m4, m4, m1

    vpbroadcastd   m6, [pw_1]
    vpmaddwd       m4, m4, m6
    vpmaddwd       m2, m2, m2
    vpmaddwd       m0, m0, m0
    vpmaddwd       m3, m3, m3
    vpmaddwd       m1, m1, m1
    vpaddd         m5, m5, m2
    vpaddd         m5, m5, m0
    vpaddd         m5, m5, m3
    vpaddd         m5, m5, m1

%if WIN64
    vmovdqu        xm6, [rsp + 8]
%endif
    vphaddd        m0, m4, m5
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovq          rax, xm0
    RET

;=============================================================================
; VAR2
;=============================================================================
INIT_YMM avx2
cglobal pixel_var2_8x8, 0, 0
    vpxor          m5, m5, m5

    vpmovzxbw      m0, [r0]
    vmovdqu        m1, [r1]
    vpunpcklbw     m1, m1, m5
    vpsubw         m2, m0, m1
    vpmaddwd       m3, m2, m2
    vpmovzxbw      m0, [r0 + 16]
    vmovdqu        m1, [r1 + 32]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 32]
    vmovdqu        m1, [r1 + 64]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 48]
    vmovdqu        m1, [r1 + 96]
    add            r1, 128
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1

    vpmovzxbw      m0, [r0 + 64]
    vmovdqu        m1, [r1]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 80]
    vmovdqu        m1, [r1 + 32]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 96]
    vmovdqu        m1, [r1 + 64]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 112]
    vmovdqu        m1, [r1 + 96]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1

    vpbroadcastd   m5, [pw_1]
    vpmaddwd       m2, m2, m5
    vpunpckhqdq    m0, m2, m2
    vpunpckhqdq    m1, m3, m3
    vpaddd         m0, m0, m2
    vpaddd         m1, m1, m3
    vpsrlq         m2, m0, 32
    vpsrlq         m3, m1, 32
    vpaddd         m0, m0, m2
    vpaddd         m1, m1, m3
    vpmaddwd       m0, m0, m0
    vextracti128   xm2, m1, 1
    vpunpckldq     xm2, xm1, xm2
    vmovq          [r2], xm2
    vpsrld         m0, m0, 6
    vpsubd         m0, m1, m0
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovd          eax, xm0
    RET

INIT_YMM avx2
cglobal pixel_var2_8x16, 0, 0
    vpxor          m5, m5, m5

    vpmovzxbw      m0, [r0]
    vmovdqu        m1, [r1]
    vpunpcklbw     m1, m1, m5
    vpsubw         m2, m0, m1
    vpmaddwd       m3, m2, m2
    vpmovzxbw      m0, [r0 + 16]
    vmovdqu        m1, [r1 + 32]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 32]
    vmovdqu        m1, [r1 + 64]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 48]
    vmovdqu        m1, [r1 + 96]
    add            r1, 128
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1

    vpmovzxbw      m0, [r0 + 64]
    vmovdqu        m1, [r1]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 80]
    vmovdqu        m1, [r1 + 32]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 96]
    vmovdqu        m1, [r1 + 64]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 112]
    vmovdqu        m1, [r1 + 96]
    add            r0, 128
    add            r1, 128
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1

    vpmovzxbw      m0, [r0]
    vmovdqu        m1, [r1]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 16]
    vmovdqu        m1, [r1 + 32]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 32]
    vmovdqu        m1, [r1 + 64]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 48]
    vmovdqu        m1, [r1 + 96]
    add            r1, 128
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1

    vpmovzxbw      m0, [r0 + 64]
    vmovdqu        m1, [r1]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 80]
    vmovdqu        m1, [r1 + 32]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 96]
    vmovdqu        m1, [r1 + 64]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1
    vpmovzxbw      m0, [r0 + 112]
    vmovdqu        m1, [r1 + 96]
    vpunpcklbw     m1, m1, m5
    vpsubw         m0, m0, m1
    vpmaddwd       m1, m0, m0
    vpaddw         m2, m2, m0
    vpaddd         m3, m3, m1

    vpbroadcastd   m5, [pw_1]
    vpmaddwd       m2, m2, m5
    vpunpckhqdq    m0, m2, m2
    vpunpckhqdq    m1, m3, m3
    vpaddd         m0, m0, m2
    vpaddd         m1, m1, m3
    vpsrlq         m2, m0, 32
    vpsrlq         m3, m1, 32
    vpaddd         m0, m0, m2
    vpaddd         m1, m1, m3
    vpmaddwd       m0, m0, m0
    vextracti128   xm2, m1, 1
    vpunpckldq     xm2, xm1, xm2
    vmovq          [r2], xm2
    vpsrld         m0, m0, 7
    vpsubd         m0, m1, m0
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovd          eax, xm0
    RET


;=============================================================================
; SATD
;=============================================================================
INIT_XMM avx2
cglobal pixel_satd_4x4, 0, 0
    vmovddup       m5, [hmul_4p]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vmovd          m0, [r0]
    vmovd          m1, [r0 + r1]
    vshufps        m0, m0, m1, 0
    vpmaddubsw     m0, m0, m5
    vmovd          m1, [r0 + r1 * 2]
    vmovd          m2, [r0 + r6]
    vshufps        m1, m1, m2, 0
    vpmaddubsw     m1, m1, m5
    vmovd          m2, [r2]
    vmovd          m3, [r2 + r3]
    vshufps        m2, m2, m3, 0
    vpmaddubsw     m2, m2, m5
    vpsubw         m0, m0, m2
    vmovd          m3, [r2 + r3 * 2]
    vmovd          m4, [r2 + r4]
    vshufps        m3, m3, m4, 0
    vpmaddubsw     m3, m3, m5
    vpsubw         m1, m1, m3

    vpbroadcastd   m4, [pw_1]
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpunpcklqdq    m0, m2, m3
    vpunpckhqdq    m1, m2, m3
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpblendw       m0, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m1, m2, m3
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpmaxsw        m0, m0, m1
    vpmaddwd       m0, m0, m4

    vpunpckhqdq    m1, m0, m0
    vpaddd         m0, m0, m1
    vpshufd        m1, m0, 1
    vpaddd         m0, m0, m1
    vmovd          eax, m0
    ret

INIT_YMM avx2
cglobal pixel_satd_4x8, 0, 0
    vpbroadcastq   m5, [hmul_4p]
    lea            r5, [r0 + r1 * 4]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vmovd          xm0, [r0]
    vmovd          xm1, [r0 + r1]
    vshufps        xm0, xm0, xm1, 0
    vmovd          xm1, [r5]
    vmovd          xm2, [r5 + r1]
    vshufps        xm1, xm1, xm2, 0
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m5
    vmovd          xm1, [r0 + r1 * 2]
    vmovd          xm2, [r0 + r6]
    vshufps        xm1, xm1, xm2, 0
    vmovd          xm2, [r5 + r1 * 2]
    vmovd          xm3, [r5 + r6]
    lea            r5, [r2 + r3 * 4]
    vshufps        xm2, xm2, xm3, 0
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m5
    vmovd          xm2, [r2]
    vmovd          xm3, [r2 + r3]
    vshufps        xm2, xm2, xm3, 0
    vmovd          xm3, [r5]
    vmovd          xm4, [r5 + r3]
    vshufps        xm3, xm3, xm4, 0
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m5
    vpsubw         m0, m0, m2
    vmovd          xm3, [r2 + r3 * 2]
    vmovd          xm4, [r2 + r4]
    vshufps        xm3, xm3, xm4, 0
    vmovd          xm4, [r5 + r3 * 2]
    vmovd          xm2, [r5 + r4]
    vshufps        xm4, xm4, xm2, 0
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m5
    vpsubw         m1, m1, m3

    vpbroadcastd   m5, [pw_1]
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpunpcklqdq    m0, m2, m3
    vpunpckhqdq    m1, m2, m3
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpblendw       m0, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m1, m2, m3
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpmaxsw        m0, m0, m1
    vpmaddwd       m0, m0, m5

    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vpunpckhqdq    xm1, xm0, xm0
    vpaddd         xm0, xm0, xm1
    vpshufd        xm1, xm0, 1
    vpaddd         xm0, xm0, xm1
    vmovd          eax, xm0
    RET

INIT_YMM avx2
cglobal pixel_satd_4x16, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
%endif
    vpbroadcastq   m6, [hmul_4p]
    lea            r5, [r0 + r1 * 4]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vmovd          xm0, [r0]
    vmovd          xm1, [r0 + r1]
    vshufps        xm0, xm0, xm1, 0
    vmovd          xm1, [r5]
    vmovd          xm2, [r5 + r1]
    vshufps        xm1, xm1, xm2, 0
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m6
    vmovd          xm1, [r0 + r1 * 2]
    vmovd          xm2, [r0 + r6]
    vshufps        xm1, xm1, xm2, 0
    vmovd          xm2, [r5 + r1 * 2]
    vmovd          xm3, [r5 + r6]
    lea            r5, [r2 + r3 * 4]
    vshufps        xm2, xm2, xm3, 0
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m6
    vmovd          xm2, [r2]
    vmovd          xm3, [r2 + r3]
    vshufps        xm2, xm2, xm3, 0
    vmovd          xm3, [r5]
    vmovd          xm4, [r5 + r3]
    vshufps        xm3, xm3, xm4, 0
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m6
    vpsubw         m0, m0, m2
    vmovd          xm3, [r2 + r3 * 2]
    vmovd          xm4, [r2 + r4]
    vshufps        xm3, xm3, xm4, 0
    vmovd          xm4, [r5 + r3 * 2]
    vmovd          xm2, [r5 + r4]
    vshufps        xm4, xm4, xm2, 0
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m6
    vpsubw         m1, m1, m3

    lea            r0, [r0 + r1 * 8]
    lea            r2, [r2 + r3 * 8]
    lea            r5, [r0 + r1 * 4]
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpunpcklqdq    m0, m2, m3
    vpunpckhqdq    m1, m2, m3
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpblendw       m0, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m1, m2, m3
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpmaxsw        m5, m0, m1

    vmovd          xm0, [r0]
    vmovd          xm1, [r0 + r1]
    vshufps        xm0, xm0, xm1, 0
    vmovd          xm1, [r5]
    vmovd          xm2, [r5 + r1]
    vshufps        xm1, xm1, xm2, 0
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m6
    vmovd          xm1, [r0 + r1 * 2]
    vmovd          xm2, [r0 + r6]
    vshufps        xm1, xm1, xm2, 0
    vmovd          xm2, [r5 + r1 * 2]
    vmovd          xm3, [r5 + r6]
    lea            r5, [r2 + r3 * 4]
    vshufps        xm2, xm2, xm3, 0
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m6
    vmovd          xm2, [r2]
    vmovd          xm3, [r2 + r3]
    vshufps        xm2, xm2, xm3, 0
    vmovd          xm3, [r5]
    vmovd          xm4, [r5 + r3]
    vshufps        xm3, xm3, xm4, 0
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m6
    vpsubw         m0, m0, m2
    vmovd          xm3, [r2 + r3 * 2]
    vmovd          xm4, [r2 + r4]
    vshufps        xm3, xm3, xm4, 0
    vmovd          xm4, [r5 + r3 * 2]
    vmovd          xm2, [r5 + r4]
    vshufps        xm4, xm4, xm2, 0
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m6
    vpsubw         m1, m1, m3

    vpbroadcastd   m6, [pw_1]
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpunpcklqdq    m0, m2, m3
    vpunpckhqdq    m1, m2, m3
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpblendw       m0, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m1, m2, m3
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpmaxsw        m0, m0, m1
    vpaddw         m0, m0, m5
    vpmaddwd       m0, m0, m6

%if WIN64
    vmovdqu        xm6, [rsp + 8]
%endif
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vpunpckhqdq    xm1, xm0, xm0
    vpaddd         xm0, xm0, xm1
    vpshufd        xm1, xm0, 1
    vpaddd         xm0, xm0, xm1
    vmovd          eax, xm0
    RET

INIT_XMM avx2
cglobal pixel_satd_8x4, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], m6
%endif
    vmovdqu        m6, [hmul_8p]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vmovddup       m0, [r0]
    vpmaddubsw     m0, m0, m6
    vmovddup       m1, [r0 + r1]
    vpmaddubsw     m1, m1, m6
    vmovddup       m2, [r2]
    vpmaddubsw     m2, m2, m6
    vmovddup       m3, [r2 + r3]
    vpmaddubsw     m3, m3, m6
    vpsubw         m0, m0, m2
    vpsubw         m1, m1, m3
    vmovddup       m2, [r0 + r1 * 2]
    vpmaddubsw     m2, m2, m6
    vmovddup       m3, [r0 + r6]
    vpmaddubsw     m3, m3, m6
    vmovddup       m4, [r2 + r3 * 2]
    vpmaddubsw     m4, m4, m6
    vmovddup       m5, [r2 + r4]
    vpmaddubsw     m5, m5, m6
    vpsubw         m2, m2, m4
    vpsubw         m3, m3, m5

    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpbroadcastd   m6, [pw_1]
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m2, m2, m3
    vpmaxsw        m2, m2, m1
    vpblendw       m5, m0, m4, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m0, m0, m4
    vpmaxsw        m0, m0, m5
    vpaddw         m2, m2, m0
    vpmaddwd       m2, m2, m6

%if WIN64
    vmovdqu        m6, [rsp + 8]
%endif
    vpunpckhqdq    m5, m2, m2
    vpaddd         m2, m2, m5
    vpshufd        m5, m2, 1
    vpaddd         m2, m2, m5
    vmovd          eax, m2
    ret

INIT_YMM avx2
cglobal pixel_satd_8x8, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
%endif
    vbroadcasti128 m6, [hmul_8p]
    lea            r5, [r0 + r1 * 4]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vmovddup       xm0, [r0]
    vmovddup       xm1, [r5]
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m6
    vmovddup       xm1, [r0 + r1]
    vmovddup       xm2, [r5 + r1]
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m6
    vmovddup       xm2, [r0 + r1 * 2]
    vmovddup       xm3, [r5 + r1 * 2]
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m6
    vmovddup       xm3, [r0 + r6]
    vmovddup       xm4, [r5 + r6]
    lea            r5, [r2 + r3 * 4]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m6
    vmovddup       xm4, [r2]
    vmovddup       xm5, [r5]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m0, m0, m4
    vmovddup       xm4, [r2 + r3]
    vmovddup       xm5, [r5 + r3]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m1, m1, m4
    vmovddup       xm4, [r2 + r3 * 2]
    vmovddup       xm5, [r5 + r3 * 2]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m2, m2, m4
    vmovddup       xm4, [r2 + r4]
    vmovddup       xm5, [r5 + r4]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpbroadcastd   m6, [pw_1]
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m2, m2, m3
    vpmaxsw        m2, m2, m1
    vpblendw       m5, m0, m4, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m0, m0, m4
    vpmaxsw        m0, m0, m5
    vpaddw         m2, m2, m0
    vpmaddwd       m2, m2, m6

%if WIN64
    vmovdqu        xm6, [rsp + 8]
%endif
    vextracti128   xm1, m2, 1
    vpaddd         xm2, xm2, xm1
    vpunpckhqdq    xm5, xm2, xm2
    vpaddd         xm2, xm2, xm5
    vpshufd        xm5, xm2, 1
    vpaddd         xm2, xm2, xm5
    vmovd          eax, xm2
    RET

INIT_YMM avx2
cglobal pixel_satd_8x16, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
%endif
    vbroadcasti128 m6, [hmul_8p]
    lea            r5, [r0 + r1 * 4]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vmovddup       xm0, [r0]
    vmovddup       xm1, [r5]
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m6
    vmovddup       xm1, [r0 + r1]
    vmovddup       xm2, [r5 + r1]
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m6
    vmovddup       xm2, [r0 + r1 * 2]
    vmovddup       xm3, [r5 + r1 * 2]
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m6
    vmovddup       xm3, [r0 + r6]
    vmovddup       xm4, [r5 + r6]
    lea            r5, [r2 + r3 * 4]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m6
    vmovddup       xm4, [r2]
    vmovddup       xm5, [r5]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m0, m0, m4
    vmovddup       xm4, [r2 + r3]
    vmovddup       xm5, [r5 + r3]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m1, m1, m4
    vmovddup       xm4, [r2 + r3 * 2]
    vmovddup       xm5, [r5 + r3 * 2]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m2, m2, m4
    vmovddup       xm4, [r2 + r4]
    vmovddup       xm5, [r5 + r4]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    lea            r0, [r0 + r1 * 8]
    lea            r2, [r2 + r3 * 8]
    lea            r5, [r0 + r1 * 4]
    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m2, m2, m3
    vpmaxsw        m2, m2, m1
    vpblendw       m5, m0, m4, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m0, m0, m4
    vpmaxsw        m0, m0, m5
    vpaddw         m7, m2, m0

    vmovddup       xm0, [r0]
    vmovddup       xm1, [r5]
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m6
    vmovddup       xm1, [r0 + r1]
    vmovddup       xm2, [r5 + r1]
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m6
    vmovddup       xm2, [r0 + r1 * 2]
    vmovddup       xm3, [r5 + r1 * 2]
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m6
    vmovddup       xm3, [r0 + r6]
    vmovddup       xm4, [r5 + r6]
    lea            r5, [r2 + r3 * 4]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m6
    vmovddup       xm4, [r2]
    vmovddup       xm5, [r5]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m0, m0, m4
    vmovddup       xm4, [r2 + r3]
    vmovddup       xm5, [r5 + r3]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m1, m1, m4
    vmovddup       xm4, [r2 + r3 * 2]
    vmovddup       xm5, [r5 + r3 * 2]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m2, m2, m4
    vmovddup       xm4, [r2 + r4]
    vmovddup       xm5, [r5 + r4]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpbroadcastd   m6, [pw_1]
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m2, m2, m3
    vpmaxsw        m2, m2, m1
    vpblendw       m5, m0, m4, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m0, m0, m4
    vpmaxsw        m0, m0, m5
    vpaddw         m2, m2, m0
    vpaddw         m2, m2, m7
    vpmaddwd       m2, m2, m6

%if WIN64
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vextracti128   xm1, m2, 1
    vpaddd         xm2, xm2, xm1
    vpunpckhqdq    xm5, xm2, xm2
    vpaddd         xm2, xm2, xm5
    vpshufd        xm5, xm2, 1
    vpaddd         xm2, xm2, xm5
    vmovd          eax, xm2
    RET

INIT_YMM avx2
cglobal pixel_satd_16x8, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
%endif
    vmovdqu        m6, [hmul_16p]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m6
    vpmaddubsw     m1, m1, m6
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m6
    vpmaddubsw     m2, m2, m6
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m6
    vpmaddubsw     m3, m3, m6
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    vpmaddubsw     m3, m3, m6
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m2, m2, m3
    vpmaxsw        m2, m2, m1
    vpblendw       m5, m0, m4, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m0, m0, m4
    vpmaxsw        m0, m0, m5
    vpaddw         m5, m2, m0

    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m6
    vpmaddubsw     m1, m1, m6
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m6
    vpmaddubsw     m2, m2, m6
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m6
    vpmaddubsw     m3, m3, m6
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    vpmaddubsw     m3, m3, m6
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    vpaddw         m4, m0, m1
    vpsubw         m6, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m6, m1
    vpsubw         m4, m6, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m2, m2, m3
    vpmaxsw        m2, m2, m1
    vpbroadcastd   m1, [pw_1]
    vpblendw       m6, m0, m4, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m0, m0, m4
    vpmaxsw        m0, m0, m6
    vpaddw         m2, m2, m0
    vpaddw         m2, m2, m5
    vpmaddwd       m2, m2, m1

%if WIN64
    vmovdqu        xm6, [rsp + 8]
%endif
    vextracti128   xm1, m2, 1
    vpaddd         xm2, xm2, xm1
    vpunpckhqdq    xm5, xm2, xm2
    vpaddd         xm2, xm2, xm5
    vpshufd        xm5, xm2, 1
    vpaddd         xm2, xm2, xm5
    vmovd          eax, xm2
    RET

INIT_YMM avx2
cglobal pixel_satd_16x16, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
%endif
    vmovdqu        m6, [hmul_16p]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m6
    vpmaddubsw     m1, m1, m6
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m6
    vpmaddubsw     m2, m2, m6
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m6
    vpmaddubsw     m3, m3, m6
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    vpmaddubsw     m3, m3, m6
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m2, m2, m3
    vpmaxsw        m2, m2, m1
    vpblendw       m5, m0, m4, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m0, m0, m4
    vpmaxsw        m0, m0, m5
    vpaddw         m7, m2, m0

    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m6
    vpmaddubsw     m1, m1, m6
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m6
    vpmaddubsw     m2, m2, m6
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m6
    vpmaddubsw     m3, m3, m6
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    vpmaddubsw     m3, m3, m6
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m2, m2, m3
    vpmaxsw        m2, m2, m1
    vpblendw       m5, m0, m4, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m0, m0, m4
    vpmaxsw        m0, m0, m5
    vpaddw         m2, m2, m0
    vpaddw         m7, m2, m7

    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m6
    vpmaddubsw     m1, m1, m6
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m6
    vpmaddubsw     m2, m2, m6
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m6
    vpmaddubsw     m3, m3, m6
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    vpmaddubsw     m3, m3, m6
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m2, m2, m3
    vpmaxsw        m2, m2, m1
    vpblendw       m5, m0, m4, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m0, m0, m4
    vpmaxsw        m0, m0, m5
    vpaddw         m2, m2, m0
    vpaddw         m7, m2, m7

    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m6
    vpmaddubsw     m1, m1, m6
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m6
    vpmaddubsw     m2, m2, m6
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m6
    vpmaddubsw     m3, m3, m6
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    vpmaddubsw     m3, m3, m6
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m2, m2, m3
    vpmaxsw        m2, m2, m1
    vpbroadcastd   m1, [pw_1]
    vpblendw       m5, m0, m4, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m0, m0, m4
    vpmaxsw        m0, m0, m5
    vpaddw         m2, m2, m0
    vpaddw         m2, m2, m7
    vpmaddwd       m2, m2, m1

%if WIN64
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vextracti128   xm1, m2, 1
    vpaddd         xm2, xm2, xm1
    vpunpckhqdq    xm5, xm2, xm2
    vpaddd         xm2, xm2, xm5
    vpshufd        xm5, xm2, 1
    vpaddd         xm2, xm2, xm5
    vmovd          eax, xm2
    RET


;=============================================================================
; SATD X3/X4
;=============================================================================
INIT_YMM avx2
cglobal pixel_satd_x3_4x4, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
%endif
    vpbroadcastq   m6, [hmul_4p]
    lea            r6d, [r4 + r4 * 2]

    vmovd          xm0, [r0]
    vmovd          xm1, [r0 + 16]
    vshufps        xm0, xm0, xm1, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m6
    vmovd          xm1, [r1]
    vinserti128    m1, m1, [r2], 1
    vmovd          xm2, [r1 + r4]
    vinserti128    m2, m2, [r2 + r4], 1
    vshufps        m1, m1, m2, 0
    vpmaddubsw     m1, m1, m6
    vmovd          xm2, [r3]
    vmovd          xm3, [r3 + r4]
    vshufps        xm2, xm2, xm3, 0
    vpmaddubsw     xm2, xm2, xm6
    vpsubw         m1, m0, m1
    vpsubw         xm2, xm0, xm2
    vmovd          xm0, [r0 + 32]
    vmovd          xm3, [r0 + 48]
    vshufps        xm0, xm0, xm3, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m6
    vmovd          xm3, [r1 + r4 * 2]
    vinserti128    m3, m3, [r2 + r4 * 2], 1
    vmovd          xm4, [r1 + r6]
    vinserti128    m4, m4, [r2 + r6], 1
    vshufps        m3, m3, m4, 0
    vpmaddubsw     m3, m3, m6
    vmovd          xm4, [r3 + r4 * 2]
    vmovd          xm5, [r3 + r6]
    vshufps        xm4, xm4, xm5, 0
    vpmaddubsw     xm4, xm4, xm6
    vpsubw         m3, m0, m3
    vpsubw         xm4, xm0, xm4
    
    vpaddw         m5, m1, m3
    vpsubw         m6, m1, m3
    vpaddw         xm0, xm2, xm4
    vpsubw         xm1, xm2, xm4
    vpunpcklqdq    m2, m5, m6
    vpunpckhqdq    m3, m5, m6
    vpunpcklqdq    xm4, xm0, xm1
    vpunpckhqdq    xm5, xm0, xm1
    vpaddw         m0, m2, m3
    vpsubw         m6, m2, m3
    vpaddw         xm2, xm4, xm5
    vpsubw         xm3, xm4, xm5

    vpblendw       m1, m0, m6, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m6, m6, 16
    vpor           m0, m0, m6
    vpabsw         m1, m1
    vpabsw         m0, m0
    vpmaxsw        m0, m0, m1
    vpbroadcastd   m5, [pw_1]
    vpblendw       xm1, xm2, xm3, 0AAh
    vpsrld         xm2, xm2, 16
    vpslld         xm3, xm3, 16
    vpor           xm2, xm2, xm3
    vpabsw         xm1, xm1
    vpabsw         xm2, xm2
    vpmaxsw        xm1, xm1, xm2
    vpmaddwd       m0, m0, m5
    vpmaddwd       xm1, xm1, xm5

%if WIN64
    vmovdqu        xm6, [rsp + 8]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r5], xm0
    RET

INIT_YMM avx2
cglobal pixel_satd_x3_4x8, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 40
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
%endif
    vpbroadcastq   m7, [hmul_4p]
    lea            r6d, [r4 + r4 * 2]

    vmovd          xm0, [r0]
    vmovd          xm1, [r0 + 16]
    vshufps        xm0, xm0, xm1, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m7
    vmovd          xm1, [r1]
    vinserti128    m1, m1, [r2], 1
    vmovd          xm2, [r1 + r4]
    vinserti128    m2, m2, [r2 + r4], 1
    vshufps        m1, m1, m2, 0
    vpmaddubsw     m1, m1, m7
    vmovd          xm2, [r3]
    vmovd          xm3, [r3 + r4]
    vshufps        xm2, xm2, xm3, 0
    vpmaddubsw     xm2, xm2, xm7
    vpsubw         m1, m0, m1
    vpsubw         xm2, xm0, xm2
    vmovd          xm0, [r0 + 32]
    vmovd          xm3, [r0 + 48]
    vshufps        xm0, xm0, xm3, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m7
    vmovd          xm3, [r1 + r4 * 2]
    vinserti128    m3, m3, [r2 + r4 * 2], 1
    vmovd          xm4, [r1 + r6]
    vinserti128    m4, m4, [r2 + r6], 1
    vshufps        m3, m3, m4, 0
    vpmaddubsw     m3, m3, m7
    vmovd          xm4, [r3 + r4 * 2]
    vmovd          xm5, [r3 + r6]
    vshufps        xm4, xm4, xm5, 0
    vpmaddubsw     xm4, xm4, xm7
    vpsubw         m3, m0, m3
    vpsubw         xm4, xm0, xm4
    
    lea            r1, [r1 + r4 * 4]
    lea            r2, [r2 + r4 * 4]
    lea            r3, [r3 + r4 * 4]
    vpaddw         m5, m1, m3
    vpsubw         m6, m1, m3
    vpaddw         xm0, xm2, xm4
    vpsubw         xm1, xm2, xm4
    vpunpcklqdq    m2, m5, m6
    vpunpckhqdq    m3, m5, m6
    vpunpcklqdq    xm4, xm0, xm1
    vpunpckhqdq    xm5, xm0, xm1
    vpaddw         m0, m2, m3
    vpsubw         m6, m2, m3
    vpaddw         xm2, xm4, xm5
    vpsubw         xm3, xm4, xm5

    vpblendw       m1, m0, m6, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m6, m6, 16
    vpor           m0, m0, m6
    vpabsw         m1, m1
    vpabsw         m0, m0
    vpmaxsw        m8, m0, m1
    vpblendw       xm1, xm2, xm3, 0AAh
    vpsrld         xm2, xm2, 16
    vpslld         xm3, xm3, 16
    vpor           xm2, xm2, xm3
    vpabsw         xm1, xm1
    vpabsw         xm2, xm2
    vpmaxsw        xm9, xm1, xm2

    vmovd          xm0, [r0 + 64]
    vmovd          xm1, [r0 + 80]
    vshufps        xm0, xm0, xm1, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m7
    vmovd          xm1, [r1]
    vinserti128    m1, m1, [r2], 1
    vmovd          xm2, [r1 + r4]
    vinserti128    m2, m2, [r2 + r4], 1
    vshufps        m1, m1, m2, 0
    vpmaddubsw     m1, m1, m7
    vmovd          xm2, [r3]
    vmovd          xm3, [r3 + r4]
    vshufps        xm2, xm2, xm3, 0
    vpmaddubsw     xm2, xm2, xm7
    vpsubw         m1, m0, m1
    vpsubw         xm2, xm0, xm2
    vmovd          xm0, [r0 + 96]
    vmovd          xm3, [r0 + 112]
    vshufps        xm0, xm0, xm3, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m7
    vmovd          xm3, [r1 + r4 * 2]
    vinserti128    m3, m3, [r2 + r4 * 2], 1
    vmovd          xm4, [r1 + r6]
    vinserti128    m4, m4, [r2 + r6], 1
    vshufps        m3, m3, m4, 0
    vpmaddubsw     m3, m3, m7
    vmovd          xm4, [r3 + r4 * 2]
    vmovd          xm5, [r3 + r6]
    vshufps        xm4, xm4, xm5, 0
    vpmaddubsw     xm4, xm4, xm7
    vpsubw         m3, m0, m3
    vpsubw         xm4, xm0, xm4
    
    vpaddw         m5, m1, m3
    vpsubw         m6, m1, m3
    vpaddw         xm0, xm2, xm4
    vpsubw         xm1, xm2, xm4
    vpunpcklqdq    m2, m5, m6
    vpunpckhqdq    m3, m5, m6
    vpunpcklqdq    xm4, xm0, xm1
    vpunpckhqdq    xm5, xm0, xm1
    vpaddw         m0, m2, m3
    vpsubw         m6, m2, m3
    vpaddw         xm2, xm4, xm5
    vpsubw         xm3, xm4, xm5

    vpbroadcastd   m5, [pw_1]
    vpblendw       m1, m0, m6, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m6, m6, 16
    vpor           m0, m0, m6
    vpabsw         m1, m1
    vpabsw         m0, m0
    vpmaxsw        m0, m0, m1
    vpaddw         m0, m0, m8
    vpmaddwd       m0, m0, m5
    vpblendw       xm1, xm2, xm3, 0AAh
    vpsrld         xm2, xm2, 16
    vpslld         xm3, xm3, 16
    vpor           xm2, xm2, xm3
    vpabsw         xm1, xm1
    vpabsw         xm2, xm2
    vpmaxsw        xm1, xm1, xm2
    vpaddw         xm1, xm1, xm9
    vpmaddwd       xm1, xm1, xm5

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    add            rsp, 40
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r5], xm0
    RET

INIT_YMM avx2
cglobal pixel_satd_x3_8x4, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 40
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
%endif
    vbroadcasti128 m9, [hmul_8p]
    lea            r6d, [r4 + r4 * 2]

    vpbroadcastq   m0, [r0]
    vpmaddubsw     m0, m0, m9
    vmovddup       xm1, [r1]
    vmovddup       xm2, [r2]
    vinserti128    m1, m1, xm2, 1
    vmovddup       xm2, [r3]
    vpmaddubsw     m1, m1, m9
    vpmaddubsw     xm2, xm2, xm9
    vpsubw         m1, m0, m1
    vpsubw         xm2, xm0, xm2
    vpbroadcastq   m0, [r0 + 16]
    vpmaddubsw     m0, m0, m9
    vmovddup       xm3, [r1 + r4]
    vmovddup       xm4, [r2 + r4]
    vinserti128    m3, m3, xm4, 1
    vmovddup       xm4, [r3 + r4]
    vpmaddubsw     m3, m3, m9
    vpmaddubsw     xm4, xm4, xm9
    vpsubw         m3, m0, m3
    vpsubw         xm4, xm0, xm4
    vpbroadcastq   m0, [r0 + 32]
    vpmaddubsw     m0, m0, m9
    vmovddup       xm5, [r1 + r4 * 2]
    vmovddup       xm6, [r2 + r4 * 2]
    vinserti128    m5, m5, xm6, 1
    vmovddup       xm6, [r3 + r4 * 2]
    vpmaddubsw     m5, m5, m9
    vpmaddubsw     xm6, xm6, xm9
    vpsubw         m5, m0, m5
    vpsubw         xm6, xm0, xm6
    vpbroadcastq   m0, [r0 + 48]
    vpmaddubsw     m0, m0, m9
    vmovddup       xm7, [r1 + r6]
    vmovddup       xm8, [r2 + r6]
    vinserti128    m7, m7, xm8, 1
    vmovddup       xm8, [r3 + r6]
    vpmaddubsw     m7, m7, m9
    vpmaddubsw     xm8, xm8, xm9
    vpsubw         m7, m0, m7
    vpsubw         xm8, xm0, xm8

    vpaddw         m0, m1, m3
    vpsubw         m9, m1, m3
    vpaddw         m1, m5, m7
    vpsubw         m3, m5, m7
    vpaddw         m5, m0, m1
    vpsubw         m7, m0, m1
    vpaddw         m0, m9, m3
    vpsubw         m1, m9, m3
    vpabsw         m5, m5
    vpabsw         m7, m7
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpblendw       m3, m5, m7, 0AAh
    vpsrld         m5, m5, 16
    vpslld         m7, m7, 16
    vpor           m5, m5, m7
    vpmaxsw        m5, m5, m3
    vpblendw       m9, m0, m1, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m1, m1, 16
    vpor           m0, m0, m1
    vpmaxsw        m0, m0, m9
    vpaddw         m0, m0, m5

    vpaddw         xm1, xm2, xm4
    vpsubw         xm3, xm2, xm4
    vpaddw         xm2, xm6, xm8
    vpsubw         xm4, xm6, xm8
    vpaddw         xm6, xm1, xm2
    vpsubw         xm8, xm1, xm2
    vpaddw         xm1, xm3, xm4
    vpsubw         xm2, xm3, xm4
    vpabsw         xm6, xm6
    vpabsw         xm8, xm8
    vpabsw         xm1, xm1
    vpabsw         xm2, xm2
    vpbroadcastd   m9, [pw_1]
    vpblendw       xm3, xm6, xm8, 0AAh
    vpsrld         xm6, xm6, 16
    vpslld         xm8, xm8, 16
    vpor           xm6, xm6, xm8
    vpmaxsw        xm6, xm6, xm3
    vpblendw       xm5, xm1, xm2, 0AAh
    vpsrld         xm1, xm1, 16
    vpslld         xm2, xm2, 16
    vpor           xm1, xm1, xm2
    vpmaxsw        xm1, xm1, xm5
    vpaddw         xm6, xm6, xm1
    vpmaddwd       m0, m0, m9
    vpmaddwd       xm1, xm6, xm9

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    add            rsp, 40
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r5], xm0
    RET


INIT_YMM avx2
cglobal pixel_satd_x3_8xN_internal, 0, 0
    vpbroadcastq   m0, [r0]
    vpmaddubsw     m0, m0, m12
    vmovddup       xm1, [r1]
    vmovddup       xm2, [r2]
    vinserti128    m1, m1, xm2, 1
    vmovddup       xm2, [r3]
    vpmaddubsw     m1, m1, m12
    vpmaddubsw     xm2, xm2, xm12
    vpsubw         m1, m0, m1
    vpsubw         xm2, xm0, xm2
    vpbroadcastq   m0, [r0 + 16]
    vpmaddubsw     m0, m0, m12
    vmovddup       xm3, [r1 + r4]
    vmovddup       xm4, [r2 + r4]
    vinserti128    m3, m3, xm4, 1
    vmovddup       xm4, [r3 + r4]
    vpmaddubsw     m3, m3, m12
    vpmaddubsw     xm4, xm4, xm12
    vpsubw         m3, m0, m3
    vpsubw         xm4, xm0, xm4
    vpbroadcastq   m0, [r0 + 32]
    vpmaddubsw     m0, m0, m12
    vmovddup       xm5, [r1 + r4 * 2]
    vmovddup       xm6, [r2 + r4 * 2]
    vinserti128    m5, m5, xm6, 1
    vmovddup       xm6, [r3 + r4 * 2]
    vpmaddubsw     m5, m5, m12
    vpmaddubsw     xm6, xm6, xm12
    vpsubw         m5, m0, m5
    vpsubw         xm6, xm0, xm6
    vpbroadcastq   m0, [r0 + 48]
    vpmaddubsw     m0, m0, m12
    vmovddup       xm7, [r1 + r6]
    vmovddup       xm8, [r2 + r6]
    vinserti128    m7, m7, xm8, 1
    vmovddup       xm8, [r3 + r6]
    vpmaddubsw     m7, m7, m12
    vpmaddubsw     xm8, xm8, xm12
    vpsubw         m7, m0, m7
    vpsubw         xm8, xm0, xm8

    add            r0, 64
    lea            r1, [r1 + r4 * 4]
    lea            r2, [r2 + r4 * 4]
    lea            r3, [r3 + r4 * 4]
    vpaddw         m0, m1, m3
    vpsubw         m9, m1, m3
    vpaddw         m1, m5, m7
    vpsubw         m3, m5, m7
    vpaddw         m5, m0, m1
    vpsubw         m7, m0, m1
    vpaddw         m0, m9, m3
    vpsubw         m1, m9, m3
    vpabsw         m5, m5
    vpabsw         m7, m7
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpblendw       m3, m5, m7, 0AAh
    vpsrld         m5, m5, 16
    vpslld         m7, m7, 16
    vpor           m5, m5, m7
    vpmaxsw        m5, m5, m3
    vpblendw       m9, m0, m1, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m1, m1, 16
    vpor           m0, m0, m1
    vpmaxsw        m0, m0, m9
    vpaddw         m0, m0, m5
    vpaddw         m10, m0, m10

    vpaddw         xm1, xm2, xm4
    vpsubw         xm3, xm2, xm4
    vpaddw         xm2, xm6, xm8
    vpsubw         xm4, xm6, xm8
    vpaddw         xm6, xm1, xm2
    vpsubw         xm8, xm1, xm2
    vpaddw         xm1, xm3, xm4
    vpsubw         xm2, xm3, xm4
    vpabsw         xm6, xm6
    vpabsw         xm8, xm8
    vpabsw         xm1, xm1
    vpabsw         xm2, xm2
    vpblendw       xm3, xm6, xm8, 0AAh
    vpsrld         xm6, xm6, 16
    vpslld         xm8, xm8, 16
    vpor           xm6, xm6, xm8
    vpmaxsw        xm6, xm6, xm3
    vpblendw       xm5, xm1, xm2, 0AAh
    vpsrld         xm1, xm1, 16
    vpslld         xm2, xm2, 16
    vpor           xm1, xm1, xm2
    vpmaxsw        xm1, xm1, xm5
    vpaddw         xm6, xm6, xm1
    vpaddw         xm11, xm6, xm11
    ret

INIT_YMM avx2
cglobal pixel_satd_x3_8x8, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 88
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
%endif
    vbroadcasti128 m12, [hmul_8p]
    lea            r6d, [r4 + r4 * 2]
    vpxor          m10, m10, m10
    vpxor          m11, m11, m11
    call           pixel_satd_x3_8xN_internal
    call           pixel_satd_x3_8xN_internal
    vpbroadcastd   m9, [pw_1]
    vpmaddwd       m0, m10, m9
    vpmaddwd       xm1, xm11, xm9

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    add            rsp, 88
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r5], xm0
    RET

INIT_YMM avx2
cglobal pixel_satd_x3_8x16, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 88
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
%endif
    vbroadcasti128 m12, [hmul_8p]
    lea            r6d, [r4 + r4 * 2]
    vpxor          m10, m10, m10
    vpxor          m11, m11, m11
    call           pixel_satd_x3_8xN_internal
    call           pixel_satd_x3_8xN_internal
    call           pixel_satd_x3_8xN_internal
    call           pixel_satd_x3_8xN_internal
    vpbroadcastd   m9, [pw_1]
    vpmaddwd       m0, m10, m9
    vpmaddwd       xm1, xm11, xm9

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    add            rsp, 88
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r5], xm0
    RET


INIT_YMM avx2
cglobal pixel_satd_x3_16xN_internal, 0, 0
    vbroadcasti128 m0, [r0]
    vpmaddubsw     m0, m0, m13
    vbroadcasti128 m1, [r0 + 16]
    vpmaddubsw     m1, m1, m13
    vbroadcasti128 m2, [r0 + 32]
    vpmaddubsw     m2, m2, m13
    vbroadcasti128 m3, [r0 + 48]
    vpmaddubsw     m3, m3, m13
    add            r0, 64

    vbroadcasti128 m4, [r1]
    vpmaddubsw     m4, m4, m13
    vpsubw         m4, m0, m4
    vbroadcasti128 m5, [r1 + r4]
    vpmaddubsw     m5, m5, m13
    vpsubw         m5, m1, m5
    vbroadcasti128 m6, [r1 + r4 * 2]
    vpmaddubsw     m6, m6, m13
    vpsubw         m6, m2, m6
    vbroadcasti128 m7, [r1 + r6]
    vpmaddubsw     m7, m7, m13
    vpsubw         m7, m3, m7

    lea            r1, [r1 + r4 * 4]
    vpaddw         m8, m4, m5
    vpsubw         m9, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m4
    vpsubw         m7, m8, m4
    vpaddw         m8, m9, m5
    vpsubw         m4, m9, m5
    vpabsw         m6, m6
    vpabsw         m7, m7
    vpabsw         m8, m8
    vpabsw         m4, m4
    vpblendw       m9, m6, m7, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m7, m7, 16
    vpor           m6, m6, m7
    vpmaxsw        m6, m6, m9
    vpblendw       m5, m8, m4, 0AAh
    vpsrld         m8, m8, 16
    vpslld         m4, m4, 16
    vpor           m8, m8, m4
    vpmaxsw        m8, m8, m5
    vpaddw         m6, m6, m8
    vpaddw         m10, m6, m10

    vbroadcasti128 m4, [r2]
    vpmaddubsw     m4, m4, m13
    vpsubw         m4, m0, m4
    vbroadcasti128 m5, [r2 + r4]
    vpmaddubsw     m5, m5, m13
    vpsubw         m5, m1, m5
    vbroadcasti128 m6, [r2 + r4 * 2]
    vpmaddubsw     m6, m6, m13
    vpsubw         m6, m2, m6
    vbroadcasti128 m7, [r2 + r6]
    vpmaddubsw     m7, m7, m13
    vpsubw         m7, m3, m7

    lea            r2, [r2 + r4 * 4]
    vpaddw         m8, m4, m5
    vpsubw         m9, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m4
    vpsubw         m7, m8, m4
    vpaddw         m8, m9, m5
    vpsubw         m4, m9, m5
    vpabsw         m6, m6
    vpabsw         m7, m7
    vpabsw         m8, m8
    vpabsw         m4, m4
    vpblendw       m9, m6, m7, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m7, m7, 16
    vpor           m6, m6, m7
    vpmaxsw        m6, m6, m9
    vpblendw       m5, m8, m4, 0AAh
    vpsrld         m8, m8, 16
    vpslld         m4, m4, 16
    vpor           m8, m8, m4
    vpmaxsw        m8, m8, m5
    vpaddw         m6, m6, m8
    vpaddw         m11, m6, m11

    vbroadcasti128 m4, [r3]
    vpmaddubsw     m4, m4, m13
    vpsubw         m4, m0, m4
    vbroadcasti128 m5, [r3 + r4]
    vpmaddubsw     m5, m5, m13
    vpsubw         m5, m1, m5
    vbroadcasti128 m6, [r3 + r4 * 2]
    vpmaddubsw     m6, m6, m13
    vpsubw         m6, m2, m6
    vbroadcasti128 m7, [r3 + r6]
    vpmaddubsw     m7, m7, m13
    vpsubw         m7, m3, m7

    lea            r3, [r3 + r4 * 4]
    vpaddw         m8, m4, m5
    vpsubw         m9, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m4
    vpsubw         m7, m8, m4
    vpaddw         m8, m9, m5
    vpsubw         m4, m9, m5
    vpabsw         m6, m6
    vpabsw         m7, m7
    vpabsw         m8, m8
    vpabsw         m4, m4
    vpblendw       m9, m6, m7, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m7, m7, 16
    vpor           m6, m6, m7
    vpmaxsw        m6, m6, m9
    vpblendw       m5, m8, m4, 0AAh
    vpsrld         m8, m8, 16
    vpslld         m4, m4, 16
    vpor           m8, m8, m4
    vpmaxsw        m8, m8, m5
    vpaddw         m6, m6, m8
    vpaddw         m12, m6, m12
    ret

INIT_YMM avx2
cglobal pixel_satd_x3_16x8, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 104
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
    vmovdqu        [rsp + 80], xm13
%endif
    vmovdqu        m13, [hmul_16p]
    lea            r6d, [r4 + r4 * 2]
    vpxor          m10, m10, m10
    vpxor          m11, m11, m11
    vpxor          m12, m12, m12
    call           pixel_satd_x3_16xN_internal
    call           pixel_satd_x3_16xN_internal
    vpbroadcastd   m3, [pw_1]
    vpmaddwd       m0, m10, m3
    vpmaddwd       m1, m11, m3
    vpmaddwd       m2, m12, m3

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    vmovdqu        xm13, [rsp + 80]
    add            rsp, 104
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vphaddd        m0, m0, m1
    vpunpckhqdq    m3, m2, m2
    vpaddd         m2, m2, m3
    vphaddd        m0, m0, m2
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovdqu        [r5], xm0
    RET

INIT_YMM avx2
cglobal pixel_satd_x3_16x16, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
    mov            r5, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 104
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
    vmovdqu        [rsp + 80], xm13
%endif
    vmovups        m13, [hmul_16p]
    lea            r6d, [r4 + r4 * 2]
    vpxor          m10, m10, m10
    vpxor          m11, m11, m11
    vpxor          m12, m12, m12
    call           pixel_satd_x3_16xN_internal
    call           pixel_satd_x3_16xN_internal
    call           pixel_satd_x3_16xN_internal
    call           pixel_satd_x3_16xN_internal
    vpbroadcastd   m3, [pw_1]
    vpmaddwd       m0, m10, m3
    vpmaddwd       m1, m11, m3
    vpmaddwd       m2, m12, m3

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    vmovdqu        xm13, [rsp + 80]
    add            rsp, 104
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vphaddd        m0, m0, m1
    vpunpckhqdq    m3, m2, m2
    vpaddd         m2, m2, m3
    vphaddd        m0, m0, m2
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovdqu        [r5], xm0
    RET


INIT_YMM avx2
cglobal pixel_satd_x4_4x4, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
%endif
    vpbroadcastq   m6, [hmul_4p]
    lea            r6d, [r5 + r5 * 2]

    vmovd          xm0, [r0]
    vmovd          xm1, [r0 + 16]
    vshufps        xm0, xm0, xm1, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m6
    vmovd          xm1, [r1]
    vinserti128    m1, m1, [r2], 1
    vmovd          xm2, [r1 + r5]
    vinserti128    m2, m2, [r2 + r5], 1
    vshufps        m1, m1, m2, 0
    vpmaddubsw     m1, m1, m6
    vmovd          xm2, [r3]
    vinserti128    m2, m2, [r4], 1
    vmovd          xm3, [r3 + r5]
    vinserti128    m3, m3, [r4 + r5], 1
    vshufps        m2, m2, m3, 0
    vpmaddubsw     m2, m2, m6
    vpsubw         m1, m0, m1
    vpsubw         m2, m0, m2

    vmovd          xm0, [r0 + 32]
    vmovd          xm3, [r0 + 48]
    vshufps        xm0, xm0, xm3, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m6
    vmovd          xm3, [r1 + r5 * 2]
    vinserti128    m3, m3, [r2 + r5 * 2], 1
    vmovd          xm4, [r1 + r6]
    vinserti128    m4, m4, [r2 + r6], 1
    vshufps        m3, m3, m4, 0
    vpmaddubsw     m3, m3, m6
    vmovd          xm4, [r3 + r5 * 2]
    vinserti128    m4, m4, [r4 + r5 * 2], 1
    vmovd          xm5, [r3 + r6]
    vinserti128    m5, m5, [r4 + r6], 1
    vshufps        m4, m4, m5, 0
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m0, m3
    vpsubw         m4, m0, m4
    
    vpaddw         m5, m1, m3
    vpsubw         m6, m1, m3
    vpaddw         m0, m2, m4
    vpsubw         m1, m2, m4
    vpunpcklqdq    m2, m5, m6
    vpunpckhqdq    m3, m5, m6
    vpunpcklqdq    m4, m0, m1
    vpunpckhqdq    m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m6, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5

    vpbroadcastd   m5, [pw_1]
    vpblendw       m1, m0, m6, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m6, m6, 16
    vpor           m0, m0, m6
    vpabsw         m1, m1
    vpabsw         m0, m0
    vpmaxsw        m0, m0, m1
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m2, m2, m3
    vpabsw         m1, m1
    vpabsw         m2, m2
    vpmaxsw        m1, m1, m2
    vpmaddwd       m0, m0, m5
    vpmaddwd       m1, m1, m5

%if WIN64
    vmovdqu        [rsp + 8], xm6
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r6], xm0
    RET

INIT_YMM avx2
cglobal pixel_satd_x4_4x8, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 40
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
%endif
    vpbroadcastq   m7, [hmul_4p]
    lea            r6d, [r5 + r5 * 2]

    vmovd          xm0, [r0]
    vmovd          xm1, [r0 + 16]
    vshufps        xm0, xm0, xm1, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m7
    vmovd          xm1, [r1]
    vinserti128    m1, m1, [r2], 1
    vmovd          xm2, [r1 + r5]
    vinserti128    m2, m2, [r2 + r5], 1
    vshufps        m1, m1, m2, 0
    vpmaddubsw     m1, m1, m7
    vmovd          xm2, [r3]
    vinserti128    m2, m2, [r4], 1
    vmovd          xm3, [r3 + r5]
    vinserti128    m3, m3, [r4 + r5], 1
    vshufps        m2, m2, m3, 0
    vpmaddubsw     m2, m2, m7
    vpsubw         m1, m0, m1
    vpsubw         m2, m0, m2
    vmovd          xm0, [r0 + 32]
    vmovd          xm3, [r0 + 48]
    vshufps        xm0, xm0, xm3, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m7
    vmovd          xm3, [r1 + r5 * 2]
    vinserti128    m3, m3, [r2 + r5 * 2], 1
    vmovd          xm4, [r1 + r6]
    vinserti128    m4, m4, [r2 + r6], 1
    vshufps        m3, m3, m4, 0
    vpmaddubsw     m3, m3, m7
    vmovd          xm4, [r3 + r5 * 2]
    vinserti128    m4, m4, [r4 + r5 * 2], 1
    vmovd          xm5, [r3 + r6]
    vinserti128    m5, m5, [r4 + r6], 1
    vshufps        m4, m4, m5, 0
    vpmaddubsw     m4, m4, m7
    vpsubw         m3, m0, m3
    vpsubw         m4, m0, m4
    
    lea            r1, [r1 + r5 * 4]
    lea            r2, [r2 + r5 * 4]
    lea            r3, [r3 + r5 * 4]
    lea            r4, [r4 + r5 * 4]
    vpaddw         m5, m1, m3
    vpsubw         m6, m1, m3
    vpaddw         m0, m2, m4
    vpsubw         m1, m2, m4
    vpunpcklqdq    m2, m5, m6
    vpunpckhqdq    m3, m5, m6
    vpunpcklqdq    m4, m0, m1
    vpunpckhqdq    m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m6, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5

    vpblendw       m1, m0, m6, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m6, m6, 16
    vpor           m0, m0, m6
    vpabsw         m1, m1
    vpabsw         m0, m0
    vpmaxsw        m8, m0, m1
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m2, m2, m3
    vpabsw         m1, m1
    vpabsw         m2, m2
    vpmaxsw        m9, m1, m2

    vmovd          xm0, [r0 + 64]
    vmovd          xm1, [r0 + 80]
    vshufps        xm0, xm0, xm1, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m7
    vmovd          xm1, [r1]
    vinserti128    m1, m1, [r2], 1
    vmovd          xm2, [r1 + r5]
    vinserti128    m2, m2, [r2 + r5], 1
    vshufps        m1, m1, m2, 0
    vpmaddubsw     m1, m1, m7
    vmovd          xm2, [r3]
    vinserti128    m2, m2, [r4], 1
    vmovd          xm3, [r3 + r5]
    vinserti128    m3, m3, [r4 + r5], 1
    vshufps        m2, m2, m3, 0
    vpmaddubsw     m2, m2, m7
    vpsubw         m1, m0, m1
    vpsubw         m2, m0, m2
    vmovd          xm0, [r0 + 96]
    vmovd          xm3, [r0 + 112]
    vshufps        xm0, xm0, xm3, 0
    vinserti128    m0, m0, xm0, 1
    vpmaddubsw     m0, m0, m7
    vmovd          xm3, [r1 + r5 * 2]
    vinserti128    m3, m3, [r2 + r5 * 2], 1
    vmovd          xm4, [r1 + r6]
    vinserti128    m4, m4, [r2 + r6], 1
    vshufps        m3, m3, m4, 0
    vpmaddubsw     m3, m3, m7
    vmovd          xm4, [r3 + r5 * 2]
    vinserti128    m4, m4, [r4 + r5 * 2], 1
    vmovd          xm5, [r3 + r6]
    vinserti128    m5, m5, [r4 + r6], 1
    vshufps        m4, m4, m5, 0
    vpmaddubsw     m4, m4, m7
    vpsubw         m3, m0, m3
    vpsubw         m4, m0, m4
    
    vpaddw         m5, m1, m3
    vpsubw         m6, m1, m3
    vpaddw         m0, m2, m4
    vpsubw         m1, m2, m4
    vpunpcklqdq    m2, m5, m6
    vpunpckhqdq    m3, m5, m6
    vpunpcklqdq    m4, m0, m1
    vpunpckhqdq    m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m6, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5

    vpbroadcastd   m5, [pw_1]
    vpblendw       m1, m0, m6, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m6, m6, 16
    vpor           m0, m0, m6
    vpabsw         m1, m1
    vpabsw         m0, m0
    vpmaxsw        m0, m0, m1
    vpaddw         m0, m0, m8
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m2, m2, m3
    vpabsw         m1, m1
    vpabsw         m2, m2
    vpmaxsw        m1, m1, m2
    vpaddw         m1, m1, m9

    vpmaddwd       m0, m0, m5
    vpmaddwd       m1, m1, m5

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    add            rsp, 40
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r6], xm0
    RET

INIT_YMM avx2
cglobal pixel_satd_x4_8x4, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 56
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
%endif
    vbroadcasti128 m9, [hmul_8p]
    lea            r6d, [r5 + r5 * 2]

    vpbroadcastq   m0, [r0]
    vpmaddubsw     m0, m0, m9
    vmovddup       xm1, [r1]
    vmovddup       xm2, [r2]
    vinserti128    m1, m1, xm2, 1
    vmovddup       xm2, [r3]
    vmovddup       xm3, [r4]
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m1, m1, m9
    vpmaddubsw     m2, m2, m9
    vpsubw         m1, m0, m1
    vpsubw         m2, m0, m2
    vpbroadcastq   m0, [r0 + 16]
    vpmaddubsw     m0, m0, m9
    vmovddup       xm3, [r1 + r5]
    vmovddup       xm4, [r2 + r5]
    vinserti128    m3, m3, xm4, 1
    vmovddup       xm4, [r3 + r5]
    vmovddup       xm5, [r4 + r5]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m3, m3, m9
    vpmaddubsw     m4, m4, m9
    vpsubw         m3, m0, m3
    vpsubw         m4, m0, m4
    vpbroadcastq   m0, [r0 + 32]
    vpmaddubsw     m0, m0, m9
    vmovddup       xm5, [r1 + r5 * 2]
    vmovddup       xm6, [r2 + r5 * 2]
    vinserti128    m5, m5, xm6, 1
    vmovddup       xm6, [r3 + r5 * 2]
    vmovddup       xm7, [r4 + r5 * 2]
    vinserti128    m6, m6, xm7, 1
    vpmaddubsw     m5, m5, m9
    vpmaddubsw     m6, m6, m9
    vpsubw         m5, m0, m5
    vpsubw         m6, m0, m6
    vpbroadcastq   m0, [r0 + 48]
    vpmaddubsw     m0, m0, m9
    vmovddup       xm7, [r1 + r6]
    vmovddup       xm8, [r2 + r6]
    vinserti128    m7, m7, xm8, 1
    vmovddup       xm8, [r3 + r6]
    vmovddup       xm10, [r4 + r6]
    vinserti128    m8, m8, xm10, 1
    vpmaddubsw     m7, m7, m9
    vpmaddubsw     m8, m8, m9
    vpsubw         m7, m0, m7
    vpsubw         m8, m0, m8

    vpaddw         m0, m1, m3
    vpsubw         m9, m1, m3
    vpaddw         m1, m5, m7
    vpsubw         m3, m5, m7
    vpaddw         m5, m0, m1
    vpsubw         m7, m0, m1
    vpaddw         m0, m9, m3
    vpsubw         m1, m9, m3
    vpabsw         m5, m5
    vpabsw         m7, m7
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpblendw       m3, m5, m7, 0AAh
    vpsrld         m5, m5, 16
    vpslld         m7, m7, 16
    vpor           m5, m5, m7
    vpmaxsw        m5, m5, m3
    vpblendw       m9, m0, m1, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m1, m1, 16
    vpor           m0, m0, m1
    vpmaxsw        m0, m0, m9
    vpaddw         m0, m0, m5

    vpaddw         m1, m2, m4
    vpsubw         m3, m2, m4
    vpaddw         m2, m6, m8
    vpsubw         m4, m6, m8
    vpaddw         m6, m1, m2
    vpsubw         m8, m1, m2
    vpaddw         m1, m3, m4
    vpsubw         m2, m3, m4
    vpabsw         m6, m6
    vpabsw         m8, m8
    vpabsw         m1, m1
    vpabsw         m2, m2
    vpbroadcastd   m9, [pw_1]
    vpblendw       m3, m6, m8, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m8, m8, 16
    vpor           m6, m6, m8
    vpmaxsw        m6, m6, m3
    vpblendw       m5, m1, m2, 0AAh
    vpsrld         m1, m1, 16
    vpslld         m2, m2, 16
    vpor           m1, m1, m2
    vpmaxsw        m1, m1, m5
    vpaddw         m6, m6, m1

    vpmaddwd       m0, m0, m9
    vpmaddwd       m1, m6, m9

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    add            rsp, 56
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r6], xm0
    RET


INIT_YMM avx2
cglobal pixel_satd_x4_8xN_internal, 0, 0
    vpbroadcastq   m0, [r0]
    vpmaddubsw     m0, m0, m12
    vmovddup       xm1, [r1]
    vmovddup       xm2, [r2]
    vinserti128    m1, m1, xm2, 1
    vmovddup       xm2, [r3]
    vmovddup       xm3, [r4]
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m1, m1, m12
    vpmaddubsw     m2, m2, m12
    vpsubw         m1, m0, m1
    vpsubw         m2, m0, m2
    vpbroadcastq   m0, [r0 + 16]
    vpmaddubsw     m0, m0, m12
    vmovddup       xm3, [r1 + r5]
    vmovddup       xm4, [r2 + r5]
    vinserti128    m3, m3, xm4, 1
    vmovddup       xm4, [r3 + r5]
    vmovddup       xm5, [r4 + r5]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m3, m3, m12
    vpmaddubsw     m4, m4, m12
    vpsubw         m3, m0, m3
    vpsubw         m4, m0, m4
    vpbroadcastq   m0, [r0 + 32]
    vpmaddubsw     m0, m0, m12
    vmovddup       xm5, [r1 + r5 * 2]
    vmovddup       xm6, [r2 + r5 * 2]
    vinserti128    m5, m5, xm6, 1
    vmovddup       xm6, [r3 + r5 * 2]
    vmovddup       xm7, [r4 + r5 * 2]
    vinserti128    m6, m6, xm7, 1
    vpmaddubsw     m5, m5, m12
    vpmaddubsw     m6, m6, m12
    vpsubw         m5, m0, m5
    vpsubw         m6, m0, m6
    vpbroadcastq   m0, [r0 + 48]
    vpmaddubsw     m0, m0, m12
    vmovddup       xm7, [r1 + r6]
    vmovddup       xm8, [r2 + r6]
    vinserti128    m7, m7, xm8, 1
    vmovddup       xm8, [r3 + r6]
    vmovddup       xm9, [r4 + r6]
    vinserti128    m8, m8, xm9, 1
    vpmaddubsw     m7, m7, m12
    vpmaddubsw     m8, m8, m12
    vpsubw         m7, m0, m7
    vpsubw         m8, m0, m8

    add            r0, 64
    lea            r1, [r1 + r5 * 4]
    lea            r2, [r2 + r5 * 4]
    lea            r3, [r3 + r5 * 4]
    lea            r4, [r4 + r5 * 4]
    vpaddw         m0, m1, m3
    vpsubw         m9, m1, m3
    vpaddw         m1, m5, m7
    vpsubw         m3, m5, m7
    vpaddw         m5, m0, m1
    vpsubw         m7, m0, m1
    vpaddw         m0, m9, m3
    vpsubw         m1, m9, m3
    vpabsw         m5, m5
    vpabsw         m7, m7
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpblendw       m3, m5, m7, 0AAh
    vpsrld         m5, m5, 16
    vpslld         m7, m7, 16
    vpor           m5, m5, m7
    vpmaxsw        m5, m5, m3
    vpblendw       m9, m0, m1, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m1, m1, 16
    vpor           m0, m0, m1
    vpmaxsw        m0, m0, m9
    vpaddw         m0, m0, m5
    vpaddw         m10, m0, m10

    vpaddw         m1, m2, m4
    vpsubw         m3, m2, m4
    vpaddw         m2, m6, m8
    vpsubw         m4, m6, m8
    vpaddw         m6, m1, m2
    vpsubw         m8, m1, m2
    vpaddw         m1, m3, m4
    vpsubw         m2, m3, m4
    vpabsw         m6, m6
    vpabsw         m8, m8
    vpabsw         m1, m1
    vpabsw         m2, m2
    vpblendw       m3, m6, m8, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m8, m8, 16
    vpor           m6, m6, m8
    vpmaxsw        m6, m6, m3
    vpblendw       m5, m1, m2, 0AAh
    vpsrld         m1, m1, 16
    vpslld         m2, m2, 16
    vpor           m1, m1, m2
    vpmaxsw        m1, m1, m5
    vpaddw         m6, m6, m1
    vpaddw         m11, m6, m11
    ret

INIT_YMM avx2
cglobal pixel_satd_x4_8x8, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 88
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
%endif
    vbroadcasti128 m12, [hmul_8p]
    lea            r6d, [r5 + r5 * 2]
    vpxor          m10, m10, m10
    vpxor          m11, m11, m11
    call           pixel_satd_x4_8xN_internal
    call           pixel_satd_x4_8xN_internal
    vpbroadcastd   m9, [pw_1]
    vpmaddwd       m0, m10, m9
    vpmaddwd       m1, m11, m9

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    add            rsp, 88
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r6], xm0
    RET

INIT_YMM avx2
cglobal pixel_satd_x4_8x16, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 88
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
%endif
    vbroadcasti128 m12, [hmul_8p]
    lea            r6d, [r5 + r5 * 2]
    vpxor          m10, m10, m10
    vpxor          m11, m11, m11
    call           pixel_satd_x4_8xN_internal
    call           pixel_satd_x4_8xN_internal
    call           pixel_satd_x4_8xN_internal
    call           pixel_satd_x4_8xN_internal
    vpbroadcastd   m9, [pw_1]
    vpmaddwd       m0, m10, m9
    vpmaddwd       m1, m11, m9

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    add            rsp, 88
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m0, m0, m0
    vextracti128   xm1, m0, 1
    vpunpckldq     xm0, xm0, xm1
    vmovdqu        [r6], xm0
    RET


INIT_YMM avx2
cglobal pixel_satd_x4_16xN_internal, 0, 0
    vbroadcasti128 m0, [r0]
    vpmaddubsw     m0, m0, m13
    vbroadcasti128 m1, [r0 + 16]
    vpmaddubsw     m1, m1, m13
    vbroadcasti128 m2, [r0 + 32]
    vpmaddubsw     m2, m2, m13
    vbroadcasti128 m3, [r0 + 48]
    vpmaddubsw     m3, m3, m13
    add            r0, 64

    vbroadcasti128 m4, [r1]
    vpmaddubsw     m4, m4, m13
    vpsubw         m4, m0, m4
    vbroadcasti128 m5, [r1 + r5]
    vpmaddubsw     m5, m5, m13
    vpsubw         m5, m1, m5
    vbroadcasti128 m6, [r1 + r5 * 2]
    vpmaddubsw     m6, m6, m13
    vpsubw         m6, m2, m6
    vbroadcasti128 m7, [r1 + r6]
    vpmaddubsw     m7, m7, m13
    vpsubw         m7, m3, m7

    lea            r1, [r1 + r5 * 4]
    vpaddw         m8, m4, m5
    vpsubw         m9, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m4
    vpsubw         m7, m8, m4
    vpaddw         m8, m9, m5
    vpsubw         m4, m9, m5
    vpabsw         m6, m6
    vpabsw         m7, m7
    vpabsw         m8, m8
    vpabsw         m4, m4
    vpblendw       m9, m6, m7, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m7, m7, 16
    vpor           m6, m6, m7
    vpmaxsw        m6, m6, m9
    vpblendw       m5, m8, m4, 0AAh
    vpsrld         m8, m8, 16
    vpslld         m4, m4, 16
    vpor           m8, m8, m4
    vpmaxsw        m8, m8, m5
    vpaddw         m6, m6, m8
    vpaddw         m10, m6, m10

    vbroadcasti128 m4, [r2]
    vpmaddubsw     m4, m4, m13
    vpsubw         m4, m0, m4
    vbroadcasti128 m5, [r2 + r5]
    vpmaddubsw     m5, m5, m13
    vpsubw         m5, m1, m5
    vbroadcasti128 m6, [r2 + r5 * 2]
    vpmaddubsw     m6, m6, m13
    vpsubw         m6, m2, m6
    vbroadcasti128 m7, [r2 + r6]
    vpmaddubsw     m7, m7, m13
    vpsubw         m7, m3, m7

    lea            r2, [r2 + r5 * 4]
    vpaddw         m8, m4, m5
    vpsubw         m9, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m4
    vpsubw         m7, m8, m4
    vpaddw         m8, m9, m5
    vpsubw         m4, m9, m5
    vpabsw         m6, m6
    vpabsw         m7, m7
    vpabsw         m8, m8
    vpabsw         m4, m4
    vpblendw       m9, m6, m7, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m7, m7, 16
    vpor           m6, m6, m7
    vpmaxsw        m6, m6, m9
    vpblendw       m5, m8, m4, 0AAh
    vpsrld         m8, m8, 16
    vpslld         m4, m4, 16
    vpor           m8, m8, m4
    vpmaxsw        m8, m8, m5
    vpaddw         m6, m6, m8
    vpaddw         m11, m6, m11

    vbroadcasti128 m4, [r3]
    vpmaddubsw     m4, m4, m13
    vpsubw         m4, m0, m4
    vbroadcasti128 m5, [r3 + r5]
    vpmaddubsw     m5, m5, m13
    vpsubw         m5, m1, m5
    vbroadcasti128 m6, [r3 + r5 * 2]
    vpmaddubsw     m6, m6, m13
    vpsubw         m6, m2, m6
    vbroadcasti128 m7, [r3 + r6]
    vpmaddubsw     m7, m7, m13
    vpsubw         m7, m3, m7

    lea            r3, [r3 + r5 * 4]
    vpaddw         m8, m4, m5
    vpsubw         m9, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m4
    vpsubw         m7, m8, m4
    vpaddw         m8, m9, m5
    vpsubw         m4, m9, m5
    vpabsw         m6, m6
    vpabsw         m7, m7
    vpabsw         m8, m8
    vpabsw         m4, m4
    vpblendw       m9, m6, m7, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m7, m7, 16
    vpor           m6, m6, m7
    vpmaxsw        m6, m6, m9
    vpblendw       m5, m8, m4, 0AAh
    vpsrld         m8, m8, 16
    vpslld         m4, m4, 16
    vpor           m8, m8, m4
    vpmaxsw        m8, m8, m5
    vpaddw         m6, m6, m8
    vpaddw         m12, m6, m12

    vbroadcasti128 m4, [r4]
    vpmaddubsw     m4, m4, m13
    vpsubw         m4, m0, m4
    vbroadcasti128 m5, [r4 + r5]
    vpmaddubsw     m5, m5, m13
    vpsubw         m5, m1, m5
    vbroadcasti128 m6, [r4 + r5 * 2]
    vpmaddubsw     m6, m6, m13
    vpsubw         m6, m2, m6
    vbroadcasti128 m7, [r4 + r6]
    vpmaddubsw     m7, m7, m13
    vpsubw         m7, m3, m7

    lea            r4, [r4 + r5 * 4]
    vpaddw         m8, m4, m5
    vpsubw         m9, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m4
    vpsubw         m7, m8, m4
    vpaddw         m8, m9, m5
    vpsubw         m4, m9, m5
    vpabsw         m6, m6
    vpabsw         m7, m7
    vpabsw         m8, m8
    vpabsw         m4, m4
    vpblendw       m9, m6, m7, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m7, m7, 16
    vpor           m6, m6, m7
    vpmaxsw        m6, m6, m9
    vpblendw       m5, m8, m4, 0AAh
    vpsrld         m8, m8, 16
    vpslld         m4, m4, 16
    vpor           m8, m8, m4
    vpmaxsw        m8, m8, m5
    vpaddw         m6, m6, m8
    vpaddw         m14, m6, m14
    ret

INIT_YMM avx2
cglobal pixel_satd_x4_16x8, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 120
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
    vmovdqu        [rsp + 80], xm13
    vmovdqu        [rsp + 96], xm14
%endif
    vmovdqu        m13, [hmul_16p]
    lea            r6d, [r5 + r5 * 2]
    vpxor          m10, m10, m10
    vpxor          m11, m11, m11
    vpxor          m12, m12, m12
    vpxor          m14, m14, m14
    call           pixel_satd_x4_16xN_internal
    call           pixel_satd_x4_16xN_internal
    vpbroadcastd   m4, [pw_1]
    vpmaddwd       m0, m10, m4
    vpmaddwd       m1, m11, m4
    vpmaddwd       m2, m12, m4
    vpmaddwd       m3, m14, m4

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    vmovdqu        xm13, [rsp + 80]
    vmovdqu        xm14, [rsp + 96]
    add            rsp, 120
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m2, m2, m3
    vphaddd        m0, m0, m2
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovdqu        [r6], xm0
    RET

INIT_YMM avx2
cglobal pixel_satd_x4_16x16, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 120
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
    vmovdqu        [rsp + 80], xm13
    vmovdqu        [rsp + 96], xm14
%endif
    vmovdqu        m13, [hmul_16p]
    lea            r6d, [r5 + r5 * 2]
    vpxor          m10, m10, m10
    vpxor          m11, m11, m11
    vpxor          m12, m12, m12
    vpxor          m14, m14, m14
    call           pixel_satd_x4_16xN_internal
    call           pixel_satd_x4_16xN_internal
    call           pixel_satd_x4_16xN_internal
    call           pixel_satd_x4_16xN_internal
    vpbroadcastd   m4, [pw_1]
    vpmaddwd       m0, m10, m4
    vpmaddwd       m1, m11, m4
    vpmaddwd       m2, m12, m4
    vpmaddwd       m3, m14, m4

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    vmovdqu        xm13, [rsp + 80]
    vmovdqu        xm14, [rsp + 96]
    add            rsp, 120
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
    mov            r6, [rsp + 56]
%else
    mov            r6, [rsp + 8]
%endif
    vphaddd        m0, m0, m1
    vphaddd        m2, m2, m3
    vphaddd        m0, m0, m2
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovdqu        [r6], xm0
    RET


;=============================================================================
; HADAMARD_AC
;=============================================================================
INIT_YMM avx2
cglobal pixel_hadamard_ac_8x8, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 24
    vmovdqu        [rsp], xm8
%endif
    vbroadcasti128 m6, [hmul_8p]
    lea            r6d, [r1 + r1 * 2]
    lea            r2, [r0 + r1 * 4]
    
    vmovddup       xm0, [r0]
    vmovddup       xm1, [r2]
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m6
    vmovddup       xm1, [r0 + r1]
    vmovddup       xm2, [r2 + r1]
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m6
    vmovddup       xm2, [r0 + r1 * 2]
    vmovddup       xm3, [r2 + r1 * 2]
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m6
    vmovddup       xm3, [r0 + r6]
    vmovddup       xm4, [r2 + r6]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m6

; dc
    vpaddw         m7, m0, m1
    vpaddw         m4, m2, m3
    vpaddw         m7, m7, m4

; sum4 part
    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m5, m2, 16
    vpslld         m6, m3, 16
    vpor           m5, m5, m6
    vpaddw         m6, m1, m5
    vpabsw         m8, m6
    vpsubw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6
    vpblendw       m1, m0, m4, 0AAh
    vpsrld         m5, m0, 16
    vpslld         m6, m4, 16
    vpor           m5, m5, m6
    vpaddw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6
    vpsubw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6

; sum8 part
    vperm2i128     m1, m2, m0, 31h
    vinserti128    m2, m2, xm0, 1
    vpaddw         m0, m1, m2
    vpsubw         m1, m1, m2
    vperm2i128     m2, m3, m4, 31h
    vinserti128    m3, m3, xm4, 1
    vpaddw         m4, m2, m3
    vpsubw         m5, m2, m3
    vshufps        m2, m0, m1, 0DDh
    vshufps        m3, m0, m1, 88h
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vshufps        m2, m4, m5, 0DDh
    vshufps        m3, m4, m5, 88h
    vpaddw         m4, m2, m3
    vpsubw         m5, m2, m3

    vpblendw       m2, m0, m1, 0AAh
    vpsrld         m3, m0, 16
    vpslld         m6, m1, 16
    vpor           m3, m3, m6
    vpaddw         m6, m2, m3
    vpabsw         m6, m6
    vpsubw         m2, m2, m3
    vpabsw         m2, m2
    vpaddw         m6, m6, m2
    vpbroadcastd   m0, [pw_1]
    vpblendw       m2, m4, m5, 0AAh
    vpsrld         m3, m4, 16
    vpslld         m1, m5, 16
    vpor           m3, m3, m1
    vpaddw         m4, m2, m3
    vpabsw         m4, m4
    vpaddw         m6, m6, m4
    vpsubw         m4, m2, m3
    vpabsw         m4, m4
    vpaddw         m6, m6, m4

    vpmaddwd       m1, m7, m0      ; dc
    vpmaddwd       m2, m8, m0      ; sum4
    vpmaddwd       m3, m6, m0      ; sum8

%if WIN64
    vmovdqu        xm8, [rsp]
    add            rsp, 24
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vmovddup       m1, m1
    vphaddd        m2, m2, m3
    vpsubd         m2, m2, m1
    vphaddd        m2, m2, m2
    vextracti128   xm3, m2, 1
    vpaddd         xm2, xm2, xm3
    vpsrld         xm3, xm2, 1
    vpsrld         xm4, xm2, 2
    vpblendd       xm2, xm3, xm4, 00000010b
    vmovq          rax, xm2
    RET

INIT_YMM avx2
cglobal pixel_hadamard_ac_8x16, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 40
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
%endif
    vbroadcasti128 m6, [hmul_8p]
    lea            r6d, [r1 + r1 * 2]
    lea            r2, [r0 + r1 * 4]

    vmovddup       xm0, [r0]
    vmovddup       xm1, [r2]
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m6
    vmovddup       xm1, [r0 + r1]
    vmovddup       xm2, [r2 + r1]
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m6
    vmovddup       xm2, [r0 + r1 * 2]
    vmovddup       xm3, [r2 + r1 * 2]
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m6
    vmovddup       xm3, [r0 + r6]
    vmovddup       xm4, [r2 + r6]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m6
    lea            r0, [r0 + r1 * 8]
    lea            r2, [r2 + r1 * 8]

; dc
    vpaddw         m7, m0, m1
    vpaddw         m4, m2, m3
    vpaddw         m7, m7, m4

; sum4 part
    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m5, m2, 16
    vpslld         m6, m3, 16
    vpor           m5, m5, m6
    vpaddw         m6, m1, m5
    vpabsw         m8, m6
    vpsubw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6
    vpblendw       m1, m0, m4, 0AAh
    vpsrld         m5, m0, 16
    vpslld         m6, m4, 16
    vpor           m5, m5, m6
    vpaddw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6
    vpsubw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6

; sum8 part
    vperm2i128     m1, m2, m0, 31h
    vinserti128    m2, m2, xm0, 1
    vpaddw         m0, m1, m2
    vpsubw         m1, m1, m2
    vperm2i128     m2, m3, m4, 31h
    vinserti128    m3, m3, xm4, 1
    vpaddw         m4, m2, m3
    vpsubw         m5, m2, m3
    vshufps        m2, m0, m1, 0DDh
    vshufps        m3, m0, m1, 88h
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vshufps        m2, m4, m5, 0DDh
    vshufps        m3, m4, m5, 88h
    vpaddw         m4, m2, m3
    vpsubw         m5, m2, m3

    vpblendw       m2, m0, m1, 0AAh
    vpsrld         m3, m0, 16
    vpslld         m6, m1, 16
    vpor           m3, m3, m6
    vpaddw         m6, m2, m3
    vpabsw         m9, m6
    vpsubw         m2, m2, m3
    vpabsw         m2, m2
    vpaddw         m9, m9, m2
    vbroadcasti128 m6, [hmul_8p]
    vpblendw       m2, m4, m5, 0AAh
    vpsrld         m3, m4, 16
    vpslld         m1, m5, 16
    vpor           m3, m3, m1
    vpaddw         m4, m2, m3
    vpabsw         m4, m4
    vpaddw         m9, m9, m4
    vpsubw         m4, m2, m3
    vpabsw         m4, m4
    vpaddw         m9, m9, m4

    vmovddup       xm0, [r0]
    vmovddup       xm1, [r2]
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m6
    vmovddup       xm1, [r0 + r1]
    vmovddup       xm2, [r2 + r1]
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m6
    vmovddup       xm2, [r0 + r1 * 2]
    vmovddup       xm3, [r2 + r1 * 2]
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m6
    vmovddup       xm3, [r0 + r6]
    vmovddup       xm4, [r2 + r6]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m6

; dc
    vpaddw         m4, m0, m1
    vpaddw         m5, m2, m3
    vpaddw         m7, m7, m4
    vpaddw         m7, m7, m5

; sum4 part
    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m5, m2, 16
    vpslld         m6, m3, 16
    vpor           m5, m5, m6
    vpaddw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6
    vpsubw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6
    vpblendw       m1, m0, m4, 0AAh
    vpsrld         m5, m0, 16
    vpslld         m6, m4, 16
    vpor           m5, m5, m6
    vpaddw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6
    vpsubw         m6, m1, m5
    vpabsw         m6, m6
    vpaddw         m8, m8, m6

; sum8 part
    vperm2i128     m1, m2, m0, 31h
    vinserti128    m2, m2, xm0, 1
    vpaddw         m0, m1, m2
    vpsubw         m1, m1, m2
    vperm2i128     m2, m3, m4, 31h
    vinserti128    m3, m3, xm4, 1
    vpaddw         m4, m2, m3
    vpsubw         m5, m2, m3
    vshufps        m2, m0, m1, 0DDh
    vshufps        m3, m0, m1, 88h
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vshufps        m2, m4, m5, 0DDh
    vshufps        m3, m4, m5, 88h
    vpaddw         m4, m2, m3
    vpsubw         m5, m2, m3

    vpblendw       m2, m0, m1, 0AAh
    vpsrld         m3, m0, 16
    vpslld         m6, m1, 16
    vpor           m3, m3, m6
    vpaddw         m6, m2, m3
    vpabsw         m6, m6
    vpaddw         m9, m9, m6
    vpsubw         m2, m2, m3
    vpabsw         m2, m2
    vpaddw         m9, m9, m2
    vpbroadcastd   m0, [pw_1]
    vpblendw       m2, m4, m5, 0AAh
    vpsrld         m3, m4, 16
    vpslld         m1, m5, 16
    vpor           m3, m3, m1
    vpaddw         m4, m2, m3
    vpabsw         m4, m4
    vpaddw         m9, m9, m4
    vpsubw         m4, m2, m3
    vpabsw         m4, m4
    vpaddw         m9, m9, m4

    vpmaddwd       m1, m7, m0      ; dc
    vpmaddwd       m2, m8, m0      ; sum4
    vpmaddwd       m3, m9, m0      ; sum8

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    add            rsp, 40
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vmovddup       m1, m1
    vphaddd        m2, m2, m3
    vpsubd         m2, m2, m1
    vphaddd        m2, m2, m2
    vextracti128   xm3, m2, 1
    vpaddd         xm2, xm2, xm3
    vpsrld         xm3, xm2, 1
    vpsrld         xm4, xm2, 2
    vpblendd       xm2, xm3, xm4, 00000010b
    vmovq          rax, xm2
    RET

INIT_YMM avx2
cglobal pixel_hadamard_ac_16x8, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 72
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
%endif
    vmovdqu        m8, [hmul_16p]
    lea            r6d, [r1 + r1 * 2]

    vbroadcasti128 m0, [r0]
    vpmaddubsw     m0, m0, m8
    vbroadcasti128 m1, [r0 + r1]
    vpmaddubsw     m1, m1, m8
    vbroadcasti128 m2, [r0 + r1 * 2]
    vpmaddubsw     m2, m2, m8
    vbroadcasti128 m3, [r0 + r6]
    vpmaddubsw     m3, m3, m8
    lea            r0, [r0 + r1 * 4]
    vbroadcasti128 m4, [r0]
    vpmaddubsw     m4, m4, m8
    vbroadcasti128 m5, [r0 + r1]
    vpmaddubsw     m5, m5, m8
    vbroadcasti128 m6, [r0 + r1 * 2]
    vpmaddubsw     m6, m6, m8
    vbroadcasti128 m7, [r0 + r6]
    vpmaddubsw     m7, m7, m8

; dc
    vpaddw         xm8, xm0, xm1
    vpaddw         xm9, xm2, xm3
    vpaddw         xm10, xm4, xm5
    vpaddw         xm11, xm6, xm7
    vpaddw         xm8, xm8, xm9
    vpaddw         xm10, xm10, xm11
    vpaddw         xm10, xm8, xm10

; sum4 part
    vpaddw         m8, m0, m1
    vpsubw         m9, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m0
    vpsubw         m7, m8, m0
    vpaddw         m0, m9, m1
    vpsubw         m8, m9, m1
    vpaddw         m1, m2, m4
    vpsubw         m9, m2, m4
    vpaddw         m2, m3, m5
    vpsubw         m4, m3, m5

    vpblendw       m3, m6, m0, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m0, m0, 16
    vpor           m5, m6, m0
    vpaddw         m6, m3, m5
    vpsubw         m0, m3, m5
    vpabsw         m11, m6
    vpabsw         m3, m0
    vpaddw         m11, m11, m3
    vpblendw       m3, m7, m8, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m8, m8, 16
    vpor           m5, m7, m8
    vpaddw         m7, m3, m5
    vpsubw         m8, m3, m5
    vpabsw         m3, m7
    vpabsw         m5, m8
    vpaddw         m3, m3, m5
    vpaddw         m11, m11, m3
    vpblendw       m3, m1, m2, 0AAh
    vpsrld         m1, m1, 16
    vpslld         m2, m2, 16
    vpor           m5, m1, m2
    vpaddw         m1, m3, m5
    vpsubw         m2, m3, m5
    vpabsw         m3, m1
    vpabsw         m5, m2
    vpaddw         m3, m3, m5
    vpaddw         m11, m11, m3
    vpblendw       m3, m9, m4, 0AAh
    vpsrld         m9, m9, 16
    vpslld         m4, m4, 16
    vpor           m5, m9, m4
    vpaddw         m9, m3, m5
    vpsubw         m4, m3, m5
    vpabsw         m3, m9
    vpabsw         m5, m4
    vpaddw         m3, m3, m5
    vpaddw         m11, m11, m3

; sum8 part
    vpaddw         m3, m6, m1
    vpsubw         m5, m6, m1
    vpaddw         m1, m0, m2
    vpsubw         m6, m0, m2
    vpaddw         m0, m7, m9
    vpsubw         m2, m7, m9
    vpaddw         m7, m8, m4
    vpsubw         m9, m8, m4

    vpblendd       m4, m3, m1, 10101010b
    vpsrlq         m3, m3, 32
    vpsllq         m1, m1, 32
    vpor           m3, m3, m1
    vpaddw         m8, m4, m3
    vpabsw         m8, m8
    vpsubw         m3, m4, m3
    vpabsw         m3, m3
    vpaddw         m8, m8, m3
    vpblendd       m4, m0, m7, 10101010b
    vpsrlq         m0, m0, 32
    vpsllq         m7, m7, 32
    vpor           m0, m0, m7
    vpaddw         m7, m4, m0
    vpabsw         m7, m7
    vpaddw         m8, m8, m7
    vpsubw         m7, m4, m0
    vpabsw         m7, m7
    vpaddw         m8, m8, m7
    vpblendd       m4, m5, m6, 10101010b
    vpsrlq         m5, m5, 32
    vpsllq         m6, m6, 32
    vpor           m5, m5, m6
    vpaddw         m7, m4, m5
    vpabsw         m7, m7
    vpaddw         m8, m8, m7
    vpsubw         m7, m4, m5
    vpabsw         m7, m7
    vpaddw         m8, m8, m7
    vpbroadcastd   m5, [pw_1]
    vpblendd       m4, m2, m9, 10101010b
    vpsrlq         m2, m2, 32
    vpsllq         m9, m9, 32
    vpor           m2, m2, m9
    vpaddw         m7, m4, m2
    vpabsw         m7, m7
    vpaddw         m8, m8, m7
    vpsubw         m7, m4, m2
    vpabsw         m7, m7
    vpaddw         m8, m8, m7

    vpmaddwd       xm1, xm10, xm5     ; dc
    vpmaddwd       m2, m11, m5        ; sum4
    vpmaddwd       m3, m8, m5         ; sum8

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    add            rsp, 72
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vextracti128   xm4, m2, 1
    vextracti128   xm5, m3, 1
    vpaddd         xm2, xm2, xm4
    vpaddd         xm3, xm3, xm5
    vpsubd         xm2, xm2, xm1
    vpsubd         xm3, xm3, xm1
    vphaddd        xm2, xm2, xm3
    vphaddd        xm2, xm2, xm2
    vpsrld         xm3, xm2, 1
    vpsrld         xm4, xm2, 2
    vpblendd       xm2, xm3, xm4, 00000010b
    vmovq          rax, xm2
    RET

INIT_YMM avx2
cglobal pixel_hadamard_ac_16x16, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 120
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
    vmovdqu        [rsp + 80], xm13
    vmovdqu        [rsp + 96], xm14
%endif
    vmovdqu        m8, [hmul_16p]
    vpbroadcastd   m13, [pw_1]
    lea            r6d, [r1 + r1 * 2]

    vbroadcasti128 m0, [r0]
    vpmaddubsw     m0, m0, m8
    vbroadcasti128 m1, [r0 + r1]
    vpmaddubsw     m1, m1, m8
    vbroadcasti128 m2, [r0 + r1 * 2]
    vpmaddubsw     m2, m2, m8
    vbroadcasti128 m3, [r0 + r6]
    vpmaddubsw     m3, m3, m8
    lea            r0, [r0 + r1 * 4]
    vbroadcasti128 m4, [r0]
    vpmaddubsw     m4, m4, m8
    vbroadcasti128 m5, [r0 + r1]
    vpmaddubsw     m5, m5, m8
    vbroadcasti128 m6, [r0 + r1 * 2]
    vpmaddubsw     m6, m6, m8
    vbroadcasti128 m7, [r0 + r6]
    vpmaddubsw     m7, m7, m8
    lea            r0, [r0 + r1 * 4]

; dc
    vpaddw         xm8, xm0, xm1
    vpaddw         xm9, xm2, xm3
    vpaddw         xm10, xm4, xm5
    vpaddw         xm11, xm6, xm7
    vpaddw         xm8, xm8, xm9
    vpaddw         xm10, xm10, xm11
    vpaddw         xm10, xm8, xm10

; sum4 part
    vpaddw         m8, m0, m1
    vpsubw         m9, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m0
    vpsubw         m7, m8, m0
    vpaddw         m0, m9, m1
    vpsubw         m8, m9, m1
    vpaddw         m1, m2, m4
    vpsubw         m9, m2, m4
    vpaddw         m2, m3, m5
    vpsubw         m4, m3, m5

    vpblendw       m3, m6, m0, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m0, m0, 16
    vpor           m5, m6, m0
    vpaddw         m6, m3, m5
    vpsubw         m0, m3, m5
    vpabsw         m11, m6
    vpabsw         m3, m0
    vpaddw         m11, m11, m3
    vpblendw       m3, m7, m8, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m8, m8, 16
    vpor           m5, m7, m8
    vpaddw         m7, m3, m5
    vpsubw         m8, m3, m5
    vpabsw         m3, m7
    vpabsw         m5, m8
    vpaddw         m3, m3, m5
    vpaddw         m11, m11, m3
    vpblendw       m3, m1, m2, 0AAh
    vpsrld         m1, m1, 16
    vpslld         m2, m2, 16
    vpor           m5, m1, m2
    vpaddw         m1, m3, m5
    vpsubw         m2, m3, m5
    vpabsw         m3, m1
    vpabsw         m5, m2
    vpaddw         m3, m3, m5
    vpaddw         m11, m11, m3
    vpblendw       m3, m9, m4, 0AAh
    vpsrld         m9, m9, 16
    vpslld         m4, m4, 16
    vpor           m5, m9, m4
    vpaddw         m9, m3, m5
    vpsubw         m4, m3, m5
    vpabsw         m3, m9
    vpabsw         m5, m4
    vpaddw         m3, m3, m5
    vpaddw         m11, m11, m3

; sum8 part
    vpaddw         m3, m6, m1
    vpsubw         m5, m6, m1
    vpaddw         m1, m0, m2
    vpsubw         m6, m0, m2
    vpaddw         m0, m7, m9
    vpsubw         m2, m7, m9
    vpaddw         m7, m8, m4
    vpsubw         m9, m8, m4

    vpblendd       m4, m3, m1, 10101010b
    vpsrlq         m3, m3, 32
    vpsllq         m1, m1, 32
    vpor           m3, m3, m1
    vpaddw         m12, m4, m3
    vpabsw         m12, m12
    vpsubw         m3, m4, m3
    vpabsw         m3, m3
    vpaddw         m12, m12, m3
    vpblendd       m4, m0, m7, 10101010b
    vpsrlq         m0, m0, 32
    vpsllq         m7, m7, 32
    vpor           m0, m0, m7
    vpaddw         m7, m4, m0
    vpabsw         m7, m7
    vpaddw         m12, m12, m7
    vpsubw         m7, m4, m0
    vpabsw         m7, m7
    vpaddw         m12, m12, m7
    vpblendd       m4, m5, m6, 10101010b
    vpsrlq         m5, m5, 32
    vpsllq         m6, m6, 32
    vpor           m5, m5, m6
    vpaddw         m7, m4, m5
    vpabsw         m7, m7
    vpaddw         m12, m12, m7
    vpsubw         m7, m4, m5
    vpabsw         m7, m7
    vpaddw         m12, m12, m7
    vmovdqu        m8, [hmul_16p]
    vpblendd       m4, m2, m9, 10101010b
    vpsrlq         m2, m2, 32
    vpsllq         m9, m9, 32
    vpor           m2, m2, m9
    vpaddw         m7, m4, m2
    vpabsw         m7, m7
    vpaddw         m12, m12, m7
    vpsubw         m7, m4, m2
    vpabsw         m7, m7
    vpaddw         m12, m12, m7

    vpmaddwd       xm10, xm10, xm13     ; dc
    vpmaddwd       m11, m11, m13        ; sum4
    vpmaddwd       m12, m12, m13        ; sum8

    vbroadcasti128 m0, [r0]
    vpmaddubsw     m0, m0, m8
    vbroadcasti128 m1, [r0 + r1]
    vpmaddubsw     m1, m1, m8
    vbroadcasti128 m2, [r0 + r1 * 2]
    vpmaddubsw     m2, m2, m8
    vbroadcasti128 m3, [r0 + r6]
    vpmaddubsw     m3, m3, m8
    lea            r0, [r0 + r1 * 4]
    vbroadcasti128 m4, [r0]
    vpmaddubsw     m4, m4, m8
    vbroadcasti128 m5, [r0 + r1]
    vpmaddubsw     m5, m5, m8
    vbroadcasti128 m6, [r0 + r1 * 2]
    vpmaddubsw     m6, m6, m8
    vbroadcasti128 m7, [r0 + r6]
    vpmaddubsw     m7, m7, m8

; dc
    vpaddw         xm8, xm0, xm1
    vpaddw         xm9, xm2, xm3
    vpaddw         xm8, xm8, xm4
    vpaddw         xm9, xm9, xm5
    vpaddw         xm8, xm8, xm6
    vpaddw         xm9, xm9, xm7
    vpaddw         xm8, xm8, xm9
    vpmaddwd       xm8, xm8, xm13
    vpaddd         xm10, xm8, xm10

; sum4 part
    vpaddw         m8, m0, m1
    vpsubw         m9, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m0
    vpsubw         m7, m8, m0
    vpaddw         m0, m9, m1
    vpsubw         m8, m9, m1
    vpaddw         m1, m2, m4
    vpsubw         m9, m2, m4
    vpaddw         m2, m3, m5
    vpsubw         m4, m3, m5

    vpblendw       m3, m6, m0, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m0, m0, 16
    vpor           m5, m6, m0
    vpaddw         m6, m3, m5
    vpsubw         m0, m3, m5
    vpabsw         m3, m6
    vpabsw         m5, m0
    vpaddw         m14, m3, m5
    vpblendw       m3, m7, m8, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m8, m8, 16
    vpor           m5, m7, m8
    vpaddw         m7, m3, m5
    vpsubw         m8, m3, m5
    vpabsw         m3, m7
    vpabsw         m5, m8
    vpaddw         m3, m3, m5
    vpaddw         m14, m14, m3
    vpblendw       m3, m1, m2, 0AAh
    vpsrld         m1, m1, 16
    vpslld         m2, m2, 16
    vpor           m5, m1, m2
    vpaddw         m1, m3, m5
    vpsubw         m2, m3, m5
    vpabsw         m3, m1
    vpabsw         m5, m2
    vpaddw         m3, m3, m5
    vpaddw         m14, m14, m3
    vpblendw       m3, m9, m4, 0AAh
    vpsrld         m9, m9, 16
    vpslld         m4, m4, 16
    vpor           m5, m9, m4
    vpaddw         m9, m3, m5
    vpsubw         m4, m3, m5
    vpabsw         m3, m9
    vpabsw         m5, m4
    vpaddw         m3, m3, m5
    vpaddw         m14, m14, m3 
    vpmaddwd       m14, m14, m13
    vpaddd         m11, m11, m14

; sum8 part
    vpaddw         m3, m6, m1
    vpsubw         m5, m6, m1
    vpaddw         m1, m0, m2
    vpsubw         m6, m0, m2
    vpaddw         m0, m7, m9
    vpsubw         m2, m7, m9
    vpaddw         m7, m8, m4
    vpsubw         m9, m8, m4

    vpblendd       m4, m3, m1, 10101010b
    vpsrlq         m3, m3, 32
    vpsllq         m1, m1, 32
    vpor           m3, m3, m1
    vpaddw         m8, m4, m3
    vpabsw         m14, m8
    vpsubw         m3, m4, m3
    vpabsw         m3, m3
    vpaddw         m14, m14, m3
    vpblendd       m4, m0, m7, 10101010b
    vpsrlq         m0, m0, 32
    vpsllq         m7, m7, 32
    vpor           m0, m0, m7
    vpaddw         m7, m4, m0
    vpabsw         m7, m7
    vpaddw         m14, m14, m7
    vpsubw         m7, m4, m0
    vpabsw         m7, m7
    vpaddw         m14, m14, m7
    vpblendd       m4, m5, m6, 10101010b
    vpsrlq         m5, m5, 32
    vpsllq         m6, m6, 32
    vpor           m5, m5, m6
    vpaddw         m7, m4, m5
    vpabsw         m7, m7
    vpaddw         m14, m14, m7
    vpsubw         m7, m4, m5
    vpabsw         m7, m7
    vpaddw         m14, m14, m7
    vpblendd       m4, m2, m9, 10101010b
    vpsrlq         m2, m2, 32
    vpsllq         m9, m9, 32
    vpor           m2, m2, m9
    vpaddw         m7, m4, m2
    vpabsw         m7, m7
    vpaddw         m14, m14, m7
    vpsubw         m7, m4, m2
    vpabsw         m7, m7
    vpaddw         m14, m14, m7
    vpmaddwd       m14, m14, m13
    vpaddd         m12, m12, m14

    vextracti128   xm4, m11, 1
    vextracti128   xm5, m12, 1
    vpaddd         xm2, xm11, xm4
    vpaddd         xm3, xm12, xm5
    vpsubd         xm2, xm2, xm10
    vpsubd         xm3, xm3, xm10
    vphaddd        xm2, xm2, xm3
    vphaddd        xm2, xm2, xm2
    vpsrld         xm3, xm2, 1
    vpsrld         xm4, xm2, 2
    vpblendd       xm2, xm3, xm4, 00000010b
    vmovq          rax, xm2
%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    vmovdqu        xm13, [rsp + 80]
    vmovdqu        xm14, [rsp + 96]
    add            rsp, 120
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    RET


;=============================================================================
; SA8D
;=============================================================================
INIT_YMM avx2
cglobal pixel_sa8d_8x8, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
%endif
    vbroadcasti128 m6, [hmul_8p]
    lea            r5, [r0 + r1 * 4]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vmovddup       xm0, [r0]
    vmovddup       xm1, [r5]
    vinserti128    m0, m0, xm1, 1
    vpmaddubsw     m0, m0, m6
    vmovddup       xm1, [r0 + r1]
    vmovddup       xm2, [r5 + r1]
    vinserti128    m1, m1, xm2, 1
    vpmaddubsw     m1, m1, m6
    vmovddup       xm2, [r0 + r1 * 2]
    vmovddup       xm3, [r5 + r1 * 2]
    vinserti128    m2, m2, xm3, 1
    vpmaddubsw     m2, m2, m6
    vmovddup       xm3, [r0 + r6]
    vmovddup       xm4, [r5 + r6]
    lea            r5, [r2 + r3 * 4]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m6
    vmovddup       xm4, [r2]
    vmovddup       xm5, [r5]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m0, m0, m4
    vmovddup       xm4, [r2 + r3]
    vmovddup       xm5, [r5 + r3]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m1, m1, m4
    vmovddup       xm4, [r2 + r3 * 2]
    vmovddup       xm5, [r5 + r3 * 2]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m2, m2, m4
    vmovddup       xm4, [r2 + r4]
    vmovddup       xm5, [r5 + r4]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m6
    vpsubw         m3, m3, m4

    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vperm2i128     m1, m2, m0, 31h
    vinserti128    m2, m2, xm0, 1
    vpaddw         m0, m1, m2
    vpsubw         m1, m1, m2
    vperm2i128     m2, m3, m4, 31h
    vinserti128    m3, m3, xm4, 1
    vpaddw         m4, m2, m3
    vpsubw         m5, m2, m3
    vshufps        m2, m0, m1, 0DDh
    vshufps        m3, m0, m1, 88h
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vshufps        m2, m4, m5, 0DDh
    vshufps        m3, m4, m5, 88h
    vpaddw         m4, m2, m3
    vpsubw         m5, m2, m3

    vpbroadcastd   m6, [pw_1]
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpabsw         m4, m4
    vpabsw         m5, m5
    vpblendw       m2, m0, m1, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m1, m1, 16
    vpor           m0, m0, m1
    vpmaxsw        m2, m2, m0
    vpblendw       m3, m4, m5, 0AAh
    vpsrld         m4, m4, 16
    vpslld         m5, m5, 16
    vpor           m4, m4, m5
    vpmaxsw        m3, m3, m4
    vpaddw         m2, m2, m3
    vpmaddwd       m2, m2, m6

%if WIN64
    vmovdqu        xm6, [rsp + 8]
%endif
    vextracti128   xm1, m2, 1
    vpaddd         xm2, xm2, xm1
    vpunpckhqdq    xm5, xm2, xm2
    vpaddd         xm2, xm2, xm5
    vpshufd        xm5, xm2, 1
    vpaddd         xm2, xm2, xm5
    vpxor          xm0, xm0, xm0
    vpavgw         xm2, xm2, xm0
    vmovd          eax, xm2
    RET

INIT_YMM avx2
cglobal pixel_sa8d_16x16, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 56
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
%endif
    vmovdqu        m9, [hmul_16p]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m9
    vpmaddubsw     m1, m1, m9
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m9
    vpmaddubsw     m2, m2, m9
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m9
    vpmaddubsw     m3, m3, m9
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpmaddubsw     m3, m3, m9
    vpmaddubsw     m4, m4, m9
    vpsubw         m3, m3, m4
    vbroadcasti128 m4, [r0]
    vbroadcasti128 m5, [r2]
    vpmaddubsw     m4, m4, m9
    vpmaddubsw     m5, m5, m9
    vpsubw         m4, m4, m5
    vbroadcasti128 m5, [r0 + r1]
    vbroadcasti128 m6, [r2 + r3]
    vpmaddubsw     m5, m5, m9
    vpmaddubsw     m6, m6, m9
    vpsubw         m5, m5, m6
    vbroadcasti128 m6, [r0 + r1 * 2]
    vbroadcasti128 m7, [r2 + r3 * 2]
    vpmaddubsw     m6, m6, m9
    vpmaddubsw     m7, m7, m9
    vpsubw         m6, m6, m7
    vbroadcasti128 m7, [r0 + r6]
    vbroadcasti128 m8, [r2 + r4]
    vpmaddubsw     m7, m7, m9
    vpmaddubsw     m8, m8, m9
    vpsubw         m7, m7, m8

    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpaddw         m8, m0, m1
    vpsubw         m9, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m0
    vpsubw         m7, m8, m0
    vpaddw         m0, m9, m1
    vpsubw         m8, m9, m1
    vpaddw         m1, m2, m4
    vpsubw         m9, m2, m4
    vpaddw         m2, m3, m5
    vpsubw         m4, m3, m5
    vpaddw         m3, m6, m1
    vpsubw         m5, m6, m1
    vpaddw         m1, m0, m2
    vpsubw         m6, m0, m2
    vpaddw         m0, m7, m9
    vpsubw         m2, m7, m9
    vpaddw         m7, m8, m4
    vpsubw         m9, m8, m4

    vshufps        m4, m3, m5, 0DDh
    vshufps        m8, m3, m5, 88h
    vpaddw         m3, m4, m8
    vpsubw         m5, m4, m8
    vshufps        m4, m1, m6, 0DDh
    vshufps        m8, m1, m6, 88h
    vpaddw         m1, m4, m8
    vpsubw         m6, m4, m8
    vshufps        m4, m0, m2, 0DDh
    vshufps        m8, m0, m2, 88h
    vpaddw         m0, m4, m8
    vpsubw         m2, m4, m8
    vshufps        m4, m7, m9, 0DDh
    vshufps        m8, m7, m9, 88h
    vpaddw         m7, m4, m8
    vpsubw         m9, m4, m8

    vpabsw         m3, m3
    vpabsw         m5, m5
    vpabsw         m1, m1
    vpabsw         m6, m6
    vpabsw         m0, m0
    vpabsw         m2, m2
    vpabsw         m7, m7
    vpabsw         m9, m9
    vpblendw       m4, m3, m5, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m5, m5, 16
    vpor           m3, m3, m5
    vpmaxsw        m4, m4, m3
    vpblendw       m8, m1, m6, 0AAh
    vpsrld         m1, m1, 16
    vpslld         m6, m6, 16
    vpor           m1, m1, m6
    vpmaxsw        m8, m8, m1
    vpaddw         m10, m4, m8
    vpblendw       m4, m0, m2, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m2, m2, 16
    vpor           m0, m0, m2
    vpmaxsw        m4, m4, m0
    vpaddw         m10, m10, m4
    vpblendw       m8, m7, m9, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m9, m9, 16
    vpor           m7, m7, m9
    vpmaxsw        m8, m8, m7
    vpaddw         m10, m10, m8

    vmovdqu        m9, [hmul_16p]
    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m9
    vpmaddubsw     m1, m1, m9
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m9
    vpmaddubsw     m2, m2, m9
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m9
    vpmaddubsw     m3, m3, m9
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpmaddubsw     m3, m3, m9
    vpmaddubsw     m4, m4, m9
    vpsubw         m3, m3, m4
    vbroadcasti128 m4, [r0]
    vbroadcasti128 m5, [r2]
    vpmaddubsw     m4, m4, m9
    vpmaddubsw     m5, m5, m9
    vpsubw         m4, m4, m5
    vbroadcasti128 m5, [r0 + r1]
    vbroadcasti128 m6, [r2 + r3]
    vpmaddubsw     m5, m5, m9
    vpmaddubsw     m6, m6, m9
    vpsubw         m5, m5, m6
    vbroadcasti128 m6, [r0 + r1 * 2]
    vbroadcasti128 m7, [r2 + r3 * 2]
    vpmaddubsw     m6, m6, m9
    vpmaddubsw     m7, m7, m9
    vpsubw         m6, m6, m7
    vbroadcasti128 m7, [r0 + r6]
    vbroadcasti128 m8, [r2 + r4]
    vpmaddubsw     m7, m7, m9
    vpmaddubsw     m8, m8, m9
    vpsubw         m7, m7, m8

    vpaddw         m8, m0, m1
    vpsubw         m9, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m0
    vpsubw         m7, m8, m0
    vpaddw         m0, m9, m1
    vpsubw         m8, m9, m1
    vpaddw         m1, m2, m4
    vpsubw         m9, m2, m4
    vpaddw         m2, m3, m5
    vpsubw         m4, m3, m5
    vpaddw         m3, m6, m1
    vpsubw         m5, m6, m1
    vpaddw         m1, m0, m2
    vpsubw         m6, m0, m2
    vpaddw         m0, m7, m9
    vpsubw         m2, m7, m9
    vpaddw         m7, m8, m4
    vpsubw         m9, m8, m4

    vshufps        m4, m3, m5, 0DDh
    vshufps        m8, m3, m5, 88h
    vpaddw         m3, m4, m8
    vpsubw         m5, m4, m8
    vshufps        m4, m1, m6, 0DDh
    vshufps        m8, m1, m6, 88h
    vpaddw         m1, m4, m8
    vpsubw         m6, m4, m8
    vshufps        m4, m0, m2, 0DDh
    vshufps        m8, m0, m2, 88h
    vpaddw         m0, m4, m8
    vpsubw         m2, m4, m8
    vshufps        m4, m7, m9, 0DDh
    vshufps        m8, m7, m9, 88h
    vpaddw         m7, m4, m8
    vpsubw         m9, m4, m8

    vpabsw         m3, m3
    vpabsw         m5, m5
    vpabsw         m1, m1
    vpabsw         m6, m6
    vpabsw         m0, m0
    vpabsw         m2, m2
    vpabsw         m7, m7
    vpabsw         m9, m9
    vpbroadcastd   m8, [pw_1]
    vpblendw       m4, m3, m5, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m5, m5, 16
    vpor           m3, m3, m5
    vpmaxsw        m4, m4, m3
    vpaddw         m10, m10, m4
    vpblendw       m4, m1, m6, 0AAh
    vpsrld         m1, m1, 16
    vpslld         m6, m6, 16
    vpor           m1, m1, m6
    vpmaxsw        m4, m4, m1
    vpaddw         m10, m10, m4
    vpblendw       m4, m0, m2, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m2, m2, 16
    vpor           m0, m0, m2
    vpmaxsw        m4, m4, m0
    vpaddw         m10, m10, m4
    vpblendw       m4, m7, m9, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m9, m9, 16
    vpor           m7, m7, m9
    vpmaxsw        m4, m4, m7
    vpaddw         m10, m10, m4
    vpmaddwd       m2, m10, m8

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    add            rsp, 56
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vextracti128   xm1, m2, 1
    vpaddd         xm2, xm2, xm1
    vpunpckhqdq    xm5, xm2, xm2
    vpaddd         xm2, xm2, xm5
    vpshufd        xm5, xm2, 1
    vpaddd         xm2, xm2, xm5
    vmovd          eax, xm2
    add            eax, 1
    shr            eax, 1
    RET

;=============================================================================
; SA8D_SATD
;=============================================================================
INIT_YMM avx2
cglobal pixel_sa8d_satd_16x16, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 104
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
    vmovdqu        [rsp + 80], xm13
%endif
    vmovdqu        m10, [hmul_16p]
    vpbroadcastd   m13, [pw_1]
    lea            r6d, [r1 + r1 * 2]
    lea            r4d, [r3 + r3 * 2]

    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m10
    vpmaddubsw     m1, m1, m10
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m10
    vpmaddubsw     m2, m2, m10
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m10
    vpmaddubsw     m3, m3, m10
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpmaddubsw     m3, m3, m10
    vpmaddubsw     m4, m4, m10
    vpsubw         m3, m3, m4
    vbroadcasti128 m4, [r0]
    vbroadcasti128 m5, [r2]
    vpmaddubsw     m4, m4, m10
    vpmaddubsw     m5, m5, m10
    vpsubw         m4, m4, m5
    vbroadcasti128 m5, [r0 + r1]
    vbroadcasti128 m6, [r2 + r3]
    vpmaddubsw     m5, m5, m10
    vpmaddubsw     m6, m6, m10
    vpsubw         m5, m5, m6
    vbroadcasti128 m6, [r0 + r1 * 2]
    vbroadcasti128 m7, [r2 + r3 * 2]
    vpmaddubsw     m6, m6, m10
    vpmaddubsw     m7, m7, m10
    vpsubw         m6, m6, m7
    vbroadcasti128 m7, [r0 + r6]
    vbroadcasti128 m8, [r2 + r4]
    vpmaddubsw     m7, m7, m10
    vpmaddubsw     m8, m8, m10
    vpsubw         m7, m7, m8
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]

; satd part
    vpaddw         m8, m0, m1
    vpsubw         m9, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m0
    vpsubw         m7, m8, m0
    vpaddw         m0, m9, m1
    vpsubw         m8, m9, m1
    vpaddw         m1, m2, m4
    vpsubw         m9, m2, m4
    vpaddw         m2, m3, m5
    vpsubw         m4, m3, m5

    vpblendw       m3, m6, m0, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m0, m0, 16
    vpor           m5, m6, m0
    vpaddw         m6, m3, m5
    vpsubw         m0, m3, m5
    vpabsw         m11, m6
    vpabsw         m3, m0
    vpaddw         m11, m11, m3
    vpblendw       m3, m7, m8, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m8, m8, 16
    vpor           m5, m7, m8
    vpaddw         m7, m3, m5
    vpsubw         m8, m3, m5
    vpabsw         m3, m7
    vpabsw         m5, m8
    vpaddw         m3, m3, m5
    vpaddw         m11, m11, m3
    vpblendw       m3, m1, m2, 0AAh
    vpsrld         m1, m1, 16
    vpslld         m2, m2, 16
    vpor           m5, m1, m2
    vpaddw         m1, m3, m5
    vpsubw         m2, m3, m5
    vpabsw         m3, m1
    vpabsw         m5, m2
    vpaddw         m3, m3, m5
    vpaddw         m11, m11, m3
    vpblendw       m3, m9, m4, 0AAh
    vpsrld         m9, m9, 16
    vpslld         m4, m4, 16
    vpor           m5, m9, m4
    vpaddw         m9, m3, m5
    vpsubw         m4, m3, m5
    vpabsw         m3, m9
    vpabsw         m5, m4
    vpaddw         m3, m3, m5
    vpaddw         m11, m11, m3

; sa8d part
    vpaddw         m3, m6, m1
    vpsubw         m5, m6, m1
    vpaddw         m1, m0, m2
    vpsubw         m6, m0, m2
    vpaddw         m0, m7, m9
    vpsubw         m2, m7, m9
    vpaddw         m7, m8, m4
    vpsubw         m9, m8, m4

    vpblendd       m4, m3, m1, 10101010b
    vpsrlq         m3, m3, 32
    vpsllq         m1, m1, 32
    vpor           m3, m3, m1
    vpaddw         m12, m4, m3
    vpabsw         m12, m12
    vpsubw         m3, m4, m3
    vpabsw         m3, m3
    vpaddw         m12, m12, m3
    vpblendd       m4, m0, m7, 10101010b
    vpsrlq         m0, m0, 32
    vpsllq         m7, m7, 32
    vpor           m0, m0, m7
    vpaddw         m7, m4, m0
    vpabsw         m7, m7
    vpaddw         m12, m12, m7
    vpsubw         m7, m4, m0
    vpabsw         m7, m7
    vpaddw         m12, m12, m7
    vpblendd       m4, m5, m6, 10101010b
    vpsrlq         m5, m5, 32
    vpsllq         m6, m6, 32
    vpor           m5, m5, m6
    vpaddw         m7, m4, m5
    vpabsw         m7, m7
    vpaddw         m12, m12, m7
    vpsubw         m7, m4, m5
    vpabsw         m7, m7
    vpaddw         m12, m12, m7
    vmovdqu        m10, [hmul_16p]
    vpblendd       m4, m2, m9, 10101010b
    vpsrlq         m2, m2, 32
    vpsllq         m9, m9, 32
    vpor           m2, m2, m9
    vpaddw         m7, m4, m2
    vpabsw         m7, m7
    vpaddw         m12, m12, m7
    vpsubw         m7, m4, m2
    vpabsw         m7, m7
    vpaddw         m12, m12, m7

; convert to dword before being unsigned
    vpmaddwd       m11, m11, m13 
    vpmaddwd       m12, m12, m13

    vbroadcasti128 m0, [r0]
    vbroadcasti128 m1, [r2]
    vpmaddubsw     m0, m0, m10
    vpmaddubsw     m1, m1, m10
    vpsubw         m0, m0, m1
    vbroadcasti128 m1, [r0 + r1]
    vbroadcasti128 m2, [r2 + r3]
    vpmaddubsw     m1, m1, m10
    vpmaddubsw     m2, m2, m10
    vpsubw         m1, m1, m2
    vbroadcasti128 m2, [r0 + r1 * 2]
    vbroadcasti128 m3, [r2 + r3 * 2]
    vpmaddubsw     m2, m2, m10
    vpmaddubsw     m3, m3, m10
    vpsubw         m2, m2, m3
    vbroadcasti128 m3, [r0 + r6]
    vbroadcasti128 m4, [r2 + r4]
    lea            r0, [r0 + r1 * 4]
    lea            r2, [r2 + r3 * 4]
    vpmaddubsw     m3, m3, m10
    vpmaddubsw     m4, m4, m10
    vpsubw         m3, m3, m4
    vbroadcasti128 m4, [r0]
    vbroadcasti128 m5, [r2]
    vpmaddubsw     m4, m4, m10
    vpmaddubsw     m5, m5, m10
    vpsubw         m4, m4, m5
    vbroadcasti128 m5, [r0 + r1]
    vbroadcasti128 m6, [r2 + r3]
    vpmaddubsw     m5, m5, m10
    vpmaddubsw     m6, m6, m10
    vpsubw         m5, m5, m6
    vbroadcasti128 m6, [r0 + r1 * 2]
    vbroadcasti128 m7, [r2 + r3 * 2]
    vpmaddubsw     m6, m6, m10
    vpmaddubsw     m7, m7, m10
    vpsubw         m6, m6, m7
    vbroadcasti128 m7, [r0 + r6]
    vbroadcasti128 m8, [r2 + r4]
    vpmaddubsw     m7, m7, m10
    vpmaddubsw     m8, m8, m10
    vpsubw         m7, m7, m8

; satd part
    vpaddw         m8, m0, m1
    vpsubw         m9, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m5
    vpsubw         m3, m4, m5
    vpaddw         m4, m6, m7
    vpsubw         m5, m6, m7
    vpaddw         m6, m8, m0
    vpsubw         m7, m8, m0
    vpaddw         m0, m9, m1
    vpsubw         m8, m9, m1
    vpaddw         m1, m2, m4
    vpsubw         m9, m2, m4
    vpaddw         m2, m3, m5
    vpsubw         m4, m3, m5

    vpblendw       m3, m6, m0, 0AAh
    vpsrld         m6, m6, 16
    vpslld         m0, m0, 16
    vpor           m5, m6, m0
    vpaddw         m6, m3, m5
    vpsubw         m0, m3, m5
    vpabsw         m3, m6
    vpabsw         m5, m0
    vpaddw         m10, m3, m5
    vpblendw       m3, m7, m8, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m8, m8, 16
    vpor           m5, m7, m8
    vpaddw         m7, m3, m5
    vpsubw         m8, m3, m5
    vpabsw         m3, m7
    vpabsw         m5, m8
    vpaddw         m3, m3, m5
    vpaddw         m10, m10, m3
    vpblendw       m3, m1, m2, 0AAh
    vpsrld         m1, m1, 16
    vpslld         m2, m2, 16
    vpor           m5, m1, m2
    vpaddw         m1, m3, m5
    vpsubw         m2, m3, m5
    vpabsw         m3, m1
    vpabsw         m5, m2
    vpaddw         m3, m3, m5
    vpaddw         m10, m10, m3
    vpblendw       m3, m9, m4, 0AAh
    vpsrld         m9, m9, 16
    vpslld         m4, m4, 16
    vpor           m5, m9, m4
    vpaddw         m9, m3, m5
    vpsubw         m4, m3, m5
    vpabsw         m3, m9
    vpabsw         m5, m4
    vpaddw         m3, m3, m5
    vpaddw         m10, m10, m3 
    vpmaddwd       m10, m10, m13
    vpaddd         m11, m11, m10

; sa8d part
    vpaddw         m3, m6, m1
    vpsubw         m5, m6, m1
    vpaddw         m1, m0, m2
    vpsubw         m6, m0, m2
    vpaddw         m0, m7, m9
    vpsubw         m2, m7, m9
    vpaddw         m7, m8, m4
    vpsubw         m9, m8, m4

    vpblendd       m4, m3, m1, 10101010b
    vpsrlq         m3, m3, 32
    vpsllq         m1, m1, 32
    vpor           m3, m3, m1
    vpaddw         m8, m4, m3
    vpabsw         m10, m8
    vpsubw         m3, m4, m3
    vpabsw         m3, m3
    vpaddw         m10, m10, m3
    vpblendd       m4, m0, m7, 10101010b
    vpsrlq         m0, m0, 32
    vpsllq         m7, m7, 32
    vpor           m0, m0, m7
    vpaddw         m7, m4, m0
    vpabsw         m7, m7
    vpaddw         m10, m10, m7
    vpsubw         m7, m4, m0
    vpabsw         m7, m7
    vpaddw         m10, m10, m7
    vpblendd       m4, m5, m6, 10101010b
    vpsrlq         m5, m5, 32
    vpsllq         m6, m6, 32
    vpor           m5, m5, m6
    vpaddw         m7, m4, m5
    vpabsw         m7, m7
    vpaddw         m10, m10, m7
    vpsubw         m7, m4, m5
    vpabsw         m7, m7
    vpaddw         m10, m10, m7
    vpblendd       m4, m2, m9, 10101010b
    vpsrlq         m2, m2, 32
    vpsllq         m9, m9, 32
    vpor           m2, m2, m9
    vpaddw         m7, m4, m2
    vpabsw         m7, m7
    vpaddw         m10, m10, m7
    vpsubw         m7, m4, m2
    vpabsw         m7, m7
    vpaddw         m10, m10, m7
    vpmaddwd       m10, m10, m13
    vpaddd         m12, m12, m10

    vphaddd        m0, m12, m11
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vpshufd        xm1, xm0, 00110001b
    vpaddd         xm0, xm0, xm1
    vpsrld         xm1, xm0, 2
    vpsrld         xm2, xm0, 1
    vpblendd       xm0, xm1, xm2, 00000100b
    vpshufd        xm0, xm0, 00001000b
    vmovq          rax, xm0
%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    vmovdqu        xm13, [rsp + 80]
    add            rsp, 104
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    RET


;=============================================================================
; INTRA_SAD_X9
;=============================================================================
INIT_YMM avx2
cglobal intra_sad_x9_4x4, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 184
    vmovdqu        [rsp + 160], xm8
%else
    sub            rsp, 168
%endif
    lea            r5, [intrax9a_vrl1]
    vmovdqu        xm1, [r1 - 40]
    vpinsrb        xm1, xm1, [r1 + 95],0
    vpinsrb        xm1, xm1, [r1 + 63],1
    vpinsrb        xm1, xm1, [r1 + 31],2
    vpinsrb        xm1, xm1, [r1 - 1],3          ; l3 l2 l1 l0 __ __ __ lt t0 t1 t2 t3 t4 t5 t6 t7
    vpshufb        xm1, xm1, [intrax9_edge]      ; l3 l3 l2 l1 l0 lt t0 t1 t2 t3 t4 t5 t6 t7 t7 __
    vpsrldq        xm0, xm1, 1                   ; l3 l2 l1 l0 lt t0 t1 t2 t3 t4 t5 t6 t7 t7 __ __
    vpsrldq        xm2, xm1, 2                   ; l2 l1 l0 lt t0 t1 t2 t3 t4 t5 t6 t7 t7 __ __ __
    vpavgb         xm5, xm0, xm1                 ; Gl3 Gl2 Gl1 Gl0 Glt Gt0 Gt1 Gt2 Gt3 Gt4 Gt5  __  __ __ __ __
    vinserti128    m5, m5, xm5, 1
    vinserti128    m8, m1, xm1, 1
    vpavgb         xm4, xm1, xm2
    vpxor          xm2, xm2, xm1
    vpbroadcastd   xm3, [pb_1]
    vpand          xm2, xm2, xm3
    vpsubusb       xm4, xm4, xm2
    vpavgb         xm0, xm0, xm4                 ; Fl3 Fl2 Fl1 Fl0 Flt Ft0 Ft1 Ft2 Ft3 Ft4 Ft5 Ft6 Ft7 __ __ __
    vinserti128    m0, m0, xm0, 1

    ; ddl               ddr
    ; Ft1 Ft2 Ft3 Ft4   Flt Ft0 Ft1 Ft2
    ; Ft2 Ft3 Ft4 Ft5   Fl0 Flt Ft0 Ft1
    ; Ft3 Ft4 Ft5 Ft6   Fl1 Fl0 Flt Ft0
    ; Ft4 Ft5 Ft6 Ft7   Fl2 Fl1 Fl0 Flt
    vpshufb        m2, m0, [r5 - 64]                  ; a: ddl row0, ddl row1, ddr row0, ddr row1 / b: ddl row0, ddr row0, ddl row1, ddr row1
                                                 ; rows 2,3

    ; hd                hu
    ; Glt Flt Ft0 Ft1   Gl0 Fl1 Gl1 Fl2
    ; Gl0 Fl0 Glt Flt   Gl1 Fl2 Gl2 Fl3
    ; Gl1 Fl1 Gl0 Fl0   Gl2 Fl3 Gl3 Gl3
    ; Gl2 Fl2 Gl1 Fl1   Gl3 Gl3 Gl3 Gl3
    vpslldq        m0, m0, 5                     ; ___ ___ ___ ___ ___ Fl3 Fl2 Fl1 Fl0 Flt Ft0 Ft1 Ft2 Ft3 Ft4 Ft5
    vpalignr       m7, m5, m0, 5                 ; Fl3 Fl2 Fl1 Fl0 Flt Ft0 Ft1 Ft2 Ft3 Ft4 Ft5 Gl3 Gl2 Gl1 Gl0 Glt
    vpshufb        m6, m7, [r5 - 32]             ; hdu1 | hdu2

    ; vr                vl
    ; Gt0 Gt1 Gt2 Gt3   Gt1 Gt2 Gt3 Gt4
    ; Flt Ft0 Ft1 Ft2   Ft1 Ft2 Ft3 Ft4
    ; Fl0 Gt0 Gt1 Gt2   Gt2 Gt3 Gt4 Gt5
    ; Fl1 Flt Ft0 Ft1   Ft2 Ft3 Ft4 Ft5
    vpsrldq        m5, m5, 5                     ; Gt0 Gt1 Gt2 Gt3 Gt4 Gt5 ...
    vpalignr       m5, m5, m0, 6                 ; ___ Fl1 Fl0 Flt Ft0 Ft1 Ft2 Ft3 Ft4 Ft5 Gt0 Gt1 Gt2 Gt3 Gt4 Gt5
    vpshufb        m4, m5, [r5]                  ; vrl1 | vrl2

    vmovdqu        [rsp], m2
    vmovdqu        [rsp + 32], m4
    vmovdqu        [rsp + 64], m6

    vmovd          xm0, [r0]
    vpinsrd        xm0, xm0, [r0 + 16], 1
    vmovd          xm1, [r0 + 32]
    vpinsrd        xm1, xm1, [r0 + 48],1
    vinserti128    m0, m0, xm1, 1
    vpunpcklqdq    m0, m0, m0
    vpsadbw        m2, m2, m0
    vpsadbw        m4, m4, m0
    vpsadbw        m6, m6, m0
    vpshufb        m3, m8, [r5 + 32]             ; t0 t1 t2 t3 t0 t1 t2 t3 l0 l0 l0 l0 l1 l1 l1 l1
                                                 ; t0 t1 t2 t3 t0 t1 t2 t3 l2 l2 l2 l2 l3 l3 l3 l3
    vpshufb        xm8, xm8, [r5 + 64]           ; l3 l2 l1 l0 t0 t1 t2 t3 0  0  0  0  0  0  0  0
    vpxor          xm7, xm7, xm7
    vpsadbw        xm8, xm8, xm7
    vpsrlw         xm8, xm8, 2
    vpavgw         xm8, xm8, xm7
    vpbroadcastb   m8, xm8
    vmovdqu        [rsp + 96], m3
    vmovdqu        [rsp + 128], m8
    vpsadbw        m3, m3, m0
    vextracti128   xm5, m3, 1
    vpaddd         xm5, xm3, xm5
    vpsadbw        m0, m8, m0
    movzx          r3d, word [r2]
    vmovd          r0d, xm5
    add            r3d, r0d                      ; v
    vpunpckhqdq    m3, m3, m0
    vshufps        m3, m3, m2, 88h               ; h,dc,ddl,ddr
    vpsllq         m6, m6, 32
    vpor           m4, m4, m6                    ; vr,hd,vl,hu
    vmovdqu        xm0, [r2 + 2]
    vpackssdw      m3, m3, m4                    ; h,dc,ddl,ddr,vr,hd,vl,hu
    vextracti128   xm4, m3, 1
    vpaddw         xm3, xm3, xm4
    vpaddw         xm0, xm0, xm3                 ; add cost
    vphminposuw    xm0, xm0                      ; h,dc,ddl,ddr,vr,hd,vl,hu
    vmovd          eax, xm0
    add            eax, 10000h                   ; index not include V
    cmp            ax, r3w
    cmovge         eax, r3d
    mov            r3d, eax
    shr            r3d, 10h
    lea            r2, [r5 + 80]                 ; intrax9a_lut
    movzx          r2d, byte [r2 + r3]
    vmovq          xm0,  [rsp + r2]
    vmovq          xm1,  [rsp + r2 + 16]
    vmovd          [r1], xm0
    vmovd          [r1 + 64], xm1
    vpsrlq         xm0, 32
    vpsrlq         xm1, 32
    vmovd          [r1 + 32], xm0
    vmovd          [r1 + 96], xm1

%if WIN64 
    vmovdqu        xm8, [rsp + 60]
    add            rsp, 184
    vmovdqu        xm7, [rsp + 24]
    vmovdqu        xm6, [rsp + 8]
%else
    add            rsp, 168
%endif
    RET

INIT_YMM avx2
cglobal intra_sad_x9_8x8, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    mov            r4, [rsp + 40]
    sub            rsp, 616
    vmovdqu        [rsp + 576], xm8
    vmovdqu        [rsp + 592], xm9
%else
    sub            rsp, 584
%endif
    vpbroadcastd   m8, [pb_1]
    vmovdqu        m5, [r0]
    vmovdqu        m6, [r0 + 64]
    vpunpcklqdq    m5, m5, [r0 + 32]
    vpunpcklqdq    m6, m6, [r0 + 96]

    ; save instruction size: avoid 4-byte memory offsets
    lea            r0, [intra8x9_vl1]
    vpbroadcastq   m0, [r2 + 16]                 ; v
    vpsadbw        m4, m0, m5
    vpsadbw        m2, m0, m6
    vmovdqu        [rsp], m0
    vmovdqu        [rsp + 32], m0
    vpaddw         m4, m4, m2

    vpbroadcastq   m1, [r2 + 7]                  ; h
    vpshufb        m3, m1, [r0 - 128]            ; intra8x9_h1 intra8x9_h2
    vpshufb        m2, m1, [r0 - 96]             ; intra8x9_h3 intra8x9_h4
    vmovdqu        [rsp + 64], m3
    vmovdqu        [rsp + 96], m2
    vpsadbw        m3, m3, m5
    vpsadbw        m2, m2, m6
    vpaddw         m3, m3, m2

    lea            r5, [rsp + 256]

    ; combine the first two
    vpsllq         m3, m3, 16
    vpor           m4, m4, m3                    ; v, h

    vpxor          m2, m2, m2
    vpsadbw        m0, m0, m2
    vpsadbw        m1, m1, m2
    vpaddw         m0, m0, m1
    vpsrlw         m0, m0, 3
    vpavgw         m0, m0, m2
    vpshufb        m0, m0, m2                    ; dc
    vmovdqu        [r5 - 128], m0
    vmovdqu        [r5 - 96], m0
    vpsadbw        m3, m0, m5
    vpsadbw        m2, m0, m6
    vpaddw         m3, m3, m2
    vpsllq         m3, m3, 32
    vpor           m4, m4, m3                    ; v, h, dc

    vbroadcasti128 m0, [r2 + 16]
    vbroadcasti128 m2, [r2 + 17]
    vpslldq        m1, m0, 1
    vpavgb         m3, m0, m2

    vpavgb         m7, m1, m2
    vpxor          m2, m2, m1
    vpand          m2, m2, m8
    vpsubusb       m7, m7, m2
    vpavgb         m0, m0, m7

    vpshufb        m1, m0, [r0 - 64]             ; intra8x9_ddl1 intra8x9_ddl2
    vpshufb        m2, m0, [r0 - 32]             ; intra8x9_ddl3 intra8x9_ddl4
    vmovdqu        [r5 - 64], m1
    vmovdqu        [r5 - 32], m2
    vpsadbw        m1, m1, m5
    vpsadbw        m2, m2, m6
    vpaddw         m1, m1, m2
    vpsllq         m1, m1, 48
    vpor           m9, m4, m1                    ; v, h, dc, ddl

    ; for later
    vinserti128    m7, m3, xm0, 1
    vbroadcasti128 m2, [r2 + 8]
    vbroadcasti128 m0, [r2 + 7]
    vbroadcasti128 m1, [r2 + 6]
    vpavgb         m3, m2, m0

    vpavgb         m4, m1, m2
    vpxor          m2, m2, m1
    vpand          m2, m2, m8
    vpsubusb       m4, m4, m2
    vpavgb         m0, m0, m4
    vpshufb        m1, m0, [r0 + 64]             ; intra8x9_ddr1 intra8x9_ddr2
    vpshufb        m2, m0, [r0 + 96]             ; intra8x9_ddr3 intra8x9_ddr4
    vmovdqu        [r5], m1
    vmovdqu        [r5 + 32], m2
    vpsadbw        m4, m1, m5
    vpsadbw        m2, m2, m6
    vpaddw         m4, m4, m2                    ; ddr

    add            r0, 256
    add            r5, 192
    vpblendd       m2, m3, m0, 11110011b
    vpshufb        m1, m2, [r0 - 128]            ; intra8x9_vr1 intra8x9_vr2
    vpshufb        m2, m2, [r0 - 96]             ; intra8x9_vr3 intra8x9_vr4
    vmovdqu        [r5 - 128], m1
    vmovdqu        [r5 - 96], m2
    vpsadbw        m1, m1, m5
    vpsadbw        m2, m2, m6
    vpaddw         m1, m1, m2
    vpsllq         m1, m1, 16
    vpor           m4, m4, m1                    ; ddr, vr

    vpsrldq        m2, m3, 4
    vpblendw       m2, m2, m0, q3330
    vpunpcklbw     m0, m0, m3
    vpshufb        m1, m2, [r0 - 64]             ; intra8x9_hd1 intra8x9_hd2
    vpshufb        m2, m0, [r0 - 32]             ; intra8x9_hd3 intra8x9_hd4
    vmovdqu        [r5 - 64], m1
    vmovdqu        [r5 - 32], m2
    vpsadbw        m1, m1, m5
    vpsadbw        m2, m2, m6
    vpaddw         m1, m1, m2
    vpsllq         m1, m1, 32
    vpor           m4, m4, m1                    ; ddr, vr, hd

    vpshufb        m1, m7, [r0 - 256]            ; intra8x9_vl1 intra8x9_vl2
    vpshufb        m2, m7, [r0 - 224]            ; intra8x9_vl3 intra8x9_vl4
    vmovdqu        [r5], m1
    vmovdqu        [r5 + 32], m2
    vpsadbw        m1, m1, m5
    vpsadbw        m2, m2, m6
    vpaddw         m1, m1, m2
    vpsllq         m1, m1, 48
    vpor           m4, m4, m1                    ; ddr, vr, hd, vl
    vpunpckhqdq    m7, m9, m4
    vpunpcklqdq    m3, m9, m4
    vpaddw         m3, m3, m7
    vextracti128   xm7, m3, 1
    vpaddw         xm3, xm3, xm7                 ; v, h, dc, ddl, ddr, vr, hd, vl

    vpslldq        m1, m0, 1
    vpbroadcastd   m0, [r2 + 7]
    vpalignr       m0, m0, m1, 1
    vpshufb        m1, m0, [r0]                  ; intra8x9_hu1 intra8x9_hu2
    vpshufb        m2, m0, [r0 + 32]             ; intra8x9_hu3 intra8x9_hu4
    vmovdqu        [r5 + 64], m1
    vmovdqu        [r5 + 96], m2
    vpsadbw        m1, m1, m5
    vpsadbw        m2, m2, m6
    vpaddw         m1, m1, m2
    vextracti128   xm2, m1, 1
    vpaddw         xm1, xm1, xm2
    vpunpckhqdq    xm2, xm1, xm1
    vpaddw         xm1, xm1, xm2
    vmovd          r2d, xm1                      ; hu

    vpaddw         xm3, xm3, [r3]
    vmovdqu        [r4], xm3
    add            r2w, [r3 + 16]
    mov            [r4 + 16], r2w

    vphminposuw    xm3, xm3
    vmovd          r3d, xm3
    add            r2d, 80000h                   ; add the index of hu
    cmp            r3w, r2w
    cmovg          r3d, r2d

    mov            eax, r3d
    shr            r3, 16
    shl            r3, 6
    add            r1, 128
    vmovdqu        xm0, [rsp + r3]
    vmovdqu        xm1, [rsp + r3 + 16]
    vmovdqu        xm2, [rsp + r3 + 32]
    vmovdqu        xm3, [rsp + r3 + 48]
    vmovq          [r1 - 128], xm0
    vmovhps        [r1 - 64], xm0
    vmovq          [r1 - 96], xm1
    vmovhps        [r1 - 32], xm1
    vmovq          [r1], xm2
    vmovhps        [r1 + 64], xm2
    vmovq          [r1 + 32], xm3
    vmovhps        [r1 + 96], xm3
%if WIN64
    vmovdqu        xm8, [rsp + 576]
    vmovdqu        xm9, [rsp + 592]
    add            rsp, 616
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%else
    add            rsp, 584
%endif
    RET


;=============================================================================
; INTRA_SATD/SA8D_X9
;=============================================================================
INIT_YMM avx2
cglobal intra_satd_x9_4x4, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 216
    vmovdqu        [rsp + 160], xm8
    vmovdqu        [rsp + 176], xm9
    vmovdqu        [rsp + 192], xm10
%else
    sub            rsp, 168
%endif
    lea            r5, [intrax9b_vrl1]
    vmovdqu        xm1, [r1 - 40]
    vpinsrb        xm1, xm1, [r1 + 95],0
    vpinsrb        xm1, xm1, [r1 + 63],1
    vpinsrb        xm1, xm1, [r1 + 31],2
    vpinsrb        xm1, xm1, [r1 - 1],3          ; l3 l2 l1 l0 __ __ __ lt t0 t1 t2 t3 t4 t5 t6 t7
    vpshufb        xm1, xm1, [intrax9_edge]      ; l3 l3 l2 l1 l0 lt t0 t1 t2 t3 t4 t5 t6 t7 t7 __
    vpsrldq        xm0, xm1, 1                   ; l3 l2 l1 l0 lt t0 t1 t2 t3 t4 t5 t6 t7 t7 __ __
    vpsrldq        xm2, xm1, 2                   ; l2 l1 l0 lt t0 t1 t2 t3 t4 t5 t6 t7 t7 __ __ __
    vpavgb         xm5, xm0, xm1                 ; Gl3 Gl2 Gl1 Gl0 Glt Gt0 Gt1 Gt2 Gt3 Gt4 Gt5  __  __ __ __ __
    vinserti128    m5, m5, xm5, 1
    vinserti128    m10, m1, xm1, 1
    vpavgb         xm4, xm1, xm2
    vpxor          xm2, xm2, xm1
    vpbroadcastd   xm3, [pb_1]
    vpand          xm2, xm2, xm3
    vpsubusb       xm4, xm4, xm2
    vpavgb         xm0, xm0, xm4                 ; Fl3 Fl2 Fl1 Fl0 Flt Ft0 Ft1 Ft2 Ft3 Ft4 Ft5 Ft6 Ft7 __ __ __
    vinserti128    m0, m0, xm0, 1

    ; ddl               ddr
    ; Ft1 Ft2 Ft3 Ft4   Flt Ft0 Ft1 Ft2
    ; Ft2 Ft3 Ft4 Ft5   Fl0 Flt Ft0 Ft1
    ; Ft3 Ft4 Ft5 Ft6   Fl1 Fl0 Flt Ft0
    ; Ft4 Ft5 Ft6 Ft7   Fl2 Fl1 Fl0 Flt
    vpshufb        m2, m0, [r5 - 64]             ; a: ddl row0, ddl row1, ddr row0, ddr row1 / b: ddl row0, ddr row0, ddl row1, ddr row1
                                                 ; rows 2,3

    ; hd                hu
    ; Glt Flt Ft0 Ft1   Gl0 Fl1 Gl1 Fl2
    ; Gl0 Fl0 Glt Flt   Gl1 Fl2 Gl2 Fl3
    ; Gl1 Fl1 Gl0 Fl0   Gl2 Fl3 Gl3 Gl3
    ; Gl2 Fl2 Gl1 Fl1   Gl3 Gl3 Gl3 Gl3
    vpslldq        m0, m0, 5                     ; ___ ___ ___ ___ ___ Fl3 Fl2 Fl1 Fl0 Flt Ft0 Ft1 Ft2 Ft3 Ft4 Ft5
    vpalignr       m7, m5, m0, 5                 ; Fl3 Fl2 Fl1 Fl0 Flt Ft0 Ft1 Ft2 Ft3 Ft4 Ft5 Gl3 Gl2 Gl1 Gl0 Glt
    vpshufb        m6, m7, [r5 - 32]             ; hdu1 | hdu2

    ; vr                vl
    ; Gt0 Gt1 Gt2 Gt3   Gt1 Gt2 Gt3 Gt4
    ; Flt Ft0 Ft1 Ft2   Ft1 Ft2 Ft3 Ft4
    ; Fl0 Gt0 Gt1 Gt2   Gt2 Gt3 Gt4 Gt5
    ; Fl1 Flt Ft0 Ft1   Ft2 Ft3 Ft4 Ft5
    vpsrldq        m5, m5, 5                     ; Gt0 Gt1 Gt2 Gt3 Gt4 Gt5 ...
    vpalignr       m5, m5, m0, 6                 ; ___ Fl1 Fl0 Flt Ft0 Ft1 Ft2 Ft3 Ft4 Ft5 Gt0 Gt1 Gt2 Gt3 Gt4 Gt5
    vpshufb        m4, m5, [r5]                  ; vrl1 | vrl2

    vmovdqu        [rsp], m2
    vmovdqu        [rsp + 32], m4
    vmovdqu        [rsp + 64], m6
    vpbroadcastd   xm0, [r0]
    vpbroadcastd   xm1, [r0 + 16]
    vpbroadcastd   xm3, [r0 + 32]
    vpbroadcastd   xm5, [r0 + 48]
    vinserti128    m7, m0, xm3, 1
    vinserti128    m8, m1, xm5, 1
    vbroadcasti128 m9, [hmul_8p]
    vpmaddubsw     m7, m7, m9
    vpmaddubsw     m8, m8, m9

    vmovddup       m0, m2
    vpunpckhqdq    m1, m2, m2
    call           .satd_8x4                     ; ddl, ddr
    vmovdqu        m5, m0
    vmovddup       m0, m4
    vpunpckhqdq    m1, m4, m4
    call           .satd_8x4                     ; vr, vl
    vmovdqu        m4, m0
    vmovddup       m0, m6
    vpunpckhqdq    m1, m6, m6
    call           .satd_8x4                     ; hd, hu
    vpunpckldq     m1, m4, m0
    vpunpckhdq     m4, m4, m0
    vpaddw         m4, m4, m1                    ; vr, hd, vl, hu

    vpshufb        m2, m10, [r5 + 32]
    vmovdqu        [rsp + 96], m2
    vmovddup       m0, m2
    vpunpckhqdq    m1, m2, m2
    call           .satd_8x4                     ; v, h
    vmovdqu        m6, m0
    vpshufb        xm10, xm10, [r5 + 64]         ; t0 t1 t2 t3 l0 l1 l2 l3 _ _ _ _ _ _ _ _
    vpxor          xm0, xm0, xm0
    vpsadbw        xm10, xm10, xm0
    vpsrlw         xm10, xm10, 2
    vpavgw         xm10, xm10, xm0
    vpbroadcastb   m10, xm10
    vmovdqu        [rsp + 128], m10
    vmovddup       m0, m10
    vpunpckhqdq    m1, m10, m10
    call           .satd_8x4                     ; dc
    vpbroadcastd   m1, [pw_1]
    vpmaddwd       m5, m5, m1                    ; ddl, ddr
    vpmaddwd       m4, m4, m1                    ; vr, hd, vl, hu
    vpmaddwd       m6, m6, m1                    ; v, h
    vpmaddwd       m0, m0, m1                    ; dc

    vextracti128   xm1, m6, 1
    vpaddd         xm1, xm1, xm6
    vpunpckhqdq    xm3, xm1, xm1
    vpaddd         xm1, xm1, xm3
    movzx          r3d, word [r2]
    vmovd          r0d, xm1
    add            r3d, r0d                      ; v
    vpsrlq         m6, m6, 32
    vpblendd       m0, m6, m0, 10101010b         ; h, dc
    vpunpcklqdq    m1, m0, m5
    vpunpckhqdq    m5, m0, m5
    vpaddd         m1, m1, m5                    ; h, dc, ddl, ddr
    vmovdqu        xm0, [r2 + 2]
    vpackssdw      m1, m1, m4                    ; h,dc,ddl,ddr,vr,hd,vl,hu
    vextracti128   xm2, m1, 1
    vpaddw         xm1, xm1, xm2
    vpaddw         xm0, xm0, xm1                 ; add cost
    vphminposuw    xm0, xm0                      ; h,dc,ddl,ddr,vr,hd,vl,hu
    vmovd          eax, xm0
    add            eax, 10000h                   ; index not include V
    cmp            ax, r3w
    cmovge         eax, r3d
    mov            r3d, eax
    shr            r3d, 10h

    ; output the predicted samples
    lea            r2, [r5 + 80]                 ; intrax9b_lut
    movzx          r2d, byte [r2 + r3]
    mov            r3d, [rsp + r2]
    mov            [r1], r3d
    mov            r3d, [rsp + r2 + 8]
    mov            [r1 + 32], r3d
    mov            r3d, [rsp + r2 + 16]
    mov            [r1 + 64], r3d
    mov            r3d, [rsp + r2 + 24]
    mov            [r1 + 96], r3d

%if WIN64
    vmovdqu        xm8, [rsp + 160]
    vmovdqu        xm9, [rsp + 176]
    vmovdqu        xm10, [rsp + 192]
    add            rsp, 216
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%else
    add            rsp, 168
%endif
    RET

ALIGN 16
.satd_8x4:
    vpmaddubsw     m0, m0, m9
    vpmaddubsw     m1, m1, m9
    vpsubw         m0, m0, m7
    vpsubw         m1, m1, m8

    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vperm2i128     m1, m2, m3, 31h
    vinserti128    m0, m2, xm3, 1
    vpaddw         m2, m0, m1
    vpsubw         m3, m0, m1
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m2, m2, 10h
    vpslld         m3, m3, 10h
    vpor           m2, m2, m3
    vpmaxsw        m0, m1, m2
    ret


INIT_YMM avx2
cglobal intra_sa8d_x9_8x8, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 136
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
    vmovdqu        [rsp + 80], xm13
    vmovdqu        [rsp + 96], xm14
    vmovdqu        [rsp + 112], xm15
    sub            rsp, 608
%else
    sub            rsp, 616
%endif
    vbroadcasti128 m10, [hmul_8p]
    vmovddup       m6, [r0]
    vmovddup       m7, [r0 + 32]
    vmovddup       m8, [r0 + 64]
    vmovddup       m9, [r0 + 96]
    vpmaddubsw     m6, m6, m10
    vpmaddubsw     m7, m7, m10
    vpmaddubsw     m8, m8, m10
    vpmaddubsw     m9, m9, m10

    ; save instruction size: avoid 4-byte memory offsets
    lea            r0, [intra8x9_vl1]
    vpbroadcastq   m12, [r2 + 16]                ; v
    vmovdqu        [rsp], m12
    vmovdqu        [rsp + 32], m12
    vmovdqu        m0, m12
    vmovdqu        m1, m12
    vmovdqu        m2, m12
    vmovdqu        m3, m12
    call           .sa8d
    vmovdqu        m14, m0

    vpbroadcastq   m13, [r2 + 7]                 ; h
    vpshufb        m4, m13, [r0 - 128]           ; intra8x9_h1 intra8x9_h2
    vpshufb        m5, m13, [r0 - 96]            ; intra8x9_h3 intra8x9_h4
    vmovdqu        [rsp + 64], m4
    vmovdqu        [rsp + 96], m5
    vmovddup       m0, m4
    vpunpckhqdq    m1, m4, m4
    vmovddup       m2, m5
    vpunpckhqdq    m3, m5, m5
    call           .sa8d
    vphaddw        m14, m14, m0                  ; v, h

    lea            r5, [rsp + 256]
    vpxor          m2, m2, m2
    vpsadbw        m12, m12, m2
    vpsadbw        m13, m13, m2
    vpaddw         m0, m12, m13
    vpsrlw         m0, m0, 3
    vpavgw         m0, m0, m2
    vpshufb        m0, m0, m2                    ; dc
    vmovdqu        [r5 - 128], m0
    vmovdqu        [r5 - 96], m0
    vmovdqu        m1, m0
    vmovdqu        m2, m0
    vmovdqu        m3, m0
    call           .sa8d
    vmovdqu        m15, m0

    vbroadcasti128 m12, [r2 + 16]
    vbroadcasti128 m13, [r2 + 17]
    vpslldq        m1, m12, 1
    vpavgb         m11, m12, m13

    vpbroadcastd   m0, [pb_1]
    vpavgb         m4, m1, m13
    vpxor          m13, m13, m1
    vpand          m13, m13, m0
    vpsubusb       m4, m4, m13
    vpavgb         m12, m12, m4

    vpshufb        m4, m12, [r0 - 64]            ; intra8x9_ddl1 intra8x9_ddl2
    vpshufb        m5, m12, [r0 - 32]            ; intra8x9_ddl3 intra8x9_ddl4
    vmovdqu        [r5 - 64], m4
    vmovdqu        [r5 - 32], m5
    vmovddup       m0, m4
    vpunpckhqdq    m1, m4, m4
    vmovddup       m2, m5
    vpunpckhqdq    m3, m5, m5
    call           .sa8d
    vphaddw        m15, m15, m0                  ; dc, ddl
    vphaddw        m14, m14, m15                 ; v, h, dc, ddl
    vmovdqu        [rsp + 576], m14

    ; for later
    vinserti128    m11, m11, xm12, 1
    vbroadcasti128 m12, [r2 + 8]
    vbroadcasti128 m13, [r2 + 7]
    vbroadcasti128 m14, [r2 + 6]
    vpavgb         m15, m12, m13

    vpbroadcastd   m0, [pb_1]
    vpavgb         m4, m14, m12
    vpxor          m12, m12, m14
    vpand          m12, m12, m0
    vpsubusb       m4, m4, m12
    vpavgb         m13, m13, m4
    vpshufb        m4, m13, [r0 + 64]            ; intra8x9_ddr1 intra8x9_ddr2
    vpshufb        m5, m13, [r0 + 96]            ; intra8x9_ddr3 intra8x9_ddr4
    vmovdqu        [r5], m4
    vmovdqu        [r5 + 32], m5
    vmovddup       m0, m4
    vpunpckhqdq    m1, m4, m4
    vmovddup       m2, m5
    vpunpckhqdq    m3, m5, m5
    call           .sa8d
    vmovdqu        m14, m0                       ; ddr

    add            r0, 256
    add            r5, 192
    vpblendd       m2, m15, m13, 11110011b
    vpshufb        m4, m2, [r0 - 128]            ; intra8x9_vr1 intra8x9_vr2
    vpshufb        m5, m2, [r0 - 96]             ; intra8x9_vr3 intra8x9_vr4
    vmovdqu        [r5 - 128], m4
    vmovdqu        [r5 - 96], m5
    vmovddup       m0, m4
    vpunpckhqdq    m1, m4, m4
    vmovddup       m2, m5
    vpunpckhqdq    m3, m5, m5
    call           .sa8d
    vphaddw        m14, m14, m0                  ; ddr, vr

    vpsrldq        m2, m15, 4
    vpblendw       m2, m2, m13, q3330
    vpunpcklbw     m13, m13, m15
    vpshufb        m4, m2, [r0 - 64]             ; intra8x9_hd1 intra8x9_hd2
    vpshufb        m5, m13, [r0 - 32]            ; intra8x9_hd3 intra8x9_hd4
    vmovdqu        [r5 - 64], m4
    vmovdqu        [r5 - 32], m5
    vmovddup       m0, m4
    vpunpckhqdq    m1, m4, m4
    vmovddup       m2, m5
    vpunpckhqdq    m3, m5, m5
    call           .sa8d
    vmovdqu        m15, m0                       ; hd

    vpshufb        m4, m11, [r0 - 256]           ; intra8x9_vl1 intra8x9_vl2
    vpshufb        m5, m11, [r0 - 224]           ; intra8x9_vl3 intra8x9_vl4
    vmovdqu        [r5], m4
    vmovdqu        [r5 + 32], m5
    vmovddup       m0, m4
    vpunpckhqdq    m1, m4, m4
    vmovddup       m2, m5
    vpunpckhqdq    m3, m5, m5
    call           .sa8d
    vphaddw        m15, m15, m0                  ; hd, vl
    vphaddw        m14, m14, m15                 ; ddr, vr, hd, vl
    vmovdqu        m15, [rsp + 576]
    vphaddw        m14, m15, m14
    vextracti128   xm15, m14, 1
    vpavgw         xm14, xm14, xm15              ; v, h, dc, ddl, ddr, vr, hd, vl

    vpslldq        m1, m13, 1
    vpbroadcastd   m0, [r2 + 7]
    vpalignr       m0, m0, m1, 1
    vpshufb        m4, m0, [r0]                  ; intra8x9_hu1 intra8x9_hu2
    vpshufb        m5, m0, [r0 + 32]             ; intra8x9_hu3 intra8x9_hu4
    vmovdqu        [r5 + 64], m4
    vmovdqu        [r5 + 96], m5
    vmovddup       m0, m4
    vpunpckhqdq    m1, m4, m4
    vmovddup       m2, m5
    vpunpckhqdq    m3, m5, m5
    call           .sa8d
    vextracti128   xm1, m0, 1
    vpaddw         xm0, xm0, xm1
    vpunpckhqdq    xm1, xm0, xm0
    vpaddw         xm0, xm0, xm1
    vpshufd        xm1, xm0, 1
    vpaddw         xm0, xm0, xm1
    vpshuflw       xm1, xm0, 1
    vpavgw         xm0, xm0, xm1
    vpextrw        r2d, xm0, 0                   ; hu

    vpaddw         xm3, xm14, [r3]
    vmovdqu        [r4], xm3
    add            r2w, [r3 + 16]
    mov            [r4 + 16], r2w

    vphminposuw    xm3, xm3
    vmovd          r3d, xm3
    add            r2d, 80000h                   ; add the index of hu
    cmp            r3w, r2w
    cmovg          r3d, r2d

    mov            eax, r3d
    shr            r3, 16
    shl            r3, 6
    add            r1, 128
    vmovdqu        xm0, [rsp + r3]
    vmovdqu        xm1, [rsp + r3 + 16]
    vmovdqu        xm2, [rsp + r3 + 32]
    vmovdqu        xm3, [rsp + r3 + 48]
    vmovq          [r1 - 128], xm0
    vmovhps        [r1 - 64], xm0
    vmovq          [r1 - 96], xm1
    vmovhps        [r1 - 32], xm1
    vmovq          [r1], xm2
    vmovhps        [r1 + 64], xm2
    vmovq          [r1 + 32], xm3
    vmovhps        [r1 + 96], xm3

%if WIN64
    add            rsp, 608
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    vmovdqu        xm13, [rsp + 80]
    vmovdqu        xm14, [rsp + 96]
    vmovdqu        xm15, [rsp + 112]
    add            rsp, 136
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%else
    add            rsp, 616
%endif
    RET

ALIGN 16
.sa8d:
    vpmaddubsw     m0, m0, m10
    vpmaddubsw     m1, m1, m10
    vpmaddubsw     m2, m2, m10
    vpmaddubsw     m3, m3, m10
    vpsubw         m0, m0, m6
    vpsubw         m1, m1, m7
    vpsubw         m2, m2, m8
    vpsubw         m3, m3, m9

    vpaddw         m4, m0, m1
    vpsubw         m5, m0, m1
    vpaddw         m0, m2, m3
    vpsubw         m1, m2, m3
    vpaddw         m2, m4, m0
    vpsubw         m3, m4, m0
    vpaddw         m0, m5, m1
    vpsubw         m4, m5, m1
    vperm2i128     m1, m2, m3, 31h
    vinserti128    m5, m2, xm3, 1
    vpaddw         m2, m1, m5
    vpsubw         m3, m1, m5
    vperm2i128     m1, m0, m4, 31h
    vinserti128    m5, m0, xm4, 1
    vpaddw         m0, m1, m5
    vpsubw         m4, m1, m5

    vshufps        m1, m2, m3, 0DDh
    vshufps        m5, m2, m3, 88h
    vpaddw         m2, m1, m5
    vpsubw         m3, m1, m5
    vshufps        m1, m0, m4, 0DDh
    vshufps        m5, m0, m4, 88h
    vpaddw         m0, m1, m5
    vpsubw         m4, m1, m5
    vpabsw         m2, m2
    vpabsw         m3, m3
    vpabsw         m0, m0
    vpabsw         m4, m4
    vpblendw       m1, m2, m3, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m3, m3, 16
    vpor           m2, m2, m3
    vpmaxsw        m2, m2, m1
    vpblendw       m5, m0, m4, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m4, m4, 16
    vpor           m0, m0, m4
    vpmaxsw        m0, m0, m5
    vpaddw         m0, m0, m2
    ret


;=============================================================================
; INTRA SATD
;=============================================================================
INIT_YMM avx2
cglobal intra_satd_x3_4x4, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 24
    vmovdqu        [rsp], xm8
%endif
    vmovdqu        xm4, [intra_satd_4x4_shuf]
    vpbroadcastq   m7, [hmul_4p]
    vpbroadcastd   xm0, [r1 - 32]
    vmovd          xm1, [r1 + 92]
    vpinsrb        xm1, xm1, [r1 - 1], 0
    vpinsrb        xm1, xm1, [r1 + 31], 1
    vpinsrb        xm1, xm1, [r1 + 63], 2
    vpunpckldq     xm2, xm0, xm1
    vpxor          xm3, xm3, xm3
    vpsadbw        xm2, xm2, xm3
    vpsrlw         xm2, xm2, 2
    vpavgw         xm2, xm2, xm3
    vpbroadcastb   xm2, xm2
    vinserti128    m0, m0, xm2, 1
    vpmaddubsw     m0, m0, m7                       ; v dc
    vpshufb        xm2, xm1, xm4
    vpmaddubsw     xm2, xm2, xm7                    ; h1
    vpsrld         xm1, xm1, 16
    vpshufb        xm1, xm1, xm4
    vpmaddubsw     xm1, xm1, xm7                    ; h2

    vmovd          xm3, [r0]
    vmovd          xm4, [r0 + 16]
    vshufps        xm3, xm3, xm4, 0
    vinserti128    m3, m3, xm3, 1
    vpmaddubsw     m3, m3, m7
    vmovd          xm4, [r0 + 32]
    vmovd          xm5, [r0 + 48]
    vshufps        xm4, xm4, xm5, 0
    vinserti128    m4, m4, xm4, 1
    vpmaddubsw     m4, m4, m7

; v + dc
    vpsubw         m5, m3, m0
    vpsubw         m6, m4, m0
    vpaddw         m7, m5, m6
    vpsubw         m8, m5, m6
    vpunpcklqdq    m5, m7, m8
    vpunpckhqdq    m6, m7, m8
    vpaddw         m7, m5, m6
    vpsubw         m8, m5, m6
    vpblendw       m5, m7, m8, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m8, m8, 16
    vpor           m7, m7, m8
    vpabsw         m5, m5
    vpabsw         m7, m7
    vpmaxsw        m0, m5, m7

; h
    vpsubw         xm5, xm3, xm2
    vpsubw         xm6, xm4, xm1
    vpaddw         xm7, xm5, xm6
    vpsubw         xm8, xm5, xm6
    vpunpcklqdq    xm5, xm7, xm8
    vpunpckhqdq    xm6, xm7, xm8
    vpaddw         xm7, xm5, xm6
    vpsubw         xm8, xm5, xm6
    vpblendw       xm5, xm7, xm8, 0AAh
    vpsrld         xm7, xm7, 16
    vpslld         xm8, xm8, 16
    vpor           xm7, xm7, xm8
    vpabsw         xm5, xm5
    vpabsw         xm7, xm7
    vpmaxsw        xm1, xm5, xm7
    vextracti128   xm2, m0, 1

%if WIN64
    vmovdqu        xm8, [rsp]
    add            rsp, 24
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vpbroadcastd   xm5, [pw_1]
    vpxor          xm3, xm3, xm3
    vphaddw        xm0, xm0, xm1
    vphaddw        xm2, xm2, xm3
    vphaddw        xm0, xm0, xm2
    vpmaddwd       xm0, xm0, xm5
    vmovdqu        [r2], xm0
    RET


INIT_YMM avx2
cglobal intra_satd_x3_8x8c, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 88
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
%endif
    vbroadcasti128 m8, [hmul_8p]
    vpbroadcastq   m7, [intra_satd_8x8c_shuf_dc]
    vpbroadcastq   m0, [r1 - 32]                 ; V0 V1
    lea            r6, [r1 + 127]
    vmovd          xm1, [r1 + 92]
    vmovd          xm2, [r6 + 93]
    vpinsrb        xm1, xm1, [r1 - 1], 0
    vpinsrb        xm2, xm2, [r6], 0
    vpinsrb        xm1, xm1, [r1 + 31], 1
    vpinsrb        xm2, xm2, [r6 + 32], 1
    vpinsrb        xm1, xm1, [r1 + 63], 2        ; H0
    vpinsrb        xm2, xm2, [r6 + 64], 2        ; H1
    vpunpckldq     xm3, xm1, xm2                 ; H0 H1
    vpunpcklqdq    xm3, xm0, xm3                 ; V0 V1 H0 H1
    vinserti128    m1, m1, xm2, 1
    vpunpcklbw     m1, m1, m1
    vpunpcklwd     m1, m1, m1                    ; H0 | H1
    vpshufd        xm2, xm3, q1310               ; V0 V1 H1 V1
    vpshufd        xm3, xm3, q3312               ; H0 V1 H1 H1
    vpmovzxbw      m2, xm2
    vpmovzxbw      m3, xm3
    vpxor          m4, m4, m4
    vpsadbw        m2, m2, m4
    vpsadbw        m3, m3, m4
    vpaddw         m2, m2, m3
    vpsrlw         m2, m2, 2
    vpavgw         m2, m2, m4                    ; DC0 DC1 | DC2 DC3
    vpshufb        m2, m2, m7                    ; DC 0 1 0 1 | 2 3 2 3
    vpmaddubsw     m0, m0, m8                    ; V
    vpmaddubsw     m2, m2, m8                    ; DC

    vmovddup       xm3, [r0]
    vmovddup       xm4, [r0 + 64]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m8
    vmovddup       xm4, [r0 + 16]
    vmovddup       xm5, [r0 + 80]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m8
    vmovddup       xm5, [r0 + 32]
    vmovddup       xm6, [r0 + 96]
    vinserti128    m5, m5, xm6, 1
    vpmaddubsw     m5, m5, m8
    vmovddup       xm6, [r0 + 48]
    vmovddup       xm7, [r0 + 112]
    vinserti128    m6, m6, xm7, 1
    vpmaddubsw     m6, m6, m8

; DC
    vpsubw         m7, m2, m3
    vpsubw         m9, m2, m4
    vpsubw         m10, m2, m5
    vpsubw         m2, m2, m6

    vpaddw         m11, m7, m9
    vpsubw         m12, m7, m9
    vpaddw         m7, m10, m2
    vpsubw         m9, m10, m2
    vpaddw         m10, m11, m7
    vpsubw         m2, m11, m7
    vpaddw         m7, m12, m9
    vpsubw         m11, m12, m9
    vpabsw         m10, m10
    vpabsw         m2, m2
    vpabsw         m7, m7
    vpabsw         m11, m11
    vpblendw       m9, m10, m2, 0AAh
    vpsrld         m10, m10, 16
    vpslld         m2, m2, 16
    vpor           m2, m2, m10
    vpmaxsw        m2, m2, m9
    vpblendw       m9, m7, m11, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m11, m11, 16
    vpor           m7, m7, m11
    vpmaxsw        m7, m7, m9
    vpaddw         m2, m2, m7

; V
    vpsubw         m7, m0, m3
    vpsubw         m9, m0, m4
    vpsubw         m10, m0, m5
    vpsubw         m0, m0, m6

    vpaddw         m11, m7, m9
    vpsubw         m12, m7, m9
    vpaddw         m7, m10, m0
    vpsubw         m9, m10, m0
    vpaddw         m10, m11, m7
    vpsubw         m0, m11, m7
    vpaddw         m7, m12, m9
    vpsubw         m11, m12, m9
    vpabsw         m10, m10
    vpabsw         m0, m0
    vpabsw         m7, m7
    vpabsw         m11, m11
    vpblendw       m9, m10, m0, 0AAh
    vpsrld         m10, m10, 16
    vpslld         m0, m0, 16
    vpor           m0, m0, m10
    vpmaxsw        m0, m0, m9
    vpblendw       m9, m7, m11, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m11, m11, 16
    vpor           m7, m7, m11
    vpmaxsw        m7, m7, m9
    vpaddw         m0, m0, m7

; H
    vpshufd        m7, m1, q0000
    vpmaddubsw     m7, m7, m8
    vpsubw         m3, m7, m3
    vpshufd        m7, m1, q1111
    vpmaddubsw     m7, m7, m8
    vpsubw         m4, m7, m4
    vpshufd        m7, m1, q2222
    vpmaddubsw     m7, m7, m8
    vpsubw         m5, m7, m5
    vpshufd        m7, m1, q3333
    vpmaddubsw     m7, m7, m8
    vpsubw         m6, m7, m6

    vpaddw         m7, m3, m4
    vpsubw         m8, m3, m4
    vpaddw         m3, m5, m6
    vpsubw         m4, m5, m6
    vpaddw         m5, m7, m3
    vpsubw         m6, m7, m3
    vpaddw         m3, m8, m4
    vpsubw         m7, m8, m4
    vpabsw         m5, m5
    vpabsw         m6, m6
    vpabsw         m3, m3
    vpabsw         m7, m7
    vpblendw       m4, m5, m6, 0AAh
    vpsrld         m5, m5, 16
    vpslld         m6, m6, 16
    vpor           m5, m5, m6
    vpmaxsw        m5, m5, m4
    vpblendw       m4, m3, m7, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m7, m7, 16
    vpor           m3, m3, m7
    vpmaxsw        m3, m3, m4
    vpaddw         m1, m3, m5

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    add            rsp, 88
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vpbroadcastd   xm5, [pw_1]
    vpxor          m3, m3, m3
    vphaddw        m2, m2, m1
    vphaddw        m0, m0, m3
    vphaddw        m0, m2, m0
    vextracti128   xm1, m0, 1
    vpaddw         xm0, xm0, xm1
    vpmaddwd       xm0, xm0, xm5
    vmovdqu        [r2], xm0
    RET


INIT_YMM avx2
cglobal intra_satd_x3_8x16c, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 136
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
    vmovdqu        [rsp + 80], xm13
    vmovdqu        [rsp + 96], xm14
    vmovdqu        [rsp + 112], xm15
%endif
    vbroadcasti128 m8, [hmul_8p]
    vpbroadcastq   m14, [intra_satd_8x8c_shuf_dc]
    vpbroadcastq   m0, [r1 - 32]                 ; V0 V1
    lea            r6, [r1 + 127]
    vmovd          xm1, [r1 + 92]
    vmovd          xm2, [r6 + 93]
    vpinsrb        xm1, xm1, [r1 - 1], 0
    vpinsrb        xm2, xm2, [r6], 0
    vpinsrb        xm1, xm1, [r1 + 31], 1
    vpinsrb        xm2, xm2, [r6 + 32], 1
    vpinsrb        xm1, xm1, [r1 + 63], 2        ; H0
    vpinsrb        xm2, xm2, [r6 + 64], 2        ; H1
    add            r1, 255
    add            r6, 256
    vpunpckldq     xm3, xm1, xm2                 ; H0 H1
    vpunpcklqdq    xm3, xm0, xm3                 ; V0 V1 H0 H1
    vinserti128    m1, m1, xm2, 1
    vpunpcklbw     m1, m1, m1
    vpunpcklwd     m1, m1, m1                    ; H0 | H1
    vpshufd        xm2, xm3, q1310               ; V0 V1 H1 V1
    vpshufd        xm3, xm3, q3312               ; H0 V1 H1 H1
    vpmovzxbw      m2, xm2
    vpmovzxbw      m3, xm3
    vpxor          m4, m4, m4
    vpsadbw        m2, m2, m4
    vpsadbw        m3, m3, m4
    vpaddw         m2, m2, m3
    vpsrlw         m2, m2, 2
    vpavgw         m2, m2, m4                    ; DC0 DC1 | DC2 DC3
    vpshufb        m2, m2, m14                   ; DC 0 1 0 1 | 2 3 2 3
    vpmaddubsw     m0, m0, m8                    ; V
    vpmaddubsw     m2, m2, m8                    ; DC

    vmovddup       xm3, [r0]
    vmovddup       xm4, [r0 + 64]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m8
    vmovddup       xm4, [r0 + 16]
    vmovddup       xm5, [r0 + 80]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m8
    vmovddup       xm5, [r0 + 32]
    vmovddup       xm6, [r0 + 96]
    vinserti128    m5, m5, xm6, 1
    vpmaddubsw     m5, m5, m8
    vmovddup       xm6, [r0 + 48]
    vmovddup       xm7, [r0 + 112]
    vinserti128    m6, m6, xm7, 1
    vpmaddubsw     m6, m6, m8
    add            r0, 128

; DC
    vpsubw         m7, m2, m3
    vpsubw         m9, m2, m4
    vpsubw         m10, m2, m5
    vpsubw         m2, m2, m6

    vpaddw         m11, m7, m9
    vpsubw         m12, m7, m9
    vpaddw         m7, m10, m2
    vpsubw         m9, m10, m2
    vpaddw         m10, m11, m7
    vpsubw         m2, m11, m7
    vpaddw         m7, m12, m9
    vpsubw         m11, m12, m9
    vpabsw         m10, m10
    vpabsw         m2, m2
    vpabsw         m7, m7
    vpabsw         m11, m11
    vpblendw       m9, m10, m2, 0AAh
    vpsrld         m10, m10, 16
    vpslld         m2, m2, 16
    vpor           m2, m2, m10
    vpmaxsw        m2, m2, m9
    vpblendw       m9, m7, m11, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m11, m11, 16
    vpor           m7, m7, m11
    vpmaxsw        m7, m7, m9
    vpaddw         m13, m2, m7

; V
    vpsubw         m7, m0, m3
    vpsubw         m9, m0, m4
    vpsubw         m10, m0, m5
    vpsubw         m2, m0, m6

    vpaddw         m11, m7, m9
    vpsubw         m12, m7, m9
    vpaddw         m7, m10, m2
    vpsubw         m9, m10, m2
    vpaddw         m10, m11, m7
    vpsubw         m2, m11, m7
    vpaddw         m7, m12, m9
    vpsubw         m11, m12, m9
    vpabsw         m10, m10
    vpabsw         m2, m2
    vpabsw         m7, m7
    vpabsw         m11, m11
    vpblendw       m9, m10, m2, 0AAh
    vpsrld         m10, m10, 16
    vpslld         m2, m2, 16
    vpor           m2, m2, m10
    vpmaxsw        m2, m2, m9
    vpblendw       m9, m7, m11, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m11, m11, 16
    vpor           m7, m7, m11
    vpmaxsw        m7, m7, m9
    vpaddw         m15, m2, m7

; H
    vpshufd        m7, m1, q0000
    vpmaddubsw     m7, m7, m8
    vpsubw         m3, m7, m3
    vpshufd        m7, m1, q1111
    vpmaddubsw     m7, m7, m8
    vpsubw         m4, m7, m4
    vpshufd        m7, m1, q2222
    vpmaddubsw     m7, m7, m8
    vpsubw         m5, m7, m5
    vpshufd        m7, m1, q3333
    vpmaddubsw     m7, m7, m8
    vpsubw         m6, m7, m6

    vpaddw         m7, m3, m4
    vpsubw         m9, m3, m4
    vpaddw         m3, m5, m6
    vpsubw         m4, m5, m6
    vpaddw         m5, m7, m3
    vpsubw         m6, m7, m3
    vpaddw         m3, m9, m4
    vpsubw         m7, m9, m4
    vpabsw         m5, m5
    vpabsw         m6, m6
    vpabsw         m3, m3
    vpabsw         m7, m7
    vpblendw       m4, m5, m6, 0AAh
    vpsrld         m5, m5, 16
    vpslld         m6, m6, 16
    vpor           m5, m5, m6
    vpmaxsw        m5, m5, m4
    vpblendw       m4, m3, m7, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m7, m7, 16
    vpor           m3, m3, m7
    vpmaxsw        m3, m3, m4
    vmovdqu        m7, m14
    vpaddw         m14, m3, m5

    vmovd          xm1, [r1 + 93]
    vmovd          xm2, [r6 + 93]
    vpinsrb        xm1, xm1, [r1], 0
    vpinsrb        xm2, xm2, [r6], 0
    vpinsrb        xm1, xm1, [r1 + 32], 1
    vpinsrb        xm2, xm2, [r6 + 32], 1
    vpinsrb        xm1, xm1, [r1 + 64], 2        ; H2
    vpinsrb        xm2, xm2, [r6 + 64], 2        ; H3
    vpunpckldq     xm3, xm1, xm2                 ; H2 H3
    vpunpcklqdq    xm3, xm0, xm3                 ; V0 V1 H2 H3
    vinserti128    m1, m1, xm2, 1
    vpunpcklbw     m1, m1, m1
    vpunpcklwd     m1, m1, m1                    ; H2 | H3
    vpshufd        xm2, xm3, q1312               ; H2 V1 H3 V1
    vpshufd        xm3, xm3, q3322               ; H2 H2 H3 H3
    vpmovzxbw      m2, xm2
    vpmovzxbw      m3, xm3
    vpxor          m4, m4, m4
    vpsadbw        m2, m2, m4
    vpsadbw        m3, m3, m4
    vpaddw         m2, m2, m3
    vpsrlw         m2, m2, 2
    vpavgw         m2, m2, m4                    ; DC4 DC5 | DC6 DC7
    vpshufb        m2, m2, m7                    ; DC 4 5 4 5 | 6 7 6 7
    vpmaddubsw     m2, m2, m8                    ; DC

    vmovddup       xm3, [r0]
    vmovddup       xm4, [r0 + 64]
    vinserti128    m3, m3, xm4, 1
    vpmaddubsw     m3, m3, m8
    vmovddup       xm4, [r0 + 16]
    vmovddup       xm5, [r0 + 80]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m8
    vmovddup       xm5, [r0 + 32]
    vmovddup       xm6, [r0 + 96]
    vinserti128    m5, m5, xm6, 1
    vpmaddubsw     m5, m5, m8
    vmovddup       xm6, [r0 + 48]
    vmovddup       xm7, [r0 + 112]
    vinserti128    m6, m6, xm7, 1
    vpmaddubsw     m6, m6, m8

; DC
    vpsubw         m7, m2, m3
    vpsubw         m9, m2, m4
    vpsubw         m10, m2, m5
    vpsubw         m2, m2, m6

    vpaddw         m11, m7, m9
    vpsubw         m12, m7, m9
    vpaddw         m7, m10, m2
    vpsubw         m9, m10, m2
    vpaddw         m10, m11, m7
    vpsubw         m2, m11, m7
    vpaddw         m7, m12, m9
    vpsubw         m11, m12, m9
    vpabsw         m10, m10
    vpabsw         m2, m2
    vpabsw         m7, m7
    vpabsw         m11, m11
    vpblendw       m9, m10, m2, 0AAh
    vpsrld         m10, m10, 16
    vpslld         m2, m2, 16
    vpor           m2, m2, m10
    vpmaxsw        m2, m2, m9
    vpblendw       m9, m7, m11, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m11, m11, 16
    vpor           m7, m7, m11
    vpmaxsw        m7, m7, m9
    vpaddw         m2, m2, m7
    vpaddw         m2, m2, m13

; V
    vpsubw         m7, m0, m3
    vpsubw         m9, m0, m4
    vpsubw         m10, m0, m5
    vpsubw         m0, m0, m6

    vpaddw         m11, m7, m9
    vpsubw         m12, m7, m9
    vpaddw         m7, m10, m0
    vpsubw         m9, m10, m0
    vpaddw         m10, m11, m7
    vpsubw         m0, m11, m7
    vpaddw         m7, m12, m9
    vpsubw         m11, m12, m9
    vpabsw         m10, m10
    vpabsw         m0, m0
    vpabsw         m7, m7
    vpabsw         m11, m11
    vpblendw       m9, m10, m0, 0AAh
    vpsrld         m10, m10, 16
    vpslld         m0, m0, 16
    vpor           m0, m0, m10
    vpmaxsw        m0, m0, m9
    vpblendw       m9, m7, m11, 0AAh
    vpsrld         m7, m7, 16
    vpslld         m11, m11, 16
    vpor           m7, m7, m11
    vpmaxsw        m7, m7, m9
    vpaddw         m0, m0, m7
    vpaddw         m0, m0, m15

; H
    vpshufd        m7, m1, q0000
    vpmaddubsw     m7, m7, m8
    vpsubw         m3, m7, m3
    vpshufd        m7, m1, q1111
    vpmaddubsw     m7, m7, m8
    vpsubw         m4, m7, m4
    vpshufd        m7, m1, q2222
    vpmaddubsw     m7, m7, m8
    vpsubw         m5, m7, m5
    vpshufd        m7, m1, q3333
    vpmaddubsw     m7, m7, m8
    vpsubw         m6, m7, m6

    vpaddw         m7, m3, m4
    vpsubw         m9, m3, m4
    vpaddw         m3, m5, m6
    vpsubw         m4, m5, m6
    vpaddw         m5, m7, m3
    vpsubw         m6, m7, m3
    vpaddw         m3, m9, m4
    vpsubw         m7, m9, m4
    vpabsw         m5, m5
    vpabsw         m6, m6
    vpabsw         m3, m3
    vpabsw         m7, m7
    vpblendw       m4, m5, m6, 0AAh
    vpsrld         m5, m5, 16
    vpslld         m6, m6, 16
    vpor           m5, m5, m6
    vpmaxsw        m5, m5, m4
    vpblendw       m4, m3, m7, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m7, m7, 16
    vpor           m3, m3, m7
    vpmaxsw        m3, m3, m4
    vpaddw         m3, m3, m5
    vpaddw         m1, m3, m14

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
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vpbroadcastd   xm5, [pw_1]
    vpxor          m3, m3, m3
    vphaddw        m2, m2, m1
    vphaddw        m0, m0, m3
    vphaddw        m0, m2, m0
    vextracti128   xm1, m0, 1
    vpaddw         xm0, xm0, xm1
    vpmaddwd       xm0, xm0, xm5
    vmovdqu        [r2], xm0
    RET    

INIT_YMM avx2
cglobal intra_satd_x3_16x16, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 136
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
    vmovdqu        [rsp + 80], xm13
    vmovdqu        [rsp + 96], xm14
    vmovdqu        [rsp + 112], xm15
%endif
    vmovdqu        m4, [hmul_16p]
    vpbroadcastd   m5, [pw_1]
    vbroadcasti128 m0, [r1 - 32]                 ; V
    lea            r6, [r1 + 383]
    add            r1, 127
    vmovd          xm1, [r1 - 35]
    vpinsrb        xm1, xm1, [r1 - 128], 0
    vpinsrb        xm1, xm1, [r1 - 96], 1
    vpinsrb        xm1, xm1, [r1 - 64], 2
    vpinsrb        xm1, xm1, [r1], 4
    vpinsrb        xm1, xm1, [r1 + 32], 5
    vpinsrb        xm1, xm1, [r1 + 64], 6
    vpinsrb        xm1, xm1, [r1 + 96], 7
    vpinsrb        xm1, xm1, [r6 - 128], 8
    vpinsrb        xm1, xm1, [r6 - 96], 9
    vpinsrb        xm1, xm1, [r6 - 64], 10
    vpinsrb        xm1, xm1, [r6 - 32], 11
    vpinsrb        xm1, xm1, [r6], 12
    vpinsrb        xm1, xm1, [r6 + 32], 13
    vpinsrb        xm1, xm1, [r6 + 64], 14
    vpinsrb        xm1, xm1, [r6 + 96], 15       ; H
    vpxor          xm6, xm6, xm6
    vpsadbw        xm2, xm0, xm6
    vpsadbw        xm3, xm1, xm6
    vpaddw         xm2, xm2, xm3
    vpunpckhqdq    xm3, xm2, xm2
    vpaddw         xm2, xm2, xm3
    vpsrlw         xm2, xm2, 4
    vpavgw         xm2, xm2, xm6
    vpbroadcastb   m2, xm2                       ; DC
    vinserti128    m1, m1, xm1, 1                ; H
    vpmaddubsw     m0, m0, m4                    ; V
    vpmaddubsw     m2, m2, m4                    ; DC

%if WIN64
    sub            rsp, 64
%else
    sub            rsp, 72
%endif
    vpxor          m6, m6, m6
    vmovdqu        [rsp], m6
    vmovdqu        [rsp + 32], m6
    call           .internal
    call           .internal
    call           .internal
    call           .internal
    vmovdqu        m1, [rsp]
    vmovdqu        m2, [rsp + 32]

    vpxor          m3, m3, m3
    vphaddd        m0, m15, m1
    vphaddd        m2, m2, m3
    vphaddd        m0, m0, m2
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vmovdqu        [r2], xm0

%if WIN64
    add            rsp, 64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    vmovdqu        xm12, [rsp + 64]
    vmovdqu        xm13, [rsp + 80]
    vmovdqu        xm14, [rsp + 96]
    vmovdqu        xm15, [rsp + 112]
    add            rsp, 136
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%else
    add            rsp, 72
%endif
    RET

ALIGN 16
.internal:
    vbroadcasti128 m6, [r0]
    vbroadcasti128 m7, [r0 + 16]
    vbroadcasti128 m8, [r0 + 32]
    vbroadcasti128 m9, [r0 + 48]
    add            r0, 64
    vpmaddubsw     m6, m6, m4
    vpmaddubsw     m7, m7, m4
    vpmaddubsw     m8, m8, m4
    vpmaddubsw     m9, m9, m4

; V
    vpsubw         m10, m0, m6
    vpsubw         m11, m0, m7
    vpsubw         m12, m0, m8
    vpsubw         m13, m0, m9

    vpaddw         m3, m10, m11
    vpsubw         m14, m10, m11
    vpaddw         m10, m12, m13
    vpsubw         m11, m12, m13
    vpaddw         m12, m3, m10
    vpsubw         m13, m3, m10
    vpaddw         m3, m14, m11
    vpsubw         m10, m14, m11
    vpabsw         m12, m12
    vpabsw         m13, m13
    vpabsw         m3, m3
    vpabsw         m10, m10
    vpblendw       m11, m12, m13, 0AAh
    vpsrld         m12, m12, 16
    vpslld         m13, m13, 16
    vpor           m12, m12, m13
    vpmaxsw        m14, m11, m12
    vpblendw       m11, m3, m10, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m10, m10, 16
    vpor           m3, m3, m10
    vpmaxsw        m3, m3, m11
    vpaddw         m14, m14, m3
    vpmaddwd       m14, m14, m5
    vpaddd         m15, m15, m14

; H
    vpxor          m14, m14, m14
    vpshufb        m3, m1, m14
    vpmaddubsw     m3, m3, m4
    vpsubw         m10, m3, m6
    vpsrldq        m1, m1, 1
    vpshufb        m3, m1, m14
    vpmaddubsw     m3, m3, m4
    vpsubw         m11, m3, m7
    vpsrldq        m1, m1, 1
    vpshufb        m3, m1, m14
    vpmaddubsw     m3, m3, m4
    vpsubw         m12, m3, m8
    vpsrldq        m1, m1, 1
    vpshufb        m3, m1, m14
    vpmaddubsw     m3, m3, m4
    vpsubw         m13, m3, m9
    vpsrldq        m1, m1, 1

    vpaddw         m3, m10, m11
    vpsubw         m14, m10, m11
    vpaddw         m10, m12, m13
    vpsubw         m11, m12, m13
    vpaddw         m12, m3, m10
    vpsubw         m13, m3, m10
    vpaddw         m3, m14, m11
    vpsubw         m10, m14, m11
    vpabsw         m12, m12
    vpabsw         m13, m13
    vpabsw         m3, m3
    vpabsw         m10, m10
    vpblendw       m11, m12, m13, 0AAh
    vpsrld         m12, m12, 16
    vpslld         m13, m13, 16
    vpor           m12, m12, m13
    vpmaxsw        m14, m11, m12
    vpblendw       m11, m3, m10, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m10, m10, 16
    vpor           m3, m3, m10
    vpmaxsw        m3, m3, m11
    vpaddw         m14, m14, m3
    vpmaddwd       m14, m14, m5
    vpaddd         m14, m14, [rsp + 8]
    vmovdqu        [rsp + 8], m14

; DC
    vpsubw         m10, m2, m6
    vpsubw         m11, m2, m7
    vpsubw         m12, m2, m8
    vpsubw         m13, m2, m9

    vpaddw         m3, m10, m11
    vpsubw         m14, m10, m11
    vpaddw         m10, m12, m13
    vpsubw         m11, m12, m13
    vpaddw         m12, m3, m10
    vpsubw         m13, m3, m10
    vpaddw         m3, m14, m11
    vpsubw         m10, m14, m11
    vpabsw         m12, m12
    vpabsw         m13, m13
    vpabsw         m3, m3
    vpabsw         m10, m10
    vpblendw       m11, m12, m13, 0AAh
    vpsrld         m12, m12, 16
    vpslld         m13, m13, 16
    vpor           m12, m12, m13
    vpmaxsw        m14, m11, m12
    vpblendw       m11, m3, m10, 0AAh
    vpsrld         m3, m3, 16
    vpslld         m10, m10, 16
    vpor           m3, m3, m10
    vpmaxsw        m3, m3, m11
    vpaddw         m14, m14, m3
    vpmaddwd       m14, m14, m5
    vpaddd         m14, m14, [rsp + 40]
    vmovdqu        [rsp + 40], m14
    ret


;=============================================================================
; INTRA SA8D
;=============================================================================
INIT_YMM avx2
cglobal intra_sa8d_x3_8x8, 0, 0
%if WIN64
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 136
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    vmovdqu        [rsp + 64], xm12
    vmovdqu        [rsp + 80], xm13
    vmovdqu        [rsp + 96], xm14
    vmovdqu        [rsp + 112], xm15
%endif
    vpbroadcastq   m0, [r1 + 16]                 ; V
    vpbroadcastq   m1, [r1 + 7]                  ; H
    vmovdqu        m5, [intra_sa8d_8x8_shuf_h]
    vpxor          xm4, xm4, xm4
    vpsadbw        xm2, xm0, xm4
    vpsadbw        xm3, xm1, xm4
    vpaddw         xm2, xm2, xm3
    vpsrlw         xm2, xm2, 3
    vpavgw         xm2, xm2, xm4
    vpbroadcastb   m2, xm2                       ; DC
    vbroadcasti128 m3, [hmul_8p]
    vpmaddubsw     m0, m0, m3                    ; V
    vpmaddubsw     m2, m2, m3                    ; DC
    vpshufb        m11, m1, m5
    vpmaddubsw     m13, m11, m3
    vpsllq         m1, m1, 8
    vpshufb        m11, m1, m5
    vpmaddubsw     m14, m11, m3
    vpsllq         m1, m1, 8
    vpshufb        m11, m1, m5
    vpmaddubsw     m15, m11, m3
    vpsllq         m1, m1, 8
    vpshufb        m11, m1, m5
    vpmaddubsw     m1, m11, m3                   ; H

    vmovddup       xm4, [r0]
    vmovddup       xm5, [r0 + 64]
    vinserti128    m4, m4, xm5, 1
    vpmaddubsw     m4, m4, m3
    vmovddup       xm5, [r0 + 16]
    vmovddup       xm6, [r0 + 80]
    vinserti128    m5, m5, xm6, 1
    vpmaddubsw     m5, m5, m3
    vmovddup       xm6, [r0 + 32]
    vmovddup       xm7, [r0 + 96]
    vinserti128    m6, m6, xm7, 1
    vpmaddubsw     m6, m6, m3
    vmovddup       xm7, [r0 + 48]
    vmovddup       xm8, [r0 + 112]
    vinserti128    m7, m7, xm8, 1
    vpmaddubsw     m7, m7, m3

; V
    vpsubw         m8, m0, m4
    vpsubw         m9, m0, m5
    vpsubw         m10, m0, m6
    vpsubw         m11, m0, m7

    vpaddw         m0, m8, m9
    vpsubw         m12, m8, m9
    vpaddw         m8, m10, m11
    vpsubw         m9, m10, m11
    vpaddw         m10, m0, m8
    vpsubw         m11, m0, m8
    vpaddw         m0, m12, m9
    vpsubw         m8, m12, m9
    vperm2i128     m12, m10, m11, 31h
    vinserti128    m11, m10, xm11, 1
    vpaddw         m10, m12, m11
    vpsubw         m11, m12, m11
    vperm2i128     m12, m0, m8, 31h
    vinserti128    m8, m0, xm8, 1
    vpaddw         m0, m12, m8
    vpsubw         m8, m12, m8
    vshufps        m12, m10, m11, 0DDh
    vshufps        m11, m10, m11, 88h
    vpaddw         m10, m12, m11
    vpsubw         m11, m12, m11
    vshufps        m12, m0, m8, 0DDh
    vshufps        m8, m0, m8, 88h
    vpaddw         m0, m12, m8
    vpsubw         m8, m12, m8

    vpabsw         m10, m10
    vpabsw         m11, m11
    vpabsw         m0, m0
    vpabsw         m8, m8
    vpblendw       m12, m10, m11, 0AAh
    vpsrld         m10, m10, 16
    vpslld         m11, m11, 16
    vpor           m10, m10, m11
    vpmaxsw        m10, m10, m12
    vpblendw       m12, m0, m8, 0AAh
    vpsrld         m0, m0, 16
    vpslld         m8, m8, 16
    vpor           m0, m0, m8
    vpmaxsw        m0, m0, m12
    vpaddw         m0, m0, m10

; H
    vpsubw         m8, m13, m4
    vpsubw         m9, m14, m5
    vpsubw         m10, m15, m6
    vpsubw         m11, m1, m7

    vpaddw         m1, m8, m9
    vpsubw         m12, m8, m9
    vpaddw         m8, m10, m11
    vpsubw         m9, m10, m11
    vpaddw         m10, m1, m8
    vpsubw         m11, m1, m8
    vpaddw         m1, m12, m9
    vpsubw         m8, m12, m9
    vperm2i128     m12, m10, m11, 31h
    vinserti128    m11, m10, xm11, 1
    vpaddw         m10, m12, m11
    vpsubw         m11, m12, m11
    vperm2i128     m12, m1, m8, 31h
    vinserti128    m8, m1, xm8, 1
    vpaddw         m1, m12, m8
    vpsubw         m8, m12, m8
    vshufps        m12, m10, m11, 0DDh
    vshufps        m11, m10, m11, 88h
    vpaddw         m10, m12, m11
    vpsubw         m11, m12, m11
    vshufps        m12, m1, m8, 0DDh
    vshufps        m8, m1, m8, 88h
    vpaddw         m1, m12, m8
    vpsubw         m8, m12, m8

    vpabsw         m10, m10
    vpabsw         m11, m11
    vpabsw         m1, m1
    vpabsw         m8, m8
    vpblendw       m12, m10, m11, 0AAh
    vpsrld         m10, m10, 16
    vpslld         m11, m11, 16
    vpor           m10, m10, m11
    vpmaxsw        m10, m10, m12
    vpblendw       m12, m1, m8, 0AAh
    vpsrld         m1, m1, 16
    vpslld         m8, m8, 16
    vpor           m1, m1, m8
    vpmaxsw        m1, m1, m12
    vpaddw         m1, m1, m10

; DC
    vpsubw         m8, m2, m4
    vpsubw         m9, m2, m5
    vpsubw         m10, m2, m6
    vpsubw         m11, m2, m7

    vpaddw         m2, m8, m9
    vpsubw         m12, m8, m9
    vpaddw         m8, m10, m11
    vpsubw         m9, m10, m11
    vpaddw         m10, m2, m8
    vpsubw         m11, m2, m8
    vpaddw         m2, m12, m9
    vpsubw         m8, m12, m9
    vperm2i128     m12, m10, m11, 31h
    vinserti128    m11, m10, xm11, 1
    vpaddw         m10, m12, m11
    vpsubw         m11, m12, m11
    vperm2i128     m12, m2, m8, 31h
    vinserti128    m8, m2, xm8, 1
    vpaddw         m2, m12, m8
    vpsubw         m8, m12, m8
    vshufps        m12, m10, m11, 0DDh
    vshufps        m11, m10, m11, 88h
    vpaddw         m10, m12, m11
    vpsubw         m11, m12, m11
    vshufps        m12, m2, m8, 0DDh
    vshufps        m8, m2, m8, 88h
    vpaddw         m2, m12, m8
    vpsubw         m8, m12, m8

    vpbroadcastd   m3, [pw_1]
    vpabsw         m10, m10
    vpabsw         m11, m11
    vpabsw         m2, m2
    vpabsw         m8, m8
    vpblendw       m12, m10, m11, 0AAh
    vpsrld         m10, m10, 16
    vpslld         m11, m11, 16
    vpor           m10, m10, m11
    vpmaxsw        m10, m10, m12
    vpblendw       m12, m2, m8, 0AAh
    vpsrld         m2, m2, 16
    vpslld         m8, m8, 16
    vpor           m2, m2, m8
    vpmaxsw        m2, m2, m12
    vpaddw         m2, m2, m10

    vpmaddwd       m0, m0, m3
    vpmaddwd       m1, m1, m3
    vpmaddwd       m2, m2, m3

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
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%endif
    vphaddd        m0, m0, m1
    vpunpckhqdq    m3, m2, m2
    vpaddd         m2, m2, m3
    vphaddd        m0, m0, m2
    vextracti128   xm1, m0, 1
    vpaddd         xm0, xm0, xm1
    vpxor          m3, m3, m3
    vpavgw         xm0, xm0, xm3
    vmovdqu        [r2], xm0
    RET


;=============================================================================
; SSIM
;=============================================================================
INIT_XMM avx2
cglobal pixel_ssim_4x4x2_core, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    vmovdqu        [rsp + 8], m6
%endif
    vpmovzxbw      m2, [r0]
    vpmovzxbw      m3, [r2]
    lea            r6, [r1 + r1 * 2]
    lea            r5, [r3 + r3 * 2]
    vpmaddwd       m4, m2, m2
    vpmaddwd       m6, m3, m3
    vpmaddwd       m5, m2, m3
    vpaddd         m4, m4, m6
    vpmovzxbw      m0, [r0 + r1]
    vpmovzxbw      m1, [r2 + r3]
    vpaddw         m2, m2, m0
    vpaddw         m3, m3, m1
    vpmaddwd       m6, m0, m1
    vpmaddwd       m0, m0, m0
    vpmaddwd       m1, m1, m1
    vpaddd         m5, m5, m6
    vpaddd         m4, m4, m0
    vpaddd         m4, m4, m1
    vpmovzxbw      m0, [r0 + r1 * 2]
    vpmovzxbw      m1, [r2 + r3 * 2]
    vpaddw         m2, m2, m0
    vpaddw         m3, m3, m1
    vpmaddwd       m6, m0, m1
    vpmaddwd       m0, m0, m0
    vpmaddwd       m1, m1, m1
    vpaddd         m5, m5, m6
    vpaddd         m4, m4, m0
    vpaddd         m4, m4, m1
    vpmovzxbw      m0, [r0 + r6]
    vpmovzxbw      m1, [r2 + r5]
    vpaddw         m2, m2, m0
    vpaddw         m3, m3, m1
    vpmaddwd       m6, m0, m1
    vpmaddwd       m0, m0, m0
    vpmaddwd       m1, m1, m1
    vpaddd         m5, m5, m6
    vpaddd         m4, m4, m0
    vpaddd         m4, m4, m1

    vpbroadcastd   m0, [pw_1]
    vphaddw        m2, m2, m3
    vpmaddwd       m2, m2, m0
    vphaddd        m4, m4, m5
    vshufps        m0, m2, m4, 88h
    vshufps        m1, m2, m4, 0DDh
%if WIN64
    vmovdqu        m6, [rsp + 8]
%endif
    vmovdqu        [r4], m0
    vmovdqu        [r4 + 16], m1
    RET

INIT_XMM avx2
cglobal pixel_ssim_end4, 0, 0
    vmovdqu        m0, [r0]
    vmovdqu        m1, [r0 + 16]
    vmovdqu        m2, [r0 + 32]
    vmovdqu        m3, [r0 + 48]
    vmovdqu        m4, [r0 + 64]
    vpaddd         m0, m0, [r1]
    vpaddd         m1, m1, [r1 + 16]
    vpaddd         m2, m2, [r1 + 32]
    vpaddd         m3, m3, [r1 + 48]
    vpaddd         m4, m4, [r1 + 64]
    vpaddd         m0, m0, m1
    vpaddd         m1, m1, m2
    vpaddd         m2, m2, m3
    vpaddd         m3, m3, m4
    vpunpckhdq     m4, m0, m1
    vpunpckldq     m0, m0, m1
    vpunpckhdq     m1, m2, m3
    vpunpckldq     m2, m2, m3
    vpunpckhqdq    m3, m0, m2
    vpunpcklqdq    m0, m0, m2
    vpunpckhqdq    m2, m4, m1
    vpunpcklqdq    m4, m4, m1
    vpmaddwd       m1, m3, m0
    vpslld         m3, m3, 16
    vpor           m0, m0, m3
    vpmaddwd       m0, m0, m0
    vpslld         m1, m1, 1
    vpslld         m2, m2, 7
    vpslld         m4, m4, 6
    vpsubd         m2, m2, m1
    vpsubd         m4, m4, m0
    vpbroadcastd   m3, [ssim_c1]
    vpaddd         m0, m0, m3
    vpaddd         m1, m1, m3
    vpbroadcastd   m3, [ssim_c2]
    vpaddd         m2, m2,m3
    vpaddd         m4, m4, m3
    vcvtdq2ps      m0, m0
    vcvtdq2ps      m1, m1
    vcvtdq2ps      m2, m2
    vcvtdq2ps      m4, m4
    vmulps         m1, m1, m2
    vmulps         m0, m0, m4
    vdivps         m1, m1, m0
    cmp            r2d,4
    je             .skip
    neg            r2
    lea            r3, [mask_ff + 16]
    vandps         m1, m1, [r3 + r2 * 4]
.skip:
    vmovhlps       m0, m0, m1
    vaddps         m0, m0, m1
    vmovshdup      m1, m0
    vaddss         m0, m0, m1
    RET

;=============================================================================
; ASD8
;=============================================================================
INIT_XMM avx2
cglobal pixel_asd8, 0, 0
%if WIN64
    mov            r4d, [rsp + 40]
%endif
    vpxor          m0, m0, m0
    vpxor          m3, m3, m3
    test           r4d, r4d
    jg             .loop
    xor            eax, eax
    ret

ALIGN 16
.loop:
    vmovq          xm1, [r0]
    vpinsrq        xm1, xm1, [r0 + r1], 1
    vmovq          xm2, [r2]
    vpinsrq        xm2, xm2, [r2 + r3], 1
    vpsadbw        m1, m1, m0
    vpsadbw        m2, m2, m0
    vpsubw         m1, m1, m2
    vpaddw         m3, m3, m1
    lea            r0, [r0 + r1 * 2]
    lea            r2, [r2 + r3 * 2]
    sub            r4d, 2
    jg             .loop

.end:
    vpunpckhqdq    xm0, xm3, xm3
    vpaddw         xm0, xm0, xm3
    vpabsw         xm0, xm0
    vmovd          eax, xm0
    ret

;=============================================================================
; Successive Elimination ADS
;=============================================================================
INIT_YMM avx2
cglobal pixel_ads1, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vmovd          xm5, [rsp + 56]
    vpbroadcastw   m5, xm5
    vmovdqu        [rsp + 8], xm6
    mov            [rsp + 24], r7
    mov            [rsp + 32], r8
%else
    vmovd          xm5, [rsp + 8]
    vpbroadcastw   m5, xm5
%endif
    vmovd          xm4, [r0]
    vpbroadcastw   m4, xm4
    vpxor          m2, m2, m2
    xor            r6d, r6d
    lea            r8, [ads_shuf_000]
    vmovdqu        xm6, [pw_76543210]
    vpbroadcastd   xm3, [pw_8]
    jmp            .load

ALIGN 16
.loop:
    mov            r2d, r0d
    and            r0d, 0FFh
    shr            r2d, 8
    popcnt         r7d, r0d
    shl            r0d, 4
    vpshufb        xm1, xm6, [r8 + r0]
    vmovdqu        [r4 + r6 * 2], xm1
    add            r6d, r7d
    vpaddw         xm6, xm6, xm3

    mov            r0d, r2d
    and            r2d, 0FFh
    shr            r0d, 8
    popcnt         r7d, r2d
    shl            r2d, 4
    vpshufb        xm1, xm6, [r8 + r2]
    vmovdqu        [r4 + r6 * 2], xm1
    add            r6d, r7d
    vpaddw         xm6, xm6, xm3

    mov            r2d, r0d
    and            r0d, 0FFh
    shr            r2d, 8
    popcnt         r7d, r0d
    shl            r0d, 4
    vpshufb        xm1, xm6, [r8 + r0]
    vmovdqu        [r4 + r6 * 2], xm1
    add            r6d, r7d
    vpaddw         xm6, xm6, xm3

    popcnt         r7d, r2d
    shl            r2d, 4
    vpshufb        xm1, xm6, [r8 + r2]
    vmovdqu        [r4 + r6 * 2], xm1
    add            r6d, r7d
    vpaddw         xm6, xm6, xm3

ALIGN 16
.load:
    vpsubw         m0, m4, [r1]
    vpsubw         m1, m4, [r1 + 32]
    vpabsw         m0, m0
    vpabsw         m1, m1
    vpaddw         m0, m0, [r3]
    vpaddw         m1, m1, [r3 + 32]
    vpsubw         m0, m5, m0
    vpsubw         m1, m5, m1
    vpcmpgtw       m0, m0, m2
    vpcmpgtw       m1, m1, m2
    vpacksswb      m0, m0, m1                    ; 0 2 1 3
    vpermq         m0, m0, q3120                 ; 0 1 2 3
    vpmovmskb      r0d, m0
    add            r1, 64
    add            r3, 64
    sub            r5d, 32
    jg             .loop

    neg            r5d
    add            r5d, 32
    shlx           r0d, r0d, r5d
    shrx           r0d, r0d, r5d

    mov            r2d, r0d
    and            r0d, 0FFh
    shr            r2d, 8
    popcnt         r7d, r0d
    shl            r0d, 4
    vpshufb        xm1, xm6, [r8 + r0]
    vmovdqu        [r4 + r6 * 2], xm1
    add            r6d, r7d
    vpaddw         xm6, xm6, xm3

    mov            r0d, r2d
    and            r2d, 0FFh
    shr            r0d, 8
    popcnt         r7d, r2d
    shl            r2d, 4
    vpshufb        xm1, xm6, [r8 + r2]
    vmovdqu        [r4 + r6 * 2], xm1
    add            r6d, r7d
    vpaddw         xm6, xm6, xm3

    mov            r2d, r0d
    and            r0d, 0FFh
    shr            r2d, 8
    popcnt         r7d, r0d
    shl            r0d, 4
    vpshufb        xm1, xm6, [r8 + r0]
    vmovdqu        [r4 + r6 * 2], xm1
    add            r6d, r7d
    vpaddw         xm6, xm6, xm3

    popcnt         r7d, r2d
    shl            r2d, 4
    vpshufb        xm1, xm6, [r8 + r2]
    vmovdqu        [r4 + r6 * 2], xm1
    add            r6d, r7d

%if WIN64
    vmovdqu        xm6, [rsp + 8]
    mov            r7, [rsp + 24]
    mov            r8, [rsp + 32]
%endif
    RET

INIT_YMM avx2
cglobal pixel_ads2, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vmovd          xm0, [rsp + 56]
    vpbroadcastw   m0, xm0
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 40
    vmovdqu        [rsp], xm8
    mov            [rsp + 16], r7
    mov            [rsp + 24], r8
    mov            [rsp + 32], r9
%else
    vmovd          xm0, [rsp + 8]
    vpbroadcastw   m0, xm0
    mov            [rsp - 8], r9
%endif
    vmovd          xm1, [r0]
    vpbroadcastw   m1, xm1
    vmovd          xm2, [r0 + 4]
    vpbroadcastw   m2, xm2
    vpxor          m6, m6, m6
    xor            r6d, r6d
    lea            r8, [ads_shuf_000]
    vmovdqu        xm7, [pw_76543210]
    vpbroadcastd   xm8, [pw_8]
    jmp            .load

ALIGN 16
.loop:
    mov            r9d, r0d
    and            r0d, 0FFh
    shr            r9d, 8
    popcnt         r7d, r0d
    shl            r0d, 4
    vpshufb        xm3, xm7, [r8 + r0]
    vmovdqu        [r4 + r6 * 2], xm3
    add            r6d, r7d
    vpaddw         xm7, xm7, xm8

    mov            r0d, r9d
    and            r9d, 0FFh
    shr            r0d, 8
    popcnt         r7d, r9d
    shl            r9d, 4
    vpshufb        xm3, xm7, [r8 + r9]
    vmovdqu        [r4 + r6 * 2], xm3
    add            r6d, r7d
    vpaddw         xm7, xm7, xm8

    mov            r9d, r0d
    and            r0d, 0FFh
    shr            r9d, 8
    popcnt         r7d, r0d
    shl            r0d, 4
    vpshufb        xm3, xm7, [r8 + r0]
    vmovdqu        [r4 + r6 * 2], xm3
    add            r6d, r7d
    vpaddw         xm7, xm7, xm8

    popcnt         r7d, r9d
    shl            r9d, 4
    vpshufb        xm3, xm7, [r8 + r9]
    vmovdqu        [r4 + r6 * 2], xm3
    add            r6d, r7d
    vpaddw         xm7, xm7, xm8

.load:
    vpsubw         m3, m1, [r1]
    vpsubw         m4, m2, [r1 + r2 * 2]
    vpabsw         m3, m3
    vpabsw         m4, m4
    vpaddw         m3, m3, m4
    vpaddw         m3, m3, [r3]
    vpsubw         m3, m0, m3
    vpsubw         m4, m1, [r1 + 32]
    vpsubw         m5, m2, [r1 + r2 * 2 + 32]
    vpabsw         m4, m4
    vpabsw         m5, m5
    vpaddw         m4, m4, m5
    vpaddw         m4, m4, [r3 + 32]
    vpsubw         m4, m0, m4

    vpcmpgtw       m3, m3, m6
    vpcmpgtw       m4, m4, m6
    vpacksswb      m3, m3, m4                    ; 0 2 1 3
    vpermq         m3, m3, q3120                 ; 0 1 2 3
    vpmovmskb      r0d, m3
    add            r1, 64
    add            r3, 64
    sub            r5d, 32
    jg             .loop

    neg            r5d
    add            r5d, 32
    shlx           r0d, r0d, r5d
    shrx           r0d, r0d, r5d

    mov            r9d, r0d
    and            r0d, 0FFh
    shr            r9d, 8
    popcnt         r7d, r0d
    shl            r0d, 4
    vpshufb        xm3, xm7, [r8 + r0]
    vmovdqu        [r4 + r6 * 2], xm3
    add            r6d, r7d
    vpaddw         xm7, xm7, xm8

    mov            r0d, r9d
    and            r9d, 0FFh
    shr            r0d, 8
    popcnt         r7d, r9d
    shl            r9d, 4
    vpshufb        xm3, xm7, [r8 + r9]
    vmovdqu        [r4 + r6 * 2], xm3
    add            r6d, r7d
    vpaddw         xm7, xm7, xm8

    mov            r9d, r0d
    and            r0d, 0FFh
    shr            r9d, 8
    popcnt         r7d, r0d
    shl            r0d, 4
    vpshufb        xm3, xm7, [r8 + r0]
    vmovdqu        [r4 + r6 * 2], xm3
    add            r6d, r7d
    vpaddw         xm7, xm7, xm8

    mov            r0d, r9d
    and            r9d, 0FFh
    shr            r0d, 8
    popcnt         r7d, r9d
    shl            r9d, 4
    vpshufb        xm3, xm7, [r8 + r9]
    vmovdqu        [r4 + r6 * 2], xm3
    add            r6d, r7d

%if WIN64
    vmovdqu        xm8, [rsp]
    mov            r7, [rsp + 16]
    mov            r8, [rsp + 24]
    mov            r9, [rsp + 32]
    add            rsp, 40
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%else
    mov            r9, [rsp - 8]
%endif
    RET

INIT_YMM avx2
cglobal pixel_ads4, 0, 0
%if WIN64
    mov            r4, [rsp + 40]
    mov            r5d, [rsp + 48]
    vmovd          xm0, [rsp + 56]
    vpbroadcastw   m0, xm0
    vmovdqu        [rsp + 8], xm6
    vmovdqu        [rsp + 24], xm7
    sub            rsp, 88
    vmovdqu        [rsp], xm8
    vmovdqu        [rsp + 16], xm9
    vmovdqu        [rsp + 32], xm10
    vmovdqu        [rsp + 48], xm11
    mov            [rsp + 64], r7
    mov            [rsp + 72], r8
    mov            [rsp + 80], r9
%else
    vmovd          xm0, [rsp + 8]
    vpbroadcastw   m0, xm0
    mov            [rsp - 8], r9
%endif
    vmovd          xm1, [r0]
    vpbroadcastw   m1, xm1
    vmovd          xm2, [r0 + 4]
    vpbroadcastw   m2, xm2
    vmovd          xm3, [r0 + 8]
    vpbroadcastw   m3, xm3
    vmovd          xm4, [r0 + 12]
    vpbroadcastw   m4, xm4
    vpxor          m8, m8, m8
    xor            r6d, r6d
    lea            r8, [ads_shuf_000]
    vmovdqu        xm9, [pw_76543210]
    vpbroadcastd   xm10, [pw_8]
    jmp            .load

ALIGN 16
.loop:
    mov            r9d, r0d
    and            r0d, 0FFh
    shr            r9d, 8
    popcnt         r7d, r0d
    shl            r0d, 4
    vpshufb        xm5, xm9, [r8 + r0]
    vmovdqu        [r4 + r6 * 2], xm5
    add            r6d, r7d
    vpaddw         xm9, xm9, xm10

    mov            r0d, r9d
    and            r9d, 0FFh
    shr            r0d, 8
    popcnt         r7d, r9d
    shl            r9d, 4
    vpshufb        xm5, xm9, [r8 + r9]
    vmovdqu        [r4 + r6 * 2], xm5
    add            r6d, r7d
    vpaddw         xm9, xm9, xm10

    mov            r9d, r0d
    and            r0d, 0FFh
    shr            r9d, 8
    popcnt         r7d, r0d
    shl            r0d, 4
    vpshufb        xm5, xm9, [r8 + r0]
    vmovdqu        [r4 + r6 * 2], xm5
    add            r6d, r7d
    vpaddw         xm9, xm9, xm10

    popcnt         r7d, r9d
    shl            r9d, 4
    vpshufb        xm5, xm9, [r8 + r9]
    vmovdqu        [r4 + r6 * 2], xm5
    add            r6d, r7d
    vpaddw         xm9, xm9, xm10

.load:
    vpsubw         m5, m1, [r1]
    vpabsw         m5, m5
    vpsubw         m6, m2, [r1 + 16]
    vpabsw         m6, m6
    vpaddw         m5, m5, m6
    vpsubw         m6, m3, [r1 + r2 * 2]
    vpabsw         m6, m6
    vpaddw         m5, m5, m6
    vpsubw         m6, m4, [r1 + r2 * 2 + 16]
    vpabsw         m6, m6
    vpaddw         m5, m5, m6
    vpaddw         m5, m5, [r3]
    vpsubw         m5, m0, m5

    vpsubw         m6, m1, [r1 + 32]
    vpabsw         m6, m6
    vpsubw         m11, m2, [r1 + 48]
    vpabsw         m11, m11
    vpaddw         m6, m6, m11
    vpsubw         m11, m3, [r1 + r2 * 2 + 32]
    vpabsw         m11, m11
    vpaddw         m6, m6, m11
    vpsubw         m11, m4, [r1 + r2 * 2 + 48]
    vpabsw         m11, m11
    vpaddw         m6, m6, m11
    vpaddw         m6, m6, [r3 + 32]
    vpsubw         m6, m0, m6

    vpcmpgtw       m5, m5, m8
    vpcmpgtw       m6, m6, m8
    vpacksswb      m5, m5, m6                    ; 0 2 1 3
    vpermq         m5, m5, q3120                 ; 0 1 2 3
    vpmovmskb      r0d, m5
    add            r1, 64
    add            r3, 64
    sub            r5d, 32
    jg             .loop

    neg            r5d
    add            r5d, 32
    shlx           r0d, r0d, r5d
    shrx           r0d, r0d, r5d

    mov            r9d, r0d
    and            r0d, 0FFh
    shr            r9d, 8
    popcnt         r7d, r0d
    shl            r0d, 4
    vpshufb        xm5, xm9, [r8 + r0]
    vmovdqu        [r4 + r6 * 2], xm5
    add            r6d, r7d
    vpaddw         xm9, xm9, xm10

    mov            r0d, r9d
    and            r9d, 0FFh
    shr            r0d, 8
    popcnt         r7d, r9d
    shl            r9d, 4
    vpshufb        xm5, xm9, [r8 + r9]
    vmovdqu        [r4 + r6 * 2], xm5
    add            r6d, r7d
    vpaddw         xm9, xm9, xm10

    mov            r9d, r0d
    and            r0d, 0FFh
    shr            r9d, 8
    popcnt         r7d, r0d
    shl            r0d, 4
    vpshufb        xm5, xm9, [r8 + r0]
    vmovdqu        [r4 + r6 * 2], xm5
    add            r6d, r7d
    vpaddw         xm9, xm9, xm10

    mov            r0d, r9d
    and            r9d, 0FFh
    shr            r0d, 8
    popcnt         r7d, r9d
    shl            r9d, 4
    vpshufb        xm5, xm9, [r8 + r9]
    vmovdqu        [r4 + r6 * 2], xm5
    add            r6d, r7d

%if WIN64
    vmovdqu        xm8, [rsp]
    vmovdqu        xm9, [rsp + 16]
    vmovdqu        xm10, [rsp + 32]
    vmovdqu        xm11, [rsp + 48]
    mov            r7, [rsp + 64]
    mov            r8, [rsp + 72]
    mov            r9, [rsp + 80]
    add            rsp, 88
    vmovdqu        xm6, [rsp + 8]
    vmovdqu        xm7, [rsp + 24]
%else
    mov            r9, [rsp - 8]
%endif
    RET
