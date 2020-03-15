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

/* <non_standart> __fp64addsf3x (float_64 A, float_64 B);
     Internal function to add 64-bit float point numbers.

   Input:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0.rAE  - arg. A
     rB7.rB6.rB5.rB4.rB3.rB2.rB1.rB0.rBE  - arg. B
   Output:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0 - result A - B
 */

#if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

FUNCTION __fp64addsf3x

	; do special case handling
	; A or B is NaN and/or Inf
	; case|	A	  |	B	 |	A+B  |  A-B | A+(-B)
	;-----+-------+------+-------+------+--------
	; 1	  |	NaN	  |	any	 |	NaN	 |  NaN |  NaN ok
	; 2	  |	any	  |	NaN	 |	NaN  |  NaN |  NaN ok
	; 3a  | +Inf  | -Inf |  NaN  | +Inf | +Inf 3b ok
	; 3b  | +Inf  | +Inf |  +Inf |  NaN | NaN 3a ok
	; 3c  | -Inf  | -Inf |  -Inf |  NaN | NaN 3d ok
	; 3d  | -Inf  | +Inf |  NaN  |  -Inf| -Inf 3c ok
	; 4	  |	Inf	  |	any	 |	Inf	 | Inf  | Inf ok
	; 5	  |	any	  |	Inf	 |	Inf  | -Inf | -Inf ok
	; 6	  |	0	  |	any  |	any  | -any | -any ok
	; 7	  |	any  |	0	 |	any  | any  | any ok

0:	brne	.L_nan				; as NaN has priority, result will be NaN (cases 1&2)	
	; from  now on, neither A nor B are NaN
	; so one or both are +Inf/-Inf
	; check wether both are Inf
	XCALL	_U(__fp64_pscA)
	;call __fp64_saveA

	brne	.L_infB			; A is not Inf --> B has to be Inf (case 5)
	XCALL	_U(__fp64_pscB)	; A is +/-Inf, so check whether B is also +/-Inf
	;call  __fp64_saveAB
	brcc	.L_inf			; B is finite --> return A Inf (case 4)
	brtc	.L_inf			; Both are inf, check Inf + Inf with the same sign (cases 3b/3c)
	tst r0					; both are inf, with different sign, check for sub (case 3a)
	brmi .L_inf				; +Inf - -Inf or -Inf - +Inf --> return Inf with sign of A
	; case 3a/3d: Inf + Inf with different sign, return NaN
.L_nan:
	XJMP	_U(__fp64_nanp)

	; recover sign(a)
	; for addition: T = sign(a) ^ sign(b), rB7.7 = sign(b)
	; for subtraction: T = sign(a) ^ sign(-b), rB7.7 = sign(-b)
.L_sign:	
	bld		rA7, 7			; get sign(a) ^ sign(b)
	;call __fp64_saveAB
	sbrc	rB7, 7			; if sign(b) not set, rA7 reflects sign(a)
	subi	rA7, 0x80		; else get rid of sign(b)
	bst		rA7, 7			; T and rA7 now contains sign(a)
	ret
	
	; cases 3b/3c Inf + Inf with same sign
	; case 4: Inf + Any -> return Inf with sign of A
.L_inf:						
	rcall .L_sign			; recover sign(a)
	XJMP	_U(__fp64_infp)	; return Inf with sign(a)

	; case 5: Any + Inf -> return Inf with sign of B
.L_infB:
	sub		rB7, r0			; if mode is sub, reverse sign of B
	bst		rB7, 7			; determine sign based on B
	XJMP	_U(__fp64_infp)	; return Inf

	/*
	float64_t fp64_sub( float64_t A, float64_t B )
	Subtracts two 64 bit floating point numbers 
	and rounds result to a 64bit floating point number
	
	Return:
		rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	result = A - B
	*/
ENTRY fp64_sub
ENTRY __subdf3
	clr r0
	sec
	ror r0					; set mode to subtraction = 0x80
	rjmp 1f
	
	/*
	float64_t fp64_add( float64_t A, float64_t B )
	Adds two 64 bit floating point numbers 
	and rounds result to a 64bit floating point number
	
	Return:
		rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	result = A + B
	*/
ENTRY fp64_add
ENTRY __adddf3
ENTRY __fp64_addsd3x
	clr r0					; set mode to addition
1:	XCALL _U(__fp64_pushB)
	XCALL _U(__fp64_split3)	; split A and B into parts for exponent and mantissa
	; rcall __fp64_saveAB
	brcs	0b				; A or B is NaN and/or InF --> manage special cases
	breq	11f				; A is 0 --> result is B, case 11
	XCALL _U(__fp64_isBzero)
	;rcall __fp64_saveAB
	brne	2f				; A and B are != 0 --> check whether A > B
							; B is 0, case 12
	rcall	.L_sign			; recover sign(A), as B might be -0
	rjmp	12f
	
2:	rcall __fp64_add_pse_r0
	XCALL _U(__fp64_popB)
	XJMP _U(__fp64_rpretA)	; round, pack result and return
 
	; case 11: A is 0 --> result is B, sign depending on B and op
11:	sub rB7, r0				; reverse sign of B in case of a subtraction
	bst rB7, 7				; set sign of result = sign(B)
	; rcall __fp64_saveAB
	XCALL _U(__fp64_movABx)	; so move B into A and return it

12:	; case 12: B = 0 --> result is A
	XCALL _U(__fp64_popB)
	sbrc rA6, 7				; is A normal number ?
	XJMP _U(__fp64_pretA)	; yes: result is already ok
	XCALL _U(__fp64_lslA)
	sbiw rAE0, 1		
	XJMP _U(__fp64_pretA)

	/*
	float64_t_intern __fp64_add_pse( float64_t_intern A, float64_t_intern B )
	Adds two 64 bit floating point numbers, both numbers have to be finite,
	no special case handling is done except handling subnormal numbers!
	Input:
		rA6.rA5.rA4.rA3.rA2.rA1.rA0		significand of A
		rAE1.rAE0						exponent of A
		rA7								sign of A
		rB6.rB5.rB4.rB3.rB2.rB1.rB0		significand of B
		rBE1.rBE0						exponent of B
		rB7								sign of B
		T								sign(a^b)
	Return:
		C								indicates over- or underflow --> output is already in float64_t format 
		rA6.rA5.rA4.rA3.rA2.rA1.rA0		significand of A+B, if C=0
		rAE1.rAE0						exponent of A+B, if C=0
		rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	result of A+B, if C=1
		
		
	*/
ENTRY __fp64_sub_pse	
	clr r0
	sec
	ror r0					; set mode to subtraction = 0x80
	rjmp __fp64_add_pse_r0
	
ENTRY __fp64_add_pse	
	clr r0					; set mode to addition
	; internal entry point, r0 must be set to 0x00 for add or 0x80 for sub
__fp64_add_pse_r0:
	; normal case, A and B are both finite
    ; the following table shows, how the sign of the
	; result depends on the sign of the two operands A & B
	;  case   | A  |  B |     A+B     | A+B op |    A-B      | A-B op
	;---------+----+----+-------------+--------+-------------+--------
	;1. A > B | >0 | >0 | >0 =sign(A) |  add   | >0 =sign(A) |  sub
	;2. A > B | >0 | <0 | >0 =sign(A) |  sub   | >0 =sign(A) |  add
	;3. A > B | <0 | >0 | <0 =sign(A) |  sub   | <0 =sign(A) |  add
	;4. A > B | <0 | <0 | <0 =sign(A) |  add   | <0 =sign(A) |  sub
	;5. A < B | >0 | >0 | >0 =sign(B) |  add*  | <0 =-sign(B)|  sub*
	;6. A < B | >0 | <0 | <0 =sign(B) |  sub*  | >0 =-sign(B)|  add*
	;7. A < B | <0 | >0 | >0 =sign(B) |  sub*  | <0 =-sign(B)|  add*
	;8. A < B | <0 | <0 | <0 =sign(B) |  add*  | >0 =-sign(B)|  sub*
	;9. A = B | any| any|    =sign(B) |  add   | =0          |  zero
	;10.A =-B | any| any| =0          |  zero  |    =sign(B) |  add
	;11.A = 0 |  0 | any|    =sign(B) |  swap  |    =-sign(B)|  swap
	;12.B = 0 | any|  0 |    =sign(A) |  none  |    =sign(A) |  none
	; * swap arguments before performing op
	;
	; this leads to the following algorithm for sign and op (cases 1-8)
	; op = "A+B" ? add : sub;
	; sign = sign(A)	// cases 1-4
	; if( fabs(A) < fabs(b) ) { // cases 5-8
	;	sign = (op == add) ? sign(b) : -sign(b);
	;	swap(A,B);
	; } 
	; if( sign(A) != sign(b) ) // cases 2,3,6,7
	;	op = (op == add) ? sub : add;
	; 
	; sign of result will be stored in T flag of SREG
	; op will be stored in bit 7 of r0, so subi r0, 0x80 will reverse the operation

    ; compare fabs(A) and fabs(B), both being != 0, cases 1-8
	XCALL _U(__fp64_cpcAB)
	cpc	rAE0, rBE0
	cpc rAE1, rBE1
	; rcall __fp64_saveAB
	brlo	3f				; fabs(A) < fabs(B) --> swap A and B, cases 5-8
	brne	14f				; fabs(A) > fabs(B) --> adjust, then add, cases 1-4

	; cases 9&10: fabs(A) = fabs(B)
	bld rA7, 7				; rA7 = sign(a) ^ sign(b)
	sub rA7, r0				; reverse sign of B in case of a subtraction
	sbrc rA7, 7				; case 9 for add (A+A) or case 10 for sub (-A - A)		
	rjmp .L_zr				; case 9 for sub (A+ -A) or case 10 for sub  (A - -A) --> result is 0.0
	clr r0					; op = add for both cases
	rcall .L_sign			; A determines sign of result
	;call __fp64_saveAB
	rjmp 6f					; start immediately with add or sub
	
14: ; cases 1-4, fabs(A) > fabs(b)
	bld rA7, 7
	sbrc rA7, 7				; sign(a) != sign(b), cases 2,3
	eor r0, rA7				; yes, we have to do swap the operation
	call .L_sign			; sign(result) = sign(A)
	;call __fp64_saveAB
	rjmp 4f
	
	; fabs(a) < fabs(b)  --> swap A and B, cases 5-8
3:	; call __fp64_saveAB
	sub rB7, r0				; reverse sign of B in case of a subtraction --> B becomes -B in subtraction
	brtc 33f
	com r0
33:	bst rB7, 7				; set sign of result = sign(B) or sign(-B)
	
	XCALL _U(__fp64_swapAB)	; swap A  & B

	; from now on, fabs(A) > fabs(b), A != 0, B != 0
	; T = sign(result), r0 = op
4:	
	; call __fp64_saveAB

	sub	rBE0, rAE0
	sbc rBE1, rAE1			; expB = expb - expA
	breq	6f				; exp(b) = exp(a) --> shift is not needed
	cpi rBE1, 0xff
	brcs	.L_ret			; A and B differ by more than 2^256 -> A is the result
	cpi rBE0, -53
	brcs	.L_ret			; A and B differ by more than 2^52 --> A is the result
	
	; shift B >>= exp(a) - exp(b)
	; align mantissa of B with A
5:	lsr rB6			; mantissa B >>= 1
	ror rB5
	ror rB4
	ror rB3
	ror rB2
	ror rB1
	ror rB0
	subi rBE0, -1
	brne 5b

6:	; B is now properly shifted for addition --> start real add or sub action
	; call __fp64_saveAB
	sbrs r0, 7	  	; operation = sub?
	rjmp	.L_add	; no, goto addition
	sub rA0, rB0	; yes, compute A -= B
	sbc	rA1, rB1
	sbc	rA2, rB2
	sbc	rA3, rB3
	sbc	rA4, rB4
	sbc	rA5, rB5
	sbc	rA6, rB6
7:
	; call __fp64_saveAB
	brmi	.L_ret	; topmost bit is still set, so in A is the final result,

	sbiw rAE0, 1
	;rcall __fp64_saveAB
	breq 8f					; underflow --> subnormal handling
	brcs 8f
	
	XCALL _U(__fp64_lslA)
	rjmp 7b		
	
8:	; subnormal number: 
	; 	exponent is already zero
	; 	significand is already in correct position
	; so everything is fine, just return
	; rcall __fp64_saveAB
	XCALL _U(__fp64_lslA)
	ret
	
	; result is in T (sign), AE1.rAE0 (exp) and rA6.rA5.rA4.rA3.rA2.rA1.rA0 --> return it
.L_ret:
	tst rA6			; is topmost bit set?
	brpl 8b			; no, subnormal number --> adjust result
	clc				; clear carry --> no error, caller has to pack result
	ret

.L_zr:	; exponent is zero, but topmost bit is still not set --> subnormal number
	; or A+(-A)
	XCALL _U(__fp64_zero)	; return 0
	movw rAE0, rA0			; also in internal format
	sec						; set carry to indicate overflow and for already packed result
	ret

.L_add:
	;call __fp64_saveAB
	add rA0, rB0	; add B to A
	adc	rA1, rB1
	adc	rA2, rB2
	adc	rA3, rB3
	adc	rA4, rB4
	adc	rA5, rB5
	adc	rA6, rB6
	brcc	.L_ret	; no overflow occured, so A is already the final result, including subnormals
	ror  rA6
	XCALL _U(__fp64_rorA5) 		; overflow --> shift mantissa of result with 1st bit set (could be discarded)
	
	adiw rAE0, 1	; increase exponent by 1
	cpi	rAE0, 0xff	; did we get overflow (exp == 0x7ff) ?
	brne .L_ret		; no -> return A
	cpi rAE1, 0x7
	brne .L_ret		; no -> return A

	rcall .L_sign	; yes, return inf with recovered sign(a)
	XCALL _U(__fp64_inf)
	sec				; set carry to indicate overflow and for already packed result
	ret
	
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
