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

#include "fp64asm.h"
#include "fp64def.h"

FUNCTION fp64_minMag

/* float64_t maximumMagnitude(float64_t x, float64_t y);
	fp64_maximumMagnitude(x, y) is x if |x| > |y|, y if |y| > |x|, otherwise maximum(x, y).
 */
ENTRY fp64_maximumMagnitude
	push rA7				; save the sign bits as the functions shall return x or y
	push rB7

	push rA7
	eor rA7, rB7			; do x and y have different sign?
	bst rA7, 7
	pop rA7

	ori rA7, 0x80			; now get minimum( -|x|, -|y|) = -maximum( |x|, |y| )
	ori rB7, 0x80			; but as we saved the original sign, this will return x or y
	brtc .L_min				; no special handling is sign(x) == sign(y)

	XCALL _U(__fp64_cpcAB)	; is y = -x?
	cpc rA7, rB7			;
	brne .L_min				; no, do normal minimum(|x|,|y|)

	; yes, y = -x --> return the one with the positive sign
	pop rB7					; restore original signs
	pop rA7
	andi rA7, 0x7f			; make sure sign is cleared
0:	ret

/* float64_t minimumMagnitude(float64_t x, float64_t y);
	minimumMagnitude(x, y) is x if |x| < |y|, y if |y| < |x|, otherwise minimum(x, y)
 */
ENTRY fp64_minimumMagnitude
	push rA7				; save the sign bits to be able to return x, y
	push rB7

	push rA7
	eor rA7, rB7			; do x and y have different sign?
	bst rA7, 7
	pop rA7

	andi rA7, 0x7f			; remove sign, create |x|, |y|
	andi rB7, 0x7f
	brtc .L_min				; no special handling is sign(x) == sign(y)

	XCALL _U(__fp64_cpcAB)	; is y = -x?
	cpc rA7, rB7			;
	brne .L_min				; no, do normal minimum(|x|,|y|)

	; yes, y = -x --> return the one with the negative sign
	pop rB7					; restore original signs
	pop rA7
	ori rA7, 0x80			; make sure sign is set
0:	ret

.L_min:						; jump to fp64_minimum routine
	; having this separate allows for more room between jump targets
	XJMP _U(__fp64_min_intern)

ENDFUNC
