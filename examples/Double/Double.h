#include <fp64lib.h>

class Double {
	public:
		Double()				{ x = 0ULL; }
		Double( double f )		{ x = fp64_sd( f ); }
		Double( float f )		{ x = fp64_sd( f ); }
		Double( const Double& d ) { x = d.x; }
		const char* toString() { 
			char *s = fp64_to_string( x, 17, 15);
			return s;
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

