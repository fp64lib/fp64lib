/* Copyright (c) 2019-2020  Uwe Bissinger
   Based on 32bit floating point arithmetic routines which are:
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

/*	int fp64_classify( float64_x );
	Categorizes floating point value x into the following categories: 
	zero, subnormal, normal, infinite, and NAN.
	The following cases apply:

	case|     x    | result
	----+----------+------------
	  1 |    NaN   | 1
	  2 |  +/-Inf  | 2
	  3 |  +/-0.0  | 0
	  4 | <2^-1023 | 3
	  5 |    any   | 4
*/

#define ret_lo r24
#define ret_hi r25
FUNCTION fp64_classify
.L_nf:
	ldi	rA7, 1			; default for NaN
	brne 1f				; x == NaN? Yes, return default value
	ldi rA7, 2
	rjmp 1f				; else return 2 for INF
ENTRY fp64_classify
	XCALL	_U(__fp64_splitA)
	brcs .L_nf			; NaN or Inf
	mov rA7, r1
	breq 1f				; return 0 for 0
	ldi rA7, 3
	sbrc rA6, 7			; subnormal ? --> bit 7 is not set
	inc rA7				; no, return 3+1=4 for normal number
1:	mov ret_lo, rA7		; get return value
	ldi ret_hi, 0x00	; make sure high byte is cleared
	ret

ENDFUNC
