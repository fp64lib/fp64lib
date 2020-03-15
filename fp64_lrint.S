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

/* $Id$ */

/* long fp64_lrint (float64_t A);
     The fp64_lrint() function rounds A to the nearest integer, rounding the
     halfway cases to the even integer direction. (That is both 1.5 and
     2.5 values are rounded to 2). This function is similar to rint()
     function, but it differs in type of return value and in that an
     overflow is possible.
   Return:
     The rounded long integer value. If A is infinite, NaN or an overflow
     was, this realization returns the LONG_MIN value (0x80000000).
	
	The following rules apply:

	case|           A	       | result
	----+----------------------+------------
	  1 |          NaN         | LONG_MIN (0x80000000)
	  2 |         +/-Inf       | LONG_MIN (0x80000000)
	  3 |         +/-0.0	   | 0L
	  4 |          |A|>=2^31   | LONG_MIN (0x80000000)
	  5 |      0 < |A|<= 0.5   | 0L
	  6 |    0.5 < |A|< 1.0	   | +/- 1L
	  7 |    1.0 <=|A|< 2^31   | trunc(x) 		  if (|x|-trunc(|x|)) < 0.5
								 trunc(x+sign(x)) if (|x|-trunc(|x|)) >= 0.5

   Input:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0 - A in IEEE 754 - 64-bit format
   Output:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0 - lround(x)
   Examples:
     fp64_lrint(1.25) --> 1L
     fp64_lrint(1.5)  --> 2L
     fp64_lrint(2.5)  --> 2L
     fp64_lrint(2.75) --> 3L
     fp64_lrint(3.5)  --> 4L
     fp64_lrint(-1.25) --> -1L
     fp64_lrint(-1.5)  --> -2L
     fp64_lrint(-2.5)  --> -2L
     fp64_lrint(-2.75) --> -3L
     fp64_lrint(-3.5)  --> -4L
 */
 
 #if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

FUNCTION fp64_lrint
	; handle NaN and +/-Inf
.L_err:
	set							; cases 1/2: force return of 0x80000000
	XJMP _U(__fp_szero)

.L_zr:
	XJMP _U(__fp_zero)			; case 3: return 0L (which is binary identical to 0.0f)

0:	; |x| < 1.0, check for case 5
	cpi rAE1, 0xff
	brne .L_zr					; |x| < 2^-255, case 5, return 0
	cpi rAE0, 0xff
	brne .L_zr					; 2^-255 >= |x| > 0.5, case 5, return 0
	or r0, rA6
	or r0, rA5
	or r0, rA4
	or r0, rA3
	mov rA6, r1
	mov rA5, r1
	mov rA4, r1
	mov rA3, r1
	rjmp .L_round
	
.L_one:		
	mov rA7, r1					; get a zero (can't use __fp_zero as this clears the T flag)
	mov rA6, r1
	movw rA4, rA6
	inc rA4						; create 1L
	rjmp .L_sign
	ret

ENTRY	fp64_lrint
GCC_ENTRY __lrint
	XCALL _U(__fp64_splitA)
	brcs .L_err					; handle cases 1&2: NaN and +/-INF
	breq .L_zr					; case 3: return 0 for 0

	subi rAE0, lo8(1023)		; remove exponent bias: exp -= 1023
	sbci rAE1, hi8(1023)

	mov r0, rA2					; save bits between 2^0 and 2^(52-31)
	or r0, rA1
	or r0, rA0

	tst rAE1
	brmi 0b						; |x| < 1, check for cases 5 & 6
	brne .L_err					; |x| > 2^255, case 4, return LONG_MIN 
	cpi rAE0, 31
	brge .L_err					; |x| >= 2^31, case 4, return LONG_MIN
	
	; case 7: now x is in range 1 <= |x| < 2^31
	; clear out the fractional bits
	
	ldi rAE1, 31				; counter = 31 digits - exp2(x)
	sub rAE1, rAE0				; as |x| < 2^31, this is always >= 0
	
1:	breq .L_round
	lsr rA6						; shift number downwards -> this clears the fraction
	ror rA5
	ror rA4
	ror rA3
	ror r0						; save dropped out bit of fraction
	brcc 2f						; about to loose infomation that there is a fraction != 0 ?
	sbrs r0, 0					; is the lowest bit still set?
	inc	r0						; no: set lowest bit
2:	dec rAE1
	rjmp 1b
	
	; now round
.L_round:
	lsl r0						; get last bit of fraction into carry --> if C==1, fraction >= 0.5
	brcc .L_sign				; fraction was < 0.5 --> adjust sign and return
	brne 3f						; if r0 != 0 --> fraction > 0.5 --> round it
	sbrs rA3, 0					; is number even?
	rjmp .L_sign				; no --> already correctly rounded (e.g. 2.5 --> 2L), return
	
3:	adc rA3, r1					; C = 1 if fraction(x) >= 0.5
	adc rA4, r1
	adc rA5, r1
	adc rA6, r1
	brcs .L_err					; carry due to rounding --> result will not fit into long

.L_sign:
	mov rA7, rA6				; move result into correct registers
	mov rA6, rA5
	mov rA5, rA4
	mov rA4, rA3
	
  ; restore the sign and return
	; rcall __fp64_saveAB
	brtc	.L_ret
	com	rA7
	com	rA6
	com	rA5
	neg	rA4
	sbci rA5, -1
	sbci rA6, -1
	sbci rA7, -1
.L_ret:
	ret

ENDFUNC

#endif /* !defined(__AVR_TINY__) */