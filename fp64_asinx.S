/* Copyright (c) 2020-2026  Uwe Bissinger
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

/*	float64_t fp64_asin( float64_t phi )
	returns the arcus cos of phi (inverse function to fp64_sin(x))

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
		res = res / x3	* factor
		if( x1 <= 0.5 )
			res = res - PI/2
			if( sign )
				res =  -res
		return sign * res

*/
FUNCTION fp64_asin

	; case |   x   | asin(x)  | acos(x)
	;------+-------+----------+--------
	;  1a  |  NaN  |	NaN	  |	 NaN
	;  1b  | +/-Inf|	NaN	  |	 NaN
	;  2   |   0.0 |	0.0	  | PI/2
	;  3   | <-1.0 |	NaN	  |	 NaN
	;  4   | >+1.0 |	NaN	  |	 NaN
	;  5   |  -1.0 |   -PI/2  |	 PI
	;  6   |  +1.0 |   +PI/2  |	 0
	;  7   |  else |  asin(x) | acos(x)

	; cases 1a, 1b: NaN, +Inf, -Inf
	; cases 3, 4: |x| > 1.0
.L_nan:
	XJMP _U(__fp64_nan)

	; case 2: 0 --> 0 (for asin) or PI/2 (for acos)
.L_x_zero:
	.sbrs_callj XH, 1			; acos?
.L_szero:
	XJMP _U(__fp64_szero)		; no: return 0.0 for asin
.L_pi2:
	clt							; yes: return +PI/2 for acos
.L_pm_pi2:
	XJMP _U(__fp64_pi2)

/*	float64_t fp64_acos( float64_t phi )
	returns the arcus cosine of phi (inverse function to fp64_cos(x))
*/
ENTRY fp64_acos
ENTRY_DOUBLE acos acosl
	ldi XH, 1 << 1				; XH.1 = 1: do acos.
	rjmp .L_common

/*	float64_t fp64_asin( float64_t phi )
	returns the arcus sine of phi (inverse function to fp64_sin(x))
*/
ENTRY fp64_asin
ENTRY_DOUBLE asin asinl
	ldi XH, 0 << 1				; XH.1 = 0: do asin.
.L_common:
	bst rA7, 7			 		; T := sign (x)
	bld XH, 7					; Transfer sign to the flags

	;; As it turns out, working on the packed IEEE format for
	;; a while is more convenient than unpacking too early.

	cbr rA7, 0x80				; x := |x|
	;; Compare 1.0 <=> |x|.
	XCALL _U(__fp64_cpc0A5)
	ldi	ZL, lo8(0x3ff0)  $  cpc ZL, rA6
	ldi	ZH, hi8(0x3ff0)  $  cpc ZH, rA7
	brlt .L_nan					; 1.0 < |x| --> NaN
	brne 1f						; 1.0 > |x| --> do the math

	;; cases 5,6: |x| = 1.0 --> return +/- PI/2 for asin, 0 or PI for acos
	sbrs XH, 1					; acos?
	rjmp .L_pm_pi2				; no: return +/- PI/2

	brtc .L_szero				; x == +1 --> return +0
	rcall .L_pi2				; x == -1 --> return +PI
	adiw rA6, 0x10				; modify exponent to become 0x400
	ret

1:
	;; |x| < 1.0
	;; Compare 0.5 <=> |x|.
	sbiw ZL, 0x10				; Z := 0x3fe0 = hi16(0.5)
	XCALL _U(__fp64_cpc0A5)
	cpc ZL, rA6
	cpc ZH, rA7
	adc XH, r1					; XH.0 := |x| > 0.5
	sts __sinFlags, XH
	bld	rA7, 7					; Restore sign of x, only needed for -0.0

	XCALL _U(__fp64_splitA)
	breq .L_x_zero				; x == 0 --> result of asin(0) / acos(0)

	clt

	XCALL _U(__fp64_pushCB)		; save the used callee-saved registers
	push YH
	push YL

	XCALL _U(__fp64_movBAx)		; B = A = x1

	lds r0, __sinFlags
	sbrc r0, 0
	rjmp 21f
11:
	; x1 <= 0.5
	; compute x2 = 2 * x1 * x1
	; and put x1 = fabs(x) as factor on the stack
	XCALL _U(__fp64_pushA)		; save factor = x1 = fabs(x)
	push rAE1
	push rAE0

	XCALL _U(__fp64_muldf3_pse)
	;; Increasing the exponent by 1 doesn't work for 0 and subnormals.
	;; In these cases, x2 will be a very small, almost subnormal number.
	;; Since x2 is tiny, the rational function maps x2 to 1.0 + x2 = 1.0,
	;; and hence the algorithm works fine even though the ADIW doesn't.
	adiw rAE0, 1				; x2 = 2*x1*x1
	rjmp 12f

21:
	; x1 > 0.5
	; compute x2 = 1 - x
	; and put sqrt(2*x2) as factor on the stack
	mov rA7, r1					; A = 1.0
	ldi rA6, 0x80
	mov rA5, r1
	mov rA4, r1
	X_movw rA2, rA4
	X_movw rA0, rA4
	ldi rAE0, 0xff
	ldi rAE1, 0x03

	clt							; clear sign
	XCALL _U(__fp64_sub_pse)	; x2 = 1 - x1
	clt

	XCALL _U(__fp64_pushA)		; save x2 = 1 - x1
	push rAE1
	push rAE0

	;; We have x2 != 0 since the case acos(1.0) got extra treatment.
	;; And due to x2 = 1 - x1 it can never be subnormal.  Hence adding
	;; 1 to x2's exponent in order to multiply it by 2 works in all cases.
	adiw rAE0, 1				; 2*x2
	XCALL _U(__fp64_sqrt_pse)	; factor = sqrt(2*x2)

	pop rBE0					; retrieve x2
	pop rBE1
	XCALL _U(__fp64_popB)

	XCALL _U(__fp64_pushA)		; save factor = sqrt(2*x2)
	push rAE1
	push rAE0

	XCALL _U(__fp64_movABx)		; A = B = x2

12:
	; start polynom calculation
	; A: x2
	; B: undefined
	; stack: factor
	XCALL _U(__fp64_pushA)		; save x2
	push rAE1
	push rAE0

	LPMX_INIT XL, .L_tableAsinDenom	; calculate Denominator
	XCALL _U(__fp64_powser)
	;; LPMX_FINI pending...

	pop rBE0					; retrieve x2
	pop rBE1
	XCALL _U(__fp64_popB)

	XCALL _U(__fp64_pushA)		; save x3 = horner( x2, coeff_nenner )
	push rAE1
	push rAE0

	XCALL _U(__fp64_movABx)		; A = B = x3
	LPMX_INIT XL, .L_tableAsinNom	; calculate Nominator
	XCALL _U(__fp64_powser)		; res = horner( x2, coeff_zähler )
	LPMX_FINI r1

	pop rBE0					; retrieve Denominator x3 = horner( x2, coeff_nenner )
	pop rBE1
	XCALL _U(__fp64_popB)

	XCALL _U(__fp64_divdf3_pse) ; res = res / x3

	pop rBE0					; retrieve either x1 = fabs(x) or x1 = sqrt(2*fabs(x))
	pop rBE1
	XCALL _U(__fp64_popB)

	XCALL _U(__fp64_muldf3_pse) ; res = res / x3 * x1 or res = res / x3 * sqrt(2*fabs(x))

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
	bld rA7, 7					;	res = -res
	subi rA7, 0x80

19:
	pop YL						; restore the used callee-saved registers
	pop YH
	XCALL _U(__fp64_popBC)

	lds r0, __sinFlags			; retrieve sign(x)
	sbrs r0,1					; asin?
	bst r0, 7					; yes, return res*sign

.L_retA:
	XJMP _U(__fp64_rpretA)		; return res

23: ; handle acos  --> r0 bit 1 set
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
	XCALL _U(__fp64_add_pse)	; compute res + pi/2 or -res + pi
	rjmp 19b
ENDFUNC

PGMX_SECTION (fp64.asinx)

;;; Degree [5/4] rational MiniMax over [0, 0.5] for
;;;    a(x) = asin(q) / q;  q = sqrt(x/2)
;;; normalized to a monic numerator and rounded to nearest 56 bits.
;;; Quality > 20

OBJECT .L_tableAsinNom
	.byte 5 ; monic
	.byte C(+, 0x94,0x39,0x8c,0xf4,0xbb,0x52,0x93,  +7) ; +1.48224807067616502820e+02 = +0x9.4398cf4bb52920p+4
	.byte C(-, 0x9f,0xd4,0x40,0xc0,0x7f,0x8a,0x06, +12) ; -5.11453161716117824653e+03 = -0x1.3fa88180ff140cp+12
	.byte C(+, 0xa2,0xaf,0x56,0xfb,0x62,0x20,0xa3, +15) ; +4.16473397733049087037e+04 = +0xa.2af56fb6220a30p+12
	.byte C(-, 0xee,0x9a,0x38,0x4b,0x38,0x0d,0x0c, +16) ; -1.22164439795500155014e+05 = -0x1.dd347096701a18p+16
	.byte C(+, 0xe6,0x78,0x70,0xab,0xe1,0x5d,0x16, +16) ; +1.18000880245371296041e+05 = +0x1.ccf0e157c2ba2cp+16
ENDOBJ .L_tableAsinNom

OBJECT .L_tableAsinDenom
	.byte 4
	.byte C(+, 0xaa,0x17,0x20,0xd2,0x93,0x0b,0xec,  +8) ; +3.40180689164924700663e+02 = +0x1.542e41a52617d8p+8
	.byte C(-, 0xea,0x67,0x91,0x7a,0xc4,0x98,0xe8, +12) ; -7.50094603494254715770e+03 = -0x1.d4cf22f58931d0p+12
	.byte C(+, 0xc5,0x02,0xa4,0xd0,0xa9,0x94,0x59, +15) ; +5.04346438089358498473e+04 = +0xc.502a4d0a994590p+12
	.byte C(-, 0x80,0xe7,0x76,0x2c,0xc5,0x6a,0xa8, +17) ; -1.31997846482614666456e+05 = -0x2.039dd8b315aaa0p+16
	.byte C(+, 0xe6,0x78,0x70,0xab,0xe1,0x5d,0x16, +16) ; +1.18000880245371296041e+05 = +0x1.ccf0e157c2ba2cp+16
ENDOBJ .L_tableAsinDenom

NOINIT_SECTION
__sinFlags:	 .skip 1
