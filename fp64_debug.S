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
 
FUNCTION __fp64_debug

ENTRY __fp64_saveC
	sts __cr1, r0
	push r0
	bld r0, 0
	sts __c_sign, r0
	in	r0, 0x3f
	sts __c_sreg, r0
	;eor r0,r0
	lds r0, __c_count
	inc r0
	sts __c_count, r0
	sts __c_exp, YL
	sts __c_exp+1, YH
	sts __c_m+0, rC6
	sts __c_m+1, rC5
	sts __c_m+2, rC4
	sts __c_m+3, rC3
	sts __c_m+4, rC2
	sts __c_m+5, rC1
	sts __c_m+6, rC0
 	sts __c7, rC7		; only for debugging as exponent is in rBE1.rBE0
	lds r0, __c_sreg
	out 0x3f, r0
	pop r0
	ret

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

ENTRY __fp64_saveABC
	rcall __fp64_saveC
	
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
	
ENTRY __fp64_before
	sts __before, ZH
	sts __before+1, ZL
	push ZH
	push ZL
	ldi ZH, hi8(__before+2)
	ldi ZL, lo8(__before+2)
.L_saveall:
	st Z+, r29
	st Z+, r28
	st Z+, r27
	st Z+, r26
	st Z+, r25
	st Z+, r24
	st Z+, r23
	st Z+, r22
	st Z+, r21
	st Z+, r20
	st Z+, r19
	st Z+, r18
	st Z+, r17
	st Z+, r16
	st Z+, r15
	st Z+, r14
	st Z+, r13
	st Z+, r12
	st Z+, r11
	st Z+, r10
	st Z+, r9
	st Z+, r8
	st Z+, r7
	st Z+, r6
	st Z+, r5
	st Z+, r4
	st Z+, r3
	st Z+, r2
	st Z+, r1
	st Z+, r0
	pop ZL
	pop ZH
	ret

ENTRY __fp64_proxy1
ENTRY __fp64_proxy1_int8
ENTRY __fp64_proxy1_int16
ENTRY __fp64_proxy1_int32
ENTRY __fp64_proxy1_int64
	sts __function, rA7
	sts __function+1, rA6
	movw ZL, rA4
	ld rA0, Z+
	ld rA1, Z+
	ld rA2, Z+
	ld rA3, Z+
	ld rA4, Z+
	ld rA5, Z+
	ld rA6, Z+
	ld rA7, Z+
	lds ZH, __function
	lds ZL, __function+1
	rcall __fp64_before
	icall
ENTRY __fp64_after
	sts __after, ZH
	sts __after+1, ZL
	push ZH
	push ZL
	ldi ZH, hi8(__after+2)
	ldi ZL, lo8(__after+2)
	rjmp .L_saveall

ENTRY __fp64_proxy2
ENTRY __fp64_proxy2_int8
	rcall __fp64_saveAB
	sts __function, rA7
	sts __function+1, rA6
	XCALL _U(__fp64_pushB)
	movw ZL, rA2
	ld rB0, Z+
	ld rB1, Z+
	ld rB2, Z+
	ld rB3, Z+
	ld rB4, Z+
	ld rB5, Z+
	ld rB6, Z+
	ld rB7, Z+
	rcall __fp64_proxy1
	XJMP _U(__fp64_popBret)
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
__c_sreg:	.skip	1
__c_count:	.skip	1
__c_sign:	.skip	1
__c_exp:	.skip	2
__c_m:		.skip	7
__c7:		.skip	1
__cr1:		.skip	1
ENTRY __before
			.skip	32
ENTRY __after
			.skip	32
__function:	.skip	2
