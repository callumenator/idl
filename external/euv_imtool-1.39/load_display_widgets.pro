;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; load_display_widgets.pro -
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 28-May-2003


function get_midpoint, jd
; --------------------------------------------------------------------
; generate a string containing the image midpoint time (add 30 seconds
; to round to the nearset minute)
; --------------------------------------------------------------------
caldat, jd + 2400000.0 + (30.0d0/86400.0d0), $
  new_month, new_day, new_year, new_hour, new_minute, new_second

mid_year = fix(new_year)
mid_doy = fix(doy(new_year,new_month,new_day))
mid_hour = fix(new_hour)
mid_min  = fix(new_minute)

return, string(mid_year,mid_doy,mid_hour,mid_min,format='(i4,"/",i3.3,"/",i2.2,":",i2.2)')

end


pro load_display_widgets

@euv_imtool-commons

;;forward_function get_midpoint

; --------------------
; do some calculations
; --------------------
mlat  = asin(image_smz/range) * !RADEG
mlon = image_maglon

; ---------------------------------
; set values in the display widgets
; ---------------------------------
widget_control, midpointw, set_value=get_midpoint(jd)
widget_control, rangew, set_value=string(range_re,format='(f6.2)')

widget_control,imlatw,set_value=string(image_gci_lat,format='(F6.2)')
image_e_lon = 360.0 - image_w_lon
if (image_e_lon gt 360.0) then image_e_lon = image_e_lon - 360.0
if (image_e_lon lt 0.0)   then image_e_lon = image_e_lon + 360.0
widget_control,imlonw,set_value=string(image_e_lon,format='(F6.2)')

widget_control,immlatw,set_value=string(mlat,format='(F6.2)')
widget_control,immlonw,set_value=string(mlon,format='(F6.2)')

widget_control, imxw, set_value=string(image_x/EARTH_RADIUS,format='(F6.2)')
widget_control, imyw, set_value=string(image_y/EARTH_RADIUS,format='(F6.2)')
widget_control, imzw, set_value=string(image_z/EARTH_RADIUS,format='(F6.2)')
widget_control, imxsmw, set_value=string(image_smx/EARTH_RADIUS,format='(F6.2)')
widget_control, imysmw, set_value=string(image_smy/EARTH_RADIUS,format='(F6.2)')
widget_control, imzsmw, set_value=string(image_smz/EARTH_RADIUS,format='(F6.2)')


end




