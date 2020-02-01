/* Copyright (c) 2019-2020  Uwe Bissinger
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

#if !defined(__AVR_TINY__)

#include "fp64def.h"
#include "asmdef.h"

FUNCTION fp64_fmodx
	; do special case handling
	; case|	A	 |	fmodx_pi2(A)
	;-----+------+------
	; 1	  |	NaN	 |	NaN
	; 2	  |	Inf	 |	NaN
	; 3	  |	0	 |	 0
	; 4	  |	subn |	 A

	; cases 1-2: result is NaN 
0:	XJMP	_U(__fp64_nan)
	; case 3: result is 0
1:	XJMP(__fp64_szero);
	; case 4: A subnormal --> A < PI/2 --> result is A
2:	XJMP(__fp64_pretA);

/* float64_t fp64_fmodx_pi2 (float64_t x, unsigned long *np, const byte *y);
     The fp64_fmod() function computes the remainder of dividing x by PI/2 with 
	 extended precision. The return value is x - n*y, where n is the quotient 
	 of x/y, rounded towards zero to an integer.
 	 n is stored in *np, if np is != NULL
*/

ENTRY fp64_fmodx_pi2
	X_movw	XL, rB6			; move pointer to one of the pointer registers

	; Write 0 for next cases: Zero, Inf or NaN.
	adiw	XL, 0
	breq	91f				; skip, if pointer is == NULL
	st X+, r1				; n = 0
	st X+, r1
	st X+, r1
	st X, r1
	sbiw XL, 1

	; split and check exceptions
91:	XCALL	_U(__fp64_splitA)
	brcs	0b			; handle special cases NaN / Inf
	breq	1b			; handle fmod( 0, PI/2 ) --> 0
	tst rA6
	brpl	2b			; handle subnormal: fmod( A, PI/2 ) --> A
	;call __fp64_saveAB	

	; save all used registers
	push rAx0
	push rAx1
	push rAx2
	push rAx3
	
	push rBx0
	push rBx1
	push rBx2
	push rBx3
	push rBx4
	push rBx5
	push rBx6
	push rBx7
	push rBx8
	push rBx9
	push rBx10
	push rBx11
	
	push rB6			; save pointer
	push rB7

	rcall __fp64_fmodx_pi2_pse
	rol r0				; save carry
		
	;call __fp64_saveAB
	pop XH					; retrieve pointer
	pop XL
	adiw	XL, 0			; skip if pointer is == NULL
	breq	3f
	st X+, rC4				; save n
	st X+, rC5
	st X+, rC6
	st X+, rC7

3:	; restore everything
	pop rBx11
	pop rBx10
	pop rBx9
	pop rBx8
	pop rBx7
	pop rBx6
	pop rBx5
	pop rBx4
	pop rBx3
	pop rBx2
	pop rBx1
	pop rBx0
	

	pop rAx3
	pop rAx2
	pop rAx1
	pop rAx0
	
	ror r0					; restore carry
	XJMP _U(__fp64_rcpretA)	; round and pack result

ENTRY __fp64_fmodx_ln2_pse

	; load PI/2 with extended precision
	rcall __fp64_load_xln2
	
	; convert float64_t into extended precision
	; rcall __fp64_saveABC
	rcall __fp64_f64_to_f96
	;call __fp64_saveAB	

	rcall __fp64_fmodx		; rAx = fmod( rAx, PI/2 );

	; convert extended precision to float64_t
	; and return
	rjmp __fp64_f96_to_f64

	
ENTRY __fp64_fmodx_pi2_pse

	; load PI/2 with extended precision
	rcall __fp64_load_xpio2
	
	; convert float64_t into extended precision
	; rcall __fp64_saveABC
	rcall __fp64_f64_to_f96
	;call __fp64_saveAB	

	rcall __fp64_fmodx		; rAx = fmod( rAx, PI/2 );

	; convert extended precision to float64_t
	; and return

/* float64_t_intern __fp64_f96_to_f64 (float96_t x)
	 Convert a number from extended 96 bit representation into 
	  unpacked float64_t representation .
	 Input:  rAx11..rAx0, rAE1.rAE0 	number to convert
	 Output: rA6..rA0, rAE1.rAE0		converted number
			 C=1 if there were truncated digits (rAx4..rAx0 != 0)
*/
ENTRY __fp64_f96_to_f64
	; convert extended precision to float64_t
	cp  rAx0, r1			; set carry if any of the additional bits are set
	cpc rAx1, r1
	cpc rAx2, r1
	cpc rAx3, r1
	cpc rAx4, r1
	mov rA0, rAx5
	mov rA1, rAx6
	mov rA2, rAx7
	mov rA3, rAx8
	mov rA4, rAx9
	mov rA5, rAx10
	mov rA6, rAx11
	ret

/* float96_t __fp64_f64_to_f96 (float64_t x)
	 Convert a number from unpacked float64_t representation into 
	 extended 96 bit  representation.
	 Input:   rA6..rA0, rAE1.rAE0		number to convert
	 Output:  rAx11..rAx0, rAE1.rAE0 	converted number
*/
ENTRY __fp64_f64_to_f96
	; convert float64_t into extended precision
	; call __fp64_saveAB	
	mov rAx11, rA6
	mov rAx10, rA5
	mov rAx9, rA4
	mov rAx8, rA3
	mov rAx7, rA2
	mov rAx6, rA1
	mov rAx5, rA0
	clr rAx4
	clr rAx3
	clr rAx2
	movw rAx0, rAx2
	ret
	
.L_sz1:
	; fabs(x) = fabs(y) --> n = 1, fmod = 0
	mov rC4, r0		; set n to 1
	rjmp 92f		; and return 0

	; fmod(x,y) can not be determined --> n = 0, fmod = 0
	; return fmod(x,y) = 0
.L_sz:
	clr rC4			; set n to 0
92:	clr rC5
	clr rC6
	clr rC7
	
	; return rAx11.rAx0 == 0
.L_Azero:
	XCALL	_U(__fp64_szero)
	movw rAx0, rAx10
	movw rAx2, rAx10
	movw rAE0, rAx10
	ret
	
	; x was < y --> result already in A, return A and n = 0
.L_retA:
	clr rC4			; set n to 0
	clr rC5
	movw rC6, rC4
	ret
		
	
/* float64_t_intern fp64_fmodx(float96_t_intern x, float96_t_intern y);
     The fp64_fmodx() function computes the remainder of dividing x by y. The
     return value is x - n*y, where n is the quotient of x/y, rounded
     towards zero to an integer.
	 It does not handle any(!) special cases, the caller has to assure that both
	 x and y are finite and != 0 and not subnormal

	 Works with extended precision, uses all 32 registers!
	 x with extended precision is in rAx11..rAx0, rAE1.rAE0
	 y with extended precision is in rBx11..rBx0, rBE1.rBE0
	 result will be returned in rAx11..rAx0, rAE1.rAE0
	 rC7.rC6.rC5.rC4 are modified and contain the lower 4 bytes of n
 */
ENTRY	__fp64_fmodx

#define Cnt0	XL
#define Cnt1	XH
#define Cnt2	YL
#define Cnt3	YH

	clr r0
	inc r0		; r0 will contain 1 to aid +1 / -1 operations
	
	cp	rAx0, rBx0	; check whether A < B
	cpc	rAx1, rBx1
	cpc	rAx2, rBx2
	cpc	rAx3, rBx3
	cpc	rAx4, rBx4
	cpc	rAx5, rBx5
	cpc	rAx6, rBx6
	cpc	rAx7, rBx7
	cpc	rAx8, rBx8
	cpc	rAx9, rBx9
	cpc	rAx10, rBx10
	cpc	rAx11, rBx11
	cpc rAE0, rBE0
	cpc rAE1, rBE1
	; rcall __fp64_saveABC
	brlo .L_retA	; if fabs(A) < fabs(B), A is already the result 
	breq .L_sz1		; if fabs(A) = fabs(B) --> return sign(A^B)*0
  
	; from now on fabs(A) > fabs(B)
5:	;call __fp64_saveAB
	sub rAE0, rBE0	; exponent(A) - exponent(B)
	sbc rAE1, rBE1
	tst rAE1
	brne .L_sz		; A > 2^256*B --> fmod(A,B) can not exactly be determined , return 0
	cpi rAE0, 96
	brsh .L_sz		; A > 2^96*B --> fmod(A,B)  can not exactly be determined , return 0
	
	push Cnt0		; we ned these for the counter
	push Cnt1
	push Cnt2
	push Cnt3
	
	clr Cnt0
	clr Cnt1
	movw Cnt2, Cnt0
	
.Loop:
	; inc r0
	sub	rAx0, rBx0	; try to subtract B, A -= B
	sbc	rAx1, rBx1
	sbc	rAx2, rBx2
	sbc	rAx3, rBx3
	sbc	rAx4, rBx4
	sbc	rAx5, rBx5
	sbc	rAx6, rBx6
	sbc	rAx7, rBx7
	sbc	rAx8, rBx8
	sbc	rAx9, rBx9
	sbc	rAx10, rBx10
	sbc	rAx11, rBx11
	sbc Cnt3, r1
	
	; call __fp64_saveAB
	; rjmp .L_done
	brmi .L_undo		; result is < 0 --> A was < B
	breq 66f			; result is 0, we are done
	
	add Cnt0, r0		; success, A was > B --> counter++
	adc Cnt1, r1
	adc Cnt2, r1
	; adc Cnt3, r1

6:	sbiw rAE0,1		; exponent(A)--
	brmi 7f			; if exponent < 0, everything is calculated

	lsl Cnt0		; shift counter
	rol Cnt1
	rol Cnt2
	; rol Cnt3

	lsl	rAx0			; A <<= 1
	rol	rAx1
	rol	rAx2
	rol	rAx3
	rol rAx4
	rol rAx5
	rol rAx6
	rol rAx7
	rol rAx8
	rol rAx9
	rol rAx10
	rol rAx11
	rol Cnt3
	rjmp .Loop

.L_undo:
	add	rAx0, rBx0	; undo the sub, A += B
	adc	rAx1, rBx1
	adc	rAx2, rBx2
	adc	rAx3, rBx3
	adc	rAx4, rBx4
	adc	rAx5, rBx5
	adc	rAx6, rBx6
	adc	rAx7, rBx7
	adc	rAx8, rBx8
	adc	rAx9, rBx9
	adc	rAx10, rBx10
	adc	rAx11, rBx11
	adc Cnt3, r1
	rjmp 6b

.L_done:
	mov rC4, Cnt0	; move the counter to its return registers
	mov rC5, Cnt1
	mov rC6, Cnt2
	mov rC7, r1
	
	; call __fp64_saveABC
	
	pop Cnt3		; and restore previous contents of counter registers
	pop Cnt2
	pop Cnt1
	pop Cnt0

	; at this point A == 0
	; --> A = Cntr * 2^n * B
	; we have to adjust counter 
66:	
	sbiw rAE0, 1	
	brmi 67f
	lsl rC4			; shift counter
	rol rC5
	rol rC6
	rol rC7
	rjmp 66b
67: ret				; and return 0

7:	; at this point A = fmod(x,y), but needs normalizing
	mov rC4, Cnt0	; move the counter to its return registers
	mov rC5, Cnt1
	mov rC6, Cnt2
	mov rC7, Cnt3
	
	;call __fp64_saveABC
	
	pop Cnt3		; and restore previous contents of counter registers
	pop Cnt2
	pop Cnt1
	pop Cnt0

	sbiw rBE0,1		; exponent B--
	;call __fp64_saveABC
	brmi 10f		; exponent < 0 --> create subnormal number
	breq 9f			; exponent == 0 --> we are done
	
8:	tst rAx11		; is topmost bit of result set?
	brmi 9f			; yes, we can return
	lsl	rAx0		; A <<= 1
	rol	rAx1
	rol	rAx2
	rol	rAx3
	rol rAx4
	rol rAx5
	rol rAx6
	rol rAx7
	rol rAx8
	rol rAx9
	rol rAx10
	rol rAx11
	; rol rC7
	sbiw rBE0, 1
	brne 8b			; repeat until topmost bit or exponent = 0, i.e. subnormal number
	
9:	adiw rBE0, 1	; adjust exponent
	movw rAE0, rBE0
	ret
	
10: 
	; lsr rC7
	lsr	rAx11		; A >>= 1
	ror	rAx10
	ror	rAx9
	ror	rAx8
	ror	rAx7
	ror	rAx6
	ror	rAx5
	ror	rAx4
	ror	rAx3
	ror	rAx2
	ror	rAx1
	ror	rAx0
	adiw rBE0, 1	; exponent++
	brne 10b		; repeat until exponent = 0
	rjmp 9b

/* float96_t_intern __fp64_load_xln2();
	 load ln2 with extended precision
	 Output: rBx11..rB0, rBE1.rBE0	ln2 in internal 96 bit format
*/
ENTRY __fp64_load_xln2
	push ZL				; load b with ln2
	push ZH
	ldi ZL, lo8(__xln2)
	ldi ZH, hi8(__xln2)
	rjmp __fp64_load_xconst
	
/* float96_t_intern __fp64_load_xpio2();
	 load pi/2 with extended precision
	 Output: rBx11..rB0, rBE1.rBE0	PI/2 in internal 96 bit format
*/
ENTRY __fp64_load_xpio2
	push ZL				; load b with PI/2
	push ZH
	ldi ZL, lo8(__xpi_o_2)
	ldi ZH, hi8(__xpi_o_2)
	
/* float96_t_intern __fp64_load_xconst();
	 load extended precision constant out of flash space in rBX11..
	 Input:  ZH.ZL Pointer to constant in progmem
	 Output: rBx11..rB0, rBE1.rBE0	loaded constant in internal 96 bit format
*/
ENTRY __fp64_load_xconst	
	lpm rBx11, Z+
	lpm rBx10, Z+
	lpm rBx9, Z+
	lpm rBx8, Z+
	lpm rBx7, Z+
	lpm rBx6, Z+
	lpm rBx5, Z+
	lpm rBx4, Z+
	lpm rBx3, Z+
	lpm rBx2, Z+
	lpm rBx1, Z+
	lpm rBx0, Z+
	lpm rBE1, Z+
	lpm rBE0, Z+
	pop ZH
	pop ZL
	ret

	; PI/2 with 96 bits precision
	; digits of PI:3243F6A88 85A308D3 13198A2E 03707344 A4093822 299F31D0 082EFA98 EC4E6C89
	; MSB aligned: C90FDAA22 168C234C 4C6628B8 
__xpi_o_2:
	;     rBx11 rBx10 rBx9  rBx8  rBx7  rBx6  rBx5  rBx4  rBx3  rBx2  rBx1  rBx0  rBE1  rBE0
	.byte 0xC9, 0x0F, 0xDA, 0xA2, 0x21, 0x68, 0xC2, 0x34, 0xC4, 0xC6, 0x62, 0x8C, 0x03, 0xff

	; ln2 with 96 bits precision from http://www.numberworld.org/digits/Log(2)/
	; MSB aligned: b17217f7d1 cf79abc9e3 b39803f2f6 af40f34326 7298b62d8a
	; 0.6931471805599453094172321214581790787926
__xln2: 
	;     rBx11 rBx10 rBx9  rBx8  rBx7  rBx6  rBx5  rBx4  rBx3  rBx2  rBx1  rBx0  rBE1  rBE0
	.byte 0xb1, 0x72, 0x17, 0xf7, 0xd1, 0xcf, 0x79, 0xab, 0xc9, 0xe3, 0xb3, 0x98, 0x03, 0xfe
	
ENDFUNC

#endif /* !defined(__AVR_TINY__) */
