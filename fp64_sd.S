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

/* float64_t fp64_sd (float A);
     Converts a float32 to the float64 representing the same number.
	 As float64_t fully includes all values of float, no error or truncation occurs

   Input:
     rA7.rA6.rA5.rA4  				 - arg. A in IEEE 754 - 32-bit format
   Output:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0 - A in IEEE 754 - 64-bit format
 */
 
 #if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

FUNCTION fp64_sd
	; A is not a finite (either NaN or +/-INF)
7:	cp rA6, r1
	cpc	rA5, r1
	cpc	rA4, r1
	brcc 8f					; if mantissa is 0, return +/-INF
	XJMP	_U(__fp64_nan)	; else return NaN
8:	XJMP	_U(__fp64_inf)	; return Inf with sign(a)

ENTRY	fp64_sd
GCC_ENTRY __extendsfdf2
	clr rA3						; clear lower mantissa bits
	clr rA2
	movw rA0, rA2
	clr rAE1

	; call __fp64_saveA

	lsl	rA6						; get LSB of exponent into C
	bst	rA7, 7					; T = sign
	rol	rA7						; A7 now contains exponent of A
	mov rAE0, rA7				; save exponent to rAE1.rAE0
	breq	0f					; if exp is 0, handle 0 or subnormal numbers
	cpi	rA7, 0xff		;		 if exp is 0x0ff, handle NaN or +/-INF
	breq	7b

	; now we have a normal number with 24 bits of mantissa in A6.A5.A4
	; and exponent in rAE1.rAE0
	subi rAE0, lo8(127-1023)	; adjust base of exponent: float exponent is based 127
	sbci rAE1, hi8(127-1023)	; float64_t exponent is 1023 based

	;call __fp64_saveA
	sec							; create leading mantissa bit
	ror rA6						; this enables us to use the
	XJMP _U(__fp64_pretA)		; normal pack and return routine

	; A is zero or subnormal (exponent is 0)
0:	cp	r1, rA4
	cpc	r1, rA5
	cpc	r1, rA6
	rol	rAE0					; for subnormal numbers exponent now is 1, else it is 0
	; call __fp64_saveA
	brne 1f
	XJMP	_U(__fp64_zero)		; exponent still 0 --> result is 0.0

1:	; subnormal number
	lsr rA6						; undo lsl from very beginning
	; call __fp64_saveA
2:	lsl rA4						; shift subnormal number until we got a leading 1 bit
	rol rA5
	rol rA6
	brmi 3f	
	subi rAE0, lo8(1)			; exp--
	sbci rAE1, hi8(1)
	rjmp 2b

3:	;call __fp64_saveA
	subi rAE0, lo8(127-1022)	; adjust base of exponent: float exponent is based 127
	sbci rAE1, hi8(127-1022)	; float64_t exponent is 1023 based
	XJMP _U(__fp64_pretA)		; pack and return converted number

ENDFUNC

#endif /* !defined(__AVR_TINY__) */

