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

#include "fp64asm.h"
#include "fp64def.h"

/*	float64_t fp64_log( float64_t x );
	returns the natural logarithm ln of x
*/
FUNCTION fp64_log

	; case|	A	  |	log(A)
	;-----+-------+-----------------------------
	; 1	  |	< 0   |	NaN		< 0 includes -Inf
	; 2	  |	NaN	  |	NaN
	; 3	  |	+Inf  |	+Inf	-Inf is part of "< 0"
	; 4	  |	0	  |	-Inf
	; 5   | 1     | 0		no special handling needed

/*	float64_t fp64_log( float64_t x );
	returns the natural logarithm ln of x
*/
ENTRY fp64_log
ENTRY_DOUBLE log logl
	XCALL _U(fp64_log2)

	XCALL _U(__fp64_pushB)		; preserve registers

	;; ln(x) = log2(x) * ln2
	LPMX_INIT ZL, .L_ln2
	XCALL _U(__fp64_ldb8_const)
	LPMX_FINI r1

	XCALL _U(fp64_mul)

	XJMP _U(__fp64_popBret)		; restore registers and return
ENDFUNC

PGMX_SECTION (fp64.logx)

OBJECT .L_ln2
	.byte 0x3F, 0xE6, 0x2E, 0x42, 0xFE, 0xFA, 0x39, 0xEF
ENDOBJ .L_ln2
