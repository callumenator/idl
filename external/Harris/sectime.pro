;-----------------------------------------------------------------
		function sectime,numsec
;+
; NAME:		sectime
;
; PURPOSE:
;	this function gives the date in the format dmyhms given
;	the time in seconds from 1/1/1965,
;	uses the routine sectim then converts the time format 
;	from ydhms to dmyhms
;
; CATEGORY:	Utility
;
; CALLING SEQUENCE:	dmyhms = sectime(numsec)
;
; INPUTS:
;	numsec  = array of number of seconds since 01/01/1965  0000 hr
;
;
; OUTPUTS:
;	dmyhms  = array of ( day, month, year, hour, min, sec ) 
;		year is in modulo 100
;		 will return -1 if the number of seconds is invalid
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: T.J.H  26/08/91, Physics Dept., University of Adelaide,
;		
;-

;	this function gives the date in the format dmyhms given
;	the time in seconds from 1/1/startyr,
;	using the usual routine sectim then converting the time format 
;	from ydhms to dmyhms
;					T.J.H   25/02/89
;
;	MODIFIED:to run under IDL from the original fortran77 code
;					T.J.H  26/08/91
		
	ydhms = sectim(numsec)

	return,timefmtconv (ydhms)
   	end
 

