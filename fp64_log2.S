/* Copyright (c) 2019-2025  Uwe Bissinger
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

#include "fp64asm.h"
#include "fp64def.h"

FUNCTION fp64_log2
.L_nf:
	;; check non-finite numbers
	brne .L_nan					; case 2: NaN  --> return NaN
	brts .L_nan					; case 1: -Inf --> return NaN
.L_Tinf:
	XJMP _U(__fp64_inf)			; case 3: +Int --> return +Inf

.L_nan:
	;; cases 1 & 2: return NaN
	XJMP	_U(__fp64_nan)

.L_inf:
	;; case 4: return -Inf for x = 0
	set
	rjmp .L_Tinf

/* float64_t fp64_logb(float64_t x);
   The fp64_logb() function returns the base 2 logarithm of |x|.
   logb(A) = log2(|x|) = log(|x|) / log(2)
 */
ENTRY fp64_logb
ENTRY_DOUBLE logb logbl
	andi rA7, 0x7f				; clear sign
	; let log2 do the rest

	; case|	A	  |	log2(A)
	;-----+-------+-------------------------------
	; 1	  |	< 0   |	NaN		< 0 includes -Inf
	; 2	  |	NaN	  |	NaN
	; 3	  |	+Inf  |	+Inf	-Inf is part of "< 0"
	; 4	  |	0	  |	-Inf
	; 5   | 1     | 0		no special handling needed

/*	float64_t fp64_log2( float64_t x );
	returns logarithmus dualis of x
*/
ENTRY fp64_log2
ENTRY_DOUBLE log2 log2l
	XCALL _U(__fp64_splitA)
	brcs .L_nf					; case 1-3: return NaN for x=NaN, +Inf for +Inf
	breq .L_inf					; case 4: return -Inf for x = 0
	brts .L_nan					; case 1: return NaN for x < 0

	;; case 5: No special handling is needed for x = 1:
	;; x - 1 is exactly 0, and powsodd multiplies the
	;; MiniMax polynomial with (x - 1) / (x + 1), so we
	;; get exactly 0.

	XCALL _U(__fp64_norm2_non0)	; non-zero: normalize if subnormal

	XCALL _U(__fp64_pushCB)		; save the used callee-saved regs
	push YH
	push YL

	push rAE1					; save exponent of x
	push rAE0

	ldi rAE1, 0x03
	ldi rAE0, 0xff				; normalize x to the range [1/sqrt2, sqrt2]

	cpi rA6, 0xb5				; x < sqrt2 = 1.414 = 0xb5 / 2**7 ?
	brlo 22f					; yes --> x already normalized
	sbiw rAE0, 1				; no, divide x by 2 and x is normalized

22:	push rAE0					; save exponent for normalization

	XCALL _U(__fp64_movCA)		; save x (lest rAE1, which is always 0x03)
	push rAE0

	XCALL _U(__fp64_ldb_1)		; load B with 1.0
	XCALL _U(__fp64_add_pse)	; x + 1

	_SWAPW rC6, rA6, rBE0		; save result of x+1 and load A with x
	_SWAPW rC4, rA4, rBE0
	_SWAPW rC2, rA2, rBE0
	_SWAPW rC0, rA0, rBE0
	pop rBE0
	push rAE1					; save exponent of x+1 on stack
	push rAE0
	mov	 rAE0, rBE0				; load exponent of x into A
	ldi  rAE1, 0x03				; rematerialize

	XCALL _U(__fp64_ldb_1)		; load B with 1.0
	clt
	XCALL _U(__fp64_sub_pse)	; x - 1
	bld rA7, 7					; save sign

	XCALL _U(__fp64_movBC)		; restore b = x + 1
	pop rBE0					; restore exponent of x+1
	pop rBE1

	bst rA7, 7					; sign is sign of (x-1), as (x+1) is always > 0
	tst rA6						; is x - 1 == 0?
	breq 23f					; yes, (x-1) / (x+1) is 0
	XCALL _U(__fp64_divdf3_pse)	; y = (x-1) / (x+1); divdf3_pse doesn't handle 0
	bld rA7, 7

	LPMX_INIT XL, .L__tableArtanhq
	XCALL _U(__fp64_powsodd)	; approximate ld(x) = y * L(y^2), L see below
	LPMX_FINI r1

23:	pop r0						; restore normalization exponent
	pop rBE0					; restore exponent
	pop rBE1

	bld rA7, 7
	XCALL _U(__fp64_pushA)		; save result of ld(y)
	push rAE1
	push rAE0

10:	X_movw rA6, rBE0			; convert exponent-base to double
	sub rA6, r0				    ; exponent - bias
	sbci rA7, 0x03

	XCALL _U(__fp64sssd_pse) 	; int16 as a double
	bld rA7, 7

	pop rBE0					; restore B = ld(y)
	pop rBE1
	XCALL _U(__fp64_popB)

	mov r0, rB7					; T has to be sign(A) ^ sign(B)
	eor r0, rA7
	bst r0, 7
	XCALL _U(__fp64_add_pse)	; ld(x * 2^n) = ld(x) + n

99:	pop YL						; restore the used callee-saved registers
	pop YH
	XCALL _U(__fp64_popBC)

	XJMP _U(__fp64_rpretA)		; round, pack and return
ENDFUNC

PGMX_SECTION (fp64.log2)

OBJECT .L__tableArtanhq
	;; Degree 7 MiniMax polynomial with minimal relative error for
	;;     L(x) = 2/ln2 artanh(q)/q
	;; over [0, w^2] where
	;;     q = sqrt(x)
	;;     w = (sqrt2 - 1) / (sqrt2 + 1) = 0.1715
	;;     w^2 = 0.02943
	;; That is:
	;;     y * L(y^2) = 2/ln2 artanh(y)
	;;                = 2/ln2 artanh((x - 1) / (x + 1))  # y = (x - 1) / (x + 1)
	;;                = ln(x) / ln2
	;;                = log2(x)
	;; due to
	;;     ln(x) = 2 artanh((x - 1) / (x + 1))
	.byte 7
	.byte 0x00, 0xda,0xce,0x58,0xf4,0x82,0x6b,0xcc,  -4 ; +2.13677778171227392146e-01 = +0x3.6b3963d209af30p-4
	.byte 0x00, 0xe2,0x36,0x88,0x05,0xc4,0xfd,0xd6,  -4 ; +2.20911145546095109837e-01 = +0x3.88da201713f758p-4
	.byte 0x00, 0x86,0x50,0xb2,0xd3,0x1b,0xec,0x9f,  -3 ; +2.62334430952216417221e-01 = +0x4.32859698df64f8p-4
	.byte 0x00, 0xa4,0x25,0x7d,0xaf,0xae,0x7d,0x64,  -3 ; +3.20598533339984809176e-01 = +0x5.212bed7d73eb20p-4
	.byte 0x00, 0xd3,0x0b,0xb1,0x6b,0x6d,0x6e,0xfd,  -3 ; +4.12198585857110423591e-01 = +0x6.985d8b5b6b77e8p-4
	.byte 0x00, 0x93,0xbb,0x62,0x87,0x71,0xb8,0x7f,  -2 ; +5.77078016345440744650e-01 = +0x9.3bb628771b87f0p-4
	.byte 0x00, 0xf6,0x38,0x4e,0xe1,0xd0,0x23,0xf0,  -2 ; +9.61796693925989876206e-01 = +0xf.6384ee1d023f00p-4
	.byte 0x00, 0xb8,0xaa,0x3b,0x29,0x5c,0x17,0xf1,  +0 ; +2.88539008177792682952e+00 = +0x2.e2a8eca5705fc4p+0
ENDOBJ .L__tableArtanhq
