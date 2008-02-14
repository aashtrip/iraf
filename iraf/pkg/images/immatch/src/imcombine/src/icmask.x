include	<imhdr.h>
include	<imset.h>
include	<pmset.h>
include	"icombine.h"
include	"icmask.h"

# IC_MASK   -- ICOMBINE mask interface
#
# IC_MOPEN  -- Initialize mask interface
# IC_MCLOSE -- Close the mask interface
# IC_MGET   -- Get lines of mask pixels for all the images
# IC_MGET1  -- Get a line of mask pixels for the specified image
# IC_MCLOSE1-- Close a mask for the specified image index


# IC_MOPEN -- Initialize mask interface.

procedure ic_mopen (in, out, nimages, offsets)

pointer	in[nimages]		#I Input images
pointer	out[ARB]		#I Output images
int	nimages			#I Number of images
int	offsets[nimages,ARB]	#I Offsets to  output image

size_t	sz_val
int	mtype			# Mask type
int	mvalue			# Mask value
pointer	bufs			# Pointer to data line buffers
pointer	pms			# Pointer to array of PMIO pointers
pointer	names			# Pointer to array of string pointers

int	i, j, k, nin, nout, npix, npms, nowhite(), strdic(), ctor()
real	rval
pointer	sp, key, fname, title, image, pm, pm_open()
bool	invert, pm_empty()
errchk	calloc, pm_open, ic_pmload

include "icombine.com"

begin
	icm = NULL
	if (IM_NDIM(out[1]) == 0)
	    return

	call smark (sp)
	sz_val = SZ_FNAME
	call salloc (key, sz_val, TY_CHAR)
	call salloc (fname, sz_val, TY_CHAR)
	call salloc (title, sz_val, TY_CHAR)
	call salloc (image, sz_val, TY_CHAR)

	# Determine the mask parameters and allocate memory.
	# The mask buffers are initialize to all excluded so that
	# output points outside the input data are always excluded
	# and don't need to be set on a line-by-line basis.

	mtype = M_NONE
	call clgstr ("masktype", Memc[key], SZ_FNAME)
	if (nowhite (Memc[key], Memc[key], SZ_FNAME) > 0) {
	    if (Memc[key] == '!') {
		mtype = M_GOODVAL
		call strcpy (Memc[key+1], Memc[key], SZ_FNAME)
	    } else {
		mtype = strdic (Memc[key], Memc[title], SZ_FNAME, MASKTYPES)
		if (mtype == 0) {
		    call sprintf (Memc[title], SZ_FNAME,
			"Invalid or ambiguous masktype (%s)")
			call pargstr (Memc[key])
		    call error (1, Memc[title])
		}
		call strcpy ("BPM", Memc[key], SZ_FNAME)
	    }
	}
	npix = IM_LEN(out[1],1)
	call calloc (pms, nimages, TY_POINTER)
	call calloc (bufs, nimages, TY_POINTER)
	call calloc (names, nimages, TY_POINTER)
	do i = 1, nimages {
	    call malloc (Memi[bufs+i-1], npix, TY_INT)
	    call amovki (1, Memi[Memi[bufs+i-1]], npix)
	}

	# Check for special cases.  The BOOLEAN type is used when only
	# zero and nonzero are significant; i.e. the actual mask values are
	# not important.  The invert flag is used to indicate that
	# empty masks are all bad rather the all good.

	# Eventually we want to allow general expressions.  For now we only
	# allow a special '<' or '>' operator.

	call clgstr ("maskvalue", Memc[title], SZ_FNAME)
	i = 1
	if (Memc[title] == '<') {
	    mtype = M_LTVAL
	    i = i + 1
	} else if (Memc[title] == '>') {
	    mtype = M_GTVAL
	    i = i + 1
	}
	if (ctor (Memc[title], i, rval) == 0)
	    call error (1, "Bad mask value")
	if (rval < 0)
	    call error (1, "Bad mask value")
	mvalue = rval
	if (mtype == 0)
	    mtype = M_NONE
	if (mtype == M_BADBITS && mvalue == 0) 
	    mtype = M_NONE
	if (mvalue == 0 && (mtype == M_GOODVAL || mtype == M_GOODBITS))
	    mtype = M_BOOLEAN
	if ((mtype == M_BADVAL && mvalue == 0) ||
	    (mtype == M_GOODVAL && mvalue != 0) ||
	    (mtype == M_GOODBITS && mvalue == 0))
	    invert = true 
	else
	    invert = false 

	# If mask images are to be used, get the mask name from the image
	# header and open it saving the descriptor in the pms array.
	# Empty masks (all good) are treated as if there was no mask image.

	nout = IM_LEN(out[1],1)
	npms = 0
	do i = 1, nimages {
	    if (mtype != M_NONE) {
		call malloc (Memi[names+i-1], SZ_FNAME, TY_CHAR)
		fname = Memi[names+i-1]
		ifnoerr (call imgstr (in[i],Memc[key],Memc[fname],SZ_FNAME)) {
		    nin = IM_LEN(in[i],1)
		    j = max (0, offsets[i,1])
		    k = min (nout, nin + offsets[i,1])
		    npix = k - j
		    if (npix < 1)
			Memc[fname] = EOS
		    else {
			pm = pm_open (NULL)
			call ic_pmload (in[i], pm, Memc[fname], SZ_FNAME)
			call pm_seti (pm, P_REFIM, in[i])
			if (pm_empty (pm) && !invert)
			    Memc[fname] = EOS
			else {
			    if (project)
				npms = nimages
			    else
				npms = npms + 1
			}
			call pm_close (pm)
		    }
		    if (project)
			break
		} else
		    Memc[fname] = EOS
	    }
	}

	# If no mask images are found and the mask parameters imply that
	# good values are 0 then use the special case of no masks.

	if (npms == 0) {
	    if (!invert)
		mtype = M_NONE
	}

	# Set up mask structure.
	call calloc (icm, ICM_LEN, TY_STRUCT)
	ICM_TYPE(icm) = mtype
	ICM_VALUE(icm) = mvalue
	ICM_BUFS(icm) = bufs
	ICM_PMS(icm) = pms
	ICM_NAMES(icm) = names

	call sfree (sp)
end


# IC_PMLOAD -- Find and load a mask.
# This is more complicated because we want to allow a mask name specified
# without a path to be found either in the current directory or in the
# directory of the image.

procedure ic_pmload (im, pm, fname, maxchar)

pointer	im			#I Image pointer to be associated with mask
pointer	pm			#O Mask pointer to be returned
char	fname[ARB]		#U Mask name
int	maxchar			#I Max size of mask name

size_t	sz_val
pointer	sp, str, imname
int	i, fnldir(), stridxs()

begin
	call smark (sp)
	sz_val = SZ_PATHNAME
	call salloc (str, sz_val, TY_CHAR)

	# First check if the specified file can be loaded.
	ifnoerr (call pm_loadf (pm, fname, Memc[str], SZ_PATHNAME))
	    return
	ifnoerr (call pm_loadim (pm, fname, Memc[str], SZ_PATHNAME))
	    return

	# Check if the file has a path in which case we return an error.
	# Must deal with possible [] which is a VMS directory delimiter.
	call strcpy (fname, Memc[str], SZ_PATHNAME)
	i = stridxs ("[", Memc[str])
	if (i > 0)
	    Memc[str+i-1] = EOS
	if (fnldir (Memc[str], Memc[str], SZ_PATHNAME) > 0) {
	    call sprintf (Memc[str], SZ_PATHNAME,
	        "Bad pixel mask not found (%s)")
		call pargstr (fname)
	    call error (1, Memc[str])
	}

	# Check if the image has a path.  If not return an error.
	sz_val = SZ_PATHNAME
	call salloc (imname, sz_val, TY_CHAR)
	call imstats (im, IM_IMAGENAME, Memc[imname], SZ_PATHNAME)
	if (fnldir (Memc[imname], Memc[str], SZ_PATHNAME) == 0) {
	    call sprintf (Memc[str], SZ_PATHNAME,
	        "Bad pixel mask not found (%s)")
		call pargstr (fname)
	    call error (1, Memc[str])
	}

	# Try using the image path for the mask file.
	call strcat (fname, Memc[str], SZ_PATHNAME)
	ifnoerr (call pm_loadf (pm, Memc[str], Memc[imname], SZ_PATHNAME)) {
	    call strcpy (Memc[str], fname, maxchar)
	    return
	}
	ifnoerr (call pm_loadim (pm, Memc[str], Memc[imname], SZ_PATHNAME)) {
	    call strcpy (Memc[str], fname, maxchar)
	    return
	}

	# No mask found.
	call sprintf (Memc[str], SZ_PATHNAME,
	    "Bad pixel mask not found (%s)")
	    call pargstr (fname)
	call error (1, Memc[str])

	# This will not be reached and we let the calling program free
	# the stack.  We include smark/sfree for lint detectors.
	call sfree (sp)
end



# IC_MCLOSE -- Close the mask interface.

procedure ic_mclose (nimages)

int	nimages			# Number of images

int	i
include	"icombine.com"

begin
	if (icm == NULL)
	    return

	do i = 1, nimages {
	    call mfree (Memi[ICM_NAMES(icm)+i-1], TY_CHAR)
	    call mfree (Memi[ICM_BUFS(icm)+i-1], TY_INT)
	}
	do i = 1, nimages {
	    if (Memi[ICM_PMS(icm)+i-1] != NULL)
		call pm_close (Memi[ICM_PMS(icm)+i-1])
	    if (project)
		break
	}
	call mfree (ICM_NAMES(icm), TY_POINTER)
	call mfree (ICM_BUFS(icm), TY_POINTER)
	call mfree (ICM_PMS(icm), TY_POINTER)
	call mfree (icm, TY_STRUCT)
end


# IC_MGET -- Get lines of mask pixels in the output coordinate system.
# This converts the mask format to an array where zero is good and nonzero
# is bad.  This has special cases for optimization.

procedure ic_mget (in, out, offsets, v1, v2, m, lflag, nimages)

pointer	in[nimages]		# Input image pointers
pointer	out[ARB]		# Output image pointer
int	offsets[nimages,ARB]	# Offsets to  output image
long	v1[IM_MAXDIM]		# Data vector desired in output image
long	v2[IM_MAXDIM]		# Data vector in input image
pointer	m[nimages]		# Pointer to mask pointers
int	lflag[nimages]		# Line flags
int	nimages			# Number of images

int	mtype			# Mask type
int	mvalue			# Mask value
pointer	bufs			# Pointer to data line buffers
pointer	pms			# Pointer to array of PMIO pointers

char	title[1]
int	i, j, k, ndim, nin, nout, npix
pointer	buf, pm, names, fname, pm_open()
bool	pm_linenotempty()
errchk	pm_glpi, pm_open, pm_loadf, pm_loadim

include	"icombine.com"

begin
	# Determine if masks are needed at all.  Note that the threshold
	# is applied by simulating mask values so the mask pointers have to
	# be set.

	dflag = D_ALL
	if (icm == NULL)
	    return
	if (ICM_TYPE(icm) == M_NONE && aligned && !dothresh)
	    return

	mtype = ICM_TYPE(icm)
	mvalue = ICM_VALUE(icm)
	bufs = ICM_BUFS(icm)
	pms = ICM_PMS(icm)
	names = ICM_NAMES(icm)

	# Set the mask pointers and line flags and apply offsets if needed.

	ndim = IM_NDIM(out[1])
	nout = IM_LEN(out[1],1)
	do i = 1, nimages {
	    nin = IM_LEN(in[i],1)
	    j = max (0, offsets[i,1])
	    k = min (nout, nin + offsets[i,1])
	    npix = k - j

	    m[i] = Memi[bufs+i-1]
	    buf = Memi[bufs+i-1] + j
	    if (project) {
		pm =  Memi[pms]
		fname = Memi[names]
	    } else {
		pm =  Memi[pms+i-1]
		fname = Memi[names+i-1]
	    }

	    if (npix < 1)
	        lflag[i] = D_NONE
	    else if (npix == nout)
	        lflag[i] = D_ALL
	    else
	        lflag[i] = D_MIX

	    if (lflag[i] != D_NONE) {
		v2[1] = 1 + j - offsets[i,1]
		do j = 2, ndim {
		    v2[j] = v1[j] - offsets[i,j]
		    if (v2[j] < 1 || v2[j] > IM_LEN(in[i],j)) {
			lflag[i] = D_NONE
			break
		    }
		}
	    }
	    if (project)
		v2[ndim+1] = i

	    if (lflag[i] == D_NONE) {
		if (pm != NULL && !project) {
		    call pm_close (pm)
		    Memi[pms+i-1] = NULL
		}
		next
	    }

	    if (fname == NULL) {
		call aclri (Memi[buf], npix)
		next
	    } else if (Memc[fname] == EOS) {
		call aclri (Memi[buf], npix)
		next
	    }

	    # Do mask I/O and convert to appropriate values in order of
	    # expected usage.

	    if (pm == NULL) {
		pm = pm_open (NULL)
		iferr (call pm_loadf (pm, Memc[fname], title, 1))
		    call pm_loadim (pm, Memc[fname], title, 1)
		call pm_seti (pm, P_REFIM, in[i])
		if (project)
		    Memi[pms] = pm
		else
		    Memi[pms+i-1] = pm
	    }

	    if (pm_linenotempty (pm, v2)) {
		call pm_glpi (pm, v2, Memi[buf], 32, npix, 0)

		if (mtype == M_BOOLEAN)
		    ;
		else if (mtype == M_BADBITS)
		    call aandki (Memi[buf], mvalue, Memi[buf], npix)
		else if (mtype == M_BADVAL)
		    call abeqki (Memi[buf], mvalue, Memi[buf], npix)
		else if (mtype == M_GOODBITS) {
		    call aandki (Memi[buf], mvalue, Memi[buf], npix)
		    call abeqki (Memi[buf], 0, Memi[buf], npix)
		} else if (mtype == M_GOODVAL)
		    call abneki (Memi[buf], mvalue, Memi[buf], npix)
		else if (mtype == M_LTVAL)
		    call abgeki (Memi[buf], mvalue, Memi[buf], npix)
		else if (mtype == M_GTVAL)
		    call ableki (Memi[buf], mvalue, Memi[buf], npix)

		lflag[i] = D_NONE
		do j = 1, npix
		    if (Memi[buf+j-1] == 0) {
			lflag[i] = D_MIX
			break
		    }
	    } else {
		if (mtype == M_BOOLEAN || mtype == M_BADBITS) {
		    call aclri (Memi[buf], npix)
		} else if ((mtype == M_BADVAL && mvalue != 0) ||
		    (mtype == M_GOODVAL && mvalue == 0)) {
		    call aclri (Memi[buf], npix)
		} else if (mtype == M_LTVAL && mvalue > 0) {
		    call aclri (Memi[buf], npix)
		} else {
		    call amovki (1, Memi[buf], npix)
		    lflag[i] = D_NONE
		}
	    }
	}

	# Set overall data flag
	dflag = lflag[1]
	do i = 2, nimages  {
	    if (lflag[i] != dflag) {
		dflag = D_MIX
		break
	    }
	}
end


# IC_MGET1 -- Get line of mask pixels from a specified image.
# This is used by the IC_STAT procedure. This procedure  converts the
# stored mask format to an array where zero is good and nonzero is bad.
# The data vector and returned mask array are in the input image pixel system.

procedure ic_mget1 (in, image, nimages, offset, v, m)

pointer	in			# Input image pointer
int	image			# Image index
int	nimages			# Number of images
int	offset			# Column offset
long	v[IM_MAXDIM]		# Data vector desired
pointer	m			# Pointer to mask

int	mtype			# Mask type
int	mvalue			# Mask value
pointer	bufs			# Pointer to data line buffers
pointer	pms			# Pointer to array of PMIO pointers

char	title[1]
int	i, npix
pointer	buf, pm, names, fname, pm_open()
bool	pm_linenotempty()
errchk	pm_glpi, pm_open, pm_loadf, pm_loadim

include	"icombine.com"

begin
	dflag = D_ALL
	if (icm == NULL)
	    return
	if (ICM_TYPE(icm) == M_NONE)
	    return

	mtype = ICM_TYPE(icm)
	mvalue = ICM_VALUE(icm)
	bufs = ICM_BUFS(icm)
	pms = ICM_PMS(icm)
	names = ICM_NAMES(icm)

	npix = IM_LEN(in,1)
	m = Memi[bufs+image-1] + offset
	if (project) {
	    pm =  Memi[pms]
	    fname = Memi[names]
	} else {
	    pm =  Memi[pms+image-1]
	    fname = Memi[names+image-1]
	}

	if (fname == NULL)
	    return
	if (Memc[fname] == EOS)
	    return

	if (pm == NULL) {
	    pm = pm_open (NULL)
	    iferr (call pm_loadf (pm, Memc[fname], title, 1))
		call pm_loadim (pm, Memc[fname], title, 1)
	    call pm_seti (pm, P_REFIM, in)
	    if (project)
		Memi[pms] = pm
	    else
		Memi[pms+image-1] = pm
	}

	# Do mask I/O and convert to appropriate values in order of
	# expected usage.

	buf = m
	if (pm_linenotempty (pm, v)) {
	    call pm_glpi (pm, v, Memi[buf], 32, npix, 0)

	    if (mtype == M_BOOLEAN)
		;
	    else if (mtype == M_BADBITS)
		call aandki (Memi[buf], mvalue, Memi[buf], npix)
	    else if (mtype == M_BADVAL)
		call abeqki (Memi[buf], mvalue, Memi[buf], npix)
	    else if (mtype == M_GOODBITS) {
		call aandki (Memi[buf], mvalue, Memi[buf], npix)
		call abeqki (Memi[buf], 0, Memi[buf], npix)
	    } else if (mtype == M_GOODVAL)
		call abneki (Memi[buf], mvalue, Memi[buf], npix)
	    else if (mtype == M_LTVAL)
		call abgeki (Memi[buf], mvalue, Memi[buf], npix)
	    else if (mtype == M_GTVAL)
		call ableki (Memi[buf], mvalue, Memi[buf], npix)

	    dflag = D_NONE
	    do i = 1, npix
		if (Memi[buf+i-1] == 0) {
		    dflag = D_MIX
		    break
		}
	} else {
	    if (mtype == M_BOOLEAN || mtype == M_BADBITS) {
		;
	    } else if ((mtype == M_BADVAL && mvalue != 0) ||
		(mtype == M_GOODVAL && mvalue == 0)) {
		;
	    } else if (mtype == M_LTVAL && mvalue > 0) {
		;
	    } else
		dflag = D_NONE
	}
end


# IC_MCLOSE1 -- Close mask by index.

procedure ic_mclose1 (image, nimages)

int	image			# Image index
int	nimages			# Number of images

pointer	pms, names, pm, fname
include	"icombine.com"

begin
	if (icm == NULL)
	    return

	pms = ICM_PMS(icm)
	names = ICM_NAMES(icm)

	if (project) {
	    pm =  Memi[pms]
	    fname = Memi[names]
	} else {
	    pm =  Memi[pms+image-1]
	    fname = Memi[names+image-1]
	}

	if (fname == NULL || pm == NULL)
	    return
	if (Memc[fname] == EOS || pm == NULL)
	    return

	call pm_close (pm)
	if (project)
	    Memi[pms] = NULL
	else
	    Memi[pms+image-1] = NULL
end
