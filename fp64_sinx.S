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
FUNCTION fp64_sinx

2:	; argument = 0 --> return 1 for cos
	ldi rA7, 0x3f	; for cos return +/-1
	ldi rA6, 0xf0
	; all other registers are already 0
	bst rA7, 7		; set sign
	ret

1:	; argument = 0 --> return 0 for sin
	XJMP _U(__fp64_szero)

0:	; handle special case NaN and +/- INF
	XJMP	_U(__fp64_nan)

/*	float64_t fp64_cos( float64_4 phi )
	returns the cosine of phi
*/
ENTRY fp64_cosx
	XCALL _U(__fp64_splitA)
	brcs 0b		; NaN or +/i INF
	breq 2b		; A = 0 --> result of sin = 0
	ldi XH, 0x02
	rjmp .L_common


/*	float64_t fp64_sin( float64_4 phi )
	returns the sine of phi
*/
ENTRY fp64_sinx
	XCALL _U(__fp64_splitA)
	brcs 0b		; NaN or +/i INF
	breq 1b		; A = 0 --> result of sin = 0
	ldi XH, 0x01

.L_common:	
	bld XH, 4			; save sign of argument 
	sts __funcCode, XH
	
	clt					; further calculations on fabs(x) 
	andi rA7, 0x7f

	push rAx3	; as all registers may be used, save them
	push rAx2
	push rAx1
	push rAx0
	push rBx11
	push rBx10
	push rBx9
	push rBx8
	push rBx7
	push rBx6
	push rBx5
	push rBx4
	push rBx3
	push rBx2
	push rBx1
	push rBx0
	push YH
	push YL
	push XH
	push XL
	
	; reduce argument to range 0 - pi/2
	; use argument reduction with extended precision
	XCALL _U(__fp64_fmodx_pi2_pse)
	; rcall __fp64_saveAB
	
	lds XH, __funcCode
	mov r0, rC4					; we need only the information about the quadrant
	sbrc XH, 1
	inc r0						; cos(x) = sin(x+PI/2) --> move forward 1 quadrant
	; rcall __fp64_saveAB
	
	push r0
	sbrs r0, 0					; was x in 2nd or 4th quadrant? (r0 == 1 or 3)
	rjmp 12f					; no, continue
	
	XCALL _U(__fp64_ldb_pi2)	; yes: sin(x) = +/-sin( PI/2 - fmod(x,PI/2)  ) 
								;			  = +/-sin( -fmod(x,PI/2) + PI/2
	ori rA7, 0x80
	set
	XCALL _U(__fp64_add_pse)	; fmod(x,PI/2) - PI/2
	; we can ignore the returned C flag, as neither underflow nor overflow will happen
		
12:	; adjust sign according to quadrant: for x in Q3 and Q4, sign must be negative
	pop r0
	lds XH, __funcCode
	ldi XL, 0x20
	sbrc r0, 1					; is x in quadrant 3 & 4? (r0 == 2 or 3)
	or XH, XL					; yes: set bit 5 (sign of result to be changed)

	; sin(-x) = -sin(x)
	sbrs XH, 0					; sin(x)?
	rjmp 15f					; no --> cos --> skip change, as cos(-x) = cos(x)
	sbrc XH, 4					; yes, is x < 0?
	eor XH, XL					; yes, toggle bit 5
	
15:	; approximate sin(x) by Taylor series 
	sts __funcCode, XH
	rcall __fp64_saveAB
	ldi XL, lo8(.L_tableSin)
	ldi XH, hi8(.L_tableSin)
	XCALL _U(__fp64_powsoddx)
	
	; restore used registers and return
	lds r0, __funcCode
	bld rA7,7
	; rcall __fp64_saveAB
	sbrc r0, 5				; check if sign has to be reversed
	subi rA7, 0x80			; reverse it
	bst rA7,7				; and set it accordingly

	pop XL					; restore all used registers
	pop XH
	pop YL
	pop YH
	pop rBx0
	pop rBx1
	pop rBx2
	pop rBx3
	pop rBx4
	pop rBx5
	pop rBx6
	pop rBx7
	pop rBx8
	pop rBx9
	pop rBx10
	pop rBx11
	pop rAx0
	pop rAx1
	pop rAx2
	pop rAx3

.L_retA:	
	XJMP _U(__fp64_rpretA)

.L_tableSin:
	.byte 16	; polynom power = 16 --> 17 entries
	.byte 0x00, 0x9C, 0xC0, 0x92, 0xA6, 0xE8, 0x6A, 0x8E, 0x03, 0x84 ;  1.151633562077195028058688149329822111482E-37   = +1/33! = +1 / 868 331 761 881 188 649 551 819 440 128 000 000
	.byte 0x80, 0xA1, 0xA6, 0x97, 0x3C, 0x1F, 0xAD, 0xE2, 0x03, 0x8e ; -1.216125041553517949629974685692292149725E-34   = -1/31! = -1 / 8 222 838 654 177 922 817 725 562 880 000 000
	.byte 0x00, 0x92, 0xCF, 0xCC, 0x5A, 0x1A, 0xC5, 0x6C, 0x03, 0x98 ;  1.130996288644771693155876457693831699244E-31   = +1/29! = +1 / 8 841 761 993 739 701 954 543 616 000 000
	.byte 0x80, 0xE8, 0xD5, 0x8E, 0x16, 0xE6, 0x75, 0x19, 0x03, 0xa1 ; -9.183689863795546148425716836473913397862E-29   = -1/27! = -1 / 10 888 869 450 418 352 160 768 000 000
	.byte 0x00, 0x9F, 0x9E, 0x66, 0xE8, 0xB2, 0xFD, 0x47, 0x03, 0xab ;  6.446950284384473396194853219204687205299E-26   = +1/25! = +1 / 15 511 210 043 330 985 984 000 000
	.byte 0x80, 0xBB, 0x0D, 0xA0, 0x98, 0xB1, 0xC0, 0xCF, 0x03, 0xb4 ; -3.868170170630684037716911931522812323179E-23   = -1/23! = -1 / 25 852 016 738 884 976 640 000
	.byte 0x00, 0xB8, 0xDC, 0x77, 0xB6, 0xE7, 0xAB, 0x8C, 0x03, 0xbd ;  1.957294106339126123084757437350543035529E-20   = +1/21! = +1 / 51 090 942 171 709 440 000
	.byte 0x80, 0x97, 0xA4, 0xDA, 0x34, 0x0A, 0x0A, 0xB9, 0x03, 0xc6 ; -8.220635246624329716955981236872280749221E-18   = -1/19! = -1 / 12 164 510 040 883 200
	.byte 0x00, 0xCA, 0x96, 0x3B, 0x81, 0x85, 0x6A, 0x53, 0x03, 0xce ;  2.811457254345520763198945583010320016233E-15   = +1/17! = +1 / 355 687 428 096 000
	.byte 0x80, 0xD7, 0x3F, 0x9F, 0x39, 0x9D, 0xC0, 0xF9, 0x03, 0xd6 ; -7.647163731819816475901131985788070444155E-13   = -1/15! = -1 / 1 307 674 368 000
	.byte 0x00, 0xB0, 0x92, 0x30, 0x9D, 0x43, 0x68, 0x4C, 0x03, 0xde ;  1.605904383682161459939237717015494793273E-10   = +1/13! = +1 / 6 227 020 800
	.byte 0x80, 0xD7, 0x32, 0x2B, 0x3F, 0xAA, 0x27, 0x1C, 0x03, 0xe5 ; -2.505210838544171877505210838544171877505E-8    = -1/11! = -1 / 3 916 800
	.byte 0x00, 0xB8, 0xEF, 0x1D, 0x2A, 0xB6, 0x39, 0x9C, 0x03, 0xec ;  0.000002755731922398589065255731922398589065256 = +1/9!  = +1 / 362 880
	.byte 0x80, 0xD0, 0x0D, 0x00, 0xD0, 0x0D, 0x00, 0xD0, 0x03, 0xf2 ; -0.0001984126984126984126984126984126984126984   = -1/7!  = -1 / 5 040
	.byte 0x00, 0x88, 0x88, 0x88, 0x88, 0x88, 0x88, 0x89, 0x03, 0xf8 ;  0.008333333333333333333333333333333333333333    = +1/5!  = +1 / 120
	.byte 0x80, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAB, 0x03, 0xfc ; -0.1666666666666666666666666666666666666667      = -1/3!  = -1 / 6
	.byte 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xff ;  1.0000000000000000000000000000000000000000      = +1/1!  = +1 / 1
	.byte 0x00												; byte needed for code alignment to even adresses!
	
ENDFUNC

.data
__funcCode:	 .skip 1
