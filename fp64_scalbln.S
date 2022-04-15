/* Copyright (c) 2019-2020  Uwe Bissinger
   Based on 32bit floating point arithmetic routines which is:
   Copyright (c) 2002  Michael Stumpf  <mistumpf@de.pepperl-fuchs.com>
   Copyright (c) 2006  Dmitry Xmelkov
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

#if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

/*
   float64_t fp64_scalbln (float64_t x, long n)
   fp64_scalbln behaves identical to fp64_ldexp() or fp64_scalbn,
   but can be called with n being of type long instead of int.

   The fp64_ldexp() function returns the result of multiplying the
   floating-point number x by 2 raised to the power n.
  The following rules apply:

	case|           x	        | result
	----+-----------------------+------------
	  1 |          NaN          | NaN
	  2 |         +/-Inf        | +/- Inf
	  3 |         +/-0.0	    | +/- 0.0
	  4 | exponent(x)+n > 1023  | +/- Inf (Overflow)
	  5 | exponent(x)+n <-1074  | +/- 0.0 (Underflow)
	  6 | exponent(x)+n <-1023  | x*2^exp as subnormal number
	  7 | exponent(x)+n >=-1023 | x*2^exp
  
 */

FUNCTION fp64_ldexp

.L_Inf:
	XJMP _U(__fp64_inf)			; case 2: return +/-Inf

.L_szero:
	bst rA7, 7					; save sign
	rcall __fp64_saveAB
	XJMP _U(__fp64_szero)		; case 3: return +0

/* float64_t fp64_scalbln (float64_t x, long n)
   fp64_scalbln behaves identical to fp64_ldexp() or fp64_scalbn,
   but can be called with n being of type long instead of int.
*/
ENTRY fp64_scalbln
GCC_ENTRY __scalbln
	rcall __fp64_saveAB
	
	; check for INF or NAN
	bst rA7, 7					; save sign
	andi rA7, 0x7f
	
	; check for INF or NaN
	cpi rA7, 0x7f
	brne 1f						; not INF or NaN, check for 0
	cpi rA6, 0xf0
	brlo 2f						; just a regular very high number
	brne .L_NaN					; case 1: it's a NaN --> return it
	XCALL _U(__fp64_cpc0A5)		; check whether it is really INF or another NaN
	breq .L_Inf					; case 3: INF --> return it
	
	; case 1: number is NaN, return it
.L_NaN:
	ret
	
1:	; check for 0
	XCALL _U(__fp64_cpc0A5)
	brne 2f
	cpc r1, rA6
	cpc r1, rA7
	bld rA7, 7					; restore sign of x
	breq .L_szero				; case 3: return 0.0, independant of n

2:	; handle regular numbers
	; check for huge n outside the range of integer, i.e. |n| > 0x7fff
	bld rA7, 7					; restore sign of x
	; rcall __fp64_saveAB
	tst rB7
	brmi 3f						; test for huge negative values
	tst rB7
	brne .L_Inf					; n > 0xffffff --> return INF or 0.0
	tst rB6
	brne .L_Inf					; n > 0xffff --> return INF or 0.0
	tst rB5
	brmi .L_Inf					; n > 0x7fff --> return INF or 0.0
	rjmp .L_common				; n fits in int, let fp64_ldexp handle the rest

3:	; check for huge negative values, lead to underflow, i.e. +/-0
	bst	rB7, 7					; save sign of n

	inc rB7
	brne .L_szero				; n < 0xff000000 --> return +/-0.0
	inc rB6
	brne .L_szero				; n < -0xffff --> return +/-0.0
	tst rB5
	rcall __fp64_saveAB
	brpl .L_szero				; -0xffff <= n < -0x7fff --> return +/-0.0
	ldi XL, 0x80
	cp rB5, XL
	breq .L_szero
	
	; n fits in int, handle sign bit correctly
	bld rB5, 7

.L_common:
	; n fits in int, move relevant bits of long n to int name
	movw rB6, rB4
	; let fp64_ldexp handle the rest
	XJMP _U(fp64_ldexp)
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
