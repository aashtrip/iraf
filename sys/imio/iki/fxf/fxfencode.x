# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.
 
include <time.h>
include "fxf.h"

# FXFENCODE.X -- Routines to encode a keyword, its value and a comment into
# a FITS card.
#
#	fxf_encode_axis (root, keyword, axisno)
#	fxf_encode_date (datestr, szdate)
#
#	    fxf_encodeb (keyword, param, card, comment)
#	    fxf_encodei (keyword, param, card, comment)
#	    fxf_encodel (keyword, param, card, comment)
#	    fxf_encoder (keyword, param, card, comment, precision)
#	    fxf_encoded (keyword, param, card, comment, precision)
#	    fxf_encodec (keyword, param, maxch, card, comment)
#
#	       fxf_akwc (keyword, value, len, comment, pn)
#	       fxf_akwb (keyword, value, comment, pn)
#	       fxf_akwi (keyword, value, comment, pn)
#	       fxf_akwr (keyword, value, comment, precision, pn)
#	       fxf_akwd (keyword, value, comment, precision, pn)
#
# Encode_axis adds an axis number to a keyword ("rootXXX").  Encode_date
# encodes the current date as a string in the form "dd/mm/yy".


# FXF_ENCODEB -- Encode a boolean parameter into a FITS card.

procedure fxf_encodeb (keyword, param, card, comment)

char	keyword[ARB]	# FITS keyword
int	param		# integer parameter equal to YES/NO
char	card[ARB]	# FITS card image
char	comment[ARB]	# FITS comment string

char	truth

begin
	if (param == YES)
	    truth = 'T'
	else
	    truth = 'F'

	call sprintf (card, LEN_CARD, "%-8.8s= %20c / %-47.47s")
	    call pargstr (keyword)
	    call pargc (truth)
	    call pargstr (comment)
end


# FXF_ENCODEI -- Encode an integer parameter into a FITS card.

procedure fxf_encodei (keyword, param, card, comment)

char	keyword[ARB]	# FITS keyword
int	param		# integer parameter
char	card[ARB]	# FITS card image
char	comment[ARB]	# FITS comment string

begin
	call sprintf (card, LEN_CARD, "%-8.8s= %20d / %-47.47s")
	    call pargstr (keyword)
	    call pargi (param)
	    call pargstr (comment)
end


# FXF_ENCODEL -- Encode a long parameter into a FITS card.

procedure fxf_encodel (keyword, param, card, comment)

char	keyword[ARB]		# FITS keyword
long	param			# long integer parameter
char	card[ARB]		# FITS card image
char	comment[ARB]		# FITS comment string

begin
	call sprintf (card, LEN_CARD, "%-8.8s= %20d / %-47.47s")
	    call pargstr (keyword)
	    call pargl (param)
	    call pargstr (comment)
end


# FXF_ENCODER -- Encode a real parameter into a FITS card.

procedure fxf_encoder (keyword, param, card, comment, precision)

char	keyword[ARB]		# FITS keyword
real	param			# real parameter
char	card[ARB]		# FITS card image
char	comment[ARB]		# FITS comment card
int	precision		# precision of real

begin
	call sprintf (card, LEN_CARD, "%-8.8s= %20.*e / %-47.47s")
	    call pargstr (keyword)
	    call pargi (precision)
	    call pargr (param)
	    call pargstr (comment)
end


# FXF_ENCODED -- Encode a double parameter into a FITS card.

procedure fxf_encoded (keyword, param, card, comment, precision)

char	keyword[ARB]		# FITS keyword
double	param			# double parameter
char	card[ARB]		# FITS card image
char	comment[ARB]		# FITS comment string
int	precision		# FITS precision

begin
	call sprintf (card, LEN_CARD, "%-8.8s= %20.*e / %-47.47s")
	    call pargstr (keyword)
	    call pargi (precision)
	    call pargd (param)
	    call pargstr (comment)
end


# FXF_ENCODE_AXIS -- Add the axis number to axis dependent keywords.

procedure fxf_encode_axis (root, keyword, axisno)

char	root[ARB]		# FITS root keyword
char	keyword[ARB]		# FITS keyword
int	axisno			# FITS axis number

begin
	call strcpy (root, keyword, SZ_KEYWORD)
	call sprintf (keyword, SZ_KEYWORD, "%-5.5s%-3.3s")
	    call pargstr (root)
	    call pargi (axisno)
end


# FXF_ENCODEC -- Procedure to encode an IRAF string parameter into a FITS card.

procedure fxf_encodec (keyword, param, maxch, card, comment)

char	keyword[LEN_CARD]	# FITS keyword
char	param[LEN_CARD]		# FITS string parameter
int	maxch			# maximum chars in value string
char	card[LEN_CARD+1]	# FITS card image
char	comment[LEN_CARD]	# comment string

int	nblanks, maxchar, slashp

begin
	maxchar = max(8, min (maxch, LEN_OBJECT))
	slashp = 32 
	nblanks = LEN_CARD - (slashp + 1)
	if (maxchar >= 19) {
	   slashp = 1
	   nblanks = max (LEN_OBJECT - maxchar - slashp+3, 1)
	}

	call sprintf (card, LEN_CARD, "%-8.8s= '%*.*s' %*t/ %*.*s")
	    call pargstr (keyword)
	    call pargi (-maxchar)
	    call pargi (maxchar)
	    call pargstr (param)
	    call pargi (slashp)
	    call pargi (-nblanks)
	    call pargi (nblanks)
	    call pargstr (comment)
end


# FXF_ENCODE_DATE -- Encode the current date in the form dd/mm/yy.
# (Year 2000 values wrap around to 00, 01, etc.).

procedure fxf_encode_date (datestr, szdate)

char	datestr[ARB]		# string containing the date
int	szdate			# number of chars in the date string

long	ctime
int	time[LEN_TMSTRUCT]
long	clktime()

begin
	ctime = clktime (long (0))
	call brktime (ctime, time)

	call sprintf (datestr, szdate, "%02s/%02s/%02s")
	    call pargi (TM_MDAY(time))
	    call pargi (TM_MONTH(time))
	    call pargi (mod (TM_YEAR(time), 100))
end


# FXF_AKWC -- Encode keyword, value and comment into a FITS card and
# append it to a buffer pointed by pn.
 
procedure fxf_akwc (keyword, value, len, comment, pn)

char	keyword[SZ_KEYWORD]	# keyword name
char	value[ARB]		# Keyword value
int	len			# Lenght of value
char	comment[ARB]		# Comment
pointer pn			# Pointer to a char area
char	card[LEN_CARD]

begin
	call fxf_encodec (keyword, value, len, card, comment)
	call amovc (card, Memc[pn], LEN_CARD)
	pn = pn + LEN_CARD
end


# FXF_AKWB -- Encode keyword, value and comment into a FITS card and
# append it to a buffer pointed by pn.
 
procedure fxf_akwb (keyword, value, comment, pn)

char	keyword[SZ_KEYWORD]	# I keyword name
int	value			# I Keyword value (YES, NO)
char	comment[ARB]		# I Comment
pointer pn			# I/O Pointer to a char area

pointer sp, pc

begin
	call smark (sp)
	call salloc (pc, LEN_CARD, TY_CHAR)

	call fxf_encodeb (keyword, value, Memc[pc], comment)
	call amovc (Memc[pc], Memc[pn], LEN_CARD)
	pn = pn + LEN_CARD

	call sfree (sp)
end


# FXF_AKWI -- Encode keyword, value and comment into a FITS card and
# append it to a buffer pointed by pn.
 
procedure fxf_akwi (keyword, value, comment, pn)

char	keyword[SZ_KEYWORD]	# I keyword name
int	value			# I Keyword value 
char	comment[ARB]		# I Comment
pointer pn			# I/O Pointer to a char area

pointer sp, pc

begin
	call smark (sp)
	call salloc (pc, LEN_CARD, TY_CHAR)

	call fxf_encodei (keyword, value, Memc[pc], comment)
	call amovc (Memc[pc], Memc[pn], LEN_CARD)
	pn = pn + LEN_CARD

	call sfree (sp)
end


# FXF_AKWR -- Encode keyword, value and comment into a FITS card and
# append it to a buffer pointed by pn.
 
procedure fxf_akwr (keyword, value, comment, precision, pn)

char	keyword[SZ_KEYWORD]	# I keyword name
real	value			# I Keyword value 
char	comment[ARB]		# I Comment
int	precision
pointer pn			# I/O Pointer to a char area

pointer sp, pc

begin
	call smark (sp)
	call salloc (pc, LEN_CARD, TY_CHAR)

	call fxf_encoder (keyword, value, Memc[pc], comment, precision)
	call amovc (Memc[pc], Memc[pn], LEN_CARD)
	pn = pn + LEN_CARD

	call sfree (sp)
end


# FXF_AKWD -- Encode keyword, value and comment into a FITS card and
# append it to a buffer pointed by pn.
 
procedure fxf_akwd (keyword, value, comment, precision, pn)

char	keyword[SZ_KEYWORD]	# I keyword name
double	value			# I Keyword value 
char	comment[ARB]		# I Comment
int	precision
pointer pn			# I/O Pointer to a char area

pointer sp, pc

begin
	call smark (sp)
	call salloc (pc, LEN_CARD, TY_CHAR)

	call fxf_encoded (keyword, value, Memc[pc], comment, precision)
	call amovc (Memc[pc], Memc[pn], LEN_CARD)
	pn = pn + LEN_CARD

	call sfree (sp)
end