/*****************************************************************************
 * cpu.c: cpu detection
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

#include "base.h"

#if HAVE_POSIXTHREAD && SYS_LINUX
#include <sched.h>
#endif
#if SYS_BEOS
#include <kernel/OS.h>
#endif
#if SYS_MACOSX || SYS_FREEBSD
#include <sys/types.h>
#include <sys/sysctl.h>
#endif
#if SYS_OPENBSD
#include <sys/param.h>
#include <sys/sysctl.h>
#include <machine/cpu.h>
#endif

const x264_cpu_name_t x264_cpu_names[] =
{
#define MMX2 X264_CPU_MMX|X264_CPU_MMX2
    {"MMX2",        MMX2},
    {"MMXEXT",      MMX2},
    {"SSE",         MMX2|X264_CPU_SSE},
#define SSE2 MMX2|X264_CPU_SSE|X264_CPU_SSE2
    {"SSE2Slow",    SSE2|X264_CPU_SSE2_IS_SLOW},
    {"SSE2",        SSE2},
    {"SSE2Fast",    SSE2|X264_CPU_SSE2_IS_FAST},
    {"LZCNT",       SSE2|X264_CPU_LZCNT},
    {"SSE3",        SSE2|X264_CPU_SSE3},
    {"SSSE3",       SSE2|X264_CPU_SSE3|X264_CPU_SSSE3},
    {"SSE4.1",      SSE2|X264_CPU_SSE3|X264_CPU_SSSE3|X264_CPU_SSE4},
    {"SSE4",        SSE2|X264_CPU_SSE3|X264_CPU_SSSE3|X264_CPU_SSE4},
    {"SSE4.2",      SSE2|X264_CPU_SSE3|X264_CPU_SSSE3|X264_CPU_SSE4|X264_CPU_SSE42},
#define AVX SSE2|X264_CPU_SSE3|X264_CPU_SSSE3|X264_CPU_SSE4|X264_CPU_SSE42|X264_CPU_AVX
    {"AVX",         AVX},
    {"XOP",         AVX|X264_CPU_XOP},
    {"FMA4",        AVX|X264_CPU_FMA4},
    {"FMA3",        AVX|X264_CPU_FMA3},
    {"BMI1",        AVX|X264_CPU_LZCNT|X264_CPU_BMI1},
    {"BMI2",        AVX|X264_CPU_LZCNT|X264_CPU_BMI1|X264_CPU_BMI2},
#define AVX2 AVX|X264_CPU_FMA3|X264_CPU_LZCNT|X264_CPU_BMI1|X264_CPU_BMI2|X264_CPU_AVX2
    {"AVX2",        AVX2},
    {"AVX512",      AVX2|X264_CPU_AVX512},
#undef AVX2
#undef AVX
#undef SSE2
#undef MMX2
    {"Cache32",         X264_CPU_CACHELINE_32},
    {"Cache64",         X264_CPU_CACHELINE_64},
    {"SlowAtom",        X264_CPU_SLOW_ATOM},
    {"SlowPshufb",      X264_CPU_SLOW_PSHUFB},
    {"SlowPalignr",     X264_CPU_SLOW_PALIGNR},
    {"SlowShuffle",     X264_CPU_SLOW_SHUFFLE},
    {"UnalignedStack",  X264_CPU_STACK_MOD4},
    {"", 0},
};

int x264_cpu_cpuid_test( void );
void x264_cpu_cpuid( uint32_t op, uint32_t *eax, uint32_t *ebx, uint32_t *ecx, uint32_t *edx );
uint64_t x264_cpu_xgetbv( int xcr );

uint32_t x264_cpu_detect( void )
{
    uint32_t cpu = 0;
    uint32_t eax, ebx, ecx, edx;
    uint32_t vendor[4] = {0};
    uint32_t max_extended_cap, max_basic_cap;

    x264_cpu_cpuid( 0, &max_basic_cap, vendor+0, vendor+2, vendor+1 );
    if( max_basic_cap == 0 )
        return 0;

    x264_cpu_cpuid( 1, &eax, &ebx, &ecx, &edx );
    if( edx&0x00800000 )
        cpu |= X264_CPU_MMX;
    else
        return cpu;
    if( edx&0x02000000 )
        cpu |= X264_CPU_MMX2|X264_CPU_SSE;
    if( edx&0x04000000 )
        cpu |= X264_CPU_SSE2;
    if( ecx&0x00000001 )
        cpu |= X264_CPU_SSE3;
    if( ecx&0x00000200 )
        cpu |= X264_CPU_SSSE3|X264_CPU_SSE2_IS_FAST;
    if( ecx&0x00080000 )
        cpu |= X264_CPU_SSE4;
    if( ecx&0x00100000 )
        cpu |= X264_CPU_SSE42;

    if( ecx&0x08000000 ) /* XGETBV supported and XSAVE enabled by OS */
    {
        uint64_t xcr0 = x264_cpu_xgetbv( 0 );
        if( (xcr0&0x6) == 0x6 ) /* XMM/YMM state */
        {
            if( ecx&0x10000000 )
                cpu |= X264_CPU_AVX;
            if( ecx&0x00001000 )
                cpu |= X264_CPU_FMA3;

            if( max_basic_cap >= 7 )
            {
                x264_cpu_cpuid( 7, &eax, &ebx, &ecx, &edx );
                if( ebx&0x00000008 )
                    cpu |= X264_CPU_BMI1;
                if( ebx&0x00000100 )
                    cpu |= X264_CPU_BMI2;
                if( ebx&0x00000020 )
                    cpu |= X264_CPU_AVX2;

                if( (xcr0&0xE0) == 0xE0 ) /* OPMASK/ZMM state */
                {
                    if( (ebx&0xD0030000) == 0xD0030000 )
                        cpu |= X264_CPU_AVX512;
                }
            }
        }
    }

    x264_cpu_cpuid( 0x80000000, &eax, &ebx, &ecx, &edx );
    max_extended_cap = eax;

    if( max_extended_cap >= 0x80000001 )
    {
        x264_cpu_cpuid( 0x80000001, &eax, &ebx, &ecx, &edx );

        if( ecx&0x00000020 )
            cpu |= X264_CPU_LZCNT;             /* Supported by Intel chips starting with Haswell */
        if( ecx&0x00000040 ) /* SSE4a, AMD only */
        {
            int family = ((eax>>8)&0xf) + ((eax>>20)&0xff);
            cpu |= X264_CPU_SSE2_IS_FAST;      /* Phenom and later CPUs have fast SSE units */
            if( family == 0x14 )
            {
                cpu &= ~X264_CPU_SSE2_IS_FAST; /* SSSE3 doesn't imply fast SSE anymore... */
                cpu |= X264_CPU_SSE2_IS_SLOW;  /* Bobcat has 64-bit SIMD units */
                cpu |= X264_CPU_SLOW_PALIGNR;  /* palignr is insanely slow on Bobcat */
            }
            if( family == 0x16 )
            {
                cpu |= X264_CPU_SLOW_PSHUFB;   /* Jaguar's pshufb isn't that slow, but it's slow enough
                                                * compared to alternate instruction sequences that this
                                                * is equal or faster on almost all such functions. */
            }
        }

        if( cpu & X264_CPU_AVX )
        {
            if( ecx&0x00000800 ) /* XOP */
                cpu |= X264_CPU_XOP;
            if( ecx&0x00010000 ) /* FMA4 */
                cpu |= X264_CPU_FMA4;
        }

        if( !strcmp((char*)vendor, "AuthenticAMD") )
        {
            if( edx&0x00400000 )
                cpu |= X264_CPU_MMX2;
            if( (cpu&X264_CPU_SSE2) && !(cpu&X264_CPU_SSE2_IS_FAST) )
                cpu |= X264_CPU_SSE2_IS_SLOW; /* AMD CPUs come in two types: terrible at SSE and great at it */
        }
    }

    if( !strcmp((char*)vendor, "GenuineIntel") )
    {
        x264_cpu_cpuid( 1, &eax, &ebx, &ecx, &edx );
        int family = ((eax>>8)&0xf) + ((eax>>20)&0xff);
        int model  = ((eax>>4)&0xf) + ((eax>>12)&0xf0);
        if( family == 6 )
        {
            /* Detect Atom CPU */
            if( model == 28 )
            {
                cpu |= X264_CPU_SLOW_ATOM;
                cpu |= X264_CPU_SLOW_PSHUFB;
            }
            /* Conroe has a slow shuffle unit. Check the model number to make sure not
             * to include crippled low-end Penryns and Nehalems that don't have SSE4. */
            else if( (cpu&X264_CPU_SSSE3) && !(cpu&X264_CPU_SSE4) && model < 23 )
                cpu |= X264_CPU_SLOW_SHUFFLE;
        }
    }

    if( (!strcmp((char*)vendor, "GenuineIntel") || !strcmp((char*)vendor, "CyrixInstead")) && !(cpu&X264_CPU_SSE42))
    {
        /* cacheline size is specified in 3 places, any of which may be missing */
        x264_cpu_cpuid( 1, &eax, &ebx, &ecx, &edx );
        int cache = (ebx&0xff00)>>5; // cflush size
        if( !cache && max_extended_cap >= 0x80000006 )
        {
            x264_cpu_cpuid( 0x80000006, &eax, &ebx, &ecx, &edx );
            cache = ecx&0xff; // cacheline size
        }
        if( !cache && max_basic_cap >= 2 )
        {
            // Cache and TLB Information
            static const char cache32_ids[] = { 0x0a, 0x0c, 0x41, 0x42, 0x43, 0x44, 0x45, 0x82, 0x83, 0x84, 0x85, 0 };
            static const char cache64_ids[] = { 0x22, 0x23, 0x25, 0x29, 0x2c, 0x46, 0x47, 0x49, 0x60, 0x66, 0x67,
                                                0x68, 0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7c, 0x7f, 0x86, 0x87, 0 };
            uint32_t buf[4];
            int max, i = 0;
            do {
                x264_cpu_cpuid( 2, buf+0, buf+1, buf+2, buf+3 );
                max = buf[0]&0xff;
                buf[0] &= ~0xff;
                for( int j = 0; j < 4; j++ )
                    if( !(buf[j]>>31) )
                        while( buf[j] )
                        {
                            if( strchr( cache32_ids, buf[j]&0xff ) )
                                cache = 32;
                            if( strchr( cache64_ids, buf[j]&0xff ) )
                                cache = 64;
                            buf[j] >>= 8;
                        }
            } while( ++i < max );
        }

        if( cache == 32 )
            cpu |= X264_CPU_CACHELINE_32;
        else if( cache == 64 )
            cpu |= X264_CPU_CACHELINE_64;
        else
            x264_log_internal( X264_LOG_WARNING, "unable to determine cacheline size\n" );
    }

#if STACK_ALIGNMENT < 16
    cpu |= X264_CPU_STACK_MOD4;
#endif

    return cpu;
}

int x264_cpu_num_processors( void )
{
#if !HAVE_THREAD
    return 1;

#elif SYS_WINDOWS
    return x264_pthread_num_processors_np();

#elif SYS_CYGWIN || SYS_SunOS
    return sysconf( _SC_NPROCESSORS_ONLN );

#elif SYS_LINUX
#ifdef __ANDROID__
    // Android NDK does not expose sched_getaffinity
    return sysconf( _SC_NPROCESSORS_CONF );
#else
    cpu_set_t p_aff;
    memset( &p_aff, 0, sizeof(p_aff) );
    if( sched_getaffinity( 0, sizeof(p_aff), &p_aff ) )
        return 1;
#if HAVE_CPU_COUNT
    return CPU_COUNT(&p_aff);
#else
    int np = 0;
    for( unsigned int bit = 0; bit < 8 * sizeof(p_aff); bit++ )
        np += (((uint8_t *)&p_aff)[bit / 8] >> (bit % 8)) & 1;
    return np;
#endif
#endif

#elif SYS_BEOS
    system_info info;
    get_system_info( &info );
    return info.cpu_count;

#elif SYS_MACOSX || SYS_FREEBSD || SYS_OPENBSD
    int ncpu;
    size_t length = sizeof( ncpu );
#if SYS_OPENBSD
    int mib[2] = { CTL_HW, HW_NCPU };
    if( sysctl(mib, 2, &ncpu, &length, NULL, 0) )
#else
    if( sysctlbyname("hw.ncpu", &ncpu, &length, NULL, 0) )
#endif
    {
        ncpu = 1;
    }
    return ncpu;

#else
    return 1;
#endif
}
