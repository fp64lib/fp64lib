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

/* Convert signed and unsigned 8-bit, 16-bit and 32-bit fixed-point
   values to float64_t complying to the AVR GCC ABI.  */

;;; The double exponent starts at bit 52 since the encoded mantissa has 52 bits.
;;; Note that when X is a multiple of 16, then dex_lo(x) evaluates to 0.
#define DEX16(x)  (x) << (52 - 48)
#define dex_lo(x) lo8 (DEX16 (x))
#define dex_hi(x) hi8 (DEX16 (x))

FUNCTION __fp64_sfx_to_d

GCC_ENTRY __fractuhadf
	;; Extend UHA to USA.
	clr r22
	mov r23, r24
	mov r24, r25
	clr r25
GCC_ENTRY __fractusadf
	;; Convert USI to DF.
	XCALL _U(__floatunsidf)
	;; The MSB indicates a value of 0.
	cpse rA7, __zero_reg__
	;; Divide non-zero values by 2^16 in order to adjust for FBIT = 16.
	subi rA7, dex_hi (16)
	ret

GCC_ENTRY __fracthadf
	;; Extend HA to SA.
	clr r22
	mov r23, r24
	mov r24, r25
	lsl r25
	sbc r25, r25
GCC_ENTRY __fractsadf
	;; Convert SI to DF.
	XCALL _U(__floatsidf)
	;; The MSB indicates a value of 0.
	tst  rA7
	breq 0f
	;; Divide non-zero values by 2^15 in order to adjust for FBIT = 15.
	subi rA6, dex_lo (15)
	sbci rA7, dex_hi (15)
0:  ret


GCC_ENTRY __fractuqqdf
	;; Extend UQQ to UHQ.
	mov r25, r24
	clr r24
GCC_ENTRY __fractuhqdf
	;; Extend UHQ to USQ.
	clr r23
	clr r22
GCC_ENTRY __fractusqdf
	;; Convert USI to DF.
	XCALL _U(__floatunsidf)
	;; The MSB indicates a value of 0.
	cpse rA7, __zero_reg__
	;; Divide non-zero values by 2^32 in order to adjust for FBIT = 32.
	subi rA7, dex_hi (32)
	ret

GCC_ENTRY __fractqqdf
	;; Extend QQ to HQ.
	mov r25, r24
	clr r24
GCC_ENTRY __fracthqdf
	;; Extend HQ to SQ.
	clr r23
	clr r22
GCC_ENTRY __fractsqdf
	;; Convert SI to DF.
	XCALL _U(__floatsidf)
	;; The MSB indicates a value of 0.
	tst rA7
	breq 0f
	;; Divide non-zero values by 2^31 in order to adjust for FBIT = 31.
	subi rA6, dex_lo (31)
	sbci rA7, dex_hi (31)
0:  ret
ENDFUNC
