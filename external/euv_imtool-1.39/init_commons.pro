;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; init_commons - initialize variables in the COMMON blocks
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 21-Jun-2005

pro init_commons

@euv_imtool-commons
@sf_common

VERSION = 'Version 1.39, June 21, 2005'
EARTH_RADIUS = 6378.0

warning = ['The center has not been defined for this image,',$
           'so the line of sight quantities may not be',$
           'calculated. Please define the Earth center by pressing',$
           'the Define Center button, then clicking to set it',$
           '(you should see a message in the program message window',$
           'when the center is set).']

warning2 = ['This FITS image was generated with either an older version',$
            'of euv_imtool or with an older version of the Web-based',$
            'FITS data extractor, using a pixel overlap of 5 pixels',$
            'between the cameras. This overlap has been revised',$
            'to 4 pixels. While this image may be loaded and viewed,',$
            'line of sight calculations will reflect systematic errors',$
            'that may be eliminated by using the revised FITS images.',$
            'This message will not be repeated during this session.']

warning3 = ['The center has not been defined for this image,',$
           'so the line of sight quantities may not be',$
           'calculated for the GSM dump. Please define the Earth center',$
           'by pressing the Define Center button, then clicking to set it',$
           '(you should see a message in the program message window',$
           'when the center is set).']

; --------------------
; image display arrays
; --------------------
xdim=140
ydim=150
xdim2 = xdim * 2
ydim2 = ydim * 2
xdim3 = xdim * 3
ydim3 = ydim * 3 * 2
mxdim = 600
mydim = 140
dtstart = 270
dtend   = 419

original = fltarr(xdim,ydim*2)
workarray = fltarr(xdim,ydim*2)

darray   = fltarr(xdim2,ydim2)
darrayl  = fltarr(xdim2,ydim2)
darray3  = fltarr(xdim3,ydim3)
darray3l = fltarr(xdim3,ydim3)

dmap    = fltarr(mxdim,mydim)
full    = fltarr(mxdim,mydim)
bigmap  = fltarr(mydim+2,mxdim)
working_dmap = fltarr(mxdim,mydim)

ref_image = replicate(0.0,xdim,ydim)
range0 = 51630.0

center_x2 = xdim2/2
center_y2 = ydim2/2
center_x3 = xdim3/2
center_y3 = ydim3/2

y_expand = 225

; ----------------------
; background subtraction
; ----------------------
bminx =   0
bminy = 201
bmaxx = 279
bmaxy = 299
deband = 1
subtract_background = 0
overlay_contour = 1
overlay_contour3 = 1

; ----------------------------------
; coordinate transformation matrices
; ----------------------------------
t1=dblarr(3,3)
t2=dblarr(3,3)
t3=dblarr(3,3)
t4=dblarr(3,3)
t5=dblarr(3,3)

mtrans = dblarr(3,3)

; --------------
; UDF start time
; --------------
start_year   = 2000
start_doy    = 145
start_hour   = 6
start_minute = 30
s0year = start_year
s0doy  = start_doy
s0hour = start_hour
s0min = start_minute
s0sec = 0

; --------------
; misc. flags
; --------------
quicklook = 0
centered = 0
warned = 0
warned2 = 0
fitsout = 0
fitsbrowse = 0
zoom_window_exists = 0
full_window_exists = 0
draw_circle = 1
prev_set = 0
continuous_readout = 0
batch_bkg_sub = 0
full_frame = 0

; -------------------
; spacecraft geometry
; -------------------
image_x = 0.0
image_y = 0.0
image_z = 0.0
image_vx = 0.0
image_vy = 0.0
image_vz = 0.0
image_smx = 0.0
image_smy = 0.0
image_smz = 0.0
image_smvx = 0.0
image_smvy = 0.0
image_smvz = 0.0
sun_x = 0.0
sun_y = 0.0
sun_z = 0.0
range = 0.0
range_re = 0.0

image_gci_lat = 0.0
image_gci_lon = 0.0
image_w_lon = 0.0

jdf1 = 0.0
jdf2 = 0.0

spin_axis_x = 0.0
spin_axis_y = 0.0
spin_axis_z = 0.0

; ----------------------
; IDL save file settings
; ----------------------
mk_idl_save = 0
save_full = 0

; ------------------------------
; radial / azimuthal plot window
; ------------------------------
plot_window_exists = 0
xplotsize = 500
yplotsize = 300
az      = fltarr(360)
azbrite = fltarr(360)
rad     = fltarr(135)
radbrite= fltarr(135)
radbrite_zoom= fltarr(135)
azbrite_zoom = fltarr(360)
circ   = fltarr(2,360)
del_x = 1
del_y = 1
del_ang = 4.0
plot_stretch = 0
multiplier = 2.0
multiplier_choices = ['2','3','4','5','6','7','8','9','10']
ra_log_scale = 0

; --------------------
; contour map settings
; --------------------
cnlevels = 8
cminval  = 10.0
cmaxval  = 1000.0

; --------------
; click settings
; --------------
xclick  = intarr(200)
yclick  = intarr(200)
xclick3 = intarr(200)
yclick3 = intarr(200)
xclick_full = intarr(200)
yclick_full = intarr(200)

nclicks = 0
sort_clicks = 0
click_in_full = 0

; ----------------------
; misc stuff
; ----------------------
backingstore = 1
auto_center = 0
cbias       = 0
n_overlap = 4
expanded_zoom = 0
from_udf = 0
write_full_fits = 0
append_to_record = 0
tau = 5.0

; -------------------------------
; ancillary solar wind data stuff
; -------------------------------
sfdatafile = 'solarwind.dat'
kpdatafile = 'kp.dat'
dstdatafile = 'dst.dat'
found_solar_data = 0
loaded_solar_data = 0
plot_sw_data = 0
sw_plot_exists = 0

sftimespan = 0.5
sflasttime = ''
sfmode = 0

end
