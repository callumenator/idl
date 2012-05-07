;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; set_contour_props - set contour plot properties
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 23-Aug-2002

pro set_contour_props

@euv_imtool-commons

if(cminval lt 1.0) then cminval = 1.0
if(cnlevels lt 1) then cnlevels = 8

contour  -> SetProperty, n_levels=cnlevels
contour  -> SetProperty, min_value= alog10(cminval), max_value=alog10(cmaxval)

contour3 -> SetProperty, n_levels=cnlevels
contour3 -> SetProperty, min_value= alog10(cminval), max_value=alog10(cmaxval)


end
