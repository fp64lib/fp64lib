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

/* float64_t __fp64_powsodd (float64_t_intern x, float64_t_intern* XH.XL);
     The __fp64_powsodd() function calculates a polynom with only odd
     powers of x. As this function operates on internal unpacked data, it
	 does not check for special cases like NaN or Inf. These case have
	 to be handled properly by the caller.

	 Attention: Routine uses all(!) registers, so caller is responsible
	 for saving content of registers
 
 Input:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0,rAE1.rAE0	- an 'x' arg as float64_t_intern
												  rA7 must contain sign of A
     XH.XL										- table address (in low 64K flash memory)
   Output:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0, rAE1.rAE0	- result, rA7 will contain sign of result

   Notes:
     * As __fp64_powsodd() is one of base function, square() is't used.
 */

FUNCTION __fp64_powsodd
ENTRY __fp64_powsodd

	bld rA7, 7					; save T flag as sign
	XCALL _U(__fp64_movBA)		; save x
	X_movw  YL, rAE0			; save exponent temporarely in YH.YL as XH.XL is still occupied
								; with pointer to polynom table

	XCALL _U(__fp64_pushB)		; save x for later use
	push	YL					; including the exponent
	push	YH
	
	push	XH					; save pointer to table for later use
	push	XL

	X_movw  rBE0, YL		
	;rcall __fp64_saveAB
	clt							; clear sign as x^2 is always positive
	XCALL	_U(__fp64_mulsd3_pse)	; calculate x^2 

	pop	XL						; retrieve pointer to table
	pop	XH
	XCALL	_U(__fp64_powser)	; calculate polynom with even powers of x

	pop rBE1
	pop rBE0
	XCALL _U(__fp64_popB)		; retrieve x into B

	mov r0, rB7					; set sign of A*B = sign(A)^sign(B)
	eor r0, rA7
	bst r0,7

	; rcall __fp64_saveABC
	XJMP	_U(__fp64_mulsd3_pse)	; multiply polynom by x --> polynom is calculated with odd powers of x

#ifdef CHECK_POWSER
.L_nf:	
	brne	.L_nan			; +/-Inf? No --> return NaN
.L_inf:
	XJMP	_U(__fp64_inf)	; No, case 2 --> return Inf
.L_nan:	; x = NaN, case 1 --> return NaN
	XJMP	_U(__fp64_nan)
#endif

ENTRY __fp64_check_powsodd3
#ifndef CHECK_POWSER
	ret
#else
	push XL
	push XH
	ldi XL, lo8(.L__testTable3x)
	ldi XH, hi8(.L__testTable3x)
	
ENTRY __fp64_check_powsoddn
98:
	XCALL	_U(__fp64_splitA)
	brcs .L_nf

	XCALL _U(__fp64_pushCB) ; preserve register set
	push YL
	push YH

	XCALL _U(__fp64_powsodd)

	pop YH
	pop YL
	XCALL _U(__fp64_popBC)	; restore register set

	pop XH
	pop XL
	brcs 99f
	XJMP _U(__fp64_rpretA)
99:	ret

ENTRY __fp64_check_powslog
	push XL
	push XH
	ldi XL, lo8(.L__testTableLogx)
	ldi XH, hi8(.L__testTableLogx)
	rjmp 98b

.L__testTable3x:
	.byte 0x03	; polynom power = 3 --> 3+1 entries
	.byte 0x00, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAB, 0x03, 0xfd ; 0x3FD5555555555555 = 0.3333333333333333333333333333333333333333
	.byte 0x80, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xfe ; 0xBFE000000000000 = -0.5
	.byte 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xff ; 0x3FF000000000000 = 1.0
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; 0x0000000000000000 = 0
	.byte 0x00												; byte needed for code alignment to even adresses!

.L__testTableLogx:
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
	
	#endif	
	
ENDFUNC
