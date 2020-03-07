/* 
 * Example program for using fp64lib.
 * Leibniz formular to approximate PI using a small C++ wrapper class
 *
 */

#include <fp64lib.h>

class Double {
	public:
		Double()				{ x = 0ULL; }
		Double( double f )		{ x = fp64_sd( f ); }
		Double( float f )		{ x = fp64_sd( f ); }
		Double( int16_t n )		{ x = fp64_int16_to_float64( n ); }
		Double( uint16_t n )	{ x = fp64_uint16_to_float64( n ); }
		Double( const Double& d ) { x = d.x; }
		const char* toString() { 
			return fp64_to_string( x, 17, 15);
			}
		Double operator+=( const Double& y ) {
			this->x = fp64_add( this->x, y.x );
			return( *this );
			}
		Double operator+( const Double& y ) {
			Double res;
			res.x = fp64_add( this->x, y.x );
			return( res );
			}
		Double operator-=( const Double& y ) {
			this->x = fp64_sub( this->x, y.x );
			return( *this );
			}
		Double operator-( const Double& y ) {
			Double res;
			res.x = fp64_sub( this->x, y.x );
			return( res );
			}
		Double operator*=( const Double& y ) {
			this->x = fp64_mul( this->x, y.x );
			return( *this );
			}
		Double operator*( const Double& y ) {
			Double res;
			res.x = fp64_mul( this->x, y.x );
			return( res );
			}
		Double operator/=( const Double& y ) {
			this->x = fp64_div( this->x, y.x );
			return( *this );
			}
		Double operator/( const Double& y ) {
			Double res;
			res.x = fp64_div( this->x, y.x );
			return( res );
			}
		Double operator%=( const Double& y ) {
			this->x = fp64_fmod( this->x, y.x );
			return( *this );
			}
		Double operator%( const Double &y ) {
			Double res;
			res.x = fp64_fmod( this->x, y.x );
			return( res );
			}
   private:
      float64_t x;
};

#define MAX_COUNT   1000    // # of iterations before printing another approximation
Double x = 1.0;
Double n = 3.0;
Double delta = 2;
bool add = false;

void setup() {
	Serial.begin(57600);
	
	Double a = 1;
	Double b;
	Serial.println( "Test for implicit type casting: b = a + 2" );
	Serial.print("a:"); Serial.println( a.toString() );
	b = a + 2;
	Serial.print("b:"); Serial.println( b.toString() );
	Serial.println( "Test for implicit type casting: a += 3" );
	a += 3;
	Serial.print("a:"); Serial.println( a.toString() );
}

void loop() {
	int cnt = 0;

	while(1) {
		if( add )
			x += Double(1.0)/n;
		else
			x -= Double(1.0)/n;
		add = !add;
		if( ++cnt == MAX_COUNT ) {
			Serial.print( n.toString() );
			Serial.print(": ");
			Serial.print( x.toString() );
			Serial.print("\t");
			Double pi = x * 4;
			Serial.println( pi.toString() );
			cnt = 0;
		}
		n += 2;
	}
}
	