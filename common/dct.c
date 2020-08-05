/*****************************************************************************
 * dct.c: transform and zigzag
 *****************************************************************************
 * Copyright (C) 2003-2019 x264 project
 *
 * Authors: Loren Merritt <lorenm@u.washington.edu>
 *          Laurent Aimar <fenrir@via.ecp.fr>
 *          Henrik Gramner <henrik@gramner.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02111, USA.
 *
 * This program is also available under a commercial proprietary license.
 * For more information, contact us at licensing@x264.com.
 *****************************************************************************/

#include "common.h"
#include "x86/dct.h"

/****************************************************************************
 * x264_dct_init:
 ****************************************************************************/
void x264_dct_init( x264_dct_function_t *dctf )
{
    dctf->sub4x4_dct = x264_sub4x4_dct_avx2;
    dctf->sub8x8_dct = x264_sub8x8_dct_avx2;
    dctf->sub8x8_dct_dc = x264_sub8x8_dct_dc_avx2;
    dctf->sub8x16_dct_dc = x264_sub8x16_dct_dc_avx2;
    dctf->sub16x16_dct = x264_sub16x16_dct_avx2;
    dctf->sub8x8_dct8 = x264_sub8x8_dct8_avx2;
    dctf->sub16x16_dct8 = x264_sub16x16_dct8_avx2;
    
    dctf->add4x4_idct = x264_add4x4_idct_avx2;
    dctf->add8x8_idct = x264_add8x8_idct_avx2;
    dctf->add16x16_idct = x264_add16x16_idct_avx2;
    dctf->add8x8_idct_dc = x264_add8x8_idct_dc_avx2;
    dctf->add16x16_idct_dc = x264_add16x16_idct_dc_avx2;
    dctf->add8x8_idct8 = x264_add8x8_idct8_avx2;

    dctf->dct4x4dc = x264_dct4x4dc_avx2;
    dctf->idct4x4dc = x264_idct4x4dc_avx2;
    dctf->dct2x4dc = x264_dct2x4dc_avx2;
}

void x264_zigzag_init( x264_zigzag_function_t *pf_progressive )
{
    pf_progressive->interleave_8x8_cavlc = x264_zigzag_interleave_8x8_cavlc_avx2;
    pf_progressive->scan_8x8 = x264_zigzag_scan_8x8_frame_avx2;
    pf_progressive->scan_4x4 = x264_zigzag_scan_4x4_frame_avx2;
    pf_progressive->sub_4x4 = x264_zigzag_sub_4x4_frame_avx2;
    pf_progressive->sub_8x8 = x264_zigzag_sub_8x8_frame_avx2;
    pf_progressive->sub_4x4ac = x264_zigzag_sub_4x4ac_frame_avx2;
}
