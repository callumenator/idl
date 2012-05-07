;-----------------------------------------------------------------
FUNCTION Timsec, in_ydhms, SUPPRESS=suppress
;+
; NAME:		timsec
;
; PURPOSE:
;	this function returns the elapsed seconds since the start of 1965 
;	given date and time in the format ydhms
;	Reverse function of SECTIM 
;	
;
; CATEGORY:	Utility
;
; CALLING SEQUENCE:	numsec = timsec(ydhms)
;
; INPUTS:
;	ydhms  = array of ( yr, day_of_yr, hour, min, sec )
;		 yr is year in modulo 100
;		 day_of_yr may extend beyond 365
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
;	Mod: T.J.H. 4/8/94, HFRD, DSTO,
;          allowed FOR year being > 99 (ie in full format,  eg 1994) 
;					
;-
  
;	this function returns the elapsed seconds since the start of startyr

;	ydhms  5(i*4) = ( yr, day, hour, min, sec )
;	ntsec   (i*4) = number of seconds since 01/01/startyr  0000 hr
  startyr = 1965

;	ntsec will be returned as -1 if any of the following are true
;		year outside range  1965 - 9999
;		day  outside range   1 - 365+leapyr
;		hour outside range   0 - 23
;		min  outside range   0 - 59
;		sec  outside range   0 - 59

  lims = [[ startyr, 9999], [ 1, 365], [ 0, 23], [ 0, 59], [ 0, 59]]
  
  ydhms = in_ydhms
  
  ;;if the years are modulo 100 then assume 20th century
  mod100 = where(ydhms( 0, * ) LT 100, count) 
  IF count GT 0 THEN ydhms( 0, mod100) = ydhms( 0, mod100) +1900
  
  sz = size(ydhms) 
  IF (sz(1) NE 5) THEN BEGIN 
    print, '% TIMSEC: ... YDHMS has not got dimensions (5,*)'
    print, '          ... setting number of seconds to -1 '
    RETURN, -1
  ENDIF ELSE IF (NOT KEYWORD_SET(suppress) ) THEN $
    print, '% TIMSEC: .... converting YDHMS to number of seconds :', $
    sz(2), ' points'
  
  ranges = reform(ydhms(0, * ) * 0) 

                                ;
                                ;define all the output variables
  n = N_ELEMENTS(ranges) 
  ndays   = long(replicate( -1, n) ) 
  yrs     = long(replicate( -1, n) ) 
  numyrs  = long(replicate( -1, n) ) 
  numdays = long(replicate( -1, n) ) 
  ntsec   = long(replicate( -1, n) ) 
  upperlimit = reform(lims(1, * ) ) #(ranges +1) 
  lowerlimit = reform(lims(0, * ) ) #(ranges +1) 
  upperlimit(1, * ) = upperlimit(1, * ) + leapyr(ydhms(0, * ) ) 
  FOR i = 0L, n -1 DO ranges(i) = $
    min((ydhms( *, i) GE lowerlimit( *, i) ) AND $
        (ydhms( *, i) LE upperlimit( *, i) ) ) 
  in_range = where(ranges EQ 1, in_count) 

  IF (in_count GT 0) THEN BEGIN
    ndays(in_range) = long(ydhms(1, in_range) ) 
    yrs(in_range) = long(ydhms(0, in_range) ) 
    numyrs(in_range) = yrs(in_range) -startyr
    FOR i = 0L, N_ELEMENTS(in_range) -1 DO BEGIN
      allyrs = indgen(yrs(in_range(i) ) -startyr +1) +startyr
      leapdays = total([ leapyr(allyrs) ]) 
    ENDFOR
    numdays(in_range) = 365 * numyrs(in_range) + leapdays + ndays(in_range) 
    ntsec(in_range) = ydhms(4, in_range) +  $
      60 *(ydhms(3, in_range) + $
           60 *(ydhms(2, in_range) + $
                24 *(numdays(in_range) -1) ) ) 
  ENDIF ELSE $
    print, '   .... no data has valid dates, number of seconds set to -1 '

  ntsec = reform(ntsec) 
  RETURN, ntsec
END


