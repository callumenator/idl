;------------------------------------------------------------------------------
FUNCTION Xyrebin, oldy, newnumx, newnumy, badpts=badpts, ymax=ymax, $
                  xtickv=xtickv, ytickv=ytickv, nogroup=nogroup
;+
; NAME:		XYREBIN
;
; PURPOSE:	To produce a consistent image format, removing extra pixels and
;		optionally suppressing outliers for a better image
;
; CATEGORY:	Images
;
; CALLING SEQUENCE: 
;		newarray = xyrebin( oldarray, sz1, sz2, badpts=badpts,$
;				xtickv=xtickv, ytickv=ytickv, $
;				ymax=ymax, nogroup=nogroup )
;
; INPUTS:
;	oldarray	=	the array to be rebinned
;
;   OPTIONAL INPUTS:
;	sz1, sz2	=	the sizes for rebinned output. 
;				Defaults to 250x150 which gives a decent image.
;				All sizes are trimmed to be multiples/factors 
;				of the array sizes
;
;	badpts		=	indices of bad data points
;	
;	ymax		=	values above ymax must be bad data
;
;	nogroup		=	DONT trim the extrema points
;
;	xtickv,ytickv	=	input x and y tick values, which are scaled 
;				according to the rebinning and output.
;
; OUTPUTS:
;	newarray	=	the rebinned array
;
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;       23-May-1994 T Harris, IE Group, HFRD, DSTO. 
;		Modified to use TH_NEAREST
;
;-

  y = reform(oldy)

  IF (N_ELEMENTS(newnumx) LE 0) THEN BEGIN
    newnumx = 250
    newnumy = 150
  ENDIF ELSE IF (N_ELEMENTS(newnumy) LE 0) THEN newnumy = newnumx
  IF (NOT KEYWORD_SET(ymax)) THEN ymax = max(abs(y))+10
  ymax = abs(ymax)
  tmp = where(abs(y) LT ymax)
  maxy = max(abs(y(tmp)))

  sz = size(y)
  num_x = sz(1)
  num_y = sz(2)
  
  nx = th_nearest(newnumx, num_x)
  ny = th_nearest(newnumy, num_y)
  xfactor = (nx/num_x - 1 ) > 0
  yfactor = (ny/num_y - 1 ) > 0

                                ;set bad data points to a very large number
  badpts = where(abs(y) GT maxy, count)
  IF (count GT 0) THEN y(badpts) = 100000.*maxy
  goodpts = where(abs(y) LE maxy, count)
  IF (count LE 0) THEN maxyy = max(y, min = minyy) $
  ELSE maxyy = max(y(goodpts), min = minyy)
  limits = [minyy, maxyy]

  IF (NOT KEYWORD_SET(nogroup)) THEN BEGIN
                                ;find the outliers and bring them in 
                                ; - for a better looking image
    IF (count GT 0) THEN BEGIN
      limits = decile(y(goodpts), [2.0, 98.0])
      y(goodpts) = (y(goodpts) > limits(0)) < limits(1)
    ENDIF
  ENDIF

                                ;now rebin to improve the image resolution
  y = rebin(y, nx, ny)

                                ; but keep track of the original bad points
  badpts = where(abs(y) GT maxy, count)
  IF (count GT 0) THEN y(badpts) = 100000.*maxy

                                ;smooth if we can
  IF (nx LT 3) OR (ny LT 3) THEN newy = y ELSE newy = smooth(y, 3)

                                ; but keep track of the original bad points
  badpts = where(abs(newy) GT maxy, count)
  IF (count GT 0) THEN newy(badpts) = y(badpts)

                                ;trim off the edge left by rebin
  newy = newy(0:nx-xfactor-1, 0:ny-yfactor-1)
  
                                ; set the bad points to be a value just less
                                ; than the minimum, for a better image
  badpts = where(abs(newy) GT maxy, count)
  IF (count GT 0) THEN $
    newy(badpts) = limits(0)-abs(limits(1)-limits(0))*0.1

  IF (KEYWORD_SET(xtickv)) THEN BEGIN
    maxxtv = max(xtickv, min = minxtv)
    xtickv = (xtickv-minxtv)/(maxxtv-minxtv) * (nx-xfactor-1)
  ENDIF
  IF (KEYWORD_SET(ytickv)) THEN BEGIN
    maxytv = max(ytickv, min = minytv)
    ytickv = (ytickv-minytv)/(maxytv-minytv) * (ny-yfactor-1)
  ENDIF

  RETURN, newy
END


