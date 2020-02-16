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

/* stack manipulation routines for B register set */
FUNCTION __fp64_stack

/* __fp64_pushB() save B register set in stack
	Does not rely on YL,YH being the frame pointer
	Function must be called via rcall or call, cannot be a target of rjmp/jmp!

	Input:
		rB7.rB6.rB5.rB4.rB3.rB2.rB1.rB0  - B will be saved on stack
	Return:
		nothing
	Modifies:
		nothing - also SREG is preserved
 */

ENTRY __fp64_pushB
	sts __fp64_saver01, r0		; save r0 & r1 
	sts __fp64_saver01+1, r1
	
	pop r0						; get return address
	pop r1
#if defined (ARDUINO_AVR_MEGA2560)
	sts  __fp64_saver01+2, r0
	pop r0
#endif

ENTRY __fp64_pushB_int
	push rB7					; save B as it will be modified
	push rB6
	push rB5
	push rB4
	push rB3
	push rB2
	push rB1
	push rB0
	
	rjmp .L_ret


/* __fp64_popB() restore B register set
	Does not rely on YL,YH being the frame pointer
	Function must be called via rcall or call, cannot be a target of rjmp/jmp!
   Input:
     none
   Return:
     rB7.rB6.rB5.rB4.rB3.rB2.rB1.rB0  - B restored from stack, as originally pushed by __fp64_pushB
	Modifies:
	 nothing - also SREG is preserved
 */

ENTRY   __fp64_popB
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

ENTRY __fp64_L_ret
.L_ret:					; restore return address, r0&r1 and return to caller
#if defined (ARDUINO_AVR_MEGA2560)
	push r0
	lds r0, __fp64_saver01+2
#endif
	push r1				; push return address back to stack
	push r0

	lds r1, __fp64_saver01+1	; retore r0 & r1
	lds r0, __fp64_saver01
	ret

/* __fp64_popBret() restore B register set and return
	Does not rely on YL,YH being the frame pointer
	Function must jumped to via rjmp/jmp!
	Input:
		none
	Return:
		rB7.rB6.rB5.rB4.rB3.rB2.rB1.rB0  - B restored from stack, as originally pushed by __fp64_pushB
	Modifies:
		nothing - also SREG is preserved
 */

ENTRY   __fp64_popBret
	pop rB0				; restore B
	pop rB1
	pop rB2
	pop rB3
	pop rB4
	pop rB5
	pop rB6
	pop rB7
	ret
ENDFUNC

.data
ENTRY __fp64_saver01
	.skip 3
