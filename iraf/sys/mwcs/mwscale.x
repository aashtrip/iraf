# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	"mwcs.h"

# MW_SCALE -- Front end to mw_translate, used to perform a simple rescaling
# of the logical system.

procedure mw_scale (mw, scale, axbits)

pointer	mw			#I pointer to MWCS descriptor
real	scale[ARB]		#I scale factor for each axis in axbits
int	axbits			#I bitflags defining axes

size_t	sz_val
pointer	sp, ltm, ltv_1, ltv_2
int	axis[MAX_DIM], naxes, pdim, nelem, axmap, i, j

begin
	# Convert axis bitflags to axis list.
	call mw_gaxlist (mw, axbits, axis, naxes)
	if (naxes <= 0)
	    return

	pdim = MI_NDIM(mw)
	nelem = pdim * pdim
	axmap = MI_USEAXMAP(mw)
	MI_USEAXMAP(mw) = NO

	call smark (sp)
	sz_val = nelem
	call salloc (ltm, sz_val, TY_DOUBLE)
	sz_val = pdim
	call salloc (ltv_1, sz_val, TY_DOUBLE)
	call salloc (ltv_2, sz_val, TY_DOUBLE)

	# Initialize the translation matrix and vectors.
	call mw_mkidmd (Memd[ltm], pdim)
	call aclrd (Memd[ltv_1], pdim)
	call aclrd (Memd[ltv_2], pdim)

	# Enter the axis scale factors.
	do i = 1, naxes {
	    j = axis[i] - 1
	    Memd[ltm+j*pdim+j] = scale[i]
	}

	# Perform the translation.
	call mw_translated (mw, Memd[ltv_1], Memd[ltm], Memd[ltv_2], pdim)

	MI_USEAXMAP(mw) = axmap
	call sfree (sp)
end
