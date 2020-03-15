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

/*
	fp64_mult:
	Result will be computed with 9*8=72 bit precision, error max of +/-1 LSB
	R mantissa:	rR13, rR12, rR11, rR10, rR9, rR8, rR7, rR6, rR5	9 registers
				rB4   rB3   rB2   rB1   rB0, rR8, rR7, rR6, rR5 
				r13,  r14,  r15,  r16,  r17, r6,  r7,  r8,  r9
	r5:			0
	Total: 9+9+4 = 22 or 9+9+9 = 27
	34 multiplications, 33*3 = 99 additions

   todo:
	rA0 und rb0 haben nur die top 4 bits gesetzt, 
	d.h. evtl. kann Multiplikation noch weiter gekürzt werden
	Algorithmus für Runden und Addition müssen fertig gestellt werden, 
	die routinen hier runden nicht
 */

#if	defined(__AVR_ENHANCED__) && __AVR_ENHANCED__

#include "fp64def.h"
#include "asmdef.h"

FUNCTION __fp64_mulsd3x

	; A or B is NaN and/or Inf
	; do special case handling
	; case|	A	  |	B	 |	A*B
	;-----+-------+------+------
	; 1	  |	NaN	  |	any	 |	NaN
	; 2	  |	any	  |	NaN	 |	NaN
	; 3	  |	Inf	  |	0	 |	NaN
	; 4	  |	0	  |	Inf	 |	NaN
	; 5	  |	Inf	  |	!= 0 |	Inf
	; 6	  |	!= 0  |	Inf	 |	Inf
0:	brne	1f				; as NaN has priority, result will be NaN	
	; from  now on, neither A nor B are NaN
	; so one or both are +Inf/-Inf
	; check if one of them is 0
	or rBE1, rBE0
	or rBE1, rB6
	or rBE1, rB5
	or rBE1, rB4
	or rBE1, rB3
	or rBE1, rB2
	or rBE1, rB1
	or rBE1, rB0
	breq 1f					; B = 0, A = +/-Inf --> A*B = NaN
	or rAE1, rAE0			; B must be Inf, so now check A for 0
	or rAE1, rA6
	or rAE1, rA5
	or rAE1, rA4
	or rAE1, rA3
	or rAE1, rA2
	or rAE1, rA1
	or rAE1, rA0
	breq 1f					; A = 0, B = +/-Inf --> A*B = NaN
	XJMP	_U(__fp64_infp)	; nonzero * Inf --> Inf (cases 5,6)
1:	XJMP	_U(__fp64_nanp)	; 0 * Inf --> NaN (cases 3,4)

	; handle A*B = 0
2:	clr		r1				; r1 may contain garbage, clear it
	XJMP	_U(__fp64_szero)

	/*
	fp64 __fp64_mulsd3x( fp64 A, fp64 B )
	fp64 fp64_mul( fp64 A, fp64 B )
	Multiplies two 64 bit floating point numbers 
	and rounds result to a 64bit floating point number
	
	Return:
		rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	result = A * B
	*/
ENTRY fp64_mul
GCC_ENTRY __muldf3
ENTRY   __fp64_mulsd3x
	XCALL _U(__fp64_pushB)
	XCALL	_U(__fp64_split3)	; split A and B into parts for exponent and mantissa
	brcs	0b					; A or B is NaN and/or InF --> manage special result
	
	push rR5	; save working registers
	push rR6
	push rR7
	push rR8
	push rZero

	rcall __fp64_mulsd3_pse0

	pop rZero
	pop rR8			; restore used registers
	pop rR7
	pop rR6
	pop rR5
	
	; rcall __fp64_saveAB
	XCALL _U(__fp64_popB)
	brcs 3f			; overflow?
	XJMP _U(__fp64_rpretA)	; no, return with proper rounding, including carry
3:	ret				; overflow, return already packed result +/-Inf

	/*
	fp64 __fp64mulsd3_pse( fp64_splitted_t A, fp64_splitted_t B )
	Multiplies two 64 bit floating point numbers  that are splitted
	and rounds result to a 64bit floating point integer
	A and B must not be NaN or +/-Inf --> A and B are both finite
	
	Return:
		rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	result = A * B
	*/
ENTRY   __fp64_mulsd3_pse			; post split entry
	; check zero (subnormal have exp == 1)
	XCALL _U(__fp64_pscA)
ENTRY   __fp64_mulsd3_pse0			; post split entry for Z flag already set
	; rcall __fp64_saveAB
	breq	2b				; A = 0 --> A*B = 0
	XCALL _U(__fp64_pscB)
	breq 	2b				; B = 0 --> A*B = 0
	
	; exponent(A*B) = exponent(A)+exponent(B)
	; base adjustment will be done later
	add		rAE0, rBE0
	adc 	rAE1, rBE1

	;call __fp64_saveAB
	
	; core algorithm for multiplication
	; multiplication will be computed with 72 bit precision --> max error +/-1 LSB
	; rB5.rB4.rB3.rB2.rB1.rB0.rR8.rR7.rR6.rR5 = rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0 * rB7.rA6.rA5.rA4.rA3.rA2.rA1.rA0
	; all multiplications "below" 72 bit are left out (e.g. rA4*rB0, rA3*rB1, rA2*rB2, rA1*rB3, rA0*rB4)
	;rR7.rR6.rR5	 = rA5 * rB0
	mul rA5, rB0
	mov rR5, r0
	mov rR6, r1
	clr rZero			; as r1 is used for multiplication, rZero will be used as "zero" register
	clr rR7
	clr rR8
	
	;rR7.rR6.rR5	+= rA4 * rB1
	mul rA4, rB1
	add rR5, r0
	adc rR6, r1
	adc rR7, rZero
	
	;rR7.rR6.rR5	+= rA3 * rB2
	mul rA3, rB2
	add rR5, r0
	adc rR6, r1
	adc rR7, rZero
	
	;rR7.rR6.rR5 += rA2 * rB3
	mul rA2, rB3
	add rR5, r0
	adc rR6, r1
	adc rR7, rZero
	
	;rR7.rR6.rR5 += rA1 * rB4
	mul rA1, rB4
	add rR5, r0
	adc rR6, r1
	adc rR7, rZero
	
	;rR7.rR6.rR5 += rA0 * rB5	rR5 can be pushed
	mul rA0, rB5
	add rR5, r0
	adc rR6, r1
	adc rR7, rZero
	
	;rcall __fp64_saveMul

	;rR8.rR7.rR6	+= rA6 * rB0
	mul rA6, rB0
	add rR6, r0
	adc rR7, r1
	adc rR8, rZero

	;rR8.rR7.rR6	+= rA5 * rB1
	mul rA5, rB1
	add rR6, r0
	adc rR7, r1
	adc rR8, rZero

	;rR8.rR7.rR6	+= rA4 * rB2
	mul rA4, rB2
	add rR6, r0
	adc rR7, r1
	adc rR8, rZero

	;rR8.rR7.rR6 += rA3 * rB3
	mul rA3, rB3
	add rR6, r0
	adc rR7, r1
	adc rR8, rZero

	;rR8.rR7.rR6 += rA2 * rB4
	mul rA2, rB4
	add rR6, r0
	adc rR7, r1
	adc rR8, rZero

	;rR8.rR7.rR6 += rA1 * rB5	
	mul rA1, rB5
	add rR6, r0
	adc rR7, r1
	adc rR8, rZero

	;rR8.rR7.rR6 += rA0 * rB6	rR6 can be pushed, B0 can be used
	mul rA0, rB6
	add rR6, r0
	adc rR7, r1
	adc rR8, rZero
	clr rB0
	;call __fp64_saveMul

	;rB0.rR8.rR7 += rA6 * rB1
	mul rA6, rB1
	add rR7, r0
	adc rR8, r1
	adc rB0, rZero
	
	;rB0.rR8.rR7 += rA5 * rB2
	mul rA5, rB2
	add rR7, r0
	adc rR8, r1
	adc rB0, rZero
	
	;rB0.rR8.rR7 += rA4 * rB3
	mul rA4, rB3
	add rR7, r0
	adc rR8, r1
	adc rB0, rZero
	
	;rB0.rR8.rR7 += rA3 * rB4
	mul rA3, rB4
	add rR7, r0
	adc rR8, r1
	adc rB0, rZero
	
	;rB0.rR8.rR7 += rA2 * rB5	
	mul rA2, rB5
	add rR7, r0
	adc rR8, r1
	adc rB0, rZero
	
	;rB0.rR8.rR7 += rA1 * rB6	rR7 can be pushed, B1 & A0 can be used
	mul rA1, rB6
	add rR7, r0
	adc rR8, r1
	adc rB0, rZero
	clr rB1
	
	;rB1.rB0.rR8 += rA6 * rB2
	mul rA6, rB2
	add rR8, r0
	adc rB0, r1
	adc rB1, rZero

	;rB1.rB0.rR8 += rA5 * rB3
	mul rA5, rB3
	add rR8, r0
	adc rB0, r1
	adc rB1, rZero

	;rB1.rB0.rR8 += rA4 * rB4
	mul rA4, rB4
	add rR8, r0
	adc rB0, r1
	adc rB1, rZero

	;rB1.rB0.rR8 += rA3 * rB5
	mul rA3, rB5
	add rR8, r0
	adc rB0, r1
	adc rB1, rZero

	;rB1.rB0.rR8 += rA2 * rB6	rR8 can be pushed, B2 & A1 can be used
	mul rA2, rB6
	add rR8, r0
	adc rB0, r1
	adc rB1, rZero
	clr rB2

	;rB2.rB1.rB0 += rA6 * rB3
	mul rA6, rB3
	add rB0, r0
	adc rB1, r1
	adc rB2, rZero

	;rB2.rB1.rB0 += rA5 * rB4
	mul rA5, rB4
	add rB0, r0
	adc rB1, r1
	adc rB2, rZero

	;rB2.rB1.rB0 += rA4 * rB5
	mul rA4, rB5
	add rB0, r0
	adc rB1, r1
	adc rB2, rZero

	;rB2.rB1.rB0 += rA3 * rB6	rB0 can be pushed, B3 & A2 can be used
	mul rA3, rB6
	add rB0, r0
	adc rB1, r1
	adc rB2, rZero
	clr rB3

	;rB3.rB2.rB1 += rA6 * rB4
	mul rA6, rB4
	add rB1, r0
	adc rB2, r1
	adc rB3, rZero

	;rB3.rB2.rB1 += rA5 * rB5
	mul rA5, rB5
	add rB1, r0
	adc rB2, r1
	adc rB3, rZero

	;rB3.rB2.rB1 += rA4 * rB6	rB1 can be pushed, B4 & A3 can be used
	mul rA4, rB6
	add rB1, r0
	adc rB2, r1
	adc rB3, rZero
	clr rB4

	;rB4.rB3.rB2 += rA6 * rB5
	mul rA6, rB5
	add rB2, r0
	adc rB3, r1
	adc rB4, rZero

	;rB4.rB3.rB2 += rA5 * rB6	rB2 can be pushed, B5 & A4 can be used
	mul rA5, rB6
	add rB2, r0
	adc rB3, r1
	adc rB4, rZero

	;rB4.rB3 += rA6 * rB6	rB3 can be pushed, B6 & A6 can be used	
	mul rA6, rB6
	add rB3, r0
	adc rB4, r1		; this can never overflow, so rB5 is not needed

	; __zero_reg__
	clr	r1

	; temporary result is in rB4.rB3.rB2.rB1.rB0.rR8.rR7.rR6.rR5
	; shift mantissa left until topmost bit is set
	; as multiplication result is only 72bits instead of 104bits
	; multiplication with subnormal numbers may result into
	; 72 bits of 0 --> no topmost bit
	; therefore we have to check whether there are some valid bits
	tst 	rB4		; in normal cases, test on rB4 will be sufficient
	;rcall __fp64_saveMul
	brne	101f
	mov		rB5, rB3
	or		rB5, rB2
	or		rB5, rB1
	or		rB5, rB0
	or		rB5, rR8
	or		rB5, rR7
	or		rB5, rR6
	or		rB5, rR5
	breq	12f			; all bits in result 0 --> underflow to 0	

	; at least one bit is set, shift mantissa left until topmost bit is set
10:	tst rB4
101: brmi 	11f			; topmost bit is set --> normalized number 
	
	lsl	rR5				; mantissa <<= 1
	rol rR6
	rol rR7
	rol rR8
	rol rB0
	rol rB1
	rol rB2
	rol rB3
	rol rB4
	sbiw rAE0, 1		; exponent--
	rjmp 10b

	; normalized result is in rB4.rB3.rB2.rB1.rB0.rR8.rR7.rR6.rR5
	; exponent -= 1023 subtract exponent base
11: subi 	rAE0, 0xfe	; subtract exponent base 1023 = 0x3ff
	sbci 	rAE1, 0x03
	adiw    rAE0, 0
	; rcall __fp64_saveMul
	brmi	13f			; exponent negative --> denormal number / underflow
	breq	15f		    ; exponent = 0 --> denormal number

	; result exponent > min ==> normalization is possible
	; check for overflow
	; rcall __fp64_saveMul
	cpi rAE1, 7			; check if exponent < 0x7ff
	brlo 15f			; everything ok, no overflow
	brne 111f			; exponent >= 0x800 -> overflow
	cpi rAE0, 0xff		; exponent >= 0x700, check if < 0x7ff
	brne 15f			; yes -> normalize number
	;call __fp64_saveMul

	; exponent >= 0x7ff --> overflow, 
111:XCALL _U(__fp64_inf)
	sec					; set carry as flag for error and returning of packed result
	ret

	; underflow, can not even expressed as denormilzed number --> return +/-0
12: mov rAE1, r1
	mov rAE0, r1
	clc
	XJMP	_U(__fp64_szero)

131: rcall 16f	
	rjmp 15f
	
	; underflow with exponent < 0, check whether denormalization could work
13:	cpi rAE0,lo8(-51)	; check if result could fit into remaining 52 bits
	;call __fp64_saveMul
	brlt 12b			; no --> return 0
	cpi rAE1, 0xFF		; catch cases where exp(a)+exp(b)<-255
	brne 12b

	; mantissa >> -rAE0
14:	rcall 16f		; mantissa >>= 1
	adiw rAE0, 1	; exponent++
	brmi 14b		; exponent still < 0
	;call __fp64_saveMul

	; shift mantissa 3 bits to prepare for packing 
	; (topmost bit is discarded as it is always 1, therefore only 3 shifts needed instead of 4)
15: ; call __fp64_saveMul
	mov rA6,rB4		; move result into A
	mov rA5,rB3
	mov rA4,rB2
	mov rA3,rB1
	mov rA2,rB0
	mov rA1,rR8
	mov rA0,rR7

	or rR6, rR5		; are there any trailing bits set?
	; rcall __fp64_saveAB
	breq 151f
	sbr rA0, 0 		; yes: set LSB to signal possible rounding
151:
	clc
	ret				; return with carry clear

16:	lsr rB4			; mantissa >>= 1
	ror rB3
	ror rB2
	ror rB1
	ror rB0
	ror rR8
	ror rR7
	ror rR6
	ror rR5
	ret
	ENDFUNC

#endif /* !defined(__AVR_TINY__) */
