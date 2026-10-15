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

FUNCTION fp64_isSubnormal
/* bool fp64_isSubnormal(float64_t x);
	 fp64_isSubnormal(x) is true if and only if x is subnormal.
 */

ENTRY fp64_isSubnormal
; GCC_ENTRY __isSubnormal
	XCALL	_U(__fp64_splitA)	; decompose number
	mov r0, rA6					; save first byte of significand
	ldi r25, 0x80				; this will toggle the topmost bit of rA6,
	rjmp .L_common				; converting a normal number into a subnormal and v.vs.

/* bool fp64_isNormal(float64_t x);
	 fp64_isNormal(x) is true if and only if x is normal (not zero, subnormal, infinite, or NaN).
 */

ENTRY fp64_isNormal
; GCC_ENTRY __isNormal
	XCALL	_U(__fp64_splitA)	; decompose number
	mov r0, rA6					; save first byte of significand
	ldi r25, 0					; don't change topmost bit of rA6
.L_common:
	ldi r24, 0
	brcs 0f						; C is set for NaN or Inf
	breq 0f						; Z is set for zero
	add r0, r25					; convert and check bit 7 in rA6, if not set
	brpl 0f						;	it's a subnormal number
	adiw r24, 1					; otherwise, return true for a normal number
0:	ldi r25, 0
	ret
ENDFUNC
