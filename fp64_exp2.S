/* Copyright (c) 2022-2026  Uwe Bissinger
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

/* float64_t fp64_exp2 (float64_t x);
	 The fp64_exp2() function returns the value of 2
	 raised to the power of x, i.e. 2^x.
 */

FUNCTION fp64_exp2

	;; Special cases
	;; case | A     | powx(A)
	;;------+-------+---------------------------
	;; 1    | NaN   | NaN
	;; 2    | +Inf  | +Inf
	;; 3    | -Inf  | 0
	;; 4    | 0     | 1 no extra handling needed

ENTRY __fp64_pow2_nf
.L_nf:
	brne	.L_nan				; +/-Inf? No --> return NaN
.L_big:
	brtc	.L_inf				; -Inf? No --> return +Inf
.L_zr:							; yes, case 3 --> return 0
	XJMP	_U(__fp64_zero)

.L_nan:							; x = NaN, case 1 --> return NaN
	XJMP	_U(__fp64_nan)

.L_inf:
	XJMP	_U(__fp64_inf)		; No, case 2 --> return Inf

ENTRY fp64_exp2
ENTRY fp64_pow2
ENTRY_DOUBLE exp2 exp2l
ENTRY_DOUBLE pow2 pow2l
	;; split and analyse A
	XCALL _U(__fp64_splitA)
	brcs .L_nf					; A is not finite: C = 1 means packed
	;; FALLTHRU

/* float64_t __fp64_pow2_pse (float72_t AX, T)
   Similar to fp64_pow2, but operates on the unpacked format in
   AX = rA6..rA0  rAE1.rAE0  and the sign of AX passed in T.
   Handles only finite values.  Used by fp64_exp and fp64_pow10.

   Implemented as  2^x = ldexp (2^{AX mod 1}, floor AX)
   where 0 <= AX mod 1 < 1.  */

ENTRY __fp64_pow2_pse
	ldi rA7, 0					; do mod 2^0
	XCALL _U(__fp64_divmod2_pse.signed) ; quot in X, rem in AX
	push YL
	push YH
	push XL						; save quot
	push XH
	XCALL _U(__fp64_pushCB)
	LPMX_INIT XL, .L_table_pow2
	XCALL _U(__fp64_powser)		; packed result, overflow (C = 1) doesn't occur
	XCALL _U(__fp64_popBC)
	XCALL _U(__fp64_rpretA)		; deflate
	;; Scale A with 2^quot.
	X_movw YL, r16				; preserve R16
	pop r17						; pass quot to ldexp
	pop r16
	XCALL _U(fp64_ldexp)		; A *= 2^quot
	X_movw r16, YL				; restore R16
	pop YH						; restore Y
	pop YL
	ret
ENDFUNC

PGMX_SECTION (fp64.exp2)

OBJECT .L_table_pow2
	;; Degree 11 MiniMax polynomial with minimal relative error for
	;; 2^x over [0, 1].
	.byte 11
	.byte C(+, 0xad,0x47,0xc7,0x95,0xa4,0x16,0xa4, -31) ; +6.30390383478953771095e-10 = +0x2.b51f1e56905a94p-32
	.byte C(+, 0xe0,0x9e,0x7a,0x13,0x76,0xd9,0x82, -28) ; +6.53727475531706917934e-09 = +0x1.c13cf426edb304p-28
	.byte C(+, 0xdc,0x4c,0xbb,0x0a,0x57,0x86,0x9e, -24) ; +1.02585055404333322506e-07 = +0x1.b8997614af0d3ep-24
	.byte C(+, 0xb1,0x45,0x28,0x33,0x7e,0xae,0xb8, -20) ; +1.32076550029884989541e-06 = +0x1.628a5066fd5d72p-20
	.byte C(+, 0xff,0xe8,0x24,0xe4,0x8e,0xfd,0xfe, -17) ; +1.52532346808647047454e-05 = +0xf.fe824e48efdff0p-20
	.byte C(+, 0xa1,0x84,0x7a,0xd9,0x3d,0x69,0xe2, -13) ; +1.54035090943119539196e-04 = +0xa.1847ad93d69e30p-16
	.byte C(+, 0xae,0xc3,0xff,0xbf,0x2a,0xa9,0x32, -10) ; +1.33335587414269148921e-03 = +0x5.761ffdf9554990p-12
	.byte C(+, 0x9d,0x95,0x5b,0x7a,0xed,0xf9,0x74,  -7) ; +9.61812909710565728388e-03 = +0x2.76556debb7e5d0p-8
	.byte C(+, 0xe3,0x58,0x46,0xb8,0x38,0x52,0x90,  -5) ; +5.55041086659186092347e-02 = +0xe.35846b83852910p-8
	.byte C(+, 0xf5,0xfd,0xef,0xfc,0x15,0xe9,0xf8,  -3) ; +2.40226506959041661432e-01 = +0x3.d7f7bff057a7e4p-4
	.byte C(+, 0xb1,0x72,0x17,0xf7,0xd1,0xcf,0xd2,  -1) ; +6.93147180559946549105e-01 = +0xb.17217f7d1cfd30p-4
	.byte C(+, 0x80,0x00,0x00,0x00,0x00,0x00,0x00,  +0) ; +1.00000000000000000000e+00 = +0x1.00000000000000p+0
ENDOBJ .L_table_pow2
