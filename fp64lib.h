/* Copyright (c) 2019-2020  Uwe Bissinger
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

   * Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in
     the documentation and/or other materials provided with the
     distribution.
   * Neither the name of the copyright holders nor the names of
     contributors may be used to endorse or promote products derived
     from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
   POSSIBILITY OF SUCH DAMAGE. */

/* $Id$ */

/* IEEE float format single
   Bit 31: sign 0 = + / 1 = -
   Bits 30-23: exponent -126 <= e <= 127, base 127
   Bits 23-0: mantissa
   31   27    23   19    15   11    7    3
   7  4 3  0  7  4 3  0  7  4 3  0  7  4 3  0
   SEEE EEEE  EMMM MMMM  MMMM MMMM  MMMM MMMM

   IEEE float format double
   Bit 63: sign S 0 = + / 1 = -
   Bits 62-51: exponent E -1022 <= e <= 1023, base 1023
   Bits 51-0: mantissa M without leading 1 bit at 52
   63   59    55   51    47   43   ... 7    3
   7  4 3  0  7  4 3  0  7  4 3  0 ... 7  4 3  0
   SEEE EEEE  EEEE MMMM  MMMM MMMM ... MMMM MMMM
   
   Interpretations:
   E = 0		M = 0	--> +/- 0 (zero)
   E = 0		M > 0	--> +/- 0,M*2^(-1022)	denormalized numbers
   0<E< 2046	M >= 0	--> +/- 1,M*2^(E-1023)	normal numbers
   E = 2047		M = 0	--> +/- Inf				infinity
   E = 2047		M > 0	--> NaN					not a number
   
   fp64lib functions do not raise exceptions and do not change the
   errno variable. Therefore the majority of them are declared
   with const attribute as "do not examine any values except their
   arguments, and have no effects except the return value", for better
   optimization by GCC.
*/

#ifndef fp64lib_h_included
#define fp64lib_h_included

#ifdef __cplusplus
extern "C"{
#endif 

#ifndef __ATTR_CONST__
# define __ATTR_CONST__ __attribute__((__const__))
#endif

#include <inttypes.h>
#include <stdlib.h>
#include <string.h>

typedef uint64_t float64_t; /* IEEE 754 double precision floating point number */
typedef float    float32_t; /* IEEE 754 single precision floating point number */

#define float64_EULER_E 							((float64_t)0x4005bf0a8b145769LLU)	// 2.7182818284590452
#define float64_NUMBER_PI 							((float64_t)0x400921fb54442d18LLU)  // 3.1415926535897932
#define float64_NUMBER_PIO2							((float64_t)0x3ff921fb54442d18LLU)  // 3.1415926535897932/2
#define float64_NUMBER_2PI							((float64_t)0x401921fb54442d18LLU)  // 3.1415926535897932*2
#define float64_NUMBER_ONE							((float64_t)0x3ff0000000000000LLU)	// 1.0
#define float64_MINUS_NUMBER_ONE					((float64_t)0xbff0000000000000LLU)	// 1.0
#define float64_NUMBER_PLUS_ZERO					((float64_t)0x0000000000000000LLU)	// 0.0
#define float64_ONE_POSSIBLE_NAN_REPRESENTATION		((float64_t)0x7fffffffffffffffLLU)	// NaN
#define float64_PLUS_INFINITY						((float64_t)0x7ff0000000000000LLU)	// +INF
#define float64_MINUS_INFINITY						((float64_t)0xfff0000000000000LLU)	// -INF

/* return values for fpclassify */
#define FP_INFINITE		2
#define FP_NAN			1
#define FP_NORMAL		4
#define FP_SUBNORMAL	3
#define FP_ZERO			0

// basic mathematic functions
float64_t fp64_add( float64_t a, float64_t b ) __ATTR_CONST__;
float64_t fp64_sub( float64_t a, float64_t b ) __ATTR_CONST__;
float64_t fp64_mul( float64_t a, float64_t b ) __ATTR_CONST__;
float64_t fp64_div( float64_t a, float64_t b ) __ATTR_CONST__;
float64_t fp64_fmod( float64_t a, float64_t b ) __ATTR_CONST__;
float64_t fp64_fmodn( float64_t a, float64_t b, unsigned long *np ) __ATTR_CONST__;

// isXXX  & compare functions
int fp64_classify( float64_t x ) __ATTR_CONST__;
int fp64_isinf( float64_t x) __ATTR_CONST__;
int fp64_isnan( float64_t x) __ATTR_CONST__;
int fp64_isfinite( float64_t x) __ATTR_CONST__;
int8_t fp64_compare( float64_t x, float64_t b) __ATTR_CONST__;
int fp64_signbit (float64_t x) __ATTR_CONST__;
float64_t fp64_fmin(float64_t x, float64_t y) __ATTR_CONST__;
float64_t fp64_fmax(float64_t x, float64_t y) __ATTR_CONST__;

// basic functions with 1 argument
float64_t fp64_neg( float64_t x ) __ATTR_CONST__;
float64_t fp64_abs( float64_t x ) __ATTR_CONST__;
float64_t fp64_inverse( float64_t x ) __ATTR_CONST__;
float64_t fp64_sqrt( float64_t x ) __ATTR_CONST__;
float64_t fp64_square( float64_t x ) __ATTR_CONST__;
float64_t fp64_trunc( float64_t x ) __ATTR_CONST__;
float64_t fp64_cut_noninteger_fraction( float64_t x ) __ATTR_CONST__; //alias to fp64_trunc
float64_t fp64_ceil( float64_t x ) __ATTR_CONST__;
float64_t fp64_floor( float64_t x ) __ATTR_CONST__;
float64_t fp64_round( float64_t x ) __ATTR_CONST__;
long fp64_lround( float64_t A ) __ATTR_CONST__;
long fp64_lrint( float64_t A ) __ATTR_CONST__;
float64_t fp64_cbrt( float64_t x ) __ATTR_CONST__;

// trigonometric functions
float64_t fp64_sin( float64_t x ) __ATTR_CONST__;
float64_t fp64_cos( float64_t x ) __ATTR_CONST__;
float64_t fp64_tan( float64_t x ) __ATTR_CONST__;
float64_t fp64_cotan( float64_t x ) __ATTR_CONST__;
float64_t fp64_atan( float64_t x ) __ATTR_CONST__;
float64_t fp64_asin( float64_t x ) __ATTR_CONST__;
float64_t fp64_acos( float64_t x ) __ATTR_CONST__;
float64_t fp64_log( float64_t x ) __ATTR_CONST__;
float64_t fp64_exp( float64_t x ) __ATTR_CONST__;
float64_t fp64_log10( float64_t x ) __ATTR_CONST__;
float64_t fp64_log2( float64_t x ) __ATTR_CONST__;
float64_t fp64_exp10( float64_t x ) __ATTR_CONST__;
float64_t fp64_pow10( float64_t x ) __ATTR_CONST__;
float64_t fp64_sinh( float64_t x ) __ATTR_CONST__;
float64_t fp64_cosh( float64_t x ) __ATTR_CONST__;
float64_t fp64_tanh( float64_t x ) __ATTR_CONST__;
float64_t fp64_fmodx_pi2( float64_t x, unsigned long *np ) __ATTR_CONST__;

// functions with 2 arguments
float64_t fp64_ldexp( float64_t x, int exp ) __ATTR_CONST__;
float64_t fp64_frexp( float64_t x, int *pexp ) __ATTR_CONST__;
float64_t fp64_fdim( float64_t A, float64_t B ) __ATTR_CONST__;
float64_t fp64_pow( float64_t x, float64_t y ) __ATTR_CONST__;
float64_t fp64_hypot( float64_t x, float64_t y ) __ATTR_CONST__;
float64_t fp64_atan2( float64_t y, float64_t x ) __ATTR_CONST__;
float64_t fp64_modf (float64_t x, float64_t *iptr);

// functions with 3 arguments
float64_t fp64_fma (float64_t A, float64_t B, float64_t C) __ATTR_CONST__;

// conversion functions
float64_t fp64_int64_to_float64( long long x ) __ATTR_CONST__;	// (signed) long long to float64_t
float64_t fp64_int32_to_float64( long x) __ATTR_CONST__;		// (signed) long to float64_t
float64_t fp64_long_to_float64( long x ) __ATTR_CONST__;		// alias to fp64_int32_to_float64
float64_t fp64_uint16_to_float64( uint16_t x ) __ATTR_CONST__;	// unsigned short to float64_t
float64_t fp64_int16_to_float64( int16_t x) __ATTR_CONST__;		// (signed) short to float64_t

float64_t fp64_uint64_to_float64( unsigned long long x ) __ATTR_CONST__;// unsigned long long to float64_t
float64_t fp64_uint32_to_float64( unsigned long x ) __ATTR_CONST__;		// unsigned long to float64_t

long long fp64_to_int64( float64_t A) __ATTR_CONST__;			// float_t to int64_t
long 	  fp64_to_int32( float64_t A) __ATTR_CONST__;			// float_t to int32_t
int 	  fp64_to_int16( float64_t A) __ATTR_CONST__;			// float_t to int16_t
char 	  fp64_to_int8( float64_t A) __ATTR_CONST__;			// float_t to int8_t
long 	  fp64_float64_to_long( float64_t A) __ATTR_CONST__;	// alias to fp64_to_int32

unsigned long long fp64_to_uint64( float64_t A) __ATTR_CONST__;	// float_t to uint64_t
unsigned long 	   fp64_to_uint32( float64_t A) __ATTR_CONST__;	// float_t to uint32_t
unsigned int 	   fp64_to_uint16( float64_t A) __ATTR_CONST__;	// float_t to uint16_t
unsigned char 	   fp64_to_uint8( float64_t A) __ATTR_CONST__; 	// float_t to uint8_t

float64_t fp64_sd( float x ) __ATTR_CONST__;					// float to float64_t
float fp64_ds( float64_t x ) __ATTR_CONST__;					// float64_t to float

// to and from string
char *fp64_to_decimalExp( float64_t x, uint8_t maxDigits, uint8_t expSep, int16_t *exp10 );
char *fp64_to_string( float64_t x, uint8_t max_nr_chars, uint8_t max_leading_mantisse_zeros );
float64_t fp64_atof( char *str );
float64_t fp64_strtod( char *str, char **endptr );

#include "fp64def.h"

#ifdef __cplusplus
} // extern "C"
#endif

#endif
