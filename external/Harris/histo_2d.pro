;-----------------------------------------------------------------
FUNCTION Histo_2d, xarray, yarray, $
                   XBINSIZE=xbinsize, YBINSIZE=ybinsize, $
                   XMAX=xmax, XMIN=xmin, YMAX=ymax, YMIN=ymin, $
                   BINSIZE=binsize, BMIN=bmin, BMAX=bmax
;+
; NAME:
;	HISTO_2D
;
; PURPOSE:
;	produces an histogram from arbitrary x,y data
;
; CATEGORY:
;	mathematical functions
;
; CALLING SEQUENCE:
;	histo_array = HISTO_2D (xarray,yarray, $
;				binsize=binsize,bmax=bmax,bmin=bmin)
;
; INPUTS:
;	XARRAY,YARRAY = the x,y data VECTORS to be histogrammed. 
;		These define points on the cartesian plane, so should be 
;		of the same length.
;
;   KEYWORD PARAMETERS:
;	XBINSIZE,YBINSIZE = the size of the bin used for the x,y data
;				defaults to 1
;	XMAX,YMAX = maximum value considered for the histogram
;			defaults to the maximum value in the data
;	XMIN,YMIN = minimum value considered for the histogram
;			defaults to the minimum value in the data
;	BINSIZE = if used then this will be the size of the bin used for both
;		 the x,y data (overridden by the explicit x,y binsize)
;	BMAX = maximum value considered for the histogram used for both
;		 the x,y data (overridden by the explicit x,y max)
;	BMIN = minimum value considered for the histogram used for both
;		 the x,y data (overridden by the explicit x,y min)
;
; OUTPUTS:
;	The histogram of the data,
;	dimensions are ((xmax-xmin)/xbinsize,(ymax-ymin)/ybinsize)
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	produces output array
;
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;	Modified: 29 April, 1994, TJH (HFRD, DSTOS)
;		Fixed problem where if ?min/max set to zero then it was
;		ignored. This occurred because the function KEYWORD_SET was
;		used so that a value of 0 was interpretted as being NOT
;		SET. Now use N_ELEMENT call.
;
;-


  IF (N_ELEMENTS(bmax) GT 0) THEN BEGIN
    IF (N_ELEMENTS(xmax) LE 0) THEN xmax = bmax
    IF (N_ELEMENTS(ymax) LE 0) THEN ymax = bmax
  ENDIF ELSE BEGIN
    IF (N_ELEMENTS(xmax) LE 0) THEN xmax = max(xarray) 
    IF (N_ELEMENTS(ymax) LE 0) THEN ymax = max(yarray) 
  ENDELSE
  
  IF (N_ELEMENTS(bmin) GT 0) THEN BEGIN
    IF (N_ELEMENTS(xmin) LE 0) THEN xmin = bmin
    IF (N_ELEMENTS(ymin) LE 0) THEN ymin = bmin
  ENDIF ELSE BEGIN
    IF (N_ELEMENTS(xmin) LE 0) THEN xmin = min(xarray) 
    IF (N_ELEMENTS(ymin) LE 0) THEN ymin = min(yarray) 
  ENDELSE
  
  IF (KEYWORD_SET(binsize) ) THEN BEGIN
    IF (NOT KEYWORD_SET(xbinsize) ) THEN xbinsize = binsize
    IF (NOT KEYWORD_SET(ybinsize) ) THEN ybinsize = binsize
  ENDIF ELSE BEGIN
    IF (NOT KEYWORD_SET(xbinsize) ) THEN xbinsize = 1
    IF (NOT KEYWORD_SET(ybinsize) ) THEN ybinsize = 1
  ENDELSE

  num_x = fix((xmax -xmin) /xbinsize) 
  num_y = fix((ymax -ymin) /ybinsize) 

  hist = replicate(0, num_x, num_y) 
  hist = long(hist) 

  xsubset = where((xarray LE xmax) AND(xarray GE xmin), count) 
  IF (count GT 0) THEN BEGIN
    x = xarray(xsubset) 
    y = yarray(xsubset) 
  ENDIF
  ysubset = where((y LE ymax) AND(y GE ymin), count) 
  IF (count GT 0) THEN BEGIN
    x = x(ysubset) 
    y = y(ysubset) 
  ENDIF

  x = (x -xmin) /xbinsize - 0.5
  y = (y -ymin) /ybinsize - 0.5


  FOR j = 0, num_y -1 DO BEGIN
    yind = where((y GE j) AND(y LT j +1), count) 

    IF (count GT 0) THEN BEGIN
      tmpx = x(yind) 
      FOR i = 0, num_x -1 DO BEGIN
        xind = where((tmpx GE i) AND(tmpx LT i +1), count) 
        hist(i, j) = count > 0
      ENDFOR
    ENDIF ELSE hist( *, j) = 0
  ENDFOR

  RETURN, hist
END

