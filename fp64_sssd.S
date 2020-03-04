/* Copyright (c) 2020  Uwe Bissinger
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

/*
   float64_t __fp64unsssd (uint16_t x);
   float64_t fp64_uint16_to_float64 (unsigned short x);

   Input:
     rA7.rA6							- an 'x' arg as unsigned 16-bit short
   Output:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	- x converted to IEEE 754-64 bit format
										  no overflow will occur, as 16bit short will
										  always fit into the 53-bit significand
 */

FUNCTION __fp64sssd
ENTRY fp64_uint16_to_float64
ENTRY   __fp64unsssd
	clt
	rjmp .L_common
	
/* float64_t __fp64sssd ( int16_t x );
   float64_t fp64_int16_to_float64 ( short x );
   Convert a signed 16-bit integer (short) to float64_t.
   No overflow will occur, as 16bit long will
   always fit into the 53-bit significand
   
   Input:
     rA7.rA6							- an 'x' arg as signed 16-bit short
   Output:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	- x converted to IEEE 754-64 bit format
*/										  
ENTRY fp64_int16_to_float64
ENTRY __fp64sssd
	rcall __fp64sssd_pse
	XJMP _U(__fp64_pretA)
	
ENTRY __fp64sssd_pse	
	bst	rA7, 7			; save sign
	brtc .L_common		; if x > 0, start conversion
	; negate A
	com	rA7
	neg	rA6
	sbci rA7, -1

.L_common:
	clr rAE0			; exponent = 0
	clr rAE1
	movw rA0, rAE0		; set lower 48 bits to 0
	movw rA2, rAE0
	movw rA4, rAE0
	
	adiw rA6, 0			; x == 0?
	brne 0f				; no, convert
	ret					; yes, result is also 0 in IEEE notation

0:	ldi rAE1, hi8(1023+15)
	ldi rAE0, lo8(1023+15)

	tst	rA7				;  A >= 2^8
	breq 2f				; no, we only need to take care of lower byte
	
	; A >= 2^8 shift to right is needed by 1..8 positions
	mov rA5, rA6
	mov rA6, rA7
    bld rA7, 7
1:	brmi .L_pack		; stop, if leftmost bit is set
	sbiw rAE0, 1		; exponent--
	lsl rA5				; x <<= 1
	rol rA6
	rjmp 1b				; until  leftmost bit is set
	
	; A < 2^8, we only need to take car of lower 8 bits already in rA6
2:	sbiw rAE0, 8		; number is at maximum 2^8-1
	tst rA6
3:	brmi .L_pack
	sbiw rAE0, 1		; exponent--
	lsl rA6				; x <<= 1
	rjmp 3b				; until  leftmost bit is set

	; pack and return
.L_pack:
	ret
ENDFUNC
