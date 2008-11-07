# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<math/curfit.h>
include	"names.h"

# IC_REJECT -- Reject points with large residuals from the fit.
#
# The sigma of the fit residuals is calculated.  The rejection thresholds
# are set at low_reject*sigma and high_reject*sigma.  Points outside the
# rejection threshold are rejected from the fit and flagged in the rejpts
# array.  Finally, the remaining points are refit.

procedure ic_rejectr (cv, x, y, w, rejpts, npts, low_reject, high_reject,
    niterate, grow, nreject)

pointer	cv				# Curve descriptor
real	x[npts]				# Input ordinates
real	y[npts]				# Input data values
real	w[npts]				# Weights
int	rejpts[npts]			# Points rejected
size_t	npts				# Number of input points
real	low_reject, high_reject		# Rejection threshold
int	niterate			# Number of rejection iterations
real	grow				# Rejection radius
size_t	nreject				# Number of points rejected

int	i, ierr, nit
size_t	newreject
errchk	ic_deviantr

begin
	# Initialize rejection.
	nreject = 0
	call amovki (NO, rejpts, npts)

	if (niterate <= 0)
	    return

	# Find deviant points.  If an error occurs reduce the number of
	# iterations and start again.
	iferr {
	    nit = 0
	    do i = 1, niterate {
		call ic_deviantr (cv, x, y, w, rejpts, npts, low_reject,
		    high_reject, grow, YES, nreject, newreject)
		nit = nit + 1
		if (newreject == 0)
		    break
	    }
	} then {
	    call rcvfit (cv, x, y, w, npts, WTS_USER, ierr)
	    nreject = 0
	    call amovki (NO, rejpts, npts)
	    do i = 1, nit
		call ic_deviantr (cv, x, y, w, rejpts, npts, low_reject,
		    high_reject, grow, YES, nreject, newreject)
	}
end
