/* Copyright (c) 2019  Uwe Bissinger
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

/* float64_t fp64_tanh (float64_t x);
     The fp64_tanh() function returns the hyperbolic tangent of x, which is
     defined mathematically as sinh(x) / cosh(x).
 */

FUNCTION fp64_tanh
ENTRY fp64_tanh
	push	rB7					; save needed registers
	push	rB6
	push	rB5
	push	rB4
	push	rB3
	push	rB2
	push	rB1
	push	rB0

	push	rA7					; save x
	push	rA6
	push	rA5
	push	rA4
	push	rA3
	push	rA2
	push	rA1
	push	rA0

	XCALL _U(fp64_sinh)			; calculate sinh(x) 

	movw rB6, rA6				; save sinh(x)
	movw rB4, rA4
	movw rB2, rA2
	movw rB0, rA0
	
	pop rA0						; restore x
	pop rA1	
	pop rA2
	pop rA3
	pop rA4
	pop rA5
	pop rA6
	pop rA7
	
	XCALL _U(fp64_cosh)			; calculate cosh(x) 
	XCALL _U(fp64_div)			; calculate sinh(x)/cosh(x)
	
	pop rB0						; restore registers
	pop rB1	
	pop rB2
	pop rB3
	pop rB4
	pop rB5
	pop rB6
	pop rB7

	ret
ENDFUNC
