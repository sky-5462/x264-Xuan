/*****************************************************************************
 * quant.h: x86 quantization and level-run
 *****************************************************************************
 * Copyright (C) 2005-2019 x264 project
 *
 * Authors: Loren Merritt <lorenm@u.washington.edu>
 *          Fiona Glaser <fiona@x264.com>
 *          Christian Heine <sennindemokrit@gmx.net>
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

#ifndef X264_X86_QUANT_H
#define X264_X86_QUANT_H

#define x264_trellis_cabac_4x4_sse2 x264_template(trellis_cabac_4x4_sse2)
int x264_trellis_cabac_4x4_sse2 ( TRELLIS_PARAMS, int b_ac );
#define x264_trellis_cabac_4x4_ssse3 x264_template(trellis_cabac_4x4_ssse3)
int x264_trellis_cabac_4x4_ssse3( TRELLIS_PARAMS, int b_ac );
#define x264_trellis_cabac_8x8_sse2 x264_template(trellis_cabac_8x8_sse2)
int x264_trellis_cabac_8x8_sse2 ( TRELLIS_PARAMS, int b_interlaced );
#define x264_trellis_cabac_8x8_ssse3 x264_template(trellis_cabac_8x8_ssse3)
int x264_trellis_cabac_8x8_ssse3( TRELLIS_PARAMS, int b_interlaced );
#define x264_trellis_cabac_4x4_psy_sse2 x264_template(trellis_cabac_4x4_psy_sse2)
int x264_trellis_cabac_4x4_psy_sse2 ( TRELLIS_PARAMS, int b_ac, dctcoef *fenc_dct, int i_psy_trellis );
#define x264_trellis_cabac_4x4_psy_ssse3 x264_template(trellis_cabac_4x4_psy_ssse3)
int x264_trellis_cabac_4x4_psy_ssse3( TRELLIS_PARAMS, int b_ac, dctcoef *fenc_dct, int i_psy_trellis );
#define x264_trellis_cabac_8x8_psy_sse2 x264_template(trellis_cabac_8x8_psy_sse2)
int x264_trellis_cabac_8x8_psy_sse2 ( TRELLIS_PARAMS, int b_interlaced, dctcoef *fenc_dct, int i_psy_trellis );
#define x264_trellis_cabac_8x8_psy_ssse3 x264_template(trellis_cabac_8x8_psy_ssse3)
int x264_trellis_cabac_8x8_psy_ssse3( TRELLIS_PARAMS, int b_interlaced, dctcoef *fenc_dct, int i_psy_trellis );
#define x264_trellis_cabac_dc_sse2 x264_template(trellis_cabac_dc_sse2)
int x264_trellis_cabac_dc_sse2 ( TRELLIS_PARAMS, int i_coefs );
#define x264_trellis_cabac_dc_ssse3 x264_template(trellis_cabac_dc_ssse3)
int x264_trellis_cabac_dc_ssse3( TRELLIS_PARAMS, int i_coefs );
#define x264_trellis_cabac_chroma_422_dc_sse2 x264_template(trellis_cabac_chroma_422_dc_sse2)
int x264_trellis_cabac_chroma_422_dc_sse2 ( TRELLIS_PARAMS );
#define x264_trellis_cabac_chroma_422_dc_ssse3 x264_template(trellis_cabac_chroma_422_dc_ssse3)
int x264_trellis_cabac_chroma_422_dc_ssse3( TRELLIS_PARAMS );


#define x264_quant_4x4_avx2 x264_template(quant_4x4_avx2)
int x264_quant_4x4_avx2( dctcoef dct[16], udctcoef mf[16], udctcoef bias[16] );
#define x264_quant_8x8_avx2 x264_template(quant_8x8_avx2)
int x264_quant_8x8_avx2( dctcoef dct[64], udctcoef mf[64], udctcoef bias[64] );
#define x264_quant_4x4x4_avx2 x264_template(quant_4x4x4_avx2)
int x264_quant_4x4x4_avx2( dctcoef dct[4][16], udctcoef mf[16], udctcoef bias[16] );
#define x264_quant_2x2_dc_avx2 x264_template(quant_2x2_dc_avx2)
int x264_quant_2x2_dc_avx2( dctcoef dct[4], int mf, int bias );
#define x264_quant_4x4_dc_avx2 x264_template(quant_4x4_dc_avx2)
int x264_quant_4x4_dc_avx2( dctcoef dct[16], int mf, int bias );

#define x264_dequant_4x4_avx2 x264_template(dequant_4x4_avx2)
void x264_dequant_4x4_avx2( int16_t dct[16], int i_qp );
#define x264_dequant_8x8_avx2 x264_template(dequant_8x8_avx2)
void x264_dequant_8x8_avx2( int16_t dct[64], int i_qp );
#define x264_dequant_4x4_dc_avx2 x264_template(dequant_4x4_dc_avx2)
void x264_dequant_4x4_dc_avx2( dctcoef dct[16], int i_qp );

#define x264_idct_dequant_2x4_dc_avx2 x264_template(idct_dequant_2x4_dc_avx2)
void x264_idct_dequant_2x4_dc_avx2 ( dctcoef dct[8], dctcoef dct4x4[8][16], int i_qp );
#define x264_idct_dequant_2x4_dconly_avx2 x264_template(idct_dequant_2x4_dconly_avx2)
void x264_idct_dequant_2x4_dconly_avx2 ( dctcoef dct[8], int i_qp );

#define x264_optimize_chroma_2x2_dc_avx2 x264_template(optimize_chroma_2x2_dc_avx2)
int x264_optimize_chroma_2x2_dc_avx2( dctcoef dct[4], int dequant_mf );
#define x264_optimize_chroma_2x4_dc_avx2 x264_template(optimize_chroma_2x4_dc_avx2)
int x264_optimize_chroma_2x4_dc_avx2( dctcoef dct[8], int dequant_mf );

#define x264_denoise_dct_avx2 x264_template(denoise_dct_avx2)
void x264_denoise_dct_avx2 ( dctcoef *dct, uint32_t *sum, udctcoef *offset, int size );

#define x264_decimate_score15_avx2 x264_template(decimate_score15_avx2)
int x264_decimate_score15_avx2( dctcoef *dct );
#define x264_decimate_score16_avx2 x264_template(decimate_score16_avx2)
int x264_decimate_score16_avx2( dctcoef *dct );
#define x264_decimate_score64_avx2 x264_template(decimate_score64_avx2)
int x264_decimate_score64_avx2( dctcoef *dct );

#define x264_coeff_last4_avx2 x264_template(coeff_last4_avx2)
int x264_coeff_last4_avx2( dctcoef *dct );
#define x264_coeff_last8_avx2 x264_template(coeff_last8_avx2)
int x264_coeff_last8_avx2( dctcoef *dct );
#define x264_coeff_last15_avx2 x264_template(coeff_last15_avx2)
int x264_coeff_last15_avx2( dctcoef *dct );
#define x264_coeff_last16_avx2 x264_template(coeff_last16_avx2)
int x264_coeff_last16_avx2( dctcoef *dct );
#define x264_coeff_last64_avx2 x264_template(coeff_last64_avx2)
int x264_coeff_last64_avx2 ( dctcoef *dct );

#define x264_coeff_level_run4_avx2 x264_template(coeff_level_run4_avx2)
int x264_coeff_level_run4_avx2( dctcoef *dct, x264_run_level_t *runlevel );
#define x264_coeff_level_run8_avx2 x264_template(coeff_level_run8_avx2)
int x264_coeff_level_run8_avx2( dctcoef *dct, x264_run_level_t *runlevel );
#define x264_coeff_level_run15_avx2 x264_template(coeff_level_run15_avx2)
int x264_coeff_level_run15_avx2( dctcoef *dct, x264_run_level_t *runlevel );
#define x264_coeff_level_run16_avx2 x264_template(coeff_level_run16_avx2)
int x264_coeff_level_run16_avx2( dctcoef *dct, x264_run_level_t *runlevel );

#endif
