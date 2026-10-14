/* Copyright (c) 2026  Uwe Bissinger
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

FUNCTION fp64_minNumber
/* float64_t fp64_maximumNumber(float64_t x, float64_t y);
	fp64_maximumNumber(x, y) returns the bigger of it's arguments. 
	This is x if x > y, y if y > x. , and the number 
	if one operand is a number and the other is a NaN.
	For this operation, +0 compares greater than −0.
	If both operands are NaNs, a NaN is returned
 */
ENTRY fp64_maximumNumber
	subi rA7, 0x80			; max(a,b) = -min(-a,-b), e.g. max(5,3) = -min(-5,-3) = -(-5) = 5
	subi rB7, 0x80
	rcall fp64_minimumNumber
	subi rA7, 0x80
	ret
	
.L_nan:	; one of the numbers is a NaN --> return the one that is a number
	cpi rAE1, 0x07			; check A for being a NaN
	brne .L_retA			; it's not A, so return A
	cpi rAE0, 0xff
	brne .L_retA			; it's not A, so return A

	; now A is either a NaN an B a number incl. INF, or A is INF and B is NaN
	XCALL _U(__fp64_cpc0A5)
	cpc r1, rA6
	brne .L_retB			; A is not INF, return BE
	rjmp .L_retA			; A is INF, so B must be the NaN, return A


/* float64_t fp64_minimumNumber(float64_t x, float64_t y);
    fp64_minimum(x, y) returns the smaller of its arguments. 
	This x if x < y, y if y < x, and the number 
	if one operand is a number and the other is a NaN. 
	For this operation, −0 compares less than +0.
	If both operands are NaNs, a NaN is returned
 */

ENTRY fp64_minimumNumber
	push rA7				; save the original sign bits
	push rB7

ENTRY __fp64_minNum_intern	; entry point for other min/max routines	
	push rA7
	push rB7
	XCALL _U(__fp64_split3)
	pop rB7					; retrieve original sign bits
	pop rA7
	; rcall __fp64_saveAB
	brcc 1f					; normal numbers
	brne .L_nan				; one is Nan --> return NaN

1:	brts .L_sign			; x and y have a different sign
	or rA7, rA7				; sign(x) = sign(y), are both negative?
	brmi .L_neg
							; no, both are positive
	XCALL _U(__fp64_cpcAB)	; if B > A, i.e. x < y, then C = 1
	cpc rA7, rB7			
	rjmp .L_common
	
.L_neg:						; both numbers are negative
	XCALL _U(__fp64_cpcBA)	; if A <= B, i.e. B is more negative, i.e y < x, then C = 0
	
.L_sign:
	; x and y have a different sign --> return the negative number, 
	; i.e. the one with the bigger value in rX7
	cpc rB7, rA7

.L_common:
	brcs .L_retA			; A is the smaller number

.L_retB:
	pop rB7					; retrieve the original signs
	pop rA7
	XCALL _U(__fp64_movABx)	; B is the smaller number, move B to A to return it
	rjmp 2f
	
.L_retA:
	pop rB7					; retrieve the original signs
	pop rA7
2:
	; rcall __fp64_saveAB
	bst rA7, 7
	cpi rAE1, 0x07			; check for +/-INF or NaN, as __fp64_pretA does not handle it
	brne 3f
	cpi rAE0, 0xff
	brne 3f
	XCALL _U(__fp64_cpc0A5)
	cpc r1, rA6				; is A INF?
	breq .L_inf				; yes, return INF
	XJMP _U(__fp64_nan)		; no, return NaN
	
.L_inf:
	XJMP _U(__fp64_inf)		; return +/-INF
3:
	XJMP _U(__fp64_pretA)	; pack and return A
	
ENDFUNC
