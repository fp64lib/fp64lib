/* Copyright (c) 2019  Uwe Bissinger
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

/* Interprocedure convensions. In separate file: for math library
   developers.	*/
#if (!defined(__AVR_ATmega328P__) || defined(__AVR_TINY__) || !defined(__AVR_ENHANCED__)) && !defined(ARDUINO_AVR_MEGA2560)
#error fp64lib is created and tested only for Atmel AVR 328p microprocessors like Arduino UNO or Nano
#endif
   
#ifndef	_FP64DEF_H
#define	_FP64DEF_H

//#include "sectionname.h"

/*
Registers 
	A packed:	rA7, rA6, rA5, rA4, rA3, rA2, rA1, rA0			8 registers
				r18, r19, r20, r21, r22, r23, r24, r25
	A unpacked:	rAE1, rAE0, rA6, rA5, rA4, rA3, rA2, rA1, rA0	9 registers
				r30.  r31,	r19, r20, r21, r22, r23, r24, r25
	B packed:	rB7, rB6, rB5, rB4, RB3, RB2, RB1, rB0			8 registers
				r10, r11, r12, r13, r14, r15, r16, r17			
	B unpacked:	rBE1, rBE0, rB6, rB5, rB4, RB3, RB2, RB1, rB0	9 registers
				r26,  r27,  r11, r12, r13, r14, r15, r16, r17

*/

// #define DEBUG_CORDIC	1
// #define CHECK_POWSER

#define MAX_SIGNIFICAND		17
#define	MAX_EXPONENT		3

// general pointer registers
#define XL  r26
#define XH  r27
#define YL  r28
#define YH  r29
#define ZL  r30
#define ZH  r31

// general register usage for float64_t parameters A and B
#define	rA7	r25
#define	rA6	r24
#define	rA5	r23
#define	rA4	r22
#define	rA3	r21
#define	rA2	r20
#define	rA1	r19
#define	rA0	r18
#define rAE0 ZL
#define rAE1 ZH

#define	rB7	r17
#define	rB6	r16
#define	rB5	r15
#define	rB4	r14
#define	rB3	r13
#define	rB2	r12
#define	rB1	r11
#define	rB0	r10
#define rBE0 XL
#define rBE1 XH

#define	rC7	r9
#define	rC6	r8
#define	rC5	r7
#define	rC4	r6
#define	rC3	r5
#define	rC2	r4
#define	rC1	r3
#define	rC0	r2

// Warning: if rDx is used then rAEx, rBEx, rExp2x, rExp10x, Xx/Yx/Zx can not be used
//			and especially r1 is no longer == 0!!!!
#define rD7 ZH
#define rD6 ZL
#define rD5 YH
#define rD4 YL
#define rD3 XH
#define rD2 XL
#define rD1 r1
#define rD0 r0

// aliases for conversion algorithms to/from decimal
#define rExp2L	ZL
#define rExp2H	ZH
#define rExp10L	XL
#define rExp10H	XH

// scratch registers used in multiplication
#define rZero r5
#define rR8 r6
#define rR7 r7
#define rR6 r8
#define rR5 r9

// The following register definitions are used for the
// cordic algorithm and the trigonometric functions
#define rPHI7	r25
#define rPHI6	r24
#define rPHI5	r23
#define rPHI4	r22
#define rPHI3	r21
#define rPHI2	r20
#define rPHI1	r19
#define rPHI0	r18

#define rX7		r17
#define rX6		r16
#define rX5		r15
#define rX4		r14
#define rX3		r13
#define rX2		r12
#define rX1		r11
#define rX0		r10

#define rY7		r9
#define rY6		r8
#define rY5		r7
#define rY4		r6
#define rY3		r5
#define rY2		r4
#define rY1		r3
#define rY0		r2


/* Put functions at this section.	*/
#ifdef	FUNCTION
# error	"The FUNCTION macro must be defined after FUNC_SEGNAME"
#endif
// #define FUNC_SEGNAME	MLIB_SECTION
#define FUNC_SEGNAME	.text.fp64lib

/* Put constant tables at low addresses in program memory, so they are
   reachable for "lpm" without using RAMPZ on >64K devices.  */
//#define PGM_SECTION	.section  .progmem.gcc_fplib, "a", @progbits

#endif	/* !_FP64DEF_H */
