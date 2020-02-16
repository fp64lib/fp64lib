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

// Include file is only needed when debugging fp64lib

#ifndef fp64lib_h_included
#include "fp64lib.h"
#endif
#ifndef fp64debug_h_included
#define fp64debug_h_included

#ifdef __cplusplus
extern "C"{
#endif 

// debugging structure
typedef struct fp64_debug_t {
  uint8_t sreg;		// SREG of AVR
  uint8_t count;	// # of times one of the debug routines was called
  uint8_t sign;		// sign of mantissa
  uint16_t exp;		// exponent, 1023 based
  uint8_t m[7];		// mantissa
  uint8_t r7;		// content of rA7 or rB7
  uint8_t r0;		// content of r0 or r1
} fp64_debug_t;
#define fp64_debug_isC(ptr)	(ptr->sreg & 0x01)
#define fp64_debug_isZ(ptr)	(ptr->sreg & 0x02)
#define fp64_debug_isT(ptr)	(ptr->sreg & 0x40)

// debugging functions
struct fp64_debug_t* __fp64_debugA(void);
struct fp64_debug_t* __fp64_debugAB(void);
void      __fp64_splitA( float64_t a );
void      __fp64_split3( float64_t a, float64_t b );
float64_t __fp64_proxy1( float64_t (*f1ptr)(float64_t), float64_t *a );
int8_t    __fp64_proxy1_int8( int8_t (*f1ptr)(float64_t), float64_t *a );
int16_t   __fp64_proxy1_int16( int16_t (*f1ptr)(float64_t), float64_t *a );
int32_t   __fp64_proxy1_int32( int32_t (*f1ptr)(float64_t), float64_t *a );
int64_t   __fp64_proxy1_int64( int64_t (*f1ptr)(float64_t), float64_t *a );
float64_t __fp64_proxy2( float64_t (*f2ptr)(float64_t, float64_t), float64_t *a, float64_t *b );
float64_t __fp64_proxy2_int8( int8_t (*f2ptr)(float64_t, float64_t), float64_t *a, float64_t *b );

// internal functions to return special values
float64_t __fp64_one( void ) __ATTR_CONST__;
float64_t __fp64_zero( void ) __ATTR_CONST__;
float64_t __fp64_szero( void ) __ATTR_CONST__;
float64_t __fp64_inf( void ) __ATTR_CONST__;
float64_t __fp64_nan( void ) __ATTR_CONST__;
float64_t __fp64_negsd2 (float64_t A) __ATTR_CONST__;
int __fp64_unordsd2( float64_t x) __ATTR_CONST__;
uint64_t __fp64_domul64AB( uint64_t a, uint64_t b ) __ATTR_CONST__;
uint64_t fp64_10pown( int16_t n, int16_t *exp2 ) __ATTR_CONST__;
float64_t __fp64_check_powser1( float64_t x );
float64_t __fp64_check_powser2( float64_t x );
float64_t __fp64_check_powser3( float64_t x );
float64_t __fp64_check_powsodd3( float64_t x );
float64_t __fp64_check_powslog( float64_t x );
float64_t __fp64_check_powserexp( float64_t x );

// internal functions that might be used for integration with gcc
// 32-bit float used the following naming convention
// 	si		for short integer, int16_t
// 	unssi	for unsigned short integer, uint16_t
// 	di		for double integer, int64_t, long long
// 	unsdi	for unsigned double integer, uint32_t, unsigned long
// 	sf		for signed float, 32-bit IEEE float (identical to double)
// for fp64lib, this naming convention was extended by
//	sd		for signed double, 64-bit IEEE float
//  li		for long integer, int32_t, long
//  sc		for short character, int8_t, char
float64_t fp64_modff (float64_t x, float64_t *iptr) __ATTR_CONST__;
float64_t fp64_sqrtf( float64_t x ) __ATTR_CONST__;
float64_t __fp64disd (long long x) __ATTR_CONST__;				// (signed) long long to float64_t
float64_t __fp64unsdisd (unsigned long long x) __ATTR_CONST__; 	// unsigned long long to float64_t
float64_t __fp64sisd ( long x ) __ATTR_CONST__;					// (signed) long to float64
float64_t __fp64unssisd (unsigned long x) __ATTR_CONST__;		// unsigned long to float64_t
float64_t __fp64sssd ( uint16_t x ) __ATTR_CONST__;				// (signed) short to float64
float64_t __fp64unsssd (uint16_t x) __ATTR_CONST__;		        // unsigned short to float64_t
long long __fp64_fixsddi( float64_t A ) __ATTR_CONST__;			// float64_t to (signed) long long
unsigned long long __fp64_fixunssddi( float64_t A ) __ATTR_CONST__;// float64_t to unsigned long long
long __fp64_fixsdli( float64_t A ) __ATTR_CONST__;				// float64_t to (signed) long
unsigned long __fp64_fixunssdli( float64_t A ) __ATTR_CONST__;	// float64_t to unsigned long
int __fp64_fixsdsi( float64_t A ) __ATTR_CONST__;				// float64_t to (signed) int
unsigned int __fp64_fixunssdsi( float64_t A ) __ATTR_CONST__;	// float64_t to unsigned int
char __fp64_fixsdsc( float64_t A ) __ATTR_CONST__;				// float64_t to signed char
unsigned char __fp64_fixunssdsc( float64_t A ) __ATTR_CONST__;	// float64_t to unsigned char
float __fp64_sdsf (float64_t A) __ATTR_CONST__;					// float64_t to float
char *__fp64_ftoa( float64_t x, uint8_t maxDigits, uint8_t expSep, int16_t *exp10 );
int __fp64_cmpsd2( float64_t a, float64_t b) __ATTR_CONST__;	// greater than
int __fp64_gesd2( float64_t a, float64_t b) __ATTR_CONST__;	// greater equal
int __fp64_gtsd2( float64_t a, float64_t b) __ATTR_CONST__;	// greater than
int __fp64_eqsd2( float64_t a, float64_t b) __ATTR_CONST__;	// equal
int __fp64_nesd2( float64_t a, float64_t b) __ATTR_CONST__;	// not equal
int __fp64_ltsd2( float64_t a, float64_t b) __ATTR_CONST__;	// less than
int __fp64_lesd2( float64_t a, float64_t b) __ATTR_CONST__;	// less equal

#ifdef __cplusplus
} // extern "C"
#endif

#endif
