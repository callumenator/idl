
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; euv_imtool - display an EUV skymap image and operate on it.
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 16-Jun-2005


function x_main_to_zoom,xmain
; -----------------------------------------------------
return, fix(float(xmain)*1.5 +0.5)
end


function y_main_to_zoom,ymain
; -----------------------------------------------------
@euv_imtool-commons
y_addition = 0
if(expanded_zoom) then y_addition = y_expand
return, fix(float(ymain)*1.5 +0.5) + y_addition
end

 
function x_zoom_to_main,xzoom
; -----------------------------------------------------
return, fix(float(xzoom)*0.6666667 +0.5)
end


function y_zoom_to_main,yzoom
; -----------------------------------------------------
@euv_imtool-commons
y_addition = 0
if(expanded_zoom) then y_addition = y_expand
return, fix(float(yzoom-y_addition)*0.6666667 +0.5)
end

function x_main_to_full,ymain
; -----------------------------------------------------
@euv_imtool-commons
return, fix(float(ymain) / 2.0 + 0.5) + dtstart + xoff
end

function y_main_to_full,xmain
; -----------------------------------------------------
return, 139 - fix(float(xmain) / 2.0)
end

function x_full_to_main,yfull
; -----------------------------------------------------
return, 2 * (139 - yfull)
end


function y_full_to_main,xfull
; -----------------------------------------------------
@euv_imtool-commons
return, 2 * (xfull - dtstart - xoff)
end


;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; euv_imtool_event - event handler
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
pro EUV_IMTOOL_event,event

@euv_imtool-commons

forward_function get_midpoint

; -------------
; handle events
; -------------
widget_control, get_uvalue=uval, event.id
case uval of

    2: begin                    ; handle menu bar events

        case event.value of

            'Quit': begin
                widget_control, /destroy, event.top ; Quit
                if (zoom_window_exists) then widget_control, /destroy, wBase3
                if (plot_window_exists) then widget_control, /destroy, wBaseP
                if (full_window_exists) then widget_control, /destroy, wBase4
                if (sw_plot_exists) then widget_control, /destroy, sf_base
                OBJ_DESTROY, scene
                OBJ_DESTROY, scene3
                OBJ_DESTROY, scene4
                OBJ_DESTROY, sceneP
            end
            
            'Save Settings': begin
                write_defaults
            end
            
            'Load FITS files...': begin
                fitsfile_temp=dialog_pickfile(/read,filter="*.fit*",$
                                              /multiple_files,$
                                              title='Select FITS file(s) to load')

                fitsfile = fitsfile_temp[sort(fitsfile_temp)]

                if (n_elements(fitsfile) gt 1) then begin
                    fitsbrowse = 1
                    widget_control, forward_button, sensitive=1
                    widget_control, backward_button, sensitive=0
                    nfitsfiles = n_elements(fitsfile)
                    fits_file_array = fitsfile
                    current_fits = 0
                    load_fits,fits_file_array[0]
                    freshen_all
                    if(auto_center) then do_auto_center else display_status,"Loaded FITS file."
                endif else begin
                    fitsbrowse = 0
                    widget_control, forward_button, sensitive=0
                    widget_control, backward_button, sensitive=0
                    if (fitsfile[0] ne '') then begin
                        load_fits,fitsfile[0]
                        freshen_all
                        if(auto_center) then do_auto_center else display_status,"Loaded FITS file."
                    endif
                end
            end

            'Load from UDF Data...': begin
                udf_load_canceled = 0
                get_start_time, event
                if(not udf_load_canceled) then begin
                    load_udf_data,quick=quicklook
                    fitsbrowse = 0
                    freshen_all
                    if(auto_center) then do_auto_center else display_status,"Loaded UDF data."
                endif
            end

            'Color Palette (main window)...': begin
                ct_update = 0
                xloadct, updatecallback='update_color_table'
            end

            'Color Palette (zoom window)...': begin
                ct_update = 1
                xloadct, updatecallback='update_color_table'
            end

            'Color Palette (full window)...': begin
                ct_update = 2
                xloadct, updatecallback='update_color_table'
            end

            'Color Palette (all windows)...': begin
                ct_update = 3
                xloadct, updatecallback='update_color_table'
            end

            'Export JPEG Image...': begin
                caldat,jd+2400000.0+(30.0d0/86400.0d0),mmonth,mday,myear,mh,mm,ms
                mdoy = doy(myear,mmonth,mday)
                default_filename = 'e'+ string(myear,mdoy,mh,mm,format='(i4,i3.3,i2.2,i2.2)')+'.jpg'
                out_filename = dialog_pickfile(dialog_parent=wBase,$
                                               file=default_filename,$
                                               filter='*.jpg',$
                                               /write)
                if(out_filename ne '') then write_jpeg_image, out_filename
            end

            'Export JPEG Image (Full Frame)...': begin
                caldat,jd+2400000.0+(30.0d0/86400.0d0),mmonth,mday,myear,mh,mm,ms
                mdoy = doy(myear,mmonth,mday)
                default_filename = 'e'+ string(myear,mdoy,mh,mm,format='(i4,i3.3,i2.2,i2.2)')+'.jpg'
                out_filename = dialog_pickfile(dialog_parent=wBase,$
                                               file=default_filename,$
                                               filter='*.jpg',$
                                               /write)
                if(out_filename ne '') then write_jpeg_image_full, out_filename
            end

            'Export FITS File...': begin
                write_full_fits = 0
                caldat,jd+2400000.0+(30.0d0/86400.0d0),mmonth,mday,myear,mh,mm,ms
                mdoy = doy(myear,mmonth,mday)
                default_filename = 'e'+ string(myear,mdoy,mh,mm,format='(i4,i3.3,i2.2,i2.2)')+'.fits'
                out_filename = dialog_pickfile(dialog_parent=wBase,$
                                               file=default_filename,$
                                               filter='*.fits',$
                                               /write)

                if(out_filename ne '') then write_fits_image, out_filename
            end

            'Export FITS File (Full Frame)...': begin
                write_full_fits = 1
                caldat,jd+2400000.0+(30.0d0/86400.0d0),mmonth,mday,myear,mh,mm,ms
                mdoy = doy(myear,mmonth,mday)
                default_filename = 'e'+ string(myear,mdoy,mh,mm,format='(i4,i3.3,i2.2,i2.2)')+'.fits'
                out_filename = dialog_pickfile(dialog_parent=wBase,$
                                               file=default_filename,$
                                               filter='*.fits',$
                                               /write)

                if(out_filename ne '') then write_fits_image, out_filename
            end


            'Subtract background...': begin
                get_backsub_params, event
                if (subtract_back) then subtract_background
                update_image_displays
                redraw_views
            end

            'Revert Image': begin
                workarray = original
                working_dmap = dmap
                redo_arrays
                update_image_displays
                redraw_views
            end

            'Dump GSM...': begin
                if(not centered) then begin
                    result=dialog_message(warning3)
                endif else begin
                    widget_control, /hourglass
                    caldat,jd+2400000.0+(30.0d0/86400.0d0),mmonth,mday,myear,mh,mm,ms
                    mdoy = doy(myear,mmonth,mday)
                    default_filename = 'e'+ string(myear,mdoy,mh,mm,format='(i4,i3.3,i2.2,i2.2)')+'.gsm'
                    out_filename = dialog_pickfile(dialog_parent=wBase,$
                                                   file=default_filename,$
                                                   filter='*.gsm',$
                                                   /write)

                    gsm_from_sm = transpose(t4)
                    

                    openw, lugsm, out_filename, /get_lun
                    from = 0
                    radius_e =  (asin(1.0/range_re) * !RADEG) / 0.3

                    for i=0,xdim-1 do begin
                        for j=0,ydim-1 do begin
                            brite = workarray[i,j+75]
                            ix = i * 2 + 1
                            jy = j * 2 + 1
                            calc_look, ix, jy, minL, tp_maglon, mlt_look, spot_average,px, py, pz, from
                            look_sm = [px,py,pz]
                            look_gsm = gsm_from_sm##look_sm

                            radius = vmag((ix-center_x2),(jy-center_y2),0)

                            if((radius/radius_e) gt 1.05 ) then printf, $
                              lugsm, look_gsm[0], look_gsm[1], look_gsm[2], minL, brite, i, j,$
                              format='(f6.2, 2x, f6.2, 2x, f6.2, 4x, f6.2, 4x, f8.2, 4x, i3, 2x, i3)'
                        endfor
                    endfor

                    close, lugsm
                    free_lun, lugsm
                end

            end

            'Set start time...': begin
                get_start_time, event, wtitle='Start Time for FITS Extraction',fitsout=1
            end

            'Set stop time...': begin
                get_start_time, event, wtitle='Stop Time for FITS Extraction',fitsout=2
            end

            'Make FITS files': begin
                widget_control, /hourglass
                write_full_fits = 0
                start_year = yf1
                start_doy  = df1
                start_hour = hf1
                start_minute = mf1
                start_second = 0
                load_udf_data,quick=quicklook
                fitsbrowse = 0
                while (jd le jdf2) do begin
                    calc_sm_coords
                    caldat,jd+2400000.0,mmonth,mday,myear,mh,mm,ms
                    mdoy = doy(myear,mmonth,mday)
                    out_filename = 'e'+ string(myear,mdoy,mh,mm,format='(i4,i3.3,i2.2,i2.2)')+'.fits'
                    if (batch_bkg_sub) then subtract_background
                    write_fits_image, out_filename
                    display_status, 'Wrote FITS file: ' + out_filename
                    start_year = next_year
                    start_doy  = next_doy
                    start_hour = next_hour
                    start_minute = next_minute
                    start_second = next_second
                    load_udf_data,quick=quicklook
                    fitsbrowse = 0
                endwhile

            end

            'Make FITS files (Full Frame)': begin
                widget_control, /hourglass
                write_full_fits = 1
                start_year = yf1
                start_doy  = df1
                start_hour = hf1
                start_minute = mf1
                start_second = 0
                load_udf_data,quick=quicklook
                fitsbrowse = 0
                while (jd le jdf2) do begin
                    calc_sm_coords
                    caldat,jd+2400000.0,mmonth,mday,myear,mh,mm,ms
                    mdoy = doy(myear,mmonth,mday)
                    out_filename = 'e'+ string(myear,mdoy,mh,mm,format='(i4,i3.3,i2.2,i2.2)')+'.fits'
                    if (batch_bkg_sub) then subtract_background
                    write_fits_image, out_filename
                    display_status, 'Wrote FITS file: ' + out_filename
                    start_year = next_year
                    start_doy  = next_doy
                    start_hour = next_hour
                    start_minute = next_minute
                    start_second = next_second
                    load_udf_data,quick=quicklook
                    fitsbrowse = 0
                endwhile

            end

            'Make IDL save file': begin
                varnames = ''
                widget_control, /hourglass
                start_year = yf1
                start_doy  = df1
                start_hour = hf1
                start_minute = mf1
                start_second = 0
                load_udf_data,quick=quicklook
                fitsbrowse = 0
                first = 1
                while (jd le jdf2) do begin
                    calc_sm_coords
                    caldat,jd+2400000.0,mmonth,mday,myear,mh,mm,ms
                    mdoy = doy(myear,mmonth,mday)
                    start_year = next_year
                    start_doy  = next_doy
                    start_hour = next_hour
                    start_minute = next_minute
                    start_second = next_second
                    save_var_name = 'e'+ string(myear,mdoy,mh,mm,format='(i4,i3.3,i2.2,i2.2)')
                    if (first) then begin 
                        save_file_name = save_var_name + ".sav"
                        first = 0
                    endif
                    if (batch_bkg_sub) then subtract_background
                    cmd = string(save_var_name) + "= workarray[*,75:224]"
                    result = execute(cmd)
                    varnames = varnames + save_var_name + ","
                    load_udf_data,quick=quicklook
                    fitsbrowse = 0
                endwhile

                cmd = "save, " + varnames + "filename=" + "'" + save_file_name + "'"
                result = execute(cmd)

            end

            'Make IDL save file (full frame)': begin
                varnames = ''
                widget_control, /hourglass
                start_year = yf1
                start_doy  = df1
                start_hour = hf1
                start_minute = mf1
                start_second = 0
                load_udf_data,quick=quicklook
                fitsbrowse = 0
                first = 1
                while (jd le jdf2) do begin
                    calc_sm_coords
                    caldat,jd+2400000.0,mmonth,mday,myear,mh,mm,ms
                    mdoy = doy(myear,mmonth,mday)
                    start_year = next_year
                    start_doy  = next_doy
                    start_hour = next_hour
                    start_minute = next_minute
                    start_second = next_second
                    load_udf_data,quick=quicklook
                    fitsbrowse = 0
                    save_var_name = 'e'+ string(myear,mdoy,mh,mm,format='(i4,i3.3,i2.2,i2.2)')
                    if (first) then begin 
                        save_file_name = save_var_name + ".sav"
                        first = 0
                    endif
                    cmd = string(save_var_name) + "= rotate(transpose(bigmap[1:140,*]),1)"
                    result = execute(cmd)
                    varnames = varnames + save_var_name + ","
                endwhile

                cmd = "save, " + varnames + "filename=" + "'" + save_file_name + "'"
                result = execute(cmd)

            end



        endcase

    end

    16: begin                   ; keep center button
        if(keep_center eq 0) then begin
            widget_control, keep_button, set_value="Center Set! "
            widget_control, center_button, set_value="Redefine Center"
            centered = 1
            keep_center = 1
            draw_center_ellipse,center_x2,center_y2,0,1
            widget_control, plot_button, sensitive=1
            display_status, string(center_x2,center_y2,format='("Using center ",I4,2x,I4," (main window coordinates)")')
            center_ellipse  -> SetProperty, hide=0
            center_ellipse3 -> SetProperty, hide=0
            center_ellipse_full -> SetProperty, hide=0
            redraw_views
        end
    end

    17: begin                   ; Define/Redefine Center
        defining_center = 1
        if(centered) then begin ; re-defining center
            center_ellipse -> SetProperty, hide=1
            center_ellipse3 -> SetProperty, hide=1
            center_ellipse_full -> SetProperty, hide=1
            center_point -> SetProperty, hide=1
            center_point3 -> SetProperty, hide=1
            center_point_full -> SetProperty, hide=1
        endif else begin        ; define center
            widget_control, center_button, set_value="Redefine Center"
            widget_control, keep_button, set_value="Center Set! "
        endelse
        center_ellipse  -> SetProperty, hide=0
        center_ellipse3 -> SetProperty, hide=0
        center_ellipse_full -> SetProperty, hide=0
        redraw_views

    end
    
    18: begin                   ; show/hide contour plot
        if(overlay_contour) then begin
            widget_control,contour_button,set_value="Overlay Contour Plot"
            overlay_contour = 0
            overlay_contour3 = 0
            contour ->SetProperty, hide=1
            contour3 ->SetProperty, hide=1
        endif else begin
            widget_control,contour_button,set_value="Remove Contour Plot"
            overlay_contour = 1
            overlay_contour3 = 1
            contour ->SetProperty, hide=0
            contour3 ->SetProperty, hide=0
        end
        redraw_views

    end
    
    19: begin                   ; enable/disable zoomed display window
        
        if (zoom_on) then begin
            widget_control,zoom_button,set_value="Show Zoomed Display"
            destroy_zoom_window
            zoom_on = 0
        endif else begin
            widget_control,zoom_button,set_value="Hide Zoomed Display"
            zoom_on = 1
            create_zoom_window
        endelse
    end

    20: begin                   ; forward browse button press
        if(fitsbrowse) then begin
            current_fits = current_fits + 1
            if (current_fits eq (nfitsfiles-1)) then begin
                widget_control, forward_button, sensitive=0
            endif
            widget_control, backward_button, sensitive=1
            load_fits,fits_file_array[current_fits]
            display_status,"Loaded FITS file."
        endif else begin
            prev_year = start_year
            prev_doy  = start_doy
            prev_hour = start_hour
            prev_minute = start_minute
            prev_second = start_second
            prev_set = 1
            start_year = next_year
            start_doy  = next_doy
            start_hour = next_hour
            start_minute = next_minute
            start_second = next_second
            load_udf_data,quick=quicklook
            fitsbrowse = 0
        endelse
        freshen_all
        if(auto_center) then do_auto_center

    end

    21: begin                   ; backward browse button press
        if(fitsbrowse) then begin
            current_fits = current_fits - 1
            if (current_fits eq 0) then begin
                widget_control, backward_button, sensitive=0
            endif
            widget_control, forward_button, sensitive=1
            load_fits,fits_file_array[current_fits]
            display_status,"Loaded FITS file."
        endif else begin
            if (not prev_set) then begin
                bump_time,-550
            endif else begin
                start_year = prev_year
                start_doy  = prev_doy
                start_hour = prev_hour
                start_minute = prev_minute
                start_second = prev_second
                prev_set = 0
            endelse
            load_udf_data,quick=quicklook
            fitsbrowse = 0
        endelse
        freshen_all
        if(auto_center) then do_auto_center
    end

    22: begin                   ; forward seek button press
        do_seek
        load_udf_data,quick=quicklook
        fitsbrowse = 0
        freshen_all
        if(auto_center) then do_auto_center
    end

    23: begin
        click_points -> SetProperty, hide=1
        click_points3 -> SetProperty, hide=1
        click_points_full -> SetProperty, hide=1
        nclicks = 0
        widget_control, record_file, sensitive=0
        redraw_views
    end

    29: begin                  ; enable/disable radial/azimuthal plots
        if(do_plots) then begin
            widget_control,plot_button,set_value="Enable Radial/Azimuthal Plots "
            if ( plot_window_exists ) then destroy_plot_window
            hide_polylines
            redraw_views
            do_plots = 0
            if (zoom_window_exists) then widget_control, expand_button, sensitive=1
        endif else begin
            widget_control,plot_button,set_value="Disable Radial/Azimuthal Plots"
            if (zoom_window_exists) then begin
                if(expanded_zoom) then shrink_zoom_window
                widget_control, expand_button, sensitive=0
            endif
            do_plots = 1
        end

    end
    
    

    30: begin                   ; write click geometry to file
        widget_control, filew, get_value=outf
        outfile = outf[0]
        if(outfile eq '') then begin
            outfile = dialog_pickfile(/write)
        endif
        if(outfile ne '') then record_clicks, minL, tp_maglon, mlt_look, spot_average, outfile
    end

    31: begin                   ; sort file check box
        sort_clicks = event.select
    end

    32: begin                   ; continuous readout check box
        continuous_readout = event.select
        if(not continuous_readout) then set_los_readouts,minL, tp_maglon, mlt_look, spot_average,0
    end

    33: begin                   ; auto-center check box
        auto_center = event.select
        if(auto_center) then begin
            do_auto_center
        endif else begin
            centered=0
            center_ellipse -> SetProperty, hide=1
            center_ellipse3 -> SetProperty, hide=1
            center_ellipse_full -> SetProperty, hide=1
            center_point -> SetProperty, hide=1
            center_point3 -> SetProperty, hide=1
            center_point_full -> SetProperty, hide=1
            widget_control, center_button, set_value="Define Center  "
            redraw_views
        endelse
    end

    34: begin                   ; bias droplist
        reads,bias_choices[event.index], cbias
        if(auto_center) then do_auto_center
    end

    41: begin               ; enable/disable full frame display window
        
        if (full_window_exists) then begin
            widget_control,full_button,set_value="Show Full Frame Display"
            destroy_full_window
        endif else begin
            widget_control,full_button,set_value="Hide Full Frame Display"
            create_full_window
        endelse
    end

    42: begin                   ; show/hide solar wind plots
        
        if(sw_plot_exists) then begin
            widget_control,sw_button,set_value="Show Solar Wind Plot"
            destroy_sw_window
            plot_sw_data = 0
        endif else begin
            widget_control,sw_button,set_value="Hide Solar Wind Plot"
            plot_sw_data = 1
            create_sw_window,get_midpoint(jd)
        endelse

    end

    44: begin                   ; Append check box
        append_to_record = event.select
    end



    4: begin                    ; events in skymap window
        handle_image_event, event, 0
    end


end

end

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; euv_imtool_event3 - zoom window event handler
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
pro EUV_IMTOOL_event3,event

@euv_imtool-commons

; -------------
; handle events
; -------------
widget_control, get_uvalue=uval, event.id

case uval of

    5: begin                    ; events in zoom skymap window
        handle_image_event, event, 1
    end

    43: begin                   ; expand / shrink button

        if(expanded_zoom) then begin
            shrink_zoom_window
        endif else begin
            expand_zoom_window
        endelse
        
    end

endcase

end

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; euv_imtool_event4 - full-frame window event handler
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
pro EUV_IMTOOL_event4,event

@euv_imtool-commons

; -------------
; handle events
; -------------
widget_control, get_uvalue=uval, event.id


case uval of

    40: begin                    ; events in full window
        handle_image_event, event, 2
    end

endcase

end
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; event handler for the start time dialog (this also
; does double (triple?) duty for the batch FITS file
; output start and stop time)
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
pro start_time_event,event

; -------------------------
; include the common blocks
; -------------------------
@euv_imtool-commons

; -------------
; handle events
; -------------
widget_control, get_uvalue=uval, event.id

case uval of
    9: begin                    ; quicklook data checkbox
        quicklook = event.select
    end

    10: begin                   ; OK
        widget_control, syearw,get_value=year1
        widget_control, sdoyw, get_value=doy1
        widget_control, shourw,get_value=hour1
        widget_control, sminw, get_value=minute1
        case ftime of
            0: begin
                check_time_limits,year1,doy1,hour1,minute1
            end
            1: begin
                yf1 = year1[0]
                df1 = doy1[0]
                hf1 = hour1[0]
                mf1 = minute1[0]
                jdf1 = calc_jd(yf1,df1,hf1,mf1,0,0)
            end
            2: begin
                yf2 = year1[0]
                df2 = doy1[0]
                hf2 = hour1[0]
                mf2 = minute1[0]
                jdf2 = calc_jd(yf2,df2,hf2,mf2,0,0)
            end
        endcase
        
        widget_control, /destroy, event.top
    end

    11: begin                   ; Cancel
        udf_load_canceled = 1
        widget_control, /destroy, event.top
    end

endcase

end

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; event handler for the background subtraction dialog
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
pro backsub_params_event,event

; -------------------------
; include the common blocks
; -------------------------
@euv_imtool-commons

; -------------
; handle events
; -------------
widget_control, get_uvalue=uval, event.id

case uval of
    9: begin                    ; de-band checkbox
        deband = event.select
    end

    10: begin                   ; OK
        widget_control, bminxw, get_value=bminxtemp
        widget_control, bmaxxw, get_value=bmaxxtemp
        widget_control, bminyw, get_value=bminytemp
        widget_control, bmaxyw, get_value=bmaxytemp
        bminx = bminxtemp[0]
        bmaxx = bmaxxtemp[0]
        bminy = bminytemp[0]
        bmaxy = bmaxytemp[0]
        if (bminx gt bmaxx) then begin
            tempx = bminx
            bminx = bmaxx
            bmaxx = tempx
        endif
        if (bminy gt bmaxy) then begin
            tempy = bminy
            bminy = bmaxy
            bmaxy = tempy
        endif

        subtract_back = 1
        widget_control, /destroy, event.top
    end

    11: begin                   ; Cancel
        subtract_back = 0
        widget_control, /destroy, event.top
    end

endcase

end

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; check the time limits that were input
; if OK, load the times
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
pro check_time_limits,y1,d1,h1,m1

@euv_imtool-commons

j1 = calc_jd(y1,d1,h1,m1,0.0,0.0)

    start_year   = y1[0]
    start_doy    = d1[0]
    start_hour   = h1[0]
    start_minute = m1[0]
    start_second = 0

end


; ---------------------------------
; event handler for the plot window
; ---------------------------------
pro plot_window_event,event

; -------------------------
; include the common blocks
; -------------------------
@euv_imtool-commons

; -------------
; handle events
; -------------


if (n_tags(event) gt 4) then begin ; motion, button press or expose event
    if(event.type eq 4) then redraw_views
endif else begin

widget_control, get_uvalue=uval, event.id
case uval of

    8: begin                    ; overlay stretched plot checkbox
        plot_stretch = event.select
        if(plot_stretch) then begin
            widget_control, mult_list, sensitive=1
            widget_control, mult_list_label, sensitive=1
            gen_plots, mouse_x, mouse_y, center_x, center_y,$
              mouse_l,mouse_mlt,from_zoom_win            
        end else begin
            widget_control, mult_list, sensitive=0
            widget_control, mult_list_label, sensitive=0
            az_plot_z -> SetProperty, hide=1
            rad_plot_z -> SetProperty, hide=1
            windowpa -> Draw, imviewPa
            windowpr -> Draw, imviewPr
        end

    end

    9: begin                    ; log scale checkbox
        ra_log_scale = event.select
        if(ra_log_scale) then begin
            widget_control, psw, sensitive=0
            widget_control, mult_list, sensitive=0
            widget_control, mult_list_label, sensitive=0
        end else begin
            widget_control, psw, sensitive=1
            widget_control, mult_list, sensitive=1
            widget_control, mult_list_label, sensitive=1
        end

        gen_plots, mouse_x, mouse_y, center_x, center_y,mouse_l,mouse_mlt,from_zoom_win
    end

    10: begin                   ; multiplier droplist
        reads,multiplier_choices(event.index),multiplier
        gen_plots, mouse_x, mouse_y, center_x, center_y,mouse_l,mouse_mlt,from_zoom_win
    end


    15: begin                   ; dump data button

        widget_control, dumpfilew, get_value=basef
        radfile = basef[0] + ".rad"
        azifile = basef[0] + ".azi"

        openw, azf, azifile, /get_lun
        for i=0,naz-1 do begin
            printf, azf, az[i],azbrite[i]
        endfor
        close, azf
        free_lun, azf

        openw, rdf, radfile, /get_lun
        for i=0,nrad-1 do begin
            printf, rdf, rad[i],radbrite[i]
        endfor
        close, rdf
        free_lun, rdf

    end

endcase

endelse


end

pro euv_imtool,xoffset=xoffset,udfdlm=udfdlm,batchsub=batchsub


@euv_imtool-commons

; -------------------------------------
; initialize the common block variables
; -------------------------------------
init_commons

; ---------------
; handle keywords
; ---------------
if (keyword_set(xoffset)) then user_xoff = xoffset else user_xoff = 0

; keyword indicating which UDF DLM is in use:
; = 0 indicates UDFToIDL developed by Chris Gurgiolo (default if keyword not set)
; = 1 indicates udf-dlm developed at LANL or its descendents
if (keyword_set(udfdlm))  then dlmflag = udfdlm else dlmflag=0
if (keyword_set(batchsub)) then batch_bkg_sub = 1

; --------------------------------
; set color table
; --------------------------------
red=intarr(256)
green=intarr(256)
blue=intarr(256)

TVLCT, red, green, blue, /GET
colorpalette= OBJ_NEW('IDLgrPalette', red, green, blue)

; ------------------------------------------------------
; load user's defaults, looking in the current directory
; if on a Unix/Linux system, look in $HOME also
; ------------------------------------------------------
found_defaults = 0
defaults_in_current = 0
if (!VERSION.OS_FAMILY eq 'unix') then udeffile = '.euv_imtool' else udeffile = 'euv_imtool.ini'

openr, udef, udeffile, ERROR=err, /get_lun
if ( err eq 0) then begin
    read_defaults, udef
    close, udef
    free_lun, udef
    found_defaults = 1
    defaults_in_current = 1
endif

if ((!VERSION.OS_FAMILY eq 'unix') and not found_defaults) then begin
    udeffile = getenv('HOME') + '/' + '.euv_imtool'
    openr, udef, udeffile, ERROR=err, /get_lun
    if ( err eq 0) then begin
        read_defaults, udef
        close, udef
        free_lun, udef
        found_defaults = 1
    endif
endif

; --------------------------
; create the graphic objects
; --------------------------
create_objects

; ------------------
; create the widgets
; ------------------

; create some base widgets for layout control
wBase = widget_base(/col, xpad=10, ypad=10, title='IMAGE EUV Image Tool - '+VERSION,mbar=menubase)
wUpper = widget_base(wBase,/row)
wLower = widget_base(wBase,/column)
wBaseL = widget_base(wUpper,/column)
wBaseR = widget_base(wUpper,/column)

wBaseR0 = widget_base(wBaseR,/row)
wBaseR1 = widget_base(wBaseR,/row)
wBaseR2 = widget_base(wBaseR,/row)
wBaseR3 = widget_base(wBaseR,/row)
wBaseR4 = widget_base(wBaseR,/row)
wBaseR4l= widget_base(wBaseR4,/row)
wBaseR4r= widget_base(wBaseR4,/row,/nonexclusive)
wBaseR5 = widget_base(wBaseR,/row)
wBaseR6 = widget_base(wBaseR,/row)
wBaseR6l= widget_base(wBaseR6,/row)
wBaseR6r= widget_base(wBaseR6,/row,/nonexclusive)
wBaseR7 = widget_base(wBaseR,/row)
wBaseR8 = widget_base(wBaseR,/row)
wBaseR9 = widget_base(wBaseR,/row)

wSpot   = widget_base(wBaseR,/row)

; button for enabling/disabling zoomed display window
zoom_button = widget_button(wBaseR0,value="Show Zoomed Display ", uvalue=19)
zoom_on = 0

; button for enabling/disabling full frame display window
full_button = widget_button(wBaseR0,value="Show Full Frame Display ", uvalue=41)

; button for enabling/disabling contour plot overlay
contour_button = widget_button(wBaseR1,value="Overlay Contour Plot", uvalue=18)
overlay_contour = 0
overlay_contour3 = 0
widget_control, contour_button, sensitive=0

; button for enabling/disabling solar wind plots
sw_button = widget_button(wBaseR1,value="Show Solar Wind Plot", uvalue=42)
widget_control, sw_button, sensitive=0

; buttons for forward and backward browsing and forward seek
backward_button = widget_button(wBaseR2,value="<-- Browse", uvalue=21)
forward_button = widget_button(wBaseR2,value="Browse -->", uvalue=20)

forward_seek = widget_button(wBaseR2,value="Seek -->", uvalue=22)

; disable them until some UDF data is loaded
widget_control, forward_button, sensitive=0
widget_control, backward_button, sensitive=0
widget_control, forward_seek, sensitive=0

; button for enabling/disabling azimuthal and radial plots
plot_button = widget_button(wBaseR3, value="Enable Radial/Azimuthal Plots ", uvalue=29)
do_plots = 0
widget_control, plot_button, sensitive=0

; button for click recording
record_file   = widget_button(wBaseR4l, value="Record clicks", uvalue=30)
sort_file     = widget_button(wBaseR4r, value="sort by MLT", uvalue=31)
append_file   = widget_button(wBaseR4r, value="Append", uvalue=44)

widget_control, sort_file, set_button=sort_clicks
widget_control, append_file, set_button=append_to_record

widget_control, record_file,sensitive=0

; text entry for recording file name
wlabel = widget_label(wBaseR5,value="Output file:")
filew = widget_text(wBaseR5,value='',xsize=20,ysize=1,/editable)

; readouts for LOS
wlabel = widget_label(wBaseR6l,value="Line of Sight Quantities:")

cont_readout  = widget_button(wBaseR6r, value="continuous", uvalue=32)
widget_control, cont_readout, set_button=continuous_readout

wlabel = widget_label(wBaseR7,value="minimum L shell:")
minLw  = widget_text(wBaseR7,value='',xsize=6,ysize=1)
wlabel = widget_label(wBaseR8,value="Magnetic Local Time:")
mltw   = widget_text(wBaseR8,value='',xsize=6,ysize=1)
wlabel = widget_label(wBaseR9,value="Magnetic Longitude:")
mlnw   = widget_text(wBaseR9,value='',xsize=6,ysize=1)
wlabel = widget_label(wSpot,value="Spot (3x3) Average = ")
wspt   = widget_text(wSpot,value='',xsize=6,ysize=1)

; create draw widgets for the image display
wDraw = widget_draw(wBaseL,xsize=xdim2,ysize=ydim2, uvalue=4, $
                    graphics_level=2,retain=backingstore,$
                    /expose_events,/button_events,/motion_events,$
                    /tracking_events)

; more base widgets
wInfo = widget_base(wBaseL,/column)
wData = widget_base(wBaseR,/row)
wAuto = widget_base(wBaseR,/row)
wAutoC = widget_base(wAuto,/row,/nonexclusive)
wAutoB = widget_base(wAuto,/row)
wCenter = widget_base(wBaseR,/row)
wClear = widget_base(wBaseR,/row)
wTime = widget_base(wInfo,/row)
wPos0 = widget_base(wInfo,/row)
wPos1 = widget_base(wInfo,/row)
wPos2 = widget_base(wInfo,/row)
wPos3 = widget_base(wInfo,/row)
wPos4 = widget_base(wInfo,/row)
wPos5 = widget_base(wInfo,/row)
wFITS = widget_base(wLower,/row)
wStatus = widget_base(wLower,/row)

; create labeled text widgets for displaying various data values
wlabel = widget_label(wData,value='Data value = ')
readoutw = widget_text(wData,value=' ',xsize=18,ysize=1)

wlabel = widget_label(wTime,value='Midpoint Time (UT):')
midpointw = widget_text(wTime,value='',xsize=14,ysize=1)

wlabel = widget_label(wPos0,value="IMAGE spacecraft information:")
wlabel = widget_label(wPos1,value='Range (RE) to Earth center: ')
rangew = widget_text(wPos1,value='',xsize=6,ysize=1)

wlabel = widget_label(wPos2,value='Latitude')
imlatw = widget_text(wPos2,value='',xsize=6,ysize=1)
wlabel = widget_label(wPos2,value='Longitude')
imlonw = widget_text(wPos2,value='',xsize=6,ysize=1)
wLabel = widget_label(wPos2,value='(Geographic)')

wlabel  = widget_label(wPos3,value='Latitude')
immlatw = widget_text(wPos3,value='',xsize=6,ysize=1)
wlabel  = widget_label(wPos3,value='Longitude')
immlonw = widget_text(wPos3,value='',xsize=6,ysize=1)
wLabel = widget_label(wPos3,value='(Magnetic)')

wlabel = widget_label(wPos4,value='XYZ (GCI)')
imxw   = widget_text(wPos4,value='',xsize=6,ysize=1)
imyw   = widget_text(wPos4,value='',xsize=6,ysize=1)
imzw   = widget_text(wPos4,value='',xsize=6,ysize=1)

wlabel = widget_label(wPos5,value='XYZ  (SM)')
imxsmw   = widget_text(wPos5,value='',xsize=6,ysize=1)
imysmw   = widget_text(wPos5,value='',xsize=6,ysize=1)
imzsmw   = widget_text(wPos5,value='',xsize=6,ysize=1)

; ---------------------------------------------
; buttons relating to defining the Earth center
; ---------------------------------------------

autocheck   = widget_button(wAutoC, value="Auto Center", uvalue=33)
widget_control, autocheck, set_button=auto_center
widget_control, autocheck, sensitive=0

bias_choices=['-10','-9','-8','-7','-6','-5','-4','-3','-2','-1','0','1','2','3','4','5','6','7','8','9','10']
bias_label  = widget_label(wAutoB, value="Bias:")
bias_droplist=widget_droplist(wAutoB,uvalue=34,value=bias_choices)
widget_control, bias_droplist, set_droplist_select=cbias+10
widget_control, bias_droplist, sensitive=0

center_button = widget_button(wCenter,value="Define Center  ", uvalue=17)
defining_center = 0
widget_control, center_button, sensitive=0

keep_button = widget_button(wCenter, value="Keep Center?", uvalue=16)
keep_center = 0
widget_control, keep_button, sensitive=centered

; -----------------------------------------------------------
; button to clear markings (clicked points and center circle)
; from the image displays
; -----------------------------------------------------------
clear_button = widget_button(wClear,value="Clear marks", uvalue=23)
widget_control, clear_button, sensitive=0

; ---------------------------------------------
; create a widget to display the FITS file name
; ---------------------------------------------
wlabel = widget_label(wFITS,value='FITS File Loaded:')
fitsnamew  = widget_text(wFITS, value='',xsize=60,ysize=1)

; ------------------------------
; create a status display widget
; ------------------------------
wlabel = widget_label(wStatus,value='Program message:')
statw  = widget_text(wStatus, value='',xsize=60,ysize=1)

; ------------------
; create the menubar
; ------------------
mdesc = replicate( {flags:0, name:''}, 25)
mdesc.flags = [1,0,0,0,0,0,0,0,2,1,0,0,2,1,0,0,0,0,0,2,1,0,0,0,2]
mdesc.name = ['File','Load FITS files...','Load from UDF Data...',$
              'Export JPEG Image...',$
              'Export JPEG Image (Full Frame)...',$
              'Export FITS File...','Export FITS File (Full Frame)...','Save Settings','Quit',$
              'Operations','Subtract background...','Revert Image','Dump GSM...',$
              'Batch','Set start time...','Set stop time...','Make FITS files','Make FITS files (Full Frame)',$
              'Make IDL save file','Make IDL save file (full frame)',$
              'Options','Color Palette (main window)...',$
              'Color Palette (zoom window)...','Color Palette (full window)...','Color Palette (all windows)...']
pdmenu = cw_pdmenu(menubase,mdesc,/return_name, /mbar,uvalue=2,ids=menu_ids)

; ---------------------------------------------
; disable File menu outputitems initially
; ---------------------------------------------
widget_control, menu_ids[3], sensitive=0
widget_control, menu_ids[4], sensitive=0
widget_control, menu_ids[5], sensitive=0
widget_control, menu_ids[6], sensitive=0

; ---------------------------------------------
; create the reference image for auto-centering
; ---------------------------------------------
create_ref_image

; ----------------------------
; make the application visible
; ----------------------------
widget_control, /realize, wBase

; ------------------------------------------
; get window object references for future use
; ------------------------------------------
widget_control, wDraw, get_value=window

; ---------------------------------------
; create object trees and draw everything
; ---------------------------------------
create_trees

window -> Draw, imview
if(zoom_window_exists) then window3 -> Draw, imview3

; -----------------------------------------------
; register with XMANAGER and allow it to call the
; event handler when events arrive
; -----------------------------------------------

widget_control, wBase
xmanager, 'euv_imtool', wBase

return

end

