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
		Double( const Double& d ) { x = d.x; }
		const char* toString() { 
			return fp64_to_string( x, 17, 15);
			}
		Double operator+( const Double& y ) {
			Double res;
			res.x = fp64_add( x, y.x );
			return( res );
			}
		Double operator-( const Double& y ) {
			Double res;
			res.x = fp64_sub( x, y.x );
			return( res );
			}
		Double operator*( const Double& y ) {
			Double res;
			res.x = fp64_mul( x, y.x );
			return( res );
			}
		Double operator/( const Double& y ) {
			Double res;
			res.x = fp64_div( x, y.x );
			return( res );
			}
   private:
      float64_t x;
};

#define MAX_COUNT   1000    // # of iterations before printing another approximation
Double x = Double( 1.0 );
Double n = Double( 3.0 );
Double delta = Double( 2.0 );
bool add = false;

void setup() {
	Serial.begin(57600);
}

void loop() {
	int cnt = 0;

	while(1) {
		if( add )
			x = x + Double(1.0)/n;
		else
			x = x - Double(1.0)/n;
		add = !add;
		if( ++cnt == MAX_COUNT ) {
			Serial.print( n.toString() );
			Serial.print(": ");
			Serial.print( x.toString() );
			Serial.print("\t");
			Double pi = x * Double(4.0);
			Serial.println( pi.toString() );
			cnt = 0;
		}
		n = n + Double(2.0);
	}
}
	