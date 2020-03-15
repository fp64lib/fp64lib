/* Copyright (c) 2019-2020  Uwe Bissinger
   Based on 32bit floating point arithmetic routines which are:
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

/* float64_t fp64_pow(float64_t x, float64_t y);
     The fp64_pow() function returns the value of x raised to the power of y.

	A \ B|  NaN | +Inf | -Inf |  +0  |  -0  |  +1  | odd>0| any>0| odd<0| any<0 
	-----+------+------+------+------+------+------+------+------+------+------+
	NaN  |      |      |      | +1  a|      | NaN c|      |      |      |      |
	+Inf |      |      |      | +1  a|      |+Inf c|      |      |      |      |
	+0.0 |      |      |      | +1  a|      |+0.0 c|      |      |      |      |
	+1.0 | +1  b| +1  b| +1  b| +1  a| +1  b| +1  c| +1  b| +1  b| +1  b| +1  b|
	> 0  | NaN L|+Inf L| +0  L| +1  L| +1  L|  A  c|  n/a | x^y L| n/a  | x^y L|
	<=-0 | NaN  | NaN  | NaN  | +1  a| NaN  |  A  c| NaN  | NaN  | NaN  | NaN  |
	Not yet implemented:                     
	-0.0 |     d|     d|     d| +1  a|     d|-0.0 c|     d|     d|     d|     d|
	-1.0 |     e|     e|     e| +1  a|     e|-1.0 c|     e|     e|     e|     e|
	-Inf |     f|     f|     f| +1  a|     f|-Inf c|     f|     f|     f|     f|

	remark | method to calculate result
	-------+----------------------------
	   a   | direct check
	   b   | direct check
	   c   | direct check
	   d   | check for integral value
	   e   | check for integral value
	   L   | computed via x^y = exp(log(x)*y)
 */

FUNCTION fp64_pow
.L_one:
	XJMP _U(__fp64_one)			; case 1: return 1.0 for y == 0.0

ENTRY fp64_pow
GCC_ENTRY __pow
	; ZH.ZL := exponent of y without sign
	movw ZL, rB6				; save exponent and sign
	andi ZH, 0x7f				; get rid of sign bit
	XCALL _U(__fp64_isBzero)	
	cpc ZH, r1					; __fp64_isBzero only checks for rB6..rB0
	breq	.L_one				; y == 0? Yes, case a: return x^+/-0 = +1.0

	; preliminary check for significand of A == 0
	ldi	ZL, 0x3f

	XCALL _U(__fp64_cpc0A5)
	brne 0f						; skip a bit of comparisons
	
	; x == +1.0 ?
	cpi	rA6, 0xf0
	cpc	rA7, ZL
	breq .L_ret					; x == +1.0? Yes, case b: return +1^any = +1.0
	
	; y == 1.0 ?
0:	cpi rB6, 0xf0
	; rcall __fp64_saveAB
	cpc rB7, ZL
	cpc	rB0, r1
	cpc	rB1, r1
	cpc	rB2, r1
	cpc	rB3, r1
	cpc	rB4, r1
	cpc	rB5, r1
	;rcall __fp64_saveAB
	breq .L_ret					; y == +1.0? Yes, case c: return any^1 = any
	
	; x >= 0 ?
	tst	rA7
	brpl .L_pow					; yes, compute x^y via exp(log(x)*y)

.L_nan:							; no, return NaN
	XJMP	_U(__fp64_nan)

	; result is in rA7...rA0 --> return it
.L_ret:
	ret

	; routine for calculating pow(abs(A)) = abs(A)^B = exp(log(abs(A))*B)
.L_pow:
	andi	rA7, 0x7f
	XCALL _U(__fp64_pushB)
	XCALL	_U(fp64_log)
	XCALL _U(__fp64_popB)
	XCALL	_U(fp64_mul)
	XJMP	_U(fp64_exp)
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
