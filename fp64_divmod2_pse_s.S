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

/* float72_t __fp64_divmod2_pse.signed (float72_t AX, int8_t P=r25, T)
   Quotient and remainder of AX mod 2^P

   Input:
        rA6.rA5.rA4.rA3.rA2.rA1.rA0  rAE1.rAE0 - dividend AX
        T - sign of AX
        rA7 (r25) - int8_t P as binary exponent for a divisor of 2^P
   Return:
        rA6.rA5.rA4.rA3.rA2.rA1.rA0  rAE1.rAE0 - remainder >=0 mod 2^P in AX
        XH.XL - int16_t saturated quotient
        T = 0 - remainder is always non-negative

   The algorithm only handles finite numbers.  The returned values satisfy
        quot * 2^P + rem = AX
        0 <= rem < 2^P
   Overflowing quotients are sign-saturated such that the low byte is
   preserved, which is useful in sinpi.  */

ENTRY __fp64_divmod2_pse.signed
	push rA7					; P
	XCALL _U(__fp64_divmod2_pse.unsigned) ; doesn't touch T
	pop rA7						; P
	brtc .L_ret					; positive input -> positive output
	;; For negative A we have
	;;    -A = |A| = quot * 2^P + rem         	# 0 <= rem < 2^P
	;;     A = (-quot - 1) * 2^P + (2^P - rem)  # if rem > 0
	;;     A = -quot * 2^P                    	# if rem == 0
	;; hence if rem > 0:
	;;     quot' = -quot - 1
	;;     rem'  = 2^P - rem
	com XL						; quot' = -quot - 1, doesn't overflow
	com XH
	XCALL _U(__fp64_cpc0A5)		; remainder == 0?
	cpc  r1, rA6
	breq .L_zero_rem			; yes: return rem unchanged and quot' = -quot

	XCALL _U(__fp64_pushB)		; no: let rem' = 2^P - rem
	push XL						; save quot'
	push XH
	XCALL _U(__fp64_ldb_1)		; BX = 1.0
	add rBE0, rA7				; BX = 2^P
	adc rBE1, r1
	sbrc rA7, 7					; post-signextend addition
	dec rBE1
	ldi	rA7, 0x80				; rA7.7 = sign(rem) := 1 for subtraction
	;; T = sign(A) ^ sign(B) = 1 is already satisfied.
	XCALL _U(__fp64_add_pse)
	clt							; rem' >= 0
	XJMP _U(__fp64_divmod2_pse.popXBret)

.L_zero_rem:
	adiw XL, 1					; quot' = -quot
	clt							; rem >= 0
.L_ret:
	ret
ENDFUNC
