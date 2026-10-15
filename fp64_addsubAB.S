/* Copyright (c) 2026  Uwe Bissinger
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

#include "fp64def.h"
#include "asmdef.h"

/* 56-bit add/sub helper routines */
FUNCTION __fp64_addsubAB

/* __fp64_addAB() add rB0:6 to rA0:6

	Input:
		rA6.rA5.rA4.rA3.rA2.rA1.rA0  - (mantissa of) A
		rB6.rB5.rB4.rB3.rB2.rB1.rB0  - (mantissa of) b
	Return:
		rA6.rA5.rA4.rA3.rA2.rA1.rA0  - (mantissa of) A + B
		Flags set according to result of last operation
	Modifies:
		nothing
 */

ENTRY __fp64_addAB
	add rA0, rB0	; compute A = A + B
	adc	rA1, rB1
	adc	rA2, rB2
	adc	rA3, rB3
	adc	rA4, rB4
	adc	rA5, rB5
	adc	rA6, rB6
	ret


/* __fp64_subAB() subtracts rB0:6 from rA0:6

	Input:
		rA6.rA5.rA4.rA3.rA2.rA1.rA0  - (mantissa of) A
		rB6.rB5.rB4.rB3.rB2.rB1.rB0  - (mantissa of) B
	Return:
		rA6.rA5.rA4.rA3.rA2.rA1.rA0  - (mantissa of) A - B
		Flags set according to result of last operation
	Modifies:
		nothing
 */

ENTRY __fp64_subAB
	sub	rA0, rB0	; compute A = A - B
	sbc	rA1, rB1
	sbc	rA2, rB2
	sbc	rA3, rB3
	sbc	rA4, rB4
	sbc	rA5, rB5
	sbc	rA6, rB6
	ret

ENDFUNC
