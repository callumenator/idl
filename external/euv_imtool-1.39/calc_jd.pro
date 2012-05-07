
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; calculate the (reduced) julian date from
; year, doy, hour, minute,second and millisecond
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 25-Sep-2002

function calc_jd, year, doy, hour, minute, second, msec

; --------------------------------------------------------------
; load day 0 of the year into an array for the juldate procedure
; --------------------------------------------------------------
tt = intarr(3)
tt[0] = year
tt[1] = 1
tt[2] = 0

; ------------------------------------------------------
; calculate the reduced (- 24000000) Julian date for the
; start of the year in question
; ------------------------------------------------------
juldate,tt,jj

; ---------------------------
; add in the rest of the time
; ---------------------------
rest = double(hour) * 3600.0d0 + double(minute) * 60.0d0 + double(second) + double(msec) / 1000.0d0
jd = jj + double(doy) + rest / 86400.0d0

return,jd

end
