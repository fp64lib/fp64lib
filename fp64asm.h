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

/* Put functions at this section.	*/
#ifdef	FUNCTION
#error	"The FUNCTION macro must be defined after FUNC_SEGNAME"
#endif

#define FUNC_SEGNAME	.text.libfp64.asm


/* Get all the good stuff from AVR-LibC */
#include "asmdef.h"


/* Arduino is spoiling SFR definitions, so build them from scratch.  */
#undef SREG
#undef SREG_IO_ADDR
#define SREG_IO_ADDR 0x3f
#define SREG SREG_IO_ADDR

#undef RAMPZ
#undef RAMPZ_IO_ADDR
#if defined (__AVR_HAVE_RAMPZ__)
#define RAMPZ_IO_ADDR 0x3b
#define RAMPZ RAMPZ_IO_ADDR
#endif

.macro  ALIAS_ENTRY name
    .global _U(\name)
_U(\name):
.endm

;;; Create an entry as used / expected by libgcc / GCC.
.macro  GCC_ENTRY name
	.global	_U(\name)
_U(\name):
.endm

;;; Define a global symbol SYM for libgcc / GCC.
.macro GCC_DEFSYM sym, val
	.global \sym
	.type \sym, "function"
	\sym = \val
.endm

;;; An entry for math.h, FD for double and FL for long double.
;;; Other than ENTRY_FLOAT, we don't .weak-en the symbols so that
;;; they are stronger than libgcc/libf7's, which are all weak.
.macro  ENTRY_DOUBLE fd, fl
#if __SIZEOF_DOUBLE__ == 8
	.global	\fd
	.type	\fd, "function"
#ifdef HAVE_LD_GNU_ATTRIBUTE_8
	.gnu_attribute Tag_GNU_AVR_BITS_DOUBLE,64
#endif
\fd:
#endif /* __SIZEOF_DOUBLE__ == 8 */

#if __SIZEOF_LONG_DOUBLE__ == 8
	.global	\fl
	.type	\fl, "function"
#ifdef HAVE_LD_GNU_ATTRIBUTE_12
	.gnu_attribute Tag_GNU_AVR_BITS_LONG_DOUBLE,64
#endif
\fl:
#endif /* __SIZEOF_LONG_DOUBLE__ == 8 */
.endm


#define NOINIT_SECTION .section .noinit, "a", @nobits

/* swap two registers without need of temporary register */
.macro _SWAP	dst, src
	eor dst, src
	eor src, dst
	eor dst, src
.endm

/* swap two words with the help of r0/r1 */
.macro _SWAPW	dst, src
	X_movw r0, \src
	X_movw \src, \dst
	X_movw \dst, r0
.endm


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Loading constants from program memory and RAMPZ

;;; We only have to init RAMPZ when we also have ELPM since we only
;;; use it for ELPM and not for LD Z / ST Z.
#if defined(RAMPZ) && defined(__AVR_HAVE_ELPM__)
#define LPMX_USES_RAMPZ
#endif

;;; On EBI devices, RAMPZ has to be restored to 0 after, since it is
;;; also used by LD Z / ST Z.  On devices without EBI, there is on need
;;; to restore RAMPZ since the next ELPM access will set it as needed.
#if defined(__AVR_HAVE_RAMPD__) && defined(LPMX_USES_RAMPZ)
#define MUST_RESTORE_RAMPZ
#endif

/*  This is a bit of a mess.  We have the following functions:
    __fp64_ldb8_const   // fp64_ldb_pi2.S
        Load an 8-bit big-endian constant to B.
        This is a row of LPMX Z+ insns that don't change SREG,
        where Z is post-incremented, and RAMPZ is NOT restored.

    __fp64_ldb_const   // fp64_ldb_pi2.S
        Load a 10-bit big-endian constant to B + rBE1/0.
        This function MUST BE JMP-ed to since it POPs Z at the end.
        As a consequence, Z (or two other regs) must be PUSHed prior
        to the invocation.  Restores RAMPZ as needed.

    __fp64_powser      // fp64_powserx.S
        Gets the table address in XH.XL.  Caller restores RAMPZ.

    Some CHECK_POWSER functions are also reading from flash and restore RAMPZ.
    In any case, RAMPZ is initialized by the caller as needed.

	For an overview over the RAMPx registers' relation to the ABI, see
	https://gcc.gnu.org/onlinedocs/gcc/AVR-Options.html#ramp
*/

.macro LPMX reg, zz
#if defined (__AVR_HAVE_ELPMX__)
    elpm \reg, \zz
#elif defined (__AVR_HAVE_ELPM__)
    .error ".require_lpmx"
#elif defined (__AVR_HAVE_LPMX__)
    lpm \reg, \zz
#else
    .error ".require_lpmx"
#endif
.endm

;;; Load the byte address of TAB to REG, and init RAMPZ as needed.
.macro LPMX_INIT reg, tab
    REGNO .regno, \reg
#ifdef LPMX_USES_RAMPZ
    ldi .regno, hh8 (\tab)
    out RAMPZ_IO_ADDR, .regno
#endif
    ldi .regno+0, lo8 (\tab)
    ldi .regno+1, hi8 (\tab)
.endm

.macro LPMX_FINI reg
#ifdef MUST_RESTORE_RAMPZ
    .ifb \reg
        ;; No reg provided: Cook one up.
        push    r31
        ldi     r31, 0
        out     RAMPZ_IO_ADDR, r31
        pop     r31
    .else
        ;; REG provided.
        REGNO .regno, \reg
        .if .regno >= 16
            ;; Upper reg: Zero without disturbing SREG.
            ldi .regno, 0
        .elseif .regno == 1
            ;; Assume zero_reg is intact.
        .else
            .error "LPMX_FINI regno??"
        .endif
        out RAMPZ_IO_ADDR, .regno
    .endif
#endif
.endm

;;; Please don't use Arduino internals.  All what needs be expressed
;;; can be expressed with AVR GCC / AVR-LibC macros.
#pragma GCC poison ARDUINO_AVR_MEGA2560


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Handling 3-byte PC and XICALL according to the AVR GCC ABI
;;; The ABI disallows to change EIND since it would break all
;;; kind of stuff like ISRs.  For an overview of the EIND ABI, see
;;; https://gcc.gnu.org/onlinedocs/gcc/AVR-Options.html#eind

#if defined (__AVR_2_BYTE_PC__)
#define PC_SIZE 2
#elif defined (__AVR_3_BYTE_PC__)
#define PC_SIZE 3
#else
#error PC_SIZE
#endif /* PC_SIZE */


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Deal with ISA quirks.

.macro .sbrs_callj reg, bit
#ifdef __AVR_ERRATA_SKIP_JMP_CALL__
    sbrc \reg, \bit
    rjmp .+4
#else
    sbrs \reg, \bit
#endif
.endm

.macro .sbrc_callj reg, bit
#ifdef __AVR_ERRATA_SKIP_JMP_CALL__
    sbrs \reg, \bit
    rjmp .+4
#else
    sbrc \reg, \bit
#endif
.endm

.macro .get_SP reg
    REGNO .regno, \reg
	in .regno + 0, SPL_IO_ADDR
#ifdef SPH
	in .regno + 1, SPH_IO_ADDR
#else
	clr .regno + 1
#endif
.endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Chicken out when the code demands more than the hardware can do.

#ifdef __AVR_TINY__
    .end
#endif

.macro .require_mul
#ifndef __AVR_HAVE_MUL__
    .end
#endif
.endm

.macro .require_lpmx
#if defined (__AVR_HAVE_ELPM__) && !defined (__AVR_HAVE_ELPMX__)
    .end
#elif !defined (__AVR_HAVE_ELPM__) && !defined (__AVR_HAVE_LPMX__)
    .end
#endif
.endm

#endif	/* !FP64ASM_H */
