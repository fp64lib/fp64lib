/* Copyright (c) 2018-2020  Uwe Bissinger
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

/* Basic CORDIC algorithm:
double atanTable[53];
double gTable[53];

struct result_t {
  double x;
  double y;
  double g;
}

struct result_t Cordic( double phi ) {
  double k = 1.0;
  double x = 1.0;
  double y = 0.0;
  double x1, y1;
  double eps = Math.pow(2.0,-53.0);
  int n = -1;
  boolean sign;
  struct result_t res;
  
  do {
    sign = phi < 0;
    if( sign ) {
      x1 = -x;
      y1 = -y;
    }
    else {
      x1 = x;
      y1 = y;
    }
    x1 = x1 * k;	// this will be implemented by shift: x1 = x1 >> n
    y1 = y1 * k;	// this will be implemented by shift: y1 = y1 >> n
    x -= y1;
    y += x1;
	n++;
    if( sign )
      phi += atanTable[n];
    else 
      phi -= atanTable[n];
    k /= 2.0;
  } while (Math.abs(phi) > eps);
  res.x = x;
  res.y = y;
  res.g = gTable[n];
  return res;
}

// with that sin, cos and tan can be calculated for fabs(phi) < PI/2
res = Cordic(phi);
sin(phi) = res.y / res.g;
cos(phi) = res.x / res.g;
tan(phi) = res.y / res.x;

To obtain sufficient precision, all calculations are done with 64bit
x, y, x1, y1 	are all 64 bit, 2s complement
x, y are stored in memory
phi, x1, y1 are stored in registers, 8 registers per variable
n is stored in register
k is not needed in the implementation, as all *k are implemented as shifts

*/

#define rn		XL

/*
	fp64_cordic( phi )
	Input:
		rPHI7.rPHI6...rPHI0		- angle phi, fabs(phi)<PI/2 in significand_64 format
		XH						- function code:
									bit7 = 1: vector mode for inverse functions (atan, asin, acos)
									bit7 = 0: circular mode for normal functions (sin, cos, tan)
		rX7.rX6...rX0			- set for vector mode with x
	Output:
		rPHI7.rPHI6...rPHI0		- remainder angle phi, can be used for minimizing computional error
		rX7.rX6...rX0			- x = cos(phi) * gain in significand_64 format
		rY7.rY6...rX0			- y = sin(phi) * gain in significand_64 format
		ZH.ZL					- &gain in PROGMEN in significand_64 format
		
		significand_64 format is a 2s complement number format with 64 bits,
		representing numbers with fabs(x) < 2.0, x = (-1)^bit63 * bit62.bit61_to_bit0 * 2^0
		bit 63 = sign of x1
		bit 62...bit 0 = significand

WARNING: 	This routine uses all available registers except r1,YL and YH.
			For XH, bits 2 and 3 are used to record overflow on X or Y
			None of the used registers are preserved, so the caller has to take
			care of preserving all registers
*/		

FUNCTION __fp64_cordic
ENTRY __fp64_cordic

#ifdef DEBUG_CORDIC
		ldi ZL, lo8(__scratch)	; clear scrtach area for saving signs of decision
		ldi ZH, hi8(__scratch)
		ldi rn, 0x7f
		mov r0, rn
		ldi rn, -55
0:		st Z+, r0
		inc rn
		brne 0b
#endif 
		;ret
		sbrs XH, 7			; vector mode?
		rjmp .L_circular	; no, go forward with initialisation for circular mode
		
		; initialisation for vector mode: x is set by caller, ; y = is set by caller as atan(PHI); PHI = 0
		movw rY6, rPHI6		; y = PHI = atan(x)
		movw rY4, rPHI4
		movw rY2, rPHI2
		movw rY0, rPHI0

		clr rPHI7			; PHI = 0
		clr rPHI6
		movw rPHI4, rPHI6
		movw rPHI2, rPHI6
		movw rPHI0, rPHI6
		rjmp .L_commmon

.L_circular: ; initialisation for circular mode: x = 1.0; y = 0.0; PHI is set by caller
		clr rY7			; y = 0.0
		clr rY6
		movw rY4, rY6
		movw rY2, rY6
		movw rY0, rY6
		
		ldi rX7, 0x40	; x = 1.0
		clr rX6
		clr rX5
		clr rX4
		movw rX2, rX4
		movw rX0, rX4
.L_commmon:		
		ldi rn, 0xff	; n = -1
		
loop:	cbr XH, (0x04+0x08)	; clear overflow indicators
		ldi	ZL, lo8(___X)
		ldi ZH, hi8(___X)
		st Z+, rX0	; save X as we do not have enough register
		st Z+, rX1
		st Z+, rX2
		st Z+, rX3
		st Z+, rX4
		st Z+, rX5
		st Z+, rX6
		st Z+, rX7
		st Z+, rY0	; save Y as we do not have enough register
		st Z+, rY1
		st Z+, rY2
		st Z+, rY3
		st Z+, rY4
		st Z+, rY5
		st Z+, rY6
		st Z+, rY7

	; now x1 and y1 sit in the registers of X and Y
		; x1 = x1 * k;	// this will be implemented by shift: x1 = x1 >> n
		; y1 = y1 * k;	// this will be implemented by shift: y1 = y1 >> n
		push rn
		inc rn
#ifdef DEBUG_CORDIC
		; inc rn
		rcall 98f
		; subi rn, 1
#endif
11:		cpi rn, 16
		brlo 12f
		movw rX0, rX2
		movw rX2, rX4
		movw rX4, rX6
		clr rX7
		sbrc rX5,7
		com rX7
		mov rX6, rX7

		movw rY0, rY2
		movw rY2, rY4
		movw rY4, rY6
		clr rY7
		sbrc rY5,7
		com rY7
		mov rY6, rY7

		subi rn, 16
		rjmp 11b
		
12:		cpi rn, 8
		brlo 13f
		mov rX0, rX1
		mov rX1, rX2
		mov rX2, rX3
		mov rX3, rX4
		mov rX4, rX5
		mov rX5, rX6
		mov rX6, rX7
		clr rX7
		sbrc rX6,7
		com rX7

		mov rY0, rY1
		mov rY1, rY2
		mov rY2, rY3
		mov rY3, rY4
		mov rY4, rY5
		mov rY5, rY6
		mov rY6, rY7
		clr rY7
		sbrc rY6,7
		com rY7

		subi rn, 8
		
13:		subi rn, 1		; one shift at a time
		brcs 14f
		
		; lsr rX7			; x1 >>= 1
		asr rX7
		ror rX6
		ror rX5
		ror rX4
		ror rX3
		ror rX2
		ror rX1
		ror rX0
		
		; lsr rY7			; y1 >>= 1
		asr rY7
		ror rY6
		ror rY5
		ror rY4
		ror rY3
		ror rY2
		ror rY1
		ror rY0
		rjmp 13b
	
		; handle overflow and swap X and Y as the results are in the wrong registers
.L_swapXY:
		sbrs XH, 2		; was there an overflow on X ?
		sbrc XH, 3		; or on Y?
		rcall .L_asrXY	; yes, shift both to the rights
		clr r0          ; and adjust sign 
		sec
		ror r0			; substitude for ldi r0, 0x80
		sbrc XH, 2
		sub rX7, r0		; adjust sign for X
		sbrc XH, 3
		sub rY7, r0		; adjust sign for Y

		; now swap X and Y
		movw ZL, rX0
		movw rX0, rY0
		movw rY0, ZL
		
		movw ZL, rX2
		movw rX2, rY2
		movw rY2, ZL
		
		movw ZL, rX4
		movw rX4, rY4
		movw rY4, ZL
		
		movw ZL, rX6
		movw rX6, rY6
		movw rY6, ZL
		ret
		
14:		pop rn			; restore n

		ldi	ZL, lo8(___X)
		ldi ZH, hi8(___X)
		sbrc XH, 7
		rjmp 40f		; vector mode has different working order
		
		; ------ circular mode
30:		bst rPHI7,7		; circular mode --> sign = sign(phi)
		brts 31f		; if( !sign ) {
		rcall .L_XsY1	;	x = x - y1
		rcall .L_YaX1	;	y = y + x1
		rjmp 32f		; } else {
31:		rcall .L_XaY1	; 	x = x + y1
		rcall .L_YsX1	; 	y = y - x1 
32:		rcall .L_swapXY	; swap X an Y as the results are in the wrong registers
		
		inc rn			
		rcall .L_PHIasZ	; PHI = sign ? PHI+atan[n] : PHI -atan[n]
; #ifdef DEBUG_CORDIC
		; rcall 98f
; #endif
		cpi rn, 54		; until(( n >= 54 )
		breq .L_ret 		
		sbrc rPHI7,7
		rjmp .L_PHIeq00
.L_PHIeqFF:
		clr r0
		com r0			; r0 = 0xff
		cp rPHI7, r0
		cpc rPHI6, r0
		cpc rPHI5, r0
		cpc rPHI4, r0
		cpc rPHI3, r0
		cpc rPHI2, r0
		cpc rPHI1, r0
		brcc .L_ret
		rjmp loop
.L_PHIeq00:
		cp r1, rPHI7
		cpc r1, rPHI6
		cpc r1, rPHI5
		cpc r1, rPHI4
		cpc r1, rPHI3
		cpc r1, rPHI2
		cpc r1, rPHI1
		breq .L_ret
		rjmp loop

		; everything already in the registers
		; rX7...rX0 contain x = cos(x) * gTable[n]
		; rY7...rY0 contain y = sin(x) * gTable[n]
		; ZL.ZH points to atanTable[n+1]
.L_ret:
#ifndef FULL_GTABLE
		cpi rn, 32
		brlo 88f
		ldi ZL, lo8(gTable32)	; after n = 32, all entries are the same
		ldi ZH, hi8(gTable32)	; so load last entry
		rjmp 89f
88:
#endif
		ldi ZL, lo8(gTable)
		ldi ZH, hi8(gTable)
		clr r0
		lsl rn			; create &atanTable[n], 1 entry = 8 bytes
		lsl rn
		lsl rn			; only this last operation can overflow as n <= 53
		rol r0
		add ZL, rn
		adc ZH, r0
89:		; call __fp64_saveCordic
		ret
		
40:		; ----- vector mode
		set				; sign = sign(-Y)
		sbrc rY7, 7		
		clt

		brts 41f		; if( !sign ) {
		rcall .L_XsY1	;	x = x - y1;
		rcall .L_YaX1	;	y = y + x1
		rjmp 42f			; } else {
41:		rcall .L_XaY1	; 	x = x + y1
		rcall .L_YsX1	; 	y = y - x1 
						; }
42:		rcall .L_swapXY	; swap X an Y as the results are in the wrong registers
		inc rn			
		rcall .L_PHIasZ	; PHI = sign ? PHI+atan[n] : PHI -atan[n]
; #ifdef DEBUG_CORDIC
		; rcall 98f
; #endif
		cpi rn, 54		; until(( n >= 54 )
;		cpi rn, 10		; until(( n >= 54 )
		breq .L_ret 		

		sbrs rY7,7
		rjmp .L_Yeq00	;			|| (abs(y) < eps) );
.L_YeqFF:
		clr r0
		com r0			; r0 = 0xff
		cp rY7, r0
		cpc rY6, r0
		cpc rY5, r0
		cpc rY4, r0
		cpc rY3, r0
		cpc rY2, r0
		cpc rY1, r0
		brcc .L_ret
		rjmp loop
.L_Yeq00:
		cp r1, rY7
		cpc r1, rY6
		cpc r1, rY5
		cpc r1, rY4
		cpc r1, rY3
		cpc r1, rY2
		cpc r1, rY1
		breq .L_ret
		rjmp loop

.L_PHIasZ:				; PHI = sign ? PHI+atan[n] : PHI -atan[n]		
		ldi ZL, lo8(atanTable)
		ldi ZH, hi8(atanTable)
		push rn
		clr r0
		lsl rn			; create &atanTable[n], 1 entry = 8 bytes
		lsl rn
		lsl rn			; only this last operation can overflow as n <= 53
		rol r0
		add ZL, rn
		adc ZH, r0
		pop rn	
		
		; ZH.ZL now points to atanTable[n]
		brtc 50f			; if( sign )
		lpm r0, Z+		; 	phi += atanTable[n];
		add rPHI0, r0
		lpm r0, Z+
		adc rPHI1,r0
		lpm r0, Z+
		adc rPHI2,r0
		lpm r0, Z+
		adc rPHI3,r0
		lpm r0, Z+
		adc rPHI4,r0
		lpm r0, Z+
		adc rPHI5,r0
		lpm r0, Z+
		adc rPHI6,r0
		lpm r0, Z+
		adc rPHI7,r0
		ret
50:		
		lpm r0, Z+	; 	phi -= atanTable[n];
		sub rPHI0, r0
		lpm r0, Z+
		sbc rPHI1,r0
		lpm r0, Z+
		sbc rPHI2,r0
		lpm r0, Z+
		sbc rPHI3,r0
		lpm r0, Z+
		sbc rPHI4,r0
		lpm r0, Z+
		sbc rPHI5,r0
		lpm r0, Z+
		sbc rPHI6,r0
		lpm r0, Z+
		sbc rPHI7,r0
		ret
		
.L_XsY1:
		ld r0, Z+		; 	x = x - y1 
		sub r0, rY0
		mov rY0, r0
		ld r0, Z+
		sbc r0, rY1
		mov rY1, r0
		ld r0, Z+
		sbc r0, rY2
		mov rY2, r0
		ld r0, Z+
		sbc r0, rY3
		mov rY3, r0
		ld r0, Z+
		sbc r0, rY4
		mov rY4, r0
		ld r0, Z+
		sbc r0, rY5
		mov rY5, r0
		ld r0, Z+
		sbc r0, rY6
		mov rY6, r0
		ld r0, Z+
		sbc r0, rY7
		mov rY7, r0
		brvc 61f		; signed overflow ?
		sbr XH, 0x08	; yes, signal overflow for Y
61:		ret				; no, return

.L_YaX1:
		ld r0, Z+		; 	y = x1 + y
		add rX0, r0
		ld r0, Z+
		adc rX1, r0
		ld r0, Z+
		adc rX2, r0
		ld r0, Z+
		adc rX3, r0
		ld r0, Z+
		adc rX4, r0
		ld r0, Z+
		adc rX5, r0
		ld r0, Z+
		adc rX6, r0
		ld r0, Z+
		adc rX7, r0
		brvc 62f		; signed overflow ?
		sbr XH,0x04		; yes --> set overflow indicator for X
62:		ret				; no, return
		
.L_XaY1:
		ld r0, Z+		; 	x = x + y1
		add rY0, r0
		ld r0, Z+
		adc rY1, r0
		ld r0, Z+
		adc rY2, r0
		ld r0, Z+
		adc rY3, r0
		ld r0, Z+
		adc rY4, r0
		ld r0, Z+
		adc rY5, r0
		ld r0, Z+
		adc rY6, r0
		ld r0, Z+
		adc rY7, r0
		brvc 63f		; signed overflow ?
		sbr XH, 0x08	; yes, signal overflow for Y
63:		ret				; no, return

.L_YsX1:
		ld r0, Z+		; 	y = y - y1 
		sub r0, rX0
		mov rX0, r0
		ld r0, Z+
		sbc r0, rX1
		mov rX1, r0
		ld r0, Z+
		sbc r0, rX2
		mov rX2, r0
		ld r0, Z+
		sbc r0, rX3
		mov rX3, r0
		ld r0, Z+
		sbc r0, rX4
		mov rX4, r0
		ld r0, Z+
		sbc r0, rX5
		mov rX5, r0
		ld r0, Z+
		sbc r0, rX6
		mov rX6, r0
		ld r0, Z+
		sbc r0, rX7
		mov rX7, r0
		brvc 63f		; signed overflow ?
		sbr XH,0x04		; yes --> set overflow indicator for X
63:		ret				; no, return
		
.L_asrXY:
		asr rX7			; x1 >>= 1
		ror rX6
		ror rX5
		ror rX4
		ror rX3
		ror rX2
		ror rX1
		ror rX0
		
		asr rY7			; y1 >>= 1
		ror rY6
		ror rY5
		ror rY4
		ror rY3
		ror rY2
		ror rY1
		ror rY0
		ret

		#ifdef DEBUG_CORDIC
98:		ldi ZL, lo8(__scratch)		; save +n or -n in __scratch[n] for debugging
		ldi ZH, hi8(__scratch)
		add ZL, rn
		adc ZH, r1
		bld rn, 7					; get sign
		st Z, rn
		cbr rn, 0x80

#if DEBUG_CORDIC > 1
		cpi rn, 20
		brsh 988f
		ldi ZL, lo8(__scratchXYZ)		; save Y in __scratchY[n] for debugging
		ldi ZH, hi8(__scratchXYZ)
		push rn
		lsl rn
		lsl rn
		lsl rn						; as n < 54, only this rol might create a carry
		adc r1, r1
		add ZL, rn					; create &__scratch[n]
		adc ZH, r1
		lsl rn
		rol r1
		add ZL, rn					; create &__scratch[n+2*n]
		adc ZH, r1
		clr r1
		st Z+,rX7
		st Z+,rX6
		st Z+,rX5
		st Z+,rX4
		st Z+,rX3
		st Z+,rX2
		st Z+,rX1
		st Z+,rX0
		st Z+,rY7
		st Z+,rY6
		st Z+,rY5
		st Z+,rY4
		st Z+,rY3
		st Z+,rY2
		st Z+,rY1
		st Z+,rY0
		st Z+,rPHI7
		st Z+,rPHI6
		st Z+,rPHI5
		st Z+,rPHI4
		st Z+,rPHI3
		st Z+,rPHI2
		st Z+,rPHI1
		st Z+,rPHI0
		pop rn
#endif
988:	ret	
#endif 
	
	
/* 
	table of precalculated atan values
    the values of that table were created with the following algorithm

   double k = 1.0;
   for( int i = 0; i < 53; i++ ) {
     atanTable[i] = Math.atan(k);
     k = k * 0.5;  
  }
  
  All calculations were done using __float128 datatype (gcc quad precision
  mathematics), and then the values were converted to significand_64 interim format

  atanTable has to be in PROGMEN as algorithm loads it with lpm, so
  there must be no .data directive before  
 */
atanTable:
	;	  PHI0, PHI1, PHI2, PHI3, PHI4, PHI5, PHI6, PHI7 
	.byte 0x8D, 0x30, 0x5A, 0x88, 0xA8, 0xF6, 0x43, 0x32 ; atan(2^-0)  0.7853981633974483096156608458198756993698 
	.byte 0x68, 0x4F, 0xBB, 0x61, 0x05, 0x67, 0xAC, 0x1D ; atan(2^-1)  0.4636476090008061162142562314612143971334
	.byte 0xB1, 0x6E, 0x40, 0x96, 0xFC, 0xBA, 0xAD, 0x0F ; atan(2^-2)  0.2449786631268641541720824812112758064196
	.byte 0x71, 0xDB, 0x0B, 0xAB, 0xA6, 0x6E, 0xF5, 0x07 ; atan(2^-3)  0.1243549945467614350313548491638710241657
	.byte 0x38, 0xBD, 0x9F, 0xE5, 0x76, 0xAB, 0xFE, 0x03 ; atan(2^-4)  0.0624188099959573484739791129855051129801
	.byte 0x4A, 0x62, 0x97, 0xBA, 0x5B, 0xD5, 0xFF, 0x01 ; atan(2^-5)  0.0312398334302682762537117448924909777360
	.byte 0xD5, 0x94, 0xDB, 0xDD, 0xAA, 0xFA, 0xFF, 0x00 ; atan(2^-6)  0.0156237286204768308028015212565703192840
	.byte 0x5C, 0xEA, 0xEE, 0x56, 0x55, 0xFF, 0x7F, 0x00 ; atan(2^-7)  0.0078123410601011112964633918421992813433
	.byte 0x6E, 0x77, 0xB7, 0xAA, 0xEA, 0xFF, 0x3F, 0x00 ; atan(2^-8)  0.0039062301319669718276286653114243871460
	.byte 0xBB, 0xBB, 0x55, 0x55, 0xFD, 0xFF, 0x1F, 0x00 ; atan(2^-9)  0.0019531225164788186851214826250767138467
	.byte 0xDD, 0xAD, 0xAA, 0xAA, 0xFF, 0xFF, 0x0F, 0x00 ; atan(2^-10) 0.0009765621895593194304034301997172908212
	.byte 0x6E, 0x55, 0x55, 0xF5, 0xFF, 0xFF, 0x07, 0x00 ; atan(2^-11) 0.0004882812111948982754692396256448486823
	.byte 0xAB, 0xAA, 0xAA, 0xFE, 0xFF, 0xFF, 0x03, 0x00 ; atan(2^-12) 0.0002441406201493617640167229432596599929
	.byte 0x55, 0x55, 0xD5, 0xFF, 0xFF, 0xFF, 0x01, 0x00 ; atan(2^-13) 0.0001220703118936702042390586461179563003
	.byte 0xAB, 0xAA, 0xFA, 0xFF, 0xFF, 0xFF, 0x00, 0x00 ; atan(2^-14) 0.0000610351561742087750216625691738291515
	.byte 0x55, 0x55, 0xFF, 0xFF, 0xFF, 0x7F, 0x00, 0x00 ; atan(2^-15) 0.0000305175781155260968618259534385360193
	.byte 0xAB, 0xEA, 0xFF, 0xFF, 0xFF, 0x3F, 0x00, 0x00 ; atan(2^-16) 0.0000152587890613157621072319358126978849
	.byte 0x55, 0xFD, 0xFF, 0xFF, 0xFF, 0x1F, 0x00, 0x00 ; atan(2^-17) 0.0000076293945311019702633884823401050905
	.byte 0xAB, 0xFF, 0xFF, 0xFF, 0xFF, 0x0F, 0x00, 0x00 ; atan(2^-18) 0.0000038146972656064962829230756163729937
	.byte 0xF5, 0xFF, 0xFF, 0xFF, 0xFF, 0x07, 0x00, 0x00 ; atan(2^-19) 0.0000019073486328101870353653693059172442
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x03, 0x00, 0x00 ; atan(2^-20) 0.0000009536743164059608794206706899231124
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00 ; atan(2^-21) 0.0000004768371582030888599275838214492471
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00 ; atan(2^-22) 0.0000002384185791015579824909479772189327
	.byte 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00 ; atan(2^-23) 0.0000001192092895507806853113684971379221
	.byte 0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00 ; atan(2^-24) 0.0000000596046447753905544139210621417889
	.byte 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00 ; atan(2^-25) 0.0000000298023223876953036767401327677095
	.byte 0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00 ; atan(2^-26) 0.0000000149011611938476551470925165959632
	.byte 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00 ; atan(2^-27) 0.0000000074505805969238279871365645744954
	.byte 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00 ; atan(2^-28) 0.0000000037252902984619140452670705718119
	.byte 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00 ; atan(2^-29) 0.0000000018626451492309570290958838214765
	.byte 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00 ; atan(2^-30) 0.0000000009313225746154785153557354776846
	.byte 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00 ; atan(2^-31) 0.0000000004656612873077392577788419347106
	.byte 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x00 ; atan(2^-32) 0.0000000002328306436538696289020427418388
	.byte 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00 ; atan(2^-33) 0.0000000001164153218269348144525990927299
	.byte 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00 ; atan(2^-34) 0.0000000000582076609134674072264967615912
	.byte 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x00 ; atan(2^-35) 0.0000000000291038304567337036132730326989
	.byte 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00 ; atan(2^-36) 0.0000000000145519152283668518066395978374
	.byte 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00 ; atan(2^-37) 0.0000000000072759576141834259033201841047
	.byte 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00 ; atan(2^-38) 0.0000000000036379788070917129516601402006
	.byte 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00 ; atan(2^-39) 0.0000000000018189894035458564758300761188
	.byte 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00 ; atan(2^-40) 0.0000000000009094947017729282379150388117
	.byte 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00 ; atan(2^-41) 0.0000000000004547473508864641189575194999
	.byte 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00 ; atan(2^-42) 0.0000000000002273736754432320594787597617
	.byte 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00 ; atan(2^-43) 0.0000000000001136868377216160297393798823
	.byte 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00 ; atan(2^-44) 0.0000000000000568434188608080148696899413
	.byte 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00 ; atan(2^-45) 0.0000000000000284217094304040074348449707
	.byte 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00 ; atan(2^-46) 0.0000000000000142108547152020037174224854
	.byte 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; atan(2^-47) 0.0000000000000071054273576010018587112427
	.byte 0x00, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; atan(2^-48) 0.0000000000000035527136788005009293556213
	.byte 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; atan(2^-49) 0.0000000000000017763568394002504646778107
	.byte 0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; atan(2^-50) 0.0000000000000008881784197001252323389053
	.byte 0x00, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; atan(2^-51) 0.0000000000000004440892098500626161694527
	.byte 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; atan(2^-52) 0.0000000000000002220446049250313080847263
	.byte 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; atan(2^-53) 0.0000000000000001110223024625156540423632
	.byte 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; atan(2^-54) 0.0000000000000000555111512312578270211816

	; table of precalculated g (gain) values
/* the values of that table were created with the following algorithm
   double k = 1.0;
   for( int i = 0; i < 53; i++ ) {
   if( i == 0 )
     gTable[i] = Math.sqrt(2.0);
   else
     gTable[i] = gTable[i-1]*sqrt(1.0+k*k);
   k = k * 0.5;  
   }

  All calculations were done using __float128 datatype (gcc quad precision
  mathematics), and then the values were converted to significand_64 interim format
  todo: table can be reduced, as only 7 bytes are used

   */
gTable:	
	.byte 0xb5, 0x04, 0xf3, 0x33, 0xf9, 0xde, 0x64, 0x84 ; g[0]  1.4142135623730950487637880730318329369766	
	.byte 0xca, 0x62, 0xc1, 0xd6, 0xd2, 0xda, 0x94, 0x90 ; g[1]  1.5811388300841896659837404470749788742978	
	.byte 0xd0, 0x9d, 0x4e, 0x5c, 0xcb, 0x32, 0x84, 0x0d ; g[2]  1.6298006013006621786826447206841805837030	
	.byte 0xd2, 0x3c, 0xea, 0xf9, 0x4d, 0xb1, 0x4b, 0xa1 ; g[3]  1.6424840657522373662787276704655425874080	
	.byte 0xd2, 0xa5, 0xef, 0x34, 0x48, 0x97, 0x04, 0x56 ; g[4]  1.6456889157572548536539319696814231974713	
	.byte 0xd2, 0xc0, 0x42, 0x4d, 0x17, 0xe2, 0xf1, 0x67 ; g[5]  1.6464922787124787573838011200955122603773	
	.byte 0xd2, 0xc6, 0xd8, 0x34, 0xd3, 0x16, 0x1e, 0xe3 ; g[6]  1.6466932542736438495811421289793941014068	
	.byte 0xd2, 0xc8, 0x7d, 0xc0, 0xdd, 0xf5, 0x5f, 0xb9 ; g[7]  1.6467435065969011554658577023424470553437	
	.byte 0xd2, 0xc8, 0xe7, 0x25, 0x02, 0x7c, 0xcc, 0x28 ; g[8]  1.6467560702048785791287710544850142468931	
	.byte 0xd2, 0xc9, 0x01, 0x7e, 0x1d, 0xbb, 0xda, 0xde ; g[9]  1.6467592111398222339598701458029950117634	
	.byte 0xd2, 0xc9, 0x08, 0x14, 0x65, 0xad, 0x72, 0xac ; g[10] 1.6467599963756175038796791820772114078864	
	.byte 0xd2, 0xc9, 0x09, 0xb9, 0xf7, 0xbb, 0xf5, 0xe6 ; g[11] 1.6467601926846950316073864284405203761708	
	.byte 0xd2, 0xc9, 0x0a, 0x23, 0x5c, 0x40, 0xb8, 0x88 ; g[12] 1.6467602417619724578315421048557709582383	
	.byte 0xd2, 0xc9, 0x0a, 0x3d, 0xb5, 0x61, 0xfb, 0x4e ; g[13] 1.6467602540312923171863385141122648747114	
	.byte 0xd2, 0xc9, 0x0a, 0x44, 0x4b, 0xaa, 0x4d, 0x22 ; g[14] 1.6467602570986223135211107271302921617462	
	.byte 0xd2, 0xc9, 0x0a, 0x45, 0xf1, 0x3c, 0x61, 0xa9 ; g[15] 1.6467602578654548145563676908587069647183	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x5a, 0xa0, 0xe6, 0xcb ; g[16] 1.6467602580571629398422869861029482763115	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x74, 0xfa, 0x08, 0x14 ; g[17] 1.6467602581050899712179769185382838259102	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7b, 0x90, 0x50, 0x66 ; g[18] 1.6467602581170717290347943473349801024597	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0x35, 0xe2, 0x7b ; g[19] 1.6467602581200671685432088131584293932974	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0x9f, 0x47, 0x00 ; g[20] 1.6467602581208160283932073753021541051567	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xb9, 0xa0, 0x21 ; g[21] 1.6467602581210032433286019615259476722713	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc0, 0x36, 0x6a ; g[22] 1.6467602581210500471437657710183088966005	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc1, 0xdb, 0xfc ; g[23] 1.6467602581210617480704516690792615918326	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x45, 0x60 ; g[24] 1.6467602581210646732479130349702245439403	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x5f, 0xba ; g[25] 1.6467602581210654046506985936915157253679	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x66, 0x50 ; g[26] 1.6467602581210655874471848747475632990245	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x67, 0xf5 ; g[27] 1.6467602581210656330920963363872999707382	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x5f ; g[28] 1.6467602581210656445846393647336469712172	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x79 ; g[29] 1.6467602581210656474035650131959584996366	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x80 ; g[30] 1.6467602581210656481625065339358116034418	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x81 ; g[31] 1.6467602581210656482709267511843620468426	
gTable32:
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[32] 1.6467602581210656483793469684329124902433	
#if defined(FULL_GTABLE)
	; table is normally  shortened, as after g[32} all entries are identical
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[33] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[34] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[35] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[36] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[37] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[38] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[39] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[40] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[41] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[42] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[43] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[44] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[45] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[46] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[47] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[48] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[49] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[50] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[51] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[52] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[53] 1.6467602581210656483793469684329124902433	
	.byte 0xd2, 0xc9, 0x0a, 0x46, 0x7d, 0xc2, 0x68, 0x82 ; g[54] 1.6467602581210656483793469684329124902433	
#endif

ENDFUNC
		
; scratch area to save X and Y
.data
___X:	.skip 8
		.skip 8

#ifdef DEBUG_CORDIC		
ENTRY __scratch
	.skip 55

#if DEBUG_CORDIC > 1
ENTRY __scratchXYZ
	.skip 20*8*3
#endif
#endif


