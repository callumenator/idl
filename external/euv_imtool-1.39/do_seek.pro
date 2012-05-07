
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; seek ahead to find next period when the voltage
; is up (using total counts in skymap 0)
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 28-Aug-2001


pro do_seek

@euv_imtool-commons

clower = 10
; -------------------------------------
; set start and stop times for udf_open
; -------------------------------------
syear = fix(start_year)
sdoy  = fix(start_doy)
shour = fix(start_hour)
smin  = fix(start_minute)

eyear = syear
edoy  = sdoy + 5
ehour = 23
emin  = 59
ndays = 365
if ((eyear mod 4) eq 0) then ndays = 366
if (edoy gt ndays) then begin
    edoy = edoy - ndays
    eyear = eyear + 1
endif

; ----------------------------------------------
; open the skymap 0 UDF file at the current time
; ----------------------------------------------
if (quicklook) then ks0 = udf_key(vinstquick('IMES0IMG')) else $
  ks0 = udf_key(vinst('IMES0IMG'))
fh0 = udf_open(ks0,[syear,sdoy,shour,smin],[eyear,edoy,ehour,emin])

; --------------------------------------------------------------
; search forward until total counts are greater than lower limit
; clower
; --------------------------------------------------------------
done = 0
while (not udf_eof(fh0) and (not done)) do begin
    s0 = udf_read(fh0)
    if (TOTAL(s0.skymap_sensor_0[*,*]) gt clower) then done = 1
endwhile

; ---------------------------------------------
; load the time into the common block variables
; ---------------------------------------------
start_year   = s0.btime.year
start_doy    = s0.btime.doy
start_hour   = s0.btime.hour
start_minute = s0.btime.min

udf_close,fh0


end
