;-------------------------------------------------------------
;+
; NAME:
;       DT_TM_TOJS
; PURPOSE:
;       Convert a date/time string to "Julian Seconds".
; CATEGORY:
; CALLING SEQUENCE:
;       js = dt_tm_tojs( dt)
; INPUTS:
;       dt = date/time string (may be array).   in
;            (see date2ymd for format)
; KEYWORD PARAMETERS:
;       Keywords:
;         ERROR=err  Error flag: 0=ok, else error.
; OUTPUTS:
;       js = "Julian Seconds".                  out
; COMMON BLOCKS:
; NOTES:
;       Notes: Julian seconds (not an official unit) serve the
;         same purpose as Julian Days, interval computations.
;         The zero point is 0:00 1 Jan 2000, so js < 0 before then.
;         Julian Seconds are double precision and have a precision
;         better than 1 millisecond over a span of +/- 1000 years.
;       
;         2 digit years (like 17 or 92), YY, are handled as follows:
;         IF YY < 50 THEN YY = YY + 2000
;         IF YY < 100 THEN YY = YY + 1900
;       
;       See also dt_tm_fromjs, ymds2js, js2ymds, jscheck.
; MODIFICATION HISTORY:
;       R. Sterner, 23 Jul, 1992
;       R. Sterner, 1994 Mar 29 --- Modified to handle arrays.
;
; Copyright (C) 1992, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	function dt_tm_tojs, dt, error=err, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Convert a date/time string to "Julian Seconds".'
	  print,' js = dt_tm_tojs( dt)'
	  print,'   dt = date/time string (may be array).   in'
	  print,'        (see date2ymd for format)'
	  print,'   js = "Julian Seconds".                  out'
	  print,' Keywords:'
	  print,'   ERROR=err  Error flag: 0=ok, else error.'
   	  print,' Notes: Julian seconds (not an official unit) serve the'
   	  print,'   same purpose as Julian Days, interval computations.'
   	  print,'   The zero point is 0:00 1 Jan 2000, so js < 0 before then.'
   	  print,'   Julian Seconds are double precision and have a precision'
   	  print,'   better than 1 millisecond over a span of +/- 1000 years.'
	  print,' '
	  print,'   2 digit years (like 17 or 92), YY, are handled as follows:'
	  print,'   IF YY < 50 THEN YY = YY + 2000'
	  print,'   IF YY < 100 THEN YY = YY + 1900'
	  print,' '
	  print,' See also dt_tm_fromjs, ymds2js, js2ymds, jscheck.'
	  return, -1
	endif
 
	err = 0
        dt_tm_brk, dt, dat, tim		   ; Break into date and time strings.
        date2ymd, dat, yy, mm, dd	   ; Break date into y,m,d.
	w = where(yy lt 0, c)		   ; Find bad dates.
	if c gt 0 then begin
	  print,' Error in dt_tm_tojs: given date not valid or incomplete.'
	  print,'   Problem date(s):'
	  for i=0,c-1 do print,dat(w(i))
	  err = 1
	endif
	w = where(yy lt 50, c)		   ; Fix 2 digit years.
	if c gt 0 then yy(w) = yy(w) + 2000
	w = where(yy lt 100, c)
	if c gt 0 then yy(w) = yy(w) + 1900   
	ss = secstr(tim)		   ; Convert time to seconds.
	js = ymds2js(yy,mm,dd,ss)	   ; Finish conversion.
	return, js
 
	end
