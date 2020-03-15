/* Copyright (c) 2019-2020  Uwe Bissinger
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

/* float __fp64_sdsf (float64_t A);
   float fp64_ds (float64_t A);
    Converts a float64 to the float32 representing the same number.
	As the range of float is significandly smaller than float64_t,
	the following rules apply:
	 
	case|           A	       | result
	----+----------------------+------------
	  1 |          NaN         | 0x7fffffff (NaN in float)
	  2 |         +Inf         | 0x7f800000 (+Inf in float)
	  3 |         -Inf         | 0xff800000 (-Inf in float)
	  4 |          0.0		   | 0x00000000 (0.0 in float)
	  5 |         -0.0		   | 0x80000000 (-0.0 in float)
	  6 |           x >=2^128  | 0x7f800000 (+Inf in float)
	  7 |  -2^128 <=x          | 0xff800000 (-Inf in float)
	  8 |       0 < x < 2^-149 | 0x00000000 (0.0 as float, underflow)
	  9 | -2^-149 < x < 0      | 0x80000000 (-0.0 as float, underflow)
	 10 |  2^-149 < x < 2^-126 | 0x00mmmmmm (subnormal number with mmmmmm < 0x800000)
	 11 | -2^-126 < x <-2^-149 | 0x80mmmmmm (subnormal number with mmmmmm < 0x800000)
	 12 |  2^-126 <|x|< 2^127  | (float) A
	  
	Significand is rounded up, if bit 25 of significand of A is set

   Input:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0 - A in IEEE 754 - 64-bit format
   Output:
     rA7.rA6.rA5.rA4  				 - arg. A in IEEE 754 - 32-bit format
 */
 
 #if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

FUNCTION fp64_ds
	; handle NaN and +/-Inf
.L_NaN:
	breq .L_Inf					; handle Inf differently
	XJMP _U(__fp_nan)			; case 1: return NaN

.L_Inf:
	XJMP _U(__fp_inf)			; case 2&3: return +/- Inf

.L_zr:
	XJMP _U(__fp_szero)			; case 4&5: return +/- 0

GCC_ENTRY __truncdfsf2
ENTRY fp64_ds
	XCALL _U(__fp64_splitA)
	brcs .L_NaN					; handle NaN and +/-INF
	breq .L_zr					; return 0 for 0

	subi rAE0, lo8(1023)		; remove exponent bias: exp -= 1023
	sbci rAE1, hi8(1023)
	cpi rAE1, 0x01
	brge .L_Inf					; return Inf as exponent > 255 (case 6&7)
	cpi rAE1, 0xff
	brlt .L_zr					; return 0 as exponent < -255 (case 8&9)
	
	; now rAE1 is either 0x00 or 0xff -- > exponent is in range -256 < exp < 255
	tst rAE1
	brpl 1f
	; rcall __fp64_saveAB
3:	cpi rAE0, -127-23			; is A < 2^-149
	brlo .L_zr					; yes, case 8&9, return 0
	cpi rAE0, -126				; is A >= 2^-126
	brsh .L_norm				; yes, it's a normal number
	
	; handle subnormal numbers
	subi rAE0, -126				; normalize exponent, exponent will be positive after this
	
0:	lsr rA6						; create subnormal number (case 10&11)
	ror rA5
	ror rA4
	inc rAE0					; until exponent is no longer positive
	; rcall __fp64_saveAB
	brmi 0b
	
	clr rA7						; clear exponent to identify subnormal number
	rjmp 2f
	
	; check for exponent 
1:	cpi rAE0, 128
	brsh .L_Inf					; return Inf as exponent is > 127 (case 6&7)

	; case 12: 2^-126 < x < 2^127, return( (float) x)
.L_norm:
	subi rAE0, -127				; add exponent base to float exponent
								; this will not trigger any overflow conditions

	; TODO: handle rounding
	; sbrc rA4,7					; if bit 24 is set, round up
	; rjmp .L_round

	; now pack and return the result
.L_pack:
	lsl rA6						; get rid of leading 1 bit
	mov rA7, rAE0				
	lsr rA7						; make room for sign bit
	ror rA6						; and shift bit 0 of exponent into bit 7 of significand
2:	bld rA7, 7					; place sign bit into sign bit of float
								; rest of significand already in place at rA5 and rA4
	ret

ENDFUNC

#endif /* !defined(__AVR_TINY__) */

