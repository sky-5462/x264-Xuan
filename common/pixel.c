/*****************************************************************************
 * pixel.c: pixel metrics
 *****************************************************************************
 * Copyright (C) 2003-2019 x264 project
 *
 * Authors: Loren Merritt <lorenm@u.washington.edu>
 *          Laurent Aimar <fenrir@via.ecp.fr>
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

#include "common.h"

#include "x86/pixel.h"

/****************************************************************************
 * pixel_ssd_WxH
 ****************************************************************************/
uint64_t x264_pixel_ssd_wxh( x264_pixel_function_t *pf, pixel *pix1, intptr_t i_pix1,
                             pixel *pix2, intptr_t i_pix2, int i_width, int i_height )
{
    uint64_t i_ssd = 0;
    int y;
    int align = !(((intptr_t)pix1 | (intptr_t)pix2 | i_pix1 | i_pix2) & 15);

#define SSD(size) i_ssd += pf->ssd[size]( pix1 + y*i_pix1 + x, i_pix1, \
                                          pix2 + y*i_pix2 + x, i_pix2 );
    for( y = 0; y < i_height-15; y += 16 )
    {
        int x = 0;
        if( align )
            for( ; x < i_width-15; x += 16 )
                SSD(PIXEL_16x16);
        for( ; x < i_width-7; x += 8 )
            SSD(PIXEL_8x16);
    }
    if( y < i_height-7 )
        for( int x = 0; x < i_width-7; x += 8 )
            SSD(PIXEL_8x8);
#undef SSD

#define SSD1 { int d = pix1[y*i_pix1+x] - pix2[y*i_pix2+x]; i_ssd += d*d; }
    if( i_width & 7 )
    {
        for( y = 0; y < (i_height & ~7); y++ )
            for( int x = i_width & ~7; x < i_width; x++ )
                SSD1;
    }
    if( i_height & 7 )
    {
        for( y = i_height & ~7; y < i_height; y++ )
            for( int x = 0; x < i_width; x++ )
                SSD1;
    }
#undef SSD1

    return i_ssd;
}

static void pixel_ssd_nv12_core( pixel *pixuv1, intptr_t stride1, pixel *pixuv2, intptr_t stride2,
                                 int width, int height, uint64_t *ssd_u, uint64_t *ssd_v )
{
    *ssd_u = 0, *ssd_v = 0;
    for( int y = 0; y < height; y++, pixuv1+=stride1, pixuv2+=stride2 )
        for( int x = 0; x < width; x++ )
        {
            int du = pixuv1[2*x]   - pixuv2[2*x];
            int dv = pixuv1[2*x+1] - pixuv2[2*x+1];
            *ssd_u += du*du;
            *ssd_v += dv*dv;
        }
}

void x264_pixel_ssd_nv12( x264_pixel_function_t *pf, pixel *pix1, intptr_t i_pix1, pixel *pix2, intptr_t i_pix2,
                          int i_width, int i_height, uint64_t *ssd_u, uint64_t *ssd_v )
{
    pf->ssd_nv12_core( pix1, i_pix1, pix2, i_pix2, i_width&~7, i_height, ssd_u, ssd_v );
    if( i_width&7 )
    {
        uint64_t tmp[2];
        pixel_ssd_nv12_core( pix1+(i_width&~7), i_pix1, pix2+(i_width&~7), i_pix2, i_width&7, i_height, &tmp[0], &tmp[1] );
        *ssd_u += tmp[0];
        *ssd_v += tmp[1];
    }
}


/****************************************************************************
 * structural similarity metric
 ****************************************************************************/
float x264_pixel_ssim_wxh( x264_pixel_function_t *pf,
                           pixel *pix1, intptr_t stride1,
                           pixel *pix2, intptr_t stride2,
                           int width, int height, void *buf, int *cnt )
{
    int z = 0;
    float ssim = 0.0;
    int (*sum0)[4] = buf;
    int (*sum1)[4] = sum0 + (width >> 2) + 3;
    width >>= 2;
    height >>= 2;
    for( int y = 1; y < height; y++ )
    {
        for( ; z <= y; z++ )
        {
            XCHG( void*, sum0, sum1 );
            for( int x = 0; x < width; x+=2 )
                pf->ssim_4x4x2_core( &pix1[4*(x+z*stride1)], stride1, &pix2[4*(x+z*stride2)], stride2, &sum0[x] );
        }
        for( int x = 0; x < width-1; x += 4 )
            ssim += pf->ssim_end4( sum0+x, sum1+x, X264_MIN(4,width-x-1) );
    }
    *cnt = (height-1) * (width-1);
    return ssim;
}

/****************************************************************************
 * x264_pixel_init:
 ****************************************************************************/
void x264_pixel_init( x264_pixel_function_t *pixf )
{
    memset( pixf, 0, sizeof(*pixf) );

    pixf->sad[PIXEL_4x4] = x264_pixel_sad_4x4_avx2;
    pixf->sad[PIXEL_4x8] = x264_pixel_sad_4x8_avx2;
    pixf->sad[PIXEL_4x16] = x264_pixel_sad_4x16_avx2;
    pixf->sad[PIXEL_8x4] = x264_pixel_sad_8x4_avx2;
    pixf->sad[PIXEL_8x8] = x264_pixel_sad_8x8_avx2;
    pixf->sad[PIXEL_8x16] = x264_pixel_sad_8x16_avx2;
    pixf->sad[PIXEL_16x8] = x264_pixel_sad_16x8_avx2;
    pixf->sad[PIXEL_16x16] = x264_pixel_sad_16x16_avx2;

    pixf->ssd[PIXEL_4x4] = x264_pixel_ssd_4x4_avx2;
    pixf->ssd[PIXEL_4x8] = x264_pixel_ssd_4x8_avx2;
    pixf->ssd[PIXEL_4x16] = x264_pixel_ssd_4x16_avx2;
    pixf->ssd[PIXEL_8x4] = x264_pixel_ssd_8x4_avx2;
    pixf->ssd[PIXEL_8x8] = x264_pixel_ssd_8x8_avx2;
    pixf->ssd[PIXEL_8x16] = x264_pixel_ssd_8x16_avx2;
    pixf->ssd[PIXEL_16x8] = x264_pixel_ssd_16x8_avx2;
    pixf->ssd[PIXEL_16x16] = x264_pixel_ssd_16x16_avx2;

    pixf->satd[PIXEL_4x4] = x264_pixel_satd_4x4_avx2;
    pixf->satd[PIXEL_4x8] = x264_pixel_satd_4x8_avx2;
    pixf->satd[PIXEL_4x16] = x264_pixel_satd_4x16_avx2;
    pixf->satd[PIXEL_8x4] = x264_pixel_satd_8x4_avx2;
    pixf->satd[PIXEL_8x8] = x264_pixel_satd_8x8_avx2;
    pixf->satd[PIXEL_8x16] = x264_pixel_satd_8x16_avx2;
    pixf->satd[PIXEL_16x8] = x264_pixel_satd_16x8_avx2;
    pixf->satd[PIXEL_16x16] = x264_pixel_satd_16x16_avx2;

    pixf->sa8d[PIXEL_8x8] = x264_pixel_sa8d_8x8_avx2;
    pixf->sa8d[PIXEL_16x16] = x264_pixel_sa8d_16x16_avx2;
    pixf->sa8d_satd[PIXEL_16x16] = x264_pixel_sa8d_satd_16x16_avx2;

    pixf->sad_x3[PIXEL_4x4] = x264_pixel_sad_x3_4x4_avx2;
    pixf->sad_x3[PIXEL_4x8] = x264_pixel_sad_x3_4x8_avx2;
    pixf->sad_x3[PIXEL_8x4] = x264_pixel_sad_x3_8x4_avx2;
    pixf->sad_x3[PIXEL_8x8] = x264_pixel_sad_x3_8x8_avx2;
    pixf->sad_x3[PIXEL_8x16] = x264_pixel_sad_x3_8x16_avx2;
    pixf->sad_x3[PIXEL_16x8] = x264_pixel_sad_x3_16x8_avx2;
    pixf->sad_x3[PIXEL_16x16] = x264_pixel_sad_x3_16x16_avx2;

    pixf->sad_x4[PIXEL_4x4] = x264_pixel_sad_x4_4x4_avx2;
    pixf->sad_x4[PIXEL_4x8] = x264_pixel_sad_x4_4x8_avx2;
    pixf->sad_x4[PIXEL_8x4] = x264_pixel_sad_x4_8x4_avx2;
    pixf->sad_x4[PIXEL_8x8] = x264_pixel_sad_x4_8x8_avx2;
    pixf->sad_x4[PIXEL_8x16] = x264_pixel_sad_x4_8x16_avx2;
    pixf->sad_x4[PIXEL_16x8] = x264_pixel_sad_x4_16x8_avx2;
    pixf->sad_x4[PIXEL_16x16] = x264_pixel_sad_x4_16x16_avx2;

    pixf->satd_x3[PIXEL_4x4] = x264_pixel_satd_x3_4x4_avx2;
    pixf->satd_x3[PIXEL_4x8] = x264_pixel_satd_x3_4x8_avx2;
    pixf->satd_x3[PIXEL_8x4] = x264_pixel_satd_x3_8x4_avx2;
    pixf->satd_x3[PIXEL_8x8] = x264_pixel_satd_x3_8x8_avx2;
    pixf->satd_x3[PIXEL_8x16] = x264_pixel_satd_x3_8x16_avx2;
    pixf->satd_x3[PIXEL_16x8] = x264_pixel_satd_x3_16x8_avx2;
    pixf->satd_x3[PIXEL_16x16] = x264_pixel_satd_x3_16x16_avx2;

    pixf->satd_x4[PIXEL_4x4] = x264_pixel_satd_x4_4x4_avx2;
    pixf->satd_x4[PIXEL_4x8] = x264_pixel_satd_x4_4x8_avx2;
    pixf->satd_x4[PIXEL_8x4] = x264_pixel_satd_x4_8x4_avx2;
    pixf->satd_x4[PIXEL_8x8] = x264_pixel_satd_x4_8x8_avx2;
    pixf->satd_x4[PIXEL_8x16] = x264_pixel_satd_x4_8x16_avx2;
    pixf->satd_x4[PIXEL_16x8] = x264_pixel_satd_x4_16x8_avx2;
    pixf->satd_x4[PIXEL_16x16] = x264_pixel_satd_x4_16x16_avx2;

    pixf->var[PIXEL_8x8] = x264_pixel_var_8x8_avx2;
    pixf->var[PIXEL_8x16] = x264_pixel_var_8x16_avx2;
    pixf->var[PIXEL_16x16] = x264_pixel_var_16x16_avx2;
    pixf->var2[PIXEL_8x8] = x264_pixel_var2_8x8_avx2;
    pixf->var2[PIXEL_8x16] = x264_pixel_var2_8x16_avx2;

    pixf->hadamard_ac[PIXEL_8x8] = x264_pixel_hadamard_ac_8x8_avx2;
    pixf->hadamard_ac[PIXEL_8x16] = x264_pixel_hadamard_ac_8x16_avx2;
    pixf->hadamard_ac[PIXEL_16x8] = x264_pixel_hadamard_ac_16x8_avx2;
    pixf->hadamard_ac[PIXEL_16x16] = x264_pixel_hadamard_ac_16x16_avx2;

    pixf->asd8 = x264_pixel_asd8_avx2;

    pixf->intra_sad_x3_4x4 = x264_intra_sad_x3_4x4_avx2;
    pixf->intra_sad_x3_8x8c = x264_intra_sad_x3_8x8c_avx2;
    pixf->intra_sad_x3_8x8 = x264_intra_sad_x3_8x8_avx2;
    pixf->intra_sad_x3_8x16c = x264_intra_sad_x3_8x16c_avx2;
    pixf->intra_sad_x3_16x16 = x264_intra_sad_x3_16x16_avx2;

    pixf->intra_satd_x3_4x4   = x264_intra_satd_x3_4x4_avx2;
    pixf->intra_satd_x3_8x8c  = x264_intra_satd_x3_8x8c_avx2;
    pixf->intra_satd_x3_8x16c = x264_intra_satd_x3_8x16c_avx2;
    pixf->intra_satd_x3_16x16 = x264_intra_satd_x3_16x16_avx2;
    pixf->intra_sa8d_x3_8x8 = x264_intra_sa8d_x3_8x8_avx2;

    pixf->intra_sad_x9_4x4  = x264_intra_sad_x9_4x4_avx2;
    pixf->intra_sad_x9_8x8  = x264_intra_sad_x9_8x8_avx2;

    pixf->intra_satd_x9_4x4 = x264_intra_satd_x9_4x4_avx2;
    pixf->intra_sa8d_x9_8x8 = x264_intra_sa8d_x9_8x8_avx2;

    pixf->ssd_nv12_core = x264_pixel_ssd_nv12_core_avx2;

    pixf->ssim_4x4x2_core  = x264_pixel_ssim_4x4x2_core_avx2;
    pixf->ssim_end4        = x264_pixel_ssim_end4_avx2;

    pixf->ads[PIXEL_16x16] = x264_pixel_ads4_avx2;
    pixf->ads[PIXEL_16x8] = x264_pixel_ads2_avx2;
    pixf->ads[PIXEL_8x8] = x264_pixel_ads1_avx2;
    pixf->ads[PIXEL_8x16] =
    pixf->ads[PIXEL_8x4] =
    pixf->ads[PIXEL_4x8] = pixf->ads[PIXEL_16x8];
    pixf->ads[PIXEL_4x4] = pixf->ads[PIXEL_8x8];
}

