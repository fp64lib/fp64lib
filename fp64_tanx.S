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

#include "fp64asm.h"
#include "fp64def.h"

FUNCTION fp64_tan

/* float64_t fp64_cotan (float64_t x);
     The fp64_cotan() function returns the cotangent of x, which is
     defined mathematically as cos(x) / sin(x).
 */

ENTRY fp64_cotan
;; ENTRY_DOUBLE cotan cotanl	; cotan / cotanl are not in math.h.
	com r1						; do cotan

/* float64_t fp64_tan (float64_t x);
     The fp64_tan() function returns the tangent of x, which is
     defined mathematically as sin(x) / cos(x).
 */

ENTRY fp64_tan
ENTRY_DOUBLE tan tanl

.L_tan_common:
	XCALL _U(__fp64_pushB)		; preserve registers

	push r1
	clr  r1

	XCALL _U(__fp64_movBA)		; copy x to B
	XCALL _U(fp64_cos)			; calculate A = cos(x)
	XCALL _U(__fp64_swapAB)		; AX <-> BX:  A = x, B = cos(x)
	XCALL _U(fp64_sin)			; calculate A = sin(x)

	pop r0
	.sbrc_callj r0,0			; tan:   sin(x) / cos(x)
	XCALL _U(__fp64_swapAB)		; cotan: cos(x) / sin(x)

	XCALL _U(fp64_div)			; calculate tan ? sin(x)/cos(x) : cos(x)/sin(x)

	XJMP _U(__fp64_popBret)		; restore registers and return
ENDFUNC
