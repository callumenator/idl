;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; bump_time - increment start time by a specified amount of
;             seconds
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified:  1-Mar-2001

pro bump_time, delta

@euv_imtool-commons

; first, calculate the Julian day
jdtemp = calc_jd(start_year,start_doy,start_hour,start_minute,0, 0) + 2400000.0

; then add the delta
jdtemp = jdtemp + double(delta) / double(86400.0)

; convert back to year, day of year, hour and minute
caldat, jdtemp, month, day, year, h, m, s

start_year   = year
start_doy    = doy(year, month, day)
start_hour   = h
start_minute = m

end
