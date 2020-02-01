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

/*	float64_t fp64_logx( float64_t x );
	returns the natural logarithm ln of x
*/
FUNCTION fp64_logx

	; case|	A	  |	log(A)
	;-----+-------+------
	; 1	  |	< 0   |	NaN		< 0 includes -Inf
	; 2	  |	NaN	  |	NaN
	; 3	  |	+Inf  |	+Inf	-Inf is part of "< 0"
	; 4	  |	0	  |	-Inf
	; 5   | 1     | 0		this case was included to avoid nasty rounding

	; check non-finite numbers
.L_nf:
	brne .L_nan					; case 2: NaN  --> return NaN
	brts .L_nan					; case 1: -Inf --> return NaN
	XJMP _U(__fp64_inf)			; case 3: +Int --> return +Inf
	
	; cases 1 & 2: return NaN
.L_nan:
	XJMP	_U(__fp64_nan)
	
	; case 4: return -Inf for x = 0
.L_inf:
	set
	XJMP _U(__fp64_inf)
	
	; case 5: return 0.0 for x = 1.0
.L_zero:	; return 0.0
	XJMP _U(__fp64_zero)
	
ENTRY fp64_logx
	XCALL _U(__fp64_splitA)
	brcs .L_nf					; case 1-3: return NaN for x=NaN,-Inf, +Inf for +Inf
	breq .L_inf					; case 4: return -Inf for x = 0
	brts .L_nan					; case 1: return NaN for x < 0
	
	XCALL _U(__fp64_cmp_1)
	breq .L_zero				; case 5: return 0 for x == 1

	tst rA6						; subnormal number?
	brmi 2f
	XCALL _U(__fp64_norm2)		; yes, normalize it
	
2:	
	push rAx3					; as all registers may be used, save them
	push rAx2
	push rAx1
	push rAx0
	push rBx11
	push rBx10
	push rBx9
	push rBx8
	push rBx7
	push rBx6
	push rBx5
	push rBx4
	push rBx3
	push rBx2
	push rBx1
	push rBx0
	push YH
	push YL
	push XH
	push XL

	push rAE1					; save exponent of x
	push rAE0

	ldi rAE1, 0x03				; normalize x to be in range 0.5 - 1.0
	ldi rAE0, 0xfe				; --> exponent of x becomes 0x3fe
	
22:	; rcall __fp64_saveAB
	movw rC6, rA6				; save x
	movw rC4, rA4
	movw rC2, rA2
	movw rC0, rA0
	push rAE1
	push rAE0

	XCALL _U(__fp64_ldb_1)		; load B with 1.0
	XCALL _U(__fp64_add_pse)	; x + 1
	
	_SWAPW rC6, rA6				; save result of x+1 and load A with x
	_SWAPW rC4, rA4
	_SWAPW rC2, rA2
	_SWAPW rC0, rA0
	clr r1
	pop rBE0
	pop rBE1
	push rAE1					; save exponent of x+1 on stack
	push rAE0
	movw rAE0, rBE0				; load exponent of x into A
	
	XCALL _U(__fp64_ldb_1)		; load B with 1.0
	clt
	XCALL _U(__fp64_sub_pse)	; x - 1
	bld rA7, 7					; save sign (always 1)
	
	movw rB6, rC6				; restore b = x + 1
	movw rB4, rC4
	movw rB2, rC2
	movw rB0, rC0
	pop rBE0					; restore exponent of x+1
	pop rBE1
	
	set
	XCALL _U(__fp64_divsd3_pse)	; y = (x-1) / (x+1)
	bld rA7, 7
	; rcall __fp64_saveAB

	ldi XL, lo8(.L__tableLog)
	ldi XH, hi8(.L__tableLog)
	XCALL _U(__fp64_powsoddx)	; approximate log(y) = log((x-1)/(x+1)) by power series
	; rcall __fp64_saveAB
	
	pop rBE0					; restore exponent			
	pop rBE1

	bld rA7,7
	push rA7					; save result of log(y)
	push rA6
	push rA5
	push rA4
	push rA3
	push rA2
	push rA1
	push rA0
	push rAE1
	push rAE0
	
10:	
	movw rA6, rBE0				; convert exponent-base into float64_t
	subi rA6, 0xfe				; exponent - base
	sbci rA7, 0x03
	
	XCALL _U(__fp64sssd_pse) 	; int16 as a float
	XCALL _U(__fp64_ldb_log2)	; B = log(2)
	XCALL _U(__fp64_mulsd3_pse)	
	
	pop rBE0					; restore B = log(y)
	pop rBE1
	pop rB0
	pop rB1	
	pop rB2
	pop rB3
	pop rB4
	pop rB5
	pop rB6
	pop rB7
	
	mov r0, rB7					; T has to be sign(A) ^ sign(B)
	eor r0, rA7
	bst r0,7
	rcall __fp64_saveAB
	XCALL _U(__fp64_add_pse)	; log(x*2^n) = log(x)+n*log(2)

99:	
	pop XL						; restore all used registers
	pop XH
	pop YL
	pop YH
	pop rBx0
	pop rBx1
	pop rBx2
	pop rBx3
	pop rBx4
	pop rBx5
	pop rBx6
	pop rBx7
	pop rBx8
	pop rBx9
	pop rBx10
	pop rBx11
	pop rAx0
	pop rAx1
	pop rAx2
	pop rAx3
	
	XJMP _U(__fp64_rpretA)		; round, pack and return
	
.L__tableLog:
	.byte 16	; polynom power = 16 --> 17 entries
	.byte 0x00, 0xF8, 0x3E, 0x0F, 0x83, 0xE0, 0xF8, 0x3E, 0x03, 0xfa ; 0x3FAF07C1F07C1F08 = 0.06060606060606060606060606060606060606061 = 2 / 33
	.byte 0x00, 0x84, 0x21, 0x08, 0x42, 0x10, 0x84, 0x21, 0x03, 0xfb ; 0x3FB8421084210840 = 0.06451612903225806451612903225806451612903 = 2 / 31
	.byte 0x00, 0x8D, 0x3D, 0xCB, 0x08, 0xD3, 0xDC, 0xB1, 0x03, 0xfb ; 0x3FB1A7B9611A7B96 = 0.06896551724137931034482758620689655172414 = 2 / 29
	.byte 0x00, 0x97, 0xB4, 0x25, 0xED, 0x09, 0x7B, 0x42, 0x03, 0xfb ; 0x3FB2F684BDA12F68 = 0.07407407407407407407407407407407407407407 = 2 / 27
	.byte 0x00, 0xA3, 0xD7, 0x0A, 0x3D, 0x70, 0xA3, 0xD7, 0x03, 0xfb ; 0x3FB47AE147AE147B = 0.08000000000000000000000000000000000000000 = 2 / 25
	.byte 0x00, 0xB2, 0x16, 0x42, 0xC8, 0x59, 0x0B, 0x21, 0x03, 0xfb ; 0x3FB642C8590B2164 = 0.08695652173913043478260869565217391304348 = 2 / 23
	.byte 0x00, 0xC3, 0x0C, 0x30, 0xC3, 0x0C, 0x30, 0xC3, 0x03, 0xfb ; 0x3FB8618618618618 = 0.09523809523809523809523809523809523809524 = 2 / 21
	.byte 0x00, 0xD7, 0x94, 0x35, 0xE5, 0x0D, 0x79, 0x43, 0x03, 0xfb ; 0x3FBAF286BCA1AF28 = 0.1052631578947368421052631578947368421053 = 2 / 19
	.byte 0x00, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF1, 0x03, 0xfb ; 0x3FBE1E1E1E1E1E1E = 0.1176470588235294117647058823529411764706 = 2 / 17
	.byte 0x00, 0x88, 0x88, 0x88, 0x88, 0x88, 0x88, 0x89, 0x03, 0xfc ; 0x3FC1111111111111 = 0.1333333333333333333333333333333333333333 = 2 / 15
	.byte 0x00, 0x9D, 0x89, 0xD8, 0x9D, 0x89, 0xD8, 0x9E, 0x03, 0xfc ; 0x3FC3B13B13B13B14 = 0.1538461538461538461538461538461538461538 = 2 / 13
	.byte 0x00, 0xBA, 0x2E, 0x8B, 0xA2, 0xE8, 0xBA, 0x2F, 0x03, 0xfc ; 0x3FC745D1745D1746 = 0.1818181818181818181818181818181818181818 = 2 / 11
	.byte 0x00, 0xE3, 0x8E, 0x38, 0xE3, 0x8E, 0x38, 0xE4, 0x03, 0xfc ; 0x3FCC71C71C71C71C = 0.2222222222222222222222222222222222222222 = 2 / 9
	.byte 0x00, 0x92, 0x49, 0x24, 0x92, 0x49, 0x24, 0x92, 0x03, 0xfd ; 0x3FD2492492492492 = 0.2857142857142857142857142857142857142857 = 2 / 7
	.byte 0x00, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCD, 0x03, 0xfd ; 0x3FD999999999999A = 0.4000000000000000000000000000000000000000 = 2 / 5
	.byte 0x00, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAB, 0x03, 0xfe ; 0x3FE5555555555555 = 0.6666666666666666666666666666666666666667 = 2 / 3
	.byte 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00 ; 0x4000000000000000 = 2.0000000000000000000000000000000000000000 = 2 / 1
	.byte 0x00												; byte needed for code alignment to even adresses!
	
	
ENDFUNC
	