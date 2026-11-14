/* Copyright (c) 2018-2020  Uwe Bissinger
   Based on 32bit floating point arithmetic routines which are:
   Copyright (c) 2002, Joerg Wunsch
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

#include "fp64asm.h"
#include "fp64def.h"

/* int fp64_isnan( float64_t x );
     The fp64_isnan() function returns a non-zero value if value is
     "not-a-number" (NaN), and 0 otherwise.
 */

FUNCTION fp64_isnan
ENTRY fp64_isnan
GCC_ENTRY __unorddf2
	rcall __fp64_AisNaN
	ldi	r24, 0
	ldi	r25, 0
	adc	r24, r24				; C = 1 for NaN
1:	ret

/* __fp64_AisNaN: internal entry to fp64_isnan( float64_t x )
	Input:	rA7..rA0	x in packed IEEE format
	Output:	C = 1		iff x is a NaN
			C = 0		iff x is not a NaN
	Modifies: nothing except flags
 */
ENTRY __fp64_AisNaN
	push rA7
	andi rA7, 0x7f				; ignore sign
	
	cpi rA7, hi8(0x7ff0)
	brlo 0f
	cpi rA6, lo8(0x7ff0)
	brlo 0f
	brne 1f
	XCALL _U(__fp64_cpc0A5)		; is it NaN or Inf, check rA0-rA5 against 0
	breq 0f						; it's INF, return C=0
1:
	sec							; it's a NaN, return C=1
	rjmp 2f
0:
	clc							; not a NaN, return C=0
2:
	pop rA7
	ret
ENDFUNC
