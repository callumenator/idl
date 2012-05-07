;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; load_udf_data - load a skymap and associated orbit information
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 14-Aug-2003 (4-pixel overlap version)

pro load_udf_data, quick=quick

@euv_imtool-commons

;;CATCH, error_status
error_status=0

syear = fix(start_year)
sdoy  = fix(start_doy)
shour = fix(start_hour)
smin  = fix(start_minute)
ssec  = fix(start_second)

; ------------------
; get UDF keys
; ------------------
if keyword_set(quick) then begin
    ks0 = udf_key(vinstquick('IMES0IMG'))
    ks1 = udf_key(vinstquick('IMES1IMG'))
    ks2 = udf_key(vinstquick('IMES2IMG'))
    korb = udf_key(vinstquick('IMOORBIT'))
endif else begin
    ks0 = udf_key(vinst('IMES0IMG'))
    ks1 = udf_key(vinst('IMES1IMG'))
    ks2 = udf_key(vinst('IMES2IMG'))
    korb = udf_key(vinst('IMOORBIT'))
endelse

; ---------------------------------------------------
; figure out a suitable ending time (end of next day)
; so that we can browse across day boundaries
; ---------------------------------------------------
eyear = syear
edoy  = sdoy + 1
ehour = 23
emin  = 59
ndays = 365
if ((eyear mod 4) eq 0) then ndays = 366
if (edoy gt ndays) then begin
    edoy = edoy - ndays
    eyear = eyear + 1
endif

; ------------------------------
; open the EUV skymap data files
; ------------------------------
if(dlmflag eq 1) then begin
    fh0  = udf_open(ks0,[syear, sdoy, shour, smin, ssec],[eyear, edoy, ehour, emin])
endif else begin
    fh0  = udf_open(ks0,[syear, sdoy, shour, smin, ssec],[eyear, edoy, ehour, emin],baseunit=1)
endelse
if error_status ne 0 then begin
    display_status, "Error opening UDF data file for SKYMAP 0!"
    return
endif

if(dlmflag eq 1) then begin
    fh1  = udf_open(ks1,[syear, sdoy, shour, smin, ssec],[eyear, edoy, ehour, emin])
endif else begin
    fh1  = udf_open(ks1,[syear, sdoy, shour, smin, ssec],[eyear, edoy, ehour, emin],baseunit=1)
endelse
if error_status ne 0 then begin
    display_status, "Error opening UDF data file for SKYMAP 1!"
    udf_close, fh0
    return
endif

if(dlmflag eq 1) then begin
    fh2  = udf_open(ks2,[syear, sdoy, shour, smin, ssec],[eyear, edoy, ehour, emin])
endif else begin
    fh2  = udf_open(ks2,[syear, sdoy, shour, smin, ssec],[eyear, edoy, ehour, emin],baseunit=1)
endelse
if error_status ne 0 then begin
    display_status, "Error opening UDF data file for SKYMAP 2!"
    return
    udf_close, fh0
    udf_close, fh1
endif

; --------------------------------------------
; back up a bit for the orbit data and open it
; --------------------------------------------
jdtemp = calc_jd(syear, sdoy, shour, smin, ssec, 0) + 2400000.0d0
jdtemp = jdtemp - (15.0/1440.0) ; back up 15 minute
caldat, jdtemp, new_month, new_day, new_year, new_hour, new_minute, new_second
syear = fix(new_year)
sdoy = fix(doy(new_year, new_month, new_day))
shour = fix(new_hour)
smin = fix(new_minute)
ssec = fix(new_second)

if(dlmflag eq 1) then begin
    forb = udf_open(korb,[syear, sdoy, shour, smin],[eyear, edoy, ehour, emin])
endif else begin
    forb = udf_open(korb,[syear, sdoy, shour, smin],[eyear, edoy, ehour, emin],baseunit=1)
endelse
if error_status ne 0 then begin
    display_status, "Error opening UDF data file for IMAGE orbit!"
    return
    udf_close, fh0
    udf_close, fh1
    udf_close, fh2
endif

; -----------------------
; read in the skymap data
; -----------------------
nadd1 = 0
nadd2 = 0
if ( not udf_eof(fh0)) then s0 = udf_read(fh0)
if(s0.nadir_count[0] eq 65534.0) then nadd2 = 65536
if(s0.nadir_count[0] eq 65535.0) then begin
    nadd1 = 65536
    nadd2 = 65537
endif

if ( not udf_eof(fh1)) then s1 = udf_read(fh1)
while ( (s1.nadir_count[0] + nadd1) lt (s0.nadir_count[0] +1)) do begin
    if ( not udf_eof(fh1)) then s1 = udf_read(fh1)
endwhile

if ( not udf_eof(fh2)) then s2 = udf_read(fh2)
while ( (s2.nadir_count[0] + nadd2) lt (s0.nadir_count[0] +2)) do begin
    if ( not udf_eof(fh2)) then s2 = udf_read(fh2)
endwhile

jd0 = load_jdate(s0.btime)

; -----------------------------
; check for missing skymap data
; -----------------------------
n0 = s0.nadir_count[0]
n1 = s1.nadir_count[0] + nadd1
n2 = s2.nadir_count[0] + nadd2

least = n0 < n1 < n2

if (least eq n0) then begin
    mask = 1
    if ( n1 eq (n0+1)) then mask = mask + 2
    if ( n2 eq (n0+2)) then mask = mask + 4
endif else if (least eq n1) then begin
    mask = 2
    if ( n2 eq (n1+1)) then mask = mask + 4
endif else begin
    mask = 4
endelse

; set midpoint time
calc_midpoint,s0,s1,s2,mask

; get spin pole
get_spin_pole,s0,s1,s2,mask

; get tau (number of spins in the integration)
get_tau,s0,s1,s2,mask

s0year = s0.btime.year
s0doy  = s0.btime.doy
s0hour  = s0.btime.hour
s0min  = s0.btime.min
s0sec = s0.btime.sec

start_year   = s0year
start_doy    = s0doy
start_hour   = s0hour
start_minute = s0min
start_second = s0sec

; -----------------------
; read in the orbit data
; -----------------------
if ( not udf_eof(forb)) then orb1 = udf_read(forb)
jorb1 = load_jdate(orb1.btime)
orb2 = orb1

; find bracketing records
while ( load_jdate(orb2.btime) le jd) do begin
    orb1 = orb2
    if ( not udf_eof(forb)) then orb2 = udf_read(forb)
endwhile

jorb1 = load_jdate(orb1.btime)
jorb2 = load_jdate(orb2.btime)

; time-interpolate the required orbit data
orb = orb2       ; just to create a structure of the same type, unused
                                ; parameters will not be interpolated
orb.gci_satellite_pos__x = interpol([orb1.gci_satellite_pos__x,orb2.gci_satellite_pos__x],$
                                    [jorb1,jorb2],jd)
orb.gci_satellite_pos__y = interpol([orb1.gci_satellite_pos__y,orb2.gci_satellite_pos__y],$
                                    [jorb1,jorb2],jd)
orb.gci_satellite_pos__z = interpol([orb1.gci_satellite_pos__z,orb2.gci_satellite_pos__z],$
                                    [jorb1,jorb2],jd)
orb.gci_satellite_vel__x = interpol([orb1.gci_satellite_vel__x,orb2.gci_satellite_vel__x],$
                                    [jorb1,jorb2],jd)
orb.gci_satellite_vel__y = interpol([orb1.gci_satellite_vel__y,orb2.gci_satellite_vel__y],$
                                    [jorb1,jorb2],jd)
orb.gci_satellite_vel__z = interpol([orb1.gci_satellite_vel__z,orb2.gci_satellite_vel__z],$
                                    [jorb1,jorb2],jd)
orb.gsm_satellite_pos__x = interpol([orb1.gsm_satellite_pos__x,orb2.gsm_satellite_pos__x],$
                                    [jorb1,jorb2],jd)
orb.gsm_satellite_pos__y = interpol([orb1.gsm_satellite_pos__y,orb2.gsm_satellite_pos__y],$
                                    [jorb1,jorb2],jd)
orb.gsm_satellite_pos__z = interpol([orb1.gsm_satellite_pos__z,orb2.gsm_satellite_pos__z],$
                                    [jorb1,jorb2],jd)
orb.gsm_satellite_vel__x = interpol([orb1.gsm_satellite_vel__x,orb2.gsm_satellite_vel__x],$
                                    [jorb1,jorb2],jd)
orb.gsm_satellite_vel__y = interpol([orb1.gsm_satellite_vel__y,orb2.gsm_satellite_vel__y],$
                                    [jorb1,jorb2],jd)
orb.gsm_satellite_vel__z = interpol([orb1.gsm_satellite_vel__z,orb2.gsm_satellite_vel__z],$
                                    [jorb1,jorb2],jd)
orb.gci_solar_pos__x = interpol([orb1.gci_solar_pos__x,orb2.gci_solar_pos__x],$
                                [jorb1,jorb2],jd)
orb.gci_solar_pos__y = interpol([orb1.gci_solar_pos__y,orb2.gci_solar_pos__y],$
                                [jorb1,jorb2],jd)
orb.gci_solar_pos__z = interpol([orb1.gci_solar_pos__z,orb2.gci_solar_pos__z],$
                                [jorb1,jorb2],jd)
orb.gci_lunar_pos__x = interpol([orb1.gci_lunar_pos__x,orb2.gci_lunar_pos__x],$
                                [jorb1,jorb2],jd)
orb.gci_lunar_pos__y = interpol([orb1.gci_lunar_pos__y,orb2.gci_lunar_pos__y],$
                                [jorb1,jorb2],jd)
orb.gci_lunar_pos__z = interpol([orb1.gci_lunar_pos__z,orb2.gci_lunar_pos__z],$
                                [jorb1,jorb2],jd)
orb.l_shell = interpol([orb1.l_shell,orb2.l_shell],$
                       [jorb1,jorb2],jd)
; ----------------------------------------
; load common block with items of interest
; ----------------------------------------
image_x = orb.gci_satellite_pos__x * EARTH_RADIUS
image_y = orb.gci_satellite_pos__y * EARTH_RADIUS
image_z = orb.gci_satellite_pos__z * EARTH_RADIUS

image_vx = orb.gci_satellite_vel__x
image_vy = orb.gci_satellite_vel__y
image_vz = orb.gci_satellite_vel__z

sun_x = orb.gci_solar_pos__x
sun_y = orb.gci_solar_pos__y
sun_z = orb.gci_solar_pos__z

moon_x = orb.gci_lunar_pos__x
moon_y = orb.gci_lunar_pos__y
moon_z = orb.gci_lunar_pos__z

image_gci_lat = asin(image_z/vmag(image_x,image_y,image_z)) * !RADEG
image_gci_lon = atan(image_y,image_x) * !RADEG
if (image_gci_lon lt 0.0) then image_gci_lon = image_gci_lon + 360.0

sidereal = gmst(jd)
image_w_lon = sidereal-image_gci_lon

; solar longitude of the spacecraft
solarlong = atan(sun_y,sun_x) * !RADEG
solarlong = image_gci_lon - solarlong
if (solarlong lt 0.0) then solarlong = solarlong + 360.0
if (solarlong gt 360.0) then solarlong = solarlong - 360.0

range = vmag(image_x, image_y, image_z)
range_re = range / EARTH_RADIUS

; compute transform from s/c coordinates to equatorial coordinates

; ----------------------------------------------------
; combine the three cameras (with overlap of 4 pixels)
; ----------------------------------------------------
bigmap[*,*] = 0.0

; camera 2
if ( (mask AND 4) gt 0) then bigmap[0:47,*]    = s2.skymap_sensor_2[0:47,*]

; camera 1
if ( (mask AND 2) gt 0) then bigmap[48:93,*]   = s1.skymap_sensor_1[2:47,*]

; camera 0
if ( (mask mod 2) gt 0) then bigmap[94:141,*]  = s0.skymap_sensor_0[2:49,*]


; if data from a camera is missing, piece the overlap area from
; the adjacent camera

if( (mask eq 2) or (mask eq 3) ) then begin ; camera 2 missing, 1 present
    bigmap[46:47,*]   = s1.skymap_sensor_1[0:1,*]
endif

if( (mask eq 4) or (mask eq 5) ) then begin ; camera 1 missing, 2 present
    bigmap[48:49,*]   = s2.skymap_sensor_2[48:49,*]
endif

if( (mask eq 2) or (mask eq 6) ) then begin ; camera 0 missing, 1 present
    bigmap[94:95,*]   = s1.skymap_sensor_1[48:49,*]
endif

if( (mask eq 1) or (mask eq 5) ) then begin ; camera 1 missing, 0 present
    bigmap[92:93,*]   = s0.skymap_sensor_0[0:1,*]
endif

dmap = transpose(bigmap[1:140,*])
working_dmap = dmap

; -------------------------------
; extract the portion of interest
; -------------------------------
if (user_xoff eq 0) then begin
    xoff = 0
    if ( (syear eq 2000) and (sdoy lt 158) ) then xoff = -13
endif else begin
    xoff=user_xoff
endelse
expand = 75 ; additional area to support the expanded zoom window
chunk = dmap[dtstart+xoff-expand:dtend+xoff+expand,*]
original = rotate(chunk,1)
workarray = original

;;;tvscl,alog10(workarray > 1.0)
redo_arrays


; -------------------------------------------------------------------------
; read ahead to find the next skymap 0 (makes forward browsing work better)
; -------------------------------------------------------------------------
if ( not udf_eof(fh0)) then s0 = udf_read(fh0)
next_year   = s0.btime.year
next_doy    = s0.btime.doy
next_hour   = s0.btime.hour
next_minute = s0.btime.min
next_second = s0.btime.sec

; check for duplicate records (successive reads return the same time)
jd0_next = load_jdate(s0.btime)
if(abs(jd0 - jd0_next) lt 0.0001d0) then begin
    if ( not udf_eof(fh0)) then s0 = udf_read(fh0)
    next_year   = s0.btime.year
    next_doy    = s0.btime.doy
    next_hour   = s0.btime.hour
    next_minute = s0.btime.min
    next_second = s0.btime.sec
    print,"next (after repeated read): ",next_year,next_doy,next_hour,next_minute,next_second
endif

; ------------------------
; close the UDF files
; ------------------------
udf_close, fh0
udf_close, fh1
udf_close, fh2
udf_close, forb

; --------------------------------
; enable the browse buttons
; --------------------------------
widget_control, forward_button, sensitive=1
widget_control, backward_button, sensitive=1
widget_control, forward_seek, sensitive=1

; ---------------------------------------------------
; set the from_udf flag to show the data source is UDF
; ---------------------------------------------------
from_udf = 1

; --------------------------------------------------
; reset the prev_set flag so that backwards browsing
; uses bump time
; --------------------------------------------------
prev_set = 0

; ----------------------------------------------
; clear the filename in the FITS filename widget
; ----------------------------------------------
widget_control, fitsnamew, set_value=''

end
