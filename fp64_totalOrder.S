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

#include "fp64def.h"
#include "fp64asm.h"

FUNCTION fp64_totalOrder
ENTRY fp64_totalOrderMag
/* bool fp64_totalOrderMag(float64_t x, float64_t y)
   fp64_totalOrderMag(x, y) is fp64_totalOrder(abs(x), abs(y)).
 */
	andi rA7, 0x7f				; create abs(x)
	andi rB7, 0x7f				; create abs(y)
	rjmp .L_pos					; shortcut into fp64_totalOrder, as we only have to handle positive values


/* bool fp64_totalOrder(float64_t x, float64_t y);
	fp64_totalOrder(x, y) imposes a total ordering on canonical members of the format of x and y:
	a) If x < y, totalOrder(x, y) is true.
	b) If x > y, totalOrder(x, y) is false.
	c) If x = y:
		1) totalOrder(−0, +0) is true.
		2) totalOrder(+0, −0) is false.
		3) If x and y represent the same floating-point datum:
			i) If x and y have negative sign,
			totalOrder(x, y) is true if and only if the exponent of x ≥ the exponent of y
			ii) otherwise,
			totalOrder(x, y) is true if and only if the exponent of x ≤ the exponent of y.
	d) If x and y are unordered numerically because x or y is a NaN:
		1) totalOrder(−NaN, y) is true where −NaN represents a NaN with negative sign bit and y is a
		floating-point number.
		2) totalOrder(x, −NaN) is false where −NaN represents a NaN with negative sign bit and x is a
		floating-point number.
		3) totalOrder(x, +NaN) is true where +NaN represents a NaN with positive sign bit and x is a
		floating-point number.
		4) totalOrder(+NaN, y) is false where +NaN represents a NaN with positive sign bit and y is a
		floating-point number.
		5) If x and y are both NaNs, then totalOrder reflects a total ordering based on:
			i) negative sign orders below positive sign
			ii) signaling orders below quiet for +NaN, reverse for −NaN
			iii) otherwise, the order of NaNs is implementation-defined.
 */

ENTRY fp64_totalOrder
; GCC_ENTRY __totalOrder
	mov r0, rA7					; is sign(x) == sign(y) ?
	eor r0, rB7
	brmi 1f						; no --> totalOrder = sign(x)-sign(y)

	or rA7, rA7					; yes, are x and y positive ?
	brpl .L_pos					; no --> totalOrder = y - x

	; x and y are negative, now check whether x or y is NaN
	push rA7
	push rB7
	XCALL _U(__fp64_split3)
	pop rB7
	pop rA7						; restore rA7 with original sign

	XCALL _U(__fp64_cpcBA)		; if A <= B, i.e. B is more negative, i.e x < y, then C = 0
	cpc rB7, rA7
	rjmp .L_common

.L_pos:							; x is positive --> totalOrder = y - x
	XCALL _U(__fp64_cpcAB)		; if B > A, i.e. B is more positive, i.e. y > x, then C = 1
	cpc rA7, rB7
	rjmp .L_common

1:	cp rB7, rA7					; different signs, C=0 if A<=B, i.e. A is neg, B is pos, i.e. y < x

.L_common:
	; call __fp64_saveAB
	brcs 4f
	brne 4f
	sec							; if x == y, return true
4:
	ldi r24, 0
	ldi r25, 0
	adc r24, r24				; C = 1 --> x "<=" y
	ret
ENDFUNC
