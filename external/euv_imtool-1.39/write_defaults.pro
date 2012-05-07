
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; write user's defaults for time limits, model settings, etc.
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; Last modified: 11-Sep-2003

pro write_defaults

@euv_imtool-commons

display_status,"Saving settings...""

; -----------------------------
; open/create the defaults file
; -----------------------------
if (!VERSION.OS_FAMILY ne 'unix') then begin
    udeffile = 'euv_imtool.ini'
endif else begin
    udeffile = '.euv_imtool'
    if (not defaults_in_current) then udeffile = getenv('HOME') + '/' + udeffile
endelse

openw, fu, udeffile, /get_lun

; ----------
; comment
; ----------
printf, fu, ";======================================"
printf, fu, ";    euv_imtool user defaults file     "
printf, fu, ";======================================"
printf, fu, ";    saved: ", systime(0)
printf, fu, ";======================================"
printf, fu, ";    ", VERSION

; ----------------
; time limits
; ----------------
printf, fu, "; -----------"
printf, fu, "; time limits"
printf, fu, "; -----------"
printf, fu, start_year,   format='("start_year   = ",i4)
printf, fu, start_doy,    format='("start_doy    = ",1x,i3)
printf, fu, start_hour,   format='("start_hour   = ",2x,i2)
printf, fu, start_minute, format='("start_minute = ",2x,i2)

; -----------------------
; background subtraction
; -----------------------
printf, fu, "; -------------------------------"
printf, fu, "; background subtraction settings"
printf, fu, "; -------------------------------"
printf, fu, "bminx = ", bminx
printf, fu, "bmaxx = ", bmaxx
printf, fu, "bminy = ", bminy
printf, fu, "bmaxy = ", bmaxy

; -----------------------
; contour plot settings
; -----------------------
printf, fu, "; -----------------------"
printf, fu, "; contour plot  settings"
printf, fu, "; -----------------------"
printf, fu, "cnlevels     = ", cnlevels
printf, fu, "cminval      = ", cminval
printf, fu, "cmaxval      = ", cmaxval


; -----------------------
; miscellaneous settings
; -----------------------
printf, fu, "; -----------------------"
printf, fu, "; miscellaneous  settings"
printf, fu, "; -----------------------"
printf, fu, "quicklook   = ", quicklook
printf, fu, "deband      = ", deband
printf, fu, "sort_clicks = ", sort_clicks
printf, fu, "continuous_readout = ", continuous_readout
printf, fu, "append_to_record = ", append_to_record

; --------------
; close the file
; --------------
close,fu
free_lun, fu

display_status,"Settings saved."
end
