/* Copyright (c) 2026  Georg-Johann Lay

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

/*	float64_t fp64_cospi( float64_t x )
	returns the cosine of pi * x

	The implementation returns ±1 when x is an integer
*/

ENTRY fp64_cospi
ENTRY_DOUBLE cospi cospil
	ldi XL, 1					; do cos
	rjmp .L_sinpicospi.common

/*	float64_t fp64_sinpi( float64_t x )
	returns the sine of pi * x

	The implementation returns ±1.0 when x is an odd multiple of 0.5
*/

ENTRY fp64_sinpi
ENTRY_DOUBLE sinpi sinpil
	ldi XL, 0					; do sin

.L_sinpicospi.common:
	XCALL _U(__fp64_splitA)
	brcs .L_nan					; A is not finite --> NaN

;;; Entry point from fp64_sin.
;;; return A = sinpi (AX)   # XL = 0
;;; return A = cospi (AX)   # XL = 1
ENTRY __fp64_sinpi_pse
	sbrc XL, 0
	clt							; if do cos: x -> |x|
	push XL
	;; sinpi has a period of 2, so mod 0.5 gives 4 quadrants.
	ldi rA7, -1					; modulo 0.5 = 2^-1
	XCALL _U(__fp64_divmod2_pse.unsigned) ; ignores and keeps T
	;; Now the quadrant of |x| is in XL[0..1].

	pop r0						; do cos?

	XCALL _U(__fp64_pushCB)
	push YL
	push YH

	;; For cos we use  cos(x) = cos(|x|) = sin(pi/2 ± x).
	add XL, r0					; if cos: cos(x) = sin(pi/2 + x) -> ++quadrant

	;; Ready to compute sinpi for x >= 0.  For negative arguments make use of
	;; sin(x) = sin(pi - x) = sin(pi + |x|) so advance quadrant by 2 if x < 0.
	brtc 10f
	subi XL, 2					; sin(x < 0) advance quadrant by 2 mod 4
10:
	push XL						; save quadrant XL[0..1]

	;; Negate the argument for odd quadrants.  Since we are
	;; mod 0.5, negating means x -> 0.5 - x.
	sbrs XL, 0					; odd quadrant?
	rjmp 20f					; no: skip negating x mod 0.5
	XCALL _U(__fp64_ldb_1)		; yes: BX = 1.0
	dec rBE0					;      BX = 0.5
	ldi	rA7, 0x80				;      rA7.7 = sign(AX) := 1 for subtraction
	set							;      T = sign(A) ^ sign(B) = 1 ^ 0
	XCALL _U(__fp64_add_pse)	;      AX -> 0.5 - AX
20:
	clt							; non-negative since  S : [0, 1/2] -> [0, 1]
	LPMX_INIT XL, .L_sinpiq		; S(x) = sin(pi * sqrt(x)) / sqrt(x)
	XCALL _U(__fp64_powsodd)	; packed result (overflow C = 1) doesn't occur
	pop XL					  	; restore quadrant
	bst XL, 1					; T = sign of sine: quadrant 0123 -> ++--

	pop YH
	pop YL
	XCALL _U(__fp64_popBC)
	XJMP  _U(__fp64_rpretA)

.L_nan:
	XJMP _U(__fp64_nan)
ENDFUNC

PGMX_SECTION (fp64.sinpi)

OBJECT .L_sinpiq
	;; Degree 8 MiniMax polynomial with minimal relative error for
	;; S(x) = sin(pi * sqrt(x)) / sqrt(x)  over [0, 1/4]  i.e.
	;; x * S(x^2) = sin(pi * x)   used for x in [0, 1/2)
	.byte 8
	.byte C(+, 0xce,0xa3,0x58,0x37,0xe6,0x71,0xbc, -21) ; +7.69786778298569675725e-07 = +0xc.ea35837e671bd0p-24
	.byte C(-, 0xb7,0xbd,0x69,0x1d,0xba,0xe8,0x3d, -16) ; -2.19035011762266135445e-05 = -0x1.6f7ad23b75d07ap-16
	.byte C(+, 0xf4,0x79,0xb3,0xbe,0x19,0xfe,0xd0, -12) ; +4.66299817856172965115e-04 = +0x1.e8f3677c33fda0p-12
	.byte C(-, 0xf1,0x83,0xa6,0xfd,0xad,0xd9,0xe7,  -8) ; -7.37043050626945146341e-03 = -0x1.e3074dfb5bb3cep-8
	.byte C(+, 0xa8,0x3c,0x1a,0x42,0xa9,0x1f,0xa4,  -4) ; +8.21458865731442069991e-02 = +0x1.50783485523f48p-4
	.byte C(-, 0x99,0x69,0x66,0x73,0x13,0xe4,0xed,  -1) ; -5.99264529318947317127e-01 = -0x9.969667313e4ed0p-4
	.byte C(+, 0xa3,0x35,0xe3,0x3b,0xad,0x53,0xe6,  +1) ; +2.55016403987730055913e+00 = +0x2.8cd78ceeb54f98p+0
	.byte C(-, 0xa5,0x5d,0xe7,0x31,0x2d,0xf2,0x92,  +2) ; -5.16771278004996958977e+00 = -0x5.2aef39896f9490p+0
	.byte C(+, 0xc9,0x0f,0xda,0xa2,0x21,0x68,0xc2,  +1) ; +3.14159265358979322702e+00 = +0x3.243f6a8885a308p+0
ENDOBJ .L_sinpiq
