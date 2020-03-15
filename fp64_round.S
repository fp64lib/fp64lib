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

/* float64_t fp64_round( float64_t x );
    Rounds x upwards to the nearest integer, but rounds halfway
	cases away from 0.
	
	The following rules apply:

	case|           x	       | result
	----+----------------------+------------
	  1 |          NaN         | NaN
	  2 |         +/-Inf       | +/- Inf
	  3 |         +/-0.0	   | +/- 0.0
	  4 |          |x|>=2^52   | x
	  5 |      0 < |x|< 0.5	   | 0.0
	  6 |    0.5 <=|x|< 1.0	   | +/- 1.0
	  7 |    1.0 <=|x|< 2^52   | trunc(x) 		  if (|x|-trunc(|x|)) < 0.5
								 trunc(x+sign(x)) if (|x|-trunc(|x|)) >= 0.5

   Input:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0 - A in IEEE 754 - 64-bit format
   Output:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0 - ceil(x)
   Examples:
     fp64_round(1.1) --> 1.0
     fp64_round(1.5) --> 2.0
     fp64_round(-1.1) --> -1.0
     fp64_round(-1.5) --> -2.0
 */
 
 #if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

FUNCTION fp64_round
	; handle NaN and +/-Inf
.L_NaN:
	breq .L_Inf					; handle Inf differently
	XJMP _U(__fp64_nan)			; case 1: return NaN

.L_Inf:
	XJMP _U(__fp64_inf)			; case 2: return +/-Inf

.L_zr:
	XJMP _U(__fp64_szero)		; case 3: return +/-0.0

0:	; |x| < 1.0, check for case 5
	cpi rAE1, 0xff
	brne .L_zr					; |x| < 2^-255, case 5, return 0
	cpi rAE0, 0xff
	brne .L_zr					; 2^-255 >= |x| > 0.5, case 5, return 0
.L_one:							
	XCALL _U(__fp64_one)		; clear all registers
	bld rA7, 7					; with proper sign
	ret

ENTRY	fp64_round
GCC_ENTRY __round
	XCALL _U(__fp64_splitA)
	brcs .L_NaN					; handle cases 1&2: NaN and +/-INF
	breq .L_zr					; case 3: return 0 for 0

	subi rAE0, lo8(1023)		; remove exponent bias: exp -= 1023
	sbci rAE1, hi8(1023)
	tst rAE1
	brmi 0b						; |x| < 1, check for cases 5 & 6
	brne .L_ret					; |x| > 2^255, case 4, return x 
	cpi rAE0, 52
	brge .L_ret					; |x| >= 2^52, case 4, return x
	
	; case 7: now x is in range 1 <= |x| < 2^52
	; clear out the fractional bits
	
	ldi rAE1, 55				; counter = (52 digits + 3 saveguard digits) - exp2(x)
	sub rAE1, rAE0				; as |x| < 2^52, this is always > 1
	push rAE1
	
0:	XCALL _U(__fp64_lsrA)		; shift number downwards -> this clears the fraction
	dec rAE1
	brne 0b
	
	adc rA0, r1					; C = 1 if fraction(x) >= 0.5
	adc rA1, r1
	adc rA2, r1
	adc rA3, r1
	adc rA4, r1
	adc rA5, r1
	adc rA6, r1					; as the significand contains only 52 bits, we will not
								; get a carry at this operation

1:	pop rAE1					; restore number of shifts
	; rcall __fp64_saveAB
	
2:	XCALL _U(__fp64_lslA)		; now shift the number back into position
	dec rAE1
	brne 2b

	;rcall __fp64_saveAB

	brcc .L_ret
	adc rAE0, r1				; C = 1 if there was an overflow --> increase exponent
								; this will not lead to exponent overflow, as x < 2^52
	ldi rA6, 0x80				; create a new leading bit (due to overflow all other bits are 0)

.L_ret:
	; rcall __fp64_saveAB
	subi rAE0, -0xff			; add base 1023
	sbci rAE1, -0x04
	XJMP _U(__fp64_pretA)		; pack and return x

ENDFUNC

#endif /* !defined(__AVR_TINY__) */