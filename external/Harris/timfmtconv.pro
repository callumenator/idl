;-----------------------------------------------------------------
	function timfmtconv,dmyhms
;+
; NAME:			timfmtconv
;
; PURPOSE:
;	this subroutine converts from the time format of DMYHMS to YDHMS  
;
; CATEGORY:		Utility
;
; CALLING SEQUENCE:	ydhms = timfmtconv(dmyhms)
;
; INPUTS:
;	dmyhms  = array of ( day, month, year, hour, min, sec ) 
;		year is in modulo 100
;
; OUTPUTS:
;	ydhms  = array of ( yr, day_of_yr, hour, min, sec )
;		 yr is year in modulo 100
;		 day_of_yr may extend beyond 365
;		 will return -1 if the input format is invalid
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: T.J.H. 17/11/88, Physics Dept., University of Adelaide,
;
;-

;	this subroutine converts from the time format of DMYHMS to YDHMS 
;	T.J.H   17/11/88
		
	mth = dmyhms(1,*)
	year = dmyhms(2,*)
	sz = size(reform(year))
	ydhms = replicate(0,5,sz(1))
	mthnumday,mth,year,stday,ndays,month
	ydhms(0,*) = dmyhms(2,*)
	ydhms(1,*) = dmyhms(0,*) + stday - 1
	ydhms(2,*) = dmyhms(3,*)
	ydhms(3,*) = dmyhms(4,*)
	ydhms(4,*) = dmyhms(5,*)
	
	return,ydhms
	
   	end
 

