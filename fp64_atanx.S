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

/*	float64_t fp64_atan( float64_t phi )
	returns the arcus tangent of phi (inverse function to fp64_tan(x))

	Basic algorithm:
	fp64_atan (const f7_t *x) {
	  if( isNan(x) )
		return NaN

	  if( isInf(x) )
		return PI/2 * sign(x)

	  res = fabs(x)
	  if( res == 0.0 )
		  return 0.0 * sign(x)

	  if( res >= 1.0 )
		  // |x| >= 1:	use atan(x) + atan(1/x) = pi/2 to reduce argument to [0, 1].
		  flag = true
		  res = 1/x

	  x2 = x*x
	  y = horner( x2, coeff_denominator )
	  z = horner( x2, coeff_nominator )
	  res = z / y * res

	  if( flag )
		  // |x| >= 1, res = atan(1/x) --> atan(x) = pi/2 - res
		  res = pi/2 - res = -(res - pi/2)
	  return res*sign(x)
	}

*/
FUNCTION fp64_atan

	; case |   x     | atan(x)
	;------+---------+----------
	;  1   |  NaN    |   NaN
	;  2   | +/-Inf  | +/-PI/2
	;  3   | +/-0.0  | +/-0.0
	;  4   | |x|>1.0 | pi/2-atan(1/x)
	;  5   |  else   |  atan(x)

	; case 1: NaN
.L_nan:
	breq .L_inf
	XJMP _U(__fp64_nan)

	; case 2: +/-Inf --> return +/- PI/2
.L_inf:
	XJMP _U(__fp64_pi2)

	; case 2: 0 --> 0
.L_zero:
	XJMP _U(__fp64_szero)		; no: return 0.0 for asin

/*	float64_t fp64_atan( float64_t phi )
	returns the arcus tangens of phi (inverse function to fp64_tan(x))
*/
ENTRY fp64_atan
ENTRY_DOUBLE atan atanl
	XCALL _U(__fp64_splitA)
	brcs .L_nan					; NaN or +/- INF
	breq .L_zero				; x = 0 --> result of atan = 0

	push rA7					; save sign of x

	XCALL _U(__fp64_pushCB)		; save the used callee-saved regs
	push YH
	push YL

	cpi rAE1, 0x03				; fabs(x) < 1.0?
	brmi 10f					; definitely yes, x < 2^-255 --> go ahead with approximation
	brne 1f						; definitely no, x >= 2.0 --> calculate 1/x

	; maybe yes, 2^-255 < x < 2.0
	cpi rAE0, 0xff
	brlo 10f					; |x| < 1.0 --> go ahead with approximation

1:	; here: |x| >= 1.0
	; use atan(x) + atan(1/x) = pi/2 to reduce argument to [0, 1]
	; --> compute 1/x , which will be <= 1.0

	XCALL _U(__fp64_movBAx)		; B = |x|

	set
	XCALL _U(__fp64_szero)		; will return packed -0, which is nearly unpacked 1.0
	mov rA6, rA7
	clr rA7
	ldi rAE1, 0x03
	ldi rAE0, 0xff
	clt
	XCALL _U(__fp64_divdf3_pse) ; 1/|x|
	inc r1						; flag = true

10: ; here: A = |x| or 1/|x|
	push r1						; save flag
	clr r1
	clt

	XCALL _U(__fp64_movBAx)		; B = A = |x|

	XCALL _U(__fp64_pushA)		; save res = |x| (or 1/|x|)
	push rAE1
	push rAE0

	XCALL _U(__fp64_muldf3_pse) ; x2 = x^2

	XCALL _U(__fp64_pushA)		; save x2 = x^2
	push rAE1
	push rAE0

	LPMX_INIT XL, .L_tableAtanDenom	; calculate Denominator
	XCALL _U(__fp64_powser)
	;; LPMX_FINI pending...

	pop rBE0					; retrieve x2 = x^2
	pop rBE1
	XCALL _U(__fp64_popB)

	XCALL _U(__fp64_pushA)		; save y = horner( x2, coeff_denominator )
	push rAE1
	push rAE0

	XCALL _U(__fp64_movABx)		; A = B = x2

	LPMX_INIT XL, .L_tableAtanNom	; calculate Nominator
	XCALL _U(__fp64_powser)		; z = horner( x2, coeff_nominator )
	LPMX_FINI r1

	pop rBE0					; retrieve Denominator y = horner( x2, coeff_denominator )
	pop rBE1
	XCALL _U(__fp64_popB)

	XCALL _U(__fp64_divdf3_pse) ; res = z / y

	pop rBE0					; retrieve res = |x| or 1/|x|
	pop rBE1
	XCALL _U(__fp64_popB)

	XCALL _U(__fp64_muldf3_pse) ; res = z / y * res

	pop r0						; retrieve flag
	tst r0
	breq 19f

	; yes: adjust result to PI/2 - res
	XCALL _U(__fp64_ldb_pi2)
	XCALL _U(__fp64_sub_pse)	; compute res - PI/2
	bld rA7, 7					; res = -res --> res = PI/2 - res
	subi rA7, 0x80

19:
	pop YL						; restore all callee-saved regs
	pop YH
	XCALL _U(__fp64_popBC)		; restore register set

	pop r0						; retrieve sign(x)
	bst r0, 7					; yes, return res*sign

.L_retA:
	XJMP _U(__fp64_rpretA)		; return res
ENDFUNC

PGMX_SECTION (fp64.atanx)

	; approximation by MiniMax polynom, as discussed on
	; https://www.mikrocontroller.net/topic/480840#6003520

;;; Degree [6/6] rational MiniMax function with minimal relative error (pQ > 22) for
;;; A(x) = atan(sqrt(x)) / sqrt(x)  over [0, 1], i.e.
;;; atan(x) = x * A(x^2)  for x in [-1, 1]

OBJECT .L_tableAtanNom
	.byte 6
	.byte 0x00, 0xc8,0x18,0xb7,0x59,0xdc,0x25,0x88,  -5 ; +9.77033924387054192318e-02 = +0x1.90316eb3b84b10p-4
	.byte 0x00, 0xb5,0x04,0x3d,0xe9,0x95,0x90,0x69,  +2 ; +1.13135356068023844589e+01 = +0xb.5043de99590690p+0
	.byte 0x00, 0xc0,0x31,0xd4,0xc8,0xf4,0x98,0x2d,  +6 ; +1.92194653091159285196e+02 = +0xc.031d4c8f4982d0p+4
	.byte 0x00, 0x8a,0xd9,0xe0,0xde,0x54,0x6c,0x7e,  +9 ; +1.11080869976510069819e+03 = +0x4.56cf06f2a363f0p+8
	.byte 0x00, 0xab,0xf5,0x19,0xba,0xa8,0xa0,0x22, +10 ; +2.75131878152722686082e+03 = +0xa.bf519baa8a0220p+8
	.byte 0x00, 0xbc,0x9b,0xca,0x9c,0x99,0x3e,0x5b, +10 ; +3.01773696575032016653e+03 = +0xb.c9bca9c993e5b0p+8
	.byte 0x00, 0x96,0x79,0x81,0xa8,0xbb,0x9c,0x20,  +9 ; +1.20379707752840567991e+03 = +0x4.b3cc0d45dce100p+8
ENDOBJ .L_tableAtanNom

OBJECT .L_tableAtanDenom
	.byte 6 ; monic
	.byte 0x01, 0x9f,0x75,0xba,0x1a,0x49,0xca,0x64,  +4 ; +3.98649677379167748370e+01 = +0x2.7dd6e869272990p+4
	.byte 0x00, 0xd3,0x08,0x20,0x46,0x57,0x9a,0xb4,  +7 ; +4.22063484947944203896e+02 = +0x1.a610408caf3568p+8
	.byte 0x00, 0xe2,0xf7,0x16,0x68,0xa1,0xe2,0xd2,  +9 ; +1.81572148543947565713e+03 = +0x7.17b8b3450f1690p+8
	.byte 0x00, 0xe4,0x23,0xa1,0x75,0x94,0xda,0xf2, +10 ; +3.65022691877504905733e+03 = +0xe.423a17594daf20p+8
	.byte 0x00, 0xd5,0xb0,0x0a,0xe3,0x63,0x2d,0x80, +10 ; +3.41900265825978567591e+03 = +0xd.5b00ae3632d800p+8
	.byte 0x00, 0x96,0x79,0x81,0xa8,0xbb,0x9c,0x20,  +9 ; +1.20379707752840567991e+03 = +0x4.b3cc0d45dce100p+8
ENDOBJ .L_tableAtanDenom
