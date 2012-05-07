;-----------------------------------------------------------------
	function timesec,dmyhms,suppress=suppress
;+
; NAME:		timesec
;
; PURPOSE:
;	this function gives the time in seconds from 1/1/1965 given the date 
;	in the format dmyhms.
;	Reverse function of SECTIME 
;	Uses the routine TIMSEC once the date format has been converted
;
; CATEGORY:	Utility
;
; CALLING SEQUENCE:	numsec = timesec(dmyhms)
;
; INPUTS:
;	dmyhms  = array of ( day, month, year, hour, min, sec ) 
;		year is in modulo 100
;
; OUTPUTS:
;	numsec  = array of number of seconds since 01/01/1965  0000 hr
;		 will return -1 if the number of seconds is invalid
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: T.J.H  17/11/88, Physics Dept., University of Adelaide,
;	
;-

;	this function gives the time in seconds from 1/1/startyr, using the 
;	usual routine timsec after converting the time format 
;	to ydhms from  dmyhms		T.J.H   17/11/88
		
	startyr = 65	
	date = reform(dmyhms)
	sz = size(date)
	if (sz(1) ne 6) then begin 
		print,'% TIMESEC: ... DMYHMS has not got dimensions (6,*)'
		print,'           ... setting number of seconds to -1 '
		return,-1
	endif else if (not keyword_set(suppress)) then print,'% TIMESEC: ... converting DMYHMS to number of seconds :',sz(2),' points'
	ydhms = timfmtconv(date)
	return,timsec(ydhms,/suppress)
   	end
 

