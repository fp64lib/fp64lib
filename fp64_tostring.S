/* Copyright (c) 2019-2020  Uwe Bissinger
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

FUNCTION fp64_to_string
	
/* char *fp64_to_string(float64_t x, uint8_t max_chars, uint8_t max_zeroes)
	converts the float64 to the decimal representation of the number x, 
	based on the following cases for x
					x	  | result
	----------------------+-----------------------------------------------------------
					NaN		"NaN"
					+INF	"+INF"
					-INF	"-INF"
				   |x|<1	"s0.mmmmmm" representation without exponent if
							x can be displayed with less than max_zeroes "0" after "0."
							leading sign s only for x < 0
							else exponential form is used "sm.mmmmmESnnn"
	log10(|x|)<max_chars	"smmm.mmm" representation without exponent
			all other cases	"sm.mmmmmESn" exponential form is used 
							leading sign s only for x < 0
							exponent "Snnn" has always a sign S ("+" or "-") and
							one digit to three digits nnn for the exponent
							
	fp64_to_string adjusts the number of decimal digits so that the result
	will fit into a string with max_chars characters. However, a longer string
	will be returned if the minimum representation will not fit into max_chars.
	Minimum representation is "mESn[nn]" for X > 0 else "-mESn[nn]".
	
	input:	rA7..rA0:	number x to convert in float64_t format
			rB6:		max_chars, maximum space for result
			rB4:		max_zeroes, use "s0.mmmmmm" when result has less than this # of 0s
	output: rA7..rA6	pointer to result, '\0' terminated C-string

	WARNING: 	function returns a pointer to a static temporary scratch area which might be used
				also for other functions. The returned string might become invalid/scrambled
				if one of the other fp64_ functions will be called. So copy the result to some
				other allocated memory that you have under control before calling further
				fp64__ routines
*/
#define		rPrec	rB7			// precision for call to f_to_decimalExp
#define 	rNrd	rB6			// number of digits available, at start max_chars
#define		rFlags	rB5			// flags: below1, above1
#undef 		rZero
#define		rZero	rB4			// max_zeroes, use "s0.mmmmmm" when result has less than this # of 0s
#define		fBelow1	0			// bit 0 of rFlags is set if |x| < 1
#define		fAbove1	1			// bit 1 of rFlags is set if log10(|x|)<max_chars
#define		fZero	6			// bit 6 of rFlags is set if x == 0.0
#define		fSign	7			// bit 1 of rFlags	

0:	; handle NaN and Inf
	pop rFlags
	pop rNrd
	pop rPrec
	XJMP _U(__fp64_ftoa_nan)	; return string as from ftoa

ENTRY   fp64_to_string
    push rPrec					; ABI requires anything below r18 to be saved
	push rNrd
	push rFlags
	clr rFlags
	XCALL _U(__fp64_splitA)
	brcs 0b
	brne .L_sign
	sec
	ror rFlags					; set flag for  x == 0.0
	ror rFlags

.L_sign:	; sign is stored in T flag
	; rcall __fp64_saveAB
	brtc 1f
	dec rNrd					; nrd = sign ? max_nr_chars-1 : max_nr_chars;
1:	bld rFlags,fSign			; save sign
	push rB7					; save used registers
	push rB6
	push rB5
	push rB4
	push rB3
	push rB2
	push rB1
	push rB0
	
	push rA7					; save x
	push rA6
	push rA5
	push rA4
	push rA3
	push rA2
	push rA1
	push rA0
	push rAE1
	push rAE0

	sbrc rFlags, fZero
	bset 1						; set Z flag if x was 0.0
	; rcall __fp64_saveAB

	; do not use clr statement in the following as it will modify the Z flag!!!
	mov rB5, r1					; rB5.rB4 = 0 --> expSep = 0, no separate storage of exponent
	mov rB4, r1
	ldi rB7, hi8(L_exp10L)		; ; rB3.rB2 = pointer to store exponent in L_exp10L/H
	mov rB3, rB7
	ldi rB7, lo8(L_exp10L)
	mov rB2, rB7
	mov rB7, r1					; rB7.rB6 = prec = 1
	ldi rB6, 0x01				
	; rcall __fp64_saveB
	XCALL _U(__fp64_ftoa_pse)	; 	s = fp64_to_decimalExp(x, prec, 0, NULL); // get number
	lds rExp10L, L_exp10L		; retrieve exp10
	lds rExp10H, L_exp10H

	pop rAE0					; restore x
	pop rAE1
	pop rA0	
	pop rA1	
	pop rA2
	pop rA3
	pop rA4
	pop rA5
	pop rA6
	pop rA7
	
	pop rB0						; restore saved registers
	pop rB1	
	pop rB2
	pop rB3
	pop rB4
	pop rB5
	pop rB6
	; pop rB7					; keep previous content of rB7 on stack
	bst rFlags, fSign			; restore sign

	; rcall __fp64_saveAB
	; movw r24, ZL
	; ret
	
	; check for |x| < 1 --> representation "s0.mmmmmm" without exponent
	cpi rAE1, 0x3				; if( exp2 < 0 ) {
	brlo .L_below1
	brne 2f
	cpi rAE0, 0xff
	brlo .L_below1
	rjmp 2f
	
.L_below1:
	adiw rExp10L, 0
	breq 19f
	cpi rExp10H, 0xff			;	// if the high byte is != 0xff, then -exp10 is definitely > max_zeroes	
	brne .L_exp					;	if( - exp10 <= max_zeroes )
	mov r0, rExp10L
	neg r0						; // -exp10
	cp rZero, r0
	; rcall __fp64_saveAB
	brcs .L_exp					; // C=1 if -exp10 > rZero --> we have too maxny leading 0s --> exponent form
	
	; yes, we can use "s0.mmmmmm" representation
19:	mov rPrec, rNrd				;		prec = nrd + exp10 - 1;
	add rPrec, rExp10L
	subi rPrec, 1
	
	ror rFlags
	sec
	rol rFlags					; 		below1 = true;
	
	adiw rExp10L, 0				;		if( exp10 == 0 )
	brne .L_get	
	subi rPrec, 1				;			prec--
	rjmp .L_get					;	}
	
2:	; check for log10(|x|)<max_chars --> representation "mmm.mmm" without exponent
	tst rExp10H					; if( exp10 < nrd ) 
	brne .L_exp
	cp rExp10L, rNrd
	brcc .L_exp
	
	; yes, number does not have too many digits before "."#
	ror rFlags
	ror rFlags
	sec
	rol rFlags
	rol rFlags					; 	above1 = true
	; sbr rFlags, fabove1			;	above1 = true;
	mov rPrec, rNrd				;	
	dec rPrec
	cp rExp10L, rPrec			; 	if( exp10 != nrd - 1 )
	brne .L_get					; 		prec = nrd - 1;	// we can store "mmmm.mm", -1 for "."
	inc rPrec					; 	else 
	rjmp .L_get					; 		prec = nrd;		// not enough space for digit after ".", just store "mmmm"
	
	; default case, format number with exponent
.L_exp:
	; calculate number of digits in exponent
	push rExp10H
	push rExp10L
	tst rExp10H
	brpl 3f
	neg rExp10H					; exp10 = -exp10;
	neg rExp10L
	sbci rExp10H, 0
3:	clr r0						; uint8_t expDigits = (abs(exp10) < 10 ? 1 : (abs(exp10) < 100 ? 2 : 3));
	tst rExp10H
	brne 4f						; abs(exp10) > 255 --> 3 digits
	cpi rExp10L, 100
	brcc 4f						; abs(exp10) >= 100 --> 3 digits
	cpi rExp10L, 10
	brcc 5f						; abs(exp10) >= 10 --> 2 digits
	rjmp 6f						; else abs(exp10) < 10 --> 1 digit

4:	inc r0						; 3 digits
5:	inc r0						; 2 digits
6:	inc r0						; 1 digit

	inc r0						; uint8_t minD = expDigits + 3; // +3 for at least 1 digit, "E" and exponent sign
	inc r0
	inc r0
	; rcall __fp64_saveAB

	mov rPrec, rNrd				; prec = (nrd < minD) ? 0 : nrd - minD;
	sub rPrec, r0
	sbrc rPrec, 7
	mov rPrec, r1
	
	pop rExp10L
	pop rExp10H

.L_get:
	; now get the string in the right precision, set in rPrec
	cpi rPrec, MAX_SIGNIFICAND+1	; limit precision to maximal # of significand digits (17)
	brlo 7f
	ldi rPrec, MAX_SIGNIFICAND
7:	cpi rPrec, 1					; limit precision to be >= 1
	adc rPrec, r1
	push rB7					; save used registers
	push rB6
	push rB5
	push rB4
	push rB3
	push rB2
	push rB1
	push rB0
	
	sbrc rFlags, fZero
	bset 1						; set Z flag if x was 0.0

	; do not use clr statement in the following as it will modify the Z flag!!!
	mov rB6, rB7				; rB7.rB6 = prec
	mov rB5, r1					; rB5.rB4 = 0 --> expSep = 0, no separate storage of exponent
	mov rB4, r1
	ldi rB7, hi8(L_exp10L)		; ; rB3.rB2 = pointer to store exponent in L_exp10L/H
	mov rB3, rB7
	ldi rB7, lo8(L_exp10L)
	mov rB2, rB7
	mov rB7, r1					
	; rcall __fp64_saveAB
	XCALL _U(__fp64_ftoa_pse)	; 	s = fp64_to_decimalExp(x, prec, 0, NULL); // get number
	movw ZL, r24				; overwrite rExp2/rAE0 which is no longer needed
	
	lds rExp10L, L_exp10L		; retrieve exp10
	lds rExp10H, L_exp10H
	pop rB0						; restore saved registers
	pop rB1	
	pop rB2
	pop rB3
	pop rB4
	pop rB5
	pop rB6
	pop rB7
	bst rFlags, fSign			; restore sign
	
	push YH
	push YL
	push ZH						; save original value for later use
	push ZL
	
	sbrc rFlags, fZero			; if( x == 0.0 )
	rjmp .L_ret					;	return( s  ); // no more processing necessary
	
	sbrc rFlags, fSign			; if( sign )
	adiw ZL, 1					;		s++;
	
	sbrs rFlags, fBelow1
	rjmp 8f
	
	adiw rExp10L, 0				; 	if( below1 && exp10 == 0 ) {
	brne 69f
	; case 0.99999 got rounded to 1.0 --> we are no longer below 1
	ror rFlags
	clc							;	below1 = false;
	ror rFlags
	sec							; 	above1 = true
	rol rFlags
	rol rFlags					
	subi rPrec, 1				;	prec--;
	rjmp 8f

	; format number as 0.mmmm
69:
	mov rPrec, rNrd				;		prec = nrd + exp10 - 1;
	add rPrec, rExp10L
	subi rPrec, 1
	cpi rPrec, MAX_SIGNIFICAND+1	; limit precision to maximal # of significand digits (17)
	brlo 699f
	ldi rPrec, MAX_SIGNIFICAND
699:
	ld r0, Z					; create continouse stream of digits
	std Z+1, r0					; m.mmmmmm -> mmmmmmmm
	
	add ZL, rPrec				; pos = prec - exp10
	adc ZH, r1
	movw YL, ZL					; YH.YL now points to s[prec]
	sub ZL, rExp10L
	sbc ZH, rExp10H				; ZH.ZL now points to s[pos]
	push ZH						; save pos
	push ZL
	
70:	dec rPrec
	brmi 71f
	ld r0, Y					;	s[pos--] = s[prec--]
	st Z, r0
	sbiw ZL, 1
	sbiw YL, 1
	rjmp 70b
	
71:	; now fill up the the zeroes
	com rExp10L					; zeroes = -(exp10+1)
								; as prec is between 1 and 17, only Exp10L needs to be regarded

	ldi rExp10H, '0'
72:	breq 73f					; for( ; zeroes > 0; zeroes-- )
	st Z, rExp10H				;		s[pos--] = '0'
	sbiw ZL, 1
	dec rExp10L
	rjmp 72b
73:	sbiw ZL, 1
	st Z, rExp10H			; s[pos--] = '.'; s[pos--] = '0';
	ldi rExp10H, '.'
	std Z+1, rExp10H
	
	pop ZL						; restore pos
	pop ZH
	adiw ZL, 1					; endPos = pos + 1
								; ZH.ZL now points to s[endPos]

	rjmp .L_cut					; now check for cutting trailing zeroes
	
	; check for next formatting option
8:	sbrs rFlags, fAbove1
	rjmp 9f
	; format number as mmm.mmm
	; input is "m.mmmmmmEeee" with prec digits before E
	; so we just have to move the "." to the right position
	adiw ZL, 1					; pos = 1; // start at "."
								; ZH.ZL now points to s[pos]

	movw YL, ZL					; endPos = pos + prec;
	add YL, rPrec
	adc YH, r1					; YH.YL now points to s[endPos]
	
	mov rExp10H, rExp10L		; for( int i = 0 ; i < exp10; i++ ) {
	tst rExp10H	
	
80:	breq 81f
	ldd r0, Z+1					; 	s[pos] = s[pos+1]
	st Z+, r0
	dec rExp10H					; 	pos++;
	rjmp 80b					; }

81: ; now insert the ".", but only of the digits after "." still fit into max_nr_chars
	dec rPrec
	cp rExp10L, rPrec			; if( exp10 != prec - 1 ) 
	breq 82f

	ldi rExp10H, '.'			;	s[pos] = '.';
	st Z, rExp10H

	movw ZL, YL					; set endpos that was saved in YL
	rjmp .L_cut					

	; digits after '.' do not fit in, so terminate the string one character earlier
82:	st Z, r1					; s[pos] = '\0';
	rjmp .L_ret					; no removing of trailing zeroes, return s as it is

9:	; format number in exponential form
	; nothing to do, just remove trailing 0s
	add ZL, rPrec				; endpos = prec + 1
	adc ZH, r1
	adiw ZL, 1					; ZL.ZH now points to s[endPos]
	movw XL, ZL					; pos = endPos

	; remove trailing 0s
.L_cut:
	; ZH.ZL points to s[endPos]
	; XH.XL points to s[pos] if exponential format

	; adiw ZL, 0
	; cp ´ZL, r1					; check whether endPos is set
	; cpc ZH, r1
	; breq .L_ret

90:	ld rA7, -Z					; while( s[--endPos] == '0' )
	cpi rA7, '0'				;		;
	breq 90b
	
	cpi rA7, '.'				; if( s[endPos] == '.' )
	brne 91f
	sbiw ZL, 1					;	endPos--
91:	
	sbrc rFlags, fAbove1		; iif( below1 || above1 )
	rjmp 92f
	sbrs rFlags, fBelow1
	rjmp 93f
92:	adiw ZL,1
	st Z, r1					;	s[++endPos] = '\0';
	rjmp .L_ret
								; else {
								; 	// copy exponent part
93:	adiw Z, 1
94:	ld r0, X+					;	do {
	st Z+, r0					; 		s[++endPos] = s[pos++];
	tst r0						; 	} while( s[pos-1] != '\0' );
	brne 94b

.L_ret:
	pop ZL						; restore s
	pop ZH
	
	pop YL						; restore Y
	pop YH

	pop rB7
	pop rFlags
	pop rNrd
	pop rPrec
	
	movw r24, ZL				; return( s )
	ret
ENDFUNC
.data	
L_exp10L:	.skip 1
L_exp10H:	.skip 1
