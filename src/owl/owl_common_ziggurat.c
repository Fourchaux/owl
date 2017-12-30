# include <stdlib.h>
# include <stdio.h>
# include <math.h>
# include <stdint.h>

# include "owl_macros.h"

static long hz;
static uint32_t kn[128], ke[256];
static float wn[128], fn[128], we[256], fe[256];


float r4_exp ( uint32_t *jsr ) {
  uint32_t iz;
  uint32_t jz;
  float value;
  float x;

  jz = shr3_seeded ( jsr );
  iz = ( jz & 255 );

  if ( jz < ke[iz] )
  {
    value = ( float ) ( jz ) * we[iz];
  }
  else
  {
    for ( ; ; )
    {
      if ( iz == 0 )
      {
        value = 7.69711 - log ( r4_uni ( jsr ) );
        break;
      }

      x = ( float ) ( jz ) * we[iz];

      if ( fe[iz] + r4_uni ( jsr ) * ( fe[iz-1] - fe[iz] ) < exp ( - x ) )
      {
        value = x;
        break;
      }

      jz = shr3_seeded ( jsr );
      iz = ( jz & 255 );

      if ( jz < ke[iz] )
      {
        value = ( float ) ( jz ) * we[iz];
        break;
      }
    }
  }
  return value;
}


void r4_exp_setup () {
  double de = 7.697117470131487;
  int i;
  const double m2 = 2147483648.0;
  double q;
  double te = 7.697117470131487;
  const double ve = 3.949659822581572E-03;

  q = ve / exp ( - de );

  ke[0] = ( uint32_t ) ( ( de / q ) * m2 );
  ke[1] = 0;

  we[0] = ( float ) ( q / m2 );
  we[255] = ( float ) ( de / m2 );

  fe[0] = 1.0;
  fe[255] = ( float ) ( exp ( - de ) );

  for ( i = 254; 1 <= i; i-- )
  {
    de = - log ( ve / de + exp ( - de ) );
    ke[i+1] = ( uint32_t ) ( ( de / te ) * m2 );
    te = de;
    fe[i] = ( float ) ( exp ( - de ) );
    we[i] = ( float ) ( de / m2 );
  }
  return;
}


float ziggurat_gaussian ( ) {
  int hz;
  uint32_t iz;
  const float r = 3.442620;
  float value;
  float x;
  float y;

  hz = ( int ) sfmt_rand32;
  iz = ( hz & 127 );

  if ( fabs ( hz ) < kn[iz] )
  {
    value = ( float ) ( hz ) * wn[iz];
  }
  else
  {
    for ( ; ; )
    {
      if ( iz == 0 )
      {
        for ( ; ; )
        {
          x = - 0.2904764 * log ( sfmt_randf1 );
          y = - log ( sfmt_randf1 );
          if ( x * x <= y + y )
          {
            break;
          }
        }

        if ( hz <= 0 )
        {
          value = - r - x;
        }
        else
        {
          value = + r + x;
        }
        break;
      }

      x = ( float ) ( hz ) * wn[iz];

      if ( fn[iz] + ( sfmt_randf1 ) * ( fn[iz-1] - fn[iz] )
        < exp ( - 0.5 * x * x ) )
      {
        value = x;
        break;
      }

      hz = ( int ) sfmt_rand32;
      iz = ( hz & 127 );

      if ( fabs ( hz ) < kn[iz] )
      {
        value = ( float ) ( hz ) * wn[iz];
        break;
      }
    }
  }

  return value;
}
/******************************************************************************/

void ziggurat_gaussian_init ( ) {
  double dn = 3.442619855899;
  int i;
  const double m1 = 2147483648.0;
  double q;
  double tn = 3.442619855899;
  const double vn = 9.91256303526217E-03;

  q = vn / exp ( - 0.5 * dn * dn );

  kn[0] = ( uint32_t ) ( ( dn / q ) * m1 );
  kn[1] = 0;

  wn[0] = ( float ) ( q / m1 );
  wn[127] = ( float ) ( dn / m1 );

  fn[0] = 1.0;
  fn[127] = ( float ) ( exp ( - 0.5 * dn * dn ) );

  for ( i = 126; 1 <= i; i-- )
  {
    dn = sqrt ( - 2.0 * log ( vn / dn + exp ( - 0.5 * dn * dn ) ) );
    kn[i+1] = ( uint32_t ) ( ( dn / tn ) * m1 );
    tn = dn;
    fn[i] = ( float ) ( exp ( - 0.5 * dn * dn ) );
    wn[i] = ( float ) ( dn / m1 );
  }

  return;
}
/******************************************************************************/

float r4_uni ( uint32_t *jsr ) {
  uint32_t jsr_input;
  float value;

  jsr_input = *jsr;

  *jsr = ( *jsr ^ ( *jsr <<   13 ) );
  *jsr = ( *jsr ^ ( *jsr >>   17 ) );
  *jsr = ( *jsr ^ ( *jsr <<    5 ) );

  value = fmod ( 0.5
    + ( float ) ( jsr_input + *jsr ) / 65536.0 / 65536.0, 1.0 );

  return value;
}
/******************************************************************************/

uint32_t shr3_seeded ( uint32_t *jsr ) {
  uint32_t value;

  value = *jsr;

  *jsr = ( *jsr ^ ( *jsr <<   13 ) );
  *jsr = ( *jsr ^ ( *jsr >>   17 ) );
  *jsr = ( *jsr ^ ( *jsr <<    5 ) );

  value = value + *jsr;

  return value;
}


void ziggurat_init ( ) {
  ziggurat_gaussian_init();
}
