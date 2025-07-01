/* Copyright (c) 2019-2025  Uwe Bissinger
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

/* char *__fp64_etoa( float64_t x, uint8_t maxDigits, uint8_t expSep, int16_t *exp10 )
	converts a number to a string with maxDigits of significand in engineering format,
	i.e. exponent is a multiple of 3
	function and parameters are fully compatible to __fp64_ftoa
	input:	rA7..rA0:	number x to convert in float64_t format
			rA6:		maximum number of digits in significand
						NOTE: this function supports conversion of up to 17 digits
							  however, accuracy of IEEE754 is only 52 bit which is 15-16 decimal digits
			rB4:		flag to store significand and exponent seperately
			rB2:		int16_t *Exp10 // if != NULL, store exponent base 10 here
	output: rA7..rA6	pointer to result, '\0' terminated C-string
	modfies: rAE1.rAE0
	
	WARNING: 	function returns a pointer to a static temporary scratch area which might be used
				also for other functions. The returned string might become invalid/scrambled
				if one of the other fp64_ functions will be called. So copy the result to some
				other allocated memory that you have under control before calling further
				fp64__ routines
 */

FUNCTION fp64_etoa

// assign aliases to registers for easier reading
#define rChar	rA7		/* actual char */
#define rDot	rA6		/* "." */
#define rExp	rA5		/* "E" or "\0", delimiter for exponent  */
#define rChr0	rA4		/* "0" */
#define rMod	rA3		/* exponent mod 3 */

.L_OK:
	jmp .L_ret	// label too far away for relative jump

ENTRY   fp64_etoa
	XCALL _U(__fp64_splitA)
	
	push rAE1						; save exponent for later
	push rAE0
	XCALL _U(__fp64_ftoa_pse)		; get an result in scientific format
	pop rAE0
	pop rAE1
	brcs .L_OK						; no treatment needed for Inf/NaN
	call __fp64_saveAB
	ret
	ld rA7, x
	cpi rA7, '0'
	breq .L_OK						; no treatment needed for 0
	
	; now get "exponent mod 3" for shifting the "."
	; get x = abs(rAE1.0) mod 3
	; for positive x
	; 	move decimal point to the right by x digits 
	; 	and increase exponent by x
	;	result:	1.2345E0	-> 1.2345E0	(0 mod 3 = 0)
	;			1.2345E1	-> 12.345E0	(1 mod 3 = 1)
	;			1.2345E2	-> 123.45E0 (2 mod 3 = 2)
	;			1.2345E3	-> 1.2345E3 (3 mod 3 = 0)	
	; for negative x
	;	calc y = (x==0) ? 0 : 3-x
	;	move decimal point to the right by y digits
	;	and decrease exponent (=increase abs(exponent)) by y
	;	result:	1.2345E-1	-> 123.45E-3 x = 1, y = 3-1 = 2
	;			1.2345E-2	-> 12.345E-3 x = 2, y = 3-2 = 1
	;			1.2345E-3	-> 1.2345E-3 x = 0, y = 0
	;			1.2345E-4	-> 123.45E-6 x = 1, y = 3-1 = 2
	;			

	; fast mod 3 for exponent
	push rAE1				; save exponent for later
	push rAE0

	subi rAE0, lo8(1023)	; remove exponent bias: exp -= 1023
	sbci rAE1, hi8(1023)
	bst rAE1,7				; save sign into t flag
	brtc 0f
	neg rAE1				; calc abs(rAE1.0)
	neg rAE0
	sbc rAE1, r1
	
0:	
	; highly optimized division
	; assumption: exponent is already normalized and contains abs(exponent)
	; highest exponent is 385, which fits into 9 bits = 2^9 = 512
	; x/3 = (x*512/3)/512 = x*171 >> 9 
	; x is a 16 bit value, x = rAE1 << 8 + rAE0
	; and rAE1 is either 0 or 1 (as exponent is 9 bits at max)
	; --> rAE1*171 is always an 8 bit result (as it is 0 or 171)
	; x/3 = ((rAE1 << 8) * 171 >> 9) + (rAE0 * 171 >> 9)
	; due to >>9, the lowbyte of rAE0*171 is irrelevant
	;     = lowbyte(rAE1 * 171) >> 1 + highbyte(rAE0*171) >> 1
	;     = (lowbyte(rAE1*171)+highbyte(rAE0*171)) >> 1
	ldi rA5, 171
	mul rAE1, rA5	; rAE1 * 171
	mov rA6, r0		; rA6 = lowbyte(rAE1*171)
	mul rAE0, rA5	; rAE0 * 171
	add rA6, r1		; rA6 = lowbyte(rAE1*171)+highbyte(rAE0*171)
	asr rA6			; >> 1
	 
	 ; rA6 is now the result of rAE1.0 / 3
	 ; for modulo multiply result now by 3
	mov r0, rA6		; save x = rAE1.0 / 3
	eor rA7, rA7	; clear high byte
	mov r1, rA7		; restore zero register (used by MUL)
	add rA6, rA6
	adc rA7, r1		; x + x = 2*x
	add rA6, r0
	adc rA7, r1		; rA7.6 = x + x + x = 3 * x
	
	sub rAE0, rA6
	sbc rAE1, rA7	; rRAE1.0 = rAE1.0 mod 3
	brtc 1f			; that's all for positive x
	tst rAE0
	brne 1f
	ldi rA7, 3		; calc 3-(x mod 3) for x!=0
	sub rA7, rAE0
	mov rAE0, rA7

1:	; rAE0 contains "exponent mod 3"
	mov rMod, rAE0	; save exponent mod 3
	tst rMod
	; rcall __fp64_saveAB
	breq .L_retp	; nothing to do for mod 3 = 0
	
	ldi rExp, 'E'
	ldi rDot, '.'
	ldi rChr0, '0'

	pop rAE0		; restore exponent
	pop rAE1
	
	push XL			; save pointer to start of string
	push XH

	ld rChar, X+	; check for sign and skip it
	cpi rChar, '-'
	breq 2f
	cpi rChar, '+'
	brne 3f
2:	ld rChar, X+	; skip first digit after sign
3:	ld rChar, X+	; get "." or E

	cpi rMod, 1		; check for exponent mod 3 == 1
	brne .L_two
	
.L_one:
	; shift by 1
	; take care of the following cases
	; 1a) "aEeee"		--> "a0Ee-1"
	; 1b) "a.Eeee"		--> "a0Ee-1"
	;						this works also, when exponent is negative
	;						e.g. 1E-2 = 10E-3
	; 2) "a.bEeee"		--> "abEe-1"
	; 3) "a.bcEeee"		--> "ab.cEe-1"
	; instead of "E", "\0" is also possible
	; "a.E-eee"			--> "a0.E-e+1" and "a0E-e+1"

	cp rChar, rExp	
	breq .L_case1a	; case 1a "aEeee"
	tst rChar
	breq .L_case1a	; case 1a "a\0eee"
	
	; >= case 1b --> rChar is "."
	ld rChar, X		; get first character after ".": either E or digit
	sbiw X, 1		; and position back to "."
	cp rChar, rExp
	breq .L_case1b	; case 1b "a.Eeee"
	tst rChar
	breq .L_case1b	; case 1b "a.\0eee"

	; >= case 2 --> rChar has first decimal digit 
	st X+, rChar	; copy first decimal it over the "."
	st X+, rDot		; and the insert the "." back, "a.b" --> "ab."
	
	ld rChar, X+	; get either next digit or "E"
	cp rChar, rExp
	breq .L_case2	; case 2 "a.bEeee"
	tst rChar
	breq .L_case2	; case 2 "a.b\0eee"
	
	; case 3, normal case "a.bcdEeee", X is pointing to "d"
	; now scan for end of digits
.L_case3:
	ld rChar, X+	; get either next digit or "E"
	cp rChar, rExp
	breq .L_decE	; exponent found, increment it
	tst rChar
	brne .L_case3

	; decrease the exponent and store it
	; X points to first character of exponent
.L_decE:
	sub rAE0, rMod	
	sbc rAE1, r1
	XCALL __itoa_ncheck	; and convert it to string

.L_retp:
	pop XH			; restore pointer to start of string
	pop XL
	
.L_ret:
	ret

	
.L_case1a:	; 1a) "aEeee"		--> "a0Ee-1"
	; rChar is "E" or "\0"
	; X points to first digit of exponent
	sbiw X, 1			; move back to exponent delimiter
	
.L_case1b:	; 1b) "a.Eeee"		--> "a0Ee-1"
	; rChar is "E" or "\0"
	; X points to "." (or exponent delimiter for case 1a)

	st X+, rChr0		; overwrite the "E" or "\0" with "0"
	st X+, rChar		; and start the exponent
	rjmp .L_decE		; increase and store the exponent

.L_case2:	; 2) "a.bEeee"		--> "abEe-1"
	; rChar is "E" or "\0"
	; currently, input string is "ab.Eeeee"
	; X points to first digit of exponent

	sbiw XL, 1			; let X point to "."
	st X+, rChar		; overwrite "." with "E" or "\0"
	rjmp .L_decE		; increase and store the exponent


.L_two:
	; shift by 2
	; take care of the following cases
	; 21a) "aEeee"		--> "a00Ee-2"
	; 21b) "a.Eeee"		--> "a00Ee-2"
	;						this works also, when exponent is negative
	;						e.g. 1E-1 = 100E-3
	; 22) "a.bEeee"		--> "ab0Ee-2"
	; 23) "a.bcEeee"		--> "abcEe-2"
	; 24) "a.bcdEeee"	--> "abc.dEe-2"
	; instead of "E", "\0" is also possible
	; "a.E-eee"			--> "a00E-e+2" and "a00\0-e+2"

	cp rChar, rExp
	breq .L_case21a		; case 21a "aEeee"
	tst rChar
	breq .L_case21a		; case 21a "a\0eee"
	
	; >= case 21b --> rChar now contains "."
	ld rChar, X			; get first character after ".": either E or digit
	sbiw XL, 1			; and position back to "."
	cp rChar, rExp
	breq .L_case21b		; case 21b "a.Eeee"
	tst rChar
	breq .L_case21b		; case 21b "a.\0eee"

	; >= case 22 --> rChar has first decimal digit
	;				 X points to "."
	st X+, rChar	; copy first decimal digit over the "." --> "abb"
	adiw X, 1		; move X to next char after "abb"
	ld rChar, X		; get either next digit or "E"
	sbiw XL, 1		; and go back to "b"
	cp rChar, rExp
	breq .L_case22	; case 22 "a.bEeee"
	tst rChar
	breq .L_case22	; case 22 "a.b\0eee"
	
	st X+, rChar	; copy 2nd decimal digit --> "abcc"
	st X+, rDot		; and the insert the "." back, "abcc" --> "abc."
	
	ld rChar, X+	; get either next digit or "E"
	cp rChar, rExp
	breq .L_case23	; case 23 "a.bcEeee"
	tst rChar
	breq .L_case23	; case 23 "a.bc\0eee"
	
	; case 24, 'normal' case "a.bcdEeee", X is pointing to "d"
	; now scan for end of digits = exponent character
.L_case24:
	ld rChar, X+		; get either next digit or "E"
	cp rChar, rExp
	breq .L_decE		; exponent found, increment it
	tst rChar
	brne .L_case24
	rjmp .L_decE		; done, decrease and store exponent
	
.L_case21a:	; 21a) "aEeee"		--> "a00Ee-2"
	; rChar is "E" or "\0"
	; X points to first digit of exponent
	sbiw XL, 1			; move to exponent delimiter

.L_case21b:	; 21b) "a.Eeee"		--> "a00Ee-2"
	; rChar is "E" or "\0"
	; X points to "."
	st X+, rChr0		; overwrite the "E" or "\0" with "00"

.L_case22:	; 22) "a.bEeee"		--> "ab0Ee-2"
	; rChar is "E" or "\0"
	; current result is "abbEeee"
	; X points to char before rChar, i.e. to second "b"
	st X+, rChr0
	st X+, rChar		; and start the exponent
	
	rjmp .L_decE		; increase and store the exponent

.L_case23: ; 23) "a.bcEeee"		--> "abcEe-2"
	; rChar is "E" or "\0"
	; current result is "abc.Eeee"
	; X points to first digit of exponent
	sbiw XL, 1 			; let X point to "."
	st X+, rChar		; start the exponent, i.e. exponent overwrites "."
	
	rjmp .L_decE		; increase and store the exponent

ENDFUNC
