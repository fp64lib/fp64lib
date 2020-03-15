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

/* float64_t fp64_hypot(float64_t x, float64_t y);
     The float64_t() function returns `sqrt (x*x + y*y)'. This is the length
     of the hypotenuse of a right triangle with sides of length x and y,
     or the distance of the point (x, y) from the origin. 
 */

FUNCTION fp64_hypot
ENTRY fp64_hypot
GCC_ENTRY __hypot
	XCALL _U(__fp64_pushB)
	XCALL _U(fp64_square)		; calc x^2
	XCALL _U(__fp64_pushA)		; save x^2
	XCALL _U(__fp64_movAB)		; get y
	XCALL _U(fp64_square)		; calc y^2
	XCALL _U(__fp64_popB)       ; restore x^2 into B
	XCALL _U(fp64_add)			; x^2+y^2
	XCALL _U(__fp64_popB)
	XJMP _U(fp64_sqrt)			; calculate and return sqrt(x^2+y^2)
ENDFUNC
