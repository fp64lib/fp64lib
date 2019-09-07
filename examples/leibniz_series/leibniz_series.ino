/* 
 * Example program for using fp64lib.
 * Leibniz formular to approximate PI
 *
 */

#include <fp64lib.h>

#define MAX_COUNT   1000    // # of iterations before printing another approximation

float64_t x, n, two, pi, pi4, prev;
float xf, nf, pif, pi4f, prevf;
bool add = false;

void setup() {

  prev = x = fp64_sd(1.0);
  n = fp64_sd(3.0);
  two = fp64_sd(2);

  prevf = xf = 1.0;
  nf = 3.0;

  pi = float64_NUMBER_PI;
  pi4 = fp64_ldexp( pi, -2 ); // fast division by 4
  pif = M_PI;
  pi4f = ldexp( pif, -2 );

  Serial.begin(57600);
}

char *fixedLength( char *s, float64_t x ) {
    // return a string always with the same length, including trailing zeros
    char *t = fp64_to_string( x, 17, 15 );
    sprintf( s, "%s%s00000000000000000", t[0] == '-' ? " " : "  ", t );
    s[18] = '\0';
    return s;
}

void printLine( float nf, float64_t x, float xf, const char* s, bool usePi ) {
    char buf[40];
  
    float64_t delta = fp64_sub( x, usePi ? pi : pi4 );
    float deltaf = xf - (usePi ? pif : pi4f );
    
    char *t = fp64_to_string( x, 17, 15 );
    Serial.print( nf, 0 ); Serial.print( s ); Serial.print( ":" );
    Serial.print( fixedLength( buf, x ) ); 
    Serial.print( fixedLength( buf, delta ) ); 
    Serial.print( "\t" );

    Serial.print( " " ); Serial.print( xf, 7 );
    Serial.print( " " ); 
    if( deltaf >= 0.0 ) 
      Serial.print( " ");
    Serial.println( deltaf, 7 );
}

void loop() {
  int cnt = 0;

  while( 1 ) {
    prev = x;
    prevf = xf;
    
    if( add ) {
      float64_t t = fp64_inverse(n);
      x = fp64_add( x, t );
      xf = xf + 1.0/nf;
    } else {
      float64_t t = fp64_inverse(n);
      x = fp64_sub( x, t );
      xf = xf - 1.0/nf;
    }
    add = !add;

    ++cnt;
    if( cnt == MAX_COUNT ) {
      float64_t approx = fp64_ldexp( fp64_add( prev, x ), 1);
      float approxf = ldexp( xf + prevf, 1 );
      printLine( nf-2, prev, prevf,  "  low", false ); 
      printLine( nf,   x,    xf,     " high", false ); 
      printLine( nf, approx, approxf,"  avg", true ); 
      printLine( nf, pi,     pif,    "   pi", true ); 
      Serial.println();
      cnt = 0;
    }
  
    n = fp64_add( n, two );
    nf = nf + 2.0;
  }
}
