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

/*
 * Simple C++ wrapper class to ease use of fp64lib.
 *
 * Usage: Do "#include <Double.h>" instead of "#include <fp64lib.h>"
 * Now variables can be declared by "Double x,y,z;" (Notice the uppercase "D"!)
 * and usual operations can be done similar to "normal" double or int variables,
 * like:
 * Double a = Double("1.234567890123456");
 * Double b = a * Double(3.14);
 * b *= Double(2);
 *
 * For more see online documentation at https://fp64lib.org or in the provided
 * demo programs for fp64lib.
 */

#ifndef DOUBLE_H
#define DOUBLE_H

#include <fp64lib.h>

class Double {
	public:
		Double()				{ x = 0ULL; }
		Double( float f )		{ x = fp64_sd( f ); }
		Double( double f ) {
#if __SIZEOF_DOUBLE__ == 8
			__builtin_memcpy (&x, &f, 8);
#else
			x = fp64_sd( f );
#endif
		}
		Double( long double f ) {
#if __SIZEOF_LONG_DOUBLE__ == 8
			__builtin_memcpy (&x, &f, 8);
#else
			x = fp64_sd( f );
#endif
		}
		Double( float64_t f ) 	{ x = f; }
		Double( int16_t n )		{ x = fp64_int16_to_float64( n ); }
		Double( uint16_t n )	{ x = fp64_uint16_to_float64( n ); }
		Double( int32_t n )		{ x = fp64_int32_to_float64( n ); }
		Double( uint32_t n )	{ x = fp64_uint32_to_float64( n ); }
		Double( const char *s )	{ x = fp64_atof( s ); }

		// We cannot overload uint64_t since it is already
		// occupied by float64_t, so bake something extra.
		static Double from_u64 (uint64_t n) {
			Double res;
			res.data() = fp64_uint64_to_float64( n );
			return res;
		}
		static Double from_i64 (int64_t n) {
			Double res;
			res.data() = fp64_int64_to_float64( n );
			return res;
		}

		const char* toString() {
			return fp64_to_string( x, 17, 15);
			}
		const char* toString( int prec ) {
			return fp64_to_string( x, prec+2, prec);
			}

		float64_t& data() {
			return this->x;
		}
		const float64_t& data() const {
			return this->x;
		}

		explicit operator float64_t() const {
			return data();
		}

		explicit operator uint32_t() const {
			return fp64_to_uint32( this->x );
		}
		explicit operator int32_t() const {
			return fp64_to_int32( this->x );
		}
		explicit operator uint16_t() const {
			return fp64_to_uint16( this->x );
		}
		explicit operator int16_t() const {
			return fp64_to_int16( this->x );
		}
		explicit operator uint8_t() const {
			return fp64_to_uint8( this->x );
		}
		explicit operator int8_t() const {
			return fp64_to_int8( this->x );
		}

		// We cannot overload uint64_t() since it is already
		// occupied by float64_t, so bake something extra.
		uint64_t to_uint64 () const {
			return fp64_to_uint64( this->x );
		}
		int64_t to_int64 () const {
			return fp64_to_int64( this->x );
		}

		explicit operator float() const {
			return fp64_ds( this->x );
		}

		explicit operator double() const {
			double d;
#if __SIZEOF_DOUBLE__ == 8
			__builtin_memcpy (&d, &x, 8);
#else
			d = fp64_ds (this->x);
#endif
			return d;
		}

		explicit operator long double() const {
			long double d;
#if __SIZEOF_LONG_DOUBLE__ == 8
			__builtin_memcpy (&d, &x, 8);
#else
			d = fp64_ds (this->x);
#endif
			return d;
		}

		Double operator+=( const Double& y ) {
			this->x = fp64_add( this->x, y.x );
			return *this ;
			}
		Double operator+( const Double& y ) const {
			Double res;
			res.x = fp64_add( this->x, y.x );
			return res;
			}
		Double operator+() const {
			return *this;
			}
		Double operator-=( const Double& y ) {
			this->x = fp64_sub( this->x, y.x );
			return *this;
			}
		Double operator-( const Double& y ) const {
			Double res;
			res.x = fp64_sub( this->x, y.x );
			return res;
			}
		Double operator-() const {
			Double res;
			res.x = fp64_neg( this->x );
			return res;
			}
		Double operator*=( const Double& y ) {
			this->x = fp64_mul( this->x, y.x );
			return *this;
			}
		Double operator*( const Double& y ) const {
			Double res;
			res.x = fp64_mul( this->x, y.x );
			return res;
			}
		Double operator/=( const Double& y ) {
			this->x = fp64_div( this->x, y.x );
			return *this;
			}
		Double operator/( const Double& y ) const {
			Double res;
			res.x = fp64_div( this->x, y.x );
			return res;
			}
		Double operator%=( const Double& y ) {
			this->x = fp64_fmod( this->x, y.x );
			return *this;
			}
		Double operator%( const Double &y ) const {
			Double res;
			res.x = fp64_fmod( this->x, y.x );
			return res;
			}
		bool operator<( const Double &y ) const {
			return fp64_compare( this->x, y.x ) < 0;
		}
		bool operator>( const Double &y ) const {
			return fp64_compare( this->x, y.x ) > 0;
		}
		bool operator<=( const Double &y ) const {
			return fp64_compare( this->x, y.x ) <= 0;
		}
		bool operator>=( const Double &y ) const {
			return fp64_compare( this->x, y.x ) >= 0;
		}
		bool operator==( const Double &y ) const {
			return fp64_compare( this->x, y.x ) == 0;
		}
		bool operator!=( const Double &y ) const {
			return fp64_compare( this->x, y.x ) != 0;
		}

		Double& operator<<= (int off) {
			x = fp64_ldexp (x, off);
			return *this;
		}
		Double& operator>>= (int off) {
			x = fp64_ldexp (x, -off);
			return *this;
		}
		Double operator<< (int off) const {
			return this->ldexp (off);
		}
		Double operator>> (int off) const {
			return this->ldexp (-off);
		}

		// Double (*) (const Double&);

#define FP64LIB_IMPL(F)							\
		Double F () const {						\
			return Double (fp64_##F (x));		\
		}										\
		static Double F (const Double &x) {		\
			return x.F ();						\
		}
		FP64LIB_IMPL (abs)
		FP64LIB_IMPL (acos)
		FP64LIB_IMPL (acosh)
		FP64LIB_IMPL (asin)
		FP64LIB_IMPL (asinh)
		FP64LIB_IMPL (atan)
		FP64LIB_IMPL (atanh)
		FP64LIB_IMPL (cbrt)
		FP64LIB_IMPL (ceil)
		FP64LIB_IMPL (cos)
		FP64LIB_IMPL (cosh)
		FP64LIB_IMPL (cotan)
		FP64LIB_IMPL (exp)
		FP64LIB_IMPL (exp2)
		FP64LIB_IMPL (exp10)
		FP64LIB_IMPL (floor)
		FP64LIB_IMPL (log)
		FP64LIB_IMPL (log2)
		FP64LIB_IMPL (log10)
		FP64LIB_IMPL (pow2)
		FP64LIB_IMPL (pow10)
		FP64LIB_IMPL (round)
		FP64LIB_IMPL (sin)
		FP64LIB_IMPL (sinh)
		FP64LIB_IMPL (sqrt)
		FP64LIB_IMPL (tan)
		FP64LIB_IMPL (tanh)
		FP64LIB_IMPL (trunc)
#undef FP64LIB_IMPL

		// Double (*) (const Double&, const Double&);

		static Double atan2 (const Double &x, const Double &y) {
			return Double (fp64_atan2 (x.x, y.x));
		}
		static Double copysign (const Double &x, const Double &y) {
			return Double (fp64_copysign (x.x, y.x));
		}
		static Double fdim (const Double &x, const Double &y) {
			return Double (fp64_fdim (x.x, y.x));
		}
		static Double hypot (const Double &x, const Double &y) {
			return Double (fp64_hypot (x.x, y.x));
		}
		long lrint () const {
			return fp64_lrint (x);
		}
		static long lrint (const Double &x) {
			return x.lrint ();
		}
		long lround () const {
			return fp64_lround (x);
		}
		static long lround (const Double &x) {
			return x.lround ();
		}
		Double max (const Double &y) const {
			return Double (fp64_fmax (x, y.x));
		}
		static Double max (const Double &x, const Double &y) {
			return x.max (y);
		}
		Double min (const Double &y) const {
			return Double (fp64_fmin (x, y.x));
		}
		static Double min (const Double &x, const Double &y) {
			return x.min (y);
		}
		Double pow (const Double &y) const {
			return Double (fp64_pow (x, y.x));
		}
		static Double pow (const Double &x, const Double &y) {
			return x.pow (y);
		}

		// Misc signature

		Double frexp (int *pex) const {
			return Double (fp64_frexp (x, pex));
		}
		static Double frexp (const Double &x, int *pex) {
			return x.frexp (pex);
		}
		Double ldexp (int ex) const {
			return Double (fp64_ldexp (x, ex));
		}
		static Double ldexp (const Double &x, int ex) {
			return x.ldexp (ex);
		}
		static Double modf (const Double &x, Double &y) {
			Double xx (x);
			return Double (fp64_modf (xx.x, &y.x));
		}
		Double scalbn (int ex) const {
			return Double (fp64_scalbn (x, ex));
		}
		static Double scalbn (const Double &x, int ex) {
			return x.scalbn (ex);
		}
		Double scalbln (long ex) const {
			return Double (fp64_scalbln (x, ex));
		}
		static Double scalbln (const Double &x, long ex) {
			return x.scalbln (ex);
		}

		static Double pi() {
			return Double(float64_NUMBER_PI);
		}

   private:
      float64_t x;
};
#endif
