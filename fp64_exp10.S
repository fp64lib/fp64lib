/* Copyright (c) 2020-2026  Uwe Bissinger
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

/* float64_t fp64_exp10 (float64_t x);
	 The fp64_exp10() function returns the value of 10
	 raised to the power of x, i.e. 10^x.
 */

FUNCTION fp64_exp10

	;; Special cases
	;; case | A     | pow10(A)
	;;------+-------+--------------------------
	;; 1    | NaN   | NaN
	;; 2    | +Inf  | +Inf
	;; 3    | -Inf  | 0
	;; 4    | 0     | 1 no extra handling needed

.L_nf:
	XJMP	_U(__fp64_pow2_nf)

ENTRY fp64_exp10
ENTRY fp64_pow10
ENTRY_DOUBLE exp10 exp10l
ENTRY_DOUBLE pow10 pow10l
	;; split and analyse A
	XCALL _U(__fp64_splitA)
	brcs .L_nf					; A is not finite: C = 1 means packed

	XCALL _U(__fp64_pushCB)     ; preserve registers
	rcall .Ldb_ln10_o_ln2
	XCALL _U(__fp64_muldf3_pse)	; 10^x = 2^{x * ln10 / ln2}
	XCALL _U(__fp64_popBC)      ; restore registers
	brcs 0f						; packed / overflow result?
	XJMP  _U(__fp64_pow2_pse)
0:	ret

.Ldb_ln10_o_ln2:
	push ZL
	push ZH
	LPMX_INIT ZL, .L_const_ln10_o_ln2
	XJMP _U(__fp64_ldb_const)
ENDFUNC

PGMX_SECTION (fp64.exp10)

OBJECT .L_const_ln10_o_ln2
	;; ln(10) / ln(2) with 56 bits precision in unpacked format.
	;; "+ 6" added by hand to counteract finite precision artifacts.
	.byte 0x00, 0xd4,0x9a,0x78,0x4b,0xcd,0x1b,0x8b + 6, 0x04,0x00 ; +3.32192809488736234824e+00 = +0x3.5269e12f346e2cp+0
ENDOBJ .L_const_ln10_o_ln2
