;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; gen_plots - generate radial and azimuthal plots
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 28-May-2003


function is_in_bounds, xx, yy, xdim, ydim

; check that a point is within the frame array size
if( (xx ge 0) and (xx lt xdim) and (yy ge 0) and (yy lt ydim) ) then return,1 else return,0

end


pro gen_plots, xx, yy, cen_x, cen_y, ll, mltlook, from_zoom

;;forward_function is_in_bounds

@euv_imtool-commons

; ---------------------------------------------------------
; save some input parameters in common, so that plot can be
; redrawn if the log scale checkbox changes
; ---------------------------------------------------------
mouse_x = xx
mouse_y = yy
mouse_l = ll
mouse_mlt = mltlook
center_x = cen_x
center_y = cen_y
from_zoom_win = from_zoom

rline = fltarr(2,2)

; -----------------------------------------------
; if coordinates come from zoomed window, correct,
; since all operations are performed with the
; 280x300 array (from main window).
; -----------------------------------------------
if(from_zoom) then begin
    xx = fix((2.0/3.0) * float(xx) + 0.5)
    yy = fix((2.0/3.0) * float(yy) + 0.5)
endif

radius = sqrt( (cen_x - xx)^2 + (cen_y - yy)^2 )

; --------------------------------
; generate data for radial plot
; --------------------------------
lscale = ll / radius

; make a copy of the data array within a larger frame
ntmpx = 396
ntmpy = 424
tmparray = replicate(0.0,ntmpx,ntmpy)
istartx = (ntmpx - xdim2) / 2
istarty = (ntmpy - ydim2) / 2

tmparray[istartx:istartx+xdim2-1,istarty:istarty+ydim2-1] = darrayl

; make a rotated image so that the chosen line is horizontal
rotangle = atan((float(cen_y) - float(yy))/(float(cen_x) - float(xx))) * !RADEG
cen2_x = cen_x+istartx
cen2_y = cen_y+istarty
r = rot(tmparray,rotangle,1.0,cen2_x,cen2_y)

; generate the data
nrad = ntmpx / (2 * del_x + 1)
ix = del_x
dix = 2 * del_x + 1
iy = ntmpy/2
miny = iy-del_y
maxy = iy+del_y

for i=0,nrad-1 do begin
    rr = sqrt( (float(cen2_x) - float(ix))^2 + (float(cen2_y) - float(iy))^2 )
    rad[i] = rr * lscale
    if (ix lt cen2_x) then rad[i] = -rad[i]
    minx = ix-del_x
    maxx = ix+del_x
    minx = minx > (-1)
    maxx = maxx < ntmpx
    npix = n_elements(r[minx:maxx,miny:maxy])
    if(ra_log_scale) then begin
        radbrite[i] = alog10(total(r[minx:maxx,miny:maxy]) / float(npix)) > 0.0000001
    endif else begin
        radbrite[i] = total(r[minx:maxx,miny:maxy]) / float(npix)
    endelse
    ix = ix + dix
endfor

slope = (float(cen_y) - float(yy)) / (float(cen_x) - float(xx))
intercept = float(cen_y) - slope * float(cen_x)

rline[0,0] = 1.0
rline[0,1] = float(xdim2-1)
rline[1,0] = slope * rline[0,0] + intercept
rline[1,1] = slope * rline[0,1] + intercept

; --------------------------------
; generate data for azimuthal plot
; --------------------------------
angle_look = atan((yy-cen_y),(xx-cen_x)) * !RADEG
ang = angle_look - mltlook * 15.0
mlt = 0.0
naz = 360.0/del_ang

for i=0,naz-1 do begin
    ar = ang / !RADEG
    ix = fix(radius * cos(ar)) + cen_x
    iy = fix(radius * sin(ar)) + cen_y
    circ[0,i] = float(ix)
    circ[1,i] = float(iy)
    if (is_in_bounds(ix,iy,xdim2,ydim2)) then begin
        sminx = (ix - del_x) > 0
        smaxx = (ix + del_x) < (xdim2 - 1)
        sminy = (iy - del_y) > 0
        smaxy = (iy + del_y) < (ydim2 - 1)
        npix  = (smaxx-sminx+1) * (smaxy-sminy+1)
        if(ra_log_scale) then begin
            azbrite[i] = alog10(total(darrayl[sminx:smaxx,sminy:smaxy]) / float(npix)) > 0.0000001
        endif else begin
            azbrite[i] = total(darrayl[sminx:smaxx,sminy:smaxy])/ float(npix)
        endelse
    endif else begin
        if(ra_log_scale) then azbrite[i] = 0.0000001 else azbrite[i] = 0.0
    endelse

    az[i] = mlt
    ang = ang + del_ang
    mlt = mlt + (del_ang/15.0)
endfor

; ------------------------------------------------------
; generate the data for the second (stretched) plot line
; ------------------------------------------------------
radbrite_zoom = radbrite * multiplier
azbrite_zoom  = azbrite * multiplier

; ------------------------------------------------------
; generate polylines to mark the positions of the radial
; and azimuthal traces
; ------------------------------------------------------
azline2 -> SetProperty, data=circ[*,0:naz-1], hide=0
azline3 -> SetProperty, data=circ[*,0:naz-1]*1.5, hide=0
radline2 -> SetProperty, data=rline, hide=0
radline3 -> SetProperty, data=rline*1.5, hide=0

; -----------------------------------------------------
; set up the viewports to allow room for the axes, etc.
; -----------------------------------------------------
viewp = [-0.25,-0.25,1.50,1.50]
imviewPa -> SetProperty, viewplane_rect=viewp
imviewPr -> SetProperty, viewplane_rect=viewp

; --------------------------------------
; define the arrays for the plot objects
; --------------------------------------
az_plot    -> SetProperty, datax=az[0:naz-1], datay=azbrite[0:naz-1]
rad_plot   -> SetProperty, datax=rad[0:nrad-1], datay=radbrite[0:nrad-1]
az_plot_z  -> SetProperty, datax=az[0:naz-1], datay=azbrite_zoom[0:naz-1]
rad_plot_z -> SetProperty, datax=rad[0:nrad-1], datay=radbrite_zoom[0:nrad-1]

; ---------------------
; show/hide second plot
; ---------------------
if(plot_stretch and not ra_log_scale) then begin
    az_plot_z -> SetProperty, hide=0
    rad_plot_z -> SetProperty, hide=0
endif else begin
    az_plot_z -> SetProperty, hide=1
    rad_plot_z -> SetProperty, hide=1
endelse

; ------------------------------------------------
; get ranges and convert to normalized coordinates
; ------------------------------------------------
az_plot -> GetProperty, xrange=xraz, yrange=yraz
yraz[0] = 0.0
az_plot -> SetProperty, XCOORD_CONV=norm_coord(xraz),$
  YCOORD_CONV=norm_coord(yraz)

rad_plot -> GetProperty, xrange=xrrad, yrange=yrrad
yrrad[0] = 0.0
rad_plot -> SetProperty, XCOORD_CONV=norm_coord(xrrad),$
  YCOORD_CONV=norm_coord(yrrad)

az_plot_z -> SetProperty, XCOORD_CONV=norm_coord(xraz),$
  YCOORD_CONV=norm_coord(yraz)

rad_plot_z -> SetProperty, XCOORD_CONV=norm_coord(xrrad),$
  YCOORD_CONV=norm_coord(yrrad)

; -----------
; define axes
; -----------
xaxis_az -> SetProperty, range=[xraz[0],xraz[1]]
xaxis_az -> SetProperty, XCOORD_CONV=norm_coord(xraz)
xaxis_az -> SetProperty, TICKLEN=0.05

if (ra_log_scale) then begin
    yaxis_az -> SetProperty, range=[0.0,3.0]
    yaxis_az -> SetProperty, YCOORD_CONV=norm_coord([0.0,3.0])
    yaxis_az -> SetProperty, tickvalues=[0.0,1.0,2.0,3.0],ticktext=log_label_a

endif else begin
    yaxis_az -> SetProperty, range=[yraz[0],yraz[1]]
    yaxis_az -> SetProperty, YCOORD_CONV=norm_coord(yraz)
    yaxis_az -> SetProperty, tickvalues=0,ticktext=null_label_a
endelse

yaxis_az -> SetProperty, TICKLEN=0.05

xaxis_az -> SetProperty, exact=1
xaxis_az -> SetProperty, title=mlt_label
yaxis_az -> SetProperty, exact=1
yaxis_az -> SetProperty, title=counts_label

xaxis_rad -> SetProperty, range=[xrrad[0],xrrad[1]]
xaxis_rad -> SetProperty, XCOORD_CONV=norm_coord(xrrad)
xaxis_rad -> SetProperty, TICKLEN=0.05

if (ra_log_scale) then begin
    yaxis_rad -> SetProperty, range=[0.0,3.0]
    yaxis_rad -> SetProperty, YCOORD_CONV=norm_coord([0.0,3.0])
    yaxis_rad -> SetProperty, tickvalues=[0.0,1.0,2.0,3.0],ticktext=log_label_r
endif else begin
    yaxis_rad -> SetProperty, range=[yrrad[0],yrrad[1]]
    yaxis_rad -> SetProperty, YCOORD_CONV=norm_coord(yrrad)
    yaxis_rad -> SetProperty, tickvalues=0,ticktext=null_label_r
endelse

yaxis_rad -> SetProperty, TICKLEN=0.05

xaxis_rad -> SetProperty, exact=1
xaxis_rad -> SetProperty, title=l_label
yaxis_rad -> SetProperty, exact=1
yaxis_rad -> SetProperty, title=counts_label

; ----------------
; draw the plots
; ----------------
windowpa -> Draw, imviewPa
windowpr -> Draw, imviewPr

; ------------------------------------------------
; update the image windows also to show the radial
; and azimuthal lines
; ------------------------------------------------
redraw_views

end
