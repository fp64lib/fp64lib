/* Copyright (c) 2002, Joerg Wunsch
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

/* struct fp64_debug* __fp64_debug (special)
     return sisgn, exponent and mantissa from internal registers
 */
 
ENTRY __fp64_saveB
	sts __br1, r1
	push r0
	bld r0, 0
	sts __b_sign, r0
	in	r0, 0x3f
	sts __b_sreg, r0
	;eor r0,r0
	lds r0, __b_count
	inc r0
	sts __b_count, r0
	sts __b_exp, rBE0
	sts __b_exp+1, rBE1
	sts __b_m+0, rB6
	sts __b_m+1, rB5
	sts __b_m+2, rB4
	sts __b_m+3, rB3
	sts __b_m+4, rB2
	sts __b_m+5, rB1
	sts __b_m+6, rB0
 	sts __b7, rB7		; only for debugging as exponent is in rBE1.rBE0
	lds r0, __b_sreg
	out 0x3f, r0
	pop r0
	ret
	
ENTRY __fp64_saveAB
	rcall __fp64_saveB
	
ENTRY __fp64_saveA
	sts __ar0, r0
	push r0
	bld r0, 0
	sts __a_sign, r0
	in	r0, 0x3f
	sts __a_sreg, r0
	;eor r0,r0
	lds r0, __a_count
	inc r0
	sts __a_count, r0
	sts __a_exp, rAE0
	sts __a_exp+1, rAE1
	sts __a_m+0, rA6
	sts __a_m+1, rA5
	sts __a_m+2, rA4
	sts __a_m+3, rA3
	sts __a_m+4, rA2
	sts __a_m+5, rA1
	sts __a_m+6, rA0
	sts __a7, rA7		; only for debugging as exponent is in rAE1.rAE0
	lds r0, __a_sreg
	out 0x3f, r0
	pop r0
	ret
	
ENTRY __fp64_saveMul
	sts __ar0, r0
	sts __br1, r1
	push r0
	in	r0, 0x3f
	sts __a_sreg, r0
	;eor r0,r0
	bld r0, 0
	sts __a_sign, r0
	sts __a_exp, rAE0
	sts __a_exp+1, rAE1
	sts __a_m+0, rB4
	sts __a_m+1, rB3
	sts __a_m+2, rB2
	sts __a_m+3, rB1
	sts __a_m+4, rB0
	sts __a_m+5, rR8
	sts __a_m+6, rR7
	sts __a7, rR6
	sts __b7, rR5
	lds r0, __a_sreg
	out 0x3f, r0
	pop r0
	ret
	
ENTRY __fp64_saveDiv
	call __fp64_saveA
	push r0
	sts __b_m+6, r0
	in	r0, 0x3f
	sts __b_sreg, r0
	;eor r0,r0
	bld r0, 0
	sts __b_sign, r0
	sts __b_exp, rAE0
	sts __b_exp+1, rAE1
	sts __b_m+0, rR5
	sts __b_m+1, rR6
	sts __b_m+2, rR7
	sts __b_m+3, rR8
	sts __b_m+4, rBE1
	sts __b_m+5, rBE0
	sts __b7, rB7
	lds r0, __b_sreg
	out 0x3f, r0
	pop r0
	ret
	
ENTRY __fp64_debugA
	call __fp64_saveA
	ldi	r24, lo8(__a_sreg)
	ldi r25, hi8(__a_sreg)
	ret

ENTRY __fp64_debugAB
	call __fp64_saveAB
	ldi	r24, lo8(__a_sreg)
	ldi r25, hi8(__a_sreg)
	ret

ENTRY __fp64_saveCordic
	sts __X+0, rX7
	sts __X+1, rX6
	sts __X+2, rX5
	sts __X+3, rX4
	sts __X+4, rX3
	sts __X+5, rX2
	sts __X+6, rX1
	sts __X+7, rX0
	sts __Y+0, rY7
	sts __Y+1, rY6
	sts __Y+2, rY5
	sts __Y+3, rY4
	sts __Y+4, rY3
	sts __Y+5, rY2
	sts __Y+6, rY1
	sts __Y+7, rY0
	sts __PHI+0, rPHI7
	sts __PHI+1, rPHI6
	sts __PHI+2, rPHI5
	sts __PHI+3, rPHI4
	sts __PHI+4, rPHI3
	sts __PHI+5, rPHI2
	sts __PHI+6, rPHI1
	sts __PHI+7, rPHI0
	sts __ZLZH+0, ZL
	sts __ZLZH+1, ZH
	ret

ENTRY __fp64_debugCordic
	ldi	r24, lo8(__X)
	ldi r25, hi8(__X)
	ret

ENTRY __fp64_debugCordicTable
	lds r24, __ZLZH+0
	lds r25, __ZLZH+1
	ret
ENDFUNC

	
.data
__a_sreg:	.skip	1
__a_count:	.skip	1
__a_sign:	.skip	1
__a_exp:	.skip	2
__a_m:		.skip	7
__a7:		.skip	1
__ar0:		.skip	1
__b_sreg:	.skip	1
__b_count:	.skip	1
__b_sign:	.skip	1
__b_exp:	.skip	2
__b_m:		.skip	7
__b7:		.skip	1
__br1:		.skip	1
__X:		.skip	8
__Y:		.skip	8
__PHI:		.skip	8
__ZLZH:		.skip	2
