/* Copyright (c) 2006  Dmitry Xmelkov
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

#ifndef	FP64ASM_H
#define FP64ASM_H

/* Get all the good stuff from AVR-LibC */
#include "asmdef.h"

.macro  ALIAS_ENTRY name
    .global _U(\name)
_U(\name):
.endm

/* Create an entry that is use by GCC standard arithmetik */
.macro  GCC_ENTRY name
	.global	_U(\name)
_U(\name):
.endm


#define NOINIT_SECTION .section .noinit, "a", @nobits

.macro _SWAP	dst, src	/* swap two registers without need of temporary register */
	eor dst, src
	eor src, dst
	eor dst, src
.endm

/* swap two words with the help of r0/r1 */
.macro _SWAPW	dst, src
	movw r0, \src
	movw \src, \dst
	movw \dst, r0
.endm

/* alias to be compatible with AVR programming manual */
// #define byte3(x)	pm_hh8(x)
#define byte3(x)	hh8(x)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Handling 3-byte PC and XICALL according to the AVR GCC ABI
;;; The ABI disallows to change EIND since it would break all
;;; kind of stuff like ISRs.

#if defined (__AVR_2_BYTE_PC__)
#define PC_SIZE 2
#elif defined (__AVR_3_BYTE_PC__)
#define PC_SIZE 3
#else
#error PC_SIZE
#endif /* PC_SIZE */

#endif	/* !FP64ASM_H */
