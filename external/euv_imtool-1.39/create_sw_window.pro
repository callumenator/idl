;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; create_sw_window - create a window to hold the solar wind plots
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 30-Jun-2003

pro create_sw_window, time

@euv_imtool-commons
@sf_common

; ------------------------------------------------------
; create the window
; ------------------------------------------------------
sf_base = widget_base(xsize = 500, $
                      ysize = 720, $
                      title = 'Solar Wind Data')

sf_draw = widget_draw(sf_base, xoffset=0, yoffset=0, xsize=500, ysize=700, $
                      retain = backingstore)

sf_slider = widget_slider(sf_base, uvalue = 'sf_slider', xoffset = 0, $
                          yoffset = 700, xsize = 400, ysize = 20, $
                          /suppress_value, minimum = 0, maximum = 1000, $
                          value = 100)

sf_dumppng = widget_button(sf_base, uvalue = 'sf_dumppng', xoffset = 450, $
                           yoffset = 700, xsize = 50, ysize = 20, $
			   value = 'PNG')

sf_modeswitch = widget_button(sf_base, uvalue = 'sf_modesw', xoffset = 400, $
                              yoffset = 700, xsize = 50, ysize = 20, $
		    	      value = 'Fixed')

; ---------------------------------------------------------------
; make the window visible and register it with XMANAGER to handle
; events
; ---------------------------------------------------------------
widget_control, sf_base, /realize
widget_control, sf_draw, get_value = sf_hdraw
if(not loaded_solar_data) then load_sw_data,1
sf_update, time
xmanager, 'sf', sf_base

sw_plot_exists = 1

sfmode = 0
end



