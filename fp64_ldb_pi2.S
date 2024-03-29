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

FUNCTION __fp64_ldb_pi2

/*	float64_t_intern __fp64_ldb_pi2x()
	load B register with π-PI/2 in internal, unpacked format
	does not modify any other registers except SREG
	
	input:		- none -
	output:		rB7.rB6...rB0.rBE1.rBE0		PI/2 in unpacked format
				
*/
ENTRY __fp64_ldb_pi2x
	push ZL				; load b with PI/2
	push ZH
#ifdef ARDUINO_AVR_MEGA2560
	in ZL, RAMPZ
	push ZL
	ldi zl, byte3(__pi_o_2x)
	out RAMPZ, ZL
#endif
	ldi ZL, lo8(__pi_o_2x)
	ldi ZH, hi8(__pi_o_2x)
	rjmp __fp64_ldb_const
	
/*	float64_t_intern __fp64_ldb_pi2()
	load B register with PI/2 in internal, unpacked format
	does not modify any other registers except SREG
	
	input:		- none -
	output:		rB7.rB6...rB0.rBE1.rBE0		PI/2 in unpacked format
				
*/
ENTRY __fp64_ldb_pi2
	push ZL				; load b with PI/2
	push ZH
#ifdef ARDUINO_AVR_MEGA2560
	in ZL, RAMPZ
	push ZL
	ldi ZL, byte3(__pi_o_2)
	out  RAMPZ, ZL
#endif
	ldi ZL, lo8(__pi_o_2)
	ldi ZH, hi8(__pi_o_2)
	
ENTRY __fp64_ldb_const
	rcall __fp64_ldb8_const
	
#ifdef ARDUINO_AVR_MEGA2560
	elpm rBE1, Z+
	elpm rBE0, Z+
	pop ZL
	out  RAMPZ, ZL	; restore RAMPZ
#else	
	lpm rBE1, Z+
	lpm rBE0, Z+
#endif
	
	pop ZH
	pop ZL
	ret
	
/*	float64_t_intern __fp64_ldb8_const()
	load B register with constant from flash
	does not modify any other registers except SREG
	ATTENTION: caller has to set/reset RAMPZ properly!!!
	
	input:		RAMPZ.ZH.ZL								pointer to flash
	output:		rB7.rB6...rB0.rBE1.rBE0		PI/2 in unpacked format
				
*/
ENTRY __fp64_ldb8_const
#ifdef ARDUINO_AVR_MEGA2560
	elpm rB7, Z+
	elpm rB6, Z+
	elpm rB5, Z+
	elpm rB4, Z+
	elpm rB3, Z+
	elpm rB2, Z+
	elpm rB1, Z+
	elpm rB0, Z+
#else
	lpm rB7, Z+
	lpm rB6, Z+
	lpm rB5, Z+
	lpm rB4, Z+
	lpm rB3, Z+
	lpm rB2, Z+
	lpm rB1, Z+
	lpm rB0, Z+
#endif
	ret
	
	; PI/2 with 56 bits precision in unpacked format
__pi_o_2:	  .byte  0x00, 0xC9, 0x0F, 0xDA, 0xA2, 0x21, 0x68, 0xC2, 0x03, 0xff	; PI/2   = 1.570796326794896613510132965529919601977
__pi_o_2x:	.byte  0x00, 0xD3, 0x13, 0x19, 0x8A, 0x2E, 0x03, 0x70, 0x03, 0xc5	; π-PI/2 = 5.721188726109831797891137135379528169152E-18
ENDFUNC
