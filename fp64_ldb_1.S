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

#include "fp64asm.h"
#include "fp64def.h"

/*	float64_t_intern __fp64_ldb_1()
	load B register with 1.0 in internal, unpacked format
	does not modify any other registers including SREG

	input:		- none -
	output:		rB7.rB6...rB0.rBE1.rBE0		1.0 in unpacked format
*/

ENTRY __fp64_ldb_1
	;; +1.0 with 56 bits precision in unpacked format
	;;        B7    B6    B5    B4    B3    B2    B1    B0    BE1   BE0
	;; .byte  0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xff

	;; Loading by hand is faster / smaller than __fp64_ldb_const.
	ldi rBE0, lo8(0x03ff)
	ldi rBE1, hi8(0x03ff)
	ldi	rB7, 0x00
	ldi rB6, 0x80
	mov	rB5, rB7
	mov	rB4, rB7
	X_movw rB2, rB4
	X_movw rB0, rB4
	ret
ENDFUNC
