/* Copyright (c) 2019-2026  Uwe Bissinger
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

/* float64_t fp64_exp (float64_t x);
	 The fp64_exp() function returns the value of e (the base of natural
	 logarithms) raised to the power of x.
 */

FUNCTION fp64_exp

	; Special cases
	; case| A	  | exp(A)
	;-----+-------+-------
	; 1	  | NaN	  | NaN
	; 2	  | +Inf  | +Inf
	; 3	  | -Inf  | 0
	; 4	  | 0	  | 1 no extra handling needed

.L_nf:
	XJMP _U(__fp64_pow2_nf)

ENTRY fp64_exp
ENTRY_DOUBLE exp expl
	;; split and analyse A
	XCALL _U(__fp64_splitA)
	brcs .L_nf					; A is not finite?

	XCALL _U(__fp64_pushCB)     ; preserve registers
	rcall .Ldb_1_o_ln2
	XCALL _U(__fp64_muldf3_pse)	; e^x = 2^{x / ln2}
	XCALL _U(__fp64_popBC)      ; restore registers
	brcs 0f						; packed / overflow result?
	XJMP  _U(__fp64_pow2_pse)
0:	ret

.Ldb_1_o_ln2:
	push ZL
	push ZH
	LPMX_INIT ZL, .L_const_1_o_ln2
	XJMP _U(__fp64_ldb_const)
ENDFUNC

PGMX_SECTION (fp64.expx)

;;; 1 / ln2 with 56 bits precision in unpacked format
OBJECT .L_const_1_o_ln2
	.byte 0x00, 0xb8,0xaa,0x3b,0x29,0x5c,0x17,0xf1, 0x03,0xff ; +1.44269504088896341476e+00 = +0x1.71547652b82fe2p+0
ENDOBJ .L_const_1_o_ln2
