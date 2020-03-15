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

#if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

/* float64_t fp64_ldexp (float64_t x, int exp)
   The fp64_ldexp() function returns the result of multiplying the
   floating-point number x by 2 raised to the power exp.
  The following rules apply:

	case|           x	         | result
	----+------------------------+------------
	  1 |          NaN           | NaN
	  2 |         +/-Inf         | +/- Inf
	  3 |         +/-0.0	     | +/- 0.0
	  4 | exponent(x)+exp>1023   | +/- Inf (Overflow)
	  5 | exponent(x)+exp<-1074  | +/- 0.0 (Underflow)
	  6 | exponent(x)+exp<-1023  | x*2^exp as subnormal number
	  7 | exponent(x)+exp>=-1023 | x*2^exp
	  

 */

FUNCTION fp64_ldexp

	; handle NaN and +/-Inf
.L_NaN:
	breq .L_Inf					; handle Inf differently
	XJMP _U(__fp64_nan)			; case 1: return NaN

.L_Inf:
	XJMP _U(__fp64_inf)			; case 2: return +/-Inf

.L_zr:
	XJMP _U(__fp64_szero)		; case 3: return +0

ENTRY fp64_ldexp
GCC_ENTRY __ldexp
	XCALL _U(__fp64_splitA)
	brcs .L_NaN					; handle cases 1&2: NaN and +/-INF
	breq .L_zr					; case 3: return 0 for 0
	
	sbrs rA6, 7					; does significand start with a leading bit?
	XCALL _U(__fp64_norm2)		; no: normalize subnormal number
	
	; now "multiply" by 2^exp
	; this is done by adding exp to exponent of A
	add rAE0, rB6
	adc rAE1, rB7
	; rcall __fp64_saveAB
	brvs .L_Inf					; case 4: abs(exponent) > 0x7fff
	
	; check for overflow
	cpi rAE1, 0x07
	; rcall __fp64_saveAB
	brlt 0f
	brne .L_Inf					; case 4: exponent >= 0x0800
	cpi rAE0, 0xff
	brge .L_Inf					; case 4: exponent >= 0x07ff
0:	; check for underflow
	adiw rAE0, 0
	brpl .L_norm				; exponent >= 0 --> go ahead

	cpi rAE1, 0xff
	brlo .L_zr					; case 5: exponent < -1023-255 --> underflow
	cpi rAE0, -51
	brlo .L_zr					; case 5: exponent < -1023-51 --> underflow
	
	; case 6: exponent between -1024 and -1074
	; create subnormal number
1:	XCALL _U(__fp64_lsrA)		; A >>= 1
	inc rAE0
	brmi 1b
	
	clr rAE0
	clr rAE1

	; case 7: return x
.L_norm:
	XJMP _U(__fp64_pretA)		; pack and return x
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
