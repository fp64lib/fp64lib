/* Copyright (c) 2019-2020  Uwe Bissinger
   Based on 32bit floating point arithmetic routines which are:
/* Copyright (c) 2002  Michael Stumpf  <mistumpf@de.pepperl-fuchs.com>
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

/* int fp64_ilogb(float64_t A);
   Returns the integral part of the logarithm of |x| to base 2.
   
   This is the exponent used internally to express the floating-point
   value x, when it uses a significand between 1.0 and 2, so that, 
   for a positive x:
		x = significand * 2^exponent
   Generally, the value returned by this function is one less than 
   the exponent obtained with frexp (because of the different significand 
   normalization as [1.0,2.0) instead of [0.5,1.0)).
   
   	The following rules apply:

	case|    x	 | result
	----+--------+------------
	  1 |   NaN  | FP_ILOGBNAN
	  2 | +/-Inf | INT_MAX
	  3 | +/-0.0 | FP_LOGB0
	  4 |  else  | ilogb(x)

 */

FUNCTION fp64_ilogb

	; check non-finite numbers
.L_nf:
	brne .L_nan					; case 1: NaN  --> return FP_ILOGBNAN
	
	; case 2: +/-Inf --> return INT_MAX
	ldi rA7, 0x7f
	ldi rA6, 0xff
	ret
	
	; case 1: NaN  --> return FP_ILOGBNAN
.L_nan:
	ldi rA7, hi8(FP_ILOGBNAN)
	ldi rA6, lo8(FP_ILOGBNAN)
	ret
	
	; case 3: +/-0.0 --> return FP_LOGB0
.L_zero:
	ldi rA7, hi8(FP_ILOGB0)
	ldi rA6, lo8(FP_ILOGB0)
	ret
	
/*	float64_t fp64_log( float64_t x );
	returns the natural logarithm ln of x
*/
ENTRY fp64_ilogb
GCC_ENTRY __ilogb
	andi rA7, 0x7f				; ignore sign
	XCALL _U(__fp64_splitA)
	brcs .L_nf					; handle cases 1-2 (NaN, Inf)
	breq .L_zero				; handle case 3 (0.0)
	
	sbrs rA6, 7				; is x a subnormal number?
	XCALL _U(__fp64_norm2)	; yes: normalize it

	; subtract base for exponent (0x3ff = 1023)
	subi rAE0, lo8(1023)
	sbci rAE1, hi8(1023)	

	movw rA6, rAE0				; and return result
	; rcall __fp64_saveAB	
	ret
	
ENDFUNC
