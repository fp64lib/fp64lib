/* Copyright (c) 2018-2020  Uwe Bissinger
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

.require_lpmx

/*	float64_t fp64_cos( float64_t phi )
	returns the cosine of phi
*/

ENTRY fp64_sin
ENTRY_DOUBLE sin sinl
	ldi XL, 0
	rjmp .L_sincos

/*	float64_t fp64_sin( float64_t phi )
	returns the sine of phi
*/

ENTRY fp64_cos
ENTRY_DOUBLE cos cosl
	ldi XL, 1
.L_sincos:
	XCALL _U(__fp64_splitA)
	brcc 1f
	XJMP _U(__fp64_nan)			; A is not finite --> NaN

1:	XCALL _U(__fp64_pushCB)
	push YL
	push YH

	;; flags:
	;; .0 = do cos
	;; .1 = flip x prior to sin
	;; .7 = sign(input)
	bld	XL, 7					; flags.7 = sign(x)
	cbr rA7, 0x80				; x := |x|
	push XL						; store flags

	XCALL _U(__fp64_movCA)		; keep |x| in CX
	X_movw YL, rAE0

	/* We use the following algorithm for argument reduction to [-pi/2, pi/2]

	   sign_x := sign(x)
	   x := |x|

	   q := x div pi/2

	   IF do_cos
		  q := q BITOR 1                    # increment q if q is even
		  flip := 1 XOR q.1
	   ELSE
		  q := (q + 1) BITAND ~1;           # increment q if q is odd
		  flip := sign_x XOR q.1

	   # Synthesize a high precision subtraction of q * pi/2 to
	   # facilitate a reduction mudulo pi in the remainder system
	   # of smallest absolute values.
	   x := x - q * pi/2.hi
	   x := x - q * pi/2.lo

	   IF flip
		  sign(x) := NOT sign(x)

	   # Now x is in the range [-pi/2, pi/2].  sin is approximated
	   # by the degree 8 MiniMax polynomial with minimal relative error
	   # of S(x) := sin(sqrt(x)) / sqrt(x)  over  [0, pi^2 / 4], i.e.
	   # sin(x) = x * S(x^2)  with  x in [-pi/2, pi/2].

	   return sin (x)
	*/

	rcall .L_div_pi2			; R22[4] := |x| div pi/2

	pop r18						; flags
	sbrs r18, 0					; sin or cos?
	rjmp .L_flags_sin
.L_flags_cos:
	sbr r18, 1 << 1				; cos: flip = 1
	sbr rA4, 1 << 0				;      ++quot if quot is even
	rjmp 20f
.L_flags_sin:
	bst r18, 7
	bld	r18, 1					; sin: flip = sign_x
	sbrs rA4, 0					;      ++quot if quot is odd
	rjmp 20f
	subi rA4, lo8(-1)
	sbci rA5, hi8(-1)
	sbci rA6, hlo8(-1)
	sbci rA7, hhi8(-1)
20:
	sbrc rA4, 1					; flip ^= q.1
	subi r18, -(1 << 1)			; flags.2 is zero and unused, so SBCI is an EOR
	push r18					; flags

	XCALL _U(fp64_uint32_to_float64) ; A = (double) (uint32_t) A[4..7]
	XCALL _U(__fp64_splitA)		; unpack to get AX; there's no overflow

	XCALL _U(__fp64_pushA)		; push quotient as double
	push rAE0
	push rAE1

	rcall .Ldb_pi2_hi
	rcall .L_sub_C_AB			; AX := CX := CX - AX * BX = X - quot * pi2_hi

	pop	rAE1					; restore quotient to AX
	pop	rAE0
	XCALL _U(__fp64_popA)

	rcall .Ldb_pi2_lo
	rcall .L_sub_C_AB			; AX := CX := CX - AX * BX = X - quot * pi2_lo

	pop r0						; flags
	sbrc r0, 1					; flip sign?
	subi rA7, 0x80				; yes
	bst rA7, 7					; T = sign

	LPMX_INIT XL, .L_sin		; S(x) = sin(sqrt(x)) / sqrt(x)
	XCALL _U(__fp64_powsodd)	; packed result (overflow C = 1) doesn't occur

	pop YH
	pop YL
	XCALL _U(__fp64_popBC)
	XJMP  _U(__fp64_rpretA)

;;; AX := CX := CX - AX * BX
.L_sub_C_AB:
	XCALL _U(__fp64_muldf3_pse_pushpop5)

	XCALL _U(__fp64_movBC)
	X_movw rBE0, YL

	sbr rA7, 0x80				; subtract the always positive product
	mov	r0, rA7					; sequence always required prior to addition
	eor r0, rB7
	bst r0, 7					; addition needs T = sign(A^B)
	XCALL _U(__fp64_add_pse)
	bld rA7, 7

	X_movw YL, rAE0
	XJMP _U(__fp64_movCA)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Divide AX by pi/2 and return the uint32_t result in R22[4] = A[4..7]

;;; Vanilla division is painstakingly slow, though in practice the inputs
;;; of sine and cosine are small values within a few periods of sine.
;;;   To that end, a small lookup table is provided that holds integral
;;; multiples of pi/2 from pi/2 up to 10 * pi/2 that allows for a fast
;;; quotient determination for values up to around 15.7 which saves more
;;; than 3000 cycles for such arguments.

.L_div_pi2:
	XCALL _U(__fp64_movBAx)

	LPMX_INIT ZL, .L_n_pi2

	ldi	rA3, 3					; expo.hi starts with expo.hi(pi/2) = 3
	clr rA4						; clear the uint32_t result quot
	clr rA5
	X_movw rA6, rA4
.Loop:
	LPMX rA1, Z+				; mant.hi
	tst  rA1					; table exhausted?
	breq .L_divide				; yes: goto the painfully slow vanilla division
	LPMX rA2, Z+				; expo.lo

	cp  rA1, rB6				; n * pi/2 ≥ X ?  compare mant.hi
	cpc rA2, rBE0				;                         expo.lo
	cpc rA3, rBE1				;                         expo.hi
	brsh .L_small_quot			; yes: rA4 equals x div pi/2

	ldi rA3, 4					; from now on we have expo.hi(n * pi/2) = 4
	inc rA4						; ++n
	rjmp .Loop

.L_small_quot:
	LPMX_FINI r1				; finalize LPMX
	ret

.L_divide:
	;; Vanilla division by pi/2 and quotient truncation to uint32_t A[4..7].
	LPMX_FINI r1				; finalize LPMX
	XCALL _U(__fp64_movABx)		; restore dividend
	rcall .Ldb_pi2_hi			; divisor is pi/2
	XCALL _U(__fp64_divdf3_pse)	; overflow (C = 1) doesn't occur

	push rBE0					; convert to uint32_t
	ldi rBE0, 32
	XJMP _U(__fp64_fixxdfxi_pse) ; A[4..7] = (uint32_t) AX

.Ldb_pi2_hi:
	push ZL
	push ZH
	LPMX_INIT ZL, .L_pi2_hi
	XJMP _U(__fp64_ldb_const)

.Ldb_pi2_lo:
	push ZL
	push ZH
	LPMX_INIT ZL, .L_pi2_lo
	XJMP _U(__fp64_ldb_const)
ENDFUNC


PGMX_SECTION (fp64.sinx)

OBJECT .L_sin
	;; Degree 8 MiniMax polynomial with minimal relative error of
	;; S(x) := sin(sqrt(x)) / sqrt(x)  over  [0, pi^2 / 4], i.e.
	;; sin(x) ≈ x * S(x^2)  for  x in [-pi/2, pi/2]
	.byte 8
	.byte C(+, 0xc4,0x1c,0x76,0xc4,0x2b,0x03,0x08, -49) ; +2.72158944311143609507e-15 = +0xc.41c76c42b03090p-52
	.byte C(-, 0xd7,0x21,0xd2,0x20,0x60,0xa8,0x9c, -41) ; -7.64302798918794397794e-13 = -0xd.721d22060a89c0p-44
	.byte C(+, 0xb0,0x91,0xe6,0x77,0x63,0x86,0xc4, -33) ; +1.60589409358735707078e-10 = +0xb.091e6776386c40p-36
	.byte C(-, 0xd7,0x32,0x2a,0x68,0x67,0x4e,0xd2, -26) ; -2.50521068917676951496e-08 = -0x6.b99153433a7690p-28
	.byte C(+, 0xb8,0xef,0x1d,0x29,0x46,0xf3,0x1c, -19) ; +2.75573192112434655481e-06 = +0x2.e3bc74a51bcc70p-20
	.byte C(-, 0xd0,0x0d,0x00,0xd0,0x0a,0x40,0x9f, -13) ; -1.98412698412087623844e-04 = -0xd.00d00d00a409f0p-16
	.byte C(+, 0x88,0x88,0x88,0x88,0x88,0x85,0xe4,  -7) ; +8.33333333333318663355e-03 = +0x2.22222222221790p-8
	.byte C(-, 0xaa,0xaa,0xaa,0xaa,0xaa,0xaa,0xa7,  -3) ; -1.66666666666666653945e-01 = -0x2.aaaaaaaaaaaa9cp-4
	.byte C(+, 0x80,0x00,0x00,0x00,0x00,0x00,0x00,  +0) ; +1.00000000000000000000e+00 = +0x1.00000000000000p+0
ENDOBJ .L_sin

OBJECT .L_n_pi2
	;; Integral multiples of pi/2 truncated to 8 expanded mantissa bits
	;; where only the low byte of the exponent is stored.
	.byte 0xc9, /*0x03,*/0xff ; 1 * pi/2 = +1.57079632679489661351e+00
	.byte 0xc9, /*0x04,*/0x00 ; 2 * pi/2 = +3.14159265358979322702e+00
	.byte 0x96, /*0x04,*/0x01 ; 3 * pi/2 = +4.71238898038468989604e+00
	.byte 0xc9, /*0x04,*/0x01 ; 4 * pi/2 = +6.28318530717958645404e+00
	.byte 0xfb, /*0x04,*/0x01 ; 5 * pi/2 = +7.85398163397448312306e+00
	.byte 0x96, /*0x04,*/0x02 ; 6 * pi/2 = +9.42477796076937979208e+00
	.byte 0xaf, /*0x04,*/0x02 ; 7 * pi/2 = +1.09955742875642763501e+01
	.byte 0xc9, /*0x04,*/0x02 ; 8 * pi/2 = +1.25663706143591729081e+01
	.byte 0xe2, /*0x04,*/0x02 ; 9 * pi/2 = +1.41371669411540694661e+01
	.byte 0xfb, /*0x04,*/0x02 ; 10 * pi/2 = +1.57079632679489662461e+01
	.byte 0 ; end of table
ENDOBJ .L_n_pi2

OBJECT .L_pi2_hi
	;; π/2 truncated to 48 MSBs
	.byte 0x00, 0xc9,0x0f,0xda,0xa2,0x21,0x68,0x00, 0x03,0xff ; +1.57079632679489122893e+00 = +0x1.921fb54442d000p+0
ENDOBJ .L_pi2_hi

OBJECT .L_pi2_lo
	;; π/2 - pi2_hi
	.byte 0x00, 0xc2,0x34,0xc4,0xc6,0x62,0x8b,0x81, 0x03,0xcf ; +5.39030285815811906672e-15 = +0x1.8469898cc51702p-48
ENDOBJ .L_pi2_lo
