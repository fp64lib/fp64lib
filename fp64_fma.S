/* Copyright (c) 2019-2020  Uwe Bissinger
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

/* $Id$ */

#if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

/* float64_t fp64_fma (float64_t A, float64_t B, float64_t C)
     The `fp64_fma' function performs floating-point multiply-add. This is the   
     operation (A * B) + C.
	 Current implementation is space optimized, so no effort is taken to
	 work on internal intermediate result. Only advantage for the caller is to
	 save space for the call sequence.
 */

FUNCTION fp64_fma
ENTRY fp64_fma
	; rcall __fp64_saveAB
	XCALL	_U(fp64_mul)
	XCALL _U(__fp64_pushB)	; save used registers
	
	; with gcc, only up to 16 bytes of parameters are passed via registers
	; as 3 float64_t as parameters exceed that limit, the last parameter is
	; passed via the stack (pushed by the caller), pointed to by the frame pointer Y
	; So we have to access C via the stack
	sbiw YL, 7				; get to start of paramter
	ld rB0, Y+				; get parameter from stack
	ld rB1, Y+
	ld rB2, Y+
	ld rB3, Y+
	ld rB4, Y+
	ld rB5, Y+
	ld rB6, Y+
	ld rB7, Y				; frame pointer is back to original value
	; rcall __fp64_saveAB
	XCALL _U(fp64_add)		; and add c to a*b
	XJMP _U(__fp64_popBret)	; restore used registers and return
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
