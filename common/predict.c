/*****************************************************************************
 * predict.c: intra prediction
 *****************************************************************************
 * Copyright (C) 2003-2019 x264 project
 *
 * Authors: Laurent Aimar <fenrir@via.ecp.fr>
 *          Loren Merritt <lorenm@u.washington.edu>
 *          Fiona Glaser <fiona@x264.com>
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

/* predict4x4 are inspired from ffmpeg h264 decoder */


#include "common.h"

#include "x86/predict.h"

/****************************************************************************
 * 4x4 prediction for intra luma block
 ****************************************************************************/

#define SRC(x,y) src[(x)+(y)*FDEC_STRIDE]
#define SRC_X4(x,y) MPIXEL_X4( &SRC(x,y) )

#define PREDICT_4x4_DC(v)\
    SRC_X4(0,0) = SRC_X4(0,1) = SRC_X4(0,2) = SRC_X4(0,3) = v;

static void predict_4x4_dc_128_c( pixel *src )
{
    PREDICT_4x4_DC( PIXEL_SPLAT_X4( 1 << (BIT_DEPTH-1) ) );
}
static void predict_4x4_dc_left_c( pixel *src )
{
    pixel4 dc = PIXEL_SPLAT_X4( (SRC(-1,0) + SRC(-1,1) + SRC(-1,2) + SRC(-1,3) + 2) >> 2 );
    PREDICT_4x4_DC( dc );
}
static void predict_4x4_dc_top_c( pixel *src )
{
    pixel4 dc = PIXEL_SPLAT_X4( (SRC(0,-1) + SRC(1,-1) + SRC(2,-1) + SRC(3,-1) + 2) >> 2 );
    PREDICT_4x4_DC( dc );
}
void x264_predict_4x4_v_c( pixel *src )
{
    PREDICT_4x4_DC(SRC_X4(0,-1));
}

/****************************************************************************
 * Exported functions:
 ****************************************************************************/
void x264_predict_16x16_init( x264_predict_t pf[7] )
{
    x264_predict_16x16_init_mmx( pf );
}

void x264_predict_8x8c_init( x264_predict_t pf[7] )
{
    x264_predict_8x8c_init_mmx( pf );
}

void x264_predict_8x16c_init( x264_predict_t pf[7] )
{
    x264_predict_8x16c_init_mmx( pf );
}

void x264_predict_8x8_init( x264_predict8x8_t pf[12], x264_predict_8x8_filter_t *predict_filter )
{
    x264_predict_8x8_init_mmx( pf, predict_filter );
}

void x264_predict_4x4_init( x264_predict_t pf[12] )
{
    pf[I_PRED_4x4_V]      = x264_predict_4x4_v_c;
    pf[I_PRED_4x4_DC_LEFT]= predict_4x4_dc_left_c;
    pf[I_PRED_4x4_DC_TOP] = predict_4x4_dc_top_c;
    pf[I_PRED_4x4_DC_128] = predict_4x4_dc_128_c;
    x264_predict_4x4_init_mmx( pf );
}

