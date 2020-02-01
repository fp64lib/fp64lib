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
	; with gcc, only up to 16 bytes of parameters are passed via registers
	; as 3 float64_t as parameters exceed that limit, the last parameter is
	; passed via the stack (pushed by the caller).
	; So we have to access c via the stack
	push YL					; save current value of frame pointer
	push YH
	in YL, 0x3d				; get stack pointer to get access to parameters on the stack
	in YH, 0x3e
	ldd rB0, Y+5			; Y+1/+2 = YL/YH, Y+3/+4 = return address, Y+5 = c
	ldd rB1, Y+6			; parameters are pushed MSB first
	ldd rB2, Y+7
	ldd rB3, Y+8
	ldd rB4, Y+9
	ldd rB5, Y+10
	ldd rB6, Y+11
	ldd rB7, Y+12
	; rcall __fp64_saveAB
	pop YH					; restore frame pointer Y
	pop YL
	XJMP	_U(fp64_add)	; and add c to a*b
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
