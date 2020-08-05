/*****************************************************************************
 * mc.c: motion compensation
 *****************************************************************************
 * Copyright (C) 2003-2019 x264 project
 *
 * Authors: Laurent Aimar <fenrir@via.ecp.fr>
 *          Loren Merritt <lorenm@u.washington.edu>
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

#include "x86/mc.h"

void x264_frame_init_lowres( x264_t *h, x264_frame_t *frame )
{
    pixel *src = frame->plane[0];
    int i_stride = frame->i_stride[0];
    int i_height = frame->i_lines[0];
    int i_width  = frame->i_width[0];

    // duplicate last row and column so that their interpolation doesn't have to be special-cased
    for( int y = 0; y < i_height; y++ )
        src[i_width+y*i_stride] = src[i_width-1+y*i_stride];
    memcpy( src+i_stride*i_height, src+i_stride*(i_height-1), (i_width+1) * sizeof(pixel) );
    h->mc.frame_init_lowres_core( src, frame->lowres[0], frame->lowres[1], frame->lowres[2], frame->lowres[3],
                                  i_stride, frame->i_stride_lowres, frame->i_width_lowres, frame->i_lines_lowres );
    x264_frame_expand_border_lowres( frame );

    memset( frame->i_cost_est, -1, sizeof(frame->i_cost_est) );

    for( int y = 0; y < h->param.i_bframe + 2; y++ )
        for( int x = 0; x < h->param.i_bframe + 2; x++ )
            frame->i_row_satds[y][x][0] = -1;

    for( int y = 0; y <= !!h->param.i_bframe; y++ )
        for( int x = 0; x <= h->param.i_bframe; x++ )
            frame->lowres_mvs[y][x][0][0] = 0x7FFF;
}

void x264_mc_init( x264_mc_functions_t *pf )
{
    x264_mc_init_mmx( pf );
}

void x264_frame_filter( x264_t *h, x264_frame_t *frame, int mb_y, int b_end )
{
    const int b_interlaced = 0;
    int start = mb_y*16 - 8; // buffer = 4 for deblock + 3 for 6tap, rounded to 8
    int height = (b_end ? frame->i_lines[0] : (mb_y+b_interlaced)*16) + 8;

    for( int p = 0; p < (CHROMA444 ? 3 : 1); p++ )
    {
        int stride = frame->i_stride[p];
        const int width = frame->i_width[p];
        int offs = start*stride - 8; // buffer = 3 for 6tap, aligned to 8 for simd

        h->mc.hpel_filter(
            frame->filtered[p][1] + offs,
            frame->filtered[p][2] + offs,
            frame->filtered[p][3] + offs,
            frame->plane[p] + offs,
            stride, width + 16, height - start);
    }

    /* generate integral image:
     * frame->integral contains 2 planes. in the upper plane, each element is
     * the sum of an 8x8 pixel region with top-left corner on that point.
     * in the lower plane, 4x4 sums (needed only with --partitions p4x4). */

    if( frame->integral )
    {
        int stride = frame->i_stride[0];
        if( start < 0 )
        {
            memset( frame->integral - PADV * stride - PADH, 0, stride * sizeof(uint16_t) );
            start = -PADV;
        }
        if( b_end )
            height += PADV-9;
        for( int y = start; y < height; y++ )
        {
            pixel    *pix  = frame->plane[0] + y * stride - PADH;
            uint16_t *sum8 = frame->integral + (y+1) * stride - PADH;
            uint16_t *sum4;
            if( h->frames.b_have_sub8x8_esa )
            {
                h->mc.integral_init4h( sum8, pix, stride );
                sum8 -= 8*stride;
                sum4 = sum8 + stride * (frame->i_lines[0] + PADV*2);
                if( y >= 8-PADV )
                    h->mc.integral_init4v( sum8, sum4, stride );
            }
            else
            {
                h->mc.integral_init8h( sum8, pix, stride );
                if( y >= 8-PADV )
                    h->mc.integral_init8v( sum8-8*stride, stride );
            }
        }
    }
}
