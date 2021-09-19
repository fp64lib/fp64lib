/* Copyright (c) 2018-2021  Uwe Bissinger
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

#if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

/*  float64_t fp64_modff (float64_t x, float64_t *iptr);
	float64_t fp64_modf (float64_t x, float64_t *iptr);

    The fp64_modf() function breaks the argument x into an integral part and a
    fractional part, each of which has the same sign as x. The integral part
    is stored in iptr.
	This implementation skips writing by zero pointer.
	Example: modf(123.45) makes 0.45 (return value) + 123.0 (stored in *iptr)
 */

	; do special case handling
	; case|	 x	  |	modf |	*iptr
	;-----+-------+------+------
	; 1	  |	NaN	  |	NaN  |	NaN
	; 2	  |	Inf	  |	 0   |	Inf
	; 3	  |	 0	  |	 0   |	0.0
	; 4	  |	>2^53 |	0.0  |   x
	; 5   | <1.0  |  x   |  0.0

FUNCTION fp64_modf
0:	breq 1f		; if Inf
	XCALL _U(__fp64_nan)	; case 1: result = NaN
	XCALL _U(__fp64_movBA)	;         *iptr = NaN
	rjmp .L_write 
	
1:	XCALL  _U(__fp64_inf)	; case 2: result = Inf
.L_zero:					;         *iptr = 0.0 
	clr rB7					
	clr rB6
	movw rB4, rB6
	movw rB2, rB6
	movw rB0, rB6
	bld rB7, 7				; copy sign from x
	rjmp .L_write

	; case 5: x < 1.0
2:	tst rA6					; check for subnormal number
	brmi 21f
	XCALL _U(__fp64_lslA)
 21:
	; rcall __fp64_saveABC
	XCALL _U(__fp64_pretA)	; case 5: result = x
	rjmp .L_zero			;         *iptr = 0.0
	
.L_nfrc: ; case 4 fabs(x) > 2^53 --> no fraction
	XCALL _U(__fp64_pretA)	; pack result
	XCALL _U(__fp64_movBA)	; *iptr = x
	clr rA7					; modf(x) = 0.0
	bld rA7, 7				; copy sign from x
	clr rA6
	clr r0
	movw rA4, r0
	movw rA2, r0
	movw rA0, r0
	rjmp .L_write

ENTRY fp64_modf
ENTRY fp64_modff
	XCALL _U(__fp64_pushCB)	; save used registers
	push rB7				; and iptr
	push rB6
	; rcall __fp64_saveAB
	
	XCALL _U(__fp64_splitA)
	; rcall __fp64_saveAB
	brcs 0b					; NaN or +/i INF
	breq .L_zero			; x = 0? --> return 0
	
	; is there an integral part?
	cpi rAE1, hi8(0x03ff)	; is exponent < 0x3ff, i.e. x < 1.0?
	brlo 2b					; yes, case 5: return x
	brne 3f					; no, break x into parts
	cpi rAE0, lo8(0x03ff)
	brlo 2b
	
3:	; fabs(x) >= 1.0
	cpi rAE1, hi8(0x3ff+53)	; x > 2^53
	brlo 4f
	brne .L_nfrc
	cpi rAE0, lo8(0x3ff+53)
	brsh .L_nfrc

4:	; fabs(x) > 1.0 and < 2^53, there is a fraction part
	; rcall __fp64_saveAB
	
	ldi rB6, 0xff			; set mask to eleminate fraction
	mov rC7, rB6
	mov rC6, r1
	mov rC5, r1
	mov rC4, r1
	movw rC2, rC4
	movw rC0, rC4

	XCALL _U(__fp64_movBAx)	; B will contain the integer part
	subi rAE0, 0xfe 		; A will contain the fraction part < 1.0
	
	; get rid of integer part by shifting A left until A is < 1
5:
	breq 6f
	rcall __fp64_lslA		; A << 1 , get rid of an integer digit
	asr rC7				; C >> 1 (add 1 more integer digit to mask)
	ror rC6
	ror rC5
	ror rC4
	ror rC3
	ror rC2
	ror rC1
	ror rC0
	dec rAE0
	rjmp 5b

6:
	ldi rAE1, 0x03			; set exponent to 0x3fe = 0.5
	ldi rAE0, 0xfe
	; A is now modf(x)
	; mask out the fraction of x in B 
	; rcall __fp64_saveABC
	and rB6, rC6
	and rB5, rC5
	and rB4, rC4
	and rB3, rC3
	and rB2, rC2
	and rB1, rC1
	and rB0, rC0
	
	; check for modf(x) == 0
	mov r0, rA6
	or r0, rA5
	or r0, rA4
	or r0, rA3
	or r0, rA2
	or r0, rA1
	or r0, rA0
	brne 7f				; there is a fraction --> normalize it

	mov rA7, r1			; set modf(x) to 0.0
	bld rA7, 7			; get sign from x
	rjmp .L_packB		; return with *iptr = x

	; fraction != 0, now normalize fraction
7:
	tst rA6			
	brmi .L_retAB			; stop as soon as topmost bit is set
	XCALL _U(__fp64_lslA)	; otherwise A << 1
	dec rAE0				; and reduce the exponent
	rjmp 7b

	; fraction is now normalized
	; A contains modf, B has integer part
	; now pack A and B
.L_retAB:
	XCALL _U(__fp64_pretA)

.L_packB:
	; rcall __fp64_saveAB

	XCALL _U(__fp64_swapAB)
	XCALL _U(__fp64_pretA)
	XCALL _U(__fp64_swapAB)

.L_write:	
	pop ZL					; restore iptr
	pop ZH
	adiw XL, 0
	breq 99f				; skip write if iptr == 0
	
	;  store packed integer part B in *iptr
	st Z+, rB0
	st Z+, rB1
	st Z+, rB2
	st Z+, rB3
	st Z+, rB4
	st Z+, rB5
	st Z+, rB6
	st Z+, rB7

99:	; restore used B registers and return with A = modf(x)
	XCALL _U(__fp64_popBC)
	nop						; hack to avoid tail call optimization
	ret
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
