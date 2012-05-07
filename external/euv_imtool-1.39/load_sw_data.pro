
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; restore the solar wind, Dst and Kp save files if possible
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; Last modified: 13-Oct-2003

pro load_sw_data, action

@euv_imtool-commons
@sf_common

; -----------------------------------------------
; set OS-dependent path delimiter
; -----------------------------------------------
if !version.os eq 'Win32' then delim = '\' $
else if !version.os eq 'MacOS' then delim = ':' $
else delim = '/'                ; default to linux

; ------------------------------------------------------
; look for the data files in the current directory first
; ------------------------------------------------------
openr,lutmp,sfdatafile,ERROR=err,/get_lun

if(err eq 0) then begin
    close, lutmp
    free_lun, lutmp
    if(action ne 0) then begin
        widget_control, /hourglass
        restore,sfdatafile
        restore,kpdatafile
        restore,dstdatafile
        loaded_solar_data = 1
    endif
    found_solar_data = 1
    return
endif

; ----------------------------------------------------
; if not found, try in the environment variable SWDATA
; ----------------------------------------------------
ddir = getenv('SWDATA')
if(ddir ne '') then begin
    ddir = getenv('SWDATA')
    if(action ne 0) then begin
        widget_control, /hourglass
        restore, ddir + delim + sfdatafile
        restore, ddir + delim + kpdatafile
        restore, ddir + delim + dstdatafile
        loaded_solar_data = 1
    endif
    found_solar_data = 1
endif

if( loaded_solar_data ) then display_status, "Loaded Solar wind data."

end
