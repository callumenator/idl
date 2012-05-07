	PRO oplotgappy,x,y, xmin = xmin, xmax = xmax, ymin = ymin,$
		       ymax = ymax, linestyle = linestyle
;+
; NAME:			OPLOTGAPPY
;
; PURPOSE:
; a procedure to oplot the sections of the x,y arrays that contain values
;  that are less than ymax and or xmax
;
; CATEGORY:		plotting
;
; CALLING SEQUENCE:	OPLOTGAPPY,x,y,xmin=xmin,xmax=xmax,ymin=ymin,ymax=ymax
;
; INPUTS:
;			x,y	= the x and y data arrays to be plotted
;		KEYWORDS:
;			xmin	= x values smaller than this signify bad data
;			xmax	= x values larger than this signify bad data
;			ymin	= y values smaller than this signify bad data
;			ymax	= y values larger than this signify bad data
;			symsize	= size of symbols to use
;
; OUTPUTS:
;	data is over-plotted
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Damian Murphy (djm) 5/8/89,
;		Physics Dept., University of Adelaide
;
;  Modified Aug. 1991 Trevor Harris, to treat non-finite values as bad points
;  Modified Jan. 1992 Trevor Harris, pass some oplot parameters through
;  Modified Feb. 1993 Trevor Harris, allow x gaps as well as y
;  Modified Sep. 1994 Brenton Vandepeer, allow minimum x and y limits
;-

  num = n_elements(x)
;
; If user only passes in one array then it is treated as an array of
; y-values. Therefore assign the x values to the y array and generate
; indices for the x array.
;
  if n_elements(y) eq 0 then $
     begin
       yy = x
       xx = indgen(num)
     endif else $
     begin
       xx = x
       yy = y
     endelse
  if (not keyword_set(linestyle)) $
     then $
       linestyle = 0
  if (not keyword_set(xmin)) $
     then $
       xmin = min(xx)-10
  if (not keyword_set(xmax)) $
     then $
       xmax = max(xx)+10
  if (not keyword_set(ymin)) $
     then $
       ymin = min(yy)-10
  if (not keyword_set(ymax)) $
     then $
       ymax = max(yy)+10
;
; The next line yields boolean values of one (bad data points)
; or zero (good data points)
;
  bad_points = (xx lt xmin) or (xx gt xmax) or (yy lt ymin) or (yy gt ymax) or $
		not(finite(xx)) or not(finite(yy))
;
  index = indgen(num-1)
;
; Find the array indices of the up and down steps
;
  up_gradient = where(bad_points(index) lt bad_points(index+1),count)
  if (count eq 0) then up_gradient = [num-1]
  down_gradient = where(bad_points(index) gt bad_points(index+1),count) + 1
  if (count eq 0) then down_gradient = [0]
;
; If the points are valid, put the index of the first element (0) into the
; down_gradient array, and the index of the last element (num-1) into the
; up_gradient array.
;
  if (xx(0) le xmax) and (xx(0) ge xmin) and (yy(0) le ymax) and $
     (yy(0) ge ymin) and finite(xx(0)) and finite(yy(0)) $
     then $
       down_gradient = [0,down_gradient]
  if (xx(num-1) le xmax) and (xx(num-1) ge xmin) and (yy(num-1) le ymax) and $
     (yy(num-1) ge ymin) and finite(xx(num-1)) and finite(yy(num-1)) $
     then $
       up_gradient = [up_gradient,(num-1)]
;
; Plot the data going from each down_gradient(i) to the
; corresponding up_gradient(i)
;
  for i = 0,n_elements(down_gradient)-1 do $
    if (up_gradient(i)-down_gradient(i)) ge 1 then $
      oplot,xx(down_gradient(i):up_gradient(i)),$
	    yy(down_gradient(i):up_gradient(i)),linestyle=linestyle
  return
end


