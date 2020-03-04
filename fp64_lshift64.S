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

#include "fp64def.h"
#include "asmdef.h"

/*  uint8_t __fp64_lshift64(uint64_t C);
    return number of shifts until top bit of C is set
	input	rC7..rC0		64 bit of C
	output	rC7...rC0		C shifted to left with topbit in rC7 set
			r0				number of shifts needed (will be 64, if C is 0 )
 */
FUNCTION __fp64_lshift64
ENTRY __fp64_lshift64
	push XL
	clr XL
1:	tst rC7
	brmi 9f				; topmost bit already set
	brne 2f				; we have to shift by 1 to 7 bits
	mov rC7, rC6		; top byte = 0 --> shift by 8 bits
	mov rC6, rC5
	mov rC5, rC4
	mov rC4, rC3
	mov rC3, rC2
	mov rC2, rC1
	mov rC1, rC0
	clr rC0
	subi XL, -8			; shifts += 8
	cpi XL, 64
	brlo 1b				; stop after 8 cycles
	rjmp 9f
	
2:	inc XL				; shifts++
	lsl rC0
	rol rC1
	rol rC2
	rol rC3
	rol rC4
	rol rC5
	rol rC6
	rol rC7
	brpl 2b				; repeat until top bit is set
9:	mov r0, XL
	pop XL
	ret
ENDFUNC
