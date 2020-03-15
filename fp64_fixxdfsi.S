/* Copyright (c) 2019-2020  Uwe Bissinger
   Partly based on 32bit floating point arithmetic routines which are:
   Copyright (c) 2002  Michael Stumpf  <mistumpf@de.pepperl-fuchs.com>
   Copyright (c) 2007  Dmitry Xmelkov
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

/* 64 bit *********************************************************************/
/* long long __fp64_fixsddi( float64_t A );
   long long fp64_to_int64( float64_t A );
    The fp64_to_int64() function converts A to the signed integer value, 
	rounding towards 0, the fractional part is lost. No saturation. 
	Besides a normal 64-bits value, the carry is returned as extra error flag.
	input:	rA7...rA0	number to convert
	output:	rA7..rA0	64-bit signed integer
			C			carry as flag of error for indicating NaN or overflow
			
	special case matrix for fp64_to_int64
	case| A	        | C	| result
	----+-----------+---+-------------------
	  1 | NaN       | 1	| 0x0000000000000000
	  2 | Inf       | 1	| 0x0000000000000000
	  3 | |x|>=2^63 | 1	| 0x0000000000000000
	  4 | 0<|x|<1.0 | 0	| 0x0000000000000000
	  5 | |A|<2^63  | 0	| (long long) A
 */

FUNCTION __fp64_fixsddi
GCC_ENTRY __fixdfdi
ENTRY fp64_to_int64
	push rBE0
	ldi rBE0, 63
	XJMP _U(__fp64_fixxdfxi)
	
/* unsigned long long __fp64_fixunssddi( float64_t A );
   unsigned long long fp64_to_uint64( float64_t A );
    The fp64_to_uint64() function converts A to the unsigned integer value, 
	rounding towards 0, the fractional part is lost. No saturation.
	Negative input is permissable (like GCC/x86). 
	Besides a normal 64-bits value, the carry is returned as extra error flag.
	input:	rA7...rA0	number to convert
	output:	rA7..rA0	32-bit unsigned integer
			C			carry as flag of error fr indicating NaN or overflow
			
	special case matrix for fp64_to_uint64
	case| A	        | C	| result
	----+-----------+---+------------
	  1 | NaN       | 1	| 0x0000000000000000
	  2 | Inf       | 1	| 0x0000000000000000
	  3 | |x|>=2^64 | 1	| 0x0000000000000000
	  4 | 0<|x|<1.0 | 0	| 0x0000000000000000
	  5 | 0<A<2^64  | 0	| (unsigned long long) A
	  6 | -2^64<A<0 | 0	| -((unsigned long long) (-A)
 */

GCC_ENTRY __fixunsdfdi
ENTRY fp64_to_uint64
	push rBE0
	ldi rBE0, 64
	XJMP _U(__fp64_fixxdfxi)
	
/* 16 bit *********************************************************************/
/* int __fp64_fixsdsi( float64_t A );
   int fp64_to_int16( float64_t A );
    The fp64_to_int16() function converts A to the signed integer value, 
	rounding towards 0, the fractional part is lost. No saturation. 
	Besides a normal 16-bits value, the carry is returned as extra error flag.
	input:	rA7...rA0	number to convert
	output:	rA7..rA6	16-bit signed integer
			C			carry as flag of error for indicating NaN or overflow
			
	special case matrix for __fp64_fixdfss
	case| A	        | C	| result
	----+-----------+---+------------
	  1 | NaN       | 1	| 0x0000
	  2 | Inf       | 1	| 0x0000
	  3 | |x|>=2^15 | 1	| 0x0000
	  4 | 0<|x|<1.0 | 0	| 0x0000
	  5 | |A|<2^15  | 0	| (int) A
 */

GCC_ENTRY __fixdfsi
ENTRY fp64_to_int16
	push rBE0
	ldi rBE0, 15
	XJMP _U(__fp64_fixxdfxi)
	
/* unsigned int __fp64_fixunssdsi( float64_t A );
   unsigned int fp64_to_uint16( float64_t A );
    The fp64_to_uint16() function converts A to the unsigned integer value, 
	rounding towards 0, the fractional part is lost. No saturation.
	Negative input is permissable (like GCC/x86). 
	Besides a normal 16-bits value, the carry is returned as extra error flag.
	input:	rA7...rA0	number to convert
	output:	rA7..rA6	16-bit unsigned integer
			C			carry as flag of error fr indicating NaN or overflow
			
	special case matrix for __fp64_fixunsdfss
	case| A	        | C	| result
	----+-----------+---+------------
	  1 | NaN       | 1	| 0x0000
	  2 | Inf       | 1	| 0x0000
	  3 | |A|>=2^16 | 1	| 0x0000
	  4 | 0<|A|<1.0 | 0	| 0x0000
	  5 | 0<A<2^16  | 0	| (unsigned int) A
	  6 | -2^16<A<0 | 0	| -((unsigned int) (-A)
 */

GCC_ENTRY __fixunsdfsi
ENTRY fp64_to_uint16
	push rBE0
	ldi rBE0, 16
	XJMP _U(__fp64_fixxdfxi)
	
/*  8 bit *********************************************************************/
/* char __fp64_fixsdsc( float64_t A );
   char fp64_to_int8( float64_t A );
    The fp64_to_int8() function converts A to the signed integer value, 
	rounding towards 0, the fractional part is lost. No saturation. 
	Besides a normal 8-bits value, the carry is returned as extra error flag.
	input:	rA7...rA0	number to convert
	output:	rA6	(!)		8-bit signed integer
			C			carry as flag of error for indicating NaN or overflow
			
	special case matrix for fp64_to_int8
	case| A	        | C	| result
	----+-----------+---+------------
	  1 | NaN       | 1	| 0x00
	  2 | Inf       | 1	| 0x00
	  3 | |x|>=2^7  | 1	| 0x00
	  4 | 0<|x|<1.0 | 0	| 0x00
	  5 | |A|<2^7   | 0	| (char) A
 */

ENTRY __fp64_fixsdsc
ENTRY fp64_to_int8
	push rBE0
	ldi rBE0, 7
	XJMP _U(__fp64_fixxdfxi)
	
/* unsigned char __fp64_fixunssdsc( float64_t A );
   unsigned char fp64_to_uint8( float64_t A );
    The fp64_to_uint8() function converts A to the unsigned integer value, 
	rounding towards 0, the fractional part is lost. No saturation.
	Negative input is permissable (like GCC/x86). 
	Besides a normal 8-bits value, the carry is returned as extra error flag.
	input:	rA7...rA0	number to convert
	output:	rA6	(!)		8-bit unsigned integer
			C			carry as flag of error fr indicating NaN or overflow
			
	special case matrix for fp64_to_uint8
	case| A	        | C	| result
	----+-----------+---+------------
	  1 | NaN       | 1	| 0x00
	  2 | Inf       | 1	| 0x00
	  3 | |A|>=2^8 | 1	| 0x00
	  4 | 0<|A|<1.0 | 0	| 0x00
	  5 | 0<A<2^8  | 0	| (unsigned char) A
	  6 | -2^8<A<0 | 0	| -((unsigned char) (-A)
 */

ENTRY __fp64_fixunssdsc
ENTRY fp64_to_uint8
	push rBE0
	ldi rBE0, 8
	XJMP _U(__fp64_fixxdfxi)
	
/* 32 bit *********************************************************************/
/* long __fp64_fixsdli( float64_t A );
   long fp64_float64_to_long( float64_t A );
   long fp64_to_int32( float64_t A );
    The fp64_to_int32() function converts A to the signed integer value, 
	rounding towards 0, the fractional part is lost. No saturation. 
	Besides a normal 32-bits value, the carry is returned as extra error flag.
	input:	rA7...rA0	number to convert
	output:	rA7..rA4	32-bit unsigned integer
			C			carry as flag of error for indicating NaN or overflow
			
	special case matrix for fp64_to_int32
	case| A	        | C	| result
	----+-----------+---+------------
	  1 | NaN       | 1	| 0x00000000
	  2 | Inf       | 1	| 0x00000000
	  3 | |A|>=2^31 | 1	| 0x00000000
	  4 | 0<|A|<1.0 | 0	| 0x00000000
	  5 | |A|<2^31  | 0	| (long) A
 */

ENTRY __fp64_fixsdli
ENTRY fp64_to_int32
ENTRY fp64_float64_to_long
	push rBE0
	ldi rBE0, 31
	XJMP _U(__fp64_fixxdfxi)
	
/* unsigned long __fp64_fixunssdli( float64_t A );
   unsigned long fp64_to_uint32( float64_t A );
    The fp64_to_uint32() function converts A to the unsigned integer value, 
	rounding towards 0, the fractional part is lost. No saturation.
	Negative input is permissable (like GCC/x86). 
	Besides a normal 32-bits value, the carry is returned as extra error flag.
	input:	rA7...rA0	number to convert
	output:	rA7..rA4	32-bit unsigned integer
			C			carry as flag of error fr indicating NaN or overflow
			
	special case matrix for fp64_to_uint32
	case| A	        | C	| result
	----+-----------+---+------------
	  1 | NaN       | 1	| 0x00000000
	  2 | Inf       | 1	| 0x00000000
	  3 | |A|>=2^32 | 1	| 0x00000000
	  4 | 0<|A|<1.0 | 0	| 0x00000000
	  5 | 0<A<2^32  | 0	| (unsigned long) A
	  6 | -2^32<A<0 | 0	| -((unsigned long) (-A)
 */

ENTRY __fp64_fixunssdli
ENTRY fp64_to_uint32
	push rBE0
	ldi rBE0, 32

/* nn bit *********************************************************************/
/* any __fp64_fixxdfxi (float64_t A);
	This is the common subroutine for all conversions from float64_t to integer.
    The __fp64_fixxdfxi() function converts A to the signed/unsigned integer value
	with given length. rounding towards 0, the fractional part is lost. No saturation.
	For conversion to unsigned, negative input is permissable (like GCC/x86). 
 	input:	rA7..rA0	float64_t number to convert
			rBE0		bit length of result:	64/63 for unsigned/signed long long
												32/31 for unsigned/signed long
												16/15 for unsigned/signed int							
												8/7   for unsigned/signed char
	output:	rA7..rA0	result for unsigned/signed long long (64 bit)
			rA7..rA4	result for unsigned/signed long (32 bit)
			rA7..rA6	result for unsigned/signed int (16 bit)
			rA7			result for unsigned/signed char (8 bit)
			C			carry as flag of error fr indicating NaN or overflow

	special case matrix for __fp64_fixxdfxi
	case| A	          | C | result
	----+-------------+---+------------
	  1 | NaN         | 1 | 0x00000000
	  2 | Inf         | 1 | 0x00000000
	  3 | |x|>=2^rBE0 | 1 | 0x00000000
	  4 | 0<|x|<1.0   | 0 | 0x00000000
	  5 | 0<A<2^rBE0  | 0 | (uint_rBE0) A
	  6 | -2^rBE0<A<0 | 0| -((uint_rBE0) (-A)
	  
	*** IMPORTANT: The caller must use the following sequence to use this function:
	push rBE0
	ldi rBE0, nn	; for valid values of nn see above
	XJMP _U(__fp64_fixxdfxi)
	*** otherwise your code will crash as __fp64_fixxdfxi will restore rBE0 from stack
	*** before returning:
*/
__fp64_fixxdfxi:
	XCALL _U(__fp64_splitA)
	brcs .L_err				; return 0 for NaN and +/-INF
	breq .L_zr				; return 0 for 0
	tst rAE1
	brmi .L_zr				; return 0 if exponent is < 0

	; A is finite and abs(x) > 0
	subi rAE0, lo8(1023)	; remove exponent bias: exp -= 1023
	sbci rAE1, hi8(1023)
	tst rAE1
	brne .L_err				; return 0 and error if exponent > 255
	mov rAE1, rBE0
	sub rAE1, rAE0			; rEA1 = maxExp - exp
	; rcall __fp64_saveAB
	brmi .L_err				; return 0 and error if exponent > 32
		
	; after splitting, the significand of x is in rA6..rA0,
	; so already shifted 8 bits to the right in reference to
	; rA7..rA0 which will hold the final result. So, with some
	; code rearrangement, we can avoid shifting the result first
	; up to rA7..rA0 and then back down.
	sbrs rBE0, 0
	dec rAE1
	cpi rAE1, 8				; do we have to make >=8 shifts
	; rcall __fp64_saveAB
	brlo 2f					; no, bring number to correct position
	
1:	mov rA7, r1				; yes, clear top 8 bits
	subi rAE1, 8			; adjust counter, as 8 shifts are done
	cpi rAE1, 8				; still more than 8 shifts to be done
	brlo 3f					; no, do single bit shifting
	mov rA0, rA1			; yes, shift down by 8 bits
	mov rA1, rA2
	mov rA2, rA3
	mov rA3, rA4
	mov rA4, rA5
	mov rA5, rA6
	mov rA6, rA7
	rjmp 1b					; and continue byte-wise shifting

	; return zero as regular value, error flag not set 
.L_zr:
	pop rBE0
	XJMP	_U(__fp_zero)			; return 0x00000000, clear carry

	; on all errors: return 0 and set error flag
.L_err:	
	XCALL	_U(__fp64_zero)			; float64_t zero is also long 0
	sec								; set error flag
	pop rBE0
	ret

2:	; number was >= 2^56 --> less than 8 shifts to be made
	; and we have to bring the number into rA7..rA0
	mov rA7, rA6
	mov rA6, rA5
	mov rA5, rA4
	mov rA4, rA3
	mov rA3, rA2
	mov rA2, rA1
	mov rA1, rA0
	mov rA0, r1				; clear bottom 8 bits
	
3:	tst rAE1				; still any shifts to be done?
4:	breq .L_sign			; no, set the sign	
	lsr rA7					; yes, shift down 1 bit
	ror rA6
	XCALL _U(__fp64_rorA5)
	dec rAE1
	rjmp 4b
	
  ; restore the sign and return
.L_sign:
	; rcall __fp64_saveAB
	brtc 6f					; if( sign )
	cpi rBE0, 33			;	clear out lower bits that are not used
	brge 5f					;	otherwise negation will round towards next number
	mov rA0, r1				;	for 32-bit: rA0..rA3 are 0
	mov rA1, r1
	movw rA2, rA0
	cpi rBE0, 17
	brge 5f
	movw rA4, rA0			;	for 16-bit: rA0..rA5 are 0
	cpi rBE0, 9
	brge 5f
	mov rA6, rA0			;	for 8-bit: rA0..rA6 are 0
5:	com	rA7					;	res = -res;
	com	rA6
	com	rA5
	com	rA4
	com	rA3
	com	rA2
	com	rA1
	neg	rA0
	sbci rA1, -1
	sbci rA2, -1
	sbci rA3, -1
	sbci rA4, -1
	sbci rA5, -1
	sbci rA6, -1
	sbci rA7, -1
6:	cpi rBE0, 9				; special case char/int8_t?
	brge 7f
	mov rA6, rA7			; yes: value has to be returned in rA6
7:	clc						; clear carry as error flag
	pop rBE0
	ret
ENDFUNC
