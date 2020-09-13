/*****************************************************************************
 * quant.c: quantization and level-run
 *****************************************************************************
 * Copyright (C) 2005-2019 x264 project
 *
 * Authors: Loren Merritt <lorenm@u.washington.edu>
 *          Fiona Glaser <fiona@x264.com>
 *          Christian Heine <sennindemokrit@gmx.net>
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

#include "x86/quant.h"

#define INIT_TRELLIS(cpu)\
    pf->trellis_cabac_4x4 = x264_trellis_cabac_4x4_##cpu;\
    pf->trellis_cabac_8x8 = x264_trellis_cabac_8x8_##cpu;\
    pf->trellis_cabac_4x4_psy = x264_trellis_cabac_4x4_psy_##cpu;\
    pf->trellis_cabac_8x8_psy = x264_trellis_cabac_8x8_psy_##cpu;\
    pf->trellis_cabac_dc = x264_trellis_cabac_dc_##cpu;\
    pf->trellis_cabac_chroma_422_dc = x264_trellis_cabac_chroma_422_dc_##cpu;

void x264_quant_init( x264_t *h, x264_quant_function_t *pf )
{
    pf->quant_4x4 = x264_quant_4x4_avx2;
    pf->quant_8x8 = x264_quant_8x8_avx2;
    pf->quant_4x4x4 = x264_quant_4x4x4_avx2;
    pf->quant_2x2_dc = x264_quant_2x2_dc_avx2;
    pf->quant_4x4_dc = x264_quant_4x4_dc_avx2;

    pf->dequant_4x4 = x264_dequant_4x4_avx2;
    pf->dequant_8x8 = x264_dequant_8x8_avx2;
    pf->dequant_4x4_dc = x264_dequant_4x4_dc_avx2;

    pf->idct_dequant_2x4_dc = x264_idct_dequant_2x4_dc_avx2;
    pf->idct_dequant_2x4_dconly = x264_idct_dequant_2x4_dconly_avx2;

    pf->optimize_chroma_2x2_dc = x264_optimize_chroma_2x2_dc_avx2;
    pf->optimize_chroma_2x4_dc =  x264_optimize_chroma_2x4_dc_avx2;
    
    pf->denoise_dct = x264_denoise_dct_avx2;

    pf->decimate_score15 = x264_decimate_score15_avx2;
    pf->decimate_score16 = x264_decimate_score16_avx2;
    pf->decimate_score64 = x264_decimate_score64_avx2;

    pf->coeff_last[DCT_CHROMA_DC] = x264_coeff_last4_avx2;
    pf->coeff_last[DCT_LUMA_AC] = x264_coeff_last15_avx2;
    pf->coeff_last[DCT_LUMA_4x4] = x264_coeff_last16_avx2;
    pf->coeff_last[DCT_LUMA_8x8] = x264_coeff_last64_avx2;

    pf->coeff_level_run[DCT_CHROMA_DC] = x264_coeff_level_run4_avx2;
    pf->coeff_level_run[DCT_LUMA_AC] = x264_coeff_level_run15_avx2;
    pf->coeff_level_run[DCT_LUMA_4x4] = x264_coeff_level_run16_avx2;


    INIT_TRELLIS( ssse3 );
    

    pf->coeff_last[DCT_LUMA_DC]     = pf->coeff_last[DCT_CHROMAU_DC]  = pf->coeff_last[DCT_CHROMAV_DC] =
    pf->coeff_last[DCT_CHROMAU_4x4] = pf->coeff_last[DCT_CHROMAV_4x4] = pf->coeff_last[DCT_LUMA_4x4];
    pf->coeff_last[DCT_CHROMA_AC]   = pf->coeff_last[DCT_CHROMAU_AC]  =
    pf->coeff_last[DCT_CHROMAV_AC]  = pf->coeff_last[DCT_LUMA_AC];
    pf->coeff_last[DCT_CHROMAU_8x8] = pf->coeff_last[DCT_CHROMAV_8x8] = pf->coeff_last[DCT_LUMA_8x8];

    pf->coeff_level_run[DCT_LUMA_DC]     = pf->coeff_level_run[DCT_CHROMAU_DC]  = pf->coeff_level_run[DCT_CHROMAV_DC] =
    pf->coeff_level_run[DCT_CHROMAU_4x4] = pf->coeff_level_run[DCT_CHROMAV_4x4] = pf->coeff_level_run[DCT_LUMA_4x4];
    pf->coeff_level_run[DCT_CHROMA_AC]   = pf->coeff_level_run[DCT_CHROMAU_AC]  =
    pf->coeff_level_run[DCT_CHROMAV_AC]  = pf->coeff_level_run[DCT_LUMA_AC];
}
