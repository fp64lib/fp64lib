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

/* float64_t fp64_acosh (float64_t x);
     The fp64_acosh() function returns the inverse hyperbolic cosine 
	 (a.k.a. area hyperbolic cosine) of x, which is defined mathematically as 
	 arcosh(x) = ln(x + sqrt(x*x-1)) for x >= 1. If x is < 1, NaN is returned.
 */

FUNCTION fp64_acosh
ENTRY fp64_acosh
GCC_ENTRY __acosh
	; check for x < 1
	sbrc rA7, 7				; is x < 0
.L_nan:
	XJMP	_U(__fp64_nan)	; yes --> return NaN

	cpi rA7, 0x3f			; is x < 2^(-15) ?
	brlo .L_nan				; yes --> return NaN
	brne 1f					; x > 2^0 --> ok
	
	cpi rA6, 0xf0			; is x < 2^0 ?
	brlo .L_nan				; yes --> return NaN

1:	
	; x is now >=1
	ldi XL, 0x80			; set sign bit
	rjmp .L_common
	

/* float64_t fp64_asinh (float64_t x);
    The fp64_asinh() function returns the inverse hyperbolic sine 
	(a.k.a. area hyperbolic sine) of x, which is defined mathematically as 
	arsinh(x) = ln(x + sqrt(x*x+1)).
	
	The following special cases apply:
	 case|	 x   | arsinh(x)
	-----+-------+------
	  1  |	NaN	 |	NaN
	  2a |	+Inf | +Inf
	  2b |	-Inf | -Inf

 */

ENTRY fp64_asinh
GCC_ENTRY __asinh
	clr XL						; clear sign bit
	
.L_common:						
	; cases NaN and +Inf are handled properly inside the calculations
	; but we have to treat -Inf specially
	cpi rA7, 0xff
	brne .L_notInf
	cpi rA6, 0xf0
	brne .L_notInf
	ret							; case 2b: asinh(-Inf) = -Inf

.L_notInf:						; calculate asinh or acosh, depending on XL
	XCALL _U(__fp64_pushB)		; preserve registers
	XCALL _U(__fp64_pushA)		; save x
	push XL						; save sign bit
	
	XCALL _U(fp64_square)		; calc x*x
	XCALL _U(__fp64_movBA)		; save x*x
	XCALL _U(__fp64_one)		; load 1
	pop r0						; retrieve sign
	or rA7, r0					; for acosh make it a -1
	XCALL _U(__fp64_swapAB)		; get operands in right order
	XCALL _U(fp64_add)			; x*x +/- 1
	XCALL _U(fp64_sqrt)			; sqrt( x*x +/- 1 )
	
	XCALL _U(__fp64_popB)		; retrieve x
	XCALL _U(fp64_add)			; sqrt( x*x +/- 1 ) + x
	XCALL _U(fp64_log)			; ln( sqrt( x*x +/- 1 ) + x ) 
	
	XJMP _U(__fp64_popBret)		; restore registers and return
ENDFUNC
