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

#include <Double.cpp>
// #include "Double.cpp"
	
/* 
 * Example on how to use the Double wrapper class and compare it to the
 * native usage of fp64lib.
 *
 */

float64_t fp64_gamma1(float64_t zpar) {
  const static float64_t par[9] = {
    ((float64_t)0x3feffffffffff950LLU), //    0.99999999999980993
    ((float64_t)0x40852429b6c30b05LLU), //  676.5203681218851
    ((float64_t)0xc093ac8e8ed4171bLLU), //-1259.1392167224028
    ((float64_t)0x40881a9661d3b4d8LLU), //  771.32342877765313
    ((float64_t)0xc06613ae51a32f5dLLU), // -176.61502916214059
    ((float64_t)0x402903c27f8b9c81LLU), //   12.507343278686905
    ((float64_t)0xbfc1bcb2992b2855LLU), //   -0.13857109526572012
    ((float64_t)0x3ee4f0514e4e324fLLU), //    9.9843695780195716E-6
    ((float64_t)0x3e8435508f3faeefLLU)  //    1.5056327351493116E-7
  };
  const static float64_t sqrt2pi =     ((float64_t)0x40040d931ff62705LLU);    // sqrt(2*pi) = 2.5066282746310002
  const static float64_t f_NUMBER_05 = ((float64_t)0x3fe0000000000000LLU);   //0.5
  const static float64_t f_NUMBER_65 = ((float64_t)0x401a000000000000LLU);   //6.5

  float64_t tt = fp64_add(zpar,f_NUMBER_65);
  float64_t dummy = par[0];
  float64_t dummy2 = zpar;
  for( byte i = 1; i < 9; i++ ) {
    dummy = fp64_add(dummy,fp64_div(par[i],dummy2));
    dummy2 = fp64_add(dummy2, float64_NUMBER_ONE);
  }
  dummy = fp64_mul(dummy, fp64_mul(sqrt2pi, fp64_mul(fp64_pow(tt,fp64_sub(zpar,f_NUMBER_05)),fp64_exp(fp64_neg(tt)))));

  return dummy;
}

// gamma function (lanczos approximation) 
// sources: https://en.wikipedia.org/wiki/Lanczos_approximation
//          https://rosettacode.org/wiki/Gamma_function
// Using Double wrapper class
Double Dbl_gamma1(Double zpar) {
  const static Double par[9] = {
    Double("0.99999999999980993"),
    Double("676.5203681218851"),
    Double("-1259.1392167224028"),
    Double("771.32342877765313"),
    Double("-176.61502916214059"),
    Double("12.507343278686905"),
    Double("-0.13857109526572012"),
    Double("9.9843695780195716E-6"),
    Double("1.5056327351493116E-7")
  };

  Double tt = zpar + Double(6.5);
  Double res = par[0];
  Double dummy2 = zpar;
  for( byte i = 1; i < 9; i++ ) {
    res += par[i] / dummy2;
    dummy2 += Double(1);
  }
  res *= Double::sqrt( Double(2)*Double::pi() );
  res *= Double::pow(tt,zpar-Double(0.5)) * Double::exp(-tt);

  return res;
}

void setup() {
	Serial.begin(57600);
	
	Serial.println( "First with direct calls to fp64lib" );
	for( int i = 0; i < 11; i++ ) {
		float64_t x = fp64_int32_to_float64(i);
		float64_t res  = fp64_gamma1(x);
		Serial.print( "gamma(" ); Serial.print(i); Serial.print(")=");
		Serial.println( fp64_to_string(res, 15, 13) );
	}
	
	Serial.println();
	Serial.println( "Now with wrapper class Double" );
	for( int i = 0; i < 11; i++ ) {
		Double x = Double(i);
		Double res  = Dbl_gamma1(x);
		Serial.print( "gamma(" ); Serial.print(i); Serial.print(")=");
		Serial.println( res.toString(13) );
	}
	
	Serial.println();
	Serial.println( "Now with some non-integer values" );
	Double x = Double(1.0);
	for( int i = 0; i < 9; i++ ) {
		x += Double("0.1");
		Double res  = Dbl_gamma1(x);
		Serial.print( "gamma(" ); Serial.print(x.toString(4)); Serial.print(")=");
		Serial.println( res.toString(13) );
	}

	Serial.println();
	Serial.println( "and with some negative values" );
	x = Double(-1.0);
	for( int i = 0; i < 9; i++ ) {
		x -= Double("0.1");
		Double res  = Dbl_gamma1(x);
		Serial.print( "gamma(" ); Serial.print(x.toString(4)); Serial.print(")=");
		Serial.println( res.toString(13) );
	}
}

void loop() {
}