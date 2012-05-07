;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; load_fits - load the display from a FITS file (created by
;             euv_display program).
;
; This routine will load the original (280x300) FITS files,
; the newer 140x150 FITS files, or the (600x140) full frame
; FITS files (even the transposed kind!).
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 18-Dec-2003

pro load_fits, filename

@euv_imtool-commons

name = 'abc'
eqsign = '='
value = 'abc'
rest = 'abc'
s0time = 'abc'
s0year = 0
s0doy = 0
s0hour = 0
s0min = 0
s0sec = 0
jd = 0.0d0

; --------------------------------------------------------------
; read the data, check for linear or logarithmic data values
; Linear data values also imply an original size image (140x150)
; or a full-frame image
; --------------------------------------------------------------
tmp=readfits(filename,fitshead)

linear = sxpar(fitshead,'LINEAR')
full_frame = sxpar(fitshead,'NAXIS1') eq 600 or sxpar(fitshead,'NAXIS2') eq 600
flipped_full_frame = sxpar(fitshead,'NAXIS2') eq 600


if(not full_frame) then begin

    original = replicate(0.0,xdim,ydim*2) ; clear array of previous contents
    if(linear) then begin
        original[*,75:224] = tmp
    endif else begin
        original[*,75:224] = rebin((10.0 ^ tmp - 1.0),140,150)
    endelse

    dmap = replicate(0.0,mxdim,mydim) ; clear full-frame array

endif else begin
    
    if(flipped_full_frame) then dmap = rotate(tmp,3) else dmap = tmp

    ; set offset for early mission data (< 2000/158)
    xoff = 0
    if ( sxpar(fitshead,'JUL_DAY') lt 2451701.5) then xoff = -13

    expand = 75  ; additional area to support the expanded zoom window
    chunk = dmap[dtstart+xoff-expand:dtend+xoff+expand,*]
    original = rotate(chunk,1)

endelse

working_dmap = dmap

workarray = original
redo_arrays

; ---------------------------------------------------------
; check for the pixel overlap keyword, and warn the user if
; an older FITS image is being loaded
; ---------------------------------------------------------
overlap = sxpar(fitshead,'OVERLAP')
if (not warned2 and (overlap eq 0)) then begin
    result = dialog_message(warning2)
    warned2 = 1
endif

; ----------------------------------------------------------
; check for the presence of the TAU keyword, set tau to
; 5.0 if not present (number of spins in the integration)
; ----------------------------------------------------------
tau = float(sxpar(fitshead,'TAU'))
if ( tau eq 0.0 ) then tau = 5.0

; --------------------------------------
; decode necessary stuff from the header
; --------------------------------------
s0time = sxpar(fitshead,'IMTIME')
reads,s0time,s0year,s0doy,s0hour,s0min,s0sec,$
  format='(I4,1x,I3,1x,I2,1x,I2,1x,I2)'

;jd = calc_jd(s0year,s0doy,s0hour,s0min,s0sec,0) - (180.0/86400.0)
jd = sxpar(fitshead,'JUL_DAY') - 2400000.0d0

image_x = sxpar(fitshead,'IMAGE_X')
image_y = sxpar(fitshead,'IMAGE_Y')
image_z = sxpar(fitshead,'IMAGE_Z')

image_vx = sxpar(fitshead,'IMAGE_VX')
image_vy = sxpar(fitshead,'IMAGE_VY')
image_vz = sxpar(fitshead,'IMAGE_VZ')

sun_x = sxpar(fitshead,'SUN_X')
sun_y = sxpar(fitshead,'SUN_Y')
sun_z = sxpar(fitshead,'SUN_Z')

moon_x = sxpar(fitshead,'MOON_X')
moon_y = sxpar(fitshead,'MOON_Y')
moon_z = sxpar(fitshead,'MOON_Z')

image_gci_lat = sxpar(fitshead,'IMAGELAT')
image_gci_lon = sxpar(fitshead,'IMAGELON')
image_w_lon   = sxpar(fitshead,'IMAGWLON')

; solar longitude of the spacecraft
solarlong = atan(sun_y,sun_x) * !RADEG
solarlong = image_gci_lon - solarlong
if (solarlong lt 0.0) then solarlong = solarlong + 360.0
if (solarlong gt 360.0) then solarlong = solarlong - 360.0

spin_axis_x = sxpar(fitshead,'SPINAXX')
spin_axis_y = sxpar(fitshead,'SPINAXY')
spin_axis_z = sxpar(fitshead,'SPINAXZ')

range = vmag(image_x, image_y, image_z)
range_re = range / EARTH_RADIUS

; --------------------------------------
; get Sun angle
; --------------------------------------
get_sun_angle

; ------------------------------------------------
; define xoff (only used in extracting the
; image from the full UDF frame, but needs to be
; defined to make the centering work
; ------------------------------------------------
xoff = 0

; --------------------------------------
; put the file name on the display
; --------------------------------------
widget_control, fitsnamew, set_value=filename

; --------------------------------
; disable the browse buttons
; --------------------------------
if(not fitsbrowse) then begin
    widget_control, forward_button, sensitive=0
    widget_control, backward_button, sensitive=0
endif
widget_control, forward_seek, sensitive=0

; ------------------------------------------------------------
; clear the from_udf flag to show that the data source is FITS
; ------------------------------------------------------------
from_udf = 0

end
