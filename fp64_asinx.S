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

/*	float64_t fp64_asin(float64_4 phi )
	returns the arcus cos of phi (inverse function to fp64_sin(x)
	
	Basic algorithm:
	fp64_asin( x ) {
  		if( (x1 = fabs(x)) > 1.0 )
	  		return NaN
  
		sign = sign(x)
		if( x1 <= 0.5 )
			x2 = 2*x1*x1
			factor = x1
  		else
			x2 = 1 - x1
			factor = sqrt(2*x2)
		res = horner( x2, coeff_nominator )
		x3 = horner( x2, coeff_denominator )
		res = res / x3  * factor
		if( x1 <= 0.5 )
			res = res - PI/2
			if( sign )
				res =  -res
		return sign * res
	
*/
FUNCTION fp64_asin

	; case |   x   | asin(x)  | acos(x)
	;------+-------+----------+--------
	;  1a  |  NaN  |    NaN   |  NaN
	;  1b  | +/-Inf|    NaN   |  NaN
	;  2   |   0.0 |    0.0   | PI/2
	;  3   | <-1.0 |    NaN   |  NaN
	;  4   | >+1.0 |    NaN   |  NaN
	;  5   |  -1.0 |   -PI/2  |  PI
	;  6   |  +1.0 |   +PI/2  |  0
	;  7   |  else |  asin(x) | acos(x)

	; cases 1a, 1b: NaN, +Inf, -Inf
	; cases 3, 4: |x| > 1.0
.L_nan:
	XJMP _U(__fp64_nan)
	
	; case 2: 0 --> 0 (for asin) or PI/2 (for acos)
.L_zero:
	sbrs r0, 1					; acos?
	XJMP _U(__fp64_szero)		; no: return 0.0 for asin
	clt							; yes: return +PI/2 for acos	
	XJMP _U(__fp64_pi2)

/*	float64_t fp64_acos(float64_4 phi )
	returns the arcus cosine of phi (inverse function to fp64_cos(x)
*/
ENTRY fp64_acos
GCC_ENTRY __acos
	inc r1
	inc r1				; set bit 1 of r1 as flag for acos

/*	float64_t fp64_asin(float64_4 phi )
	returns the arcus sine of phi (inverse function to fp64_sin(x)
*/
ENTRY fp64_asin
GCC_ENTRY __asin
	sts __sinFlags, r1	; either r1 = 0 (default) or r1 = 0x02 (acos)
	clr r1
	XCALL _U(__fp64_splitA)
	lds r0, __sinFlags	
	bld r0, 7			; save sign of x in __sinFlags
	sts __sinFlags, r0
	brcs .L_nan		; NaN or +/- INF
	breq .L_zero	; x = 0 --> result of asin = 0
	
	cpi rAE1, 0x03	; fabs(x) < 1.0?
	brmi 10f		; definitely yes, x < 2^-255 --> go ahead with approximation by poly(2*x^2)*x
	brne .L_nan		; definitely no, x >= 2.0 --> cases 3,4, return NaN
	
	; maybe yes, 2^-255 < x < 2.0
	cpi rAE0, 0xfe
	brlo 10f		; |x| < 0.5 --> go ahead with approximation by poly(2*x^2)*x
	breq 20f		; 0.5 <= |x| < 1.0 --> --> go ahead with approximation by poly(1-x)*sqrt(2*x)
	
	; now here: 1 <= |x| < 2
	; check, whether |x| is == 1.0, i.e. significand = 0x80....0

	XCALL _U(__fp64_cpc0A5)
	brne .L_nan
	cpi rA6, 0x80
	brne .L_nan
	
	; cases 5,6: fabs(x) = 1.0 --> return +/- PI/2 for asin, 0 or PI for acos
	sbrs r0,1				; acos?
	XJMP _U(__fp64_pi2)		; no: return +/- PI/2
	
	sbrs r0, 7				; x == -1?
	XJMP _U(__fp64_szero)	; no --> x == 1 --> return +0
	clt
	XCALL _U(__fp64_pi2)	; yes, return +PI/2
	adiw rA6, 0x10			; modify exponent to become 0x400
	ret
	
	; 0.5 < fabs(x) < 1.0
	; approximate asin(x) with MiniMax(1-x)*sqrt(2*x)
20:	inc r0				; set bit 0 --> |x| > 0.5	

10:	; fabs(x) < 0.5 approximate asin(x) with MiniMax
	; bld r0, 7
	sts __sinFlags, r0	; save sign and function
	clt

	XCALL _U(__fp64_pushCB)	; as all registers may be used, save them
	push YH
	push YL
	push XH
	push XL
	
	XCALL _U(__fp64_movBAx)	; B = A = x1

	lds r0, __sinFlags
	sbrc r0, 0
	rjmp 21f
11:	
	; x1 <= 0.5
	; compute x2 = 2 * x1 * x1
	; and put x1 = fabs(x) as factor on the stack
	XCALL _U(__fp64_pushA)	; save factor = x1 = fabs(x)
	push rAE1
	push rAE0
	
	XCALL _U(__fp64_mulsd3_pse)
	adiw rAE0, 1			; x2 = 2*x1*x1
	rjmp 12f

	; x1 > 0.5
	; compute x2 = 1 - x
	; and put sqrt(2*x2) as factor on the stack
21:	
	mov rA7, r1						; A = 1.0
	ldi rA6, 0x80
	mov rA5, r1
	mov rA4, r1
	X_movw rA2, rA4
	X_movw rA0, rA4
	ldi rAE0, 0xff
	ldi rAE1, 0x03

	clt								; clear sign
	XCALL _U(__fp64_sub_pse)		; x2 = 1 - x1
	clt
	
	XCALL _U(__fp64_pushA)			; save x2 = 1 - x1
	push rAE1
	push rAE0

	adiw rAE0, 1					; 2*x2
	XCALL _U(__fp64_sqrt_pse)		; factor = sqrt(2*x2)


	pop rBE0						; retrieve x2
	pop rBE1
	XCALL _U(__fp64_popB)

	;rcall __fp64_saveAB

	XCALL _U(__fp64_pushA)			; save factor = sqrt(2*x2)
	push rAE1
	push rAE0

	XCALL _U(__fp64_movABx)			; A = B = x2
	
12:
	; start polynom calculation
	; A: x2
	; B: undefined
	; stack: factor
	; rcall __fp64_saveAB

	XCALL _U(__fp64_pushA)			; save x2
	push rAE1
	push rAE0

	ldi XL, lo8(.L_tableAsinDenom)	; calculate Denominator
	ldi XH, hi8(.L_tableAsinDenom)
	XCALL _U(__fp64_powser)
	
	pop rBE0						; retrieve x2
	pop rBE1
	XCALL _U(__fp64_popB)

	XCALL _U(__fp64_pushA)			; save x3 = horner( x2, coeff_nenner )
	push rAE1
	push rAE0
	
	XCALL _U(__fp64_movABx)			; A = B = x3
	ldi XL, lo8(.L_tableAsinNom)	; calculate Nominator
	ldi XH, hi8(.L_tableAsinNom)
	XCALL _U(__fp64_powser)			; res = horner( x2, coeff_zähler )
	
	pop rBE0						; retrieve Denominator x3 = horner( x2, coeff_nenner )
	pop rBE1
	XCALL _U(__fp64_popB)

	; rcall __fp64_saveAB
	
	XCALL _U(__fp64_divsd3_pse)	; res = res / x3
	
	pop rBE0				; retrieve either x1 = fabs(x) or x1 = sqrt(2*fabs(x))
	pop rBE1
	XCALL _U(__fp64_popB)
	
	XCALL _U(__fp64_mulsd3_pse)	; res = res / x3 * x1 or res = res / x3 * sqrt(2*fabs(x))
	
	lds r0, __sinFlags			; retrieve sign(x)
	sbrc r0, 1					; acos?
	rjmp 23f					; yes, handle acos
								; no, handle asin
	sbrs r0, 0					; |x| > 0,5?
	rjmp 19f					; no, result is already ok
	
	; yes: adjust result to PI/2 - res or res - PI/2
	XCALL _U(__fp64_ldb_pi2)
	XCALL _U(__fp64_sub_pse)	; compute res - PI/2

	lds r0, __sinFlags			; retrieve sign(x)
	sbrs r0, 7					; if( sign )
	rjmp 19f

18:
	bld rA7, 7					; 	res = -res
	subi rA7, 0x80
	
19:	
	pop XL						; restore all used registers
	pop XH
	pop YL
	pop YH
	XCALL _U(__fp64_popBC)
	
	lds r0, __sinFlags			; retrieve sign(x)
	sbrs r0,1					; asin?
	bst r0, 7					; yes, return res*sign

.L_retA:	
	XJMP _U(__fp64_rpretA)		; return res
	
23:	; handle acos  --> r0 bit 1 set
	XCALL _U(__fp64_ldb_pi2)	; B = PI/2
	sbrc r0, 0					; |x| <= 0.5?
	adiw rBE0, 1				; no: B = PI/2*2 = PI
	
	; A: res
	; B: PI/2 or PI (for |x|>0.5)
	tst r0						; x < 0 ?
	brmi 24f
	; x >= 0 --> either pi/2 - res or res
	sbrc r0, 0					; |x| <= 0,5?
	rjmp 19b					; no, return res
	rjmp 25f					; yes, return -res + pi/2

24: ; x < 0 --> either pi/2 + res or pi - res
	sbrc r0, 0					; |x| <= 0,5?
25:	
	subi rA7, 0x80				; no, change sign of res --> -res + pi
	bst rA7, 7
	; rcall __fp64_saveAB
	XCALL _U(__fp64_add_pse)	; compute res + pi/2 or -res + pi
	rjmp 19b
	

.L_tableAsinNom:
	; Ideal polynom: 
	; + 0.0000084705471128435769021718764878041684288 * x^5
	; + 0.0012557428614630796315205218507940285622 * x^4 
	; - 0.04333483170641685705612351801 * x^3 
	; + 0.35290206232981519813422591897720574012 * x^2 
	; - 1.035234033892197627842731209 * x 
	; + 0.99999999999999999442491073135027586203  
	.byte 5	; polynom power = 5 --> 6 entries
	.byte 0x00, 0x8e, 0x1c, 0xb9, 0x0b, 0x50, 0x6c, 0xce, 0x03, 0xee	;  0.000008470547112843576902172332924136939494644
	.byte 0x00, 0xa4, 0x97, 0xbd, 0x0b, 0x59, 0xc9, 0x25, 0x03, 0xf5	;  0.001255742861463079621886854142509548637463
	.byte 0x80, 0xb1, 0x7f, 0xdd, 0x4f, 0x4e, 0xbe, 0x1d, 0x03, 0xfa	; -0.04333483170641685630619655000828061020002 
	.byte 0x00, 0xb4, 0xaf, 0x94, 0x40, 0xcb, 0x86, 0x69, 0x03, 0xfd	;  0.35290206232981519813422591897720574012
	.byte 0x80, 0x84, 0x82, 0x8c, 0x7f, 0xa2, 0xf6, 0x65, 0x03, 0xff	; -1.035234033892197619275421516249480191618
	.byte 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xff	;  1.0000000000000000000000000000000000000000
	.byte 0x00												; byte needed for code alignment to even adresses!

.L_tableAsinDenom:
	; Ideal polynom: 
	; + 0.0028820878185134035637440105959294542908 *x^4
	; - 0.06355588484963171659942148390 * x^3 
	; + 0.42736600959872448854098334016758333519 * x^2 
	; - 1.118567367225532923662371649 * x 
	; + 1
	.byte 4	; polynom power = 4 --> 5 entries
	.byte 0x00, 0xbc, 0xe1, 0x68, 0xec, 0xba, 0x20, 0x29, 0x03, 0xf6	;  0.002882087818513403567558667228709623486793
	.byte 0x80, 0x82, 0x29, 0x96, 0x77, 0x2e, 0x19, 0xc7, 0x03, 0xfb	; -0.06355588484963171740094178829849624889903
	.byte 0x00, 0xda, 0xcf, 0xb7, 0xb5, 0x4c, 0x0d, 0xee, 0x03, 0xfd	;  0.4273660095987244916804215222327911760658
	.byte 0x80, 0x8f, 0x2d, 0x37, 0x2a, 0x4d, 0xa1, 0x57, 0x03, 0xff	; -1.118567367225532932506482097778643947095
	.byte 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xff	;  1.0000000000000000000000000000000000000000
	.byte 0x00												; byte needed for code alignment to even adresses!
	
ENDFUNC

.data
__sinFlags:	 .skip 1
