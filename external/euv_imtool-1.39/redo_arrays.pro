;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; redo_arrays - reload all image arrays after a change to the
;               working copies of the original data arrays.
;
; darrayl, darray3l - linear data arrays, used for data value 
;                     readout at the mouse cursor position.
;
; darray, darray3l  - logarithmic arrays used in the image
;                     displays.
;
; full              - logarithmic array used in the full
;                     window display.
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 19-Aug-2003

pro redo_arrays

@euv_imtool-commons

; ------------------
; main window arrays
; ------------------
darrayl = rebin(workarray[*,75:224],xdim2,ydim2)
darray  = alog10((darrayl+1.0) > 1.0)

; ------------------
; zoom window arrays
; ------------------
darray3l = rebin(workarray,xdim3,ydim3)
darray3  = alog10((darray3l+1.0) > 1.0)

; ------------------
; full window arrays
; ------------------
full = alog10((working_dmap+1.0) > 1.0)

end

