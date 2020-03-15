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

/* standard header for using 64-bit IEEE-754 compatible fp64lib
   should be included instead of math.h
   created for cooperation with math.h
*/

#ifndef __FP64_MATH_H
#define __FP64_MATH_H

#ifdef __cplusplus
extern "C"{
#endif 

#include <inttypes.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

/* TYPES */
#if defined(__HAVE_LONG_DOUBLE64__)
typedef long double float64_t;  /* IEEE 754 double precision floating point number */
typedef float       float32_t;  /* IEEE 754 single precision floating point number */
#else
typedef uint64_t float64_t;     /* IEEE 754 double precision floating point number */
typedef float    float32_t;     /* IEEE 754 single precision floating point number */
#endif

/* definitions that should be in float.h, but there is not float.h on avr gcc */
#define FLT_ROUNDS		1		/* round to nearest */
#define FLT_RADIX		2		/* base radix representation of the exponent */
#define FLT_MANT_DIG	23		/* number of bits in the number */
#define FLT_DIG			6		/* maximum number decimal digits (base-10) that can be represented without change after rounding */
#define FLT_MIN_EXP		(-126)	/* minimum negative integer value for an exponent in base FP64_RADIX */
#define FLT_MIN_10_EXP	(-37)	/* minimum negative integer value for an exponent in base 10 */
#define FLT_MAX_EXP		126		/* maximum integer value for an exponent in base FP64_RADIX */
#define FLT_MAX_10_EXP	37		/* maximum  integer value for an exponent in base 10 */
#define FLT_EPSILON		1e-9	/* least significant digit representable, 2^-23 */
#define FLT_MIN_10_EXP	1e-37 	/* minimum floating-point value */

// double on AVR is identical to float
#define DBL_ROUNDS		1		/* round to nearest */
#define DBL_RADIX		2		/* base radix representation of the exponent */
#define DBL_MANT_DIG	23		/* number of bits in the number */
#define DBL_DIG			6		/* maximum number decimal digits (base-10) that can be represented without change after rounding */
#define DBL_MIN_EXP		(-126)	/* minimum negative integer value for an exponent in base FP64_RADIX */
#define DBL_MIN_10_EXP	(-37)	/* minimum negative integer value for an exponent in base 10 */
#define DBL_MAX_EXP		126		/* maximum integer value for an exponent in base FP64_RADIX */
#define DBL_MAX_10_EXP	37		/* maximum  integer value for an exponent in base 10 */
#define DBL_EPSILON		1e-9	/* least significant digit representable, 2^-23 */
#define DBL_MIN_10_EXP	1e-37 	/* minimum floating-point value */

#define FP64_ROUNDS		1		/* round to nearest */
#define FP64_RADIX		2		/* base radix representation of the exponent */
#define FP64_MANT_DIG	53		/* number of bits in the number */
#define FP64_DIG		15		/* maximum number decimal digits (base-10) that can be represented without change after rounding */
#define FP64_MIN_EXP	(-1023) /* minimum negative integer value for an exponent in base FP64_RADIX */
#define FP64_MIN_10_EXP	(-308)	/* minimum negative integer value for an exponent in base 10 */
#define FP64_MAX_EXP	1023	/* maximum integer value for an exponent in base FP64_RADIX */
#define FP64_MAX_10_EXP	308		/* maximum  integer value for an exponent in base 10 */
#define FP64_EPSILON	((float64_t)0x3CB0000000000000LLU) /* least significant digit representable, 2^-52 = 2.2204460492503E-16 */
#define FP64_MIN_10_EXP	((float64_t)0x0010000000000000LLU) /* minimum floating-point value, 2^-1023 = 2.2250738585072E-308 */

/* some useful numbers */
#define float64_E 				((float64_t)0x4005bf0a8b145769LLU)	// 2.7182818284590452
#define float64_PI 				((float64_t)0x400921fb54442d18LLU)  // 3.1415926535897932
#define float64_PIO2			((float64_t)0x3ff921fb54442d18LLU)  // 3.1415926535897932/2
#define float64_2PI				((float64_t)0x401921fb54442d18LLU)  // 3.1415926535897932*2
#define float64_ONE				((float64_t)0x3ff0000000000000LLU)	// 1.0
#define float64_MINUS_ONE		((float64_t)0xbff0000000000000LLU)	// -1.0
#define float64_ZERO			((float64_t)0x0000000000000000LLU)	// 0.0
#define float64_PLUS_ZERO		((float64_t)0x0000000000000000LLU)	// 0.0
#define float64_MINUS_ZERO		((float64_t)0x8000000000000000LLU)	// 0.0
#define float64_PLUS_INFINITY	((float64_t)0x7ff0000000000000LLU)	// +INF
#define float64_MINUS_INFINITY	((float64_t)0xfff0000000000000LLU)	// -INF

/* MACROS */
#define FP64_HUGE_VAL 			((float64_t)0x7ff0000000000000LLU)	/* +INF */
#define FP64_INFINITY 			((float64_t)0x7ff0000000000000LLU)	/* +INF */
#define FP64_NAN 				((float64_t)0x7fffffffffffffffLLU)	/* NaN, be aware that there are also other 
															  representations of NaN, 
															  use if( fp64_isnan(x) ) to check for NaN, 
															  !!! never use if( x == NaN )!!! */

#define FP_FAST_FMA 	1	// fp64_fma executes about as fast as the expression x * y + z

/* return values for fpclassify */
#define FP_INFINITE		2
#define FP_NAN			1
#define FP_NORMAL		4
#define FP_SUBNORMAL	3
#define FP_ZERO			0

#define FP_ILOGB0 <integer constant expression> [added with C99]
#define FP_ILOGBNAN <integer constant expression> [added with C99]

#define MATH_ERRNO       1
#define MATH_ERREXCEPT   2
#define math_errhandling 0	/* fp64lib uses silent signalling, errno is not used */

/* GENERIC FUNCTION MACROS */
// unfortunately, math.h defined functions for the is... macros, 
// we can only overload the is...f macros so
#undef signbitf
#undef isfinitef
#undef isinff
#undef isnanf
#define signbitf(x) 		(sizeof(x) == 4 ? signbit(x) : fp64_signbit(x))
#define fpclassify(x)		fp64_classify(x)
#define isfinitef(x)		(sizeof(x) == 4 ? isfinite(x) : fp64_isfinite(x))
#define isinff(x) 			(sizeof(x) == 4 ? isinf(x) : fp64_isinf(x))
#define isnanf(x) 			(sizeof(x) == 4 ? isnan(x) : fp64_isnan(x))
#define isnormal(x) 		(fp64_classify(x) == FP_NORMAL)

#define isgreater(x, y) 		((isnan(x) || isnan(y)) ? 0 : __fp64_gtsd2(x,y))
#define isgreaterequal(x, y) 	((isnan(x) || isnan(y)) ? 0 : __fp64_gesd2(x,y))
#define isless(x, y) 			((isnan(x) || isnan(y)) ? 0 : __fp64_ltsd2(x,y))
#define islessequal(x, y) 		((isnan(x) || isnan(y)) ? 0 : __fp64_lesd2(x,y))
#define islessgreater(x, y) 	((isnan(x) || isnan(y)) ? 0 : __fp64_nesd2(x,y))
#define isunordered(x, y) 		((isnan(x) || isnan(y)) ? 1 : 0)

// basic mathematic functions
float64_t fp64_add( float64_t a, float64_t b );
float64_t fp64_sub( float64_t a, float64_t b );
float64_t fp64_mul( float64_t a, float64_t b );
float64_t fp64_div( float64_t a, float64_t b );
float64_t fp64_neg( float64_t x );
float64_t fp64_inverse( float64_t x );

/* FUNCTIONS */
float64_t fp64_abs(float64_t x);
float64_t fp64_acos(float64_t x);
float64_t fp64_asin(float64_t x);
float64_t fp64_atan(float64_t x);
float64_t fp64_atan2(float64_t y, float64_t x);
float64_t fp64_cbrt(float64_t x); [all added with C99]
float64_t fp64_ceil(float64_t x);
int8_t fp64_compare( float64_t x, float64_t b);
float64_t fp64_copysign(float64_t x, float64_t y); [all added with C99]
float64_t fp64_cos(float64_t x);
float64_t fp64_cosh(float64_t x);
float64_t fp64_cotan(float64_t x);
float64_t fp64_exp(float64_t x);
float64_t fp64_exp10(float64_t x);
float64_t fp64_fabs(float64_t x);
//float64_t fabs(long float64_t x);
float64_t fp64_fdim(float64_t x, float64_t y);
float64_t fp64_floor(float64_t x);
float64_t fp64_fma(float64_t x, float64_t y, float64_t z);
float64_t fp64_fmax(float64_t x, float64_t y); [all added with C99]
float64_t fp64_fmin(float64_t x, float64_t y); [all added with C99]
float64_t fp64_fmod(float64_t x, float64_t y);
float64_t fp64_frexp(float64_t x, int *pexp);
float64_t fp64_hypot(float64_t x, float64_t y); [all added with C99]
float64_t fp64_ldexp(float64_t x, int ex);
long fp64_lrint(float64_t x);
long fp64_lround(float64_t x);
float64_t fp64_log(float64_t x);
float64_t fp64_log10(float64_t x);
float64_t fp64_log2(float64_t x);
float64_t fp64_modf(float64_t x, float64_t *pint);
float64_t fp64_pow(float64_t x, float64_t y);
float64_t fp64_round(float64_t x);
float64_t fp64_sin(float64_t x);
float64_t fp64_sinh(float64_t x);
float64_t fp64_square( float64_t x );
float64_t fp64_sqrt(float64_t x);
float64_t fp64_tan(float64_t x);
float64_t fp64_tanh(float64_t x);
float64_t fp64_trunc(float64_t x);

/* FUNCTIONS of C99 standard, not supported by fp64lib */
// float64_t acosh(float64_t x); [all added with C99]
// float64_t asinh(float64_t x); [all added with C99]
// float64_t atanh(float64_t x); [all added with C99]
// float64_t erf(float64_t x); [all added with C99]
// float64_t erfc(float64_t x); [all added with C99]
// float64_t exp2(float64_t x); [all added with C99]
// float64_t expm1(float64_t x); [all added with C99]
// int ilogb(float64_t x); [all added with C99]
// float64_t lgamma(float64_t x); [all added with C99]
// long long llrint(float64_t x); [all added with C99]
// long long llround(float64_t x); [all added with C99]
// float64_t log1p(float64_t x); [all added with C99]
// float64_t log2(float64_t x); [all added with C99]
// float64_t logb(float64_t x); [all added with C99]
// float64_t nan(const char *str); [all added with C99]
// float64_t nearbyint(float64_t x); [all added with C99]
// float64_t nextafter(float64_t x, float64_t y); [all added with C99]
// float64_t nexttoward(float64_t x, long float64_t y); [all added with C99]
// float64_t remainder(float64_t x, float64_t y); [all added with C99]
// float64_t remquo(float64_t x, float64_t y, int *pquo); [all added with C99]
// float64_t rint(float64_t x); [all added with C99]
// float64_t scalbln(float64_t x, long ex); [all added with C99]
// float64_t scalbn(float64_t x, int ex); [all added with C99]
// float64_t tgamma(float64_t x); [all added with C99]
#ifdef __cplusplus
} // extern "C"
#endif 
#endif 