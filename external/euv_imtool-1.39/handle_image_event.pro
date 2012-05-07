
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; handle_image_event - process a mouse event from 
;                      any of the image windows
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 5-Jan-2004

pro handle_image_event,event,from

; from = 0 - main window, 1 - zoom window, 2 - full window

@euv_imtool-commons

y_addition = 0
if(expanded_zoom) then y_addition = y_expand

if (n_tags(event) gt 4) then begin ; motion, button press or expose event

    case event.type of

        1: begin              ; button release (nothing to do for now)

        end

        2: begin                ; motion event
            case from of
                0: begin
                    val = darrayl[event.x,event.y]
                end
                1: begin
                    if(expanded_zoom) then val = darray3l[event.x,event.y] else val = darray3l[event.x,event.y+y_expand]
                end
                2: begin
                    val = 10.0 ^ full[event.x,event.y] - 1.0
                end
            endcase

            if (centered and from eq 2) then begin
                calc_radec, event.x, event.y, ra, dec
                widget_control, w_ra,  set_value=string(ra,format='(f6.2)')
                widget_control, w_dec, set_value=string(dec,format='(f6.2)')
            endif


            widget_control,readoutw, $
              set_value=STRING(event.x,event.y,val,$
                               FORMAT='(i3.3,":",i3.3,5x,i6)')
            if(centered and continuous_readout and from ne 2) then begin
                calc_look, event.x, event.y, minL, tp_maglon, mlt_look, spot_average,px, py, pz, from
                set_los_readouts, minL, tp_maglon, mlt_look, spot_average, 1
            endif
            if(defining_center) then draw_center_ellipse,event.x,event.y, from, 0
            redraw_views
        end

        4: begin                ; expose event
            redraw_views
        end

        0: begin                ; mouse button press

            case event.press of

                4: begin        ; right button press
                    if (nclicks gt 0) then delete_click_point,event.x, event.y, from
                end

                2: begin        ; middle button press
                end

                1: begin        ; left button press

                    if (defining_center) then begin ; center definition
                        display_status, string(event.x,event.y,format='("Recentering at ",I4,2x,I4)')
                        case from of
                            0: begin
                                center_x2 = event.x
                                center_y2 = event.y
                                center_x3 = fix((center_x2 / 2.0) * 3.0 + 0.5)
                                center_y3 = fix((center_y2 / 2.0) * 3.0 + 0.5) + y_addition
                            end
                            1: begin
                                center_x3 = event.x
                                center_y3 = event.y
                                center_x2 = fix((center_x3 / 3.0) * 2.0 + 0.5)
                                center_y2 = fix(((center_y3-y_addition) / 3.0) * 2.0 + 0.5)
                            end
                            2: begin
                                center_x_full = event.x
                                center_y_full = event.x
                            end
                        endcase

                        center_full_x = dtstart + xoff + fix(center_y2/2.0)
                        center_full_y = 139 - fix(center_x2/2.0)

                        gen_mtrans

                        draw_center_ellipse, event.x, event.y, from, 1
                        widget_control, keep_button, sensitive=1
                        widget_control, plot_button, sensitive=1
                        centered = 1
                        defining_center = 0
                        redraw_views

                    endif else begin ; define click point or radial/azimuthal plot
                        if( (not centered) and (not warned) ) then begin
                            result = dialog_message(warning)
                            warned = 1
                        endif

                        if(centered) then begin
                            calc_look, event.x, event.y, minL, tp_maglon, mlt_look, spot_average,px, py, pz, from
                            set_los_readouts, minL, tp_maglon, mlt_look, spot_average, 1
                            if (not plot_window_exists and not do_plots) then add_click_point, event.x, event.y, from
                        endif

                        if (do_plots) then begin
                            if ( not plot_window_exists ) then create_plot_window
                            gen_plots, event.x, event.y, center_x2, center_y2, minL, mlt_look,from
                        endif

                    endelse
                end
            endcase

            
                                ; redisplay data readout after click
            case from of
                0: begin
                    val = darrayl[event.x,event.y]
                end
                1: begin
                    val = darray3l[event.x,event.y]
                end
                2: begin
                    val = 10.0 ^ full[event.x,event.y] - 1.0
                end
            endcase
            widget_control,readoutw, $
              set_value=STRING(event.x,event.y,val,FORMAT='(i3.3,":",i3.3,5x,i6)')
        end
    endcase

endif else begin                ; tracking event

    if(event.enter eq 0) then begin
        widget_control, readoutw, set_value=''
        set_los_readouts, minL, tp_maglon, mlt_look, spot_average, 0
        redraw_views
    end
    if(event.enter eq 0 and from eq 2) then begin
        widget_control, w_ra,  set_value=""
        widget_control, w_dec, set_value=""
;;        widget_control, fullreadoutw, set_value=""
        redraw_views
    end

endelse

end
