/* Copyright (c) 2018-2020  Uwe Bissinger
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

/* float64_t __fp64disd (long long x)
   float64_t int64_to_float64( long long x );
   Convert a signed 64-bit integer (long long) to float64_t.
   Overflow cannot occur, but loss of precision, if abs(x) > 2^53

   Input:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	- an 'x' arg as signed 64-bit long
   Output:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	- x converted to IEEE 754-64 bit format
										  
 */

#include "fp64def.h"
#include "asmdef.h"

FUNCTION __fp64disd
ENTRY fp64_int64_to_float64
ENTRY __fp64disd
	bst	rA7, 7				; set sign
	brtc	1f
	XCALL	_U(__fp_negdi)	; if x < 0, negate x (routine from 32bit fp library
1:	XJMP	_U(__fp64_di2sd); do conversion

/* float64_t __fp64unsdisd ( unsigned long long x );
   float64_t fp64_uint64_to_float64( unsigned long long x );
   Convert an unsigned 64-bit integer (unsigned long long) to float64_t.
   Overflow cannot occur, but loss of precision, if abs(x) > 2^53
   
   Input:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	- an 'x' arg as signed 64-bit long
   Output:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	- x converted to IEEE 754-64 bit format
 */
 
ENTRY fp64_uint64_to_float64
ENTRY __fp64unsdisd
	clt			; result sign = +
	
__fp64_di2sd:
	clr rAE0				; exponent = 0
	clr rAE1
	XCALL _U(__fp64_cpc0A5)	; A = 0?
	cpc r1, rA6
	cpc r1, rA7
	brne 0f				; no, convert
	ret					; yes, result is also 0 in IEEE notation
	
0:	ldi rAE0, 55		; exponent for 00.80.00.00.00.00.00.00
	tst rA7				; is A >= 2^55
	breq 2f				; no, check next byte
	; A >= 2^54, shift to right is needed by 1..8 positions
1:	inc rAE0
	lsr rA7
	ror rA6
	XCALL _U(__fp64_rorA5)
	tst rA7
	brne 1b
	rjmp .L_round

	; check: is fast shift possible?
2:
	tst	rA6			; highest byte = 0 ?
	brne 4f			; no, normalise result
					; yes, do fast shift to left
	subi	rAE0, 8	; exponent -= 8 for shift of 8 bits
	mov	rA6, rA5
	mov	rA5, rA4
	mov	rA4, rA3
	mov	rA3, rA2
	mov	rA2, rA1
	mov	rA1, rA0
	ldi	rA0, 0
	rjmp 2b			; loop until one bit is set 
					; (loop will terminate, as it is guaranteed that A <> 0)
	
	; rA6 is not 0.  It is needed shift to left by 0..7 positions.
4:	brmi	.L_round; stop, if topmost bit is set
	dec	rAE0		; exponent -= 1
	XCALL _U(__fp64_lslA)	; A <<= 1
	rjmp 4b

	; Round and pack
.L_round:
	subi rAE0, -0xFF	; add exponent base 0x3ff
	sbci rAE1, -0x04
	XJMP _U(__fp64_rpretA)
ENDFUNC

