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

/* Convert a float64_t value in A to a signed fixed-point value
   according to the AVR GCC ABI.  */

;;; The double exponent starts at bit 52 since the encoded mantissa has 52 bits.
;;; Note that when X is a multiple of 16, then dex_lo(x) evaluates to 0.
#define DEX16(x)  (x) << (52 - 48)
#define dex_lo(x) lo8 (DEX16 (x))
#define dex_hi(x) hi8 (DEX16 (x))

FUNCTION __fp64_float64_to_sfixed

GCC_ENTRY __fractdfqq
	;; Multiply with 2^{24+7} to get a QQ result in r25.
	rcall .L_fixdfsi_add31
	mov   r24, r25
	ret

GCC_ENTRY __fractdfha
	;; Multiply with 2^{16+7} to get a HA result in r25:r24
	subi r24, dex_lo (-23)
	sbci r25, dex_hi (-23)
	rjmp .L_fixdfsi

GCC_ENTRY __fractdfhq
GCC_ENTRY __fractdfsq
	;; Multiply with 2^{16+15} to get a HQ result in r25:r24
	;; resp. with 2^31 to get a SQ result in r25:r22.
.L_fixdfsi_add31:
	subi r24, dex_lo (-31)
	sbci r25, dex_hi (-31)
.L_fixdfsi:
	XJMP _U(__fixdfsi)

GCC_ENTRY __fractdfsa
	;; Multiply with 2^15 to get a SA result in r25:r22.
	subi r24, dex_lo (-15)
	sbci r25, dex_hi (-15)
	rjmp .L_fixdfsi

GCC_ENTRY __fractdfda
	;; Multiply with 2^FBIT to get a DA result in A.
	subi r24, dex_lo (-__DA_FBIT__)
	sbci r25, dex_hi (-__DA_FBIT__)
.L_fixdfdi:
	XJMP _U(__fixdfdi)

GCC_ENTRY __fractdfta
	;; Multiply with 2^FBIT to get a TA result in A.
	subi r24, dex_lo (-__TA_FBIT__)
	sbci r25, dex_hi (-__TA_FBIT__)
	rjmp .L_fixdfdi

GCC_ENTRY __fractdfdq
	;; Multiply with 2^FBIT to get a DQ result in A.
	subi r24, dex_lo (-__DQ_FBIT__)
	sbci r25, dex_hi (-__DQ_FBIT__)
	rjmp .L_fixdfdi
ENDFUNC
