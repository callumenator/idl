
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; update color table for main and/or zoom window
; image displays.
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; originally created: 7-Sep-2000 by Martin Wuest, SwRI

; last modified: 7-Sep-2001

pro update_color_table

@euv_imtool-commons

;---------------------------------------------
; Define color arrays
;---------------------------------------------
red = INTARR(256)
green = INTARR(256)
blue = INTARR(256)

;---------------------------------------------
; get newest color table values
;---------------------------------------------

TVLCT, red, green, blue, /GET
colorpalette=OBJ_NEW('IDLgrPalette', red, green, blue)


;---------------------------------------------
; set new image color properties and redraw
;---------------------------------------------

case ct_update of
    0: begin
        image -> SetProperty, Palette=colorpalette
    end
    1: begin
        image3 -> SetProperty, Palette=colorpalette
    end
    2:begin
        image4 -> SetProperty, Palette=colorpalette
    end
    3:begin
        image -> SetProperty, Palette=colorpalette
        image3 -> SetProperty, Palette=colorpalette
        image4 -> SetProperty, Palette=colorpalette
    end

end

redraw_views

end
