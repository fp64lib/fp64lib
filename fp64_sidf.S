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


#if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

/*
   float64_t __fp64unssisd (unsigned long x);
   float64_t fp64_uint32_to_float64 (unsigned long x);

   Input:
     rA7.rA6.rA5.rA4					- an 'x' arg as unsigned 32-bit long
   Output:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	- x converted to IEEE 754-64 bit format
										  no overflow will occur, as 32bit long will
										  always fit into the 53-bit significand
 */

FUNCTION __fp64sisd
ENTRY fp64_uint32_to_float64
GCC_ENTRY __floatunsidf
	clt
	rjmp .L_common
	
/* float64_t __fp64sisd ( long x );
   float64_t fp64_long_to_float64 ( long x );
   float64_t fp64_int32_to_float64 ( long x );
   Convert a signed 32-bit integer (long) to float64_t.
   No overflow will occur, as 32bit long will
   always fit into the 53-bit significand
   
   Input:
     rA7.rA6.rA5.rA4					- an 'x' arg as signed 32-bit long
   Output:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	- x converted to IEEE 754-64 bit format
*/										  
ENTRY fp64_int32_to_float64
ENTRY fp64_long_to_float64
GCC_ENTRY __floatsidf
	bst	rA7, 7		; save sign
	brtc .L_common	; if x > 0, start conversion
	; negate A
	com	rA7
	com	rA6
	com	rA5
	neg	rA4
	sbci rA5, -1
	sbci rA6, -1
	sbci rA7, -1

.L_common:
	clr rAE0			; exponent = 0
	clr rAE1
	movw rA0, rAE0		; set lower 32 bits to 0
	movw rA2, rAE0

	cp r1, rA4
	cpc r1, rA5
	cpc r1, rA6
	cpc r1, rA7
	brne 0f				; no, convert
	ret					; yes, result is also 0 in IEEE notation


0:	ldi rAE0, 23		; exponent of 00.80.00.00
	tst	rA7				; if A >= 2^23
	breq 2f			; no, check next byte
	; A >= 2^23m shift to right is needed by 1..8 positions
	
1:	inc rAE0			; exponent++
	lsr rA7				; A >>= 1
	ror rA6
	ror rA5
	ror rA4
	ror rA3				; bytes below A3 need not to be shifted,
						; as the number of shifts does not exceed 8
	tst rA7
	brne 1b				; repeat until top byte is empty
	rjmp .L_pack

	; rA7 is already 0
	; check: is fast shift possible?
2:
	tst	rA6			; highest byte = 0 ?
	brne 4f			; no, normalise result
					; yes, do fast shift to left
	subi rAE0, 8	; exponent -= 8 for shift of 8 bits
	mov	rA6, rA5
	mov	rA5, rA4
	mov	rA4, rA3	; rA3 is 0
	rjmp 2b		; loop until one bit is set 
					; (loop will terminate, as it is guaranteed that A <> 0)

	; rA6 is not 0.  It is needed shift to left by 0..7 positions.
4:	brmi .L_pack	; stop, if topmost bit is set
	dec	rAE0		; exponent -= 1
	lsl rA4			; A <<= 1, no action needed for rA3 and below as they are always 0
	rol rA5
	rol rA6
	rjmp 4b

	; pack and return
.L_pack:
	subi rAE0, -0xFF	; add exponent base 0x3ff
	sbci rAE1, -0x04
	XJMP _U(__fp64_pretA)
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
