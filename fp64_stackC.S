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

/* stack manipulation routines for C register set */
FUNCTION __fp64_stack

/* __fp64_pushCB() save C & B register set in stack
	Does not rely on YL,YH being the frame pointer
	Function must be called via rcall or call, cannot be a target of rjmp/jmp!

	Input:
		rC7.rC6.rC5.rC4.rC3.rC2.rC1.rC0  - C will be saved on stack
		rB7.rB6.rB5.rB4.rB3.rB2.rB1.rB0  - B will be saved on stack
	Return:
		nothing
	Modifies:
		nothing - also SREG is preserved
 */

ENTRY __fp64_pushCB
	sts __fp64_saver01, r0		; save r0 & r1 
	sts __fp64_saver01+1, r1
	
	pop r0						; get return address
	pop r1
#if defined (ARDUINO_AVR_MEGA2560)
	sts  __fp64_saver01+2, r0
	pop r0
#endif

	push rC7					; save B as it will be modified
	push rC6
	push rC5
	push rC4
	push rC3
	push rC2
	push rC1
	push rC0
	
	XJMP _U(__fp64_pushB_int)	; continue with pushing B


/* __fp64_popBC() restore B & C register set
	Does not rely on YL,YH being the frame pointer
	Function must be called via rcall or call, cannot be a target of rjmp/jmp!
	Input:
		none
	Return:
		rB7.rB6.rB5.rB4.rB3.rB2.rB1.rB0  - B restored from stack, as originally pushed by __fp64_pushCB
		rC7.rC6.rC5.rC4.rC3.rC2.rC1.rC0  - C restored from stack, as originally pushed by __fp64_pushCB
	Modifies:
		nothing - also SREG is preserved
 */

ENTRY   __fp64_popBC
	;call __fp64_saveAB
	sts __fp64_saver01, r0	; save r0 & r1 
	sts __fp64_saver01+1, r1
	
	pop r0				; get return address
	pop r1
#if defined (ARDUINO_AVR_MEGA2560)
	sts  __fp64_saver01+2, r0
	pop r0
#endif

	pop rB0				; restore B
	pop rB1
	pop rB2
	pop rB3
	pop rB4
	pop rB5
	pop rB6
	pop rB7

	pop rC0				; restore C
	pop rC1
	pop rC2
	pop rC3
	pop rC4
	pop rC5
	pop rC6
	pop rC7
	
	XJMP _U(__fp64_L_ret)
ENDFUNC
