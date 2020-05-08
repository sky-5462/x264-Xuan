/*****************************************************************************
 * resize.c: resize video filter
 *****************************************************************************
 * Copyright (C) 2010-2019 x264 project
 *
 * Authors: Steven Walters <kemuri9@gmail.com>
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

#include "video.h"

#define NAME "resize"
#define FAIL_IF_ERROR( cond, ... ) FAIL_IF_ERR( cond, NAME, __VA_ARGS__ )

cli_vid_filter_t resize_filter;

static int full_check( video_info_t *info, x264_param_t *param )
{
    int required = 0;
    required |= info->csp       != param->i_csp;
    required |= info->width     != param->i_width;
    required |= info->height    != param->i_height;
    required |= info->fullrange != param->vui.b_fullrange;
    return required;
}

static int init( hnd_t *handle, cli_vid_filter_t *filter, video_info_t *info, x264_param_t *param, char *opt_string )
{
    int ret = 0;

    if( !opt_string )
        ret = full_check( info, param );
    else
    {
        if( !strcmp( opt_string, "normcsp" ) )
            ret = info->csp & X264_CSP_OTHER;
        else
            ret = -1;
    }

    /* pass if nothing needs to be done, otherwise fail */
    FAIL_IF_ERROR( ret, "not compiled with swscale support\n" );
    return 0;
}

#define help NULL
#define get_frame NULL
#define release_frame NULL
#define free_filter NULL
#define convert_csp_to_pix_fmt(x) (x & X264_CSP_MASK)

cli_vid_filter_t resize_filter = { NAME, help, init, get_frame, release_frame, free_filter, NULL };
