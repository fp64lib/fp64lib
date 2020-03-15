/* Copyright (c) 2019-2020  Uwe Bissinger
   Based on 32bit floating point arithmetic routines which are:
   Copyright (c) 2002, Reiner Patommel
   Copyright (c) 2006  Dmitry Xmelkov
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

/* float fp64_atan2 (float A, float B);	// A is y coord, B is x coord.
     The fp64_atan2() function calculates the arc tangent of the two variables
     A and B. It is similar to calculating the arc tangent of A/B, except
     that the signs of both arguments are used to determine the quadrant
     of the result. The fp64_atan2() function returns the result in radians,
     which is between -PI and PI (inclusive).
     
   Note:
     Unlike the 32bit floating library, this implementation respects all four
	 cases of 0/0, like x86 (GCC/Glibc): +0/+0, +0/-0, -0/+0 and -0/-0.
	 
	Overview:
	Sector|  x   |  y   | |y|<=|x| | result algorithm | result range
	------+------+------+----------+------------------+-----------------
	 I	  | >= 0 | >= 0 |   yes    |  atan(y/x) +0    |       0..PI/4
	 II   | >= 0 | >= 0	|    no    | -atan(x/y) +PI/2 |	   PI/4..PI/2
	 III  |  < 0 | >= 0	|    no    | -atan(x/y) +PI/2 |    PI/2..3*PI/4
	 IV   |  < 0 | >= 0 |   yes    |  atan(y/x) +PI   |  3*PI/4..PI
	 V    |  < 0 |  < 0 |   yes    |  atan(y/x) -PI   |     -PI..-3*PI/4
	 VI   |  < 0 |  < 0 |    no    | -atan(x/y) -PI/2 | -3*PI/4..-PI/2
	 VII  | >= 0 |  < 0 |    no    | -atan(x/y) -PI/2 |   -PI/2..-PI/4
	 VIII |	>= 0 |  < 0 |   yes    |  atan(y/x) +0    |   -PI/4..0

	; case|	  A = y	 |	 B = x	 | atan2(A,B)
	;-----+----------+-----------+--------------------
	;  1a |	  NaN    |	  any    | NaN
	;  1b |	  any    |	  NaN    | NaN
	;  2a |   +0     |    >= 0   | +0
	;  2b |   +0     |     < 0   | +PI
	;  2c |   -0     |    >= 0   | -0
	;  2d |   -0     |     < 0   | -PI
	;  3a | +finite  |    +Inf   | +0
	;  3b | +finite  |    -Inf   | +PI
	;  3c | -finite  |    +Inf   | -0
	;  3d | -finite  |    -Inf   | -PI
	;  3e | +/- Inf  |   +/-Inf  | NaN
	;  3f | +/- Inf  |    any	 | +/- PI/2
	;  4  | |y|<=|x| |    >= 0   | see sector I & VIII: atan(y/x)+0
	;  5  | |y|<=|x| |     < 0   | see sector IV & V:   atan(y/x)+/-PI
	;  6  |    >= 0  | |y| > |x| | see sector II & III:	-atan(x/y)+PI/2
	;  7  |     < 0  | |y| > |x| | see sector VI & VII: -atan(x/y)-PI/2 
	;  8a |   +any   |   +/-0    | +PI/2
	;  8b |   -any   |   +/-0    | -PI/2
 */
#if !defined(__AVR_TINY__)
#include "fp64def.h"
#include "asmdef.h"

FUNCTION fp64_atan2
.L_nf:
	; handle special cases:
	;	B  / A |   NaN	  |	+/-Inf	 |	   0	|	finite
	;	-------+----------+----------+----------+----------
	; 	NaN	   | C=1 Z=0 a| C=1 Z=0 a| C=1 Z=0 a| C=1 Z=0 a
	;	+/-Inf | C=1 Z=0 a| C=1 Z=1 b| C=1 Z=1 b| C=1 Z=1 b
	;	0	   | C=1 Z=0 a| C=1 Z=1 b| C=0 Z=1 c| C=0 Z=0 d
	;	finite | C=1 Z=0 a| C=1 Z=1 b| C=0 Z=1 c| C=0 Z=0 d
	
	brne .L_nan		; case 1a&1b, a C=1 Z=0: A or B is NaN --> return NaN
	
	; b C=1 Z=1: now either A is +/-Inf and B is any != NaN
	;      		  or A is 0 or finite and B is +/- Inf
	XCALL _U(__fp64_pscA)
	brne .L_0orPI		; case 3a-3d: A is finite, B is +/-Inf --> atan(A/B) = +0 or +PI
	
	; case 3b&3c: A is +/-Inf, B is any != NaN
	; is B also +/- Inf?
	XCALL _U(__fp64_pscB)
	brcs .L_nan			; yes, case 3b: A = +/-Inf, B = +/-Inf --> atan2(A,B) = NaN
	
	; no: case 3c: A= +/- Inf, B is finite --> atan2(A,B) will be handled via atan(A/B)
	sbrc rB7, 7			; is B negative?
	subi rA7, 0x80		; yes: restore original sign of A
	push rA7			; save sign of A
	bst rA7, 7			; sign of result is depending on sign of y
	mov r0, r1			; set indicator to 0x00 = add nothing
	ori rA6, 0x80		; make +/-Inf a really big number
	ori rB6, 0x80		; handle also the case of B == 0 or B being subnormal
	rjmp .L_div

	; cases 1a & 1b: A  or B  is NaN    --> atan2(A,B) == NaN
	; also case 3b:  A and B are +/-Inf --> atan2(A,B) == NaN
.L_nan:				
	XJMP	_U(__fp64_nanp)

	; return 0 or PI for
	; case 2a-2d: A is 0, B is finite
	; case 3a-3d: A is finite, B is +/-Inf
.L_0orPI:
	sbrs rB7, 7			; is B < 0?
	rjmp .L_zr			; no, handle positive cases

	; here B < 0
	; case 2b: A is +0, B is -finite --> atan(A,B) == +PI
	; case 2d: A is -0, B is -finite --> atan(A,B) == -PI
	; case 3b: A is +finite, B is -Inf    --> atan(A,B) == +PI
	; case 3d: A is -finite, B is -Inf    --> atan(A,B) == -PI
	subi rA7, 0x80		    ; restore original sign of A
	mov r0, rA7				; return 0 +/- PI, depending on sign of A
	XCALL _U(__fp64_szero)	; only needed for 3b/3d: overwrite Inf with 0
	ldi rB7, 0x80  			; set indicator to "add PI"
	rjmp .L_addPi

	; case 2a: A is +0,      B is +finite --> atan(A,B) == +0	
	; case 2c: A is -0,      B is +finite --> atan(A,B) == -0	
	; case 3a: A is +finite, B is +Inf    --> atan(A,B) == +0	
	; case 3c: A is -finite, B is +Inf    --> atan(A,B) == -0	
.L_zr:
	XCALL _U(__fp64_popB)
	XJMP _U(__fp64_szero)

ENTRY   fp64_atan2
GCC_ENTRY __atan2
	XCALL _U(__fp64_pushB)
	XCALL	_U(__fp64_split3)
	; rcall __fp64_saveAB
	brcs .L_nf			; handle special cases A or B being non-finite
	breq .L_0orPI		; check for case 2a-2d: A == 0

	sbrc rB7, 7			; is B negative?
	subi rA7, 0x80		; yes: restore original sign of A

	XCALL _U(__fp64_isBzero)
	brne .L_cmp			; check for cases 4-7

	; case 8a/b: A is finite, B is 0: atan(A/B)=atan(+/-INF)
	; rcall __fp64_saveAB
	push rA7			; push sign of y
	bst rA7, 7			; sign of y drives result
	XCALL _U(__fp64_inf); B is 0 --> avoid division, go ahead with result = +/-INF
	push r1				; push 0x00 as post processing indicator = add nothing
	rjmp .L_atan

  ; compare absolute values
.L_cmp:
	XCALL _U(__fp64_cpcAB)
	cpc rBE0, rAE0
	cpc rBE1, rAE1
	; rcall __fp64_saveAB
	brlo 1f			; fabs(a) > fabs(B)

	; cases 4&5: fabs(A) <= fabs(B) --> no swapping needed
	mov r0, r1		
	sec
	sbrc rB7,7		; copy sign of x into r0
	ror r0			; r0 becomes 0x80
	
	push rA7		; save sign of y
	
.L_div:
	push r0			; push post processing indicator
					; r0 = 0x00 --> add nothing
					; r0 = 0x80 --> add PI
					; r0 = 0x81 --> add PI/2
	; rcall __fp64_saveAB
	XCALL _U(__fp64_divsd3_pse)
	brcs .L_atan
	XCALL _U(__fp64_rpretA)
.L_atan:
	; rcall __fp64_saveAB
	XCALL _U(fp64_atan)
	pop rB7			; restore post processing indicator into now free rB7
	pop r0			; restore sign of y into r0, as rA7 holds result of atan

	; rcall __fp64_saveAB

	sbrc rB7, 7		; indicator >= 0x80?
	rjmp .L_addPi	; yes, case 5-7, add +/- PI or +/- PI/2
    				
	; no: case 4, return atan(y/x)
	XJMP _U(__fp64_popBret)		; restore registers and return

.L_addPi:
	; add +/-PI or +/-PI/2, depending on
	; 	bit 0 of rB7 == 0 --> use PI as displacement
	; 	bit 0 of rB7 == 1 --> use PI/2 as displacement
	;	bit 7 of r0  == 0 --> add displacement
	;   bit 7 of r0  == 1 --> subtract displacement
	
	; sector II, III, VI, VII: add +/- PI/2
	ldi ZL, lo8(.L_pi_o_2)
	ldi ZH, hi8(.L_pi_o_2)
	sbrs rB7, 0		; indicator = 0x81?
	adiw ZL, 0x08	; no: sector IV, V: add PI

	lpm rB7, Z+
	lpm rB6, Z+
	lpm rB5, Z+
	lpm rB4, Z+
	lpm rB3, Z+
	lpm rB2, Z+
	lpm rB1, Z+
	lpm rB0, Z+
	
	sbrc r0, 7		; y < 0?
	subi rB7, 0x80	; yes: Sector V, VI, VII: change sign of displacement

	; add displacement
	; rcall __fp64_saveAB
	XCALL _U(__fp64_popB)
	XJMP	_U(fp64_add)
	
1:	; cases 6 & 7: fabs(A) > fabs(B) --> swap values and change the atan sign
	; atan(y/x) = -atan(x/y) +/- PI/2
	;           = atan(x/-y) +/- PI/2
	XCALL _U(__fp64_swapAB)

	push rB7
	ldi rB7, 0x81			; r0 = 0x81: add pi/2
	mov r0, rB7
	pop rB7
	
	push rB7				; save original sign of y
	subi rB7, 0x80			; -atan(x/y) = atan(x/-y)
	eor rB7, rA7			; T must reflext sign(A)^sign(B)
	bst rB7, 7
	eor rB7, rA7			; restore rB7
	rjmp .L_div

.L_pi_o_2:	; PI/2 = 1.5707963267948966
	.byte 0x3f, 0xf9, 0x21, 0xfb, 0x54, 0x44, 0x2d, 0x18
.L_pi:		; PI = 3.1415926535897932
	.byte 0x40, 0x09, 0x21, 0xfb, 0x54, 0x44, 0x2d, 0x18
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
