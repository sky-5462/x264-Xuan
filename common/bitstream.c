/*****************************************************************************
 * bitstream.c: bitstream writing
 *****************************************************************************
 * Copyright (C) 2003-2019 x264 project
 *
 * Authors: Laurent Aimar <fenrir@via.ecp.fr>
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
#include "x86/bitstream.h"

/****************************************************************************
 * x264_nal_encode:
 ****************************************************************************/
void x264_nal_encode( x264_t *h, uint8_t *dst, x264_nal_t *nal )
{
    uint8_t *src = nal->p_payload;
    uint8_t *end = nal->p_payload + nal->i_payload;
    uint8_t *orig_dst = dst;

    if( h->param.b_annexb )
    {
        if( nal->b_long_startcode )
            *dst++ = 0x00;
        *dst++ = 0x00;
        *dst++ = 0x00;
        *dst++ = 0x01;
    }
    else /* save room for size later */
        dst += 4;

    /* nal header */
    *dst++ = ( 0x00 << 7 ) | ( nal->i_ref_idc << 5 ) | nal->i_type;

    dst = h->bsf.nal_escape( dst, src, end );
    int size = dst - orig_dst;

    /* Apply AVC-Intra padding */
    if( h->param.i_avcintra_class )
    {
        int padding = nal->i_payload + nal->i_padding + NALU_OVERHEAD - size;
        if( padding > 0 )
        {
            memset( dst, 0, padding );
            size += padding;
        }
        nal->i_padding = X264_MAX( padding, 0 );
    }

    /* Write the size header for mp4/etc */
    if( !h->param.b_annexb )
    {
        /* Size doesn't include the size of the header we're writing now. */
        int chunk_size = size - 4;
        orig_dst[0] = chunk_size >> 24;
        orig_dst[1] = chunk_size >> 16;
        orig_dst[2] = chunk_size >> 8;
        orig_dst[3] = chunk_size >> 0;
    }

    nal->i_payload = size;
    nal->p_payload = orig_dst;
}

void x264_bitstream_init( x264_bitstream_function_t *pf )
{
    pf->cabac_block_residual_internal = x264_cabac_block_residual_internal_avx2;
    pf->cabac_block_residual_rd_internal = x264_cabac_block_residual_rd_internal_avx2;
    pf->cabac_block_residual_8x8_rd_internal = x264_cabac_block_residual_8x8_rd_internal_avx2;
    pf->nal_escape = x264_nal_escape_avx2;
}
