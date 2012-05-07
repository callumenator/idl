;-----------------------------------------------------------------
		function sectim,numsec
;+
; NAME:		sectim
;
; PURPOSE:
;	this function returns the date and time in the format ydhms, given the 
;	elapsed seconds since the start of 1965
;
; CATEGORY:	Utility
;
; CALLING SEQUENCE:	ydhms = sectim(numsec)
;
; INPUTS:
;	numsec  = array of number of seconds since 01/01/1965  0000 hr
;
;
; OUTPUTS:
;	ydhms  = array of ( yr, day_of_yr, hour, min, sec )
;		 yr is year in modulo 100
;		 day_of_yr may extend beyond 365
;		 will return -1 if the number of seconds is invalid
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: T.J.H  26/08/91 Physics Dept., University of Adelaide,
;					
;-
;
;	this function returns the date and time in the format ydhms, given the 
;	elapsed seconds since the start of startyr
;
;	ydhms  = array of ( yr, day, hour, min, sec ) ,yr is year in modulo 100
;	numsec  = array of number of seconds since 01/01/startyr  0000 hr
;
;	ydhms will be -1 if the number of seconds, ntsec, is < 0
;					T.J.H  25/02/89
;
;	MODIFIED:to correct for integer number of days 
;		lost /gained by leap years as opposed to fractional days
;					T.J.H  31/05/89
;
;	MODIFIED:to correct for when the leapyr correction takes the time
;		back one year
;					T.J.H  10/01/90
;
;	MODIFIED:to run under IDL from the original fortran77 code
;					T.J.H  26/08/91

	startyr = 65	
	secindy = 24.*60.*60. &  secinyr = 365.*secindy

	n = n_elements(numsec)
	ydhms = replicate(-1,5,n)
	
	tmp  = where(numsec ge 0,count)
	if (count le 0) then ydhms = -1 else begin
	
		ntsec = numsec(tmp)
		seconds = double(ntsec)
		years   = long(seconds/secinyr)
		seconds = seconds - years*secinyr
		days    = long(seconds/secindy) 
		seconds = seconds - days*secindy
		hours   = long(seconds/3600.)
		seconds = seconds - hours*3600.
		minutes = long(seconds/60.)
		seconds = seconds - minutes*60.
		
		years = years + startyr
		days  = days + 1
		
;...          ..correct the days for number of leap years
		for i=0L,n_elements(years)-1 do begin
			yr = indgen(years(i)-startyr+1)+startyr
			days(i) = days(i) - total([leapyr(yr)])
		
			if (days(i) le 0) then begin
				years(i) = years(i) -1
				days(i)  = 365 + leapyr(years(i)) + days(i)
			endif
		endfor

;...	      ..put into output variable
		ydhms(0,tmp) = years 
		ydhms(1,tmp) = days 
		ydhms(2,tmp) = hours
		ydhms(3,tmp) = minutes
		ydhms(4,tmp) = fix(seconds)
	endelse
	return,ydhms
	end
	

