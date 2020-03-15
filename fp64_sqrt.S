/* Copyright (c) 2018-2020  Uwe Bissinger
   Based on 32bit floating point arithmetic routines which are:
   Copyright (c) 2002  Michael Stumpf  <mistumpf@de.pepperl-fuchs.com>
   Copyright (c) 2006  Dmitry Xmelkov
   Copyright (c) 2008  Ruud v Gessel
   
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

#if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

/*  float64_t fp64_sqrt (float64_t);
    Square root function.
 */

 
FUNCTION fp64_sqrt
	// Special cases
	// sqrt(NaN) = NaN
	// sqrt(+Inf) = +Inf
	// sqrt(-Inf) = NaN
	// sqrt(+-0) = +-0

0:	brne	.L_NaN		; not Inf --> NaN, return as is
	brtc	.L_inf		; sqrt(+Inf) --> +Inf
.L_NaN:	XJMP	_U(__fp64_nan)
.L_inf:	XJMP	_U(__fp64_inf)
.L_zr:	XJMP	_U(__fp64_szero)

ENTRY fp64_sqrt
GCC_ENTRY __sqrt
ALIAS_ENTRY fp64_sqrtf
  ; split and check arg.
	XCALL	_U(__fp64_splitA)
	; call __fp64_saveA
	brcs	0b		; !isfinite(A)
	breq	.L_zr	; return 0 with original sign
	brts	.L_NaN	; sqrt(negative) --> NaN

	;call __fp64_saveA
	; normalize, if A is subnormal
	sbrs	rA6, 7
	XCALL	_U(__fp64_norm2)
	;call __fp64_saveA
	
	rcall __fp64_sqrt_pse		; call the internal worker routine
	
	XJMP _U(__fp64_rpretA)		; round, pack and return A

	
ENTRY __fp64_sqrt_pse

#define	msk6	rA7
#define msk5	rR5
#define msk4	rR6
#define msk3	rR7
#define msk2	rR8
#define msk1	rBE1
#define msk0	rBE0
#define tv		r0

	; exponent bias
	subi rAE0, lo8(1023)
	sbci rAE1, hi8(1023)

	push msk5		; save temp registers
	push msk4
	push msk3
	push msk2
	push rB0
	push rB1
	push rB2
	push rB3
	push rB4
	push rB5
	push rB6

	ldi	msk6, 0x60	; Initial rotation mask   =
					;	01100000.00000000...00000000
	clr	msk5
	clr msk4
	X_movw msk2, msk4
	X_movw msk0, msk4
	
	ldi	rB6, 0xa0		; Initial developing root =
						;	10100000.00000000...00000000
	X_movw	rB4, msk0	
	X_movw	rB2, msk0	
	X_movw	rB0, msk0	

	clr	tv			; Test value for end of loop
	subi rA6, 0x40	; Initial remainder for odd exponent
	asr	rAE1
	ror	rAE0		; Divide exponent by 2, C==>exponent was odd
	; call __fp64_saveA
	brcs	3f		; Jump for odd exponent in argument

	subi rA6, 0x40	; Initial remainder for even exponent, C=0

  ; Loop for all 53 bits + 3 safety bits
.Loop:	brcc	2f		; NC --> nope, bit is 0
	cp	msk6, tv	; Only needed to get the proper rounding
					;   for ffffff
	sbc	rA0, rB0	; Prepare remainder argument for next bits
	sbc	rA1, rB1
	sbc	rA2, rB2
	sbc	rA3, rB3
	sbc	rA4, rB4
	sbc	rA5, rB5
	sbc	rA6, rB6
	
	or	rB0, msk0	; Set developing bit to 1
	or	rB1, msk1
	or	rB2, msk2
	or	rB3, msk3
	or	rB4, msk4
	or	rB5, msk5
	or	rB6, msk6
	
2:	lsr	msk6		; Shift right mask, C --> end loop
	ror	msk5
	ror	msk4
	ror	msk3
	ror	msk2
	ror	msk1
	ror	msk0
	rol	tv			; Bit 1 set if end of loop
	
	eor	rB0, msk0	; Shift right test bit in developing root
	eor	rB1, msk1
	eor	rB2, msk2
	eor	rB3, msk3
	eor	rB4, msk4
	eor	rB5, msk5
	eor	rB6, msk6
	
3:	XCALL _U(__fp64_lslA)	; Shift left remainder argument (C used at .Loop)
	brcs	4f
	
	XCALL _U(__fp64_cpcBA)

4:	sbrs	tv, 1
	rjmp	.Loop

	X_movw	rA0, rB0	; copy result from rB6.rB5...rB0 to A
	X_movw	rA2, rB2	
	X_movw	rA4, rB4	
	mov	rA6, rB6
	
	pop rB6
	pop rB5
	pop rB4
	pop rB3
	pop rB2
	pop rB1
	pop rB0

	pop msk2			; restore temporarely used registers
	pop msk3
	pop msk4
	pop msk5

	subi	rAE0, lo8(-1023)	; adjust to exponent bias
	sbci	rAE1, hi8(-1023)
	
	ret
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
