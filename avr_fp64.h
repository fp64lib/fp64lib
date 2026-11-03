/* Copyright (c) 2019-2020  Uwe Bissinger
   Copyright (c) 2007-2009  Detlef Schücker
   Copyright (c) 2007-2009  Florian Königstein

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

/* This file contains definitions to easily port code based on
   avr_f64.h / avr_f64.c to using fp64lib.

   Instead of
      #include "avr_f64.h"
   use
      #include "avr_fp64.h"

   All calls to avr_f64 routines will be replaced by calls to
   fp64lib routines.  Be aware of the following differences:

   * As fp64lib is provided as a library, where the compiler/linker will
     automatically only pull in the routines that are needed, the
        #define F_WITH_...
     are ignored. Also,
        #define F_PREFER_SMALL_BUT_SLOWER_CODE
     will have no effect as fp64lib code is already significandly smaller
     AND faster as it is written in assembly language, taking advantage of
     the AVR microprocessor architecture as much as possible.

   * fp64lib fully supports IEEE 754 denormalized numbers, avr_f64 interprets
     them as zero.

   * fp64lib handles and returns all kinds of IEEE NaNs (Not a Number),
     whereas avr_64 returns always/only 0x7fffffffffffffff as NaN.

   * fp64lib always and properly handles +INF and -INF, whereas avr_f64
     supports +/-INF only if F_ONLY_NAN_NO_INFINITY is NOT defined.

   * fp64lib uses different algorithms for sin/cos/tan and asin/acos/atan,
     so the results will differ slightly from avr_f64.

   * fp64lib uses a different algorithm for f_to_string, so the result will
     differ slightly.  In most cases, the string will fit better into the
     given length.

   Due to the use of assembly language, all routines are significandly faster
   than avr_f64 routines, in the range of factor 2 to 10 (-50% to -90%).
   Be aware to adjust your timing/delays, if your project uses some relative
   waiting routines.  Also, if you periodically run some floating point
   calculations on sensor data, your calculations could fail now, as some
   sensors will not provide you new data if the interval between two readings
   is too short.  */

#ifdef avr_f64_h_included
#error "Include either avr_f64.h or avr_fp64.h, but not both"
#endif

#ifndef avr_fp64_h_included
#define avr_fp64_h_included
#define avr_f64_h_included		// avoid including avr_f64.h

#include "fp64lib.h"

#ifdef __cplusplus
extern "C" {
#endif

#define	f_long_to_float64(n)			fp64_long_to_float64(x)
#define f_float64_to_long(x)			fp64_float64_to_long(x)
#define	f_sd(fx)						fp64_sd(fx)
#define f_ds(x)							fp64_ds(x)

#define	f_add(a, b)						fp64_add((a), (b))
#define f_sub(a, b)						fp64_sub((a), (b))
#define f_mult(a, b)					fp64_mul((a), (b))
#define f_div(a, b)						fp64_div((a), (b))

#define f_abs(x)						fp64_abs(x)
#define f_cut_noninteger_fraction(x)	fp64_cut_noninteger_fraction(x)
#define f_mod(x, y, ganz)


#define f_isnan(x)						fp64_isnan(x)
#define f_finite(x)						fp64_isfinite(x)
#define f_compare(a, b)					fp64_compare((a), (b))

#define f_to_decimalExp(x, maxDigits, expSep, exp10)	fp64_to_decimalExp((x), (maxDigits), (expSep), (exp10))
#define f_to_string(x, max_chars, max_zeroes)			fp64_to_string((x), (max_chars), (max_zeroes))
#define f_strtod(str, endptr)							fp64_strtod((str), (endptr))
#define f_atof(str) 									fp64_atof(str)

#define f_sqrt(x)						fp64_sqrt(x)
#define f_exp(x)						fp64_exp(x)
#define f_log(x)						fp64_log(x)
#define f_pow(x, y) 					fp64_pow((x), (y))

#define f_sin(x) 						fp64_sin(x)
#define f_cos(x) 						fp64_cos(x)
#define f_tan(x) 						fp64_tan(x)

#define f_arcsin(x) 					fp64_asin(x)
#define f_arccos(x) 					fp64_acos(x)
#define f_arctan(x) 					fp64_atan(x)

#ifdef __cplusplus
} // extern "C"
#endif

#endif //#ifndef avr_f64_h_included
