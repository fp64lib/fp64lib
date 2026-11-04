/* Copyright (c) 2026  Georg-Johann Lay

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

#include "fp64asm.h"
#include "fp64def.h"

/* float72_t __fp64_divmod2_pse.unsigned (float72_t AX, int8_t P=r25)
   Quotient and remainder of AX mod 2^P, T is unused and unchanged

   Input:
        rA6.rA5.rA4.rA3.rA2.rA1.rA0  rAE1.rAE0 - AX dividend taken non-negative
        rA7 (r25) - int8_t P as binary exponent for a divisor of 2^P
   Return:
        rA6.rA5.rA4.rA3.rA2.rA1.rA0  rAE1.rAE0 - remainder in AX
        XH.XL - uint15_t saturated quotient
        T - untouched

   The algorithm only handles finite numbers.  The returned values satisfy
        quot * 2^P + rem = AX
        0 <= rem < 2^P
        0 <= quot <= 0x7fff = 32767
   Overflowing quotients are saturated to unsigned 15 bits preserving
   the lower 8 bits.
   -  Preserving the low byte is useful in sinpi.
   -  Saturating to unsigned 15 bits means that the quotient doesn't overflow
      when negated, which is useful in the signed variant.
*/

ENTRY __fp64_divmod2_pse.unsigned
	;; Split into quotient and remainder
	;; AX is in the form  AX = 1.M * 2^(Z - 1023)  where M is the 55-bit
	;; fractional part in rA6.6...rA0.0.  Doing mod 2^P means that the
	;; highest fractional bit of the remainder is bitno = Z - 1022 - P.
	X_movw XL, ZL				; calculate bitno X = Z - 1022 - P
	sub XL, rA7
	sbc XH, r1
	sbrc rA7, 7					; post-signextend subtraction
	inc XH
	;; A negative result means that we have 0.0 or subnormal, though
	;; no check is needed here since the next subtract will catch it.
	subi XL, lo8(1022)
	sbci XH, hi8(1022)
	breq .L_small				; bitno <= 0: nothing to do --> A mod 2^P = A
	brmi .L_small
	;; There are only 55 fractional bits.  When bitno exceeds that limit,
	;; then there are no bits left for the remainder.
	cpi XL, 56
	cpc XH, r1
	brge .L_big					; bitno >= 56 --> return remainder 0
	;; XH is dead now (always 0)

	XCALL _U(__fp64_pushB)
	XCALL _U(__fp64_movBA)

#define Cnt XH

	;; AX >>= 56 - bitno
	ldi Cnt, 56
	sub Cnt, XL
	;; Byte shift so that it doesn't take forever.
.Loop_lsr8:
	subi Cnt, 8
	brmi 1f
	mov rA0, rA1
	mov rA1, rA2
	mov rA2, rA3
	mov rA3, rA4
	mov rA4, rA5
	mov rA5, rA6
	clr rA6
	rjmp .Loop_lsr8
1:	subi Cnt, -8

	;; Bit shift:  We only need lo16 and have to perform at most 7 right
	;; shifts, hence the result is somewhere in rA2..rA0.
	breq 2f
.Loop_lsr1:
	lsr rA2
	ror rA1
	ror rA0
	dec Cnt
	brne .Loop_lsr1

2:	;; Saturate quot such that the lower bits are preserved and negating
	;; it doesn't overflow.  The latter is useful in the signed variant,
	;; and the former is useful in sinpi.
	cpi rA1, 0x80
	cpc rA2, r1
	cpc rA3, r1
	cpc rA4, r1
	cpc rA5, r1
	cpc rA6, r1
	brlo 3f
	ldi rA1, 0x7f				; uint15_t saturate keeping the low byte rA0
3:
	push rA0					; save quot
	push rA1

	;; Now work on the remainder: shift AX left XL = bitno bits,
	;; keeping the exponent in sync.
	XCALL _U(__fp64_movAB)

	sub	 ZL, XL					; adjust expo to the following left shift
	sbci ZH, 0

	rjmp 4f
.Loop_lsl1:
	XCALL _U(__fp64_lslA)
4:	dec XL
	brpl .Loop_lsl1

	XCALL _U(__fp64_cpc0A5)		; remainder == 0?
	cpc  r1, rA6
	brne .L_normalize
	X_movw rAE0, rA0			; yes: clear the exponent for 0.0
	rjmp .L_popXBret			;      and return

.L_normalize:					; no: normalize
	.sbrs_callj rA6, 7			;     already normalized?
	XCALL _U(__fp64_norm2)		;     no: normalize A[7] keeping AX.expo in sync

ENTRY __fp64_divmod2_pse.popXBret
.L_popXBret:
	pop XH						; restore quot
	pop XL
	XJMP _U(__fp64_popBret)		; and return

.L_small:
	;; Value x is small such that x mod 2^P = x.
	clr	XL						; quot = 0
	clr XH
	ret

.L_big:
	;; Value x is big such that x mod 2^P = 0.
	XCALL _U(__fp64_zero)
	X_movw 	rAE0, rA0			; AX.expo = 0
	ldi	XL, lo8(0x7fff)			; saturate quot
	ldi	XH, hi8(0x7fff)
	ret
ENDFUNC
