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


FUNCTION __fp64_ftoa

	; internal entry point with x already split into rA7..rA0 rEA1.rAE0 
	; make sure to properly set Z and T flags: 
	; 	Z=0 x is NaN 
	;	Z=1	x is +/- INF (depending on sign in T)
ENTRY __fp64_ftoa_nan
	ldi XL, lo8(__fp64_ftoabuf)
	ldi XH, hi8(__fp64_ftoabuf)
	push rB7
	
0:	; handle NaN and +/-Inf
	breq 3f					; handle Inf differently
	ldi ZL, lo8(.L_nan)
	ldi ZH, hi8(.L_nan)		; return "NaN"

1:	lpm rA7, Z+				; copy string into buffer
2:	st X+, rA7
	tst rA7
	brne 1b
	st X+, rA7				; store additional '\0' to terminate exponent string
	sec						; flag for special case
	rjmp .L_ret

3:	; handle +/-Inf
	ldi ZL, lo8(.L_inf)
	ldi ZH, hi8(.L_inf)
	ldi rA7, '+'			; return either +Inf
	brtc 2b
	ldi rA7, '-'			; or '-Inf'
	rjmp 2b
	
4:	; handle 0
	ldi rA7, '0'			; return "0"
	st X+, rA7
	clr rA7

	movw ZL, rB2			; if exp10 != NULL, store exponent base 10 here
	adiw ZL, 0
	breq 2b
	st Z+, r1				; exponent is 0
	st Z+, r1
	rjmp 2b
	
/* char *__fp64_ftoa( float64_t x, uint8_t maxDigits, uint8_t expSep, int16_t *exp10 )
   char *fp64_to_decimalExp( float64_t x, uint8_t maxDigits, uint8_t expSep, int16_t *exp10 )
	converts a number to a string with maxDigits of significand
	input:	rA7..rA0:	number x to convert in float64_t format
			rB6:		maximum number of digits in significand
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
ENTRY   __fp64_ftoa
ENTRY	fp64_to_decimalExp
	XCALL _U(__fp64_splitA)
	
	; internal entry point with x already split into rA7..rA0 rEA1.rAE0 
	; make sure to properly set C, Z and T flags: 
	; 	C=1 Z=0 x is NaN 
	;	C=1 Z=1	x is +/- INF (depending on sign in T)
	; 	C=0 Z=1	x is +/- 0.0 (depending on sign in T)
	;	C=0 Z=0 x is a finite number != 0.0, sign is in T
ENTRY __fp64_ftoa_pse
	ldi XL, lo8(__fp64_ftoabuf)
	ldi XH, hi8(__fp64_ftoabuf)
	push rB7
	brcs 0b		; handle NaN and Inf
	breq 4b		; handle 0.0
	
	; TemporaryMemory[len++]= (f_sign) ? '+' : '-';
	ldi rB7, '+'
	brtc 0f
	ldi rB7, '-'
0:	st X+, rB7
	adiw XL, 1					; leave room for '.'
	
	; if(anz_dezimal_mantisse>17)
	;	anz_dezimal_mantisse=17;
	; if(anz_dezimal_mantisse<1)
	; 	anz_dezimal_mantisse=1;
	cpi rB6, MAX_SIGNIFICAND+1	; limit precision to maximal # of significand digits (17)
	brlo 1f
	ldi rB6, MAX_SIGNIFICAND
1:	cpi rB6, 1					; limit precision to be >= 1
	adc rB6, r1

	sts .L_maxDigits, rB6		; save precision as counter
	sts .L_maxDigits2, rB6		; and original value
	sts .L_bufp, XH				; and current pointer
	sts .L_bufp+1, XL
	sts .L_sepExp, rB4			; save flag for seperating significand and mantissa
	
	subi rAE0, 0xff
	sbci rAE1, 0x03			; remove base from exponent

	XCALL _U(__fp64_pushCB) ; save registers used by 10pown

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
	XCALL _U(__fp64_getExp10r)	; and get log10 of A
	; rcall __fp64_saveAB
	push rExp10H
	push rExp10L
	neg rExp10H				;	exp10 = -exp10;
	neg rExp10L
	sbci rExp10H, 0
	XCALL _U(__fp64_10pown)	; create 10^(-exp10), overrides rBx and rCx!
	pop rExp10L
	pop rExp10H

	pop rB7
	pop rB6					; restore exponent of A
	; rcall __fp64_saveAB
	add rExp2L, rB6
	adc rExp2H, rB7			; exponent2 += exponent2 of 10^(-exp10) (result should be between 0 and 3)

	; restore significand of A and expand it to 64 bit
	clr rB0					; lowest 8 bits = 0
	pop rB1					; get 56 bits of significand of A
	pop rB2
	pop rB3
	pop rB4
	pop rB5
	pop rB6
	pop rB7
	pop r0						; throw away rA7
	XCALL _U(__fp64_mul64AB)	; C = significand * 10^-exp10
	XCALL _U(__fp64_lshift64)	;
	XCALL _U(__fp64_movAC)		; move result to A

	adiw rExp2L, 1			; exponent += 1 - shiftLeft(A)
	sub rExp2L, r0
	sbc rExp2H, r1
	
	push YH	
	push YL

	ldi rB7, '0'			; digitBase = '0'
	mov r1, rB7

	lds YH, .L_bufp			; save pointer to current position
	lds YL, .L_bufp+1
	
50:	tst rExp2H
	brpl 51f				; while( exp2 < 0 ) {
	rcall .L_initB10		; 	B = 10;
	rcall .L_nextDigit		;	A = A * 10; exp2 += 4 - shiftLeft(A)
	sbiw rExp10L, 1			;	exp10--
	rjmp 50b				; }
	
	; now rA7...rA0 is A*10^-(exp10)
51:	cpi rExp2L, 3			; if( exp2 < 3 )
	brlo 59f				;	no scaling necessary
	brne 52f				; else if( exp2 > 3 ) scaling necessary
	cpi rA7, 0xa0			; same, if exp2 == 3 and first digit > 9
	brlo 59f
	
52:	ldi rB7, 0xcc			; load B with 0,1
	mov rB6, rB7
	movw rB4, rB6
	movw rB2, rB6
	movw rB0, rB6
	
	push r1
	clr r1
	XCALL _U(__fp64_mul64AB)	; C = A * 0.1
	XCALL _U(__fp64_lshift64)	; shift left C until bit63 is set
	pop r1
	XCALL _U(__fp64_movAC)		; move result back to A
	
	adiw rExp10L, 1				; exp10++
	
	; exp2 = exp2 - 3 - numberOfShifts in r0
	sbiw rExp2L, 3
	sub rExp2L, r0
	sbci rExp2H, 0
	rjmp 51b
	
59:	rcall .L_initB10		; preload B with 10

	; main loop for conversion
6:	clr r0
	tst rExp2H				; if( exp2 < 0 )
	brmi 8f					; 	digit = 0
	
	;	A <<= 1 + exp2
	;   digit = A >> 63-exp2 
7:	add rA0, rA0
	XCALL _U(__fp64_lslA1)
	rol rA7
	rol r0				; highest bit of A now comes into r0
	sbiw rExp2L, 1
	brpl 7b
						; at the end of the loop exp2 = -1
8:	
	add r0, r1			; digit += '0'
	st Y+, r0			; TemporaryMemory[len++] = digit + '0'

	rcall .L_nextDigit

	lds r0, .L_maxDigits
	dec r0
	sts .L_maxDigits, r0
	brpl 6b					; repeat until necessary precision+1 is reached
	
	; check whether rounding is needed
	ld ZL, -Y				; get last digit, overrides exp2 (no longer needed)
	cpi ZL, '5'				; next digit < 5 --> no rounding
	brlo .L_exp
	
	push YH					; save pointer to last digit
	push YL
	lds ZH, .L_maxDigits2
9:	ld ZL, -Y				; get previous digit
	cpi ZL, '9'				
	breq 10f				; if(TemporaryMemory[i]!='9')
	inc ZL					;	++TemporaryMemory[i];
	st Y, ZL
	rjmp 12f
	
10:	ldi ZL, '0'				; else
	st Y, ZL				;	TemporaryMemory[i]='0';
	dec ZH					; repeat until at beginning of string
	brne 9b					; or a digit != 9 is encountered

	; all previous digits where 9 (e.g. 999999)
	; we have to round to 10 and increase the exponent
	; rcall __fp64_saveAB
	adiw rExp10L, 1
	lds ZH, .L_maxDigits2
	inc ZL					; TemporaryMemory[++i]='1';
	st Y+, ZL
	dec ZL					;{
11:	st Y+, ZL				;	TemporaryMemory[++i]='0';
	dec ZH					;} until (i>=len)
	brne 11b
	
12:
	pop YL					; restore pointer to last digit
	pop YH

.L_exp:	; add exponent to digit string
	lds	r0, __fp64_ftoabuf + 2	; get first digit
	sts __fp64_ftoabuf+1, r0	; and put it before the decimal point
	ldi rA7, '.'
	sts __fp64_ftoabuf+2, rA7	; store the decimal point
	
	clr r1						; restore some registers to confirm to libc conventions
	lds r0, .L_sepExp			; do we have to seperate significand and exponent
	tst r0
	breq 13f
	st Y+, r1					; yes, terminate significand with '\0'

13:	
	ldi rA7, 'E'
	st Y+, rA7					; start exponent with 'E'
	;rcall __fp64_saveAB

	adiw rExp10L, 0				
	breq 14f					; if exponent > 0
	brmi 14f
	ldi rA7, '+'				; store +-sign for exponent
	st Y+, rA7
	
14:	ldi r20, 0x0a				; use existing itoa function to convert exponent
	movw r22, YL
	movw r24, rExp10L
	pop YL
	pop YH

	push rExp10H				; save exp10
	push rExp10L
	call __itoa_ncheck
	pop rExp10L
	pop rExp10H 

	XCALL _U(__fp64_popBC)		; restore register set
	
	movw ZL, rB2			; // if exp10 != NULL, store exponent base 10 here
	adiw ZL, 0

	; rcall __fp64_saveAB

	breq .L_retn
	st Z+, rExp10L
	st Z+, rExp10H

.L_retn:
	clc						; clear carry for normal cases

.L_ret:
	ldi XL, lo8(__fp64_ftoabuf)	; load return buffer address
	ldi XH, hi8(__fp64_ftoabuf)

	brcs 99f
	ld r24, X					; skip if first character is '+'
	cpi r24, '-'				; '+' is 0x2b, '-' is 0x2d --> C is set when character is '+'
	adc XL, r1
	adc XH, r1
99:	
	movw r24, XL				; and return address
	pop rB7
	ret
	
.L_initB10:					; initialize B with 10
	ldi rB7, 0xa0			; B = 10 << 60;
	clr rB6
	clr rB5
	clr rB4
	movw rB2, rB4
	movw rB0, rB2
	ret
	
	; get next digit
.L_nextDigit:
	push r1
	clr r1
	XCALL _U(__fp64_mul64AB)	; C = A * 10
	XCALL _U(__fp64_lshift64)	; shift left C until bit63 is set
	pop r1
	XCALL _U(__fp64_movAC)		; move result back to A
	
	; exp2 = exp2 + 4 - numberOfShifts in r0
	adiw rExp2L, 4
	sub rExp2L, r0
	sbci rExp2H, 0
	ret
	

.L_nan:	.asciz "NaN"
.L_inf:	.asciz "INF"
ENDFUNC

.data
.L_bufp:		.space 2	; pointer to current location in __fp64_ftoabuf
.L_maxDigits:	.space 1	; maximum number of digits, working counter
.L_maxDigits2:	.space 1	; maximum number of digits, original value
.L_sepExp:		.space 1	; flag to seperate significand and exponent
__fp64_ftoabuf:	.space 2+MAX_SIGNIFICAND+3+MAX_EXPONENT, 0	; max 26 bytes needed:
														; 1 for sign
														; 1 for leading digit
														; 1 for decimal point '.'
														; 16 for trailing digits
														; 1 for optional terminating '\0' for significand
														; 1 for 'E'
														; 1 for sign of exponent
														; 3 for exponent
														; 1 for terminating character \0
