/* Copyright (c) 2020  Uwe Bissinger
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

/*	float64_t fp64_atan(float64_4 phi )
	returns the arcus tangens of phi (inverse function to fp64_tan(x)
	
	Basic algorithm:
	fp64_atan (const f7_t *x) {
	  if( isNan(x) )
		return NaN

	  if( isInf(x) ) 
		return PI/2 * sign(x)

	  res = fabs(x)
	  if( res == 0.0 )
		  return 0.0 * sign(x)
	  
	  if( res >= 1.0 )
		  // |x| >= 1:  use atan(x) + atan(1/x) = pi/2 to reduce argument to [0, 1].
		  flag = true
		  res = 1/x
	  
	  x2 = x*x
	  y = horner( x2, coeff_denominator )
	  z = horner( x2, coeff_nominator )
	  res = z / y * res

	  if( flag )
		  // |x| >= 1, res = atan(1/x) --> atan(x) = pi/2 - res
		  res = pi/2 - res = -(res - pi/2)
	  return res*sign(x)
	}
	
*/
FUNCTION fp64_atan

	; case |   x     | atan(x) 
	;------+---------+----------
	;  1   |  NaN    |   NaN   
	;  2   | +/-Inf  | +/-PI/2    
	;  3   | +/-0.0  | +/-0.0   
	;  4   | |x|>1.0 | pi/2-atan(1/x)   
	;  5   |  else   |  atan(x) 

	; case 1: NaN
.L_nan:
	breq .L_inf
	XJMP _U(__fp64_nan)
	
	; case 2: +/-Inf --> return +/- PI/2
.L_inf:
	XJMP _U(__fp64_pi2)
	
	; case 2: 0 --> 0 
.L_zero:
	XJMP _U(__fp64_szero)			; no: return 0.0 for asin

/*	float64_t fp64_atan(float64_4 phi )
	returns the arcus tangens of phi (inverse function to fp64_tan(x)
*/
ENTRY fp64_atan
GCC_ENTRY __atan
	XCALL _U(__fp64_splitA)
	brcs .L_nan						; NaN or +/- INF
	breq .L_zero					; x = 0 --> result of atan = 0
	
	push rA7						; save sign of x

	XCALL _U(__fp64_pushCB)			; as all registers may be used, save them
	push YH
	push YL
	push XH
	push XL

	cpi rAE1, 0x03					; fabs(x) < 1.0?
	brmi 10f						; definitely yes, x < 2^-255 --> go ahead with approximation
	brne 1f							; definitely no, x >= 2.0 --> calculate 1/x
	
	; maybe yes, 2^-255 < x < 2.0
	cpi rAE0, 0xff
	brlo 10f						; |x| < 1.0 --> go ahead with approximation

1:	; here: |x| >= 1.0
	; use atan(x) + atan(1/x) = pi/2 to reduce argument to [0, 1]	
	; --> compute 1/x , which will be <= 1.0

	XCALL _U(__fp64_movBAx)			; B = |x|

	set
	XCALL _U(__fp64_szero)			; will return packed -0, which is nearly unpacked 1.0
	mov rA6, rA7
	clr rA7
	ldi rAE1, 0x03
	ldi rAE0, 0xff
	clt
	; rcall __fp64_saveAB
	XCALL _U(__fp64_divsd3_pse)		; 1/|x|
	inc r1							; flag = true

10:	; here: A = |x| or 1/|x|
	push r1							; save flag
	clr r1
	clt

	XCALL _U(__fp64_movBAx)			; B = A = |x|

	XCALL _U(__fp64_pushA)			; save res = |x| (or 1/|x|)
	push rAE1
	push rAE0

	; rcall __fp64_saveAB
	XCALL _U(__fp64_mulsd3_pse)		; x2 = x^2
	; rcall __fp64_saveA

	XCALL _U(__fp64_pushA)			; save x2 = x^2
	push rAE1
	push rAE0

	ldi XL, lo8(.L_tableAtanDenom)	; calculate Denominator
	ldi XH, hi8(.L_tableAtanDenom)
	; rcall __fp64_saveAB
	XCALL _U(__fp64_powser)
	
	pop rBE0						; retrieve x2 = x^2
	pop rBE1
	XCALL _U(__fp64_popB)

	XCALL _U(__fp64_pushA)			; save y = horner( x2, coeff_denominator )
	push rAE1
	push rAE0
	
	XCALL _U(__fp64_movABx)			; A = B = x2
	ldi XL, lo8(.L_tableAtanNom)	; calculate Nominator
	ldi XH, hi8(.L_tableAtanNom)
	XCALL _U(__fp64_powser)			; z = horner( x2, coeff_nominator )
	; rcall __fp64_saveAB
	
	pop rBE0						; retrieve Denominator y = horner( x2, coeff_denominator )
	pop rBE1
	XCALL _U(__fp64_popB)

	; rcall __fp64_saveAB
	
	XCALL _U(__fp64_divsd3_pse)			; res = z / y
	
	pop rBE0							; retrieve res = |x| or 1/|x|
	pop rBE1
	XCALL _U(__fp64_popB)
	
	XCALL _U(__fp64_mulsd3_pse)			; res = z / y * res
	
	pop r0								; retrieve flag
	tst r0
	breq 19f
	
	; yes: adjust result to PI/2 - res
	XCALL _U(__fp64_ldb_pi2)
	XCALL _U(__fp64_sub_pse)			; compute res - PI/2
	bld rA7, 7							; res = -res --> res = PI/2 - res
	subi rA7, 0x80
	
19:	
	pop XL						; restore all used registers
	pop XH
	pop YL
	pop YH
	XCALL _U(__fp64_popBC)		; restore register set
	
	pop r0						; rerieve sign(x)
	bst r0, 7					; yes, return res*sign

.L_retA:	
	XJMP _U(__fp64_rpretA)		; return res

	; approximation by MiniMax polynom, as discussed on 
	; https://www.mikrocontroller.net/topic/480840#6003520

.L_tableAtanNom:
	; Ideal polynom: 
	; +   0.09762721591717633036983 * x^6
	; +  11.3221594116764655236245  * x^5 
	; + 192.5792014481559613474286  * x^4 
	; +1114.1290728455183546172942  * x^3 
	; +2761.7198246138834959053784  * x^2 
	; +3031.0745956115083044212807  * x 
	; +1209.7470017580907217240715 
	.byte 6	; polynom power = 6 --> 7 entries
	.byte 0x00, 0xc7, 0xf0, 0xc7, 0x1c, 0x82, 0xab, 0x23, 0x03, 0xfb	; 0.09762721591717633036983906357029073391773
	.byte 0x00, 0xb5, 0x27, 0x90, 0xa0, 0x93, 0xfb, 0xfc, 0x04, 0x02	; 11.32215941167646552362524635208795853458
	.byte 0x00, 0xc0, 0x94, 0x46, 0x8b, 0xcd, 0xa0, 0x2d, 0x04, 0x06	; 192.5792014481559613474381288666936740128
	.byte 0x00, 0x8b, 0x44, 0x21, 0x5d, 0x60, 0x49, 0xb2, 0x04, 0x09	; 1114.129072845518354617326550748401814417
	.byte 0x00, 0xac, 0x9b, 0x84, 0x66, 0xd0, 0x77, 0xc4, 0x04, 0x0a	; 2761.719824613883495905211629128928052523
	.byte 0x00, 0xbd, 0x71, 0x31, 0x8b, 0x2a, 0xfd, 0xa7, 0x04, 0x0a	; 3031.074595611508304421159720742906529267
	.byte 0x00, 0x97, 0x37, 0xe7, 0x70, 0x3b, 0x21, 0xbc, 0x04, 0x09	; 1209.747001758090732437267433851957321167
	.byte 0x00												; byte needed for code alignment to even adresses!

.L_tableAtanDenom:
	; Ideal polynom: 
	; +   1.0000000000000000000000 * x^6
	; +  39.9178842486537981501999 * x^5 
	; + 423.0716464809047804524206 * x^4 
	; +1821.6003392918464941509225 * x^3 
	; +3664.5449563283749893504796 * x^2 
	; +3434.3235961975351716547069 * x 
	; +1209.7470017580907287514197 
	.byte 6 ; polynom power = 6 --> 7 entries
	.byte 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xff	; 1.0
	.byte 0x00, 0x9f, 0xab, 0xe9, 0xd9, 0x35, 0xed, 0x27, 0x04, 0x04	; 39.91788424865379815019601761338918777255
	.byte 0x00, 0xd3, 0x89, 0x2b, 0xb6, 0x3e, 0x2e, 0x05, 0x04, 0x07	; 423.0716464809047804524009400717332596287
	.byte 0x00, 0xe3, 0xb3, 0x35, 0xfa, 0xbf, 0x1f, 0x81, 0x04, 0x09	; 1821.600339291846495370919001288712024689
	.byte 0x00, 0xe5, 0x08, 0xb8, 0x24, 0x20, 0x81, 0xe7, 0x04, 0x0a	; 3664.544956328375008069997420534491539001
	.byte 0x00, 0xd6, 0xa5, 0x2d, 0x73, 0x34, 0xd8, 0x60, 0x04, 0x0a	; 3434.323596197535171654739716284865380658
	.byte 0x00, 0x97, 0x37, 0xe7, 0x70, 0x3b, 0x21, 0xbc, 0x04, 0x09	; 1209.747001758090732437267433851957321167
	.byte 0x00												; byte needed for code alignment to even adresses!
ENDFUNC
