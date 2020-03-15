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

/* float64_t fp64_trunc( float64_t A );
    Rounds A to the nearest integer not larger in absolute value,
	by cutting the noninteger part ( = setting the fractional part to 0).
	This is effectively the same as rounding A towards 0.
	
	The following rules apply:
	 
	case|           A	       | result
	----+----------------------+------------
	  1 |          NaN         | NaN
	  2 |         +Inf         | +Inf
	  3 |         -Inf         | -Inf
	  4 |          0.0		   | 0.0
	  5 |         -0.0		   | -0.0
	  6 |          |A|>=2^52   | A
	  7 |       0 <|A|< 1      | 0.0
	  8 |       1=<|A|< 2^52   | A - fractional_part(A)

   Input:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0 - A in IEEE 754 - 64-bit format
   Output:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0 - trunc(x)
   Examples:
     fp64_trunc(1.9) --> 1.0
     fp64_trunc(-1.9) --> -1.0
 */
 
 #if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

FUNCTION fp64_trunc
	; handle NaN and +/-Inf
.L_NaN:
	breq .L_Inf					; handle Inf differently
	XJMP _U(__fp64_nan)			; case 1: return NaN

.L_Inf:
	XJMP _U(__fp64_inf)			; case 2&3: return +/- Inf

.L_zr:
	XJMP _U(__fp64_szero)		; case 4&5: return +/- 0

ENTRY	fp64_trunc
GCC_ENTRY __trunc
ENTRY   fp64_cut_noninteger_fraction
	XCALL _U(__fp64_splitA)
	brcs .L_NaN					; handle NaN and +/-INF
	breq .L_zr					; case 4, 5: return 0 for 0

	subi rAE0, lo8(1023)		; remove exponent bias: exp -= 1023
	sbci rAE1, hi8(1023)
	tst rAE1
	brmi .L_zr					; 0 < |x| < 1, case 7, return 0
	brne .L_ret				; |x| > 2^255, case 6, return x 
	cpi rAE0, 52
	brge .L_ret					; |x| >= 2^52, case 6, return x
	
	; now x is in range 1 <= |x| < 2^52
	; clear out the fractional bits
	
	ldi rA7, 0xff				; inital mask
	ldi rAE1, 55				; counter = (52 digits + 3 saveguard digits) - exp2(x)
	sub rAE1, rAE0				; as |x| < 2^52, this is always > 1
	andi rAE1 ,0x07				
0:	breq 1f
	lsl rA7
	dec rAE1
	rjmp 0b

1:	; rA7 now contains the mask to clear out the bits inside a register
	; now determine which registers have to be cleared

	push rAE0
	andi rAE0, 0xf8				; bottom 3 bits were already used above
	lsr rAE0					; index = (exp/8)*4 as 4 byte are used for clearing out a register
	mov rAE1, rAE0				; take care of proper order of operation as rAE0 == ZL!
	ldi ZL, lo8(.L_mask)		; add offset to jump table

	add ZL, rAE1		
	ldi ZH, hi8(.L_mask)
	adc ZH, r1					; take care of any overflows
	; rcall __fp64_saveAB
	lsr ZH						; PC addresses words, so divide target address by 2
	ror ZL
	ijmp						; and clear out the bits top to bottom
		
.L_mask:
	; for 2^0 <= |x| < 2^8, i.e. (rAE0/8)*4 == 0 
	and rA6, rA7				; clear out parts of rA6
	clr rA7						; and all lower digits

	; for 2^8 <= |x| < 2^16, i.e. (rAE0/8)*4 == 4 
	and rA5, rA7				; clear out parts of rA5
	clr rA7     				; and all lower digits

	; for 2^16 <= |x| < 2^24, i.e. (rAE0/8)*4 == 8 
	and rA4, rA7				; clear out parts of rA4
	clr rA7     				; and all lower digits

	; for 2^24 <= |x| < 2^32, i.e. (rAE0/8)*4 == 12 
	and rA3, rA7				; clear out parts of rA3
	clr rA7     				; and all lower digits

	; for 2^32 <= |x| < 2^40, i.e. (rAE0/8)*4 == 16 
	and rA2, rA7				; clear out parts of rA2
	clr rA7     				; and all lower digits

	; for 2^40 <= |x| < 2^48, i.e. (rAE0/8)*4 == 20 
	and rA1, rA7				; clear out parts of rA1
	clr rA7     				; and all lower digits

	; for 2^48 <= |x| < 2^52, i.e. (rAE0/8)*4 == 24
	and rA0, rA7				; clear out parts of rA6

	clr rAE1					; restore proper exponent 0 <= rAE1.rAE0 < 52
	pop rAE0

.L_ret:
	subi rAE0, -0xff			; add base 1023
	sbci rAE1, -0x04
	XJMP _U(__fp64_pretA)		; pack and return x

ENDFUNC

#endif /* !defined(__AVR_TINY__) */

