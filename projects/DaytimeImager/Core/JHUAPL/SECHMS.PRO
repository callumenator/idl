;-------------------------------------------------------------
;+
; NAME:
;       SECHMS
; PURPOSE:
;       Seconds after midnight to h, m, s, numbers and strings.
; CATEGORY:
; CALLING SEQUENCE:
;       sechms, sec, h, [m, s, sh, sm, ss]
; INPUTS:
;       sec = seconds after midnight.            in
; KEYWORD PARAMETERS:
; OUTPUTS:
;       h, m, s = Hrs, Min, Sec as numbers.      out
;       sh, sm, ss = Hrs, Min, Sec as strings    out
;             (with leading 0s where needed).
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       Written by R. Sterner, 17 Nov, 1988.
;       Johns Hopkins University Applied Physics Laboratory.
;       R. Sterner, 27 Sep, 1993 --- modified to handle arrays.
;
; Copyright (C) 1988, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	pro sechms, sec, h, m, s, sh, sm, ss, help=hlp
 
	if (keyword_set(hlp)) or (n_params(0) LT 2) then begin
	  print,' Seconds after midnight to h, m, s, numbers and strings.'
	  print,' sechms, sec, h, [m, s, sh, sm, ss]
	  print,'   sec = seconds after midnight.            in
	  print,'   h, m, s = Hrs, Min, Sec as numbers.      out
	  print,'   sh, sm, ss = Hrs, Min, Sec as strings    out
	  print,'         (with leading 0s where needed).
	  return
	endif
 
	t = sec
	h = long(t/3600)
	t = t - 3600*h
	m = long(t/60)
	t = t - 60*m
	s = t
 
	sh = string(h,form='(i2.2)')
	sm = string(m,form='(i2.2)')
	ss = string(s,form='(i2.2)')
 
	return
 
	end
