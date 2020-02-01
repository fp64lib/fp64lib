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
 
Größtes Argument:  	((float64_t)0x40862E42FEFA39EFLLU), //709.78271289338397 res
				--> ((float64_t)0x7FEFFFFFFFFFFFFFLLU), //1.7976931348623E+308 x
Kleinstes Argument:	((float64_t)0xC086232BDD7ABCD2LLU), //-708.39641853226408 res
				--> ((float64_t)0x0010000000000000LLU), //2.2250738585072E-308 x
mit subnormal:		((float64_t)0xC0874046DFEFD9D0LLU), //-744.03460681327306 res
				--> ((float64_t)0x0000000000000001LLU), //0 x
Mit subnormal kann nicht Ansatz mit 1/x genutzt werden, da x nicht darstellbar ist.
Lösung1: Statt 1/x wird 1 durch 2^(exponent differenz) ersetzt und x auf 2^1023 begrenzt
Lösung2: Es wird zuerst 1/x berechnet mit x reduziert auf 2^1023 und danach wird subnormal erzeugt
Lösung3: keine Unetrstützung subnormals (ist keine Lösung)

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
	brts	.L_zr			; -Inf?
.L_inf:
	XJMP	_U(__fp64_inf)	; No, case 2 --> return Inf

.L_zr:						; yes, case 3 --> return 0
	XJMP	_U(__fp64_zero)

.L_nan:	; x = NaN, case 1 --> return NaN
	XJMP	_U(__fp64_nan)

ENTRY fp64_exp
	; split and analyse A
	XCALL	_U(__fp64_splitA)
	; rcall __fp64_saveA
	brcs	.L_nf		; A is not a finite number

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

0:	; check for negative numbers


1:	; x is in valid range
	; todo check for 1.0
	push rC7			; save used registers
	push rC6
	push rC5
	push rC4
	push rC3
	push rC2
	push rC1
	push rC0
	push rB7
	push rB6
	push rB5
	push rB4
	push rB3
	push rB2
	push rB1
	push rB0
	
	; calculate fmod(x,ln(2)) = x - n*ln(2)
	push ZL
	push ZH
	ldi ZL, lo8(.L_ln2)
	ldi ZH, hi8(.L_ln2)
	lpm rB7, Z+
	lpm rB6, Z+
	lpm rB5, Z+
	lpm rB4, Z+
	lpm rB3, Z+
	lpm rB2, Z+
	lpm rB1, Z+
	lpm rB0, Z+	
	lpm rC1, Z+		; load exponent into C0/C1
	lpm rC0, Z+
	pop ZH
	pop ZL
	movw rBE0, rC0
	bld rC3, 7		; save sign of x
	;rcall __fp64_saveAB
	XCALL _U(__fp64_fmod_pse)
	; now we got:
	; rA7..rA0 rAE1.rAE0	y = fmod(x,ln(2))
	; rC7..rC4				n

	; now calculate exp(y) via taylor approximation
	; exp(x) = 2^n * exp(x-n*ln(2))
	XCALL _U(__fp64_rpretA)	; pack A into float64_t format

	ldi ZL, lo8(.L_expTable)
	ldi ZH, hi8(.L_expTable)
	XCALL	_U(__fp64_powser)
	
	pop rB0				; restore used registers part1
	pop rB1
	pop rB2
	pop rB3
	pop rB4
	pop rB5
	pop rB6
	pop rB7
	
	bst rC3, 7			; save sign of x
	movw XL, rC4		; save n (only lower 12bits are needed)
	
	pop rC0				; restore used registers part 2
	pop rC1
	pop rC2
	pop rC3
	pop rC4
	pop rC5
	pop rC6
	pop rC7
	
	; multiply result by 2^n --> add n to exponent
	lsl XL			; align n to packed exponent
	rol XH
	lsl XL
	rol XH
	lsl XL
	rol XH
	lsl XL
	rol XH
	brts 2f			; if x < 0, subtract n from exponent

	add rA6, XL		; else add n to exponent
	adc rA7, XH
	; check for various overflow conditions
	; rcall __fp64_saveAB
	brcs 8f			; if overflow return +INF
	brmi 8f			; overflow, exponent > 0x7ff
	cpi rA7, 0x7f	; exponent = 0x7ff --> overflow
	brlo 9f
	cpi rA6, 0xf0	
	brlo 9f
8:	rjmp .L_inf		; overflow, return +INF
9:	ret
	
2:	sub rA6, XL		; subtract n from exponent
	sbc rA7, XH
	; rcall __fp64_saveAB
	; check for various underflow conditions
	tst rA7
	brmi 22f		; exponent < 0 --> check range
	brne 9b			; exponent > 0 --> normal number return
	cpi rA6, 0x10	; top byte of exponent is 0, what about lower 4 bits
	brsh 9b			; exponent >= 0x001 --> normal number, return
	rjmp 3f			; exponent is 0 --> subnormal number

	; exponent < 0, check if in range for subnormal number
22:	cpi rA7, hi8(-53 << 4)
	brlo 6f			; exponent < -53 --> underflow
	brne 3f
	cpi rA6, lo8(-53 << 4)
	brlo 6f
	
3:	; subnormal number, exponent between 0 and -53
	; shift significand to right until exponent is 0
	mov XL, rA6	
	andi XL, 0xf0
	swap XL
	mov XH, rA7
	andi XH, 0x0f
	swap XH
	or XL, XH			; XL now contains the lower 8 bits of the exponent
	
	clr rA7				; clear exponent in A
	andi rA6, 0x0f
	ori rA6, 0x10		; add hidden bit to significand

	; rcall __fp64_saveAB
	
	tst XL
	breq 5f
	
4:	cpi XL, -8			; can we fast shift by 8 bits = 1 byte?
	brsh 5f
	mov rA0, rA1
	mov rA1, rA2
	mov rA2, rA3
	mov rA3, rA4
	mov rA4, rA5
	mov rA5, rA6
	mov rA6, rA7
	subi XL, -8
	rjmp 4b
	
5:	; shift 1 bit at a time
	lsr rA6				; A >>= 1
	ror rA5
	ror rA4
	ror rA3
	ror rA2
	ror rA1
	ror rA0
	inc XL			
	brmi 5b				; until exponent > 0
	breq 5b
	ret					; return subnormal number

6:	; real underflow, return 0
	rjmp .L_zr


ENTRY __fp64_check_powserexp
#ifndef CHECK_POWSER
	ret
#else
	ldi ZL, lo8(.L_expTable)
	ldi ZH, hi8(.L_expTable)
	XJMP _U(__fp64_powser)
#endif
 
.L_ln2: ; ln2 in internal format
	.byte 0x3f, 0xB1, 0x72, 0x17, 0xF7, 0xD1, 0xCF, 0x84, 0x03, 0xFE	; 0x3FE62E42FEFA39EF = 0.69314718055994529 
.L_expTable:
	.byte 16	; polynom power = 16 --> 17 entries
	.byte 0x3D, 0x2A, 0xE7, 0xF3, 0xE7, 0x33, 0xB8, 0x1F ; = 0x3D2AE7F3E733B81F = 4.7794773323874E-14  = 1/16! = 1/20.922.789.888.000
	.byte 0x3D, 0x6A, 0xE7, 0xF3, 0xE7, 0x33, 0xB8, 0x1F ; = 0x3D6AE7F3E733B81F = 7.6471637318198E-13  = 1/15! = 1/1.307.674.368.000
	.byte 0x3D, 0xA9, 0x39, 0x74, 0xA8, 0xC0, 0x7C, 0x9D ; = 0x3DA93974A8C07C9D = 1.147074559773E-11   = 1/14! = 1/87.178.291.200
	.byte 0x3D, 0xE6, 0x12, 0x46, 0x13, 0xA8, 0x6D, 0x09 ; = 0x3DE6124613A86D09 = 1.60590438368216E-10 = 1/13! = 1/6.227.020.800
	.byte 0x3E, 0x21, 0xEE, 0xD8, 0xEF, 0xF8, 0xD8, 0x98 ; = 0x3E21EED8EFF8D897 = 2.08767569878681E-9  = 1/12! = 1/479.001.600
	.byte 0x3E, 0x5A, 0xE6, 0x45, 0x67, 0xF5, 0x44, 0xE4 ; = 0x3E5AE64567F544E3 = 2.50521083854417E-8  = 1/11! = 1/39.916.800
	.byte 0x3E, 0x92, 0x7E, 0x4F, 0xB7, 0x78, 0x9F, 0x5C ; = 0x3E927E4FB7789F5C = 2.75573192239859E-7  = 1/10! = 1/3.628.800
	.byte 0x3E, 0xC7, 0x1D, 0xE3, 0xA5, 0x56, 0xC7, 0x33 ; = 0x3EC71DE3A556C733 = 2.75573192239859E-6  = 1/9!  = 1/362.880
	.byte 0x3E, 0xFA, 0x01, 0xA0, 0x1A, 0x01, 0xA0, 0x1A ; = 0x3EFA01A01A01A019 = 2.48015873015873E-5  = 1/8!  = 1/40.320
	.byte 0x3F, 0x2A, 0x01, 0xA0, 0x1A, 0x01, 0xA0, 0x1A ; = 0x3F2A01A01A01A019 = 1.98412698412698E-4  = 1/7!  = 1/5.040
	.byte 0x3F, 0x56, 0xC1, 0x6C, 0x16, 0xC1, 0x6C, 0x17 ; = 0x3F56C16C16C16C16 = 1.38888888888889E-3  = 1/6!  = 1/720
	.byte 0x3F, 0x81, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11 ; = 0x3F81111111111111 = 8.33333333333333E-3  = 1/5!  = 1/120
	.byte 0x3F, 0xA5, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55 ; = 0x3FA5555555555555 = 0.041666666666666664 = 1/4!  = 1/24
	.byte 0x3F, 0xC5, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55 ; = 0x3FC5555555555555 = 0.16666666666666666  = 1/3!  = 1/6
	.byte 0x3F, 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; = 0x3FE0000000000000 = 0.5 				   = 1/2!  = 1/2
	.byte 0x3F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; = 0x3FF0000000000000 = 1 				   = 1/1!  = 1/1
	.byte 0x3F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; = 0x3FF0000000000000 = 1 				   = 1/0!  = 1/1
	.byte 0x00												; byte needed for code alignment to even adresses!
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
