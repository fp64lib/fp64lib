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

#include "fp64asm.h"
#include "fp64def.h"

/*
   float64_t fp64_scalbln (float64_t x, long n)
   fp64_scalbln behaves identical to fp64_ldexp() or fp64_scalbn,
   but can be called with n being of type long instead of int.

   The fp64_ldexp() function returns the result of multiplying the
   floating-point number x by 2 raised to the power n.
  The following rules apply:

	case|           x	        | result
	----+-----------------------+------------
	  1 |          NaN          | NaN
	  2 |         +/-Inf        | +/- Inf
	  3 |         +/-0.0	    | +/- 0.0
	  4 | exponent(x)+n > 1023  | +/- Inf (Overflow)
	  5 | exponent(x)+n <-1074  | +/- 0.0 (Underflow)
	  6 | exponent(x)+n <-1023  | x*2^exp as subnormal number
	  7 | exponent(x)+n >=-1023 | x*2^exp

 */

#define S0  r14
#define S1  r15
#define S2  r16
#define S3  r17

ENTRY fp64_scalbln
ENTRY_DOUBLE scalbln scalblnl
	push	r17
	push	r16
	;; R0 = signs (lo16 (S)).
	mov		r0, S1
	lsl		r0
	sbc		r0, r0
	;; Test whether S == sign_extend (lo16 (S)).
	cp		S2, r0
	cpc		S3, r0
	;; If yes, scalbn (lo16 (S)) will do the job.
	breq 1f

	;; Otherwise, saturate S to a signed 16-bit value.
	;; sign S = 0 ->  hi16 = 0x7fff
	;; sign S = 1 ->  hi16 = 0x8000
	cpi		S3, 0x80
	sbc		S2, S2
	sbc		S3, S3
	subi	S3, 0x80
	rjmp 2f

1:	;; scalbn() with a 16-bit exponent is just fine.
	X_movw	S2, S0

2:	XCALL	_U(fp64_scalbn)
	pop		r16
	pop		r17
	ret
ENDFUNC
