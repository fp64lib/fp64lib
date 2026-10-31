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
	.byte 0x00, 0xac,0x6a,0x55,0x03,0xbe,0xde,0x6c, 0x03,0xe0 ; +6.27243424679634192716e-10 = +0x2.b1a9540efb79b0p-32
	.byte 0x00, 0xe1,0x35,0x9d,0xb3,0xcf,0x0d,0x1d, 0x03,0xe3 ; +6.55445728908881128856e-09 = +0x1.c26b3b679e1a3ap-28
	.byte 0x00, 0xdc,0x36,0x79,0xb7,0x02,0xb7,0xef, 0x03,0xe7 ; +1.02544573471769459691e-07 = +0x1.b86cf36e056fdep-24
	.byte 0x00, 0xb1,0x47,0x01,0xde,0x4f,0xa9,0x86, 0x03,0xeb ; +1.32081935003077986951e-06 = +0x1.628e03bc9f530cp-20
	.byte 0x00, 0xff,0xe7,0xf4,0x09,0xf0,0x17,0x7e, 0x03,0xee ; +1.52531902484222515509e-05 = +0xf.fe7f409f0177e0p-20
	.byte 0x00, 0xa1,0x84,0x7c,0x77,0x0b,0x31,0x35, 0x03,0xf2 ; +1.54035114465143555532e-04 = +0xa.1847c770b31350p-16
	.byte 0x00, 0xae,0xc3,0xff,0xad,0x9b,0x63,0xc0, 0x03,0xf5 ; +1.33335586615748562245e-03 = +0x5.761ffd6cdb1e00p-12
	.byte 0x00, 0x9d,0x95,0x5b,0x7b,0x64,0xaf,0x7e, 0x03,0xf8 ; +9.61812909879264333821e-03 = +0x2.76556ded92bdf8p-8
	.byte 0x00, 0xe3,0x58,0x46,0xb8,0x34,0xac,0x32, 0x03,0xfa ; +5.55041086657111371744e-02 = +0xe.35846b834ac320p-8
	.byte 0x00, 0xf5,0xfd,0xef,0xfc,0x15,0xf8,0xab, 0x03,0xfc ; +2.40226506959054713491e-01 = +0x3.d7f7bff057e2acp-4
	.byte 0x00, 0xb1,0x72,0x17,0xf7,0xd1,0xcf,0xbc, 0x03,0xfe ; +6.93147180559946229916e-01 = +0xb.17217f7d1cfbc0p-4
	.byte 0x00, 0x80,0x00,0x00,0x00,0x00,0x00,0x00, 0x03,0xff ; +1.00000000000000000000e+00 = +0x1.00000000000000p+0
ENDOBJ .L_table_pow2
