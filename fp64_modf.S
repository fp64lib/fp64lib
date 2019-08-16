/* Copyright (c) 2018  Uwe Bissinger
   Based on 32bit floating point arithmetic routines which are:
   Copyright (c) 2002  Michael Stumpf  <mistumpf@de.pepperl-fuchs.com>
   Copyright (c) 2006,2009  Dmitry Xmelkov
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

/*  float64_t fp64_modff (float64_t x, float64_t *iptr);
	float64_t fp64_modf (float64_t x, float64_t *iptr);

    The fp64_modf() function breaks the argument x into an integral part and a
    fractional part, each of which has the same sign as x. The integral part
    is stored in iptr.
	This implementation skips writing by zero pointer.
	Example: modf(123.45) makes 0.45 (return value) + 123.0 (stored in *iptr)
 */

#define	iptr_lo	r20

	; do special case handling
	; case|	 x	  |	modf |	*iptr
	;-----+-------+------+------
	; 1	  |	NaN	  |	NaN  |	NaN
	; 2	  |	Inf	  |	Inf  |	0.0
	; 3	  |	 0	  |	 0   |	0.0
	; 4	  |	>2^53 |	0.0  |   x
	; 5   | <1.0  |  x   |  0.0

0:	breq 1f		; if Inf
	XCALL _U(__fp64_nan)	; case 1: result = NaN
	movw rB6, rA6			; *iptr = NaN
	movw rB4, rA4
	movw rB2, rA2
	movw rB0, rA0
	rjmp .L_write 
	
1:	XCALL  _U(__fp64_inf)	; case 2: result = Inf
.L_zero:
	clr rB7					; *iptr = 0.0
	bld rB7, 7				; copy sign from x
	clr rB6
	movw rB4, rB6
	movw rB2, rB6
	movw rB0, rB6
	rjmp .L_write

	; case 5: x < 1.0
2:	XCALL _U(__fp64_pretA)	; pack result, fmod(x) = x
	rjmp .L_zero			; *iptr = 0.0
	
.L_nfrc: ; case 4 fabs(x) > 2^53 --> no fraction
	XCALL _U(__fp64_pretA)	; pack result
	movw rB6, rA6			; *iptr = x
	movw rB4, rA4
	movw rB2, rA2
	movw rB0, rA0
	clr rA7					; modf(x) = 0.0
	bld rA7, 7				; copy sign from x
	clr rA6
	movw rA4, rB4
	movw rA2, rB2
	movw rA0, rB0
	rjmp .L_write

ENTRY fp64_modf
ENTRY fp64_modff
	push rB7		; save used registers
	push rB6
	push rB5
	push rB4
	push rB3
	push rB2
	push rB1
	push rB0
	movw XL, ZL		; save iptr
	
	XCALL _U(__fp64_splitA)
	brcs 0b			; NaN or +/i INF
	breq .L_zero	; x = 0? --> return 0
	
	; is there an integral part?
	cpi rAE1, hi8(0x03ff)	; is exponent < 0x3ff, i.e. x < 1.0?
	brlo 2b			; yes, case 5: return x
	brne 3f			; no, break x into parts
	cpi rAE0, lo8(0x03ff)
	brlo 2b
3:	; fabs(x) >= 1.0
	cpi rAE1, hi8(0x3ff+53)	; x > 2^53
	brlo 4f
	brne .L_nfrc
	cpi rAE0, lo8(0x3ff+53)
	brsh .L_nfrc

4:	; fabs(x) > 1.0 and < 2^53, there is a fraction part

  ; Is there a fraction part?
1:	subi	XH, 23
	brsh	4f		; no fraction part

	; check fraction:  B >>= 23 - (exp-127)
	mov	XL, XH		; Now XH is -23..-1
	clr	r0		; to control, is the fraction zero?
2:	lsr	rB2
	ror	rB1
	ror	rB0
	adc	r0, r1
	inc	XL
	brmi	2b
	tst	r0
	breq	.L_nfrc		; fraction == 0
  ; restore and clear fraction:  B <<= 23 - (exp-127)
3:	lsl	rB0
	rol	rB1
	rol	rB2
	inc	XH
	brmi	3b
  ; write B
	rcall	.L_write
  ; return nonzero fraction:  A - B
	XJMP	_U(__subsf3)

	; exponent too big:  compare with smallest NaN (0x7f800001)
4:	cpi	rA0, 1
	cpc	rA1, r1
	ldi	XL, 0x80
	cpc	rA2, XL
	sbci	XH, 128 - 23
	brsh	.L_write	; NaN: write and return as is
  ; fraction == 0

 ;.L_nfrc:
	X_movw	rB0, rA0
	X_movw	rB2, rA2
  ; A = 0.0 with sign
	clr	rA0
	clr	rA1
	clr	rA2
	andi	rA3, 0x80

.L_write:
	adiw	XL, 0		; skip writing with NULL pointer
	breq	99f
	st X+, rB0			; save integral part
	st X+, rB1
	st X+, rB2
	st X+, rB3
	st X+, rB4
	st X+, rB5
	st X+, rB6
	st X+, rB7
	pop rB0				; restore used registers
	pop rB1
	pop rB2
	pop rB3
	pop rB4
	pop rB5
	pop rB6
	pop rB7
	
99:	ret
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
