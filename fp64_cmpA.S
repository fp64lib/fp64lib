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

/*  __fp64_cpcAB() compare A with B
   Input:
		rA6.rA5.rA4.rA3.rA2.rA1.rA0  - A in unpacked format
		rB6.rB5.rB4.rB3.rB2.rB1.rB0  - B in unpacked format
   Return:
		C=1		B > A
		C=0 Z=1	B == A
		C=0 Z=0 B < A
	Modifies:
		SREG
 */

FUNCTION __fp64_cmpA
ENTRY __fp64_cpcAB
	cp	rA0, rB0
	cpc	rA1, rB1
	cpc	rA2, rB2
	cpc	rA3, rB3
	cpc	rA4, rB4
	cpc	rA5, rB5
	cpc	rA6, rB6
	ret

/*  __fp64_cpcBA() compare B with A
   Input:
		rA6.rA5.rA4.rA3.rA2.rA1.rA0  - A in unpacked format
		rB6.rB5.rB4.rB3.rB2.rB1.rB0  - B in unpacked format
   Return:
		C=1		B < A
		C=0 Z=1	B == A
		C=0 Z=0 B > A
	Modifies:
		SREG
 */

ENTRY __fp64_cpcBA
	cp	rB0, rA0
	cpc	rB1, rA1
	cpc	rB2, rA2
	cpc	rB3, rA3
	cpc	rB4, rA4
	cpc	rB5, rA5
	cpc	rB6, rA6
	ret
	
/*  __fp64_cpc0A5() compare A with 0
   Input:
		rA5.rA4.rA3.rA2.rA1.rA0  - A in unpacked format
   Return:
		C=1		0 > A
		C=0 Z=1	0 == A
		C=0 Z=0 0 < A
	Modifies:
		SREG
 */

ENTRY __fp64_cpc0A5
	cp r1, rA0
	cpc r1, rA1
	cpc r1, rA2
	cpc r1, rA3
	cpc r1, rA4
	cpc r1, rA5
	ret
	
/*  __fp64_cpc0B5() compare B with 0
   Input:
		rB5.rB4.rB3.rB2.rB1.rB0  - B in unpacked format
   Return:
		C=1		0 > B
		C=0 Z=1	0 == B
		C=0 Z=0 0 < B
	Modifies:
		SREG
 */

ENTRY __fp64_cpc0B5
	cp	r1, rB0		; check rest of mantissa
	cpc	r1, rB1
	cpc	r1, rB2
	cpc	r1, rB3
	cpc	r1, rB4
	cpc	r1, rB5
	ret
ENDFUNC
