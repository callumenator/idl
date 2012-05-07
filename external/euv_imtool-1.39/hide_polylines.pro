;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; hide_polylines
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 7-Sep-2001

pro hide_polylines

@euv_imtool-commons

; ----------------
; redraw the views
; ----------------
azline2 -> SetProperty, hide=1
radline2 -> SetProperty, hide=1
azline3 -> SetProperty, hide=1
radline3 -> SetProperty, hide=1

end
