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


/*  uint64_t __fp64_mul64AB (uint64_t A, B);
    return top 64 bit of unsigned multiplication C = A*B
	input	rA7..rA0		64 bit of A
			rB7..rB0		64 bit of B
	output	rC7...rC0		top 64 bit of result A*B 
	modifies r0
 */
FUNCTION __fp64_mul64AB
ENTRY __fp64_mul64AB
	push ZL				; need ZL, ZH
	push ZH
	clr ZL				; clear ZL as lowest 8 bits for multiplication result
	clr ZH				; as r1 is used in mul, we use ZH as an alwys 0 register
	movw rC6, ZL		; and result
	movw rC4, rC6
	movw rC2, rC6
	movw rC0, rC6

	; rC7.rC6...rC0.ZL = rB7.rB6...rB0 * rA7.rA6...rA0
	; multiplications of rAm * rBn will be skipped for m + n < 7
	; rAm*rBn for m+n = 6 --> rC0.ZL
	mul rA0, rB6
	mov ZL, r1
	
	mul rA1, rB5
	add ZL, r1
	adc rC0, ZH
	
	mul rA2, rB4
	add ZL, r1
	adc rC0, ZH
	
	mul rA3, rB3
	add ZL, r1
	adc rC0, ZH
	
	mul rA4, rB2
	add ZL, r1
	adc rC0, ZH
	
	mul rA5, rB1
	add ZL, r1
	adc rC0, ZH
	
	mul rA6, rB0
	add ZL, r1
	adc rC0, ZH
	
	; start with m+n = 7
	mul rA0, rB7	; rAm*rBn for m+n=7 -> rC1.rC0.ZL
;	mov ZL, r0
;	mov rC0, r1
	add ZL, r0
	adc rC0, r1
	adc rC1, ZH
	
	mul rA1, rB6
	add ZL, r0
	adc rC0, r1
	adc rC1, ZH
	
	mul rA2, rB5
	add ZL, r0
	adc rC0, r1
	adc rC1, ZH

	mul rA3, rB4
	add ZL, r0
	adc rC0, r1
	adc rC1, ZH

	mul rA4, rB3
	add ZL, r0
	adc rC0, r1
	adc rC1, ZH

	mul rA5, rB2
	add ZL, r0
	adc rC0, r1
	adc rC1, ZH

	mul rA6, rB1
	add ZL, r0
	adc rC0, r1
	adc rC1, ZH

	mul rA7, rB0
	add ZL, r0
	adc rC0, r1
	adc rC1, ZH

	mul rA1, rB7	; rAm*rBn for m+n=8 -> rC2.rC1.rC0
	add rC0, r0
	adc rC1, r1
	adc rC2, ZH
	
	mul rA2, rB6
	add rC0, r0
	adc rC1, r1
	adc rC2, ZH
	
	mul rA3, rB5
	add rC0, r0
	adc rC1, r1
	adc rC2, ZH
	
	mul rA4, rB4
	add rC0, r0
	adc rC1, r1
	adc rC2, ZH
	
	mul rA5, rB3
	add rC0, r0
	adc rC1, r1
	adc rC2, ZH
	
	mul rA6, rB2
	add rC0, r0
	adc rC1, r1
	adc rC2, ZH
	
	mul rA7, rB1
	add rC0, r0
	adc rC1, r1
	adc rC2, ZH
	
	mul rA2, rB7	; rAm*rBn for m+n=9 -> rC3.rC2.rC1
	add rC1, r0
	adc rC2, r1
	adc rC3, ZH
	
	mul rA3, rB6
	add rC1, r0
	adc rC2, r1
	adc rC3, ZH
	
	mul rA4, rB5
	add rC1, r0
	adc rC2, r1
	adc rC3, ZH
	
	mul rA5, rB4
	add rC1, r0
	adc rC2, r1
	adc rC3, ZH
	
	mul rA6, rB3
	add rC1, r0
	adc rC2, r1
	adc rC3, ZH
	
	mul rA7, rB2
	add rC1, r0
	adc rC2, r1
	adc rC3, ZH
	
	mul rA3, rB7	; rAm*rBn for m+n=10 -> rC4.rC3.rC2
	add rC2, r0
	adc rC3, r1
	adc rC4, ZH
	
	mul rA4, rB6
	add rC2, r0
	adc rC3, r1
	adc rC4, ZH
	
	mul rA5, rB5
	add rC2, r0
	adc rC3, r1
	adc rC4, ZH
	
	mul rA6, rB4
	add rC2, r0
	adc rC3, r1
	adc rC4, ZH
	
	mul rA7, rB3
	add rC2, r0
	adc rC3, r1
	adc rC4, ZH
	
	mul rA4, rB7	; rAm*rBn for m+n=11 -> rC5.rC4.rC3
	add rC3, r0
	adc rC4, r1
	adc rC5, ZH

	mul rA5, rB6
	add rC3, r0
	adc rC4, r1
	adc rC5, ZH

	mul rA6, rB5
	add rC3, r0
	adc rC4, r1
	adc rC5, ZH

	mul rA7, rB4
	add rC3, r0
	adc rC4, r1
	adc rC5, ZH

	mul rA5, rB7	; rAm*rBn for m+n=12 -> rC6.rC5.rC4
	add rC4, r0
	adc rC5, r1
	adc rC6, ZH
	
	mul rA6, rB6
	add rC4, r0
	adc rC5, r1
	adc rC6, ZH
	
	mul rA7, rB5
	add rC4, r0
	adc rC5, r1
	adc rC6, ZH
	
	mul rA6, rB7	; rAm*rBn for m+n=13 -> rC7.rC6.rC5
	add rC5, r0
	adc rC6, r1
	adc rC7, ZH
	
	mul rA7, rB6
	add rC5, r0
	adc rC6, r1
	adc rC7, ZH
	
	mul rA7, rB7	; rAm*rBn for m+n=14 -> rC7.rC6 (carry not possible)
	add rC6, r0
	adc rC7, r1

	tst ZL			; do we have to round
	brpl 1f			; no
	ldi ZL, 1		; yes, add 1 to lowest  bit
	add rC0, ZL
	adc rC1, ZH
	adc rC2, ZH
	adc rC3, ZH
	adc rC4, ZH
	adc rC5, ZH
	adc rC6, ZH
	adc rC7, ZH
	
1:	mov r1, ZH	; clear r1 without affecting flags
	
	pop ZH		; restore used registers and return
	pop ZL
	
	ret

/*  uint64_t __fp64_domul64AB (uint64_t A, B);
    return top 64 bit of unsigned multiplication A = A*B
	input	rA7..rA0		64 bit of A
			rB7..rB0		64 bit of B
	output	rA7...rA0		top 64 bit of result A*B 
 */

ENTRY __fp64_domul64AB
	push rC0	; save C registers
	push rC1
	push rC2
	push rC3
	push rC4
	push rC5
	push rC6
	push rC7
	
	XCALL _U(__fp64_mul64AB)	; C = A * B
	
	XCALL _U(__fp64_movAC)		; move result to A
	
	pop rC7		; restore registers
	pop rC6
	pop rC5
	pop rC4
	pop rC3
	pop rC2
	pop rC1
	pop rC0
	
	ret
	
ENDFUNC
