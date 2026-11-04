/* Copyright (c) 2026  Georg-Johann Lay

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

/* foat64_t fp64_divmod2 (float64_t r18, int8_t r16=expo, int *r14=pquot);
   Unused by fp64lib; just provide a C/C++ interface to divmod2.
   return double r18   = double r18 mod 2^expo
          int16_t *r14 = double r18 div 2^expo  // only if r14 != NULL
   using the smallest non-negative remainder system, i.e. 0 <= rem < 2^expo.
   Large quotients are saturated in such a way that the low byte is kept.  */

ENTRY fp64_divmod2
	XCALL _U(__fp64_splitA)
	brcs .L_ret					; non-finite -> return as is
	;; T = sign AX
	;; rA7 = P modular exponent: do mod 2^P
	mov rA7, r16				; expo
	XCALL _U(__fp64_divmod2_pse.signed)
	XCALL _U(__fp64_rpretA)
	X_movw ZL, r14				; *r14 = quot
	sbiw ZL, 0
	breq .L_ret					; ignore NULL pointer
	std Z + 0, XL
	std Z + 1, XH
.L_ret:
	ret
ENDFUNC
