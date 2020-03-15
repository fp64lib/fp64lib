/* Copyright (c) 2019-2020  Uwe Bissinger
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

#include "fp64def.h"
#include "asmdef.h"

/* float64_t fp64_cbrt(float64_t x)
     The fp64_cbrt() returns the cubic root of x. Works for positive and
	 negative values of x
 */

FUNCTION fp64_cbrt
ENTRY fp64_cbrt
GCC_ENTRY __cbrt
	XCALL _U(__fp64_pushB)		; preserve registers

	push rA7					; save original sign
	andi rA7, 0x7f				; delete sign
	
	ldi rB7, 0x3f				; load b with 0x3FD555555555555555LLU = 1/3
	ldi rB6, 0x55
	mov rB5, rB6
	mov rB4, rB6
	movw rB2, rB4
	movw rB0, rB4
	ldi rB6, 0xd5

	XCALL _U(fp64_pow)			; calc x^(1/3) = cbrt(x)
	
	pop r0						; restore original sign
	bst r0, 7
	bld rA7, 7					; and transfer it to result
	XJMP _U(__fp64_popBret)		; restore registers and return
ENDFUNC
