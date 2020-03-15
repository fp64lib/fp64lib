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

/* $Id$ */

#if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

/* float64_t fp64_exp10 (float64_t x);
     The fp64_exp10() function returns the value of 10
     raised to the power of x, i.e. 10^x. 
 */
 
#d 
FUNCTION fp64_exp10
ENTRY fp64_exp10
ENTRY fp64_pow10
GCC_ENTRY __exp10
GCC_ENTRY __pow10
	XCALL _U(__fp64_pushB)		; preserve registers
	ldi ZL, lo8(.L_log10)
	ldi ZH, hi8(.L_log10)
	XCALL _U(__fp64_ldb8_const)
	XCALL _U(fp64_mul)
	XCALL _U(__fp64_popB)

	XJMP _U(fp64_exp)			; return with exp(x*ln10) = 10^x

.L_log10: ; log(10) = 0x40026BB1BBB55516 = 2.302585092994045684017994549539580913123
	.byte 0x40, 0x02, 0x6B, 0xB1, 0xBB, 0xB5, 0x55, 0x16

ENDFUNC

#endif /* !defined(__AVR_TINY__) */
