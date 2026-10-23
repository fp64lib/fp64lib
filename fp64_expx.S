/* Copyright (c) 2019-2026  Uwe Bissinger
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

/* float64_t fp64_exp (float64_t x);
	 The fp64_exp() function returns the value of e (the base of natural
	 logarithms) raised to the power of x.
 */

#define X2BIG		0x0408
								; start of biggest argument
								; ((float64_t)0x40862E42FEFA39EFLLU), //709.78271289338397 res
								; exp(x) --> ((float64_t)0x7FEFFFFFFFFFFFFFLLU), //1.7976931348623E+308 x

FUNCTION fp64_exp

	; Special cases
	; case| A	  | log(A)
	;-----+-------+------
	; 1	  | NaN	  | NaN
	; 2	  | +Inf  | +Inf
	; 3	  | -Inf  | 0
	; 4	  | 0	  | 1
	; 5	  | >709  | +Inf (Overflow)
	; 6	  | <-744 | 0 (Underflow)

.L_nf:
	brne	.L_nan				; +/-Inf? No --> return NaN
.L_tb:
	brtc	.L_inf				; -Inf? No --> return +Inf
.L_zr:							; yes, case 3 --> return 0
	XJMP	_U(__fp64_zero)

.L_nan: ; x = NaN, case 1 --> return NaN
	XJMP	_U(__fp64_nan)

.L_one:
	XCALL _U(__fp64_zero)
	ldi rA7, 0x3f				; return 1
	ldi rA6, 0xf0
	ret

ENTRY fp64_exp
ENTRY_DOUBLE exp expl
	; split and analyse A
	XCALL	_U(__fp64_splitA)
	; rcall __fp64_saveA
	brcs .L_nf					; A is not a finite number
	breq .L_one

	cpi rAE1, hi8(X2BIG)
	brlo 1f						; exponent lower --> all ok
	brne .L_tb					; exponent to big --> return +Inf
	cpi rAE0, lo8(X2BIG)
	brlo 1f						; exponent lower --> all ok
	brne .L_tb					; exponent to big --> return +Inf
	; exponent exactly on boundary
	; check mantissa?
	brts 0f
	rjmp 1f

.L_inf:
	XJMP	_U(__fp64_inf)		; No, case 2 --> return Inf

0:	; check for negative numbers


1:	; x is in valid range
	XCALL _U(__fp64_pushCB)		; preserve register set
	bld r0, 7					; save sign of x
	push r0


	; calculate fmod(x,ln(2)) = x - n*ln(2)
	XCALL _U(__fp64_fmodx_ln2_pse)
	; now we got:
	; rA7..rA0 rAE1.rAE0	y = fmod(x,ln(2))
	; rC7..rC4				n
	push rC4					; save n (only lower 12bits are needed)
	push rC5

	; now calculate exp(y) via taylor approximation
	; exp(x) = 2^n * exp(x-n*ln(2))

	push YL
	push YH
	LPMX_INIT XL, .L_expxTable
	XCALL	_U(__fp64_powser)
	LPMX_FINI r1
	pop YH
	pop YL
	pop rBE1					; load n into B
	pop rBE0


	pop r0
	bst r0, 7					; restore saved sign of x
	XCALL _U(__fp64_popBC)		; restore register set

	; multiply result by 2^n --> add n to exponent
	brts 2f						; if x < 0, subtract n from exponent

	add rAE0, rBE0				; else add n to exponent
	adc rAE1, rBE1
	; check for various overflow conditions
	cpi rAE1, 0x8
	brsh .L_inf					; exponent > 0x7ff --> overflow
	brne .L_retA				; exponent < 0x700 --> normal case, return A
	cpi rAE0, 0xff
	brne .L_inf					; exponent == 0x7ff --> overflow

	; normal case, return A
.L_retA:
	clt
	XJMP _U(__fp64_rpretA);

2:	sub rAE0, rBE0				; subtract n from exponent
	sbc rAE1, rBE1
	; check for various underflow conditions
	brmi 22f					; exponent < 0 --> check range for underflow
	rjmp .L_retA

	brne .L_retA				; exponent > 0 --> normal case, return A

	; exponent == 0, check for 0
	XCALL _U(__fp64_cpc0A5)		; C = 1 if one of Ax > 0
	cpc r1, rA6					; C = 1, if A is not a zero
	brcc .L_retA				; A == 0 --> return A
	; A != 0, exponent == 0 --> only one shift is needed to return A as subnormal
	XCALL _U(__fp64_lsrA)
	rjmp .L_retA

	; exponent <= 0, check if in range for subnormal number
22: cpi rAE1, hi8(-53)
	brne 6f						; exponent < -255 --> underflow, return 0
	cpi rAE0, lo8(-53)
	brlo 6f						; exponent < -53 --> underflow, return 0

3:	; subnormal number, exponent between 0 and -53
	; shift significand to right until exponent is 0


4:	cpi rAE0, -8				; can we fast shift by 8 bits = 1 byte?
	brsh 5f
	mov rA0, rA1
	mov rA1, rA2
	mov rA2, rA3
	mov rA3, rA4
	mov rA4, rA5
	mov rA5, rA6
	mov rA6, rA7
	subi rAE0, -8
	rjmp 4b

5:	tst rAE0
	breq 6f

	; shift 1 bit at a time
	XCALL _U(__fp64_lsrA)		; A >>= 1
	adiw rAE0, 1
	brmi 5b						; until exponent > 0
	rjmp .L_retA				; return subnormal number

6:	; real underflow, return 0
	rjmp .L_zr

ENTRY __fp64_check_powserexp
#ifndef CHECK_POWSER
	ret
#else
	push XL
	push XH
	LPMX_INIT XL, .L_expxTable
	XJMP _U(__fp64_check_powsern)
#endif
ENDFUNC

PGMX_SECTION (fp64.expx)

OBJECT .L_expxTable
	;; The MiniMax polynomial of degree 13 for exp over [-ln2, ln2]
	;; rounded to nearest 56 bits.
    ;;    rB7   rB6  rB5  rB4  rB3  rB2  rB1  rB0   rBE1 rBE0
	.byte 13
	.byte 0x00, 0xaf,0x29,0x99,0x39,0x10,0x4f,0x14, 0x03,0xde ; +1.5930936046605759305e-10 = +0xa.f299939104f140p-36
	.byte 0x00, 0x90,0xc6,0x27,0x16,0x89,0x77,0x03, 0x03,0xe2 ; +2.1067394691065661211e-09 = +0x9.0c627168977030p-32
	.byte 0x00, 0xd7,0x39,0x11,0xfa,0xcd,0x07,0xc8, 0x03,0xe5 ; +2.5055246730138619349e-08 = +0x6.b9c88fd6683e40p-28
	.byte 0x00, 0x93,0xf0,0xca,0x65,0xdd,0x7d,0xfa, 0x03,0xe9 ; +2.7556081925896908078e-07 = +0x4.9f86532eebefd0p-24
	.byte 0x00, 0xb8,0xef,0x13,0xed,0xa1,0x4d,0xf1, 0x03,0xec ; +2.7557298217840436130e-06 = +0x2.e3bc4fb68537c4p-20
	.byte 0x00, 0xd0,0x0d,0x02,0xfd,0xc2,0x6e,0x51, 0x03,0xef ; +2.4801591264345971373e-05 = +0x1.a01a05fb84dca2p-16
	.byte 0x00, 0xd0,0x0d,0x00,0xdb,0x30,0x7f,0xad, 0x03,0xf2 ; +1.9841269904585761752e-04 = +0xd.00d00db307fad0p-16
	.byte 0x00, 0xb6,0x0b,0x60,0xb4,0x9e,0xc9,0x0b, 0x03,0xf5 ; +1.3888888882412425902e-03 = +0x5.b05b05a4f64858p-12
	.byte 0x00, 0x88,0x88,0x88,0x88,0x82,0x2a,0x0d, 0x03,0xf8 ; +8.3333333332428233698e-03 = +0x2.2222222208a834p-8
	.byte 0x00, 0xaa,0xaa,0xaa,0xaa,0xab,0x8b,0xd1, 0x03,0xfa ; +4.1666666666716659952e-02 = +0xa.aaaaaaaab8bd10p-8
	.byte 0x00, 0xaa,0xaa,0xaa,0xaa,0xaa,0xb0,0xd3, 0x03,0xfc ; +1.6666666666667213567e-01 = +0x2.aaaaaaaaaac34cp-4
	.byte 0x00, 0xff,0xff,0xff,0xff,0xff,0xff,0x32, 0x03,0xfd ; +4.9999999999999857059e-01 = +0x7.fffffffffff990p-4
	.byte 0x00, 0xff,0xff,0xff,0xff,0xff,0xff,0xf9, 0x03,0xfe ; +9.9999999999999990286e-01 = +0xf.ffffffffffff90p-4
	.byte 0x00, 0x80,0x00,0x00,0x00,0x00,0x00,0x00, 0x03,0xff ; +1.0000000000000000000e+00 = +0x1.00000000000000p+0
ENDOBJ .L_expxTable
