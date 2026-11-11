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
	rA0 und rb0 haben nur die top 4 Bits gesetzt,
	d.h. evtl. kann Multiplikation noch weiter gekürzt werden
	Algorithmus für Runden und Addition müssen fertiggestellt werden,
	die Routinen hier runden nicht.
 */

#include "fp64asm.h"
#include "fp64def.h"

.require_mul

FUNCTION __fp64_muldf3x

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
	breq 1f						; B = 0, A = +/-Inf --> A*B = NaN
	or rAE1, rAE0				; B must be Inf, so now check A for 0
	or rAE1, rA6
	or rAE1, rA5
	or rAE1, rA4
	or rAE1, rA3
	or rAE1, rA2
	or rAE1, rA1
	or rAE1, rA0
	breq 1f						; A = 0, B = +/-Inf --> A*B = NaN
	XJMP	_U(__fp64_infp)		; nonzero * Inf --> Inf (cases 5,6)
1:	XJMP	_U(__fp64_nanp)		; 0 * Inf --> NaN (cases 3,4)

	; handle A*B = 0
.L_szero:
	clr		r1					; r1 may contain garbage, clear it and set Z=1 to indicate zero-result
	XJMP	_U(__fp64_szero)

	/*
	fp64 __fp64_muldf3x( fp64 A, fp64 B )
	fp64 fp64_mul( fp64 A, fp64 B )
	Multiplies two 64-bit floating point numbers
	and rounds result to a 64-bit floating point number

	Return:
		rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	result = A * B
	*/
ENTRY fp64_mul
GCC_ENTRY __muldf3
ENTRY   __fp64_muldf3x
	XCALL _U(__fp64_pushB)
	XCALL	_U(__fp64_split3)	; split A and B into exponent and mantissa
	brcs	0b					; A or B is NaN and/or InF --> special result

	push rR5					; save working registers
	push rR6
	push rR7
	push rR8
	push rZero

	rcall __fp64_muldf3_pse

	pop rZero
	pop rR8						; restore used registers
	pop rR7
	pop rR6
	pop rR5

	; rcall __fp64_saveAB
	XCALL _U(__fp64_popB)
	brcs 3f						; overflow? result is already packed
	XJMP _U(__fp64_rpretA)		; no, return with proper rounding, including carry
3:	ret							; overflow, return already packed result +/-Inf

/*
	fp64_splitted __fp64muldf3_pse( fp64_splitted_t A, fp64_splitted_t B )
	Multiplies two 64-bit floating point numbers that are split,
	and rounds the result to a 64-bit floating point integer.
	A and B must not be NaN or +/-Inf --> A and B are both finite.

	Input:	rAE1.rAE0 rA7..rA0	A in internal expanded format
`			rAB1.rAB0 rB7..rB0	B in internal expanded format
	Return:
			rAE1.rAE0 rA6.rA5.rA4.rA3.rA2.rA1.rA0 	result = A * B	// C=0, Z=0
			rAE1.rAE0 rA6.rA5.rA4.rA3.rA2.rA1.rA0 	result = +/-0	// C=0, Z=1
			      rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	overflow: ±INF	// C=1
			C=0: sign must be handled by caller
			C=1: sign of the Inf result is set to T

	Modifies (beside registers used for return):
			rZero, rR8..rR5 (=r5..r9)
			rB6..rB0, rBE0, rBE1
			r0
			all flags except T
*/

.L_go_clc_ret:
	rjmp .L_clc_ret

ENTRY   __fp64_muldf3_pse		; post-split entry

	;; Normalizing prior to the multiplication yields better results
	;; when subnormals are involved.
	XCALL _U(__fp64_norm2)		; normalize AX
	breq  .L_go_clc_ret			; A = 0 --> A*B = 0

	XCALL _U(__fp64_swapAB)
	mov rB7, rA7				; restore rB7 after swapAB
	XCALL _U(__fp64_norm2)		; normalize BX
	breq  .L_go_clc_ret			; B = 0 --> A*B = 0

	; exponent(A*B) = exponent(A)+exponent(B)
	; bias adjustment will be done later
	add		rAE0, rBE0
	adc 	rAE1, rBE1

	; core algorithm for multiplication
	; multiplication will be computed with 72 bit precision --> max error +/-1 LSB
#define MM0 rR6 /* r8 */
#define MM1 rR5 /* r9 = 1 + MM0 */
#define MM2 rR8 /* r6 */
#define MM3 rR7 /* r7 = 1 + MM2 */
#define MM4 rB0
#define MM5 rB1
#define MM6 rB2
#define MM7 rB3
#define MM8 rB4
	; MM8 MM7 MM6 MM5 MM4 MM3 MM2 MM1 MM0
	; rB4.rB3.rB2.rB1.rB0.rR7.rR8.rR5.rR6 = rA6.rA5.rA4.rA3.rA2.rA1.rA0
	;									  * rB6.rB5.rB4.rB3.rB2.rB1.rB0
	; all multiplications "below" 72 bit are left out
	; (e.g. rA4*MM4, rA3*rB1, rA2*rB2, rA1*rB3, rA0*rB4)
	;MM2.MM1.MM0	= rA5 * rB0
	mul rA5, rB0
	X_movw MM0, r0
	clr rZero			; as r1 is set by MUL, use rZero = 0 as zero register
	clr MM2
	clr MM3

	;MM2.MM1.MM0	+= rA4 * rB1
	mul rA4, rB1
	add MM0, r0
	adc MM1, r1
	adc MM2, rZero

	;MM2.MM1.MM0	+= rA3 * rB2
	mul rA3, rB2
	add MM0, r0
	adc MM1, r1
	adc MM2, rZero

	;MM2.MM1.MM0 	+= rA2 * rB3
	mul rA2, rB3
	add MM0, r0
	adc MM1, r1
	adc MM2, rZero

	;MM2.MM1.MM0 	+= rA1 * rB4
	mul rA1, rB4
	add MM0, r0
	adc MM1, r1
	adc MM2, rZero

	;MM2.MM1.MM0 	+= rA0 * rB5	// MM0 can be pushed
	mul rA0, rB5
	add MM0, r0
	adc MM1, r1
	adc MM2, rZero

	;rcall __fp64_saveMul

	;MM3.MM2.MM1	+= rA6 * rB0
	mul rA6, rB0
	add MM1, r0
	adc MM2, r1
	adc MM3, rZero

	;MM3.MM2.MM1	+= rA5 * rB1
	mul rA5, rB1
	add MM1, r0
	adc MM2, r1
	adc MM3, rZero

	;MM3.MM2.MM1	+= rA4 * rB2
	mul rA4, rB2
	add MM1, r0
	adc MM2, r1
	adc MM3, rZero

	;MM3.MM2.MM1 	+= rA3 * rB3
	mul rA3, rB3
	add MM1, r0
	adc MM2, r1
	adc MM3, rZero

	;MM3.MM2.MM1 	+= rA2 * rB4
	mul rA2, rB4
	add MM1, r0
	adc MM2, r1
	adc MM3, rZero

	;MM3.MM2.MM1 	+= rA1 * rB5
	mul rA1, rB5
	add MM1, r0
	adc MM2, r1
	adc MM3, rZero

	;MM3.MM2.MM1 	+= rA0 * rB6	// MM1 can be pushed, B0(=MM4) can be used
	mul rA0, rB6
	add MM1, r0
	adc MM2, r1
	adc MM3, rZero
	clr MM4
	;call __fp64_saveMul

	;MM4.MM3.MM2 	+= rA6 * rB1
	mul rA6, rB1
	add MM2, r0
	adc MM3, r1
	adc MM4, rZero

	;MM4.MM3.MM2 	+= rA5 * rB2
	mul rA5, rB2
	add MM2, r0
	adc MM3, r1
	adc MM4, rZero

	;MM4.MM3.MM2 	+= rA4 * rB3
	mul rA4, rB3
	add MM2, r0
	adc MM3, r1
	adc MM4, rZero

	;MM4.MM3.MM2 	+= rA3 * rB4
	mul rA3, rB4
	add MM2, r0
	adc MM3, r1
	adc MM4, rZero

	;MM4.MM3.MM2 	+= rA2 * rB5
	mul rA2, rB5
	add MM2, r0
	adc MM3, r1
	adc MM4, rZero

	;MM4.MM3.MM2 	+= rA1 * rB6	// MM2 can be pushed, B1 & A0 can be used
	mul rA1, rB6
	add MM2, r0
	adc MM3, r1
	adc MM4, rZero
	clr MM5

	;MM5.MM4.MM3 	+= rA6 * rB2
	mul rA6, rB2
	add MM3, r0
	adc MM4, r1
	adc MM5, rZero

	;MM5.MM4.MM3 	+= rA5 * rB3
	mul rA5, rB3
	add MM3, r0
	adc MM4, r1
	adc MM5, rZero

	;MM5.MM4.MM3 	+= rA4 * rB4
	mul rA4, rB4
	add MM3, r0
	adc MM4, r1
	adc MM5, rZero

	;MM5.MM4.MM3 	+= rA3 * rB5
	mul rA3, rB5
	add MM3, r0
	adc MM4, r1
	adc MM5, rZero

	;MM5.MM4.MM3 	+= rA2 * rB6	// MM3 can be pushed, B2 & A1 can be used
	mul rA2, rB6
	add MM3, r0
	adc MM4, r1
	adc MM5, rZero
	clr MM6

	;MM6.MM5.MM4 	+= rA6 * rB3
	mul rA6, rB3
	add MM4, r0
	adc MM5, r1
	adc MM6, rZero

	;MM6.MM5.MM4 	+= rA5 * rB4
	mul rA5, rB4
	add MM4, r0
	adc MM5, r1
	adc MM6, rZero

	;MM6.MM5.MM4 	+= rA4 * rB5
	mul rA4, rB5
	add MM4, r0
	adc MM5, r1
	adc MM6, rZero

	;MM6.MM5.MM4 	+= rA3 * rB6	// MM4 can be pushed, B3 & A2 can be used
	mul rA3, rB6
	add MM4, r0
	adc MM5, r1
	adc MM6, rZero
	clr MM7

	;MM7.MM6.MM5 	+= rA6 * rB4
	mul rA6, rB4
	add MM5, r0
	adc MM6, r1
	adc MM7, rZero

	;MM7.MM6.MM5 	+= rA5 * rB5
	mul rA5, rB5
	add MM5, r0
	adc MM6, r1
	adc MM7, rZero

	;MM7.MM6.MM5 	+= rA4 * rB6	// MM5 can be pushed, B4 & A3 can be used
	mul rA4, rB6
	add MM5, r0
	adc MM6, r1
	adc MM7, rZero
	clr MM8

	;MM8.MM7.MM6 	+= rA6 * rB5
	mul rA6, rB5
	add MM6, r0
	adc MM7, r1
	adc MM8, rZero

	;MM8.MM7.MM6 	+= rA5 * rB6	// MM6 can be pushed, B5 & A4 can be used
	mul rA5, rB6
	add MM6, r0
	adc MM7, r1
	adc MM8, rZero

	;MM8.MM7 		+= rA6 * rB6	// MM7 can be pushed, B6 & A6 can be used
	mul rA6, rB6
	add MM7, r0
	adc MM8, r1		; this can never overflow, so MM9 is not needed

	;; rA6 and rB6 are normalized, i.e. >= 0x80.  Hence rA6 * rB6 >= 0x4000
	;; and in order to normalize, at most one << is needed.
	;; The temporary result is in MM8.MM7.MM6.MM5.MM4.MM3.MM2.MM1.MM0
	;; and a shift left is needed iff MM8.7 = 0.
	brmi 	11f			; topmost bit is set --> already normalized number

	lsl	MM0						; mantissa <<= 1
	rol MM1
	rol MM2
	rol MM3
	rol MM4
	rol MM5
	rol MM6
	rol MM7
	rol MM8
	sbiw rAE0, 1				; exponent--

11:	clr __zero_reg__

	;; Normalized result is in MM8.MM7.MM6.MM5.MM4.MM3.MM2.MM1.MM0
	;; The added exponents were both biased with 1023, so we have to subtract
	;; one bias again.  The implicit decimal point of the inputs is after
	;; bit 7 of rA6 resp. rB6, but the implicit decimal point of the product
	;; is atfer bit 6 of MM8, hence we have to multiply the result with 2.0
	;; in order to account for that --> subtract only bias - 1.
	subi rAE0, lo8(1023 - 1)	; subtract bias - 1
	sbci rAE1, hi8(1023 - 1)
	; rcall __fp64_saveMul
	brmi	13f					; exponent negative --> denormal number / underflow
	breq	15f		    		; exponent = 0 --> denormal number

	; result exponent > min ==> normalization is possible
	; check for overflow
	; rcall __fp64_saveMul
	ldi rA6, hi8(0x7ff)			; check if exponent < 0x7ff
	cpi rAE0,lo8(0x7ff)
	cpc rAE1, rA6
	brlo 15f					; everything ok, no overflow
	;call __fp64_saveMul

	; exponent >= 0x7ff --> overflow,
111:
	sec							; C = 1: error and returning of packed result
	XJMP _U(__fp64_inf)

	; underflow, cannot even be expressed as denormalized number --> return +/-0
12: rcall .L_szero
	clr rAE1					; does SEZ
	clr rAE0
	rjmp .L_clc_ret				; C=0, Z=1: return 0.0

131: rcall 16f
	rjmp 15f

	; underflow with exponent < 0, check whether denormalization could work
13:	cpi rAE0,lo8(-51)			; check if result could fit into remaining 52 bits
	;call __fp64_saveMul
	brlt 12b					; no --> return 0
	cpi rAE1, 0xFF				; catch cases where exp(a)+exp(b)<-255
	brne 12b

	; mantissa >> -rAE0
14:	rcall 16f					; mantissa >>= 1
	adiw rAE0, 1				; exponent++
	brmi 14b					; exponent still < 0
	;call __fp64_saveMul

	;; shift mantissa 3 bits to prepare for packing (topmost bit is discarded
	;; as it is always 1, therefore only 3 shifts needed instead of 4)
15: ; call __fp64_saveMul
	mov rA6,MM8					; move result into A
	X_movw rA4,MM6
	X_movw rA2,MM4
	X_movw rA0,MM2

	or MM1, MM0					; are there any trailing bits set?
	; rcall __fp64_saveAB
	breq .L_clz_clc_ret
	sbr rA0, 1 					; yes: set LSB to signal possible rounding
.L_clz_clc_ret:
	clz							; return result != 0
.L_clc_ret:
	clc							; C=0: return finite number
	ret

16:	lsr MM8						; mantissa >>= 1
	ror MM7
	ror MM6
	ror MM5
	ror MM4
	ror MM3
	ror MM2
	ror MM1
	ror MM0
	ret
ENDFUNC
