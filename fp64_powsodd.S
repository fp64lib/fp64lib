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

#include "fp64def.h"
#include "asmdef.h"

/* float64_t __fp64_powsodd (float64_t A, ZH.ZL);
     The __fp64_powsodd() function calculates a polynom with only odd
     powers of x.  Result is rounded.

   Input:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	- an 'x' arg
     ZH.ZL								- table address (in flash low 64K memory)

   Notes:
     * As __fp64_powsodd() is one of base function, square() is't used.
 */

ENTRY __fp64_powsodd

	push	rB7				; save used registers
	push	rB6
	push	rB5
	push	rB4
	push	rB3
	push	rB2
	push	rB1
	push	rB0
	push	rBE0
	push	rBE1
	push	rA7				; save x
	push	rA6
	push	rA5
	push	rA4
	push	rA3
	push	rA2
	push	rA1
	push	rA0
	
	push	ZH				; save pointer to table
	push	ZL

	X_movw	rB0, rA0		; B = A = x
	X_movw	rB2, rA2
	X_movw	rB4, rA4
	X_movw	rB6, rA6
	;rcall __fp64_saveAB
	XCALL	_U(fp64_mul)	; calculate x^2

	pop	ZL					; retrieve pointer to table
	pop	ZH
	XCALL	_U(__fp64_powser)	; calculate polynom with even powers of x

	pop	rB0					; retrieve x into B
	pop	rB1
	pop	rB2
	pop	rB3
	pop	rB4
	pop	rB5
	pop	rB6
	pop	rB7
	XCALL	_U(fp64_mul)	; multiply polynom by x --> polynom is calculated with odd powers of x

	pop	rBE1				; restore used registers
	pop	rBE0
	pop	rB0
	pop	rB1
	pop	rB2
	pop	rB3
	pop	rB4
	pop	rB5
	pop	rB6
	pop	rB7
	ret

ENTRY __fp64_check_powsodd3
#ifndef CHECK_POWSER
	ret
#else
	ldi ZL, lo8(.L__testTable3)
	ldi ZH, hi8(.L__testTable3)
	XJMP _U(__fp64_powsodd)

ENTRY __fp64_check_powslog
	ldi ZL, lo8(.L__testTableLog)
	ldi ZH, hi8(.L__testTableLog)
	XJMP _U(__fp64_powsodd)

.L__testTable3:
	.byte 0x03	; polynom power = 3 --> 3+1 entries
	.byte 0x3f, 0xd5, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55	; 0x3fd5555555555555 = 0.3333333333333333333
	.byte 0xbf, 0xe0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0xbfe0000000000000 = -0.5
	.byte 0x3f, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0x3ff0000000000000 = 1.0
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0x0000000000000000 = 0.0
	.byte 0x00												; byte needed for code alignment to even adresses!

.L__testTableLog:
	.byte 16	; polynom power = 16 --> 17 entries
	.byte 0x3F, 0xAF, 0x07, 0xC1, 0xF0, 0x7C, 0x1F, 0x08 ; 0x3FAF07C1F07C1F08 = 0.060606060606060608 = 2 / 33
	.byte 0x3F, 0xB0, 0x84, 0x21, 0x08, 0x42, 0x10, 0x84 ; 0x3FB0842108421084 = 0.064516129032258063 = 2 / 31
	.byte 0x3F, 0xB1, 0xA7, 0xB9, 0x61, 0x1A, 0x7B, 0x96 ; 0x3FB1A7B9611A7B96 = 0.068965517241379309 = 2 / 29
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
	
	#endif	
	
ENDFUNC
