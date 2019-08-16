/* Copyright (c) 2018  Uwe Bissinger
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

/*	float64_t fp64_log( float64_t x );
	returns the natural logarithm ln of x
*/
FUNCTION fp64_log

	; case|	A	  |	log(A)
	;-----+-------+------
	; 1	  |	< 0   |	NaN		< 0 includes -Inf
	; 2	  |	NaN	  |	NaN
	; 3	  |	+Inf  |	+Inf	-Inf is part of "< 0"
	; 4	  |	0	  |	-Inf
	; 5   | 1     | 0		this case was included to avoid nasty rounding

.L_nan:		; return NaN
	XJMP	_U(__fp64_nan)
	
.L_inf:		; return -INF
	set
	XJMP _U(__fp64_inf)
	
.L_zero:	; return 0.0
	XJMP _U(__fp64_zero)
	
0:	; check if rA5 to rA0 are 0
	cpc rA5, r1
	cpc rA4, r1
	cpc rA3, r1
	cpc rA2, r1
	cpc rA1, r1
	cpc rA0, r1
	ret
	
ENTRY fp64_log
	; XCALL _U(__fp64_splitA)
	tst rA7				; x < 0?
	brmi .L_nan			; if x < 0 (case 1), log(x) = NaN
	cpi rA7, 0x7f		; x is NaN or +INF?
	brne 1f				; no -> calculate
	cpi rA6, 0xf0
	brlo 1f				; no -> calculate
	ret					; yes, cases 2&3, return x (NaN for NaN, +Inf for +InF)

1:	cp rA7, r1			; is A = 0 ?
	cpc rA6, r1
	rcall 0b
	breq .L_inf			; yes, case 4, return -Inf
	
	cpi rA7, 0x3f		; is A = 1.0 ?
	brne 2f
	cpi rA6, 0xf0
	rcall 0b
	;rcall __fp64_saveAB
	breq .L_zero		; yes, return 0.0
	
2:	push rC7			; save used registers
	push rC6
	push rC5
	push rC4
	push rC3
	push rC2
	push rC1
	push rC0
	push rB7
	push rB6
	push rB5
	push rB4
	push rB3
	push rB2
	push rB1
	push rB0

	push rA0			; save x (only necessary for subnormal numbers)
	push rA1
	push rA2
	push rA3
	push rA4
	push rA5
	push rA6			; save exponent of x
	push rA7
	;rcall __fp64_saveAB
	
	tst rA7				; check for subnormal numbers
	brne 22f
	cpi rA6, 0x10
	brsh 22f			; if exponent >= 1, normal number

	; for subnormal numbers, we have to shift significand 1 bit to the left, until topmos bit is set
21:	sbrc rA6, 4
	rjmp 22f
	lsl rA0
	rol rA1
	rol rA2
	rol rA3
	rol rA4
	rol rA5
	rol rA6
	rjmp 21b
	
22:	rcall __fp64_saveAB
	ldi rA7, 0x3f		; normalize x to be in range 0.5 - 1.0
	andi rA6, 0x0f		; --> exponent of x is 0x3fe
	ori rA6, 0xe0
	
	movw rC6, rA6		; save x
	movw rC4, rA4
	movw rC2, rA2
	movw rC0, rA0

	rcall .L_B1			; load B with one
	; rcall __fp64_saveAB
	XCALL _U(fp64_add)	; x + 1
	
	_SWAPW rC6, rA6		; save result of x+1  and load A with x
	_SWAPW rC4, rA4
	_SWAPW rC2, rA2
	_SWAPW rC0, rA0
	clr r1
	
	rcall .L_B1			; load B with one
	XCALL _U(fp64_sub)	; x - 1

	movw rB6, rC6		; restore b = x + 1
	movw rB4, rC4
	movw rB2, rC2
	movw rB0, rC0


	XCALL _U(fp64_div)	; y = (x-1) / (x+1)

	ldi ZL, lo8(.L__tableLog)
	ldi ZH, hi8(.L__tableLog)
	XCALL _U(__fp64_powsodd)	; approximate log by power series
	
	movw rC6, rA6			; save result of log(y)
	movw rC4, rA4
	movw rC2, rA2
	movw rC0, rA0
	
	; restore exponent and convert it into long
	pop rAE1				; restore exponent			
	pop rAE0
	pop rA5					; and rest of A
	pop rA4
	pop rA3
	pop rA2
	pop rA1
	pop rA0
	
	andi rAE1, 0x7f			; clear sign bit
	mov rA6, rAE0			; save start of significand
	
	; rcall __fp64_saveAB
	lsr rAE1				; shift down exponent by 4 bits
	ror rAE0
	lsr rAE1
	ror rAE0
	lsr rAE1
	ror rAE0
	lsr rAE1
	ror rAE0
	
	cp rAE0, r1				; is exponent = 0?
	cpc rAE1, r1
	brne 9f					; no --> normal number
	
	; handle subnormal numbers
	; adiw rAE0, 1			; adjust exponent
	swap rA6
	andi rA6, 0xf0			; get rid of exponent part
	breq 3f					; some bits set?
	; no, check until we got a top bit
	mov rA5, rA6
	rjmp 7f

3:	; no bits set in rA6 --> we have to skip 4 bits
	subi rAE0, 4
	
6:	tst rA5					; are there any signifcand bits?
	brne 7f					; yes, find them
	subi rAE0, 8			; no, we have to skip 8 bits
	mov rA5, rA4			; significand << 8
	mov rA4, rA3
	mov rA3, rA2
	mov rA2, rA1
	mov rA1, rA0			; loop will terminate as 0.0 is excluded 
	clr rA0					
	rjmp 6b
	
7:	brmi 8f					; stop if we got a bit in topmost position
	dec rAE0				; exponent--
	lsl rA5					; move up 1 bit
	brne 7b					; until we got a bit in topmost position

8:	; end of subnormal handling, set exponent
	sbrc rAE0, 7
	ldi rAE1, 0xff			; sign extension for exponent
	movw rA4, rAE0
	mov rA6, rAE1			; now for 32 bits
	mov rA7, rAE1
	rjmp 10f
	
9:	; normal number 
	movw rA4, rAE0
	clr rA6					; top byte = 0
	clr rA7
10:	;rcall __fp64_saveAB
	subi rA4, 0xfe			; exponent - base
	sbci rA5, 0x03
	sbc rA6, r1
	sbc rA7, r1
	
	;rcall __fp64_saveAB
	XCALL _U(__fp64sidf) ; as a float
	
	ldi ZL, lo8(.L_log2) ; B = log(2)
	ldi ZH, hi8(.L_log2)
	rcall __fp64_loadB
	XCALL _U(fp64_mul)
	
	movw rB6, rC6		; restore B = log(y)
	movw rB4, rC4
	movw rB2, rC2
	movw rB0, rC0
	XCALL _U(fp64_add)	; 

99:	
	pop rB0				; restore registers
	pop rB1
	pop rB2
	pop rB3
	pop rB4
	pop rB5
	pop rB6
	pop rB7
	pop rC0
	pop rC1
	pop rC2
	pop rC3
	pop rC4
	pop rC5
	pop rC6
	pop rC7
	
	ret					; and return
	
.L_B1:					; load B with one	
	ldi ZL, lo8(.L_1)
	ldi ZH, hi8(.L_1)
	
	; load a float64_t number into rB7...rB0
	; from address pointed to by ZH.ZL
ENTRY __fp64_loadB
	lpm rB7, Z+
	lpm rB6, Z+
	lpm rB5, Z+
	lpm rB4, Z+
	lpm rB3, Z+
	lpm rB2, Z+
	lpm rB1, Z+
	lpm rB0, Z+	
	ret
	
.L_1:	; 1.0 = 0x3ff000000000
	.byte 0x3f, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	
.L_log2: ; log(2) = x3FE62E42FEFA39EF = 0.69314718055994529
	.byte 0x3F, 0xE6, 0x2E, 0x42, 0xFE, 0xFA, 0x39, 0xEF
	
.L__tableLog:
	; .byte 16	; polynom power = 16 --> 17 entries
	; .byte 0x3F, 0xAF, 0x07, 0xC1, 0xF0, 0x7C, 0x1F, 0x08 ; 0x3FAF07C1F07C1F08 = 0.060606060606060608 = 2 / 33
	.byte 15	; polynom power = 15 --> 16 entries
	.byte 0x3F, 0xB0, 0x84, 0x21, 0x08, 0x42, 0x10, 0x84 ; 0x3FB0842108421084 = 0.064516129032258063 = 2 / 31
	; .byte 14	; polynom power = 14 --> 15 entries
	.byte 0x3F, 0xB1, 0xA7, 0xB9, 0x61, 0x1A, 0x7B, 0x96 ; 0x3FB1A7B9611A7B96 = 0.068965517241379309 = 2 / 29
	; .byte 13	; polynom power = 13 --> 14 entries
	.byte 0x3F, 0xB2, 0xF6, 0x84, 0xBD, 0xA1, 0x2F, 0x68 ; 0x3FB2F684BDA12F68 = 0.07407407407407407  = 2 / 27 
	.byte 0x3F, 0xB4, 0x7A, 0xE1, 0x47, 0xAE, 0x14, 0x7B ; 0x3FB47AE147AE147B = 0.080000000000000002 = 2 / 25
	.byte 0x3F, 0xB6, 0x42, 0xC8, 0x59, 0x0B, 0x21, 0x64 ; 0x3FB642C8590B2164 = 0.086956521739130432 = 2 / 23
	.byte 0x3F, 0xB8, 0x61, 0x86, 0x18, 0x61, 0x86, 0x18 ; 0x3FB8618618618618 = 0.095238095238095233 = 2 / 21
	.byte 0x3F, 0xBA, 0xF2, 0x86, 0xBC, 0xA1, 0xAF, 0x28 ; 0x3FBAF286BCA1AF28 = 0.10526315789473684  = 2 / 19
	.byte 0x3F, 0xBE, 0x1E, 0x1E, 0x1E, 0x1E, 0x1E, 0x1E ; 0x3FBE1E1E1E1E1E1E = 0.11764705882352941  = 2 / 17
	.byte 0x3F, 0xC1, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11 ; 0x3FC1111111111111 = 0.13333333333333333  = 2 / 15
	.byte 0x3F, 0xC3, 0xB1, 0x3B, 0x13, 0xB1, 0x3B, 0x14 ; 0x3FC3B13B13B13B14 = 0.15384615384615385  = 2 / 13
	.byte 0x3F, 0xC7, 0x45, 0xD1, 0x74, 0x5D, 0x17, 0x46 ; 0x3FC745D1745D1746 = 0.18181818181818182  = 2 / 11
	.byte 0x3F, 0xCC, 0x71, 0xC7, 0x1C, 0x71, 0xC7, 0x1C ; 0x3FCC71C71C71C71C = 0.22222222222222221  = 2 / 9 
	.byte 0x3F, 0xD2, 0x49, 0x24, 0x92, 0x49, 0x24, 0x92 ; 0x3FD2492492492492 = 0.2857142857142857   = 2 / 7
	.byte 0x3F, 0xD9, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9A ; 0x3FD999999999999A = 0.40000000000000002  = 2 / 5
	.byte 0x3F, 0xE5, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55 ; 0x3FE5555555555555 = 0.66666666666666663  = 2 / 3
	.byte 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; 0x4000000000000000 = 2.00000000000000000  = 2 / 1
	.byte 0x00												; byte needed for code alignment to even adresses!
	
	
ENDFUNC
	