/*****************************************************************************
 * predict-c.c: intra prediction
 *****************************************************************************
 * Copyright (C) 2003-2019 x264 project
 *
 * Authors: Laurent Aimar <fenrir@via.ecp.fr>
 *          Loren Merritt <lorenm@u.washington.edu>
 *          Fiona Glaser <fiona@x264.com>
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

#include "common/common.h"
#include "predict.h"
#include "pixel.h"

static void predict_8x8c_dc_left( uint8_t *src )
{
    int y;
    uint32_t s0 = 0, s1 = 0;
    uint64_t dc0, dc1;

    for( y = 0; y < 4; y++ )
    {
        s0 += src[y * FDEC_STRIDE     - 1];
        s1 += src[(y+4) * FDEC_STRIDE - 1];
    }
    dc0 = (( s0 + 2 ) >> 2) * 0x0101010101010101ULL;
    dc1 = (( s1 + 2 ) >> 2) * 0x0101010101010101ULL;

    for( y = 0; y < 4; y++ )
    {
        M64( src ) = dc0;
        src += FDEC_STRIDE;
    }
    for( y = 0; y < 4; y++ )
    {
        M64( src ) = dc1;
        src += FDEC_STRIDE;
    }
}

static void predict_8x8c_v(uint8_t* src) {
	uint64_t v = M64(src - FDEC_STRIDE);
	for (int y = 0; y < 8; y++) {
		M64(src) = v;
		src += FDEC_STRIDE;
	}
}

static void predict_8x8c_dc_128(uint8_t* src) {
	uint64_t dc = 0x8080808080808080ULL;
	for (int y = 0; y < 8; y++) {
		M64(src) = dc;
		src += FDEC_STRIDE;
	}
}

static void predict_8x16c_v(uint8_t* src) {
	uint64_t v = M64(src - FDEC_STRIDE);
	for (int y = 0; y < 16; y++) {
		M64(src) = v;
		src += FDEC_STRIDE;
	}
}

static void predict_8x16c_dc_left(uint8_t* src) {
	int y;
	uint32_t s0 = 0, s1 = 0, s2 = 0, s3 = 0;
	uint64_t dc0, dc1, dc2, dc3;

	for (y = 0; y < 4; y++) {
		s0 += src[y * FDEC_STRIDE - 1];
		s1 += src[(y + 4) * FDEC_STRIDE - 1];
		s2 += src[(y + 8) * FDEC_STRIDE - 1];
		s3 += src[(y + 12) * FDEC_STRIDE - 1];
	}
	dc0 = ((s0 + 2) >> 2) * 0x0101010101010101ULL;
	dc1 = ((s1 + 2) >> 2) * 0x0101010101010101ULL;
	dc2 = ((s2 + 2) >> 2) * 0x0101010101010101ULL;
	dc3 = ((s3 + 2) >> 2) * 0x0101010101010101ULL;

	for (y = 0; y < 4; y++) {
		M64(src) = dc0;
		src += FDEC_STRIDE;
	}
	for (y = 0; y < 4; y++) {
		M64(src) = dc1;
		src += FDEC_STRIDE;
	}
	for (y = 0; y < 4; y++) {
		M64(src) = dc2;
		src += FDEC_STRIDE;
	}
	for (y = 0; y < 4; y++) {
		M64(src) = dc3;
		src += FDEC_STRIDE;
	}
}

static void predict_8x16c_dc_128(uint8_t* src) {
	uint64_t dc = 0x8080808080808080ULL;
	for (int y = 0; y < 16; y++) {
		M64(src) = dc;
		src += FDEC_STRIDE;
	}
}

static void predict_8x8_v(pixel* src, pixel edge[36]) {
	uint64_t v = M64(edge + 16);
	for (int y = 0; y < 8; y++) {
		M64(src) = v;
		src += FDEC_STRIDE;
	}
}

static void predict_8x8_dc_128(pixel* src, pixel edge[36]) {
	uint64_t dc = 0x8080808080808080ULL;
	for (int y = 0; y < 8; y++) {
		M64(src) = dc;
		src += FDEC_STRIDE;
	}
}

/****************************************************************************
 * Exported functions:
 ****************************************************************************/
void x264_predict_16x16_init_avx2( x264_predict_t pf[7] )
{
    pf[I_PRED_16x16_V] = x264_predict_16x16_v_avx2;
    pf[I_PRED_16x16_H] = x264_predict_16x16_h_avx2;
    pf[I_PRED_16x16_DC] = x264_predict_16x16_dc_avx2;
    pf[I_PRED_16x16_P] = x264_predict_16x16_p_avx2;
    pf[I_PRED_16x16_DC_LEFT] = x264_predict_16x16_dc_left_avx2;
    pf[I_PRED_16x16_DC_TOP] = x264_predict_16x16_dc_top_avx2;
    pf[I_PRED_16x16_DC_128]= x264_predict_16x16_dc_128_avx2;
}

void x264_predict_8x8c_init_avx2( x264_predict_t pf[7] )
{
    pf[I_PRED_CHROMA_V] = predict_8x8c_v;
    pf[I_PRED_CHROMA_H] = x264_predict_8x8c_h_avx2;
    pf[I_PRED_CHROMA_DC] = x264_predict_8x8c_dc_avx2;
    pf[I_PRED_CHROMA_P] = x264_predict_8x8c_p_avx2;
    pf[I_PRED_CHROMA_DC_LEFT] = predict_8x8c_dc_left;
    pf[I_PRED_CHROMA_DC_TOP] = x264_predict_8x8c_dc_top_avx2;
    pf[I_PRED_CHROMA_DC_128]= predict_8x8c_dc_128;
}

void x264_predict_8x16c_init_avx2( x264_predict_t pf[7] )
{
    pf[I_PRED_CHROMA_V] = predict_8x16c_v;
    pf[I_PRED_CHROMA_H] = x264_predict_8x16c_h_avx2;
    pf[I_PRED_CHROMA_DC] = x264_predict_8x16c_dc_avx2;
    pf[I_PRED_CHROMA_P] = x264_predict_8x16c_p_avx2;
    pf[I_PRED_CHROMA_DC_LEFT] = predict_8x16c_dc_left;
    pf[I_PRED_CHROMA_DC_TOP] = x264_predict_8x16c_dc_top_avx2;
    pf[I_PRED_CHROMA_DC_128 ]= predict_8x16c_dc_128;
}

void x264_predict_8x8_init_avx2( x264_predict8x8_t pf[12], x264_predict_8x8_filter_t *predict_8x8_filter )
{
    pf[I_PRED_8x8_V] = predict_8x8_v;
    pf[I_PRED_8x8_H] = x264_predict_8x8_h_avx2;
    pf[I_PRED_8x8_DC] = x264_predict_8x8_dc_avx2;
    pf[I_PRED_8x8_DC_LEFT] = x264_predict_8x8_dc_left_avx2;
    pf[I_PRED_8x8_DC_TOP] = x264_predict_8x8_dc_top_avx2;
    pf[I_PRED_8x8_DC_128] = predict_8x8_dc_128;
    pf[I_PRED_8x8_DDL] = x264_predict_8x8_ddl_avx2;
    pf[I_PRED_8x8_DDR] = x264_predict_8x8_ddr_avx2;
    pf[I_PRED_8x8_VR] = x264_predict_8x8_vr_avx2;
    pf[I_PRED_8x8_HD] = x264_predict_8x8_hd_avx2;
    pf[I_PRED_8x8_VL] = x264_predict_8x8_vl_avx2;
    pf[I_PRED_8x8_HU] = x264_predict_8x8_hu_avx2;
    *predict_8x8_filter = x264_predict_8x8_filter_avx2;
}

void x264_predict_4x4_init_avx2( x264_predict_t pf[12] )
{
    pf[I_PRED_4x4_DC] = x264_predict_4x4_dc_avx2;
    pf[I_PRED_4x4_H] = x264_predict_4x4_h_avx2;
    pf[I_PRED_4x4_DDL] = x264_predict_4x4_ddl_avx2;
    pf[I_PRED_4x4_DDR] = x264_predict_4x4_ddr_avx2;
    pf[I_PRED_4x4_VR] = x264_predict_4x4_vr_avx2;
    pf[I_PRED_4x4_HD] = x264_predict_4x4_hd_avx2;
    pf[I_PRED_4x4_VL] = x264_predict_4x4_vl_avx2;
    pf[I_PRED_4x4_HU] = x264_predict_4x4_hu_avx2;
}
