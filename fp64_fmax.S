/* Copyright (c) 2019-2020  Uwe Bissinger
   Based on 32bit floating point arithmetic routines which is:
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

#include "fp64def.h"
#include "asmdef.h"

FUNCTION fp64_fmin
/* float64_t fp64_fmin (float64_t A, float64_t B);
    The fp64_fmin() function returns the lesser of the two values A and B.
	The following rules apply:
	 case|	A	 |	B	 |	fp64_fmin(A,B)
	-----+-------+-------+------
	 1	 |	NaN	 |	any	 |	NaN	
	 2	 |	any	 |	NaN	 |	NaN 
	 3	 |	< 0  |	>= 0 |	A
	 4	 |	>=0	 |	< 0	 |	B	
	 5	 |	A>=B |	any  |	B 
	 6	 |	A<B  |	any	 |	A	
*/

ENTRY fp64_fmin
GCC_ENTRY __fmin
	set							; set flag for fmin
	rjmp .L_common


/* float64_t fp64_fmax (float64_t A, float64_t B);
    The fp64_fmax() function returns the greater of the two values A and B.
	The following rules apply:
	 case|	A	 |	B	 |	fp64_fmax(A,B)
	-----+-------+-------+------
	 1	 |	NaN	 |	any	 |	NaN	
	 2	 |	any	 |	NaN	 |	NaN 
	 3	 |	< 0  |	>= 0 |	B
	 4	 |	>=0	 |	< 0	 |	A	
	 5	 |	A>=B |	any  |	A 
	 6	 |	A<B  |	any	 |	B
*/

ENTRY fp64_fmax
GCC_ENTRY __fmax
   clt							; clear flag for fmin
.L_common:	
	push rB7
	lsl rA7
	sbc rAE1, rAE1				; rAE1 = (A < 0) ? -1 : 0
	lsl rB7
	sbc rBE1, rBE1				; rBE1 = (B < 0) ? -1 : 0

	; isNan(A)
	ldi rBE0, 0xf0				; A is NaN if A is >0x3ff0000000000000
	ldi rAE0, 0xfe				; as rA7 is shifted, max high byte is now 0x3f << 1 --> 0xfe
    XCALL _U(__fp64_cpc0A5)
	cpc rBE0, rA6
	cpc rAE0, rA7
	brlo .L_retB				; case 1: A is NaN --> return B
	
	; isNan(B)
	XCALL _U(__fp64_cpc0B5)
	cpc rBE0, rB6
	cpc rAE0, rB7
	brlo .L_retA				; case 2: B is NaN --> return A
	
	; neither A nor B are NaN
    ; compare signs
	cp	rAE1, rBE1
	brtc 1f
	cp rBE1, rAE1
1:	brlt .L_retB				; case 3 fmax, case 4 fmin --> return B
	brne .L_retA				; case 4 fmax, case 3 fmin --> return A
	
	; case 5,6: compare absolute values for fmax
	brts 3f
	XCALL _U(__fp64_cpcAB)
	cpc	rA7, rB7				; C is set, if A < B

	; analyse result
2:	ror rBE1					; V = C ^ sign
	brvc .L_retA				; case 5: A >= B for fmax, B >= A for fmin, return A
	
	; return B
.L_retB:
	mov rAE1, rBE1				; move B to A, including saved sign
	XCALL _U(__fp64_movAB)
	; return A
.L_retA:
	lsr rAE1					; restore the sign
	ror rA7
	pop rB7
	ret

	; case 5,6: compare absolute values for fmin
3:	XCALL _U(__fp64_cpcBA)
	cpc	rB7, rA7				; C is set, if B < A
	rjmp 2b

ENDFUNC
