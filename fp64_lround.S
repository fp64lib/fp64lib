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

/* long fp64_lround (double A);
     The fp64_lround() function rounds A to the nearest integer, but rounds
     halfway cases away from zero (instead of to the nearest even integer).
     This function is similar to round() function, but it differs in
     type of return value and in that an overflow is possible.
   Return:
     The rounded long integer value. If A is infinite, NaN or an overflow
     was, this realization returns the LONG_MIN value (0x80000000).
	
	The following rules apply:

	case|           A	       | result
	----+----------------------+------------
	  1 |          NaN         | LONG_MIN (0x80000000)
	  2 |         +/-Inf       | LONG_MIN (0x80000000)
	  3 |         +/-0.0	   | 0L
	  4 |          |x|>=2^31   | LONG_MIN (0x80000000)
	  5 |      0 < |x|< 0.5	   | 0L
	  6 |    0.5 <=|x|< 1.0	   | +/- 1L
	  7 |    1.0 <=|x|< 2^31   | trunc(x) 		  if (|x|-trunc(|x|)) < 0.5
								 trunc(x+sign(x)) if (|x|-trunc(|x|)) >= 0.5

   Input:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0 - A in IEEE 754 - 64-bit format
   Output:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0 - lround(x)
   Examples:
     fp64_lround(1.1) --> 1L
     fp64_lround(1.5) --> 2L
     fp64_lround(-1.1) --> -1L
     fp64_lround(-1.5) --> -2L
 */
 
 #if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

FUNCTION fp64_lround
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
.L_one:	
	mov rA7, r1					; get a zero (can't use __fp_zero as this clears the T flag)
	mov rA6, r1
	movw rA4, rA6
	inc rA4						; create 1L
	rjmp .L_sign
	ret

ENTRY	fp64_lround
GCC_ENTRY __lround
	XCALL _U(__fp64_splitA)
	brcs .L_err					; handle cases 1&2: NaN and +/-INF
	breq .L_zr					; case 3: return 0 for 0

	subi rAE0, lo8(1023)		; remove exponent bias: exp -= 1023
	sbci rAE1, hi8(1023)
	tst rAE1
	brmi 0b						; |x| < 1, check for cases 5 & 6
	brne .L_err					; |x| > 2^255, case 4, return LONG_MIN 
	cpi rAE0, 31
	brge .L_err					; |x| >= 2^31, case 4, return LONG_MIN
	
	; case 7: now x is in range 1 <= |x| < 2^31
	; clear out the fractional bits
	
	ldi rAE1, 31				; counter = 31 digits - exp2(x)
	sub rAE1, rAE0				; as |x| < 2^31, this is always >= 0
	
0:	breq 1f
	lsr rA6						; shift number downwards -> this clears the fraction
	ror rA5
	ror rA4
	ror rA3
	dec rAE1
	rjmp 0b
	
1:	adc rA3, r1					; C = 1 if fraction(x) >= 0.5
	adc rA4, r1
	adc rA5, r1
	adc rA6, r1
	brcs .L_err					; carry due to rounding --> result will not fit into long

	mov rA7, rA6				; move result into correct registers
	mov rA6, rA5
	mov rA5, rA4
	mov rA4, rA3
	
  ; restore the sign and return
.L_sign:
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