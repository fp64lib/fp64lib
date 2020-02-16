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

#include "fp64def.h"
#include "asmdef.h"

/*  __fp64_lslA() shift A 1 bit to the left
   Input:
		rA6.rA5.rA4.rA3.rA2.rA1.rA0  - A
   Return:
		rA6.rA5.rA4.rA3.rA2.rA1.rA0  - A << 1
		C - contains MSB of rA6 before shift
	Modifies:
		SREG
 */

FUNCTION __fp64_shift
ENTRY __fp64_lslA
	lsl rA0				; A <<= 1
ENTRY __fp64_lslA1
	rol	rA1
	rol	rA2
	rol	rA3
	rol	rA4
	rol	rA5
	rol	rA6
	ret
	
/*  __fp64_lsrA() shift A 1 bit to the right
   Input:
		rA6.rA5.rA4.rA3.rA2.rA1.rA0  - A
   Return:
		rA6.rA5.rA4.rA3.rA2.rA1.rA0  - A >> 1
		C - contains LSB of rA0 before shift
	Modifies:
		SREG
 */

ENTRY __fp64_lsrA
	lsr rA6				; A >>= 1
ENTRY	__fp64_rorA5
	ror rA5
	ror rA4
	ror rA3
	ror rA2
	ror rA1
	ror rA0
	ret
	
ENDFUNC
