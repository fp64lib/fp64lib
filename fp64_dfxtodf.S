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

;;; The double exponent starts at bit 52 since the encoded mantissa has 52 bits.
;;; Note that when X is a multiple of 16, then dex_lo(x) evaluates to 0.
#define DEX16(x)  (x) << (52 - 48)
#define dex_lo(x) lo8 (DEX16 (x))
#define dex_hi(x) hi8 (DEX16 (x))

FUNCTION __fp64_ufx64_to_d

;;; Convert an [un]signed 64-bit fixed-point value R18[] to double.
;;;    double .L_ufx64_to_d (ufx64_t R18, uint8_t fbit R30);
;;;    double .L_sfx64_to_d (sfx64_t R18, uint8_t fbit R30);
;;; FBIT accounts for the fractional bits of the fixed-point type,
;;; e.g. pass __DA_FBIT__ for long accum etc.

GCC_ENTRY __fractudadf
	ldi  r30, __UDA_FBIT__
	rjmp .L_ufx64_to_d

GCC_ENTRY __fractutadf
	ldi  r30, __UTA_FBIT__
	rjmp .L_ufx64_to_d

GCC_ENTRY __fractudqdf
	ldi  r30, __UDQ_FBIT__
	;; FALLTHRU

.L_ufx64_to_d:
	push r30
	XCALL _U(__floatundidf)
	rjmp .L_common

;;; Dito for signed.

GCC_ENTRY __fractdadf
	ldi  r30, __DA_FBIT__
	rjmp .L_sfx64_to_d

GCC_ENTRY __fracttadf
	ldi  r30, __TA_FBIT__
	rjmp .L_sfx64_to_d

GCC_ENTRY __fractdqdf
	ldi  r30, __DQ_FBIT__
	;; FALLTHRU

.L_sfx64_to_d:
	push  r30
	XCALL _U(__floatdidf)
.L_common:
	pop   r30

	;; The MSB indicates a value of 0.  Notice that at this point,
	;; we have a normal floating point number with a biased exponent
	;; that won't underflow below.
	tst  rA7
	breq 0f

	;; Subtract fbit from the double exponent.  R30[] = fbit << 4.
	swap r30
	mov  r31, r30
	andi r30, lo8 (0x0ff0)
	andi r31, hi8 (0x0ff0)
	sub  rA6, r30
	sbc  rA7, r31
0:	ret
ENDFUNC
