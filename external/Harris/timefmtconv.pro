;-----------------------------------------------------------------
	function timefmtconv,ydhms
;+
; NAME:			timefmtconv
;
; PURPOSE:
;	this subroutine converts from the time format of YDHMS to DMYHMS 
;
; CATEGORY:		Utility
;
; CALLING SEQUENCE:	dmyhms = timefmtconv(ydhms)
;
; INPUTS:
;	ydhms  = array of ( yr, day_of_yr, hour, min, sec )
;		 yr is year in modulo 100
;		 day_of_yr may extend beyond 365
;
; OUTPUTS:
;	dmyhms  = array of ( day, month, year, hour, min, sec ) 
;		year is in modulo 100
;		 will return -1 if the input format is invalid
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: T.J.H.  17/11/88, Physics Dept., University of Adelaide
;	
;	MODIFIED so that if the doy is greater than the number of days
;	in the year then the year will be incremented
;	T.J.H.  23/10/89 
;
;-

;	this subroutine converts from the time format of YDHMS to DMYHMS 
;	T.J.H   17/11/88

;	modified so that if the doy is greater than the number of days
;	in the year then the year will be incremented
;	T.J.H.  23/10/89
		
	sz = size(ydhms)
	if sz(0) lt 2 then return,[0,0,0,0,0,0]

	year = ydhms(0,*)
	day  = ydhms(1,*)
	sz = size(reform(year))
	dmyhms = replicate(0,6,sz(1))

	daymonth,year,day,month,dayofmth,ndays,mthnum,year=yr
	dmyhms(0,*) = dayofmth
	dmyhms(1,*) = mthnum
	dmyhms(2,*) = yr 
	dmyhms(3,*) = ydhms(2,*) 
	dmyhms(4,*) = ydhms(3,*) 
	dmyhms(5,*) = ydhms(4,*)
	
	return,dmyhms
	
   	end
 

