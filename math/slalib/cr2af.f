      SUBROUTINE slCRAF (NDP, ANGLE, SIGN, IDMSF)
*+
*     - - - - - -
*      C R A F
*     - - - - - -
*
*  Convert an angle in radians into degrees, arcminutes, arcseconds
*  (single precision)
*
*  Given:
*     NDP       int      number of decimal places of arcseconds
*     ANGLE     real     angle in radians
*
*  Returned:
*     SIGN      char     '+' or '-'
*     IDMSF     int(4)   degrees, arcminutes, arcseconds, fraction
*
*  Notes:
*
*     1)  NDP less than zero is interpreted as zero.
*
*     2)  The largest useful value for NDP is determined by the size of
*         ANGLE, the format of REAL floating-point numbers on the target
*         machine, and the risk of overflowing IDMSF(4).  For example,
*         on the VAX, for ANGLE up to 2pi, the available floating-point
*         precision corresponds roughly to NDP=3.  This is well below
*         the ultimate limit of NDP=9 set by the capacity of the 32-bit
*         integer IHMSF(4).
*
*     3)  The absolute value of ANGLE may exceed 2pi.  In cases where it
*         does not, it is up to the caller to test for and handle the
*         case where ANGLE is very nearly 2pi and rounds up to 360 deg,
*         by testing for IDMSF(1)=360 and setting IDMSF(1-4) to zero.
*
*  Called:
*     slCDTF
*
*  P.T.Wallace   Starlink   11 September 1990
*
*  Copyright (C) 1995 Rutherford Appleton Laboratory
*  Copyright (C) 1995 Association of Universities for Research in Astronomy Inc.
*-

      IMPLICIT NONE

      INTEGER NDP
      REAL ANGLE
      CHARACTER SIGN*(*)
      INTEGER IDMSF(4)

*  Hours to degrees * radians to turns
      REAL F
      PARAMETER (F=15.0/6.283185307179586476925287)



*  Scale then use days to h,m,s routine
      CALL slCDTF(NDP,ANGLE*F,SIGN,IDMSF)

      END