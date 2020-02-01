/* Copyright (c) 2018-2020  Uwe Bissinger
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

#include "fp64def.h"
#include "asmdef.h"

/*	float64_t fp64_acos(float64_4 phi )
	returns the arcus cos of phi (inverse function to cos(x)
*/
FUNCTION fp64_asin
ENTRY fp64_acos
	rcall fp64_asin
	push rB7			; save used registers
	push rB6
	push rB5
	push rB4
	push rB3
	push rB2
	push rB1
	push rB0
	
	movw rB6, rA6		; B = asin(x)
	movw rB4, rA4
	movw rB2, rA2
	movw rB0, rA0
	
	; PI/2 = 0x3f f9 21 fb 54 44 2d 18LLU
	ldi rA7, 0x3f		; A = PI/2
	ldi rA6, 0xf9
	ldi rA5, 0x21
	ldi rA4, 0xfb
	ldi rA3, 0x54
	ldi rA2, 0x44
	ldi rA1, 0x2d
	ldi rA0, 0x18
	XCALL _U(fp64_sub)	; acos(x) = PI/2 - asin(x)
	; rcall __fp64_saveAB

	pop rB0					; restore used registers
	pop rB1
	pop rB2
	pop rB3
	pop rB4
	pop rB5
	pop rB6
	pop rB7
	ret

	; result is already in a, return it
2:	pop rA7				; retrieve original sign
	ret
	
/*	float64_t fp64_asin(float64_4 phi )
	returns the arcus sine of phi (inverse function to fp64_sin(x)
*/
ENTRY fp64_asin
	push rA7
	bst rA7, 7			; save sign
	cbr rA7, 0x80
	cp r1, rA7			; abs(x) = 0?
	cpc r1, rA6
	cpc r1, rA5
	cpc r1, rA4
	cpc r1, rA3
	cpc r1, rA2
	cpc r1, rA1
	cpc r1, rA0
	breq 2b				; yes, asin(x) = 0
	
	ldi XH, 0x3f
	ldi XL, 0xf0
	cp rA6, XL			; fabs(x) < 1.0 ? 
	cpc rA7, XH
	;rcall __fp64_saveAB
	brlo 1f				; yes, start calculating		
	breq 0f				;check if x is 1.0
.L_nan: ; fabs(x) > 1 --> asin(x) = NaN
	; (this also handles x = +/-INF and NaN)
	pop rA7
	XJMP _U(__fp64_nan)
	
0:	; check whether x is 1.0
	cp r1, rA5			; significand > 0.0?
	cpc r1, rA4
	cpc r1, rA3
	cpc r1, rA2
	cpc r1, rA1
	cpc r1, rA0
	brcs .L_nan			; yes --> x > 1.0, asin(x) = NaN
	; fabs(x) = 1.0 --> asin(x) = +/- PI/2
	pop rA7				; retrieve sign
	bst rA7, 7			; save sign
	
	; PI/2 = 0x3f f9 21 fb 54 44 2d 18LLU
	ldi rA7, 0x3f
	ldi rA6, 0xf9
	ldi rA5, 0x21
	ldi rA4, 0xfb
	ldi rA3, 0x54
	ldi rA2, 0x44
	ldi rA1, 0x2d
	ldi rA0, 0x18
9:	bld rA7, 7			; retrieve sign
	ret
		
1:	; fabs(x) < 1.0, calculate x/sqrt(1-x*x)
	cpi rA7, 0x3e		; is x < 2^-32
	pop rA7
	brlo 9b				; yes: asin(x) = x
	
	push rB7			; save used registers
	push rB6
	push rB5
	push rB4
	push rB3
	push rB2
	push rB1
	push rB0
	push rA7			; save x for later use
	push rA6
	push rA5
	push rA4
	push rA3
	push rA2
	push rA1
	push rA0
	XCALL _U(fp64_square)
	movw rB6, rA6		; B = x*x
	movw rB4, rA4
	movw rB2, rA2
	movw rB0, rA0
	ldi rA7, 0x3f		; A = 1.0
	ldi rA6, 0xf0
	clr rA5
	clr rA4
	movw rA2, rA4
	movw rA0, rA4
	XCALL _U(fp64_sub)
	XCALL _U(fp64_sqrt)
	movw rB6, rA6		; B = sqrt(1-x*x)
	movw rB4, rA4
	movw rB2, rA2
	movw rB0, rA0
	pop rA0				; A = x
	pop rA1
	pop rA2
	pop rA3
	pop rA4
	pop rA5
	pop rA6
	pop rA7
	;rcall __fp64_saveAB
	XCALL _U(__fp64_divsd3) ; A = x / sqrt(1-x*x)
	pop rB0					; restore used registers
	pop rB1
	pop rB2
	pop rB3
	pop rB4
	pop rB5
	pop rB6
	pop rB7
	XJMP _U(fp64_atan)	; asin(x) = atan( x / sqrt(1-x*x) )
	
99: ; rcall __fp64_saveAB
	pop r0
	pop r0
	pop r0
	pop r0
	pop r0
	pop r0
	pop r0
	pop r0
	ret
ENDFUNC
