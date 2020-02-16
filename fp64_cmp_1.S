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

/*	CZ __fp64_cmp_1(float64_t_intern A)
	compare whether |A| is < 1, == 1 or > 1
	
	input:		rA7.rA6...rA0.rAE1.rAE0		A in unpacked format
	output:		sets only flags in SREG
				Z=1			if |A| == 1.0
				Z=0 C=1		if |A| < 1.0
				Z=0 C=0		if |A| > 1.0
				does not modify any other register
*/

FUNCTION __fp64_cmp_1
ENTRY __fp64_cmp_1
	cpi rAE1, 0x03	; x < 2^-255 or x > 2^1\
	brne .L_ret		; yes --> return Z=0, C=1 for x<2^-255, C=0 for x>2

	cpi rAE0, 0xff	; x < 1.0
	brlo .L_ret		; yes --> return Z=0, C=1

	; now here: 1 <= |x| < 2
	; check, whether |x| is == 1.0, i.e. significand = 0x80....0
	
	XCALL _U(__fp64_cpc0A5)
	brne .L_ret		; significand != 0 --> |x|>1, return Z=0, C=0

	cpi rA6, 0x80	; significand = 0x80...0? --> Z=1 C=0 if yes, otherwise x>1 --> Z=0 C=0

.L_ret:	; return current flag settings
	ret
ENDFUNC
