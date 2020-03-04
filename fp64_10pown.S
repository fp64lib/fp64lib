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



/*  uint64_t __fp64_10pown (int16_t n);
    internal function to return 64 bit significant of 10^n
	input	XH.XL	n
	output	rA7...rA0		significand of 10^n
			rAE1.rAE0		exponent in base 2 of 10^n
	modifies rB7..rB0
			 rC7..rC0
 */
FUNCTION __fp64_10pown
ENTRY __fp64_10pown
	push YL
	push YH
	ldi YL, 3			; pot_exp2 = 3		// first 3 bits of pot are the leading bits
	clr YH

	ldi ZL, lo8(.L_10)	; pot = 10 << 60
	ldi ZH, hi8(.L_10)
	bst XH, 7			; neg = 0
	brtc 0f				; if( n < 0 ) {
	neg XH				;	neg = 1; n = -n
	neg XL				; 
	sbci XH, 0
	adiw ZL, 8			; 	pot = 0.1 << 63

0:	lpm rB7, Z+			; load pot with 10.0 or 0.1
	lpm rB6, Z+
	lpm rB5, Z+
	lpm rB4, Z+
	lpm rB3, Z+
	lpm rB2, Z+
	lpm rB1, Z+
	lpm rB0, Z+

	clr rAE1			; exp2 = 0 // exponent of result in base 2
	clr rAE0

	ldi rA7, 0x80		; res = 1 << 63 // res = 1.0
	clr rA6
	movw rA4, rAE0
	movw rA2, rAE0
	movw rA0, rAE0
	
1:	adiw XL, 0			; while( 0 != n ) {
	breq 3f
	
	sbrs XL, 0					; 	if( 0 != (n & 1) ) {
	rjmp 2f
	XCALL _U(__fp64_mul64AB)	;		res = res * pot;
	XCALL _U(__fp64_lshift64)	;		// align result		
	XCALL _U(__fp64_movAC)		; 		move result of res * pot to res
								; 	}

	add rAE0, YL		; exp2 += pot_exp2
	adc rAE1, YH

	brts 11f			; if( !neg )
	sub rAE0, r0		; 	exp2 += 1 - shiftLeft(res)
	sbc rAE1, r1
	adiw rAE0, 1
	rjmp 2f
	
11:	add rAE0, r0		; else
	adc rAE1, r1		;	exp2 += shiftLeft(res)
	
2:	push rA7			; save res
	push rA6
	push rA5
	push rA4
	push rA3
	push rA2
	push rA1
	push rA0
	
	XCALL _U(__fp64_movAB)		; B = A = pot
	XCALL _U(__fp64_mul64AB)	; pot = pot * pot
	XCALL _U(__fp64_lshift64)
	XCALL _U(__fp64_movBC)
	
	lsl YL					; pot_exp2 <<= 1
	rol YH
	brts 12f				; if( !neg )
	adiw YL, 1				; 	pot_exp2 += 1 - shiftLeft(pot)
	sub YL, r0
	sbc YH, r1
	rjmp 13f
	
12:	add YL, r0				; else
	adc YH, r1				;	pot_exp2 += shiftLeft(pot)

13:	pop rA0					; restore res
	pop rA1
	pop rA2
	pop rA3
	pop rA4
	pop rA5
	pop rA6
	pop rA7

	; rcall __fp64_saveAB
	
	lsr XH					; n >>= 1
	ror XL
	
	rjmp 1b					; repeat until n is 0

3:	brtc 4f					; if( neg )
	neg rAE1				;	exp2 = -exp2;
	neg rAE0
	sbci rAE1, 0
	
4:	pop YH
	pop YL
	ret	
	
.L_10:	; 10.0
	.byte 0xa0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.L_01:	; 0.1
	.byte 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcd

/*  uint64_t fp64_10pown (int16_t n, int16_t *exp2);
    return 64 bit significant of 10^n
	input	rA7.rA6	n		exponent for 10^n
			rA5.rA4 *exp2	point for saving exponent in base 2 of result
	output	rA7...rA0		significand of 10^n
			*exp2			exponent in base 2 of result
 */
ENTRY fp64_10pown
	XCALL _U(__fp64_pushCB) ; preserve register set

	movw XL, rA6	; for __fp64_10pown, n has to be in XH.XL
	push rA4		; save pointer
	push rA5
	
	rcall __fp64_10pown
	
	pop XH
	pop XL
	adiw XL, 0
	breq 1f			; skip NULL pointer
	st X+, rAE0		; save exp2
	st X, rAE1
	
1:	
	XCALL _U(__fp64_popBC)	; restore register set
	nop						; hack to avoid tail call optimization
	ret

ENDFUNC
