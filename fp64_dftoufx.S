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

/* Convert a float64_t value in A to an unsigned fixed-point value
   according to the AVR GCC ABI.  */

;;; The double exponent starts at bit 52 since the encoded mantissa has 52 bits.
;;; Note that when X is a multiple of 16, then dex_lo(x) evaluates to 0.
#define DEX16(x)  (x) << (52 - 48)
#define dex_lo(x) lo8 (DEX16 (x))
#define dex_hi(x) hi8 (DEX16 (x))

FUNCTION __fp64_float64_to_ufixed

GCC_ENTRY __fractdfuqq
	;; Multiply with 2^{24+8} to get a UQQ result in r25.
	rcall .L_fixunsdfsi_add32
	mov   r24, r25
	ret

GCC_ENTRY __fractdfuha
	;; Multiply with 2^24 to get a UHA result in r25:r24.
	subi r24, dex_lo (-24)
	sbci r25, dex_hi (-24)
	rjmp .L_fixunsdfsi

GCC_ENTRY __fractdfuhq
GCC_ENTRY __fractdfusq
	;; Multiply with 2^{16+16} to get a UHQ result in r25:r24
	;; resp. with 2^32 to get a USQ result in r25:r22.
.L_fixunsdfsi_add32:
	subi r25, dex_hi (-32)
.L_fixunsdfsi:
	XJMP _U(__fixunsdfsi)

GCC_ENTRY __fractdfusa
	;; Multiply with 2^16 to get a USA result in r25:r22.
	subi r25, dex_hi (-16)
	rjmp .L_fixunsdfsi

GCC_ENTRY __fractdfuda
	;; Multiply with 2^FBIT to get an UDA result in A.
	subi r25, dex_hi (-__UDA_FBIT__)
.L_fixunsdfdi:
	XJMP _U(__fixunsdfdi)

GCC_ENTRY __fractdfuta
	;; Multiply with 2^FBIT to get an UTA result in A.
	subi r25, dex_hi (-__UTA_FBIT__)
	rjmp .L_fixunsdfdi

GCC_ENTRY __fractdfudq
	;; Multiply with 2^FBIT to get an UDQ result in A.
	subi r25, dex_hi (-__UDQ_FBIT__)
	rjmp __fixunsdfdi
ENDFUNC
