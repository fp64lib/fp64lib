/* Copyright (c) 2019-2020  Uwe Bissinger
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

/* $Id$ */

#if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

/* float64_t fp64_pow(float64_t x, float64_t y);
     The fp64_pow() function returns the value of x raised to the power of y.

	A \ B|  NaN | +Inf | -Inf |  +0  |  -0  |  +1  | odd>0| any>0| odd<0| any<0 
	-----+------+------+------+------+------+------+------+------+------+------+
	NaN  |      |      |      | +1  a|      | NaN c|      |      |      |      |
	+Inf |      |      |      | +1  a|      |+Inf c|      |      |      |      |
	+0.0 |      |      |      | +1  a|      |+0.0 c|      |      |      |      |
	+1.0 | +1  b| +1  b| +1  b| +1  a| +1  b| +1  c| +1  b| +1  b| +1  b| +1  b|
	> 0  | NaN L|+Inf L| +0  L| +1  L| +1  L|  A  c|  n/a | x^y L| n/a  | x^y L|
	<=-0 | NaN  | NaN  | NaN  | +1  a| NaN  |  A  c| NaN  | NaN  | NaN  | NaN  |
	Not yet implemented:                     
	-0.0 |     d|     d|     d| +1  a|     d|-0.0 c|     d|     d|     d|     d|
	-1.0 |     e|     e|     e| +1  a|     e|-1.0 c|     e|     e|     e|     e|
	-Inf |     f|     f|     f| +1  a|     f|-Inf c|     f|     f|     f|     f|

	remark | method to calculate result
	-------+----------------------------
	   a   | direct check
	   b   | direct check
	   c   | direct check
	   d   | check for integral value
	   e   | check for integral value
	   L   | computed via x^y = exp(log(x)*y)
 */

FUNCTION fp64_pow
.L_one:
	XJMP _U(__fp64_one)			; case 1: return 1.0 for y == 0.0
	
	; result is in rA7...rA0 --> return it
.L_ret:
	ret

ENTRY fp64_pow
GCC_ENTRY __pow
	; ZH.ZL := exponent of y without sign
	movw ZL, rB6				; save exponent and sign
	andi ZH, 0x7f				; get rid of sign bit
	XCALL _U(__fp64_isBzero)	
	cpc ZH, r1					; __fp64_isBzero only checks for rB6..rB0
	breq	.L_one				; y == 0? Yes, case a: return x^+/-0 = +1.0

	; preliminary check for significand of A == 0
	ldi	ZL, 0x3f
	; rcall __fp64_saveAB

	XCALL _U(__fp64_cpc0A5)
	brne 0f						; skip a bit of comparisons
	
	; x == +1.0 ?
	cpi	rA6, 0xf0
	cpc	rA7, ZL
	breq .L_ret					; x == +1.0? Yes, case b: return +1^any = +1.0
	
	; y == 1.0 ?
0:	cpi rB6, 0xf0
	; rcall __fp64_saveAB
	cpc rB7, ZL
	cpc	rB0, r1
	cpc	rB1, r1
	cpc	rB2, r1
	cpc	rB3, r1
	cpc	rB4, r1
	cpc	rB5, r1
	;rcall __fp64_saveAB
	breq .L_ret					; y == +1.0? Yes, case c: return any^1 = any
	
	; x >= 0 ?
	tst	rA7
	brpl .L_pow					; yes, compute x^y via exp(log(x)*y)
    
    ; x < 0, now check if y is an odd/even integer
    ; if x is an odd integer, then pow(x,y) = -pow(abs(x),y)
    ; if x is an even integer, then pow(x,y) = pow(abs(x),y)
    ; for y to be an integer, it has to be in the range of 1 <= y < 2^52
    tst rB7
	brmi .L_nan					; y < 0 --> x^y result undefined
	cpi rB7, 0x3f
	brlo .L_nan					; y < 1 --> x^y result undefined
	brne 7f						; y >= 2, check for y < 2^52
	cpi rB6, 0xf0				
	brlo .L_nan					; y < 1 --> x^y result undefined

7:	cpi rB7, 0x43
	brlo 1f						; y < 2^52, ok
	brne .L_nan					; y > 2^59, not an integer
	cpi rB6, 0x40
	brlo 1f						; 2^49 < y < 2^53, ok
	rjmp .L_nan					; y >= 2^53, not an integer

1:	; here y/B is between 1 and 2^52
	; now check, whether y is an integer
	; first get the exponent of y
	movw rBE0, rB6 				; get exponent from rB7.rB6 into rBE1.rBE0
    andi rBE0, 0xf0 			; get rid of mantissa bits in exponent
  
	lsr  rBE1       			; mov exponent downwards 4 bits
	ror  rBE0		
	lsr  rBE1
	ror  rBE0		
	lsr  rBE1
	ror  rBE0		
	lsr  rBE1
	ror  rBE0
	
	subi rBE0, lo8(1023)		; remove exponent bias: exp -= 1023
	sbci rBE1, hi8(1023)
	; rcall __fp64_saveAB

	; now rBE1.rBE0 is < 53 --> rBE0 is < 53, rBE1 can be used
	mov rBE1, rBE0 				; save the exponent
	
	; we have to separate between rBE0 < 4 and >=4
	push rB7 					; rB7 will now be used as a bitmask for the fraction bits
	ldi rB7, 0x0f				; load mask to be used on rB6 for 0 <= exponent < 4
	cpi rBE0, 4
	brlo 3f
	ldi rB7, 0xff				; load mask to be used on rB5..rB0 for exponent >= 4
	subi rBE0, 4				; round down to nearest 8 bits
	andi rBE0, 0x07
	
3:  ; now rB7 has the mask and rBE0 the exponent mod 8
	; now shift the mask to the right position
	tst rBE0
	breq 4f 					; mask is correct
	lsr rB7
	dec rBE0
	brne 3b

4:	; mask is correct now, some examples
	; rB7.rB6      .rB5
	;  40.0000 immm.mmmm mmmm	2 <= y < 4,		exp = 0x400-0x3ff = 0x01
	;mask 0000 0111 = 0x0f >> 1, start with rB6
	;  40.0010 iiim.mmmm mmmm	8 <= y < 16,	exp = 0x402-0x3ff = 0x03
	;mask 0000 0001 = 0x0f >> 3, start with rB6
	;  40.0011 iiii.mmmm mmmm	16 <= y < 32,	exp = 0x403-0x3ff = 0x04
	;mask           1111 1111 = 0xff >> (4-4), start with rB5
	; now we have to determine where to start the search for a fraction
	mov r0, rB7					; save mask
	cpi rBE1, 4
	brlo 5f						; exp < 4 --> start with rB6
	subi rBE1, (-4)				; round up to next group (exp=4 will get exp=8)

5:	; rcall __fp64_saveAB
	andi rBE1, 0xf8				; truncate lower 3 bits
	  					        ; --> index = (exp/8)*8 as 8 byte are used for mov, mov, and, rjmp
	ldi ZL, lo8(.L_mask)		; add 8*offset to jump table
	add ZL, rBE1		
	ldi ZH, hi8(.L_mask)
	adc ZH, r1					; take care of any overflows
	; rcall __fp64_saveAB
	lsr ZH						; PC addresses words, so divide target address by 2
	ror ZL
	ijmp						; and clear out the bits top to bottom

	; return NaN
.L_nan2:
	pop rB7						; restore used register
	; ldi rBE0, 0xff

.L_nan:							
	; rcall __fp64_saveAB
	XJMP	_U(__fp64_nan)

	; routine for calculating pow(abs(A),B) = abs(A)^B = exp(log(abs(A))*B)
	; inserted here to keep other jumps in reach for rjmp
.L_pow:
	andi	rA7, 0x7f			; convert x to abs(x)
	XCALL _U(__fp64_pushB)
	XCALL	_U(fp64_log)		; log(abs(x))
	XCALL _U(__fp64_popB)
	XCALL	_U(fp64_mul)		; log(abs(x))*y
	XJMP	_U(fp64_exp)		; exp(log(abs(x)))*y = abs(x)^y
	
.L_mask:
	; for 2^1 <= y < 2^4
	mov rBE0, rB6				; fraction starts at rB6
	mov rBE1, rB6				; integer ends in rB6
	and r0, rB6					; if mask & rB6 true --> not an integer
	rjmp .L_a5
	
	; for 2^4 <= y < 2^12
	mov rBE0, rB5				; fraction starts at rB5
	mov rBE1, rB6				; integer might end in rB6
	and r0, rB5
	rjmp .L_a4
	
	; for 2^12 <= y < 2^20
	mov rBE0, rB4
	mov rBE1, rB5
	and r0, rB4
	rjmp .L_a3
	
	; for 2^20 <= y < 2^28
	mov rBE0, rB3
	mov rBE1, rB4
	and r0, rB3
	rjmp .L_a2

	; for 2^28 <= y < 2^36
	mov rBE0, rB2
	mov rBE1, rB3
	and r0, rB2
	rjmp .L_a1

	; for 2^36 <= y < 2^44
	mov rBE0, rB1
	mov rBE1, rB2
	and r0, rB1
	rjmp .L_a0

	; for 2^44 <= y < 2^52
	mov rBE0, rB0
	mov rBE1, rB1
	and r0, rBE0
	rjmp .L_check
	
	; for 2^52 <= y < 2^53
	; special case, there can be no fraction
	mov rBE0, rB0
	mov rBE1, rB0
	and r0, r1
	rjmp .L_check
	
	; r0 contains the first fraction bits
	; now check, there are some more fraction bits set
.L_a5:
	or r0, rB5
.L_a4:
	or r0, rB4
.L_a3:
	or r0, rB3
.L_a2:
	or r0, rB2
.L_a1:
	or r0, rB1
.L_a0:
	or r0, rB0
.L_check:
	; here Z is set if r0<>0 --> y has a fraction
	brne .L_nan2				; if y has a fraction, then x^y is not defined

	; so we have no fraction, now determine whether the number is odd or even
	; rcall __fp64_saveAB
	lsl rB7	   					; goto from the fraction to lower most bit of integer
	brcs 3f						; we have to check the byte above

	; the lower most byte to check is in rBE0
	and rBE0, rB7				; check lower most bit of integer

2:	pop rB7						; restore used rB7
	breq .L_pow					; bit not set --> number is even, x^y = abs(x)^y
	rcall .L_pow				; bit set --> number is odd 
	subi rA7, 0x80				; return -pow(abs(x),y)
	ret 

3:	; we are here because rBE0 contains only fraction bits
	; so we have to check the byte above, i.e. bit 0 of rBE1 as the LSB of the integer
	andi rBE1, 1
	rjmp 2b
	
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
