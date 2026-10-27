/* Copyright (c) 2019-2026  Uwe Bissinger
   Based on 32bit floating point arithmetic routines which are:
   Copyright (c) 2002  Michael Stumpf  <mistumpf@de.pepperl-fuchs.com>
   Copyright (c) 2006  Dmitry Xmelkov
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

/* float64_t fp64_fma (float64_t A, float64_t B, float64_t C)
	 The `fp64_fma' function performs floating-point multiply-add. This is the
	 operation (A * B) + C.
	 Current implementation is space optimized, so no effort is taken to
	 work on internal intermediate result. Only advantage for the caller is to
	 save space for the call sequence.
 */

FUNCTION fp64_fma
ENTRY fp64_fma
	XCALL _U(fp64_mul)
	XCALL _U(__fp64_pushB)		; save used registers

	;; With GCC, only up to 16 bytes of parameters are passed via registers.
	;; As three float64_t parameters exceed that limit, the caller has passed
	;; the last parameter on the stack.

#define PUSHED (PC_SIZE + 8)

	.get_SP ZL
	;; "Z + 1" due to AVR's post-decrement PUSH.
	ldd rB0, Z + 1 + PUSHED + 0
	ldd rB1, Z + 1 + PUSHED + 1
	ldd rB2, Z + 1 + PUSHED + 2
	ldd rB3, Z + 1 + PUSHED + 3
	ldd rB4, Z + 1 + PUSHED + 4
	ldd rB5, Z + 1 + PUSHED + 5
	ldd rB6, Z + 1 + PUSHED + 6
	ldd rB7, Z + 1 + PUSHED + 7

	XCALL _U(fp64_add)			; and add c to a*b
	XJMP _U(__fp64_popBret)		; restore used registers and return
ENDFUNC
