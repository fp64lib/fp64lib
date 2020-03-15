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
ENTRY fp64_cos
GCC_ENTRY __cos
	XCALL _U(__fp64_splitA)
	brcs 0b		; NaN or +/i INF
	breq 2b		; A = 0 --> result of sin = 0
	ldi XH, 0x02
	rjmp .L_common


/*	float64_t fp64_sin( float64_4 phi )
	returns the sine of phi
*/
ENTRY fp64_sin
GCC_ENTRY __sin
	XCALL _U(__fp64_splitA)
	brcs 0b		; NaN or +/i INF
	breq 1b		; A = 0 --> result of sin = 0
	ldi XH, 0x01

.L_common:	
	bld XH, 4			; save sign of argument 
	sts __funcCode, XH
	
	clt					; further calculations on fabs(x) 
	andi rA7, 0x7f

	XCALL _U(__fp64_pushCB)	; as all registers may be used, save them
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
	XCALL _U(__fp64_add_pse)	; fmod(x,PI/2) - PI/2 (upper 56 bits)

	XCALL _U(__fp64_ldb_pi2x)
	clt
	XCALL _U(__fp64_add_pse)	; fmod(x,PI/2) - PI/2 (lower 56 bits)
	
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
	; rcall __fp64_saveAB
	ldi XL, lo8(.L_tableSin)
	ldi XH, hi8(.L_tableSin)
	XCALL _U(__fp64_powsodd)
	
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
	XCALL _U(__fp64_popBC)	; restore register set

.L_retA:	
	XJMP _U(__fp64_rpretA)

.L_tableSin:
	.byte 8		; polynom power = 8 --> 9 entries
	.byte 0x00, 0xC4, 0x07, 0xFB, 0x4D, 0x40, 0xAE, 0x86, 0x03, 0xce ; 0x3CE880FF69A815D1 =  2.720479096311348754125777035760538080062928010E-15 	
	.byte 0x80, 0xD7, 0x21, 0x06, 0xE0, 0x47, 0xD9, 0x4C, 0x03, 0xd6 ; 0xBD6AE420DC08FB2A = -7.642917806936943181404083427350360977933E-13 		
	.byte 0x00, 0xB0, 0x91, 0xE3, 0x43, 0x56, 0xB5, 0x41, 0x03, 0xde ; 0x3DE6123C686AD6A8 =  1.605893649037322308343580530203636594694026606E-10 	
	.byte 0x80, 0xD7, 0x32, 0x2A, 0x5A, 0xEE, 0x05, 0xA5, 0x03, 0xe5 ; 0xBE5AE6454B5DC0B5 = -2.505210679827461489694414386497765381412E-8 		
	.byte 0x00, 0xB8, 0xEF, 0x1D, 0x29, 0x27, 0x83, 0x19, 0x03, 0xec ; 0x3EC71DE3A524F063 =  0.000002755731921015275643621147943522106380777954579 
	.byte 0x80, 0xD0, 0x0D, 0x00, 0xD0, 0x09, 0xF0, 0xD1, 0x03, 0xf2 ; 0xBF2A01A01A013E1A = -0.0001984126984120184045925275053678029666036 		
	.byte 0x00, 0x88, 0x88, 0x88, 0x88, 0x88, 0x85, 0x80, 0x03, 0xf8 ; 0x3F811111111110B0 =  0.008333333333333165031409486688626409893626479389 	
	.byte 0x80, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xA6, 0x03, 0xfc ; 0xBFC5555555555555 = -0.1666666666666666505227673233538421622550 			
	.byte 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xff ; 0x3FF0000000000000 =  0.9999999999999999997427749007994397865435536768 			
	.byte 0x00												; byte needed for code alignment to even adresses!                        ;                    = 
ENDFUNC

.data
__funcCode:	 .skip 1
