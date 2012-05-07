
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; calculate the (reduced) julian date from a
; btime/etime structure
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 25-Sep-2002

function load_jdate, btime

; --------------------------------------------------------------
; load day 0 of the year into an array for the juldate procedure
; --------------------------------------------------------------
tt = intarr(3)
tt[0] = btime.year
tt[1] = 1
tt[2] = 0

; ------------------------------------------------------
; calculate the reduced (- 2400000) Julian date for the
; start of the year in question
; ------------------------------------------------------
juldate,tt,jj

; ---------------------------
; add in the rest of the time
; ---------------------------
rest = double(btime.hour) * 3600.0d0 + double(btime.min) * 60.0d0 + double(btime.sec)
jd = jj + double(btime.doy) + rest / 86400.0d0

return,jd

end
