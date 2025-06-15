/* Copyright (c) 2019-2025  Uwe Bissinger
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

/*
 * Show that double and float are the same on the MegaAVR C compiler
 * and that we run quite quite early into the limits of single precision
 *
 */
 
#include <fp64lib.h>

void setup() {
	Serial.begin(57600);
	
	volatile float aa, a;
	volatile double bb, b;    
	volatile float64_t cc, c; 

	a = aa = 1.234567890123456;
    b = bb = 1.234567890123456;
    c = cc = fp64_atof("1.234567890123456" );
	
	Serial.println( "double is the same as float" );
	Serial.print( "    sizeof(float) = " ); Serial.println( sizeof(float) );
	Serial.print( "   sizeof(double) = " ); Serial.println( sizeof(double) );
	Serial.print( "sizeof(float64_t) = " ); Serial.println( sizeof(float64_t) );
	Serial.println();

	Serial.println( "Var should be 1.234567890123456" );
	Serial.print("    float a = "); Serial.println( a, 15 );
	Serial.print("   double a = "); Serial.println( b, 15 );
	Serial.print("float64_t c = "); Serial.println( fp64_to_string(c,17,15) );
	Serial.println();

	Serial.println( "Add 1e-5 = 0.00001\nRes should be 1.234577890123456" );
	a += 1e-5;
	b += 1e-5;
	c = fp64_add( c, fp64_atof("1e-5") );
	Serial.print("    float a = "); Serial.println( a, 15 );
	Serial.print("   double a = "); Serial.println( b, 15 );
	Serial.print("float64_t c = "); Serial.println( fp64_to_string(c,17,15) );
	Serial.println();
	
	Serial.println( "Add 1000\nRes should be 1001.234577890123456" );
	a += 1000.0;
	b += 1000.0;
	c = fp64_add( c, fp64_atof("1000") );
	Serial.print("    float a = "); Serial.println( a, 15 );
	Serial.print("   double a = "); Serial.println( b, 15 );
	Serial.print("float64_t c = "); Serial.println( fp64_to_string(c,18,16) );
	Serial.println();


	Serial.println( "Now subtract 1000.00001\nRes should be 1.234567890123456, our starting value" );
	a -= 1000.00001;
	b -= 1000.00001;
	c = fp64_sub( c, fp64_atof("1000.00001") );
	Serial.print("    float a = "); Serial.print( a, 15 ); Serial.print( " diff = " ); Serial.println( a-aa, 15 );
	Serial.print("   double a = "); Serial.print( b, 15 ); Serial.print( " diff = " ); Serial.println( b-bb, 15 );
	Serial.print("float64_t c = "); Serial.print( fp64_to_string(c,17,15) );  Serial.print( " diff = " ); Serial.println( fp64_to_string(fp64_sub(c,cc),17,15) );
	Serial.println();
	
	
	Serial.println("Now with multiplication");
	a = aa;
	b = bb;
	c = cc;

	Serial.println( "Multiply with 1e-1 = 0.00001\nRes should be 0.1234567890123456" );
	a *= 1e-1;
	b *= 1e-1;
	c = fp64_mul( c, fp64_atof("1e-1") );
	Serial.print("    float a = "); Serial.println( a, 15 );
	Serial.print("   double a = "); Serial.println( b, 15 );
	Serial.print("float64_t c = "); Serial.println( fp64_to_string(c,17,15) );
	Serial.println();
	
	Serial.println( "Multiply 1000\nRes should be 123.4567890123456" );
	a *= 1000.0;
	b *= 1000.0;
	c = fp64_mul( c, fp64_atof("1000") );
	Serial.print("    float a = "); Serial.println( a, 15 );
	Serial.print("   double a = "); Serial.println( b, 15 );
	Serial.print("float64_t c = "); Serial.println( fp64_to_string(c,18,16) );
	Serial.println();


	Serial.println( "Now divide by 100\nRes should be 1.234567890123456, our starting value" );
	a /= 100;
	b /= 100;
	c = fp64_div( c, fp64_atof("100") );
	Serial.print("    float a = "); Serial.print( a, 15 ); Serial.print( " diff = " ); Serial.println( a-aa, 15 );
	Serial.print("   double a = "); Serial.print( b, 15 ); Serial.print( " diff = " ); Serial.println( b-bb, 15 );
	Serial.print("float64_t c = "); Serial.print( fp64_to_string(c,17,15) );  Serial.print( " diff = " ); Serial.println( fp64_to_string(fp64_sub(c,cc),17,15) );
	Serial.println();
	
}

void loop() {
}