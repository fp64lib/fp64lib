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

/* stack manipulation routines for A register set */
FUNCTION __fp64_stack

/* __fp64_pushA() save A register set in stack
	Does not rely on YL,YH being the frame pointer
	Function must be called via rcall or call, cannot be a target of rjmp/jmp!

	Input:
		rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0  - A will be saved on stack
	Return:
		nothing
	Modifies:
		nothing - also SREG is preserved
 */

ENTRY __fp64_pushA
	sts __fp64_saver01, r0		; save r0 & r1 
	sts __fp64_saver01+1, r1
	
	pop r0						; get return address
	pop r1
#if defined (ARDUINO_AVR_MEGA2560)
	sts  __fp64_saver01+2, r0
	pop r0
#endif

	push rA7					; save A
	push rA6
	push rA5
	push rA4
	push rA3
	push rA2
	push rA1
	push rA0
	
	XJMP _U(__fp64_L_ret)


/* __fp64_popA() restore A register set
	Does not rely on YL,YH being the frame pointer
	Function must be called via rcall or call, cannot be a target of rjmp/jmp!
	Input:
		none
	Return:
		rA7.rA6.rA5.rA4.rA3.rA2.rA1.rA0  - A will be saved on stack
	Modifies:
		nothing - also SREG is preserved
 */

ENTRY   __fp64_popA
	;call __fp64_saveAB
	sts __fp64_saver01, r0	; save r0 & r1 
	sts __fp64_saver01+1, r1
	
	pop r0				; get return address
	pop r1
#if defined (ARDUINO_AVR_MEGA2560)
	sts  __fp64_saver01+2, r0
	pop r0
#endif

	pop rA0				; restore B
	pop rA1
	pop rA2
	pop rA3
	pop rA4
	pop rA5
	pop rA6
	pop rA7

	XJMP _U(__fp64_L_ret)

ENDFUNC