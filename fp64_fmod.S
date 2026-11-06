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

#include "fp64asm.h"
#include "fp64def.h"

/* float64_t fp64_fmod (float64_t x, float64_t y);
     The fp64_fmod() function computes the remainder of dividing x by y. The
     return value is x - n*y, where n is the quotient of x/y, rounded
     towards zero to an integer.
 */

FUNCTION fp64_fmod
/* float64_t fp64_fmod (float64_t x, float64_t y);
     The fp64_fmod() function computes the remainder of dividing x by y. The
     return value is x - n*y, where n is the quotient of x/y, rounded
     towards zero to an integer.
 */
	
ENTRY fp64_fmod
ENTRY_DOUBLE fmod fmodl
	push rC7
	push rC6
	mov rC6, r0					; call fmodn with np = NULL
	mov rC7, r0
	rcall fp64_fmodn
	pop rC6
	pop rC7
	ret 

	; do special case handling
	; A or B is NaN and/or Inf or A is 0
	; case|	A	  |	B	 |	fmod(A,B)
	;-----+-------+------+------
	; 1	  |	NaN	  |	any	 |	NaN
	; 2	  |	any	  |	NaN	 |	NaN
	; 3	  |	Inf	  |	0	 |	NaN
	; 4   | Inf   | Inf  |  NaN
	; 5	  |	Inf	  |	!= 0 |	NaN
	; 6	  |	0	  |	Inf	 |	 0
	; 7	  |	!= 0  |	Inf	 |	 A
	; 8   | 0     | 0    |  NaN
	; 9   | 0     | != 0 |   0

/* float64_t fp64_fmodn (float64_t x, float64_t y, long long *np);
     The fp64_fmod() function computes the remainder of dividing x by y. The
     return value is x - n*y, where n is the quotient of x/y, rounded
     towards zero to an integer.
	 n is stored in *np, if np is != NULL
 */
 	; cases 1-5: result is NaN
.L_nan:
	XCALL	_U(__fp64_popB)
	XJMP	_U(__fp64_nan)

0:	brne .L_nan					; as NaN has priority, result will be NaN, cases 1&2

	; from  now on, neither A nor B are NaN
	; so one or both are +Inf/-Inf
	; check if A is Inf
	XCALL	_U(__fp64_pscA)
	breq	.L_nan				; A is +/-Inf, cases 3,4,5

	; A is not Inf, so B must be Inf, cases 6,7 --> return A
	XCALL _U(__fp64_popB)
	XJMP _U(__fp64_pretA)


ENTRY fp64_fmodn
	XCALL _U(__fp64_pushB)		; save working registers

	; Write 0 for next cases: Zero, Inf or NaN.
	X_movw	XL, rC6				; move pointer to one of the pointer registers
	adiw	XL, 0
	breq	91f					; skip, if pointer is == NULL
	st X+, r1					; *np = 0
	st X+, r1
	st X+, r1
	st X+, r1
	st X+, r1
	st X+, r1
	st X+, r1
	st X, r1

91:
	; split A and B and check exceptions
	mov r0, rB7					; save sign for adjusting n
    cbr rB7, 0x80				; calculation of fmod is done with |B|
 	XCALL	_U(__fp64_split3)
	brcs	0b					; handle special cases NaN / Inf
	breq	.L_Azero			; handle fmod( 0, B ) --> 0

	XCALL	_U(__fp64_pscB)
	breq	.L_nan				; finite (!=0) / 0.0 --> NaN

	push rC0					; save working registers
	push rC1
	push rC2
	push rC3
	push rC4
	push rC5
	push rC6
	push rC7
	mov rC7, r0
	rcall __fp64_fmod_pse		; do the calculation, result will be in rA7..0, n in rC0..6
	
	X_movw rB0, rC0				; save n and sign(B) into B
	X_movw rB2, rC2
	X_movw rB4, rC4
	X_movw rB6, rC6

	pop rC7						; restore used registers, n is saved to rB1..rB7
	pop rC6
	pop rC5
	pop rC4
	pop rC3
	pop rC2
	pop rC1
	pop rC0

.L_exit:
	mov r0, r1					; save Carry into r0.0 (C=1 if result is packed)
	adc r0, r1	
	bld r0, 7					; get sign of A into r0
	andi rB7, 0x80				; extract sign of B
	eor r0, rB7					; r0.7 has sign(A)^sign(B)
	
	X_movw	XL, rC6				; move pointer to one of the pointer registers
	adiw	XL, 0				; skip if pointer is == NULL
	breq	.L_popRet

	mov rB7, r1					; as n only uses 54 bit, i.e. rB0..rB6, 
								; we have to extend it to 64 bits
	tst r0
	brpl .L_stoN				; if sign(A) = sign(B), n stays positive

	XCALL	_U(__fp64_swapAB)	; otherwise return -n
	XCALL	_U(__negdi2)
	XCALL	_U(__fp64_swapAB)

.L_stoN:	
	st X+, rB0					; save n in *np
	st X+, rB1
	st X+, rB2
	st X+, rB3
	st X+, rB4
	st X+, rB5
	st X+, rB6
	st X, rB7

.L_popRet:						; pop B and return
	XCALL _U(__fp64_popB)
	sbrc r0, 0					; is result already packed (i.e. C=1 was formerly signalled) ?
	ret							; yes, return with packed result
	sbrs rA6, 7					; subnormal number?
	XCALL _U(__fp64_lslA)		; yes, A <<= 1
	XJMP _U(__fp64_pretA)		; finally pack the result and return

.L_Azero:
	; A is 0, B is not Inf or NaN, cases 8, 9
	XCALL	_U(__fp64_pscB)
	brne	30f
	rjmp	.L_nan				; fmod(0,0), case 8 -->  NaN
30:	XCALL 	_U(__fp64_szero)	; set division result to 0/-0 and n to +0
	XCALL	_U(__fp64_movBA)
	andi rB7, 0x7f				; clear sign flag coming from A
	sec							; signal packed result
	rjmp .L_exit
	
/* float64_t_intern fp64_fmod_pse (float64_t_intern x, float64_t_intern y);
     The fp64_fmod_pse() function computes the remainder of dividing x by y. The
     return value is x - n*y, where n is the quotient of x/y, rounded
     towards zero to an integer.
	 It does not handle any special cases, the caller has to assure that both
	 x and y are finite and != 0

	 In:		rAE0..rAE1, rA0..rA7	x in internal 10 byte format
				rBE0..rBE1, rB0..rB7	y in internal 10 byte format
	 Out:		rAE0..rAE1, rA0..rA7	x in internal 10 byte format or
				rA0..rA7				x in float64_t/IEEE format
				rC0..rC6				|n| = |x/y|
				C						C=1 if x is in float64_t/IEEE format
	 Modifies:	all registers in In & Out
				r0
				all flags excluding T
 */
 
 /* Algorithm:
	r0 = 1;
	counter = 0;
	A = x; B = y;
	if( A < B ) {
		// A is already the result
		Carry = 0;
		return( A );
		}
	if( A == B )
		return( 0 * sign(A^B) );
	Normalize A;
	Normalize B;
	expo = exponent(A) - exponent(B);
	if( expo >= 54 ) {
		// A > 2^54 * B --> fmod cannot be determined exactly
		return( 0 * sign(A^B) );
		}
	do {
		counter++;
		A -= B;
		if( A == 0 ) {
			// A is a 2^n multiple of B
			for( ; --expo >= 0; )
				counter <<= 1;
			return( 0 * sign(A^b );
			}
		if( A < 0 ) {
			// A was < B --> undo
			counter--;
			A += B;
			}
		if( --expo < 0 )
			break;

	}

*/

.L_sz1:
	rcall .L_add1				; fabs(A) = fabs(1) --> n = 1, fmod = 0

	; A is 0, B is not 0, case 9 --> 0
.L_sz:
	clr rAE0
	clr rAE1
	sec
	XJMP	_U(__fp64_szero)

.L_retA:
	clc							; result is in A, unpacked
	ret

ENTRY	__fp64_fmod_pse			; post split entry

	clr r0
	inc r0						; r0 will contain 1 to aid +1 / -1 operations
	clr rC0						; init counter n = 0
	clr rC1
	X_movw rC2, rC0
	X_movw rC4, rC0
	clr rC6						; preserve rC7!

	XCALL _U(__fp64_cpcAB)		; check whether A < B
	cpc rAE0, rBE0
	cpc rAE1, rBE1
	brlo .L_retA				; if fabs(A) < fabs(B), A is already the result
	breq .L_sz1					; if fabs(A) = fabs(B) --> return sign(A^B)*0

	; from now on fabs(A) > fabs(B)
	; as we do allow subnormal numbers, mantissa of A might not start with
	; a leading 1 bit, so normalize A
	tst rA6
	brmi 3f

2:	sbiw rAE0,1					; decrease exponent
	XCALL _U(__fp64_lslA)		; A <<= 1
	brpl 2b						; repeat until we have a leading 1 bit

3:	; as we do allow subnormal numbers, mantissa of B might not start with
	; a leading 1 bit, so normalize B
	tst rB6
	brmi 5f

4:	sbiw rBE0,1					; decrease exponent
	lsl	rB0						; B <<= 1
	rol	rB1
	rol	rB2
	rol	rB3
	rol	rB4
	rol	rB5
	rol	rB6
	brpl 4b						; repeat until we have a leading 1 bit

5:	sub rAE0, rBE0				; exponent(A) - exponent(B)
	sbc rAE1, rBE1
	tst rAE1
	brne .L_sz					; A > 2^256*B --> fmod(A,B) can not exactly be determined , return 0
	cpi rAE0, 54
	brsh .L_sz					; A > 2^54*B --> fmod(A,B)  can not exactly be determined , return 0
	clr rA7						; highest A byte
	clr rB7						; and B byte

.Loop:
	; inc r0
	rcall .L_add1				; counter++
	XCALL _U(__fp64_subAB)		; try to subtract B, A -= B
	sbc	rA7, rB7
	breq 66f					; result is 0
	brpl 6f						; if A > B, success

	sub rC0, r0					; counter--
	sbc rC1, r1
	sbc rC2, r1
	sbc rC3, r1
	sbc rC4, r1
	sbc rC5, r1
	sbc rC6, r1
	XCALL _U(__fp64_addAB)		; else undo the sub, A += B
	adc	rA7, rB7
6:	sbiw rAE0,1					; exponent(A)--
	brmi 7f						; if exponent < 0, everything is calculated

	rcall .L_lslC				; shift counter
	XCALL _U(__fp64_lslA)		; A <<= 1
	rol rA7
	rjmp .Loop
	
66:	sbiw rAE0, 1
	brmi 67f
	rcall .L_lslC				; shift counter
	rjmp 66b
67: rjmp .L_sz

7:	sbiw rBE0,1					; exponent B--
	brmi 10f
	breq 9f
8:	tst rA6						; is topmost bit of result set?
	brmi 9f						; yes, we can return
	XCALL _U(__fp64_lslA)		; A <<= 1
	rol rA7
	sbiw rBE0, 1
	brne 8b						; repeat until topmost bit or exponent = 0, i.e. subnormal number
9:	adiw rBE0, 1				; adjust exponent
.L_pk:
	X_movw rAE0, rBE0
	clc
	ret

10:
	XCALL _U(__fp64_lsrA)		; A >>= 1
	adiw rBE0, 1				; exponent++
	brne 10b					; repeat until exponent = 0
	rjmp 9b

.L_add1:						; C += 1
	add rC0, r0					; counter++
	adc rC1, r1
	adc rC2, r1
	adc rC3, r1
	adc rC4, r1
	adc rC5, r1
	adc rC6, r1
	ret
	
.L_lslC:						; C <<= 1
	lsl rC0						; shift counter
	rol rC1
	rol rC2
	rol rC3
	rol rC4
	rol rC5
	rol rC6
	ret
	
ENDFUNC
