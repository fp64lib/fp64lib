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

/*	enum fp64_t_class fp64_class( float64_x );
class(x) tells which of the following ten classes x falls into:
		signalingNaN		// 0, not used
		quietNaN			// 1
		negativeInfinity	// 2
		negativeNormal		// 3
		negativeSubnormal	// 4
		negativeZero		// 5
		positiveZero		// 6
		positiveSubnormal	// 7
		positiveNormal		// 8
		positiveInfinity	// 9
*/

#define ret_lo r24
#define ret_hi r25

FUNCTION fp64_class
.L_nan:							; handle NaN or INF
	ldi rA7, 1					; default for NaN
	brne .L_ret					; x == NaN? Yes, return default value

	ldi rA7, 0x92				; +/-INF
	rjmp .L_common

ENTRY fp64_class
	XCALL	_U(__fp64_splitA)
	brcs .L_nan					; NaN or Inf

	ldi rA7, 0x65
	breq .L_common				; +/-0

	or rA6, rA6					; subnormal do not have the topmost bit set in rA6
	ldi rA7, 0x74				; +/- subnormal
	brpl .L_common

	ldi rA7, 0x83				; +/-normal number

.L_common:
	brts 1f
	swap rA7					; positive number, use upper nibble
1:	andi rA7, 0x0f

.L_ret:
	mov ret_lo, rA7				; get return value
	ldi ret_hi, 0x00			; make sure high byte is cleared
	ret

ENDFUNC
