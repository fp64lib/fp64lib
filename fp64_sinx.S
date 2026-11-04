/* Copyright (c) 2018-2020  Uwe Bissinger
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

/*	float64_t fp64_cos( float64_t phi )
	returns the cosine of phi
*/

ENTRY fp64_cos
ENTRY_DOUBLE cos cosl
	ldi XL, 1					; do cos
	rjmp .L_sincos_common


/*	float64_t fp64_sin( float64_t phi )
	returns the sine of phi
*/

ENTRY fp64_sin
ENTRY_DOUBLE sin sinl
	ldi XL, 0					; do sin
.L_sincos_common:
	XCALL _U(__fp64_splitA)
	brcs .L_nan					; A is not finite -> NaN

	push XL
	XCALL _U(__fp64_pushCB)     ; save registers
	push YL
	push YH
	XCALL _U(__fp64_ldb_1_o_pi)
	XCALL _U(__fp64_muldf3_pse)
	pop YH
	pop YL
	XCALL _U(__fp64_popBC)      ; restore registers
	pop XL						; sin or cos?
	XJMP _U(__fp64_sinpi_pse)	; return A = sinpi(AX) resp. cospi(AX)

.L_nan:
	XJMP _U(__fp64_nan)

ENTRY __fp64_ldb_1_o_pi
	push ZL
	push ZH
	LPMX_INIT ZL, .L_const_1_o_pi
	XJMP _U(__fp64_ldb_const)
ENDFUNC

PGMX_SECTION (fp64.sinx)

;; 1/pi with 56 bits precision in unpacked format
OBJECT .L_const_1_o_pi
	.byte 0x00, 0xa2,0xf9,0x83,0x6e,0x4e,0x44,0x15, 0x03,0xfd ; +3.18309886183790670400e-01 = +0x5.17cc1b727220a8p-4
ENDOBJ .L_const_1_o_pi
