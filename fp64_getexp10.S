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

/*  int16_t __fp64_getExp10(int16_t n);
	int16_t __fp64_getExp10r(int16_t n);
	calculates log10 of a signed number in range -1023-53 < n < 1023
	used in conversion routines from float64_t to decimal
	__fp64_getExp10r rounds the number up to the next integer >= log10(n)
	__fp64_getExp10 truncates down to the next integer <= log10(n)
	input:	rAE1.rAE0		exponent to convert, must be between  -1023-53 < n < 1023
	output:	rBE1.rBE0		log10(n), is between -324 <= log10(n) <= 308
			T flag			sign of exp10
	overwrites:	rAE1.rAE0
			rB7..rB0		
			r0				
 */

FUNCTION __fp64_getExp10
ENTRY   __fp64_getExp10r
	ldi rB7, lo8(999)	
	ldi rB6, hi8(999)
	rjmp __fp64_getExp10int
	
ENTRY   __fp64_getExp10
	clr rB7
	clr rB6

ENTRY __fp64_getExp10int

#if (rExp2L != rAE0) || (rExp2H != rAE1)
#error Code only works when rExp2 == rAE == Z
#endif
	; call __fp64_saveA
	bst rExp2H, 7			; save sign of exponent
	brtc 0f
	neg rExp2H				;	exp2 = -exp2;
	neg rExp2L
	sbci rExp2H, 0
0:
	; rough approximation of exp10 = log10(rA)
	; exp10 = exp2 * log2(10) = exp2 * 301 / 1000
	; if exp10 in correctionTable
	; 	exp10++
	; exp2 * 301 = exp2 * 256 + exp2 * 32 + exp2 * 8 + exp2 * 4 + exp2
	; rB2.rB1.rb0 = rExp2H * 301 			// 301 = 1000*log2(10)
	; rExp10H.rExp10L = rB2.rB1.rB0 / 1000	// --> rExp10 = rExp2 * log2(10)
	
	ldi rExp10L, lo8(301)
	mul rExp10L, rExp2L
	movw rB0, r0			
	eor rB2, rB2					; rB2.rB1.rB0 = 45*exp2L
	mul rExp10L, rExp2H
	add rB1, r0
	adc rB2, r1				; rB2.rB1.rB0 = 45 * exp2
	add rB1, rExp2L
	adc rB2, rExp2H			; rB2.rB1.rB0 += 256*exp2
	clr r1
	; call __fp64_saveAB
							; --> rB2.rB1.rB0 = 301  * exp2
	; now divide by 1000
	; first round to next
	add rB0, rB7
	adc rB1, r1
	adc rB2, r1
	add rB1, rB6
	adc rB2, r1
	
	; biggest exponent base 2 is +1023 
	; --> biggest exponent base 10 is 1023*301 = 307923 = 0x04b2d3
	; biggest 2^n multiple of 1000 that fits into 307923 is 256000 = 0x3e800
	; --> load divisor rB5.rb4.rb3 with 0x03.e8.00
	; --> load rb2.rb1.rb0 with 301*exp2
	
	; rExp10H.rExp10L = rB2.rB1.rB0 / 1000
	ldi rB7, 0x03		; rB5.rB4.rB3 = 0x03e800
	mov rB5, rB7
	ldi rB7, 0xe8
	mov rB4, rB7
	clr rB3
	ldi rB7, 0x09		; max 8 iterations
	clr rExp10H 		; result = 0
	clr rExp10L
	
.L_div:
	; result *= 2
	add rExp10L, rExp10L
	rol rExp10H
	
	; does divisor fit in divident?
	cp rB0, rB3
	cpc rB1, rB4
	cpc rB2, rB5		; divident rB0.rB1.rB2 >= divisor rB3.rB4.rB5 ?
	brlo 3f				; no, skip this iteration
	
	sub rB0, rB3		; yes, so subtract iteration
	sbc rB1, rB4
	sbc rB2, rB5
	adiw rExp10L, 1		; mark result
	
3:	; goto next iteration
	asr rB5				; divisor /= 2
	ror rB4
	ror rB3
	
	dec rB7
	brne .L_div
	
	; approximation of log10(exp2) as 0,301*exp2 is correct for
	; all but 16 values of exp2 in the range between 0 and 1023
	; e.g. log10(196) = 59,0018791501403 = 60 rounded up,
	;		196*0,301 = 58,996			 = 59 rounded up
	; so 1 has to be added to obtain the correct rounded value
	
	; now check for exceptions stored in a table
	; exception table is sorted in ascending order
	; of exp2 values, with terminating value which is always 
	; greater than the biggest exponent
	movw rB4, rExp2L	; save exponent
	ldi ZL, lo8(.L_exc)
	ldi ZH, hi8(.L_exc)

4:	lpm r0, Z+
	cp rB4, r0
	lpm r0, Z+
	cpc rB5, r0
	brlo .L_nomatch		; no match up to now, exp2 is lower than current entry, stop
	brne 4b				; exp2 is greater than current entry, try next one

.L_match:
	adiw rExp10L, 1
.L_nomatch:	
	; previous calculations were all done using abs(exp2)
	; now create -exp10
	brtc 5f					; if exp2 < 0, exp10 has already the correct (positive) sign
	neg rExp10H				;	exp10 = -exp10;
	neg rExp10L
	sbci rExp10H, 0
5:	
	; now exp10H.exp10L contains result, return to caller
	ret	

.L_exc:	; list of exp values where approximation needs to be corrected
		.word 196, 299, 392, 495, 588, 598, 681, 691, 784
		.word 794, 877, 887, 897, 980, 990, 1000, 0x7fff
ENDFUNC
