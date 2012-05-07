;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; set_los_readouts.pro - set/clear the LOS readout widgets
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 28-Aug-2002

pro set_los_readouts, minL, tp_maglon, mlt_look, spot_average, set

@euv_imtool-commons

if(set) then begin
    widget_control,minLw,set_value=string(minL,format='(f6.2)')
    widget_control,mltw,set_value=string(mlt_look,format='(f6.2)')
    widget_control,mlnw,set_value=string(tp_maglon,format='(f6.2)')
    widget_control, wspt, set_value=string(spot_average,format='(f6.0)')
endif else begin
    widget_control,minLw,set_value=''
    widget_control,mltw,set_value=''
    widget_control,mlnw,set_value=''
    widget_control, wspt, set_value=''
endelse


end
