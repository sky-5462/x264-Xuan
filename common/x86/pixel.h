/*****************************************************************************
 * pixel.h: x86 pixel metrics
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

#ifndef X264_X86_PIXEL_H
#define X264_X86_PIXEL_H

#define x264_pixel_ads1_avx2 x264_template(pixel_ads1_avx2)
#define x264_pixel_ads2_avx2 x264_template(pixel_ads2_avx2)
#define x264_pixel_ads4_avx2 x264_template(pixel_ads4_avx2)
#define x264_pixel_hadamard_ac_16x16_avx2 x264_template(pixel_hadamard_ac_16x16_avx2)
#define x264_pixel_hadamard_ac_16x8_avx2 x264_template(pixel_hadamard_ac_16x8_avx2)
#define x264_pixel_hadamard_ac_8x16_avx2 x264_template(pixel_hadamard_ac_8x16_avx2)
#define x264_pixel_hadamard_ac_8x8_avx2 x264_template(pixel_hadamard_ac_8x8_avx2)
#define x264_pixel_sa8d_16x16_avx2 x264_template(pixel_sa8d_16x16_avx2)
#define x264_pixel_sa8d_8x8_avx2 x264_template(pixel_sa8d_8x8_avx2)
#define x264_pixel_sad_16x16_avx2 x264_template(pixel_sad_16x16_avx2)
#define x264_pixel_sad_16x8_avx2 x264_template(pixel_sad_16x8_avx2)
#define x264_pixel_sad_4x16_avx2 x264_template(pixel_sad_4x16_avx2)
#define x264_pixel_sad_4x4_avx2 x264_template(pixel_sad_4x4_avx2)
#define x264_pixel_sad_4x8_avx2 x264_template(pixel_sad_4x8_avx2)
#define x264_pixel_sad_8x16_avx2 x264_template(pixel_sad_8x16_avx2)
#define x264_pixel_sad_8x4_avx2 x264_template(pixel_sad_8x4_avx2)
#define x264_pixel_sad_8x8_avx2 x264_template(pixel_sad_8x8_avx2)
#define x264_pixel_sad_x3_16x16_avx2 x264_template(pixel_sad_x3_16x16_avx2)
#define x264_pixel_sad_x3_16x8_avx2 x264_template(pixel_sad_x3_16x8_avx2)
#define x264_pixel_sad_x3_4x4_avx2 x264_template(pixel_sad_x3_4x4_avx2)
#define x264_pixel_sad_x3_4x8_avx2 x264_template(pixel_sad_x3_4x8_avx2)
#define x264_pixel_sad_x3_8x16_avx2 x264_template(pixel_sad_x3_8x16_avx2)
#define x264_pixel_sad_x3_8x4_avx2 x264_template(pixel_sad_x3_8x4_avx2)
#define x264_pixel_sad_x3_8x8_avx2 x264_template(pixel_sad_x3_8x8_avx2)
#define x264_pixel_sad_x4_16x16_avx2 x264_template(pixel_sad_x4_16x16_avx2)
#define x264_pixel_sad_x4_16x8_avx2 x264_template(pixel_sad_x4_16x8_avx2)
#define x264_pixel_sad_x4_4x4_avx2 x264_template(pixel_sad_x4_4x4_avx2)
#define x264_pixel_sad_x4_4x8_avx2 x264_template(pixel_sad_x4_4x8_avx2)
#define x264_pixel_sad_x4_8x16_avx2 x264_template(pixel_sad_x4_8x16_avx2)
#define x264_pixel_sad_x4_8x4_avx2 x264_template(pixel_sad_x4_8x4_avx2)
#define x264_pixel_sad_x4_8x8_avx2 x264_template(pixel_sad_x4_8x8_avx2)
#define x264_pixel_satd_16x16_avx2 x264_template(pixel_satd_16x16_avx2)
#define x264_pixel_satd_16x8_avx2 x264_template(pixel_satd_16x8_avx2)
#define x264_pixel_satd_4x16_avx2 x264_template(pixel_satd_4x16_avx2)
#define x264_pixel_satd_4x4_avx x264_template(pixel_satd_4x4_avx)
#define x264_pixel_satd_4x4_avx2 x264_template(pixel_satd_4x4_avx2)
#define x264_pixel_satd_4x8_avx x264_template(pixel_satd_4x8_avx)
#define x264_pixel_satd_4x8_avx2 x264_template(pixel_satd_4x8_avx2)
#define x264_pixel_satd_8x16_avx2 x264_template(pixel_satd_8x16_avx2)
#define x264_pixel_satd_8x4_avx2 x264_template(pixel_satd_8x4_avx2)
#define x264_pixel_satd_8x8_avx2 x264_template(pixel_satd_8x8_avx2)
#define x264_pixel_satd_x3_16x16_avx2 x264_template(pixel_satd_x3_16x16_avx2)
#define x264_pixel_satd_x3_16x8_avx2 x264_template(pixel_satd_x3_16x8_avx2)
#define x264_pixel_satd_x3_4x4_avx2 x264_template(pixel_satd_x3_4x4_avx2)
#define x264_pixel_satd_x3_4x8_avx2 x264_template(pixel_satd_x3_4x8_avx2)
#define x264_pixel_satd_x3_8x16_avx2 x264_template(pixel_satd_x3_8x16_avx2)
#define x264_pixel_satd_x3_8x4_avx2 x264_template(pixel_satd_x3_8x4_avx2)
#define x264_pixel_satd_x3_8x8_avx2 x264_template(pixel_satd_x3_8x8_avx2)
#define x264_pixel_satd_x4_16x16_avx2 x264_template(pixel_satd_x4_16x16_avx2)
#define x264_pixel_satd_x4_16x8_avx2 x264_template(pixel_satd_x4_16x8_avx2)
#define x264_pixel_satd_x4_4x4_avx2 x264_template(pixel_satd_x4_4x4_avx2)
#define x264_pixel_satd_x4_4x8_avx2 x264_template(pixel_satd_x4_4x8_avx2)
#define x264_pixel_satd_x4_8x16_avx2 x264_template(pixel_satd_x4_8x16_avx2)
#define x264_pixel_satd_x4_8x4_avx2 x264_template(pixel_satd_x4_8x4_avx2)
#define x264_pixel_satd_x4_8x8_avx2 x264_template(pixel_satd_x4_8x8_avx2)
#define x264_pixel_ssd_16x16_avx2 x264_template(pixel_ssd_16x16_avx2)
#define x264_pixel_ssd_16x8_avx2 x264_template(pixel_ssd_16x8_avx2)
#define x264_pixel_ssd_4x16_avx2 x264_template(pixel_ssd_4x16_avx2)
#define x264_pixel_ssd_4x4_avx2 x264_template(pixel_ssd_4x4_avx2)
#define x264_pixel_ssd_4x8_avx2 x264_template(pixel_ssd_4x8_avx2)
#define x264_pixel_ssd_8x16_avx2 x264_template(pixel_ssd_8x16_avx2)
#define x264_pixel_ssd_8x4_avx2 x264_template(pixel_ssd_8x4_avx2)
#define x264_pixel_ssd_8x8_avx2 x264_template(pixel_ssd_8x8_avx2)
#define x264_pixel_var_16x16_avx2 x264_template(pixel_var_16x16_avx2)
#define x264_pixel_var_8x16_avx2 x264_template(pixel_var_8x16_avx2)
#define x264_pixel_var_8x8_avx2 x264_template(pixel_var_8x8_avx2)
#define DECL_PIXELS( ret, name, suffix, args ) \
    ret x264_pixel_##name##_16x16_##suffix args;\
    ret x264_pixel_##name##_16x8_##suffix args;\
    ret x264_pixel_##name##_8x16_##suffix args;\
    ret x264_pixel_##name##_8x8_##suffix args;\
    ret x264_pixel_##name##_8x4_##suffix args;\
    ret x264_pixel_##name##_4x16_##suffix args;\
    ret x264_pixel_##name##_4x8_##suffix args;\
    ret x264_pixel_##name##_4x4_##suffix args;\

#define DECL_X1( name, suffix ) \
    DECL_PIXELS( int, name, suffix, ( pixel *, intptr_t, pixel *, intptr_t ) )

#define DECL_X4( name, suffix ) \
    DECL_PIXELS( void, name##_x3, suffix, ( pixel *, pixel *, pixel *, pixel *, intptr_t, int * ) )\
    DECL_PIXELS( void, name##_x4, suffix, ( pixel *, pixel *, pixel *, pixel *, pixel *, intptr_t, int * ) )

DECL_X1( sad, avx2 )
DECL_X4( sad, avx2 )
DECL_X1( ssd, avx2 )
DECL_X1( satd, avx2 )
DECL_X4( satd, avx2 )
DECL_X1( sa8d, avx2 )

DECL_PIXELS( uint64_t, var, avx2,   ( pixel *pix, intptr_t i_stride ))
DECL_PIXELS( uint64_t, hadamard_ac, avx2,  ( pixel *pix, intptr_t i_stride ))


#define x264_intra_satd_x3_4x4_avx2 x264_template(intra_satd_x3_4x4_avx2)
void x264_intra_satd_x3_4x4_avx2   ( pixel   *, pixel   *, int * );
#define x264_intra_sad_x3_4x4_avx2 x264_template(intra_sad_x3_4x4_avx2)
void x264_intra_sad_x3_4x4_avx2    ( uint8_t *, uint8_t *, int * );
#define x264_intra_satd_x3_8x8c_avx2 x264_template(intra_satd_x3_8x8c_avx2)
void x264_intra_satd_x3_8x8c_avx2  ( pixel   *, pixel   *, int * );
#define x264_intra_sad_x3_8x8c_avx2 x264_template(intra_sad_x3_8x8c_avx2)
void x264_intra_sad_x3_8x8c_avx2   ( uint8_t *, uint8_t *, int * );
#define x264_intra_satd_x3_8x16c_avx2 x264_template(intra_satd_x3_8x16c_avx2)
void x264_intra_satd_x3_8x16c_avx2   ( uint8_t *, uint8_t *, int * );
#define x264_intra_sad_x3_8x16c_avx2 x264_template(intra_sad_x3_8x16c_avx2)
void x264_intra_sad_x3_8x16c_avx2   ( uint8_t *, uint8_t *, int * );
#define x264_intra_satd_x3_16x16_avx2 x264_template(intra_satd_x3_16x16_avx2)
void x264_intra_satd_x3_16x16_avx2 ( pixel   *, pixel   *, int * );
#define x264_intra_sad_x3_16x16_avx2 x264_template(intra_sad_x3_16x16_avx2)
void x264_intra_sad_x3_16x16_avx2  ( uint8_t *, uint8_t *, int * );
#define x264_intra_sa8d_x3_8x8_avx2 x264_template(intra_sa8d_x3_8x8_avx2)
void x264_intra_sa8d_x3_8x8_avx2   ( uint8_t *, uint8_t *, int * );
#define x264_intra_sad_x3_8x8_avx2 x264_template(intra_sad_x3_8x8_avx2)
void x264_intra_sad_x3_8x8_avx2    ( uint8_t *, uint8_t *, int * );
#define x264_intra_satd_x9_4x4_avx2 x264_template(intra_satd_x9_4x4_avx2)
int x264_intra_satd_x9_4x4_avx2  ( uint8_t *, uint8_t *, uint16_t * );
#define x264_intra_sad_x9_4x4_avx2 x264_template(intra_sad_x9_4x4_avx2)
int x264_intra_sad_x9_4x4_avx2   ( uint8_t *, uint8_t *, uint16_t * );
#define x264_intra_sa8d_x9_8x8_avx2 x264_template(intra_sa8d_x9_8x8_avx2)
int x264_intra_sa8d_x9_8x8_avx2  ( uint8_t *, uint8_t *, uint8_t *, uint16_t *, uint16_t * );
#define x264_intra_sad_x9_8x8_avx2 x264_template(intra_sad_x9_8x8_avx2)
int x264_intra_sad_x9_8x8_avx2  ( uint8_t *, uint8_t *, uint8_t *, uint16_t *, uint16_t * );

#define x264_pixel_ssd_nv12_core_avx2 x264_template(pixel_ssd_nv12_core_avx2)
void x264_pixel_ssd_nv12_core_avx2( pixel *pixuv1, intptr_t stride1,
                                    pixel *pixuv2, intptr_t stride2, int width,
                                    int height, uint64_t *ssd_u, uint64_t *ssd_v );
#define x264_pixel_ssim_4x4x2_core_avx2 x264_template(pixel_ssim_4x4x2_core_avx2)
void x264_pixel_ssim_4x4x2_core_avx2 ( const pixel *pix1, intptr_t stride1,
                                       const pixel *pix2, intptr_t stride2, int sums[2][4] );
#define x264_pixel_ssim_end4_avx2 x264_template(pixel_ssim_end4_avx2)
float x264_pixel_ssim_end4_avx2 ( int sum0[5][4], int sum1[5][4], int width );
#define x264_pixel_var2_8x8_avx2 x264_template(pixel_var2_8x8_avx2)
int  x264_pixel_var2_8x8_avx2   ( pixel   *fenc, pixel   *fdec, int ssd[2] );
#define x264_pixel_var2_8x16_avx2 x264_template(pixel_var2_8x16_avx2)
int  x264_pixel_var2_8x16_avx2  ( pixel   *fenc, pixel   *fdec, int ssd[2] );
#define x264_pixel_vsad_avx2 x264_template(pixel_vsad_avx2)
int  x264_pixel_vsad_avx2 ( pixel *src, intptr_t stride, int height );
#define x264_pixel_asd8_avx2 x264_template(pixel_asd8_avx2)
int x264_pixel_asd8_avx2( pixel *pix1, intptr_t stride1, pixel *pix2, intptr_t stride2, int height );
#define x264_pixel_sa8d_satd_16x16_avx2 x264_template(pixel_sa8d_satd_16x16_avx2)
uint64_t x264_pixel_sa8d_satd_16x16_avx2      ( pixel *pix1, intptr_t stride1, pixel *pix2, intptr_t stride2 );


#define DECL_ADS( size, suffix ) \
int x264_pixel_ads##size##_##suffix( int enc_dc[size], uint16_t *sums, int delta,\
                                     uint16_t *cost_mvx, int16_t *mvs, int width, int thresh );
DECL_ADS( 4, avx2 )
DECL_ADS( 2, avx2 )
DECL_ADS( 1, avx2 )

#undef DECL_PIXELS
#undef DECL_X1
#undef DECL_X4
#undef DECL_ADS

#endif
