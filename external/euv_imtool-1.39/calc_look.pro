;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; calc_look.pro - calculate all look direction quantiteis
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 18-Aug-2003

pro calc_look, mx, my, minL, tp_maglon, mlt_look, spot_average, px, py, pz, from

@euv_imtool-commons

forward_function x_main_to_zoom,y_main_to_zoom,$
  x_main_to_full,y_main_to_full,x_zoom_to_main,y_zoom_to_main

if(from eq 2 and not click_in_full) then return


; set some things, depending on which window the event came from
case from of
    0: begin
        x_center = center_x2
        delta_y = center_y2 - (ydim2/2)
        xdimension = xdim2
        ydimension = ydim2
    end
    1: begin
        x_center = center_x3
        delta_y = center_y3 - (ydim3/2)
        xdimension = xdim3
        ydimension = ydim3
    end
    2: begin ; full window, turn on its side (conceptually) for these calcs
        x_center = center_full_y
        delta_y  = center_full_x - (mxdim/2)
        xdimension = mydim
        ydimension = mxdim
        mtemp = my
        my = mx
        mx = 139 - mtemp
    end
endcase

; ----------------------------
; determine the look direction
; ----------------------------
get_lookv,mx,my-delta_y,xdimension,ydimension,$
  [image_smx/EARTH_RADIUS,image_smy/EARTH_RADIUS,image_smz/EARTH_RADIUS],$
  [-image_smvx,-image_smvy, -image_smvz],n_overlap,x_center,lookv

; -----------------------------------------------
; calculate the minimum L along the line of sight
; -----------------------------------------------
result = get_min_l([double(image_smx/EARTH_RADIUS), double(image_smy/EARTH_RADIUS), $
                    double(image_smz/EARTH_RADIUS)], $
                   [double(lookv[0]), double(lookv[1]), double(lookv[2])], 0)

minL = result[0]
px = result[1]
py = result[2]
pz = result[3]

;sm_result  = [px, py, pz]
;gsm_result = transpose(t4)##sm_result
;print, gsm_result[0], gsm_result[1], gsm_result[2]

; --------------------------------------------------------
; calculate the magnetic longitude and magnetic local time
; --------------------------------------------------------
along = atan(py, px)
mlt_look = ((along + !PI) * !RADEG) / 15.0
if(mlt_look gt 24.0) then mlt_look = mlt_look - 24.0

tp_sm = [px,py,pz]
tp_mag = t5##t1##transpose(t2)##transpose(t3)##transpose(t4)##tp_sm
tp_maglon = atan(tp_mag[1],tp_mag[0]) * !RADEG
if (tp_maglon lt 0.0) then tp_maglon = tp_maglon + 360.0

; ------------------------------------------------------
; calculate a spot average, using zoomed array darray3l
; ------------------------------------------------------ 

y_addition = 0
if(not expanded_zoom) then y_addition = y_expand

if (from ge 0 and from le 1) then begin
    case from of
        0: begin
            mousex = x_main_to_zoom(mx)
            mousey = y_main_to_zoom(my) + y_addition
        end
        1: begin
            mousex = mx
            mousey = my + y_addition
        end
    endcase

    sminx = (mousex - 1) > 0
    smaxx = (mousex + 1) < (xdim3 - 1)
    sminy = (mousey - 1) > 0
    smaxy = (mousey + 1) < (ydim3 - 1)
    npix  = (smaxx-sminx+1) * (smaxy-sminy+1)
    spot_average = total(darray3l[sminx:smaxx,sminy:smaxy]) / float(npix)
endif else begin
    mousex = my
    mousey = mx
    sminx = (mousex - 1) > 0
    smaxx = (mousex + 1) < (mxdim - 1)
    sminy = (mousey - 1) > 0
    smaxy = (mousey + 1) < (mydim - 1)
    npix  = (smaxx-sminx+1) * (smaxy-sminy+1)
    spot_average = total(dmap[sminx:smaxx,sminy:smaxy]) / float(npix)
end


end
