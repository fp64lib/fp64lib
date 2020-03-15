/* Copyright (c) 2019-2020  Uwe Bissinger
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

/* float64_t fp64_sinh (float64_t x);
     The fp64_sinh() function returns the hyperbolic sine of x, which is
     defined mathematically as (exp(x) - exp(-x)) / 2.
 */

FUNCTION fp64_cosh
ENTRY fp64_sinh
GCC_ENTRY __sinh
	ldi XL, 0x80
	rjmp .L_common
	

/* float64_t fp64_cosh (float64_t x);
     The fp64_cosh() function returns the hyperbolic cosine of x, which is
     defined mathematically as (exp(x) + exp(-x)) / 2.
 */

ENTRY fp64_cosh
GCC_ENTRY __cosh
	clr XL
	
.L_common:						; calculate sinh or cosh, depending on r0
	; A = exp(x))
	sts .L_sign, XL
	XCALL	_U(fp64_exp)
	XCALL _U(__fp64_pushB)		; preserve registers

	XCALL _U(__fp64_movBA)		; save exp(-fabs(x))
	
	XCALL _U(fp64_inverse)		; calculate exp(fabs(x)) 
	lds XL, .L_sign				; retrieve sign
	sub rA7, XL					; for sinh, exp(-x) becomes -exp(-x)
	XCALL _U(fp64_add)			; exp(x) +/- exp(-x)
	ldi rB7, hi8(-1)
	ldi rB6, lo8(-1)
	XCALL _U(fp64_ldexp)		; (exp(x) +/- exp(-x))*(2^-1)
	
	XJMP _U(__fp64_popBret)		; restore registers and return
ENDFUNC
.data
.L_sign:	.skip 1				; storage for saving sign
