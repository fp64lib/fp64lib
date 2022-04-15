/* Copyright (c) 2022  Uwe Bissinger
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

/* $Id$ */

#if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

/* float64_t fp64_exp2 (float64_t x);
     The fp64_exp2() function returns the value of 2
     raised to the power of x, i.e. 2^x. 
 */
 
FUNCTION fp64_exp2
ENTRY fp64_exp2
ENTRY fp64_pow2
GCC_ENTRY __exp2
GCC_ENTRY __pow2
	XCALL _U(__fp64_pushB)		; preserve registers
	
#ifdef ARDUINO_AVR_MEGA2560
	in ZL, RAMPZ
	push ZL
	ldi ZL, byte3(.L_log2)
	out RAMPZ, ZL
#endif
	ldi ZL, lo8(.L_log2)
	ldi ZH, hi8(.L_log2)
	XCALL _U(__fp64_ldb8_const)
#ifdef ARDUINO_AVR_MEGA2560
	pop r0
	out RAMPZ, r0	; restore RAMPZ
#endif	

	XCALL _U(fp64_mul)
	XCALL _U(__fp64_popB)

	XJMP _U(fp64_exp)			; return with exp(x*ln10) = 10^x

.L_log2: ; log(2) = 0x3FE62E42FEFA39EF = 0.6931471805599452862267639829951804131269
	.byte 0x3F, 0xE6, 0x2E, 0x42, 0xFE, 0xFA, 0x39, 0xEF

ENDFUNC

#endif /* !defined(__AVR_TINY__) */
