/* Copyright (c) 2018-2020  Uwe Bissinger
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

/* float64_t __fp64_powser (float64_t_intern x, float64_t_intern* XH.XL);
     The __fp64_powser() function calculates the polynom using the horner
	 scheme. As this function operates on internal unpacked data, it
	 does not check for special cases like NaN or Inf. These case have
	 to be handled properly by the caller.
	 
	 Attention: Routine uses all(!) registers, so caller is responsible
	 for saving content of registers

   Input:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0,rAE1.rAE0	- an 'x' arg as float64_t_intern
												  rA7 must contain sign of A
     XH.XL										- table address (in low 64K flash memory)
   Output:
     rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0, rAE1.rAE0	- result, rA7 will contain sign of result

 */

#define	rcntr	r0

ENTRY __fp64_powser
	bld rA7, 7					; save T flag as sign
	XCALL _U(__fp64_movCA)		; save x
	X_movw  YL, rAE0
	
	push ZL						; Z is in use by A
	push ZH
	movw ZL, XL
	lpm	rcntr, Z+				; load polynom power (3 in our example)
	sts .L_saveZ, ZL			; save pointer to table
	sts .L_saveZ+1, ZH
	; rcall __fp64_saveABC
	pop ZH
	pop ZL	
	rcall	.Load10				; load first factor into B (in our example C3)
	
	rjmp 1f

.Loop:
	XCALL _U(__fp64_movBC)		; restore x (was overwritten by loaded constants Cn)
	X_movw  rBE0, YL
	
1:
	push rcntr					; save counter

	mov r0, rB7					; sign of A*B = sign(A)^sign(B)
	eor r0, rA7
	bst r0,7

	; rcall __fp64_saveABC

	push rR5	; save working registers
	push rR6
	push rR7
	push rR8
	push rZero
	XCALL	_U(__fp64_mulsd3_pse)	; create x*Cn (1st run: x*C3, 2nd: (x*C3+C2)*x, 3rd: ((x*C3+C2)*x+C1)*x )
	pop rZero
	pop rR8				; restore used registers and return
	pop rR7
	pop rR6
	pop rR5

	bld rA7, 7					; save sign of result
	brcs .L_ret					; C is set on overflow and result is already packed
	
	rcall .Load10
	mov r0, rB7					; set sign for operation A+B or A-B = sign(A)^sign(B)
	eor r0, rA7
	bst r0,7		

	XCALL	_U(__fp64_add_pse)	; create x*Cn + Cn-1 (1st run: x*C3 + C2, 2nd: (x*C3+C2)*x + C1, 3rd: ((x*C3+C2)*x+C1)*x + C0 )
	bld rA7, 7					; save sign bit

	pop rcntr					; retrieve counter
	brcs .L_ret					; C is set on overflow and result is already packed

	dec	rcntr					; 1st Run: 3-->2, 2nd: 2-->1, 3rd 1-->0 = stop
	brne	.Loop				; repeat until all constants processed
	
.L_ret:
	ret

	; load an unpacked 10 byte number from program memory
	; location will be retrieved from .L_saveZ and .L_saveZ+1
.Load10:
	push ZL
	push ZH
	lds ZL, .L_saveZ			; load table pointer
	lds ZH, .L_saveZ+1
	lpm	rB7, Z+				; load next constant from program memory
	lpm	rB6, Z+
	lpm	rB5, Z+
	lpm	rB4, Z+
	lpm	rB3, Z+
	lpm	rB2, Z+
	lpm	rB1, Z+
	lpm	rB0, Z+
	lpm	rBE1, Z+
	lpm	rBE0, Z+
	sts .L_saveZ, ZL			; save table pointer, now pointing to the next constant
	sts .L_saveZ+1, ZH
	pop ZH
	pop ZL
	ret

#ifdef CHECK_POWSER
.L_nf:	
	brne	.L_nan			; +/-Inf? No --> return NaN
.L_inf:
	XJMP	_U(__fp64_inf)	; No, case 2 --> return Inf
.L_nan:	; x = NaN, case 1 --> return NaN
	XJMP	_U(__fp64_nan)
#endif

ENTRY __fp64_check_powser3
#ifndef CHECK_POWSER
	ret
#else
	push XL
	push XH
	ldi XL, lo8(__testTablex3)
	ldi XH, hi8(__testTablex3)

ENTRY __fp64_check_powsern
98:
	XCALL	_U(__fp64_splitA)
	brcs .L_nf

	XCALL _U(__fp64_pushCB) ; preserve register set
	push YL
	push YH
	XCALL _U(__fp64_powser)
	; rcall __fp64_saveABC

	pop YH
	pop YL
	XCALL _U(__fp64_popBC)	; restore register set

	pop XH
	pop XL
	brcs 99f
	XJMP _U(__fp64_rpretA)
99:	ret

__testTablex3: ; f(x) = ((x/3-0,5)*x+1.0)*x+0 = x^3/3-x^2/2+x
	.byte 0x03	; polynom power = 3 --> 3+1 entries
	;     rB7   rB6   rB5   rB4   rB3   rB2   rB1   rB0   rBE1  rBE0
	.byte 0x00, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0x03, 0xfd	; 0x3fd5555555555555 = 0.3333333333333333333
	.byte 0x80, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xfe	; 0xbfe0000000000000 = -0.5
	.byte 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xff	; 0x3ff0000000000000 = 1.0
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0x0000000000000000 = 0.0
	.byte 0x00												; byte needed for code alignment to even adresses!
#endif	
ENTRY __fp64_check_powser2
#ifndef CHECK_POWSER
	ret
#else
	push XL
	push XH
	ldi XL, lo8(__testTablex2)
	ldi XH, hi8(__testTablex2)
	rjmp 98b

__testTablex2: ; f(x) = (x*-0,5+1.0)*x+0 = -x^2/2 + x
	.byte 0x02	; polynom power = 2 --> 2+1 entries
	.byte 0x80, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xfe	; 0xbfe0000000000000 = -0.5
	.byte 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xff	; 0x3ff0000000000000 = 1.0
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0x0000000000000000 = 0.0
	.byte 0x00												; byte needed for code alignment to even adresses!
#endif	
ENTRY __fp64_check_powser1
#ifndef CHECK_POWSER
	ret
#else
	push XL
	push XH
	ldi XL, lo8(__testTablex1)
	ldi XH, hi8(__testTablex1)
	rjmp 98b

__testTablex1: ; f(x) = x*1+0 = x
	.byte 0x01	; polynom power = 1 --> 1+1 entries
	.byte 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xff	; 0x3ff0000000000000 = 1.0
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 0x0000000000000000 = 0.0
	.byte 0x00												; byte needed for code alignment to even adresses!
#endif	
ENDFUNC

.data
ENTRY __fp64_saveZ
.L_saveZ:	.skip 2			; scratch area to save pointer to table
#endif /* !defined(__AVR_TINY__) */
