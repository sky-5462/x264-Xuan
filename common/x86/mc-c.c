/*****************************************************************************
 * mc-c.c: x86 motion compensation
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
#include "mc.h"

#define x264_pixel_avg_2x2_avx2 x264_template(pixel_avg_2x2_avx2)
#define x264_pixel_avg_2x4_avx2 x264_template(pixel_avg_2x4_avx2)
#define x264_pixel_avg_2x8_avx2 x264_template(pixel_avg_2x8_avx2)
#define x264_pixel_avg_4x2_avx2 x264_template(pixel_avg_4x2_avx2)
#define x264_pixel_avg_4x4_avx2 x264_template(pixel_avg_4x4_avx2)
#define x264_pixel_avg_4x8_avx2 x264_template(pixel_avg_4x8_avx2)
#define x264_pixel_avg_4x16_avx2 x264_template(pixel_avg_4x16_avx2)
#define x264_pixel_avg_8x4_avx2 x264_template(pixel_avg_8x4_avx2)
#define x264_pixel_avg_8x8_avx2 x264_template(pixel_avg_8x8_avx2)
#define x264_pixel_avg_8x16_avx2 x264_template(pixel_avg_8x16_avx2)
#define x264_pixel_avg_16x8_avx2 x264_template(pixel_avg_16x8_avx2)
#define x264_pixel_avg_16x16_avx2 x264_template(pixel_avg_16x16_avx2)
void x264_pixel_avg_2x2_avx2( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
void x264_pixel_avg_2x4_avx2( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
void x264_pixel_avg_2x8_avx2( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
void x264_pixel_avg_4x2_avx2( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
void x264_pixel_avg_4x4_avx2( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
void x264_pixel_avg_4x8_avx2( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
void x264_pixel_avg_4x16_avx2( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
void x264_pixel_avg_8x4_avx2( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
void x264_pixel_avg_8x8_avx2( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
void x264_pixel_avg_8x16_avx2( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
void x264_pixel_avg_16x8_avx2( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
void x264_pixel_avg_16x16_avx2( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );

#define x264_mc_weight_w4_avx2 x264_template(mc_weight_w4_avx2)
#define x264_mc_weight_w8_avx2 x264_template(mc_weight_w8_avx2)
#define x264_mc_weight_w16_avx2 x264_template(mc_weight_w16_avx2)
#define x264_mc_weight_w20_avx2 x264_template(mc_weight_w20_avx2)
#define x264_mc_offsetadd_w4_avx2 x264_template(mc_offsetadd_w4_avx2)
#define x264_mc_offsetadd_w8_avx2 x264_template(mc_offsetadd_w8_avx2)
#define x264_mc_offsetadd_w16_avx2 x264_template(mc_offsetadd_w16_avx2)
#define x264_mc_offsetadd_w20_avx2 x264_template(mc_offsetadd_w20_avx2)
#define x264_mc_offsetsub_w4_avx2 x264_template(mc_offsetsub_w4_avx2)
#define x264_mc_offsetsub_w8_avx2 x264_template(mc_offsetsub_w8_avx2)
#define x264_mc_offsetsub_w16_avx2 x264_template(mc_offsetsub_w16_avx2)
#define x264_mc_offsetsub_w20_avx2 x264_template(mc_offsetsub_w20_avx2)
#define MC_WEIGHT_OFFSET(w,type) \
    void x264_mc_offsetadd_w##w##_##type( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int ); \
    void x264_mc_offsetsub_w##w##_##type( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int ); \
    void x264_mc_weight_w##w##_##type( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );

MC_WEIGHT_OFFSET( 4, avx2 )
MC_WEIGHT_OFFSET( 8, avx2 )
MC_WEIGHT_OFFSET( 16, avx2 )
MC_WEIGHT_OFFSET( 20, avx2 )
#undef MC_WEIGHT_OFFSET

#define x264_mc_copy_w4_mmx x264_template(mc_copy_w4_mmx)
void x264_mc_copy_w4_mmx ( pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_mc_copy_w8_mmx x264_template(mc_copy_w8_mmx)
void x264_mc_copy_w8_mmx ( pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_mc_copy_w8_sse x264_template(mc_copy_w8_sse)
void x264_mc_copy_w8_sse ( pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_mc_copy_w16_mmx x264_template(mc_copy_w16_mmx)
void x264_mc_copy_w16_mmx( pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_mc_copy_w16_sse x264_template(mc_copy_w16_sse)
void x264_mc_copy_w16_sse( pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_mc_copy_w16_aligned_sse x264_template(mc_copy_w16_aligned_sse)
void x264_mc_copy_w16_aligned_sse( pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_mc_copy_w16_avx x264_template(mc_copy_w16_avx)
void x264_mc_copy_w16_avx( uint16_t *, intptr_t, uint16_t *, intptr_t, int );
#define x264_mc_copy_w16_aligned_avx x264_template(mc_copy_w16_aligned_avx)
void x264_mc_copy_w16_aligned_avx( uint16_t *, intptr_t, uint16_t *, intptr_t, int );
#define x264_prefetch_fenc_400_mmx2 x264_template(prefetch_fenc_400_mmx2)
void x264_prefetch_fenc_400_mmx2( pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_prefetch_fenc_420_mmx2 x264_template(prefetch_fenc_420_mmx2)
void x264_prefetch_fenc_420_mmx2( pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_prefetch_fenc_422_mmx2 x264_template(prefetch_fenc_422_mmx2)
void x264_prefetch_fenc_422_mmx2( pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_prefetch_ref_mmx2 x264_template(prefetch_ref_mmx2)
void x264_prefetch_ref_mmx2( pixel *, intptr_t, int );
#define x264_plane_copy_avx2 x264_template(plane_copy_avx2)
void x264_plane_copy_avx2( pixel *, intptr_t, pixel *, intptr_t, int w, int h );
#define x264_plane_copy_interleave_avx2 x264_template(plane_copy_interleave_avx2)
void x264_plane_copy_interleave_avx2( pixel *dst,  intptr_t i_dst,
                                          pixel *srcu, intptr_t i_srcu,
                                          pixel *srcv, intptr_t i_srcv, int w, int h );
#define x264_plane_copy_deinterleave_avx2 x264_template(plane_copy_deinterleave_avx2)
void x264_plane_copy_deinterleave_avx2( pixel *dsta, intptr_t i_dsta,
                                        pixel *dstb, intptr_t i_dstb,
                                        pixel *src,  intptr_t i_src, int w, int h );
#define x264_store_interleave_chroma_avx2 x264_template(store_interleave_chroma_avx2)
void x264_store_interleave_chroma_avx2 ( pixel *dst, intptr_t i_dst, pixel *srcu, pixel *srcv, int height );
#define x264_load_deinterleave_chroma_fenc_avx2 x264_template(load_deinterleave_chroma_fenc_avx2)
void x264_load_deinterleave_chroma_fenc_avx2( pixel *dst, pixel *src, intptr_t i_src, int height );
#define x264_load_deinterleave_chroma_fdec_avx2 x264_template(load_deinterleave_chroma_fdec_avx2)
void x264_load_deinterleave_chroma_fdec_avx2( uint8_t *dst, uint8_t *src, intptr_t i_src, int height );
#define x264_memcpy_aligned_sse x264_template(memcpy_aligned_sse)
void *x264_memcpy_aligned_sse   ( void *dst, const void *src, size_t n );
#define x264_memcpy_aligned_avx x264_template(memcpy_aligned_avx)
void *x264_memcpy_aligned_avx   ( void *dst, const void *src, size_t n );
#define x264_memcpy_aligned_avx512 x264_template(memcpy_aligned_avx512)
void *x264_memcpy_aligned_avx512( void *dst, const void *src, size_t n );
#define x264_memzero_aligned_sse x264_template(memzero_aligned_sse)
void x264_memzero_aligned_sse   ( void *dst, size_t n );
#define x264_memzero_aligned_avx x264_template(memzero_aligned_avx)
void x264_memzero_aligned_avx   ( void *dst, size_t n );
#define x264_memzero_aligned_avx512 x264_template(memzero_aligned_avx512)
void x264_memzero_aligned_avx512( void *dst, size_t n );
#define x264_integral_init4h_avx2 x264_template(integral_init4h_avx2)
void x264_integral_init4h_avx2( uint16_t *sum, uint8_t *pix, intptr_t stride );
#define x264_integral_init8h_avx2 x264_template(integral_init8h_avx2)
void x264_integral_init8h_avx2( uint16_t *sum, uint8_t *pix, intptr_t stride );
#define x264_integral_init4v_avx2 x264_template(integral_init4v_avx2)
void x264_integral_init4v_avx2( uint16_t *sum8, uint16_t *sum4, intptr_t stride );
#define x264_integral_init8v_avx2 x264_template(integral_init8v_avx2)
void x264_integral_init8v_avx2( uint16_t *sum8, intptr_t stride );
#define x264_mbtree_propagate_cost_avx2 x264_template(mbtree_propagate_cost_avx2)
void x264_mbtree_propagate_cost_avx2  ( int16_t *dst, uint16_t *propagate_in, uint16_t *intra_costs,
                                        uint16_t *inter_costs, uint16_t *inv_qscales, float *fps_factor, int len );
#define x264_mbtree_fix8_pack_ssse3 x264_template(mbtree_fix8_pack_ssse3)
void x264_mbtree_fix8_pack_ssse3( uint16_t *dst, float *src, int count );
#define x264_mbtree_fix8_pack_avx2 x264_template(mbtree_fix8_pack_avx2)
void x264_mbtree_fix8_pack_avx2 ( uint16_t *dst, float *src, int count );
#define x264_mbtree_fix8_pack_avx512 x264_template(mbtree_fix8_pack_avx512)
void x264_mbtree_fix8_pack_avx512( uint16_t *dst, float *src, int count );
#define x264_mbtree_fix8_unpack_ssse3 x264_template(mbtree_fix8_unpack_ssse3)
void x264_mbtree_fix8_unpack_ssse3( float *dst, uint16_t *src, int count );
#define x264_mbtree_fix8_unpack_avx2 x264_template(mbtree_fix8_unpack_avx2)
void x264_mbtree_fix8_unpack_avx2 ( float *dst, uint16_t *src, int count );
#define x264_mbtree_fix8_unpack_avx512 x264_template(mbtree_fix8_unpack_avx512)
void x264_mbtree_fix8_unpack_avx512( float *dst, uint16_t *src, int count );

#define x264_mc_chroma_avx x264_template(mc_chroma_avx)
#define x264_mc_chroma_avx2 x264_template(mc_chroma_avx2)
#define x264_mc_chroma_cache64_ssse3 x264_template(mc_chroma_cache64_ssse3)
#define x264_mc_chroma_mmx2 x264_template(mc_chroma_mmx2)
#define x264_mc_chroma_sse2 x264_template(mc_chroma_sse2)
#define x264_mc_chroma_ssse3 x264_template(mc_chroma_ssse3)
#define MC_CHROMA(cpu)\
void x264_mc_chroma_##cpu( pixel *dstu, pixel *dstv, intptr_t i_dst, pixel *src, intptr_t i_src,\
                           int dx, int dy, int i_width, int i_height );
MC_CHROMA(mmx2)
MC_CHROMA(sse2)
MC_CHROMA(ssse3)
MC_CHROMA(cache64_ssse3)
MC_CHROMA(avx)
MC_CHROMA(avx2)
#undef MC_CHROMA

#define x264_frame_init_lowres_core_avx2 x264_template(frame_init_lowres_core_avx2)
void x264_frame_init_lowres_core_avx2( pixel *src0, pixel *dst0, pixel *dsth, pixel *dstv, pixel *dstc,
                                       intptr_t src_stride, intptr_t dst_stride, int width, int height );

#define x264_pixel_avg2_w10_mmx2 x264_template(pixel_avg2_w10_mmx2)
#define x264_pixel_avg2_w10_sse2 x264_template(pixel_avg2_w10_sse2)
#define x264_pixel_avg2_w12_cache32_mmx2 x264_template(pixel_avg2_w12_cache32_mmx2)
#define x264_pixel_avg2_w12_cache64_mmx2 x264_template(pixel_avg2_w12_cache64_mmx2)
#define x264_pixel_avg2_w12_mmx2 x264_template(pixel_avg2_w12_mmx2)
#define x264_pixel_avg2_w16_avx2 x264_template(pixel_avg2_w16_avx2)
#define x264_pixel_avg2_w16_cache32_mmx2 x264_template(pixel_avg2_w16_cache32_mmx2)
#define x264_pixel_avg2_w16_cache64_mmx2 x264_template(pixel_avg2_w16_cache64_mmx2)
#define x264_pixel_avg2_w16_cache64_sse2 x264_template(pixel_avg2_w16_cache64_sse2)
#define x264_pixel_avg2_w16_cache64_ssse3 x264_template(pixel_avg2_w16_cache64_ssse3)
#define x264_pixel_avg2_w16_mmx2 x264_template(pixel_avg2_w16_mmx2)
#define x264_pixel_avg2_w16_sse2 x264_template(pixel_avg2_w16_sse2)
#define x264_pixel_avg2_w18_avx2 x264_template(pixel_avg2_w18_avx2)
#define x264_pixel_avg2_w18_mmx2 x264_template(pixel_avg2_w18_mmx2)
#define x264_pixel_avg2_w18_sse2 x264_template(pixel_avg2_w18_sse2)
#define x264_pixel_avg2_w20_avx2 x264_template(pixel_avg2_w20_avx2)
#define x264_pixel_avg2_w20_cache32_mmx2 x264_template(pixel_avg2_w20_cache32_mmx2)
#define x264_pixel_avg2_w20_cache64_mmx2 x264_template(pixel_avg2_w20_cache64_mmx2)
#define x264_pixel_avg2_w20_cache64_sse2 x264_template(pixel_avg2_w20_cache64_sse2)
#define x264_pixel_avg2_w20_mmx2 x264_template(pixel_avg2_w20_mmx2)
#define x264_pixel_avg2_w20_sse2 x264_template(pixel_avg2_w20_sse2)
#define x264_pixel_avg2_w4_mmx2 x264_template(pixel_avg2_w4_mmx2)
#define x264_pixel_avg2_w8_cache32_mmx2 x264_template(pixel_avg2_w8_cache32_mmx2)
#define x264_pixel_avg2_w8_cache64_mmx2 x264_template(pixel_avg2_w8_cache64_mmx2)
#define x264_pixel_avg2_w8_mmx2 x264_template(pixel_avg2_w8_mmx2)
#define x264_pixel_avg2_w8_sse2 x264_template(pixel_avg2_w8_sse2)
#define PIXEL_AVG_W(width,cpu)\
void x264_pixel_avg2_w##width##_##cpu( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t );
/* This declares some functions that don't exist, but that isn't a problem. */
#define PIXEL_AVG_WALL(cpu)\
PIXEL_AVG_W(4,cpu); PIXEL_AVG_W(8,cpu); PIXEL_AVG_W(10,cpu); PIXEL_AVG_W(12,cpu); PIXEL_AVG_W(16,cpu); PIXEL_AVG_W(18,cpu); PIXEL_AVG_W(20,cpu);

PIXEL_AVG_WALL(mmx2)
PIXEL_AVG_WALL(cache32_mmx2)
PIXEL_AVG_WALL(cache64_mmx2)
PIXEL_AVG_WALL(cache64_sse2)
PIXEL_AVG_WALL(sse2)
PIXEL_AVG_WALL(cache64_ssse3)
PIXEL_AVG_WALL(avx2)
#undef PIXEL_AVG_W
#undef PIXEL_AVG_WALL

#define PIXEL_AVG_WTAB(instr, name1, name2, name3, name4, name5)\
static void (* const pixel_avg_wtab_##instr[6])( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t ) =\
{\
    NULL,\
    x264_pixel_avg2_w4_##name1,\
    x264_pixel_avg2_w8_##name2,\
    x264_pixel_avg2_w12_##name3,\
    x264_pixel_avg2_w16_##name4,\
    x264_pixel_avg2_w20_##name5,\
};

/* w16 sse2 is faster than w12 mmx as long as the cacheline issue is resolved */
#define x264_pixel_avg2_w12_cache64_ssse3 x264_pixel_avg2_w16_cache64_ssse3
#define x264_pixel_avg2_w12_cache64_sse2 x264_pixel_avg2_w16_cache64_sse2
#define x264_pixel_avg2_w12_sse3         x264_pixel_avg2_w16_sse3
#define x264_pixel_avg2_w12_sse2         x264_pixel_avg2_w16_sse2

PIXEL_AVG_WTAB(mmx2, mmx2, mmx2, mmx2, mmx2, mmx2)
#if ARCH_X86
PIXEL_AVG_WTAB(cache32_mmx2, mmx2, cache32_mmx2, cache32_mmx2, cache32_mmx2, cache32_mmx2)
PIXEL_AVG_WTAB(cache64_mmx2, mmx2, cache64_mmx2, cache64_mmx2, cache64_mmx2, cache64_mmx2)
#endif
PIXEL_AVG_WTAB(sse2, mmx2, mmx2, sse2, sse2, sse2)
PIXEL_AVG_WTAB(cache64_sse2, mmx2, cache64_mmx2, cache64_sse2, cache64_sse2, cache64_sse2)
PIXEL_AVG_WTAB(cache64_ssse3, mmx2, cache64_mmx2, cache64_ssse3, cache64_ssse3, cache64_sse2)
PIXEL_AVG_WTAB(cache64_ssse3_atom, mmx2, mmx2, cache64_ssse3, cache64_ssse3, sse2)
PIXEL_AVG_WTAB(avx2, mmx2, mmx2, sse2, sse2, avx2)

#define MC_COPY_WTAB(instr, name1, name2, name3)\
static void (* const mc_copy_wtab_##instr[5])( pixel *, intptr_t, pixel *, intptr_t, int ) =\
{\
    NULL,\
    x264_mc_copy_w4_##name1,\
    x264_mc_copy_w8_##name2,\
    NULL,\
    x264_mc_copy_w16_##name3,\
};

MC_COPY_WTAB(mmx,mmx,mmx,mmx)
MC_COPY_WTAB(sse,mmx,mmx,sse)

#define MC_WEIGHT_WTAB(function)\
static void (* mc_##function##_wtab_avx2[6])( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int ) =\
{\
    x264_mc_##function##_w4_avx2,\
    x264_mc_##function##_w4_avx2,\
    x264_mc_##function##_w8_avx2,\
    x264_mc_##function##_w16_avx2,\
    x264_mc_##function##_w16_avx2,\
    x264_mc_##function##_w20_avx2,\
};

MC_WEIGHT_WTAB(weight)
MC_WEIGHT_WTAB(offsetadd)
MC_WEIGHT_WTAB(offsetsub)

static void weight_cache_avx2(x264_t *h, x264_weight_t *w) {
	int den1;
	if (w->i_scale == 1 << w->i_denom) {
		if (w->i_offset < 0)
			w->weightfn = h->mc.offsetsub;
		else
			w->weightfn = h->mc.offsetadd;

		memset(w->cachea, abs(w->i_offset), 4);   // only fill one dword
		return;
	}
	w->weightfn = h->mc.weight;
	den1 = w->i_scale << (8 - w->i_denom);
	// one dword again
	w->cachea[0] = den1;
	w->cachea[1] = den1;
	w->cacheb[0] = w->i_offset;
	w->cacheb[1] = w->i_offset;
}

#define MC_LUMA(name,instr1,instr2)\
static void mc_luma_##name( pixel *dst,    intptr_t i_dst_stride,\
                            pixel *src[4], intptr_t i_src_stride,\
                            int mvx, int mvy,\
                            int i_width, int i_height, const x264_weight_t *weight )\
{\
    int qpel_idx = ((mvy&3)<<2) + (mvx&3);\
    int offset = (mvy>>2)*i_src_stride + (mvx>>2);\
    pixel *src1 = src[x264_hpel_ref0[qpel_idx]] + offset + ((mvy&3) == 3) * i_src_stride;\
    if( qpel_idx & 5 ) /* qpel interpolation needed */\
    {\
        pixel *src2 = src[x264_hpel_ref1[qpel_idx]] + offset + ((mvx&3) == 3);\
        pixel_avg_wtab_##instr1[i_width>>2](\
                dst, i_dst_stride, src1, i_src_stride,\
                src2, i_height );\
        if( weight->weightfn )\
            weight->weightfn[i_width>>2]( dst, i_dst_stride, dst, i_dst_stride, weight, i_height );\
    }\
    else if( weight->weightfn )\
        weight->weightfn[i_width>>2]( dst, i_dst_stride, src1, i_src_stride, weight, i_height );\
    else\
        mc_copy_wtab_##instr2[i_width>>2](dst, i_dst_stride, src1, i_src_stride, i_height );\
}

MC_LUMA(mmx2,mmx2,mmx)
MC_LUMA(sse2,sse2,sse)
#if ARCH_X86
MC_LUMA(cache32_mmx2,cache32_mmx2,mmx)
MC_LUMA(cache64_mmx2,cache64_mmx2,mmx)
#endif
MC_LUMA(cache64_sse2,cache64_sse2,sse)
MC_LUMA(cache64_ssse3,cache64_ssse3,sse)
MC_LUMA(cache64_ssse3_atom,cache64_ssse3_atom,sse)

#define GET_REF(name)\
static pixel *get_ref_##name( pixel *dst,   intptr_t *i_dst_stride,\
                              pixel *src[4], intptr_t i_src_stride,\
                              int mvx, int mvy,\
                              int i_width, int i_height, const x264_weight_t *weight )\
{\
    int qpel_idx = ((mvy&3)<<2) + (mvx&3);\
    int offset = (mvy>>2)*i_src_stride + (mvx>>2);\
    pixel *src1 = src[x264_hpel_ref0[qpel_idx]] + offset + ((mvy&3) == 3) * i_src_stride;\
    if( qpel_idx & 5 ) /* qpel interpolation needed */\
    {\
        pixel *src2 = src[x264_hpel_ref1[qpel_idx]] + offset + ((mvx&3) == 3);\
        pixel_avg_wtab_##name[i_width>>2](\
                dst, *i_dst_stride, src1, i_src_stride,\
                src2, i_height );\
        if( weight->weightfn )\
            weight->weightfn[i_width>>2]( dst, *i_dst_stride, dst, *i_dst_stride, weight, i_height );\
        return dst;\
    }\
    else if( weight->weightfn )\
    {\
        weight->weightfn[i_width>>2]( dst, *i_dst_stride, src1, i_src_stride, weight, i_height );\
        return dst;\
    }\
    else\
    {\
        *i_dst_stride = i_src_stride;\
        return src1;\
    }\
}

GET_REF(mmx2)
GET_REF(sse2)
GET_REF(avx2)
#if !HIGH_BIT_DEPTH
#if ARCH_X86
GET_REF(cache32_mmx2)
GET_REF(cache64_mmx2)
#endif
GET_REF(cache64_sse2)
GET_REF(cache64_ssse3)
GET_REF(cache64_ssse3_atom)
#endif // !HIGH_BIT_DEPTH

#define x264_hpel_filter_avx2 x264_template(hpel_filter_avx2)
void x264_hpel_filter_avx2 ( uint8_t *dsth, uint8_t *dstv, uint8_t *dstc, uint8_t *src, intptr_t stride, int width, int height);


void x264_mc_init_mmx( int cpu, x264_mc_functions_t *pf )
{
    pf->avg[PIXEL_2x2] = x264_pixel_avg_2x2_avx2;
    pf->avg[PIXEL_2x4] = x264_pixel_avg_2x4_avx2;
    pf->avg[PIXEL_2x8] = x264_pixel_avg_2x8_avx2;
    pf->avg[PIXEL_4x2] = x264_pixel_avg_4x2_avx2;
    pf->avg[PIXEL_4x4] = x264_pixel_avg_4x4_avx2;
    pf->avg[PIXEL_4x8] = x264_pixel_avg_4x8_avx2;
    pf->avg[PIXEL_4x16] = x264_pixel_avg_4x16_avx2;
    pf->avg[PIXEL_8x4] = x264_pixel_avg_8x4_avx2;
    pf->avg[PIXEL_8x8] = x264_pixel_avg_8x8_avx2;
    pf->avg[PIXEL_8x16] = x264_pixel_avg_8x16_avx2;
    pf->avg[PIXEL_16x8] = x264_pixel_avg_16x8_avx2;
    pf->avg[PIXEL_16x16] = x264_pixel_avg_16x16_avx2;

    pf->weight = mc_weight_wtab_avx2;
    pf->weight_cache = weight_cache_avx2;
    pf->offsetadd = mc_offsetadd_wtab_avx2;
    pf->offsetsub = mc_offsetsub_wtab_avx2;

    pf->store_interleave_chroma = x264_store_interleave_chroma_avx2;
    pf->load_deinterleave_chroma_fenc = x264_load_deinterleave_chroma_fenc_avx2;
    pf->load_deinterleave_chroma_fdec = x264_load_deinterleave_chroma_fdec_avx2;

    pf->plane_copy = x264_plane_copy_avx2;
    pf->plane_copy_interleave = x264_plane_copy_interleave_avx2;
    pf->plane_copy_deinterleave = x264_plane_copy_deinterleave_avx2;

    pf->hpel_filter = x264_hpel_filter_avx2;
    pf->frame_init_lowres_core = x264_frame_init_lowres_core_avx2;

    pf->integral_init4h = x264_integral_init4h_avx2;
    pf->integral_init8h = x264_integral_init8h_avx2;
    pf->integral_init4v = x264_integral_init4v_avx2;
    pf->integral_init8v = x264_integral_init8v_avx2;



    pf->copy_16x16_unaligned = x264_mc_copy_w16_mmx;
    pf->copy[PIXEL_16x16] = x264_mc_copy_w16_mmx;
    pf->copy[PIXEL_8x8]   = x264_mc_copy_w8_mmx;
    pf->copy[PIXEL_4x4]   = x264_mc_copy_w4_mmx;

    pf->prefetch_fenc_400 = x264_prefetch_fenc_400_mmx2;
    pf->prefetch_fenc_420 = x264_prefetch_fenc_420_mmx2;
    pf->prefetch_fenc_422 = x264_prefetch_fenc_422_mmx2;
    pf->prefetch_ref  = x264_prefetch_ref_mmx2;



    pf->mc_luma = mc_luma_mmx2;
    pf->get_ref = get_ref_mmx2;
    pf->mc_chroma = x264_mc_chroma_mmx2;


    if( cpu&X264_CPU_SSE )
    {
        pf->memcpy_aligned  = x264_memcpy_aligned_sse;
        pf->memzero_aligned = x264_memzero_aligned_sse;
    }

#if ARCH_X86 // all x86_64 cpus with cacheline split issues use sse2 instead
    if( cpu&X264_CPU_CACHELINE_32 )
    {
        pf->mc_luma = mc_luma_cache32_mmx2;
        pf->get_ref = get_ref_cache32_mmx2;
    }
    else if( cpu&X264_CPU_CACHELINE_64 )
    {
        pf->mc_luma = mc_luma_cache64_mmx2;
        pf->get_ref = get_ref_cache64_mmx2;
    }
#endif


    if( !(cpu&X264_CPU_SSE2_IS_SLOW) )
    {
        pf->copy[PIXEL_16x16] = x264_mc_copy_w16_aligned_sse;
        if( !(cpu&X264_CPU_STACK_MOD4) )
            pf->mc_chroma = x264_mc_chroma_sse2;

        if( cpu&X264_CPU_SSE2_IS_FAST )
        {
            pf->mc_luma = mc_luma_sse2;
            pf->get_ref = get_ref_sse2;
            if( cpu&X264_CPU_CACHELINE_64 )
            {
                pf->mc_luma = mc_luma_cache64_sse2;
                pf->get_ref = get_ref_cache64_sse2;
            }
        }
    }

    pf->mbtree_fix8_pack      = x264_mbtree_fix8_pack_ssse3;
    pf->mbtree_fix8_unpack    = x264_mbtree_fix8_unpack_ssse3;

    if( !(cpu&X264_CPU_STACK_MOD4) )
        pf->mc_chroma = x264_mc_chroma_ssse3;

    if( cpu&X264_CPU_CACHELINE_64 )
    {
        if( !(cpu&X264_CPU_STACK_MOD4) )
            pf->mc_chroma = x264_mc_chroma_cache64_ssse3;
        pf->mc_luma = mc_luma_cache64_ssse3;
        pf->get_ref = get_ref_cache64_ssse3;
        if( cpu&X264_CPU_SLOW_ATOM )
        {
            pf->mc_luma = mc_luma_cache64_ssse3_atom;
            pf->get_ref = get_ref_cache64_ssse3_atom;
        }
    }

    if( !(cpu&X264_CPU_STACK_MOD4) )
        pf->mc_chroma = x264_mc_chroma_avx;

    if( cpu&X264_CPU_AVX2 )
    {
        pf->mc_chroma = x264_mc_chroma_avx2;
    }

    pf->memcpy_aligned  = x264_memcpy_aligned_avx;
    pf->memzero_aligned = x264_memzero_aligned_avx;

    pf->get_ref = get_ref_avx2;
    pf->mbtree_fix8_pack      = x264_mbtree_fix8_pack_avx2;
    pf->mbtree_fix8_unpack    = x264_mbtree_fix8_unpack_avx2;

    if( !(cpu&X264_CPU_AVX512) )
        return;
    pf->memcpy_aligned = x264_memcpy_aligned_avx512;
    pf->memzero_aligned = x264_memzero_aligned_avx512;
    pf->mbtree_fix8_pack      = x264_mbtree_fix8_pack_avx512;
    pf->mbtree_fix8_unpack    = x264_mbtree_fix8_unpack_avx512;
}
