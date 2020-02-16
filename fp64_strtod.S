/* Copyright (c) 2019-2020  Uwe Bissinger
   Algorithm is based on code of avr_f64.c with:
   Original Code by Detlef_a (Nickname in the www.mikrocontroller.net forum).
   Extensions (trigonometric functions et al.) und changes by Florian Kï¿½nigstein, mail@virgusta.eu .
  
  The following copyright information refers to the code developed by Florian Kï¿½nigstein.

; //*********************************************************************************************************** //
; //*********************************************************************************************************** //
; //                                                                                                           //
; // avr_f64.c and avr_f64.h : Contains ANSI C Funktions for handling of 64 bit IEEE 754 double precision      //
; // floating point numbers.                                                                                   //
; // float64_t represents an IEEE 64 bit double precision floating point number.                               //
; //                                                                                                           //
; // Compiler: avr-gcc                                                                                         //
; //                                                                                                           //
; // Copyright:                                                                                                //
; //      You may use this program free of charge for any purpose you wish provided you agree to the following //
; //      License:                                                                                             //
; //      Warranty of Provenance and Disclaimer of Warranty. Licensor warrants that the copyright              //
; //      in and to the Original Work and the patent rights granted herein by Licensor are owned by the        //
; //      Licensor or are sublicensed to You under the terms of this License with the permission of the        //
; //      contributor(s) of those copyrights and patent rights. Except as expressly stated in the immediately  //
; //      preceding sentence, the Original Work is provided under this License on an "AS IS" BASIS and WITHOUT //
; //      WARRANTY, either express or implied, including, without limitation, the warranties of                //
; //      non-infringement, merchantability or fitness for a particular purpose. THE ENTIRE RISK AS TO THE     //
; //      QUALITY OF THE ORIGINAL WORK IS WITH YOU. This DISCLAIMER OF WARRANTY constitutes an essential part  //
; //      of this License. No license to the Original Work is granted by this License except under this        //
; //      disclaimer.                                                                                          //
; //                                                                                                           //
; //      Limitation of Liability. Under no circumstances and under no legal theory, whether in tort           //
; //      (including negligence), contract, or otherwise, shall the Licensor be liable to anyone for any       //
; //      indirect, special, incidental, or consequential damages of any character arising as a result of      //
; //      this License or the use of the Original Work including, without limitation, damages for loss of      //
; //      goodwill, work stoppage, computer failure or malfunction, or any and all other commercial damages    //
; //      or losses. This limitation of liability shall not apply to the extent applicable law prohibits such  //
; //      limitation.                                                                                          //
; //                                                                                                           //
; //*********************************************************************************************************** //
; //*********************************************************************************************************** //

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

#define MAX_SIGNIFICAND		17
#define	MAX_EXPONENT		3
#define rExp2L				ZL
#define rExp2H				ZH
#define rCh					XL
#define rPoint				XH

FUNCTION fp64_strtod
 90:
	rjmp .L_RetZero

/* float64_t fp64_atof( char *str )
	converts a string to a number, handles also NaN, +INF, -INF
	a valid number (non NaN or INF) can be expressed by the
	following regex: [+-]?[0-9]+\.?[0-9]*([eE][+-]?[0-9]+)?
	
	input:	rA7.rA6:	pointer to string
 */
ENTRY fp64_atof
	mov rA4, r1
	mov rA5, r1			; use fp64_strod with end_ptr = NULL
 
/* float64_t fp64_strtod( char *str, char **endptr )
	converts a string to a number, handles also NaN, +INF, -INF
	a valid number (non NaN or INF) can be expressed by the
	following regex: [+-]?[0-9]+\.?[0-9]*([eE][+-]?[0-9]+)?
	
	input:	rA7.rA6:	pointer to string
			rA5.rA4:	return last parsed position in string into that char*
 */
 
ENTRY   fp64_strtod
	sts .L_endpL, rA4	; save pointer to pointer to last parsed position
	sts .L_endpH, rA5
	sts .L_sign, r1		; per default sign = 0 (positive number)
	push YH				; Y is used for pointing to actual position in str
	push YL
	movw YL, rA6
	adiw YL, 0			; if( (s = str) == NULL )
	breq 90b				;	return( 0 );

	; skip whitespace	
						; do {
0:	ld	rCh, Y+			; 	ch = *s++;
	tst rCh				; 	if( ch == '\0' ) 	
	breq 90b			;		return( 0 );	// only whitespace, return 0
	cpi rCh, ' '		; } until( ch != ' '
	breq 0b
	cpi rCh, '\t'		;						|| ch != '\t' );
	breq 0b

	; check for NaN
	cpi rCh, 'N'
	breq 1f
	cpi rCh, 'n'
	brne .L_noNaN
1:	; n or N detected, check for a or A
	ld rCh, Y			
	cpi rCh, 'A'
	breq 2f
	cpi rCh, 'a'
	brne 90b		; incorrect string starting with "N", return 0
2:	; [nN][aA] detected, check for n or N
	ldd rCh, Y+1
	cpi rCh, 'N'
	breq 3f				; NaN successfully detected
	cpi rCh, 'n'
	brne 90b			; incorrect string starting with "Na", return 0
3:	; NaN successfull detected, adjust pointer position and return NaN
	adiw YL, 3			; s point to first character after NaN
	rjmp .L_NaN
	
.L_noNaN:
	; no NaN, check for sign
	cpi rCh, '+'
	breq 4f
	cpi rCh, '-'		; sign = 1 when number starts with '-'
	brne 10f
	ldi rCh, 1			; store negative sign
	sts .L_sign, rCh
		
4:	ld rCh, Y+			; advance to next character if a sign was detected

	; past sign, check for INF
10:	cpi rCh, 'I'
	breq 11f
	cpi rCh, 'i'
	brne .L_noInf
11:	; i or I detected, check for n or N
	ld rCh, Y			
	cpi rCh, 'N'
	breq 12f
	cpi rCh, 'n'
	brne .L_NaN			; incorrect string starting with "I", return NaN
12:	; [iI][nN] detected, check for f or F
	ldd rCh, Y+1
	cpi rCh, 'F'
	breq 13f				; InF successfully detected
	cpi rCh, 'f'
	breq 13f				
	
	; incorrect string starting with "IN", return NaN
.L_NaN:
	rcall .L_savePtr		; save current position
	pop YL					; restore used register and return NaN
	pop YH
	XJMP _U(__fp64_nan)
	
13:	; INF, +INF or -INF successfull detected, adjust pointer position and return INF with sign
	adiw YL, 3			; s point to first character after INF
	rcall .L_savePtr	; save current position and restore sign
	pop YL
	pop YH
	XJMP _U(__fp64_inf)

.L_noInf:
	; up to now, we only had an optional sign
	; initalize some stuff and then enter our main loop
	clr rA7				; A = 0
	clr rA6
	movw rA4, rA6
	movw rA2, rA6
	movw rA0, rA6
	; movw rExp10L, rA6	; exp10 = 0
	sts .L_exp10L, r1		; exp10 = 0
	sts .L_exp10H, r1
	clr rExp2H
	ldi rExp2L, 3			; exp2 = 3 ( a digit 0-9 occupies bits 0-3
	clr rPoint				; rPoint = 0			
	
	push rC7				; save registers used by __fp64_10pown
	push rC6
	push rC5
	push rC4
	push rC3
	push rC2
	push rC1
	push rC0
	
	push rB7				; save registers used by __fp64_10pown
	push rB6
	push rB5
	push rB4
	push rB3
	push rB2
	push rB1
	push rB0

	; skip any leading 0
19:
	cpi rCh, '0'
	brne .L_loop
	ld rCh, Y+
	rjmp 19b
	
	; correctly handle a skipped digit:
	;	if before the decimal point, exp10 has to be increased
	;	if after the decimal point, digit can be ignored
	;		(no special handling needed for correct rounding,
	;		as digits are skipped after 64 bits ~ 19 digits
	;		where as only 53 bits are stored in the significand,
	;		~16-17 digits. So there are at least 2 more digits 
	;		that will be used for rounding.
.L_skipDigit:
	tst rPoint			
	brne .L_nextDigit	; if( !point )
	;adiw rExp10L, 1		;	exp10++
	lds r0, .L_exp10L		;	exp10++
	inc r0
	sts .L_exp10L, r0
	brne .L_nextDigit		; inc does not set the C, but Z
	lds r0, .L_exp10H
	inc r0
	sts .L_exp10H, r0

.L_nextDigit:			; get next digit
	ld rCh, Y+
	
	; *** Main parsing loop ***
.L_loop:
	cpi rCh, '.'		; if( ch == '.' ) {		
	brne 20f
	tst rPoint			;	if( point ) 
	brne .L_NaN			;		return NaN // we already had a decimal pointer
	inc rPoint			;	point = 1;		// set flag for decimal point
						; } // and advance to next character
	rjmp .L_nextDigit

20:	; check for digit
	cpi rCh, '9'+1		; if no digit, break out of loop and check for exponent
	brlo 201f			; due to code size we could not use the nicer "brge .L_exp"
	rjmp .L_exp
201:cpi rCh, '0'
	brge 202f
	rjmp .L_exp
202:
	; we got another digit
	; do we still have space for this digit?
	cpi rExp2L, 64-4			; a digit consumes 4 bits
	; rcall __fp64_saveAB

	brge .L_skipDigit			; no more space, ignore this digit
	
	; sub rExp10L, rPoint			; if( point )
	; sbc rExp10H, r1				
	tst rPoint					; if( point )
	breq 203f
	lds r0, .L_exp10L			;	--Exp10;
	sub r0, rPoint
	sts .L_exp10L, r0
	lds r0, .L_exp10H
	sbc r0, r1
	sts .L_exp10H, r0
	
203:
	ldi rB7, 0xa0				; B = 10 << 60;
	clr rB6
	clr rB5
	clr rB4
	movw rB2, rB4
	movw rB0, rB2
	XCALL _U(__fp64_mul64AB)	; C = A * 10
	cp rC7, r1					; check if result is still 0 
	cpc rC6, r1
	cpc rC5, r1
	cpc rC4, r1
	cpc rC3, r1
	cpc rC2, r1
	cpc rC1, r1
	cpc rC0, r1

	breq 21f					; if( C )
	adiw rExp2L, 4				; 	rExp2 += 4;	// increase position for new digit
	
21:	; add digit to the correct position 63 - exp2
	andi rCh, 0x0f
	mov rB0, rCh				; B = ch - '0', extended to 64 bits
	clr rB7						; NB: B was left untouched by __fp64_mul64AB

	push rExp2H					; save register for intermediate calculation
	ldi rExp2H, 63
	sub rExp2H, rExp2L			; rExp2H = 63 - exp2 , counter for shifting B

22: cpi rExp2H, 8
	brlo 23f
	mov rB7, rB6				; speed shift by 8 bits = 1 register
	mov rB6, rB5
	mov rB5, rB4
	mov rB4, rB3
	mov rB3, rB2
	mov rB2, rB1
	mov rB1, rB0
	clr rB0
	subi rExp2H, 8
	rjmp 22b
	
23:	
	; rcall __fp64_saveAB
	
	tst rExp2H
	breq 25f
24:	lsl rB0						; now shift bitwise if less than 8 shifts are needed
	rol rB1
	rol rB2
	rol rB3
	rol rB4
	rol rB5
	rol rB6
	rol rB7
	dec rExp2H
	brne 24b
	
25:	pop rExp2H					; restore temporarely used register
	
	add rC0, rB0				; now add the digit to the correct position:
	adc rC1, rB1				; C = C + (ch << 63 - exp2)
	adc rC2, rB2
	adc rC3, rB3
	adc rC4, rB4
	adc rC5, rB5
	adc rC6, rB6
	adc rC7, rB7

	cp rC7, r1
	cpc rC6, r1
	cpc rC5, r1
	cpc rC4, r1
	cpc rC3, r1
	cpc rC2, r1
	cpc rC1, r1
	cpc rC0, r1

	breq 26f
	XCALL _U(__fp64_lshift64)	; 	shift left C until bit63 is set, if C!= 0
	sub rExp2L, r0				;	exp2 -= number of neccessary left shifts
	sbci rExp2H, 0

26:
	XCALL _U(__fp64_movAC)		; 	move result back to A for next iteration
	; rcall __fp64_saveA

	rjmp .L_nextDigit
	
	; check for exponent
.L_exp:
	cpi rCh, 'E'
	breq 29f
	cpi rCh, 'e'
	breq 29f
	rjmp .L_noExp
	
	; the following is a custom n-digit atoi implementation that
	; correctly handles +/- sign and exponents even beyond 32768
29:	push rExp2H			; temporarely use rExp2H/L
	push rExp2L
	clr rExp2L
	clt
	ld rCh, Y+			; get next character after 'E'
	cpi rCh, '+'
	breq 30f			; skip + sign
	cpi rCh, '-'
	brne 31f			; no sign
	set					; set T for - sign
	
30:	; T flag now reflects sign of exponent
	ld rCh, Y+			; skip sign after 'E'
31:
	cpi rCh, '0'
	brlo 39f			; something like "E", "E+", "E-" or "E+!"
	breq 30b			; skip leading zeros

	cpi rCh, '9'+1
	brge 39f			; stop parsing
	subi rCh, '0'
	mov rExp2L, rCh		; save first digit != 0

	ld rCh, Y+			; get 2nd character
	cpi rCh, '0'
	brlo 36f			; if no digit, stop conversion 
	cpi rCh, '9'+1
	brge 36f			; if no digit, stop conversion
	
	ldi rExp2H, 10
	mul rExp2L, rExp2H
	mov rExp2L, r0		; exp = first digit * 10
	subi rCh, '0'
	add rExp2L, rCh			; 		+ 2nd digit
	
	ld rCh, Y+			; get 3rd digit
	cpi rCh, '0'
	brlo 36f			; if no digit, stop conversion
	cpi rCh, '9'+1
	brge 36f			; if no digit, stop conversion
	mul rExp2L, rExp2H
	movw rExp2L, r0		; first two digits * 10
	subi rCh, '0'
	clr r1				; restore r1 to 0
	add rExp2L, rCh			; + 3rd digit
	adc rExp2H, r1
	
	; now all further digits will definitely result in +/-INF or +/-0
	ld rCh, Y+			; get next character
	cpi rCh, '0'
	brlo 37f			; no more digits, sign adjust exponent
	cpi rCh, '9'+1
	brge 37f			; no more digits, sign adjust exponent

	; we got another digit, so we are in exponent overflow
	; skip all further digits
32:	ld rCh, Y+			; get next character
	cpi rCh, '0'		; no more digits
	brlo 33f
	cpi rCh, '9'+1
	brlo 32b			; it's a digit, skip it
	
33:	; end of overflowing exponent reached
	pop rExp2L			; restore used register
	pop rExp2H
	ldi rAE0, 0xff		; load exponent with number outside allowed range
	ldi rAE1, 0x1f
	bld rAE1, 7			; including the correct exponent sign
	rjmp .L_cleanup		; cleanup and return +/-INF or +/-0

36:
	clr rExp2H				; for 1- and 2-digit exponents, clear high byte
37:
	; stop parsing, sign adjust exponent
	brtc 38f			; if( expSign )
	neg rExp2H			;	exp = -exp;
	neg rExp2L
	sbci rExp2H, 0
	
38:	;add rExp10L, rExp2L	; add parsed exponent to current base
	;adc rExp10H, rExp10H
	lds r0, .L_exp10L
	add r0, rExp2L
	sts .L_exp10L, r0
	lds r0, .L_exp10H
	adc r0, rExp2H
	sts .L_exp10H, r0

39:	
	pop rExp2L			; and restore exp2
	pop rExp2H

.L_noExp:
	; now we have the significand in A
	; and the exponent in Exp10
	; now build our number = A * 10^Exp10
	push rA7				; save registers used by 10pown
	push rA6
	push rA5
	push rA4
	push rA3
	push rA2
	push rA1
	push rA0

	push rExp2L				; save exponent of A
	push rExp2H
	lds XL, .L_exp10L
	lds XH, .L_exp10H
	;rcall __fp64_saveAB
	XCALL _U(__fp64_10pown)	; create 10^exp10, overwriting rBx and rCx!
	pop rB7
	pop rB6					; restore exponent of A
	
	; rcall __fp64_saveAB

	add rExp2L, rB6
	adc rExp2H, rB7			; exponent2 += 1 + exponent2 of 10^exp10
	adiw rExp2L, 1
	
	pop rB0					; restore significand of A into B
	pop rB1	
	pop rB2
	pop rB3
	pop rB4
	pop rB5
	pop rB6
	pop rB7

	; rcall __fp64_saveAB

	XCALL _U(__fp64_mul64AB)	; C = significand (in B) * 10^exp10 (still in A)
	XCALL _U(__fp64_lshift64)	; shift result to the left
	XCALL _U(__fp64_movAC)		; move result to A

	; adjust exp2 for shifts
	sub rExp2L, r0				; exp2 += shiftLeft(A)
	sbc rExp2H, r1
	
	; now combine everything
	; first round to 56 bits
	; rcall __fp64_saveAB
	sbrs rA0, 7
	rjmp .L_noround
	subi rA1, -1		; add 1 to lowest relevant byte
	brcs .L_noround		; as we have to use subi, C is always set except for rA1 = 0xff
	sec					; in this case we have to handle overflow
	adc rA2, r1
	adc rA3, r1
	adc rA4, r1
	adc rA5, r1
	adc rA6, r1
	adc rA7, r1
	; check if we got an 64bit overflow
	; rcall __fp64_saveAB
	brcc .L_noround
	; 64bit overflow due to rounding --> rA7..rA1 are all 0
	ldi rA7, 0x80
	adiw rExp2L, 1		; goto next higher number

.L_noround:
	; create "normal" 56 bit significand in rA6..rA0
	mov rA0, rA1
	mov rA1, rA2
	mov rA2, rA3
	mov rA3, rA4
	mov rA4, rA5
	mov rA5, rA6
	mov rA6, rA7
	movw rAE0, rExp2L

.L_cleanup:
	; rcall __fp64_saveAB

	pop rB0					; restore saved registers
	pop rB1	
	pop rB2
	pop rB3
	pop rB4
	pop rB5
	pop rB6
	pop rB7
	
	pop rC0					; restore saved registers
	pop rC1
	pop rC2
	pop rC3
	pop rC4
	pop rC5
	pop rC6
	pop rC7
	
	; check whether exponent is in range
	subi rAE0, lo8(-(0x3ff))		; exp += 1023 (exponent base)
	sbci rAE1, hi8(-(0x3ff))
	adiw rAE0,0
	; rcall __fp64_saveAB
	brmi .L_subn			; exponent < 0 --> handle subnormal number / underflow
	breq 40f				; exponent = 0 --> handle subnormal number
	cpi rAE1, 0x07			; exponent < 0x700 --> normal number
	brlo .L_ret
	brne .L_RetInf			; exponent > 0x700 --> overflow
	cpi rAE0, 0xff
	breq .L_RetInf			; exponent = 0x7ff --> overflow
	
.L_ret:	; everything is "normal" now
	call .L_savePtr			; save last parsed position
	pop YL					; restore Y
	pop YH
	; pack and return number
	XJMP _U(__fp64_rpretA)
	
	; exponent to big, return +/-INF
.L_RetInf:
	call .L_savePtr			; save last parsed position and restore sign
	pop YL					; restore Y
	pop YH
	XJMP _U(__fp64_inf)		; and return +/- INF

.L_subn:	; handle subnormal number / underflow
	cpi rAE0, lo8(-51)
	brlt .L_RetZero			; result will not fit into 52 bits --> round down to 0 
	XCALL _U(__fp64_lsrA)	; mantissa >>= 1
	
40:	; shift subnormal number right until exponent is 0
	XCALL _U(__fp64_lsrA)	; mantissa >>= 1
	adiw rAE0, 1			; exponent++
	; rcall __fp64_saveAB
	brmi 40b				; exponent still < 0
	rjmp .L_ret				; and return normally

.L_savePtr:
	; save the current character pointer position in *endPtr
	lds XH, .L_endpH
	lds XL, .L_endpL
	adiw XL, 0				; if( endPtr )
	; rcall __fp64_saveAB
	breq 99f
	adiw YL, 0
	breq 98f
	sbiw YL, 1				; we got one character to far
98:	st X+, YL				;	*endPtr = s;
	st X, YH
99:	lds r0, .L_sign			; set T flag based on sign of significand
	bst r0, 0
	ret
	
.L_RetZero:	
	; result is too small, return +/-0
	rcall .L_savePtr
	pop YL
	pop YH
	XJMP _U(__fp64_szero)

	ENDFUNC

.data
.L_endpH:	.space 1	; temp area to save endPtr
.L_endpL:	.space 1	; temp area to save endPtr
.L_sign:	.space 1	; temp area to save sign of significant
.L_exp10H:	.space 1	; temp area to save Exp10
.L_exp10L:	.space 1	; temp area to save Exp10