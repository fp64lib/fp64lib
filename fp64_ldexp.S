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

#include "fp64asm.h"
#include "fp64def.h"

/* float64_t fp64_ldexp (float64_t x, int exp)
   The fp64_ldexp() function returns the result of multiplying the
   floating-point number x by 2 raised to the power exp.
  The following rules apply:

	case|           x	         | result
	----+------------------------+------------
	  1 |          NaN           | NaN
	  2 |         +/-Inf         | +/- Inf
	  3 |         +/-0.0	     | +/- 0.0
	  4 | exponent(x)+exp>1023   | +/- Inf (Overflow)
	  5 | exponent(x)+exp<-1074  | +/- 0.0 (Underflow)
	  6 | exponent(x)+exp<-1023  | x*2^exp as subnormal number
	  7 | exponent(x)+exp>=-1023 | x*2^exp

   float64_t fp64_scalbn (float64_t x, int n)
   fp64_scalbn is an alias to fp64_ldexp(), see there
 */

FUNCTION fp64_ldexp
	; handle NaN and +/-Inf
.L_nf:
	breq .L_Inf					; handle Inf differently
	XJMP _U(__fp64_nan)			; case 1: return NaN

.L_Inf_or_0:
	.sbrs_callj rB7, 7			; V=1 is an underflow when addend was < 0

.L_Inf:
	XJMP _U(__fp64_inf)			; case 2: return +/-Inf

.L_zr:
	XJMP _U(__fp64_szero)		; case 3: return +0

/* float64_t fp64_ldexp (float64_t x, int exp)
   The fp64_ldexp() function returns the result of multiplying the
   floating-point number x by 2 raised to the power exp.
*/
ENTRY fp64_ldexp
ENTRY fp64_scalbn
ENTRY_DOUBLE ldexp ldexpl
ENTRY_DOUBLE scalbn scalbnl
	XCALL _U(__fp64_splitA)
	brcs .L_nf					; handle non-finite cases 1&2: NaN and +/-INF
	breq .L_zr					; case 3: return 0 for 0

	subi rAE0, lo8(1023)		; un-bias exponent
	sbci rAE1, hi8(1023)

	;; Normalize in case of a subnormal.  Exponent won't overflow / underflow.
	XCALL _U(__fp64_norm2_non0)

	; now "multiply" by 2^exp
	; this is done by adding exp to exponent of A
	add rAE0, rB6
	adc rAE1, rB7
	brvs .L_Inf_or_0			; cases 4, 5: signed overflow of 16-bit addition

	;; check for overflow
	ldi XL,   hi8(0x7ff - 1023)	; compare against unbiased Inf's expo
	cpi	rAE0, lo8(0x7ff - 1023)
	cpc rAE1, XL
	brge .L_Inf

	subi rAE0, lo8(-1023)		; add exponent bias
	sbci rAE1, hi8(-1023)
	breq 2f						; normal or subnormal depends on rounding
	brpl .L_pretA				; normal? (neither subnormal nor zero)

	;; Below normal (subnormal or underflow)

	ldi XL,   hi8(-52)
	cpi rAE0, lo8(-52)
	cpc rAE1, XL
	brlt .L_zr					; case 5: exponent < -1023 - 52 --> underflow

1:	;; Case 6: exponent in [-1024, -1075]: create subnormal number.
	XCALL _U(__fp64_lsrA)		; A >>= 1
	adiw rAE0, 1
	brmi 1b

2:	subi rA0, lo8(-8)			; round
	sbci rA1, hi8(-8)
	sbci rA2, hi8(-8)
	sbci rA3, hi8(-8)
	sbci rA4, hi8(-8)
	sbci rA5, hi8(-8)
	sbci rA6, hi8(-8)

	brcs .L_pretA
	ldi rA6, 0x80				; rounding overflowed to a normal number
	adiw rAE0, 1

.L_pretA:
	;; case 7: return x
	XJMP _U(__fp64_pretA)		; pack and return x
ENDFUNC
