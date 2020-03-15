/* Copyright (c) 2018-2020  Uwe Bissinger
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

/*
	float64_t __fp64_divsd3( float64_t A, float64_t B )
	Divides two 64 bit floating point numbers 
	and rounds result to a 64bit floating point number

	Input:
		rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0 Nominator A
		rB7.rB6.rB5.rB4.rB3.rB2.rB1.rB0	Divisor B
	Return:
		rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	result = A / B
*/

#if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

FUNCTION __fp64_divsd3x

	; do special case handling
	; A or B is NaN and/or Inf or A is 0
	; case|	A	  |	B	 |	A/B
	;-----+-------+------+------
	; 1	  |	NaN	  |	any	 |	NaN
	; 2	  |	any	  |	NaN	 |	NaN
	; 3	  |	Inf	  |	0	 |	NaN
	; 4   | Inf   | Inf  |  NaN
	; 5	  |	0	  |	Inf	 |	 0
	; 6	  |	Inf	  |	!= 0 |	Inf
	; 7	  |	!= 0  |	Inf	 |	 0
	; 8   | 0     | 0    |  NaN
	; 9   | 0     | != 0 |   0

0:	brne	.L_nan		; as NaN has priority, result will be NaN, cases 1&2
	; from  now on, neither A nor B are NaN
	; so one or both are +Inf/-Inf
	; check if B is 0
	XCALL	_U(__fp64_pscB)
	brcs	1f 			; B is +/-Inf, cases 4,5,7
	breq 	.L_nan		; B = 0, A = +/-Inf --> A/B = NaN, case 3
	; now A is +/-Inf, B != 0, case 6 --> return +/- Inf
.L_inf:
	XJMP	_U(__fp64_infp)

1: ; B is +/-Inf, cases 4,5,7	
	XCALL	_U(__fp64_pscA)
	breq	.L_nan		; A is Inf, case 4: Inf/Inf = NaN

	; finite / Inf, cases 5,7: x / Inf = 0
.L_zr:
	XCALL _U(__fp64_popB)
	XJMP	_U(__fp64_szero)
	
	; 0 / B, cases 8, 9
2:	XCALL	_U(__fp64_pscB)
	brne .L_zr	; B != 0, case 9, 0 / any = 0

	; cases 1-4 and 8: result is NaN 
.L_nan:
	XJMP	_U(__fp64_nanp)

ENTRY fp64_div
GCC_ENTRY __divdf3
ENTRY	__fp64_divsd3
	XCALL _U(__fp64_pushB)
	XCALL	_U(__fp64_split3)
	; call __fp64_saveAB
	brcs	0b			; handle special cases NaN / Inf
	breq	2b			; handle = 0 / B
	XCALL	_U(__fp64_pscB)
	breq	.L_inf		; finite (!=0) / 0.0 --> Inf
	
	XCALL _U(__fp64_divsd3_pse)
	
	XCALL _U(__fp64_popB)
	brcs 99f				; underflow/overflow --> return already packed result
	XJMP _U(__fp64_rpretA)	; everything ok --> round, pack result and return
99:	ret	

/*
	float64_t_intern __fp64_divsd3( float64_t_intern A, float64_t_intern B )
	Internal routine to divide two 64 bit floating point numbers 
	and rounds result to a 64bit floating point number
	Does not handle special cases NaN, +Inf, -Inf, +/-0 (neither for A or B)
	
	Input:
		rA6.rA5.rA4.rA3.rA2.rA1.rA0		significand of A
		rAE1.rAE0						exponent of A
		rA7								sign of A
		rB6.rB5.rB4.rB3.rB2.rB1.rB0		significand of B
		rBE1.rBE0						exponent of B
		rB7								sign of B
		T								sign(a^b)
	Return:
		C								indicates overflow or underflow, result is already in packed format
		rA6.rA5.rA4.rA3.rA2.rA1.rA0		significand of A+B, if C=0
		rAE1.rAE0						exponent of A+B, if C=0
		rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	result of A+B, if C=1
*/


ENTRY	__fp64_divsd3_pse	; post split entry
	; exp(result) = exp(A) - exp(B)
	sub	rAE0, rBE0
	sbc	rAE1, rBE1
	
/* Prepare to division:
     A:  rA6.rA5.rA4.rA3.rA2.rA1.rA0	0x00000001..0x8FFFFFF	// we need one bit for overflow
     B:  rB6.rB5.RB4.rB3.rB2.rB1.rB0	0x00000002..0xFFFFFFE	
     A < B
 */
	; clr	rAE
	; clr	rBE
	
	; make sure A < B
	clr rA7
	clr rB7
	XCALL	_U(__fp64_lsrA)		; A >>= 1, make room for overflow bit
	
22:	XCALL _U(__fp64_cpcAB)		; check whether A < B
	brlo	3f		; A >= B, everything aligned, division can start
	
	; as we do allow subnormal numbers, mantissa of B might not start with 
	; a leading 1 bit (A < B)
	adiw rAE0,1		; increase exponent ( A / B * 2^exp = A / (B/2) * 2^(exp+1) )
	lsl	rB0			; B <<= 1
	rol	rB1
	rol	rB2
	rol	rB3
	rol	rB4
	rol	rB5
	rol	rB6
	rol rB7
	breq 22b		; repeat until we have a leading 1 bit or A < B
	
3:	; from now on A < B
	; call __fp64_saveAB

	push rR5	; save working registers
	push rR6
	push rR7
	push rR8
	
	rcall	.L_div
	mov	rR5, r0			; save top 8 bits of result
	brmi 5f
						; handle A < B --> A/B < 1.0
4:	clr r0
	sec
	ror r0				; r0 = 0x80
	rcall .L_div1		; do 1 bit division at a time
	subi rAE0, lo8(1)	; as result < 1, adjust exponent
	sbci rAE1, hi8(1)
	lsr r0				; get result of division into C
	rol rR5				; and add it to previous result
	brpl 4b				; until we got a leading bit

	; continue with all other digits
5:	rcall	.L_div
	mov	rR6, r0			; save result
	rcall	.L_div
	mov	rR7, r0			; save result
	rcall	.L_div
	mov	rR8, r0			; save result
	rcall	.L_div
	mov	rBE1, r0		; save result
	rcall	.L_div
	mov	rBE0, r0		; save result
	rcall	.L_div
	; call __fp64_saveDiv
	
	; now result is in R5.R6.R7.R8.BE1.BE0.r0
	; move result to A
	mov rA0, r0
	mov rA1, rBE0
	mov rA2, rBE1
	mov rA3, rR8
	mov rA4, rR7
	mov rA5, rR6
	mov rA6, rR5

	pop rR8				; restore used registers
	pop rR7
	pop rR6
	pop rR5
	
	; adjust exponent to base 1023
	subi rAE0, lo8(-1023)
	sbci rAE1, hi8(-1023)
	; call __fp64_saveAB
	brmi	13f			; denormalization is needed

   ; check to overflow
	cpi rAE1, 7			; check if exponent < 0x7ff
	brlo 15f			; everything ok, no overflow
	brne .L_inf2		; exponent >= 0x800 -> overflow
	cpi rAE0, 0xff		; exponent >= 0x700, check if < 0x7ff
	brne 15f			; yes -> no overflow

.L_inf2:				; overflow
	XCALL _U(__fp64_inf)
	sec					; set carry to indicate overflow
	ret
	
   ; return 0 for underflow
12:	XCALL	_U(__fp64_szero)
	sec					; set carry to indicate packed result
	ret

13:	cpi rAE0,lo8(-51)	; check if result could fit into remaining 52 bits
	brlt 12b			; no --> return 0
	cpi rAE1, 0xFF		; catch cases where exp(a)-exp(b)<-255
	brne 12b			; also return 0

	; handle subnormal numbers
	; shift left mantissa until exponent is 0
14:	XCALL _U(__fp64_lsrA)	; mantissa >>= 1
	adiw rAE0, 1			; exponent++
	brmi 14b				; exponent still < 0
	; stops when exponent == 0 --> indicator for subnormal number

15:	; exponent >=0 and < 0x7ff --> return normal result	
	clc					; clear carry to signal "all ok"
	ret
	
	; divide 8 times
.L_div:
	clr r0
	inc r0
.L_div1:
	XCALL _U(__fp64_lslA)	; A <<= 1
	rol rA7
	XCALL _U(__fp64_cpcAB)	; is A > B
	cpc	rA7, rB7
	brcs	2f		; no, skip subtraction
	sub	rA0, rB0	; yes, A -= B
	sbc	rA1, rB1
	sbc	rA2, rB2
	sbc	rA3, rB3
	sbc	rA4, rB4
	sbc	rA5, rB5
	sbc	rA6, rB6	; as A > B, C will be 0 after this operation
	sbc	rA7, rB7	; as A > B, C will be 0 after this operation
2:	rol	r0			; register result of operation, move C into r0
	brcc	.L_div1	; continue up to 8 times

	com	r0			; convert result to positive logic
	ret
	
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
