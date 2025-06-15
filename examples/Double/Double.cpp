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
 * Simple C++ wrapper class to ease use of fp64lib.
 * 
 * Usage: Do "#include <Double.cpp>" instead of "#include <fp64lib.h>"
 * Now variables can be declared by "Double x,y,z;" (Notice the uppercase "D"!)
 * and usual operations can be done similar to "normal" double or int variables,
 * like:
 * Double a = Double("1.234567890123456");
 * Double b = a * Double(3.14)
 *
 * For more see online documentation at https://fp64lib.org or in the provided
 * demo programs for fp64lib.
 */

#ifndef DOUBLE_CPP
#define DOUBLE_CPP
#include <fp64lib.h>

class Double {
	public:
		Double()				{ x = 0ULL; }
		Double( double f )		{ x = fp64_sd( f ); }
		Double( float f )		{ x = fp64_sd( f ); }
		Double( float64_t f ) 	{ x = f; }
		Double( int16_t n )		{ x = fp64_int16_to_float64( n ); }
		Double( uint16_t n )	{ x = fp64_uint16_to_float64( n ); }
		Double( int32_t n )		{ x = fp64_int32_to_float64( n ); }
		Double( char *s )		{ x = fp64_atof( s ); }
		Double( const Double& d ) { x = d.x; }
		
		const char* toString() { 
			return fp64_to_string( x, 17, 15);
			}
		const char* toString( int prec ) {
			return fp64_to_string( x, prec+2, prec);
			}
		float64_t data() {
			return this->x;
		}
			
		Double operator+=( const Double& y ) {
			this->x = fp64_add( this->x, y.x );
			return *this ;
			}
		Double operator+( const Double& y ) {
			Double res;
			res.x = fp64_add( this->x, y.x );
			return res;
			}
		Double operator-=( const Double& y ) {
			this->x = fp64_sub( this->x, y.x );
			return *this;
			}
		Double operator-( const Double& y ) {
			Double res;
			res.x = fp64_sub( this->x, y.x );
			return res;
			}
		Double operator-() {
			Double res;
			res.x = fp64_sub( float64_NUMBER_PLUS_ZERO, this->x );
			return res;
			}
		Double operator*=( const Double& y ) {
			this->x = fp64_mul( this->x, y.x );
			return *this;
			}
		Double operator*( const Double& y ) {
			Double res;
			res.x = fp64_mul( this->x, y.x );
			return res;
			}
		Double operator/=( const Double& y ) {
			this->x = fp64_div( this->x, y.x );
			return *this;
			}
		Double operator/( const Double& y ) {
			Double res;
			res.x = fp64_div( this->x, y.x );
			return res;
			}
		Double operator%=( const Double& y ) {
			this->x = fp64_fmod( this->x, y.x );
			return *this;
			}
		Double operator%( const Double &y ) {
			Double res;
			res.x = fp64_fmod( this->x, y.x );
			return res;
			}
		bool operator<( const Double &y ) {
			return fp64_compare( this->x, y.x ) < 0;
		}
		bool operator>( const Double &y ) {
			return fp64_compare( this->x, y.x ) > 0;
		}
		bool operator<=( const Double &y ) {
			return fp64_compare( this->x, y.x ) <= 0;
		}
		bool operator>=( const Double &y ) {
			return fp64_compare( this->x, y.x ) >= 0;
		}
		bool operator==( const Double &y ) {
			return fp64_compare( this->x, y.x ) == 0;
		}
		bool operator!=( const Double &y ) {
			return fp64_compare( this->x, y.x ) != 0;
		}
		static Double pow( const Double &x, const Double &y ) {
			Double res;
			res.x = fp64_pow( x.x, y.x );
			return res;
		}
		static Double sqrt( const Double &x ) {
			Double res;
			res.x = fp64_sqrt( x.x );
			return res;
		}
		static Double pi() {
			return Double(float64_NUMBER_PI);
		}
		static Double log( const Double &x ) {
			Double res;
			res.x = fp64_log( x.x );
			return res;
		}
		static Double exp( const Double &x ) {
			Double res;
			res.x = fp64_exp( x.x );
			return res;
		}	
   private:
      float64_t x;
};
#endif