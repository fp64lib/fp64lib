/* Copyright (c) 2019-2020  Uwe Bissinger
   Based on 32bit floating point arithmetic routines which is:
   Copyright (c) 2002  Michael Stumpf  <mistumpf@de.pepperl-fuchs.com>
   Copyright (c) 2008  Dmitry Xmelkov
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

FUNCTION fp64_compare
/* float64_t fp64_compare (float64_t A, float64_t B);
    Compares the two values A and B and returns -1/0/1,
	based on the following rules:
	 case|	A	 |	B	 |	fp64_compare(A,B)
	-----+-------+-------+--------------------
	 1	 |	NaN	 |	any	 |	1	
	 2	 |	any	 |	NaN	 |	1 
	 3	 | A < B |	any  |	-1 
	 4	 | A == B|	any	 |	0
	 5	 | A > B |	any  |	1
 */
/* GCC expects all these functions to return -1/0/1 as for __cmpsf2 -
   compare with gcc/config/fp-bit.c (the only difference is with NaNs
   where we should always return nonzero for EQ/NE, -1 for GT/GE,
   1 for LT/LE).  -MM 2000-11-18 */
 
ENTRY	fp64_compare
ENTRY   __fp64_cmpsd2
GCC_ENTRY  __eqdf2
GCC_ENTRY  __nedf2
GCC_ENTRY  __ltdf2
GCC_ENTRY  __ledf2
    XCALL _U(__fp64_pushB)
	XCALL	_U(__fp64_cmp)
    XCALL _U(__fp64_popB)
	brcc	1f
	ldi		r24, 1
1:	ret

ENDFUNC
