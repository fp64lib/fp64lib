/* Copyright (c) 2018-2020  Uwe Bissinger
   Based on 32bit floating point arithmetic routines which are:
   Copyright (c) 2002  Michael Stumpf  <mistumpf@de.pepperl-fuchs.com>
   Copyright (c) 2006,2008  Dmitry Xmelkov
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

/* GCC expects all these functions to return -1/0/1 as for __cmpsf2 -
   compare with gcc/config/fp-bit.c (the only difference is with NaNs
   where we should always return nonzero for EQ/NE, -1 for GT/GE,
   1 for LT/LE).  -MM 2000-11-18 */

/* The base compare function.
   Return:
     if (A < B)
        rA6 = -1, C = 0
     elif (A == B)
        rA6 = 0, C = 0
     elif (A > B)
        rA6 = 1, C = 0
     else // isnan(A) || isnan(B)
        C = 1
 */
FUNCTION __fp64_cmp
ENTRY	__fp64_cmp
	lsl	rA7
	sbc	r0, r0		; r0 = (A < 0) ? -1 : 0
	lsl	rB7
	sbc	rBE0, rBE0	; rBE0 = (B < 0) ? -1 : 0
	;call __fp64_saveAB
	; isnan(A) ? i.e. exponent(A) = 0x7ff
	cpi rA7, (0x7f << 1)	; check first 7 bit of exponent
	brne 1f			; not 0x7f --> normal number
	cpi rA6, 0xf0	; we have to check lower 4 bits of exponent
	brlo 1f			; exponent = 0x7fx --> normal number, do normal compare
	brne 9f			; exponent = 0x7ff and mantissa > 0 --> NaN
	XCALL _U(__fp64_cpc0A5)	; check rest of mantissa
	brlo	9f		; 0 < mantissa --> NaN

1:	; A is normal number or INF, isnan(B) ?
	;call __fp64_saveAB
	cpi rB7, (0x7f << 1)	; check first 7 bit of exponent
	brne 2f			; not 0x7f --> normal number
	cpi rB6, 0xf0	; we have to check lower 4 bits of exponent
	brlo 2f			; exponent = 0x7fx --> normal number, do normal compare
	brne 9f			; exponent = 0x7ff and mantissa > 0 --> NaN
	XCALL _U(__fp64_cpc0B5)	; check rest of mantissa
	brlo	9f		; 0 < mantissa --> NaN

2:	; both A & B are normal numbers or INF	
	sub	rA0, rB0	; compare A & B
	sbc	rA1, rB1
	sbc	rA2, rB2
	sbc	rA3, rB3
	sub	rA4, rB4
	sbc	rA5, rB5
	sbc	rA6, rB6
	sbc	rA7, rB7	; C is set, if A < B
	brne	3f

	; absolute values are equal, check signs
	eor	r0, rBE0
	breq	8f		; signs equal --> rA6 = 0, C = 0

	; force -0.0 == +0.0
	or	rB0, rB1
	or	rB0, rB2
	or	rB0, rB3
	or	rB0, rB4
	or	rB0, rB5
	or	rB0, rB6
	brne	4f		; evaluate sign(B)
	ret
	
   ; A < B (if C=1) or A > B (C=0), view argument signes
3:	eor	r0, rBE0	; C is not changed
	brne	4f		; signs are different
	sbci	rBE0, 1	; rBE[0] = (A < B && A > 0) ? 0 : 1

4:	lsr	rBE0		; C = above result OR sign(B)
	; build return value, C is set, if A > B
	ldi	rA6, -1		; rA6 = -1
	adc	rA6, r1
	adc	rA6, r1		; C = 0 at any case
8:	ret
9:	;call __fp64_saveAB
	sec
	ret
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
