/*****************************************************************************
 * deblock.c: deblocking
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

#include "common.h"

/* Deblocking filter */
static const uint8_t i_alpha_table[52+12*3] =
{
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  4,  4,  5,  6,
     7,  8,  9, 10, 12, 13, 15, 17, 20, 22,
    25, 28, 32, 36, 40, 45, 50, 56, 63, 71,
    80, 90,101,113,127,144,162,182,203,226,
   255,255,
   255,255,255,255,255,255,255,255,255,255,255,255,
};
static const uint8_t i_beta_table[52+12*3] =
{
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  2,  2,  2,  3,
     3,  3,  3,  4,  4,  4,  6,  6,  7,  7,
     8,  8,  9,  9, 10, 10, 11, 11, 12, 12,
    13, 13, 14, 14, 15, 15, 16, 16, 17, 17,
    18, 18,
    18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
};
static const int8_t i_tc0_table[52+12*3][4] =
{
    {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 },
    {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 },
    {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 },
    {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 },
    {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 },
    {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 },
    {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 0 }, {-1, 0, 0, 1 },
    {-1, 0, 0, 1 }, {-1, 0, 0, 1 }, {-1, 0, 0, 1 }, {-1, 0, 1, 1 }, {-1, 0, 1, 1 }, {-1, 1, 1, 1 },
    {-1, 1, 1, 1 }, {-1, 1, 1, 1 }, {-1, 1, 1, 1 }, {-1, 1, 1, 2 }, {-1, 1, 1, 2 }, {-1, 1, 1, 2 },
    {-1, 1, 1, 2 }, {-1, 1, 2, 3 }, {-1, 1, 2, 3 }, {-1, 2, 2, 3 }, {-1, 2, 2, 4 }, {-1, 2, 3, 4 },
    {-1, 2, 3, 4 }, {-1, 3, 3, 5 }, {-1, 3, 4, 6 }, {-1, 3, 4, 6 }, {-1, 4, 5, 7 }, {-1, 4, 5, 8 },
    {-1, 4, 6, 9 }, {-1, 5, 7,10 }, {-1, 6, 8,11 }, {-1, 6, 8,13 }, {-1, 7,10,14 }, {-1, 8,11,16 },
    {-1, 9,12,18 }, {-1,10,13,20 }, {-1,11,15,23 }, {-1,13,17,25 },
    {-1,13,17,25 }, {-1,13,17,25 }, {-1,13,17,25 }, {-1,13,17,25 }, {-1,13,17,25 }, {-1,13,17,25 },
    {-1,13,17,25 }, {-1,13,17,25 }, {-1,13,17,25 }, {-1,13,17,25 }, {-1,13,17,25 }, {-1,13,17,25 },
};
#define alpha_table(x) i_alpha_table[(x)+24]
#define beta_table(x)  i_beta_table[(x)+24]
#define tc0_table(x)   i_tc0_table[(x)+24]

static ALWAYS_INLINE void deblock_edge( x264_t *h, pixel *pix, intptr_t i_stride, uint8_t bS[4], int i_qp,
                                        int a, int b, int b_chroma, x264_deblock_inter_t pf_inter )
{
    int index_a = i_qp + a;
    int index_b = i_qp + b;
    int alpha = alpha_table(index_a);
    int beta  = beta_table(index_b);
    int8_t tc[4];

    if( !M32(bS) || !alpha || !beta )
        return;

    tc[0] = (tc0_table(index_a)[bS[0]]) + b_chroma;
    tc[1] = (tc0_table(index_a)[bS[1]]) + b_chroma;
    tc[2] = (tc0_table(index_a)[bS[2]]) + b_chroma;
    tc[3] = (tc0_table(index_a)[bS[3]]) + b_chroma;

    pf_inter( pix, i_stride, alpha, beta, tc );
}

static ALWAYS_INLINE void deblock_edge_intra( x264_t *h, pixel *pix, intptr_t i_stride, uint8_t bS[4], int i_qp,
                                              int a, int b, int b_chroma, x264_deblock_intra_t pf_intra )
{
    int index_a = i_qp + a;
    int index_b = i_qp + b;
    int alpha = alpha_table(index_a);
    int beta  = beta_table(index_b);

    if( !alpha || !beta )
        return;

    pf_intra( pix, i_stride, alpha, beta );
}

static ALWAYS_INLINE void macroblock_cache_load_neighbours_deblock( x264_t *h, int mb_x, int mb_y )
{
    int deblock_on_slice_edges = h->sh.i_disable_deblocking_filter_idc != 2;

    h->mb.i_neighbour = 0;
    h->mb.i_mb_xy = mb_y * h->mb.i_mb_stride + mb_x;
    h->mb.b_interlaced = 0;
    h->mb.i_mb_top_y = mb_y - 1;
    h->mb.i_mb_top_xy = mb_x + h->mb.i_mb_stride*h->mb.i_mb_top_y;
    h->mb.i_mb_left_xy[1] =
    h->mb.i_mb_left_xy[0] = h->mb.i_mb_xy - 1;

    if( mb_x > 0 && (deblock_on_slice_edges ||
        h->mb.slice_table[h->mb.i_mb_left_xy[0]] == h->mb.slice_table[h->mb.i_mb_xy]) )
        h->mb.i_neighbour |= MB_LEFT;
    if( mb_y > 0 && (deblock_on_slice_edges
        || h->mb.slice_table[h->mb.i_mb_top_xy] == h->mb.slice_table[h->mb.i_mb_xy]) )
        h->mb.i_neighbour |= MB_TOP;
}

void x264_frame_deblock_row( x264_t *h, int mb_y )
{
    int b_interlaced = 0;
    int a = h->sh.i_alpha_c0_offset - QP_BD_OFFSET;
    int b = h->sh.i_beta_offset - QP_BD_OFFSET;
    int qp_thresh = 15 - X264_MIN( a, b ) - X264_MAX( 0, h->pps->i_chroma_qp_index_offset );
    int stridey   = h->fdec->i_stride[0];
    int strideuv  = h->fdec->i_stride[1];
    int chroma_format = CHROMA_FORMAT;
    int chroma444 = CHROMA444;
    int chroma_height = 16 >> CHROMA_V_SHIFT;
    intptr_t uvdiff = chroma444 ? h->fdec->plane[2] - h->fdec->plane[1] : 1;

    for( int mb_x = 0; mb_x < h->mb.i_mb_width; mb_x += (~b_interlaced | mb_y)&1, mb_y ^= b_interlaced )
    {
        macroblock_cache_load_neighbours_deblock( h, mb_x, mb_y );

        int mb_xy = h->mb.i_mb_xy;
        int transform_8x8 = h->mb.mb_transform_size[mb_xy];
        int intra_cur = IS_INTRA( h->mb.type[mb_xy] );
        uint8_t (*bs)[8][4] = h->deblock_strength[mb_y&1][h->param.b_sliced_threads?mb_xy:mb_x];

        pixel *pixy = h->fdec->plane[0] + 16*mb_y*stridey  + 16*mb_x;
        pixel *pixuv = h->fdec->plane[1] + chroma_height*mb_y*strideuv + 16*mb_x;

        int stride2y  = stridey;
        int stride2uv = strideuv;
        int qp = h->mb.qp[mb_xy];
        int qpc = h->chroma_qp_table[qp];
        int first_edge_only = (h->mb.partition[mb_xy] == D_16x16 && !h->mb.cbp[mb_xy] && !intra_cur) || qp <= qp_thresh;

        #define FILTER( intra, dir, edge, qp, chroma_qp )\
        do\
        {\
            if( !(edge & 1) || !transform_8x8 )\
            {\
                deblock_edge##intra( h, pixy + 4*edge*(dir?stride2y:1),\
                                     stride2y, bs[dir][edge], qp, a, b, 0,\
                                     h->loopf.deblock_luma##intra[dir] );\
                if( chroma_format == CHROMA_444 )\
                {\
                    deblock_edge##intra( h, pixuv          + 4*edge*(dir?stride2uv:1),\
                                         stride2uv, bs[dir][edge], chroma_qp, a, b, 0,\
                                         h->loopf.deblock_luma##intra[dir] );\
                    deblock_edge##intra( h, pixuv + uvdiff + 4*edge*(dir?stride2uv:1),\
                                         stride2uv, bs[dir][edge], chroma_qp, a, b, 0,\
                                         h->loopf.deblock_luma##intra[dir] );\
                }\
                else if( chroma_format == CHROMA_420 && !(edge & 1) )\
                {\
                    deblock_edge##intra( h, pixuv + edge*(dir?2*stride2uv:4),\
                                         stride2uv, bs[dir][edge], chroma_qp, a, b, 1,\
                                         h->loopf.deblock_chroma##intra[dir] );\
                }\
            }\
            if( chroma_format == CHROMA_422 && (dir || !(edge & 1)) )\
            {\
                deblock_edge##intra( h, pixuv + edge*(dir?4*stride2uv:4),\
                                     stride2uv, bs[dir][edge], chroma_qp, a, b, 1,\
                                     h->loopf.deblock_chroma##intra[dir] );\
            }\
        } while( 0 )

        if( h->mb.i_neighbour & MB_LEFT )
        {
            int qpl = h->mb.qp[h->mb.i_mb_xy-1];
            int qp_left = (qp + qpl + 1) >> 1;
            int qpc_left = (qpc + h->chroma_qp_table[qpl] + 1) >> 1;
            int intra_left = IS_INTRA( h->mb.type[h->mb.i_mb_xy-1] );
            int intra_deblock = intra_cur || intra_left;

            /* Any MB that was coded, or that analysis decided to skip, has quality commensurate with its QP.
                * But if deblocking affects neighboring MBs that were force-skipped, blur might accumulate there.
                * So reset their effective QP to max, to indicate that lack of guarantee. */
            if( h->fdec->mb_info && M32( bs[0][0] ) )
            {
#define RESET_EFFECTIVE_QP(xy) h->fdec->effective_qp[xy] |= 0xff * !!(h->fdec->mb_info[xy] & X264_MBINFO_CONSTANT);
                RESET_EFFECTIVE_QP(mb_xy);
                RESET_EFFECTIVE_QP(h->mb.i_mb_left_xy[0]);
            }

            if( intra_deblock )
                FILTER( _intra, 0, 0, qp_left, qpc_left );
            else
                FILTER(       , 0, 0, qp_left, qpc_left );
        }
        if( !first_edge_only )
        {
            FILTER( , 0, 1, qp, qpc );
            FILTER( , 0, 2, qp, qpc );
            FILTER( , 0, 3, qp, qpc );
        }

        if( h->mb.i_neighbour & MB_TOP )
        {
            int qpt = h->mb.qp[h->mb.i_mb_top_xy];
            int qp_top = (qp + qpt + 1) >> 1;
            int qpc_top = (qpc + h->chroma_qp_table[qpt] + 1) >> 1;
            int intra_top = IS_INTRA( h->mb.type[h->mb.i_mb_top_xy] );
            int intra_deblock = intra_cur || intra_top;

            /* This edge has been modified, reset effective qp to max. */
            if( h->fdec->mb_info && M32( bs[1][0] ) )
            {
                RESET_EFFECTIVE_QP(mb_xy);
                RESET_EFFECTIVE_QP(h->mb.i_mb_top_xy);
            }

            if( intra_deblock )
            {
                FILTER( _intra, 1, 0, qp_top, qpc_top );
            }
            else
            {
                if( intra_deblock )
                    M32( bs[1][0] ) = 0x03030303;
                FILTER(       , 1, 0, qp_top, qpc_top );
            }
        }

        if( !first_edge_only )
        {
            FILTER( , 1, 1, qp, qpc );
            FILTER( , 1, 2, qp, qpc );
            FILTER( , 1, 3, qp, qpc );
        }

        #undef FILTER
    }
}

/* For deblock-aware RD.
 * TODO:
 *  deblock macroblock edges
 *  support analysis partitions smaller than 16x16
 *  deblock chroma for 4:2:0/4:2:2
 *  handle duplicate refs correctly
 */
void x264_macroblock_deblock( x264_t *h )
{
    int a = h->sh.i_alpha_c0_offset - QP_BD_OFFSET;
    int b = h->sh.i_beta_offset - QP_BD_OFFSET;
    int qp_thresh = 15 - X264_MIN( a, b ) - X264_MAX( 0, h->pps->i_chroma_qp_index_offset );
    int intra_cur = IS_INTRA( h->mb.i_type );
    int qp = h->mb.i_qp;
    int qpc = h->mb.i_chroma_qp;
    if( (h->mb.i_partition == D_16x16 && !h->mb.i_cbp_luma && !intra_cur) || qp <= qp_thresh )
        return;

    uint8_t (*bs)[8][4] = h->mb.cache.deblock_strength;
    if( intra_cur )
    {
        M32( bs[0][1] ) = 0x03030303;
        M64( bs[0][2] ) = 0x0303030303030303ULL;
        M32( bs[1][1] ) = 0x03030303;
        M64( bs[1][2] ) = 0x0303030303030303ULL;
    }
    else
        h->loopf.deblock_strength( h->mb.cache.non_zero_count, h->mb.cache.ref, h->mb.cache.mv,
                                   bs, h->sh.i_type == SLICE_TYPE_B );

    int transform_8x8 = h->mb.b_transform_8x8;

    #define FILTER( dir, edge )\
    do\
    {\
        deblock_edge( h, h->mb.pic.p_fdec[0] + 4*edge*(dir?FDEC_STRIDE:1),\
                      FDEC_STRIDE, bs[dir][edge], qp, a, b, 0,\
                      h->loopf.deblock_luma[dir] );\
        if( CHROMA444 )\
        {\
            deblock_edge( h, h->mb.pic.p_fdec[1] + 4*edge*(dir?FDEC_STRIDE:1),\
                          FDEC_STRIDE, bs[dir][edge], qpc, a, b, 0,\
                          h->loopf.deblock_luma[dir] );\
            deblock_edge( h, h->mb.pic.p_fdec[2] + 4*edge*(dir?FDEC_STRIDE:1),\
                          FDEC_STRIDE, bs[dir][edge], qpc, a, b, 0,\
                          h->loopf.deblock_luma[dir] );\
        }\
    } while( 0 )

    if( !transform_8x8 ) FILTER( 0, 1 );
                         FILTER( 0, 2 );
    if( !transform_8x8 ) FILTER( 0, 3 );

    if( !transform_8x8 ) FILTER( 1, 1 );
                         FILTER( 1, 2 );
    if( !transform_8x8 ) FILTER( 1, 3 );

    #undef FILTER
}

#include "x86/deblock.h"

void x264_deblock_init( x264_deblock_function_t *pf )
{
    pf->deblock_luma[1] = x264_deblock_v_luma_avx2;
    pf->deblock_luma[0] = x264_deblock_h_luma_avx2;
    pf->deblock_chroma[1] = x264_deblock_v_chroma_avx2;
    pf->deblock_h_chroma_420 = x264_deblock_h_chroma_avx2;
    pf->deblock_h_chroma_422 = x264_deblock_h_chroma_422_avx2;
    pf->deblock_luma_intra[1] = x264_deblock_v_luma_intra_avx2;
    pf->deblock_luma_intra[0] = x264_deblock_h_luma_intra_avx2;
    pf->deblock_chroma_intra[1] = x264_deblock_v_chroma_intra_avx2;
    pf->deblock_h_chroma_420_intra = x264_deblock_h_chroma_intra_avx2;
    pf->deblock_h_chroma_422_intra = x264_deblock_h_chroma_422_intra_avx2;
    pf->deblock_strength = x264_deblock_strength_avx2;
}
