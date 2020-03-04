/* Copyright (c) 2017-2020  Uwe Bissinger
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
#include "fp64def.h"
#include "asmdef.h"

/* <non_standard> __fp64_split3 (fp64 A, fp64 B);
	Splits/Unpacks two 64 bit floating point numbers.

   Return:
     rAE1, rAE0, rA6, rA5, rA5, rA3, rA2.rA1.rA0	- exponent and mantissa of A (see __fp64_splitA)
     rBE1, rBE0, rB6, rB5, rB4, rB3, rB2.rB1.rB0	- exponent and mantissa of B (see __fp64_splitA)
     Flags:
        C = 0, Z = 0	- both numbers are finite, A is != 0 
        C = 0, Z = 1	- both numbers are finite, A is 0 
		C = 1		    - A and/or B is Inf (if Z=1)/NaN (if Z=0)
						  NaN has priority over Inf
		T = sign(A) ^ sign(B)

   Notes:
     * Flag is different sense vs __fp64_splitA()
	 * rA7 and rB7 can be used as scratch registers afterwards
     * All other registers are not changed.
 */

FUNCTION __fp64_split3
ENTRY	__fp64_split3
	; rA7[7] := sign(A) ^ sign(B)
	sbrc rB7, 7		; is B negative?
	subi rA7, 0x80	; yes: reverse sign of A
	
	movw rBE0, rB6 	; get exponent from rB7.rB6 into rBE1.rBE0
    andi rBE0, 0xf0 ; get rid of mantissa bits in exponent
    eor  rB6, rBE0  ; and get rid of exponent bits in mantissa
  
	andi rBE1, 0x7f	; clear sign bit
	lsr  rBE1       ; mov exponent downwards 4 bits
	ror  rBE0		
	lsr  rBE1
	ror  rBE0		
	lsr  rBE1
	ror  rBE0		
	lsr  rBE1
	ror  rBE0
	
	; from now on 
	; 	exponent is in rBE1,rBE0, 
	;	mantissa is in rB6 - rB0 (not yet normalized)
	;	sign is not saved, but rA7[7] = sign(A) ^ sign(B)
	adiw rBE0,0	
	breq 4f			; e = 0 --> B is 0 or subnormal
	
	cpi  rBE1, 0x07	; exp(b) = 0x7ff ?
	brne 1f
	cpi  rBE0, 0xff
	breq 5f			; yes --> B is INF or NaN
	
	; it is a normal number --> shift it to the left until MSB is set
1:	rcall 3f
	rcall 3f
	rcall 3f
	lsl rB6   			; set leading one for mantissa (as ori rB6, 0x10 does only work if rB6 is >r15)
	sec
	ror rB6
	rjmp  __fp64_splitA	; split A into rAx, return with flags set from A
	
3:	lsl  rB0			; shift B6.B5....B0 left one bit
	rol  rB1
	rol  rB2
	rol  rB3
	rol  rB4
	rol  rB5
	rol  rB6
	ret				; C = 0
	
	; B is not a finite (i.e. NaN or Inf), exponent rBE1,rBE0 was 0x07ff
	; now check whether B is INF or NaN
	; set Z=1 if INF, else Z=0 for NaN
	; and return with C=1
5:	rcall 3b			; even for NaN make sure that value is decomposed
	rcall 3b			; correctly by shifting mantissa 4 bits to rights	
	rcall 3b			; otherwise it is possible that a NaN might be 
	rcall 3b			; converted to Inf 

	rcall __fp64_splitA	; split A into rAx, return with flags set from A
	brcc 51f		; ignore flags of A for finite number
	brne 52f		; if A is NaN, don't care about flags for B
51:	cp	rB6, r1		; Z = 1 if rBx = 0
	cpc	rB5, r1
	cpc	rB4, r1
	cpc	rB3, r1
	cpc	rB2, r1
	cpc	rB1, r1
	cpc	rB0, r1		; Z = 1 if rB0 = 0
	sec				; set C=1 to indicate NaN or Inf
52:	ret

	; B is zero or subnormal, exponent rBE1,rBE0 was 0
	; now check whether B is subnormal
	; if so set exponent rBE1, rBE0 to 1
4:	rcall 3b			; even for zero and subnormal make sure that value is decomposed
	rcall 3b			; correctly by shifting mantissa 4 bits to rights	
	rcall 3b			; otherwise it is possible that a subnormal might be 
	
	XCALL _U(__fp64_cpc0B5)	; C = 1 if one of Bx > 0
	cpc	r1, rB6		; C = 1, if A is not a zero
	rol	rBE0		; if C = 1 --> exponent rAE0 = 1 else exponent = 0
	; rjmp __fp64_splitA	; split A into rAx, return with flags set from A as B does not matter
	; rjmp eliminated by code rearrangement
	
/* <non_standard> __fp64_splitA (fp64 A);
     Splits an A 64bit floating point number, which conforms to IEEE float format double
	   Bit 63: sign S 0 = + / 1 = -
	   Bits 62-51: exponent E -1022 <= e <= 1023, base 1023
	   Bits 51-0: mantissa M without leading 1 bit
   Return:
	rAE1, rAE0 - exponent:
			0	for +0.0/-0.0
		1..2046	for finite number
		0x07ff	for Inf/NaN
	rA6.rA5.rA4.rA3.rA2.rA1.rA0 - mantissa:
		0x0..0				for +0.0/-0.0
		0x0..1 ... 0x7f..f	for subnormal (and rAE1,rAE0 = 1)
		0x8..0 ... 0xff..ff	for normal (rAE1,rAE0 = 1..254)
		0x0..0				for Inf (rAE1,rAE0 = 0x07ff
		0x0..1 ... 0x7f..ff	for NaN (rAE1,rAE0 = 0x07ff)
	rA7 is undefined on exit
    Flags:
    C = 0, Z = 0	for finite number != 0
	C = 0, Z = 1	for finite number 0
	C = 1, Z = 1	for Inf
	C = 1, Z = 0	for NaN
        T = sign

   Notes:
   * Other registers are not scratched.
 */
ENTRY   __fp64_splitA
	;call __fp64_saveAB ; save value of registers
	bst	rA7, 7		; store sign in T flag (or sign(a)^sign(B))
	movw rAE0, rA6 	; get exponent from rA7.rA6 into rAE1.rAE0
	mov  rAE1, rA7	; save exponent
	andi rAE1, 0x7f	; clear sign bit
	andi rAE0, 0xf0	; clear mantissa bits, keep exponent bits
	lsr  rAE1		; mov exponent downwards 4 bits
	ror  rAE0		

	lsr  rAE1
	ror  rAE0		

	lsr  rAE1
	ror  rAE0		

	lsr  rAE1
	ror  rAE0
	andi rA6, 0x0f 	; get rid of exponent bits
	
	; from now on 
	; 	exponent is in rAE1,rAE0, 
	;	mantissa is in rA6 - rA0 (not yet normalized)
	;	sign in T flag
	adiw rAE0, 0	; is exponent = 0 ?
	breq 6f			; e = 0 --> A is 0 or subnormal
	
	cpi rAE1, 0x07
	brne 88f
	cpi rAE0, 0xff	; is exponent = 2047 (=0x7ff)
	breq 7f			; yes --> A is INF or NaN
	
	; it is a normal number --> shift it to the left until MSB is set
88:	ori  rA6, 0x10	; set leading one for mantissa
8:	XCALL _U(__fp64_lslA)
	XCALL _U(__fp64_lslA)
	XCALL _U(__fp64_lslA)	; shift A6.A5....A0 left one bit
	clz						; clear Z (needed for subnormal numbers as rA6 may be 0)
	ret						; C = 0, Z = 0
	
	; A is zero or subnormal, exponent rAE1,rAE0 was 0
	; now check whether A is subnormal
	; if so set exponent rAE1, rAE0 to 1
6:	XCALL _U(__fp64_cpc0A5)	; C = 1 if one of Ax > 0
	cpc	r1, rA6		; C = 1, if A is not a zero
	rol	rAE0		; if C = 1 --> exponent rAE0 = 1 else exponent = 0
	brne 8b			; if Z != 0 --> subnormal, shift for correct operations
	ret				; return with C = 0, Z = 1 for finite number 0
	
	; A is not a finite (i.e. NaN or Inf), exponent rAE1,rAE0 was 0x07ff
	; now check whether A is INF or NaN
	; set Z=1 if INF, else Z=0 for NaN
	; and return with C=1
7:	XCALL _U(__fp64_lslA)	; even for NaN make sure that value is decomposed
	XCALL _U(__fp64_lslA)	; correctly by shifting mantissa 4 bits to rights	
	XCALL _U(__fp64_lslA)	; otherwise it is possible that a NaN might be 
	XCALL _U(__fp64_lslA)	; converted to Inf 

	cp	rA6, r1		; Z = 1 if rAx = 0
	cpc	rA5, r1
	cpc	rA4, r1
	cpc	rA3, r1
	cpc	rA2, r1
	cpc	rA1, r1
	cpc	rA0, r1		; Z = 1 if rA0 = 0
	sec				; set C=1 to indicate NaN or Inf
	ret
ENDFUNC
	
