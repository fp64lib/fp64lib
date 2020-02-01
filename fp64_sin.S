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

/* $Id$ */

#include "fp64def.h"
#include "asmdef.h"

/*	float64_t fp64_sin( float64_4 phi )
	returns the sine of phi
*/
FUNCTION fp64_sin

ENTRY fp64_atan
	ldi XH, 0x83
	rjmp .L_common
			
ENTRY fp64_tan
	ldi XH, 0x03
	rjmp .L_common

ENTRY fp64_cos
	ldi XH, 0x02
	rjmp .L_common

1:	; argument = 0 --> return 0 for (a)sin/(a)tan, 1 for cos; PI/2 for acos
	clr rA0
	clr rA1
	movw rA2, rA0
	movw rA4, rA0
	movw rA6, rA0
	sbrc XH,0		; no, sin/asin or tan/atan?
	ret				; for (a)sin/(a)tan return (XH is 2 or 0)
	sbrc XH, 7		; acos ?
	rjmp 39f		; yes, return PI/2
	ldi rA7, 0x3f	; for cos return +/-1
	ldi rA6, 0xf0
	clr r0			; adjust sign based on flags
	sbrc XH, 4
	inc r0			; get sign of x into bit 0 of r0
	sbrc XH, 5
	inc r0			; add sign change of result to bit 0
	sbrc r0,0
	sbr rA7, 0x80
	ret
	

0:	; handle special case NaN and +/- INF
	brne 100f		; NaN returns NaN
	cpi XH, 0x83	; atan(INF) --> PI/2
	brne 100f
	rjmp 39f
	; for all other functions return NaN
.L_nan:
	pop rX0			; restore 1st half of used registers
	pop rX1
	pop rX2
	pop rX3
	pop rX4
	pop rX5
	pop rX6
	pop rX7
100:XJMP	_U(__fp64_nan)

	; argument < 2^-53 --> return A as sin(A) is A in this range or 1 for cos
.L_retA:	
	pop rX0			; restore 1st half of used registers
	pop rX1
	pop rX2
	pop rX3
	pop rX4
	pop rX5
	pop rX6
	pop rX7
	
	; rcall __fp64_saveAB
	sbrs XH, 0		; sin/tan?
	rjmp 1b			; no, for cos return 1
	subi rAE0, lo8(-0x3ff)
	sbci rAE1, hi8(-0x3ff)
	clr r0				; adjust sign based on flags
	sbrc XH, 4
	inc r0				; get sign of x into bit 0 of r0
	sbrc XH, 5
	inc r0				; add sign change of result to bit 0
	bst r0, 0
	XJMP _U(__fp64_pretA)

ENTRY fp64_sin
	ldi XH, 0x01
.L_common:
	XCALL _U(__fp64_splitA)
	brcs 0b		; NaN or +/i INF
	breq 1b		; A = 0 --> result of sin = 0
	
	bld XH, 4			; save sign of argument 
	sts __funcCode, XH

	push rX7			; save 1st half of registers that will be used by cordic
	push rX6
	push rX5
	push rX4
	push rX3
	push rX2
	push rX1
	push rX0

	sbrc XH, 7
	rjmp 15f			; skip range rduction for inverse functions
	
	; for sin/cos/tan, reduce argument to range 0 - pi/2
	; use argument reduction with extended precision
	push rC0
	push rC1
	push rC2
	push rC3
	push rC4
	push rC5
	push rC6
	push rC7
	XCALL _U(__fp64_fmodx_pi2_pse)
	mov r0, rC4
	; rcall __fp64_saveAB
	pop rC7
	pop rC6
	pop rC5
	pop rC4
	pop rC3
	pop rC2
	pop rC1
	pop rC0

	push r0
	sbrs r0, 0					; was x in 2nd or 4th quadrant for
	rjmp 12f					; no, continue
	rcall .L_ld_pio2			; yes: sin(x) = - sin( fmod(x,PI/2) - PI/2 )
	ldi rB7, 0xbf				; set sign both in B
	set							; and T
	XCALL _U(__fp64_add_pse)	; x - PI/2
	; we can ignore the returned C flag, as neither underflow nor overflow will happen
	
12:	; adjust sign according to quadrant
	pop r0
	lds XH, __funcCode

	;mov rA7, r0

	sbrs XH, 0			; sin/tan?
	rjmp 13f			; no, continue with rules for cos
	sbrc XH, 1			; sin?
	rjmp 133f			; no, continue with rules for tan
	; for sin: if x in 1Q or 4Q, change sign 
	sbrc r0, 1			; is x in quadrant 1 & 4?
	rjmp 14f			; no, change sign
	rjmp 15f			; yes, leave sign as it is
	
133: ; for tan: if x in 
	sbrs r0, 0			; in Q1 or Q3?
	rjmp 15f			; no, leave sign as it is
	sbrs XH, 4			; x < 0?
	rjmp 15f			; no, leave sign as it is
	rjmp 14f			; yes, change sign

11: rjmp .L_retA
	
13:	; for cos: if x in 1Q or 2Q, change sign
	clt					; clear sign of x as cos(-x) = cos(x)
	bld XH, 4			; save sign of argument 
	sts __funcCode, XH

	asr r0
	adc r0, r1

	sbrs r0, 0			; is x in Q2 & Q3?
	rjmp 15f			; no, leave sign as it is
	; yes, change sign
14:	inc r1
	inc r1
	swap r1				; substitue for ldi r0, 0x20
	or XH, r1			; toggle bit 5 (sign of argument/result)
	sts __funcCode, XH
	clr r1
	
15:	;rcall __fp64_saveAB
	subi rAE0, 0xff		; remove base from exponent
	sbci rAE1, 0x03
	brcc 2f				; exponent >= 0 --> number can be converted
	cpi rAE0, lo8(-26)
	; rcall __fp64_saveAB
	brlo 11b				; A < 2^-26, return A
	cpi rAE1, hi8(-26)
	brne 11b				; A < 2^-26, return A
	
2:	; A is > 2^-26
	; convert phi to significand_64 format
	mov rPHI7, rA6
	mov rPHI6, rA5
	mov rPHI5, rA4
	mov rPHI4, rA3
	mov rPHI3, rA2
	mov rPHI2, rA1
	mov rPHI1, rA0
	;subi rPHI1, -8
	clr rPHI0
	
	;call __fp64_saveCordic
	push rY7
	push rY6
	push rY5
	push rY4
	push rY3
	push rY2
	push rY1
	push rY0

	lds XH, __funcCode
	sbrc XH,7
	rjmp 32f			; special normalization for inverse functions
	
	; argument for normal trigonometric functions are in the range
	; 2^-26 < arg < PI/2, which is < 2
	; shift phi -exponent digits to the right
3:	cpi rAE0, 0x01
	breq 4f				; done, when exponent == 1
31:	lsr rPHI7			; PHI >>= 1
	ror rPHI6
	ror rPHI5
	ror rPHI4
	ror rPHI3
	ror rPHI2
	ror rPHI1
	ror rPHI0
	inc rAE0			; exponent++
	rjmp 3b

39:	; argument > 2^40 --> result of atan is PI/2 = 0x 3f f9 21 fb 54 44 2d 18
	ldi rA7, 0x3f
	ldi rA6, 0xf9
	ldi rA5, 0x21
	ldi rA4, 0xfb
	ldi rA3, 0x54
	ldi rA2, 0x44
	ldi rA1, 0x2d
	ldi rA0, 0x18
	bld rA7,7			; with proper sign
	ret
37:	rcall 39b
	rjmp 8f				; pop registers and return
	
	; special normalization for inverse functions
	; argument may be >= 1
32: ldi rX7, 0x40	; x = 1
	clr rX6
	clr rX5
	clr rX4
	movw rX2, rX4
	movw rX0, rX4

	tst rAE1
	brmi 31b			; exponent < 0, i.e. argument < 2^-1 = 0.5 --> all normal
	brne 37b			; exponent > 256, i.e. argument > 2^256 --> result of atan is PI/2
	cpi rAE0, 40
	brsh 37b			; argument > 2^41 --> result of atan is PI/2
	
33:	tst rAE0			; while exponent > 0
	breq 31b
	lsr rX7				; x >>= 1
	ror rX6
	ror rX5
	ror rX4
	ror rX3
	ror rX2
	ror rX1
	ror rX0
	dec rAE0
	rjmp 33b
	
4:	brtc 44f			; if phi < 0 
	com rPHI7			; A = -A 
	com rPHI6
	com rPHI5
	com rPHI4
	com rPHI3
	com rPHI2
	com rPHI1
	com rPHI0
	
44:	; PHI is now in significand_64 format
	; save all working registers and call cordic routine
	; call __fp64_saveCordic
	; ret

	XCALL _U(__fp64_cordic)
	
	sbrc XH, 7		; inverse functions?
	rjmp 101f		; yes, convert phi
	
	sbrc XH,0		; cos?
	rjmp 10f		; no, go ahead and convert 
	; yes, it's cosine (XH = 2), Cordic returns cos in rX
	rcall 19f		; convert cos(phi) in X to cos(phi) in A
	bld XH,4		; get and save sign of cos(phi) from T to XH
	sts __funcCode, XH
	rjmp 12f		; continue with division by g
	
101:	; inverse functions, result is in rPHI7..rPHI0
	; needs to be moved to Y for conversion
	movw rY0, rPHI0
	movw rY2, rPHI2
	movw rY4, rPHI4
	movw rY6, rPHI6
	;call __fp64_saveCordic
	rcall 20f
	rcall 30f			; convert exponent of A
	rjmp 99f
	
	; sin or tan
10:	rcall 20f		; convert sin(phi) in Y to cos(phi) in A

	bld XH,4		; get and save sign of sin(phi) from T to XH
	sbrs XH,1		; sin (XH = 1) or tan (XH = 3)?
	rjmp 12f		; calculate sin(phi) = A / g

	; we have to calculate tan = sin(phi) / cos(phi) = Y / X
	; A already holds sin(phi), now we want to convert cos(phi) in rX7..rX0
	push rA7
	push rA6
	push rA5
	push rA4
	push rA3
	push rA2
	push rA1
	push rA0
	push r0
	
	rcall 19f		; convert cos(phi) in X to cos(phi) in A
	rcall 30f		; and convert exponent 
	
	bld r1, 4		; get sign of cos(phi)
	eor XH, r1		; sign of result = sign(A) ^ sign(B)
	sts __funcCode, XH ; save result
	clr r1			; and clear again r1

	movw rBE0, rAE0	; mov cos(phi) into B (this overwrites XH!!)
	movw rB6, rA6
	movw rB4, rA4
	movw rB2, rA2
	movw rB0, rA0
	
	pop r0			; restore exponent of A
	rcall 30f		; and convert it
	
	pop rA0			; restore sin(phi)
	pop rA1
	pop rA2
	pop rA3
	pop rA4
	pop rA5
	pop rA6
	pop rA7

	rjmp 99f		; calculate tan(phi) = sin(phi) / cos(phi) = A/B
	
	; load significand of g
12:	lpm rB6, Z+
	lpm rB5, Z+
	lpm rB4, Z+
	lpm rB3, Z+
	lpm rB2, Z+
	lpm rB1, Z+
	lpm rB0, Z+
	
	; set exponent for g
	ldi rBE0, 0xff		; g is always between 1 and 2
	ldi rBE1, 0x03		; --> exponent B = 0x0x400
	ldi rB7, 0x3f
	
	rcall 30f			; convert exponent of A

99:	; call __fp64_saveAB
	lds r0, __funcCode
	bst r0, 4			; retrieve and set sign of result
	sbrc r0, 7
	rjmp 88f
	
	; call __fp64_saveAB
	XCALL _U(__fp64_divsd3_pse)	; res = y / g
	brcs 79f
	XCALL _U(__fp64_pretA)
79:	cpi rA6, 0xf0
	brne 8f
	cpi rA7,0x3f				; check if result == 1
	breq 80f
	cpi rA7,0xbf				; check if result == -1
	brne 8f
80:	clr rA0						; make sure that result does not exceeed 1.0
	;call __fp64_saveAB
	;XCALL _U(__fp64_pretA)

	; restore used registers and return
8:	lds r0, __funcCode
	rcall __fp64_saveAB
	sbrc r0, 5				; check if sign has to be reversed
	subi rA7, 0x80			; reverse it

	pop rY0
	pop rY1
	pop rY2
	pop rY3
	pop rY4
	pop rY5
	pop rY6
	pop rY7
	pop rX0
	pop rX1
	pop rX2
	pop rX3
	pop rX4
	pop rX5
	pop rX6
	pop rX7
	ret

88:	XCALL _U(__fp64_pretA)
	rjmp 8b
	
	; subroutine to convert rX7..rX0 from significand_64 format to 
	; normal internal format with significand in rA6..rA0 and 
	; exponent in rAE1.rAE0
	; Warning: Overwrites rY7..rY0!
19:	movw rY0, rX0
	movw rY2, rX2
	movw rY4, rX4
	movw rY6, rX6

	; subroutine to convert rY7..rY0 from significand_64 format to 
	; normal internal format with significand in rA6..rA0 and 
	; exponent in rAE1.rAE0
20:	clr r1
	cp r1, rY7	; check if Y is 0
	cpc r1, rY6
	cpc r1, rY5
	cpc r1, rY4
	cpc r1, rY3
	cpc r1, rY2
	cpc r1, rY1
	cpc r1, rY0
	brcs 21f		; if result != 0, return result
	
	movw rA6, rY6	; return 0
	movw rA4, rY4
	movw rA2, rY2
	movw rA0, rY0
	movw rAE0, rY6
	clt
	ret
	
21:	clr r0			; exponent = 1 (we can't use rAE1/rAE0  = ZH.ZL
					; as ZH.ZL are used by cordic to return a pointer
					; to the gain value
	inc r0			; start with exponent = 1, which is only true is result = 1.0
	
	bst rY7,7		; set sign from Y
	brtc 22f		; if Y > 0, start conversion
	com rY7			; Y = -Y
	com rY6
	com rY5
	com rY4
	com rY3
	com rY2
	com rY1
	neg rY0
	
 22:;neg r0
	; com r0			; exponent--
	dec r0			; exponent--
	lsl rY0			; Y <<= 1
	rol rY1
	rol rY2
	rol rY3
	rol rY4
	rol rY5
	rol rY6
	rol rY7
	brpl 22b	; stop when the leading bit is set	
	
	; Y is now correctly shifted (or 0)	
	; so now move Y to A for the upcoming division
	; todo: here, we could add some rounding?
	mov rA6, rY7
	mov rA5, rY6
	mov rA4, rY5
	mov rA3, rY4
	mov rA2, rY3
	mov rA1, rY2
	mov rA0, rY1
	mov rA7, r0
	tst rY0
	brpl 23f
	
	subi rA0, -1
	adc rA1, r1
	adc rA2, r1
	adc rA3, r1
	adc rA4, r1
	adc rA5, r1
	adc rA6, r1
	; the last add will never overflow as result will always be < 1.7

23:	ret

30:	; set exponent for A
	mov rAE0, r0
	clr rAE1
	sbrc rAE0,7
	com rAE1				; extend sign to rAE1
	subi rAE0, lo8(-1023)	; adjust exponent	
	sbci rAE1, hi8(-1023)

	swap rAE0		; exponent is 11 bits = 3 nibbles = e2.e1.e0
	swap rAE1		; rAE1.rAE0 is now e2.0.e0.e1

	mov rA7,rAE0	; built top 8 bits of exponent, rA7 = e0.e1
	andi rA7, 0x0f	; start with 0.e1
	or rA7,rAE1		; add it to e2.e1

	swap rAE0		; put exponent back into normal order e2..e1.e0
	swap rAE1

	ret
	
.L_ld_pio2:
	push ZL				; load b with PI/2
	push ZH
	clr rB7
	ldi ZL, lo8(__pi_o_2)
	ldi ZH, hi8(__pi_o_2)
	lpm rB6, Z+
	lpm rB5, Z+
	lpm rB4, Z+
	lpm rB3, Z+
	lpm rB2, Z+
	lpm rB1, Z+
	lpm rB0, Z+
	lpm rBE1, Z+
	lpm rBE0, Z+
	pop ZH
	pop ZL
	ret

	; PI/2 with 106 bits precision, necessary as for x >> 2PI cancellation of digits occurs in fmod
__pi_o_2:	.byte 0xC9, 0x0F, 0xDA, 0xA2, 0x21, 0x68, 0xC2, 0x03, 0xff, 0x00	; PI/2 = 1.5707963267948966
	
ENDFUNC

.data
__funcCode:	 .skip 1
