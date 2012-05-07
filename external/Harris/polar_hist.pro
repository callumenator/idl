;-----------------------------------------------------------------
	function polar_hist, rarray,aarray, number, $
		rbinsize=rbinsize,abinsize=abinsize,rmax=rmax,rmin=rmin
;+
; NAME:
;	POLAR_HIST
;
; PURPOSE:
;	produces a 2D histogram from polar data
;
; CATEGORY:
;	mathematical functions
;
; CALLING SEQUENCE:
;	histo_array = POLAR_HIST (rarray,aarray,number, $
;	rbinsize=rbinsize,abinsize=abinsize,rmax=rmax,rmin=rmin)
;
; INPUTS:
;	RARRAY,AARRAY = the radial and angle (degrees) data to be histogrammed.
;		These define points on the cartesian plane, so should be 
;		of the same length.
;		Angle in range 0.-360. degrees
;	NUMBER = the number of elements per side for the output xy image,
;		defaults to (20*RMAX/RBINSIZE)
;
;   KEYWORD PARAMETERS:
;	RBINSIZE = the size of the bin used for the radial data
;				defaults to 1
;	RMAX = maximum radial value considered for the histogram
;			defaults to the maximum value in the data
;	RMIN = minimum radial value considered for the histogram
;			defaults to the minimum value in the data
;	ABINSIZE = the size of the bin used for the angle data
;				defaults to 1 degree increments
;
; OUTPUTS:
;	The histogram of the data,
;	dimensions are (number,number)
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	produces output array
;
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1991.
;
;-

	if (not keyword_set(rmax)) then rmax=max(rarray)
	if (not keyword_set(rmin)) then rmin=min(rarray)
	if (not keyword_set(rbinsize)) then rbinsize = 1
	if (not keyword_set(abinsize)) then abinsize = 1
	if (n_elements(number) le 0) then number = rnd((20.*rmax)/rbinsize,/up)

	;produce radial and angle arrays for selecting subsets
	rad = dist2(number)*rmax
	ang = dist2(number,/ang)
	hist = replicate(0L,number,number)

	rsubset = where((rarray le rmax)and(rarray ge rmin),count)
	if (count gt 0) then begin
		r = rarray(rsubset)
		a = aarray(rsubset)
	endif else begin
		print
		print,'% POLAR_HIST: ... no data found within amplitude range'
		print
		return,[[0,0],[0,0]]
	endelse	

	r = (r-rmin)/float(rbinsize)
	count = 1
	while (count gt 0) do begin
		tmp  = where( a lt 0.,count)
		if (count gt 0) then a(tmp) = a(tmp) + 360.
	endwhile
	a = a mod 360.
	a = a/float(abinsize) > 0.
	rad = (rad-rmin)/float(rbinsize) 
	ang = ang/float(abinsize) > 0.

	numr = rnd(max(r),/up) + 1
	numa = rnd(360./float(abinsize),/up)
	
	;move first half angle bin to end to join up with last half angle bin
	inbin = where(a lt 0.5,count)	
	if (count gt 0) then a(inbin) = a(inbin) + numa 
	inbin = where(ang lt 0.5,count)	
	if (count gt 0) then ang(inbin) = ang(inbin) + numa

	;produce histogram

	for rstep = 0,numr-1 do begin
	    for astep = 0.5,numa-0.5 do begin
		tmp = where((r ge rstep)and(r lt rstep+1),num_dr)
		if (num_dr gt 0) then tmp = where((a(tmp) ge astep)and(a(tmp) lt astep+1),num_drda) else num_drda = 0
		;if (num_drda gt 0) then print,rstep,astep,num_dr,num_drda
		tmp = where((rad ge rstep)and(rad lt rstep+1),count)
		if (count gt 0) then begin
			inbin = where((ang(tmp) ge astep)and(ang(tmp) lt astep+1),count) 
			if (count gt 0) then hist(tmp(inbin)) = num_drda
		endif
	    endfor
	endfor

	return, hist
	end

