/* Copyright (c) 2018-2020  Uwe Bissinger
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

#include "fp64def.h"
#include "asmdef.h"

/*	float64_t fp64_log( float64_t x );
	returns the natural logarithm ln of x
*/
FUNCTION fp64_log

	; case|	A	  |	log(A)
	;-----+-------+------
	; 1	  |	< 0   |	NaN		< 0 includes -Inf
	; 2	  |	NaN	  |	NaN
	; 3	  |	+Inf  |	+Inf	-Inf is part of "< 0"
	; 4	  |	0	  |	-Inf
	; 5   | 1     | 0		this case was included to avoid nasty rounding

	; check non-finite numbers
.L_nf:
	brne .L_nan					; case 2: NaN  --> return NaN
	brts .L_nan					; case 1: -Inf --> return NaN
	XJMP _U(__fp64_inf)			; case 3: +Int --> return +Inf
	
	; cases 1 & 2: return NaN
.L_nan:
	XJMP	_U(__fp64_nan)
	
	; case 4: return -Inf for x = 0
.L_inf:
	set
	XJMP _U(__fp64_inf)
	
	; case 5: return 0.0 for x = 1.0
.L_zero:	; return 0.0
	XJMP _U(__fp64_zero)
	
/*	float64_t fp64_log( float64_t x );
	returns the natural logarithm ln of x
*/
ENTRY fp64_log
GCC_ENTRY __log
	XCALL _U(__fp64_splitA)
	brcs .L_nf					; case 1-3: return NaN for x=NaN,-Inf, +Inf for +Inf
	breq .L_inf					; case 4: return -Inf for x = 0
	brts .L_nan					; case 1: return NaN for x < 0
	
	XCALL _U(__fp64_cmp_1)
	breq .L_zero				; case 5: return 0 for x == 1

	tst rA6						; subnormal number?
	brmi 2f
	XCALL _U(__fp64_norm2)		; yes, normalize it
	
2:	
	XCALL _U(__fp64_pushCB)		; as all registers may be used, save them
	push YH
	push YL
	push XH
	push XL

	push rAE1					; save exponent of x
	push rAE0

	ldi rAE1, 0x03
	ldi rAE0, 0xff				; normalize x to be in range [1/sqrt(2)..sqrt(2)]

	cpi rA6, 0xb5				; x < sqrt(2) = 1.414 = 0xb5 / 2**7 ?
	brlo 22f					; yes --> x already normalized
	sbiw rAE0, 1				; no, divide x by 2 and x is normalized

22:	; rcall __fp64_saveAB
	push rAE0					; save exponent for normalization
	
	XCALL _U(__fp64_movCA)		; save x
	push rAE1
	push rAE0

	XCALL _U(__fp64_ldb_1)		; load B with 1.0
	XCALL _U(__fp64_add_pse)	; x + 1
	
	_SWAPW rC6, rA6				; save result of x+1 and load A with x
	_SWAPW rC4, rA4
	_SWAPW rC2, rA2
	_SWAPW rC0, rA0
	clr r1
	pop rBE0
	pop rBE1
	push rAE1					; save exponent of x+1 on stack
	push rAE0
	movw rAE0, rBE0				; load exponent of x into A
	
	XCALL _U(__fp64_ldb_1)		; load B with 1.0
	clt
	XCALL _U(__fp64_sub_pse)	; x - 1
	bld rA7, 7					; save sign
	
	XCALL _U(__fp64_movBC)		; restore b = x + 1
	pop rBE0					; restore exponent of x+1
	pop rBE1
	
	bst rA7, 7					; sign is sign of (x-1), as (x+1) is always > 0
	tst rA6						; is (x-1) == 0?
	breq 23f					; yes, (x-1) / (x-1) is also 0 (__fp64_divsd3_pse does not handle 0)
	XCALL _U(__fp64_divsd3_pse)	; y = (x-1) / (x+1)
	bld rA7, 7
	; rcall __fp64_saveAB

	ldi XL, lo8(.L__tableLog)
	ldi XH, hi8(.L__tableLog)
	XCALL _U(__fp64_powsodd)	; approximate log(y) = log((x-1)/(x+1)) by power series
	; rcall __fp64_saveAB
23:	
	pop r0						; restore normalization exponent
	pop rBE0					; restore exponent			
	pop rBE1

	bld rA7,7
	XCALL _U(__fp64_pushA)		; save result of log(y)
	push rAE1
	push rAE0
	
10:	
	movw rA6, rBE0				; convert exponent-base into float64_t
	sub rA6, r0				    ; exponent - base
	sbci rA7, 0x03
	
	XCALL _U(__fp64sssd_pse) 	; int16 as a float
	XCALL _U(__fp64_ldb_log2)	; B = log(2)
	bld rA7, 7
	; rcall __fp64_saveAB
	XCALL _U(__fp64_mulsd3_pse)	
	
	pop rBE0					; restore B = log(y)
	pop rBE1
	XCALL _U(__fp64_popB)
	
	mov r0, rB7					; T has to be sign(A) ^ sign(B)
	eor r0, rA7
	bst r0,7
	; rcall __fp64_saveAB
	XCALL _U(__fp64_add_pse)	; log(x*2^n) = log(x)+n*log(2)

99:	
	pop XL						; restore all used registers
	pop XH
	pop YL
	pop YH
	XCALL _U(__fp64_popBC)
	
	XJMP _U(__fp64_rpretA)		; round, pack and return

.L__tableLog:
	.byte 7		; polynom power = 7 --> 8 entries
	.byte 0x00, 0x98, 0x04, 0x81, 0xD8, 0x93, 0x16, 0x2F, 0x03, 0xfc ; 0x3FC300903B1262C6 = 0.14845469364515489619496639294147651679382323
	.byte 0x00, 0x9C, 0xC3, 0xCA, 0xA0, 0x36, 0xDF, 0x02, 0x03, 0xfc ; 0x3FC398795406DBE0 = 0.15309063532706002857400705916802964525460117
	.byte 0x00, 0xBA, 0x33, 0xA4, 0xA8, 0x2D, 0xCB, 0x87, 0x03, 0xfc ; 0x3FC746749505B971 = 0.18183762814028228319319571146839576150306150
	.byte 0x00, 0xE3, 0x8E, 0x26, 0x5C, 0x1C, 0x31, 0x75, 0x03, 0xfc ; 0x3FCC71C4CB83862F = 0.22222194611735930977980985605447216481620959
	.byte 0x00, 0x92, 0x49, 0x24, 0xA4, 0x88, 0x92, 0x50, 0x03, 0xfd ; 0x3FD249249491124A = 0.28571428783860553210658222441345541743520204
	.byte 0x00, 0xCC, 0xCC, 0xCC, 0xCC, 0xBB, 0x2B, 0xC5, 0x03, 0xfd ; 0x3FD9999999976579 = 0.39999999999198324890372309941486219658990021
	.byte 0x00, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAD, 0xE9, 0x03, 0xfe ; 0x3FE55555555555BD = 0.66666666666667818373685193388291900221762915
	.byte 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00 ; 0x4000000000000000 = 1.9999999999999999972866132948540368981897486 
	.byte 0x00												; byte needed for code alignment to even adresses!
	
ENDFUNC
	