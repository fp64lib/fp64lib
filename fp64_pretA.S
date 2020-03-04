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


#if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

FUNCTION __fp64_pretA

/* float_64 __fp64_rpretA(non-standard A );
     Internal function to round a 64-bit float point number and
	 pack it from internal format into external IEEE 754 format
	 This routine does NOT handle special cases INF and NaN.
	 Lower 3 bits of rA0 are used for rounding (round to even)

   Input:
     rA6.rA5.rA4.rA3.rA2.rA1.rA0 - mantissa of A, 
	 rAE1.rAE0					 - exponent of A
	 T							 - sign of A
   Output:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0 - result in IEEE 754 formaz
 */
 
ENTRY __fp64_rpretA
	clc					; default: do not take carry into account
ENTRY __fp64_rcpretA
	sbrs rA0, 2			; does rounding occur?		
	rjmp __fp64_pretA 	; no, pack result
	;rjmp 0f
	
	sbrc rA1, 1
	rjmp 1f				; guard bit 1 set --> round up
	brcs 1f				; carry as guard bit -1 is set --> round up
	sbrs rA0, 0			; guard bit 1 is clear. what about guard bit 0
	rjmp 0f				; guard bit 0 is also clear --> round to even
	; at least one of the lower bits is set -> we have to round up
1:	subi rA0, (-0x08)	; increase first bit of 53bit significand
	brcs __fp64_pretA	; if no everflow, pack & return
	sec					; handle overflow
	adc rA1,r1
	adc rA2,r1
	adc rA3,r1
	adc rA4,r1
	adc rA5,r1
	adc rA6,r1
	brcc __fp64_pretA	; no overflow, everything fine
	
	ror  rA6
	XCALL _U(__fp64_rorA5) 	; overflow --> shift mantissa of result with 1st bit set (could be discarded)
	
	adiw rAE0, 1			; increase exponent by 1
	cpi	rAE0, 0xff			; did we get overflow (exp == 0x7ff) ?
	brne __fp64_pretA		; no -> return A
	cpi rAE1, 0x7
	brne __fp64_pretA		; no -> return A
	XJMP _U(__fp64_inf)		; yes -> return infinity

0:	sbrs rA0, 3			; round to even
	ori rA0, 0x08

/* float_64 __fp64_pretA(non-standard A );
     Internal function to pack a 64-bit float point number
	 from internal format into external IEEE 754 format
	 This routine does NOT handle special cases INF and NaN.
	 lower 3 bits of rA0 are discarded/truncated --> round to 0

   Input:
     rA6.rA5.rA4.rA3.rA2.rA1.rA0 - mantissa of A
	 rAE1.rAE0					 - exponent of A
	 T							 - sign of A
   Output:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0 - result in IEEE 754 formaz
 */

ENTRY __fp64_pretA
	; rcall __fp64_saveAB
	adiw rAE0, 0	; test 1 for subnormal number: exponent == 0?
	breq 2f			; yes, handle it
	tst rA6			; test 2: do we have a leading 1 bit ?
	brmi 3f			; yes --> normal number, start packing
	clr rAE0		; no --> subnormal number, set exponent to 0
	clr rAE1
2:	XCALL _U(__fp64_lsrA)	; save topmost bit for subnormal number
3:	XCALL _U(__fp64_lsrA)	; shift mantissa 3 bits to make room for exponent
	XCALL _U(__fp64_lsrA)
	XCALL _U(__fp64_lsrA)

	swap rAE0		; exponent is 11 bits = 3 nibbles = e2.e1.e0
	swap rAE1		; rAE1.rAE0 is now e2.0.e0.e1
	mov rA7,rAE0	; built top 8 bits of exponent, rA7 = e0.e1
	andi rA7, 0x0f	; start with 0.e1
	or rA7,rAE1		; add it to e2.e1
	
	andi rA6, 0x0f	; mask out leading 1 bit
	andi rAE0, 0xf0	; as e0.0 in rAE0
	or rA6, rAE0	; with mantissa as e0.a6 in rA6

	bld	rA7, 7		; get sign
	ret
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
