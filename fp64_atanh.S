/* Copyright (c) 2022  Uwe Bissinger
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

/* float64_t fp64_atanh(float64_t x);
     The fp64_atanh() function returns the inverse hyperbolic tangent 
	 (a.k.a. area hyperbolic tangent) of x, which is defined mathematically as 
	 artanh(x) = 0.5*ln((1+x)/(1-x)) for |x| < 1. If x is >= 1, NaN is returned.
 */

FUNCTION fp64_atanh
ENTRY fp64_atanh
GCC_ENTRY __atanh
	; check for |x| < 1
	push rA7
	andi rA7, 0x7f				; get rid of sign
	cpi rA7, 0x3f				; is x < 2^(-15) ?
	brlo .L_ok					; yes --> compute artanh
	brne .L_NaN					; x > 2^0 --> return 1
	
	cpi rA6, 0xf0				; is x < 2^0 ?
	brlo .L_ok					; yes --> return artanh

.L_NaN:							; return NaN for |x| >= 1
	pop rA7						; cleanup stack
	XJMP	_U(__fp64_nan)		; return NaN


.L_ok:	
	; x is now < 1
	pop rA7						; get back sign of x

	XCALL _U(__fp64_pushCB)		; preserve used registers
	XCALL _U(__fp64_movBA)		; put x in B
	XCALL _U(__fp64_one)		; and 1 in A

	XCALL _U(__fp64_pushA)		; save x and 1
	XCALL _U(__fp64_pushB)		; preserve registers
	XCALL _U(fp64_add)			; compute 1+x
	
	XCALL _U(__fp64_movCA)		; save 1+x in C
	XCALL _U(__fp64_popB)		; restore x and 1
	XCALL _U(__fp64_popA)
	XCALL _U(fp64_sub)			; compute 1-x

	XCALL _U(__fp64_movBA)		; save 1-x in B
	XCALL _U(__fp64_movAC)		; restore 1+x from C
	XCALL _U(fp64_div)			;  (1+x) / (1-x)
	
	XCALL _U(fp64_log)			; ln( sqrt( x*x +/- 1 ) + x ) 
	ldi rB7, 0x3f				; move 0.5 into B
	ldi rB6, 0xe0
	mov rB5, r1
	mov rB4, r1
	movw rB2, rB4
	movw rB0, rB4
	XCALL _U(fp64_mul)			; 1/2 * ln( sqrt( x*x +/- 1 ) + x ) 

	XCALL _U(__fp64_popBC)		; restore used registers
	ret							; and return
ENDFUNC
