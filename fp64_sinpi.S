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
	.byte 0x00, 0xce,0x8d,0xc3,0x4b,0x6a,0x2c,0xc3, 0x03,0xea ; +7.69472722742469252749e-07 = +0xc.e8dc34b6a2cc30p-24
	.byte 0x80, 0xb7,0xbc,0xbb,0x86,0x31,0x63,0x93, 0x03,0xef ; -2.19031854143233717878e-05 = -0x1.6f79770c62c726p-16
	.byte 0x00, 0xf4,0x79,0xaf,0x4e,0xac,0xf5,0x3c, 0x03,0xf3 ; +4.66299688773189811809e-04 = +0x1.e8f35e9d59ea78p-12
	.byte 0x80, 0xf1,0x83,0xa6,0xee,0x8e,0xb8,0x60, 0x03,0xf7 ; -7.37043047876341159141e-03 = -0x1.e3074ddd1d70c0p-8
	.byte 0x00, 0xa8,0x3c,0x1a,0x42,0x8c,0x86,0x5a, 0x03,0xfb ; +8.21458865698929015242e-02 = +0x1.50783485190cb4p-4
	.byte 0x80, 0x99,0x69,0x66,0x73,0x13,0xaa,0x14, 0x03,0xfe ; -5.99264529318738248254e-01 = -0x9.969667313aa140p-4
	.byte 0x00, 0xa3,0x35,0xe3,0x3b,0xad,0x53,0x6f, 0x04,0x00 ; +2.55016403987729395331e+00 = +0x2.8cd78ceeb54dbcp+0
	.byte 0x80, 0xa5,0x5d,0xe7,0x31,0x2d,0xf2,0x91, 0x04,0x01 ; -5.16771278004996947875e+00 = -0x5.2aef39896f9488p+0
	.byte 0x00, 0xc9,0x0f,0xda,0xa2,0x21,0x68,0xc2, 0x04,0x00 ; +3.14159265358979322702e+00 = +0x3.243f6a8885a308p+0
ENDOBJ .L_sinpiq
