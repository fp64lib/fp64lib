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

#if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

/* float64_t fp64_frexp (float64_t A, int *pexp);
     The fp64_frexp() function is used to split the number A into a normalized
     fraction and an exponent which is stored by pexp.

   Return:
     If A is a normal float point number, the fp64_frexp() function returns the
     value v, such that v has a magnitude in the interval [1/2, 1) or zero,
     and A equals v times 2 raised to the power *pexp. If A is zero, both
     parts of the result are zero. If A is not a finite number, the fp64_frexp()
     returns A as is and stores 0 by pexp.

   Note:
     This implementation permits a zero pointer as a directive to skip
     a storing the exponent.
 */

FUNCTION fp64_frexp
	; handle NaN or +/-Inf
.L_nf:
	breq 0f						; +/-Inf? 
	XJMP _U(__fp64_nan)			; no, return NaN
0:	XJMP _U(__fp64_inf)			; yes, return +/-Inf

.L_zero:
	bld	rA7, 7					; restore sign and return (rA7..rA0 are all == 0)
	ret
		
ENTRY fp64_frexp
GCC_ENTRY __frexp
	X_movw	XL, rB6			; move pointer to one of the pointer registers

	; Write 0 for next cases: Zero, Inf or NaN.
	adiw	XL, 0
	breq	1f				; skip, if pointer is == NULL
	st X+, r1
	st X, r1
	sbiw XL, 1

1:	XCALL _U(__fp64_splitA)
	brcs .L_nf				; if NaN or Inf, return the same value
	breq .L_zero			; return 0
	
	; rcall __fp64_saveAB
	
	subi rAE0, lo8(1022)	; remove base 1023 - 1 from exponent
	sbci rAE1, hi8(1022)	; (-1 as result is in [0.5;1) )

	sbrs rA6, 7				; is x a subnormal number
	XCALL _U(__fp64_norm2)	; yes: normalize it
	
	adiw	XL, 0			; skip if pointer is == NULL
	breq	2f
	st X+, rAE0				; save the exponent 
	st X, rAE1

2:	; normalize the number to be in the range [0.5, 1)
	; --> exponent has to be 0x3fe
	ldi rAE1, 0x03
	ldi rAE0, 0xfe
	XJMP _U(__fp64_pretA)
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
