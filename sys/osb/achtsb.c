/* Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.
 */

#define	import_spp
#define import_knames
#include <iraf.h>

/* ACHT_B -- Pack SPP array into an unsigned byte array.
 * [MACHDEP]: The underscore appended to the procedure name is OS dependent.
 */
void
ACHTSB (
  XSHORT  	*a,
  XCHAR	    	*b,
  XINT	    	*npix
)
{
	register XSHORT	*ip;
	register XUBYTE	*op;
	register int n = *npix;

	for (ip=(XSHORT *)a, op=(XUBYTE *)b;  --n >= 0;  )
		*op++ = *ip++;
}
