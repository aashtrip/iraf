# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	"imfort.h"

# IMPKWI -- Set the value of the named header keyword as an integer.

procedure impkwi (im, keyw, ival, ier)

size_t	sz_val
pointer	im			# imfort image descriptor
%       character*(*) keyw
int	ival
int	ier

pointer	sp, kp
int	errcode()

begin
	call smark (sp)
	sz_val = SZ_KEYWORD
	call salloc (kp, sz_val, TY_CHAR)

	call f77upk (keyw, Memc[kp], SZ_KEYWORD)
	iferr (call imputi (im, Memc[kp], ival)) {
	    ier = errcode()
	    call im_seterrop (ier, Memc[kp])
	} else {
	    ier = OK
	    IM_UPDATE(im) = YES
	}

	call sfree (sp)
end
