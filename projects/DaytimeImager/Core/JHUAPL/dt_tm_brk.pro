;-------------------------------------------------------------
;+
; NAME:
;       DT_TM_BRK
; PURPOSE:
;       Break a date and time string into separate date and time.
; CATEGORY:
; CALLING SEQUENCE:
;       dt_tm_brk, txt, date, time
; INPUTS:
;       txt = Input date and time string.               in
;         May be an array.
; KEYWORD PARAMETERS:
; OUTPUTS:
;       date = returned date string, null if no date.   out
;       time = returned time string, null if no time.   out
; COMMON BLOCKS:
; NOTES:
;       Note: works for systime: dt_tm_brk, systime(), dt, tm
;         The word NOW (case insensitive) is replaced
;         by the current sysem time.
; MODIFICATION HISTORY:
;       R. Sterner. 21 Nov, 1988.
;       RES 18 Sep, 1989 --- converted to SUN.
;       R. Sterner, 26 Feb, 1991 --- renamed from brk_date_time.pro
;       R. Sterner, 26 Feb, 1991 --- renamed from brk_dt_tm.pro
;       R. Sterner, 1994 Mar 29 --- Allowed arrays.
;
; Copyright (C) 1988, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	pro dt_tm_brk, txt, dt, tm, help=hlp
 
	if (n_params(0) lt 3) or keyword_set(hlp) then begin
	  print,' Break a date and time string into separate date and time.'
	  print,' dt_tm_brk, txt, date, time
	  print,'   txt = Input date and time string.               in'
	  print,'     May be an array.'
	  print,'   date = returned date string, null if no date.   out'
	  print,'   time = returned time string, null if no time.   out'
	  print,' Note: works for systime: dt_tm_brk, systime(), dt, tm'
	  print,'   The word NOW (case insensitive) is replaced'
	  print,'   by the current sysem time.'
	  return
	endif
 
	n = n_elements(txt)
 
	dt = strarr(n)
	tm = strarr(n)
 
	for j = 0, n-1 do begin
	  tt = strupcase(txt(j))
	  if tt eq 'NOW' then tt = systime()
	  if tt ne '' then begin
	    flag = 0		; Items not found yet.
	    for i = 0, nwrds(tt)-1 do begin
	      if flag eq 0 then begin
	        tim = getwrd(tt, i)
	        if strpos(tim,':') gt -1 then begin
	          dat = strtrim(stress(tt, 'D', 1, tim),2)
	          tm(j) = tim
	    	  dt(j) = dat
		  flag = 1	; Found items.
	        endif
	      endif  ; flag
	    endfor  ; i
	    if flag eq 0 then dt(j) = tt
	  endif
	endfor  ; j
 
	if n eq 1 then begin	; Return scalars if given a scalar.
	  tm = tm(0)
	  dt = dt(0)
	endif
 
	return
 
	end
