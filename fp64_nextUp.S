/* Copyright (c) 2026  Uwe Bissinger
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

/* float64_t fp64_nextUp (float64_t x);
     nextUp(x) is the least floating-point number that compares greater than x.
	 If x is the negative number of least magnitude, nextUp(x) is −0. 
	 nextUp(±0) is the positive number of least magnitude in x’s format. 
	 nextUp(+∞) is +∞, and nextUp(−∞) is the finite negative number largest
	 in magnitude. When x is a NaN, then the result is x, i.e. NaN. 
 */
 
FUNCTION fp64_nextUp

ENTRY fp64_nextDown
GCC_ENTRY __nextDown
	; nextDown(x) = -nextUp(-x)
	subi rA7, 0x80				; create -x’s
	rcall fp64_nextUp
	subi rA7, 0x80				; create -nextUp(-x)
	ret

.L_NaN:
	breq .L_Inf
	XJMP _U(__fp64_nan)			; case 1: return NaN for NaN
	
.L_Inf:
	; rcall __fp64_saveAB
	brts .L_negative			; case 2a: return biggest negative number for -Inf
	XJMP _U(__fp64_inf)			; case 2b: return +Inf for +Inf	

ENTRY fp64_nextUp
GCC_ENTRY __nextUp
	bst rA7, 7					; save sign
	andi rA7, 0x7f				; clear sign
	cpi rA7, 0x7f				; is x = NaN or Inf
	brne .L_check0
	cpi rA6, 0xf0
	brcs .L_check0				; no, continue with checks
	
	; x is either +/-INF or +/-NaN
	XCALL _U(__fp64_cpc0A5)		; check all other digits, Z is set if digits == 0
	brne .L_done				; digits != 0 --> x is NaN, return it
	; x is +/-INF
	brtc .L_done				; for x == +Inf, return +Inf
	rjmp .L_not0				; find first number next to -Inf
	
.L_check0:
	adiw rA6, 0					; is x == +/-0?
	brne .L_not0
	XCALL _U(__fp64_cpc0A5)		; check all digits, Z is set if x==0
	brne .L_not0				; x != 0 --> normal or subnormal number
	
	clt							; -0 is handled like +0, ignore sign

.L_not0: 
	mov r0, r1					; get +1 into r0 
	sec
	rol r0	
	
	brts .L_negative			; handle negative numbers
	
.L_positive:
	; handle positive numbers
	add rA0, r0					; add 1 to the first significand bit
	adc rA1, r1
	adc rA2, r1
	adc rA3, r1
	adc rA4, r1
	adc rA5, r1
	adc rA6, r1
	adc rA7, r1
	
.L_done:
	rcall __fp64_saveAB
	ret

.L_negative:
	; normal case for negative numbers, we can decrease by 1 ulp
	sub rA0, r0
	sbc rA1, r1
	sbc rA2, r1
	sbc rA3, r1
	sbc rA4, r1
	sbc rA5, r1
	sbc rA6, r1
	sbc rA7, r1
	bld rA7, 7			; restore sign
	rjmp  .L_done

.L_retZero:
	XJMP _U(__fp64_szero)

ENDFUNC

#endif /* !defined(__AVR_TINY__) */
