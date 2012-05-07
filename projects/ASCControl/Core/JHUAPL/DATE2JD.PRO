;-------------------------------------------------------------
;+
; NAME:
;       DATE2JD
; PURPOSE:
;       Convert a date string to Julian Day number.
; CATEGORY:
; CALLING SEQUENCE:
;       jd = date2jd(date)
; INPUTS:
;       date = date string.                in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       jd = Returned Julian Day number.   out
; COMMON BLOCKS:
; NOTES:
;       Note: date must contain month as a name of 3 or more leeters.
; MODIFICATION HISTORY:
;       R. Sterner, 1996 Sep 15
;
; Copyright (C) 1996, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function date2jd, date, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Convert a date string to Julian Day number.'
	  print,' jd = date2jd(date)'
	  print,'   date = date string.                in'
	  print,'   jd = Returned Julian Day number.   out'
	  print,' Note: date must contain month as a name of 3 or more leeters.'
	  return,''
	endif
 
	date2ymd,date,y,m,d
	if y lt 50 then y=y+2000	
	if y lt 100 then y=y+1900
 
	return, ymd2jd(y,m,d)
	end
