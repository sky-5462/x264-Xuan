/*****************************************************************************
 * cabac.c: arithmetic coder
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

#include "common.h"

static uint8_t cabac_contexts[2][QP_MAX_SPEC+1][1024];

void x264_cabac_init()
{
    int ctx_count = 460;
    for( int i = 0; i < 2; i++ )
    {
        const int8_t (*cabac_context_init)[1024][2] = i == 0 ? &x264_cabac_context_init_I
                                                             : &x264_cabac_context_init_PB;
        for( int qp = 0; qp <= QP_MAX_SPEC; qp++ )
            for( int j = 0; j < ctx_count; j++ )
            {
                int state = x264_clip3( (((*cabac_context_init)[j][0] * qp) >> 4) + (*cabac_context_init)[j][1], 1, 126 );
                cabac_contexts[i][qp][j] = (X264_MIN( state, 127-state ) << 1) | (state >> 6);
            }
    }
}

void x264_cabac_context_init( x264_cabac_t *cb, int i_slice_type, int i_qp )
{
    memcpy( cb->state, cabac_contexts[i_slice_type == SLICE_TYPE_I ? 0 : 1][i_qp], 460 );
}

void x264_cabac_encode_init_core( x264_cabac_t *cb )
{
    cb->i_low   = 0;
    cb->i_range = 0x01FE;
    cb->i_queue = -9; // the first bit will be shifted away and not written
    cb->i_bytes_outstanding = 0;
}

void x264_cabac_encode_init( x264_cabac_t *cb, uint8_t *p_data, uint8_t *p_end )
{
    x264_cabac_encode_init_core( cb );
    cb->p_start = p_data;
    cb->p       = p_data;
    cb->p_end   = p_end;
}

static inline void cabac_putbyte( x264_cabac_t *cb )
{
    if( cb->i_queue >= 0 )
    {
        int out = cb->i_low >> (cb->i_queue+10);
        cb->i_low = _bzhi_u32(cb->i_low, (cb->i_queue+10));
        cb->i_queue -= 8;

        if( (out & 0xff) == 0xff )
            cb->i_bytes_outstanding++;
        else
        {
            int carry = out >> 8;
            int bytes_outstanding = cb->i_bytes_outstanding;
            // this can't modify before the beginning of the stream because
            // that would correspond to a probability > 1.
            // it will write before the beginning of the stream, which is ok
            // because a slice header always comes before cabac data.
            // this can't carry beyond the one byte, because any 0xff bytes
            // are in bytes_outstanding and thus not written yet.
            cb->p[-1] += carry;
            while( bytes_outstanding > 0 )
            {
                *(cb->p++) = carry-1;
                bytes_outstanding--;
            }
            *(cb->p++) = out;
            cb->i_bytes_outstanding = 0;
        }
    }
}

static const int bypass_lut[16] =
{
    -1,      0x2,     0x14,     0x68,     0x1d0,     0x7a0,     0x1f40,     0x7e80,
    0x1fd00, 0x7fa00, 0x1ff400, 0x7fe800, 0x1ffd000, 0x7ffa000, 0x1fff4000, 0x7ffe8000
};

void x264_cabac_encode_ue_bypass( x264_cabac_t *cb, int exp_bits, int val )
{
    uint32_t v = val + (1<<exp_bits);
    int k = 31 - x264_clz( v );
    uint32_t x = (bypass_lut[k-exp_bits]<<exp_bits) + v;
    k = 2*k+1-exp_bits;
    int i = ((k-1)&7)+1;
    do {
        k -= i;
        cb->i_low <<= i;
        cb->i_low += ((x>>k)&0xff) * cb->i_range;
        cb->i_queue += i;
        cabac_putbyte( cb );
        i = 8;
    } while( k > 0 );
}

void x264_cabac_encode_flush( x264_t *h, x264_cabac_t *cb )
{
    cb->i_low += cb->i_range - 2;
    cb->i_low |= 1;
    cb->i_low <<= 9;
    cb->i_queue += 9;
    cabac_putbyte( cb );
    cabac_putbyte( cb );
    cb->i_low <<= -cb->i_queue;
    cb->i_low |= (0x35a4e4f5 >> (h->i_frame & 31) & 1) << 10;
    cb->i_queue = 0;
    cabac_putbyte( cb );

    while( cb->i_bytes_outstanding > 0 )
    {
        *(cb->p++) = 0xff;
        cb->i_bytes_outstanding--;
    }
}

