/* Copyright (c) 2019-2020  Uwe Bissinger
   Based on 32bit floating point arithmetic routines which is:
   Copyright (c) 2007  Dmitry Xmelkov

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

/* long long fp64_llrint (float64_t A);
     The fp64_llrint() function rounds A to the nearest integer, rounding the
     halfway cases to the even integer direction.  (That is, both 1.5 and
     2.5 values are rounded to 2).  This function is similar to the lrint()
     function but returns a long long value instead of a long value.
   Return:
     The rounded long long integer value.  If A is infinite, NaN or an overflow
     occures, this imlpementation returns LONG_LONG_MIN (0x8000000000000000).

	The following rules apply:

	case|           A	       | result
	----+----------------------+-----------------------------------
	  1 |          NaN         | LONG_LONG_MIN (0x8000000000000000)
	  2 |         +/-Inf       | LONG_LONG_MIN (0x8000000000000000)
	  3 |         +/-0.0	   | 0LL
	  4 |          |A|>=2^63   | LONG_LONG_MIN (0x8000000000000000)
	  5 |      0 < |A|<= 0.5   | 0LL
	  6 |    0.5 < |A|< 1.0	   | +/- 1LL
	  7 |    1.0 <=|A|< 2^63   | trunc(x) 		  if (|x|-trunc(|x|)) < 0.5
								 trunc(x+sign(x)) if (|x|-trunc(|x|)) >= 0.5

   Input:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0 - A in IEEE 754 - 64-bit format
   Output:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0 - llrint(x)
   Examples:
     fp64_llrint(1.25) --> 1LL
     fp64_llrint(1.5)  --> 2LL
     fp64_llrint(2.5)  --> 2LL
     fp64_llrint(2.75) --> 3LL
     fp64_llrint(3.5)  --> 4LL
     fp64_llrint(-1.25) --> -1LL
     fp64_llrint(-1.5)  --> -2LL
     fp64_llrint(-2.5)  --> -2LL
     fp64_llrint(-2.75) --> -3LL
     fp64_llrint(-3.5)  --> -4LL
 */

#include "fp64asm.h"
#include "fp64def.h"

FUNCTION fp64_llrint
.L_err:
	;; handle NaN, +/-Inf and rounding overflows
	set							; cases 1 & 2: force return of LONG_LONG_MIN
.L_szero:
	XJMP _U(__fp64_szero)

.L_zr:
	XJMP _U(__fp64_zero)		; case 3: return 0LL

.Less_1:
	;; |x| < 1.0, discriminate between case 5 and case 6
	;; 0.5 <= |x| < 1.0  <=>  expo == -1
	adiw rAE0, 1
	brne .L_zr					; expo != -1 so |x| < 0.5 --> case 5, return 0
	ldi rA7, 0x80				; |x| == 0.5?
	XCALL _U(__fp64_cpc0A5)
	cpc	rA6, rA7
	breq .L_zr					; yes: case 5, return 0
	;; no: 0.5 < |x| < 1.0 --> case 6, return +/-1

.L_one:
	rcall .L_szero				; get zero (almost) without disturbing T
	clr rA7						; create 1LL
	inc rA0
	rjmp .L_sign

ENTRY fp64_llrint
ENTRY_DOUBLE llrint llrintl
	XCALL _U(__fp64_splitA)
	brcs .L_err					; handle cases 1 & 2: NaN and +/-INF
	breq .L_zr					; case 3: return 0 for 0

	subi rAE0, lo8(1023)		; remove exponent bias: exp -= 1023
	sbci rAE1, hi8(1023)
	brmi .Less_1				; |x| < 1, check for cases 5 & 6

	cpi rAE0, 63
	cpc rAE1, r1
	brge .L_err					; |x| >= 2^63, case 4, return LONG_LONG_MIN

	;; case 7: now we have 1 <= |x| < 2^63

	mov rA7, rA6				; move mantissa into place for long long return
	mov rA6, rA5
	mov rA5, rA4
	mov rA4, rA3
	mov rA3, rA2
	mov rA2, rA1
	mov rA1, rA0
	clr rA0						; extend to 64 bits at the low end
	clr r0						; extend to Q-format 64.8

	;; clear the fractional bits

	ldi rAE1, 63				; counter = 63 digits - exp2(x)
	sub rAE1, rAE0				; |x| < 2^63 --> this is always >= 0
	breq .L_round

1:	lsr rA7						; shifting right clears the fraction
	ror rA6
	ror rA5
	ror rA4
	ror rA3
	ror rA2
	ror rA1
	ror rA0
	ror r0						; save dropped-out bit of fraction
	brcc 2f						; about to loose info that fract8 is != 0 ?
	sbrs r0, 0					; is the lowest bit still set?
	inc	r0						; no: set lowest bit
2:	dec rAE1
	brne 1b

	;; now round
.L_round:
	lsl r0						; C = MSB of fract8 --> C==1 <=> fract8 >= 0.5
	brcc .L_sign				; fract8 was < 0.5 --> adjust sign and return
	brne 3f						; if fract8 != 0 --> fract8 > 0.5 so round it
	sbrs rA0, 0					; is number even?
	rjmp .L_sign				; no --> already correctly rounded

3:	adc rA0, r1					; C = 1 if fract8 >= 0.5
	adc rA1, r1
	adc rA2, r1
	adc rA3, r1
	adc rA4, r1
	adc rA5, r1
	adc rA6, r1
	adc rA7, r1
	brcs .L_err					; rounding overflow?

.L_sign:
	;; restore the sign and return
	brtc	.L_ret
	XJMP _U(__negdi2)			; libgcc: R18[8] = -R18[8]
.L_ret:
	ret

ENDFUNC
