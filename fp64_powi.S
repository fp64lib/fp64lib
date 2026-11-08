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

/* float64_t fp64_powi (float64_t x, int n);
   return x^n, but more efficient that pow (x, n).

   This function can also be invoked qua GCC's __builtin_powil etc.
   provided [long] double is a 64-bit type.  */

;;; Flags.0: Result sign
;;; Flags.7: expo < 0 ?
#define Flags rB7

FUNCTION fp64_powi
.L_nan:
	cpi r16, 0					; NaN^0 := 1
	cpc r17, r1
	breq 0f						; expo == 0: proceed with C = 0 to return 1.0
	XJMP _U(__fp64_nan)

.L_inf:
	sbiw YL, 0					; (±Inf)^0 := 1
	breq 10f
	XCALL _U(__fp64_inf)
	rjmp .L_finishA				; apply Flags to ±Inf

ENTRY fp64_powi
GCC_ENTRY __powidf2
	XCALL _U(__fp64_splitA)
	brcc 0f						; C = 0: some number: do algorithm
	brne .L_nan					; C = 1, Z = 0: NaN -> NaN

0:	XCALL _U(__fp64_pushCB)
	push YH
	push YL

	X_movw YL, r16				; incoming int16_t expo will live in Y
	andi Flags, 1 << 7			; keep expo sign, notice Flags === r17
	sbrc YL, 0					; expo even -> sign(result) = 0
	bld Flags, 0				; expo odd  -> sign(result) = sign(input)

	brcs .L_inf					; ±Inf? C still from split

	;; Prepare a non-negative expo in Y.
	brpl 10f					; expo < 0 ? N is from the ANDI above
	NEG2 YL						; yes: expo := -expo

10:	;; AX is result, starts with 1.0
	;; BX = X^(2^k), starts with X = X^(2^0)
	mov r0, Flags
	XCALL _U(__fp64_ldb_1)
	XCALL _U(__fp64_swapAB)		; misnamed, does AX <-> BX actually
	mov Flags, r0

.Loop:
	lsr YH						; traverse expo bits, starting at .0
	ror YL
	brcc 20f					; bit == 1 ?

	XCALL _U(__fp64_pushB)
	XCALL _U(__fp64_muldf3_pse)	; yes: Res *= X^2^k
	XCALL _U(__fp64_popB)
	brcs .L_finishA				;      overflow: finish with already packed A

20:	sbiw YL, 0					; all bits consumed?
	brne 25f					; no: continue bit loop

	XCALL _U(__fp64_pretA)		; yes: pack and...

.L_finishA:
	.sbrc_callj Flags, 7		;      apply expo sign and...
	XCALL _U(fp64_inverse)
	bst Flags, 0				;      apply result sign
	bld rA7, 7

	pop YL						;      epilogue
	pop YH
	XJMP _U(__fp64_popBCret)

25:	;; There are still expo bits.  Continue the loop.
	push Flags					; saves for square: Flags, AX
	XCALL _U(__fp64_pushA)
	push rAE0
	push rAE1
	XCALL _U(__fp64_movABx)		; copy X^2^k from BX to AX

	XCALL _U(__fp64_muldf3_pse)	; X^2^k -> (X^2^k)^2 = X^2^(k+1)
	XCALL _U(__fp64_movBAx)		; move X^2^(k+1) to BX
	pop rAE1					; restore rAE (unused in the C = 1 case)
	pop rAE0
	brcc 30f					; overflow?
	XCALL _U(__fp64_popB)		; yes: get rid of 8 pushed A bytes
	pop Flags					;      Flags we have
	rjmp .L_finishA				;      finish with already packed A
30:
	XCALL _U(__fp64_popA)		; no: restores after square
	pop Flags
	rjmp .Loop					;     do them expo bits
ENDFUNC
