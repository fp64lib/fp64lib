/* Copyright (c) 2018  Uwe Bissinger
   Based on 32bit floating point arithmetic routines which are:
   Copyright (c) 2002  Michael Stumpf  <mistumpf@de.pepperl-fuchs.com>
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

#if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

/* float64_t __fp_powser (float64_t x, ZH.ZL);
     The __fp_powser() function calculates the polynom.

   Input:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	- an 'x' arg as float64_t
     ZH.ZL								- table address (in low 64K flash memory)
   Output:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0	- result

   Table format:
     ; example for 3 power: C0 + x*(C1 + x*(C2 + x*C3))
     ; all float64_t are little-endian
	.byte	3		; polynom power
	.byte	C3,C3,C3,C3,C3,C3,C3,C3	; float64_t C3
	.byte	C2,C2,C2,C2,C2,C2,C2,C2	; float64_t C2
	.byte	C1,C1,C1,C1,C1,C1,C1,C1	; float64_t C1
	.byte	C0,C0,C0,C0,C0,C0,C0,C0	; float64_t C0
 */

#define	rcntr	r1

ENTRY __fp64_powser
	push	rC7			; save temp registers
	push	rC6
	push	rC5
	push	rC4
	push	rC3
	push	rC2
	push	rC1
	push	rC0
	push	rB7
	push	rB6
	push	rB5
	push	rB4
	push	rB3
	push	rB2
	push	rB1
	push	rB0
	push	rBE0
	push	rBE1
	
	push	rcntr

	X_movw	rC0, rA0	; save x
	X_movw	rC2, rA2
	X_movw	rC4, rA4
	X_movw	rC6, rA6

	X_lpm	rcntr, Z+		; load polynom power (3 in our example)
	set						; T as flag to return
	rjmp	.Load8			; load first factor (in our example C3)

.Loop:
	X_movw	rB0, rC0		; restore x (was overwritten by loaded constants Cn)
	X_movw	rB2, rC2
	X_movw	rB4, rC4
	X_movw	rB6, rC6
	
1:
	; rcall __fp64_saveAB
	; clr r0
	; inc r0
	; inc r0
	; cp rcntr, r0
	; breq .L_ret
	; rjmp .L_ret

	push rcntr				; save counter
	push ZL					; save pointer to table, as routines may use Z freely
	push ZH			
	XCALL	_U(fp64_mul)	; create x*Cn (1st run: x*C3, 2nd: (x*C3+C2)*x, 3rd: ((x*C3+C2)*x+C1)*x )
	pop ZH
	pop ZL
	clt
	
.Load8:
	X_lpm	rB7, Z+			; load next constant from program memory
	X_lpm	rB6, Z+
	X_lpm	rB5, Z+
	X_lpm	rB4, Z+
	X_lpm	rB3, Z+
	X_lpm	rB2, Z+
	X_lpm	rB1, Z+
	X_lpm	rB0, Z+
	brts	1b				; return if first use

	; rcall __fp64_saveB

	push ZL					; save pointer to table, as routines may use Z freely
	push ZH			
	XCALL	_U(fp64_add)	; create x*Cn + Cn-1 (1st run: x*C3 + C2, 2nd: (x*C3+C2)*x + C1, 3rd: ((x*C3+C2)*x+C1)*x + C0 )
	pop ZH
	pop ZL

	pop rcntr				; retrieve counter
	; rcall __fp64_saveA
	; clr r0
	; inc r0
	; inc r0
	; cp rcntr, r0
	; breq .L_ret
	; rjmp .L_ret

	dec	rcntr				; 1st Run: 3-->2, 2nd: 2-->1, 3rd 1-->0 = stop
	brne	.Loop			; repeat until all constants processed
	
.L_ret:
	pop	rcntr				; restore used registers and return
	pop	rBE1
	pop	rBE0
	pop	rB0
	pop	rB1
	pop	rB2
	pop	rB3
	pop	rB4
	pop	rB5
	pop	rB6
	pop	rB7
	pop	rC0
	pop	rC1
	pop	rC2
	pop	rC3
	pop	rC4
	pop	rC5
	pop	rC6
	pop	rC7
	ret

ENTRY __fp64_check_powser3
#ifndef CHECK_POWSER
	ret
#else
	ldi ZL, lo8(__testTable3)
	ldi ZH, hi8(__testTable3)
	XJMP _U(__fp64_powser)

__testTable3:
	.byte 0x03	; polynom power = 3 --> 3+1 entries
	.byte 0x3f, 0xd5, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55	; 0x3fd5555555555555 = 0.3333333333333333333
	.byte 0xbf, 0xe0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0xbfe0000000000000 = -0.5
	.byte 0x3f, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0x3ff0000000000000 = 1.0
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0x0000000000000000 = 0.0
	.byte 0x00												; byte needed for code alignment to even adresses!
#endif	
ENTRY __fp64_check_powser2
#ifndef CHECK_POWSER
	ret
#else
	ldi ZL, lo8(__testTable2)
	ldi ZH, hi8(__testTable2)
	XJMP _U(__fp64_powser)

__testTable2:
	.byte 0x02	; polynom power = 2 --> 2+1 entries
	.byte 0xbf, 0xe0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0xbfe0000000000000 = -0.5
	.byte 0x3f, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0x3ff0000000000000 = 1.0
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0x0000000000000000 = 0.0
	.byte 0x00												; byte needed for code alignment to even adresses!
#endif	
ENTRY __fp64_check_powser1
#ifndef CHECK_POWSER
	ret
#else
	ldi ZL, lo8(__testTable1)
	ldi ZH, hi8(__testTable1)
	XJMP _U(__fp64_powser)

__testTable1:
	.byte 0x01	; polynom power = 1 --> 1+1 entries
	.byte 0x3f, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0x3ff0000000000000 = 1.0
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0x0000000000000000 = 0.0
	.byte 0x00												; byte needed for code alignment to even adresses!
#endif	
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
