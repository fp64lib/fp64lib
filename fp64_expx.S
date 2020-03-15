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

#if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

/* float64_t fp64_exp (float64_t x);
     The fp64_exp() function returns the value of e (the base of natural
     logarithms) raised to the power of x.
 */
 
#define	X2BIG		0x0408
							; start of biggest argument
							; ((float64_t)0x40862E42FEFA39EFLLU), //709.78271289338397 res
							; exp(x) --> ((float64_t)0x7FEFFFFFFFFFFFFFLLU), //1.7976931348623E+308 x
 
FUNCTION fp64_exp

	; Special cases
	; case|	A	  |	log(A)
	;-----+-------+------
	; 1	  |	NaN	  |	NaN
	; 2	  |	+Inf  |	+Inf
	; 3	  |	-Inf  |	0
	; 4	  |	0	  |	1
	; 5   | >709  | +Inf (Overflow)
	; 6   | <-744 | 0 (Underflow)

.L_nf:	
	brne	.L_nan			; +/-Inf? No --> return NaN
.L_tb:
	brtc	.L_inf			; -Inf? No --> return +Inf
.L_zr:						; yes, case 3 --> return 0
	XJMP	_U(__fp64_zero)

.L_nan:	; x = NaN, case 1 --> return NaN
	XJMP	_U(__fp64_nan)
	
.L_one:
	XCALL _U(__fp64_zero)
	ldi rA7, 0x3f			; return 1
	ldi rA6, 0xf0
	ret

ENTRY fp64_exp
GCC_ENTRY __exp
	; split and analyse A
	XCALL	_U(__fp64_splitA)
	; rcall __fp64_saveA
	brcs .L_nf			; A is not a finite number
	breq .L_one

	cpi rAE1, hi8(X2BIG)
	brlo 1f				; exponent lower --> all ok
	brne .L_tb			; exponent to big --> return +Inf
	cpi rAE0, lo8(X2BIG)
	brlo 1f				; exponent lower --> all ok
	brne .L_tb			; exponent to big --> return +Inf
	; exponent exactly on boundary
	; check mantissa?
	brts 0f
	rjmp 1f

.L_inf:
	XJMP	_U(__fp64_inf)	; No, case 2 --> return Inf

0:	; check for negative numbers


1:	; x is in valid range
	XCALL _U(__fp64_pushCB) ; preserve register set
	bld r0, 7				; save sign of x
	push r0

	
	; calculate fmod(x,ln(2)) = x - n*ln(2)
	XCALL _U(__fp64_fmodx_ln2_pse)
	; rcall __fp64_saveABC
	; now we got:
	; rA7..rA0 rAE1.rAE0	y = fmod(x,ln(2))
	; rC7..rC4				n
	push rC4				; save n (only lower 12bits are needed)
	push rC5

	; now calculate exp(y) via taylor approximation
	; exp(x) = 2^n * exp(x-n*ln(2))

	push YL
	push YH
	ldi XL, lo8(.L_expxTable)
	ldi XH, hi8(.L_expxTable)
	XCALL	_U(__fp64_powser)
	pop YH
	pop YL
	pop rBE1				; load n into B
	pop rBE0


	pop r0
	bst r0, 7				; restore saved sign of x
	; rcall __fp64_saveABC
	XCALL _U(__fp64_popBC)	; restore register set
	
	; multiply result by 2^n --> add n to exponent
	; rcall __fp64_saveAB
	brts 2f				; if x < 0, subtract n from exponent

	add rAE0, rBE0		; else add n to exponent
	adc rAE1, rBE1
	; check for various overflow conditions
	; rcall __fp64_saveAB
	cpi rAE1, 0x8
	brsh .L_inf		; exponent > 0x7ff --> overflow
	brne .L_retA	; exponent < 0x700 --> normal case, return A
	cpi rAE0, 0xff
	brne .L_inf		; exponent == 0x7ff --> overflow
	
	; normal case, return A
.L_retA:
	clt
	XJMP _U(__fp64_rpretA);
	
2:	sub rAE0, rBE0		; subtract n from exponent
	sbc rAE1, rBE1
	; rcall __fp64_saveAB
	; check for various underflow conditions
	brmi 22f		; exponent < 0 --> check range for underflow
	rjmp .L_retA
	
	brne .L_retA	; exponent > 0 --> normal case, return A
	; exponent == 0, check for 0
	XCALL _U(__fp64_cpc0A5)	; C = 1 if one of Ax > 0
	cpc	r1, rA6		; C = 1, if A is not a zero
	brcc .L_retA	; A == 0 --> return A
	; A != 0, exponent == 0 --> only one shift is needed to return A as subnormal
	XCALL _U(__fp64_lsrA)
	rjmp .L_retA
	
	; exponent <= 0, check if in range for subnormal number
22:	cpi rAE1, hi8(-53)
	brne 6f			; exponent < -255 --> underflow, return 0
	cpi rAE0, lo8(-53)
	brlo 6f			; exponent < -53 --> underflow, return 0
	
3:	; subnormal number, exponent between 0 and -53
	; shift significand to right until exponent is 0
	
	
4:	cpi rAE0, -8			; can we fast shift by 8 bits = 1 byte?
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
	XCALL _U(__fp64_lsrA)	; A >>= 1
	adiw rAE0, 1
	brmi 5b					; until exponent > 0
	rjmp .L_retA			; return subnormal number

6:	; real underflow, return 0
	rjmp .L_zr

ENTRY __fp64_check_powserexp
#ifndef CHECK_POWSER
	ret
#else
	push XL
	push XH
	ldi XL, lo8(.L_expxTable)
	ldi XH, hi8(.L_expxTable)
	XJMP _U(__fp64_check_powsern)
#endif

	; exp is calculated by Taylor Approximation
	; exp(x) ~ SUM(n = 1 to 16; x^n/n! ) = 1/0!*1 + 1/1!*x + 1/2!*x^2 + 1/3!*x^3 + ... + 1/16!*x^16
	; the coefficients were computed with python with 40 (decimal) digits precision
	; and then rounded to 56 Bits
	; 0xd73f9f399dc0f9p-116  = Decimal(0xd73f9f399dc0f9) / 2**116 
.L_expxTable:
	.byte 16	; polynom power = 16 --> 17 entries
	;     rB7   rB6   rB5   rB4   rB3   rB2   rB1   rB0   rBE1  rBE0
														; C16 = 1/16! = 1/20.922.789.888.000 = 4.779477332387385297438207491117544027596E-14
	.byte 0x00, 0xd7, 0x3f, 0x9f, 0x39, 0x9d, 0xc0, 0xf9, 0x03, 0xd2 ; 0xd73f9f399dc0f9p-116 = 4.779477332387385332332243154877912051364E-14
														; C15 = 1/15! = 1/1.307.674.368.000  = 7.647163731819816475901131985788070444153E-13
	.byte 0x00, 0xd7, 0x3f, 0x9f, 0x39, 0x9d, 0xc0, 0xf9, 0x03, 0xd6 ; 0xd73f9f399dc0f9p-112 = 7.647163731819816531731589047804659282182E-13
														; C14 = 1/14! = 1/87.178.291.200     = 1.147074559772972471385169797868210566623E-11
	.byte 0x00, 0xc9, 0xcb, 0xa5, 0x46, 0x03, 0xe4, 0xe9, 0x03, 0xda ; 0xc9cba54603e4e9p-108 = 1.147074559772972470924496218695366671716E-11
														; C13 = 1/13! = 1/6.227.020.800      = 1.605904383682161459939237717015494793272E-10
	.byte 0x00, 0xb0, 0x92, 0x30, 0x9d, 0x43, 0x68, 0x4c, 0x03, 0xde ; 0xb092309d43684cp-104 = 1.605904383682161463333262540905093784110E-10
														; C12 = 1/12! = 1/479.001.600        = 2.087675698786809897921009032120143231254E-9
	.byte 0x00, 0x8f, 0x76, 0xc7, 0x7f, 0xc6, 0xc4, 0xbe, 0x03, 0xe2 ; 0x8f76c77fc6c4bep-100 = 2.087675698786809915257938374317679339209E-9
														; C11 = 1/11! = 1/39.916.800         = 2.505210838544171877505210838544171877505E-8
	.byte 0x00, 0xd7, 0x32, 0x2b, 0x3f, 0xaa, 0x27, 0x1c, 0x03, 0xe5 ; 0xd7322b3faa271cp-97  = 2.505210838544171856950495421529831463481E-8
														; C10 = 1/10! = 1/3.628.800          = 2.755731922398589065255731922398589065256E-7
	.byte 0x00, 0x93, 0xf2, 0x7d, 0xbb, 0xc4, 0xfa, 0xe4, 0x03, 0xe9 ; 0x93f27dbbc4fae4p-93  = 2.755731922398589092276381716864475102113E-7
														; C9  = 1/9!  = 1/362.880            = 0.000002755731922398589065255731922398589065256
	.byte 0x00, 0xb8, 0xef, 0x1d, 0x2a, 0xb6, 0x39, 0x9c, 0x03, 0xec ; 0xb8ef1d2ab6399cp-90  = 0.000002755731922398589039336822513470703910343
														; C8  = 1/8!  = 1/40.320             = 0.0000248015873015873015873015873015873015873
	.byte 0x00, 0xd0, 0x0d, 0x00, 0xd0, 0x0d, 0x00, 0xd0, 0x03, 0xef ; 0xd00d00d00d00d0p-87  = 0.00002480158730158730156578963943481141996017
														; C7  = 1/7!  = 1/5.040              = 0.0001984126984126984126984126984126984126984
	.byte 0x00, 0xd0, 0x0d, 0x00, 0xd0, 0x0d, 0x00, 0xd0, 0x03, 0xf2 ; 0xd00d00d00d00d0p-84  = 0.0001984126984126984125263171154784913596814
														; C6  = 1/6!  = 1/720                = 0.001388888888888888888888888888888888888889
	.byte 0x00, 0xb6, 0x0b, 0x60, 0xb6, 0x0b, 0x60, 0xb6, 0x03, 0xf5 ; 0xb60b60b60b60b6p-81  = 0.001388888888888888887684219808349439517769
														; C5  = 1/5!  = 1/120                = 0.008333333333333333333333333333333333333336
	.byte 0x00, 0x88, 0x88, 0x88, 0x88, 0x88, 0x88, 0x89, 0x03, 0xf8 ; 0x88888888888889p-78  = 0.008333333333333333434525536098647080507362
														; C4  = 1/4!  = 1/24                 = 0.04166666666666666666666666666666666666668
	.byte 0x00, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xab, 0x03, 0xfa ; 0xaaaaaaaaaaaaabp-76  = 0.04166666666666666695578724599613451573532
														; C3  = 1/3!  = 1/6                  = 0.1666666666666666666666666666666666666667
	.byte 0x00, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xab, 0x03, 0xfc ; 0xaaaaaaaaaaaaabp-74  = 0.1666666666666666678231489839845380629413
														; C2 = 1/2!  = 1/2                   = 0.5
	.byte 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xfe ; 0x80000000000000p-72  = 0.5
														; C1 = 1/1!  = 1/1                   = 1.0
	.byte 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xff ; 0x80000000000000p-71  = 1.0
														; C0 = 1/0!  = 1/1                   = 1.0
	.byte 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xff ; 0x80000000000000p-71  = 1.0

	.byte 0x00												; byte needed for code alignment to even adresses!
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
