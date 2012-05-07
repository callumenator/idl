
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; record_clicks - write the click file, calculating
;                 all quantities based on the clicked
;                 X,Y positions and the defined center
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 11-Sep-2003

pro record_clicks, minL, tp_maglon, mlt_look, spot_average, outfile

@euv_imtool-commons

minimuml = fltarr(nclicks)
mlt      = fltarr(nclicks)
mlon     = fltarr(nclicks)
pxa      = fltarr(nclicks)
pya      = fltarr(nclicks)
pza      = fltarr(nclicks)
spot     = fltarr(nclicks)

; --------------------------------
; run through all the calculations
; --------------------------------
for i=0,nclicks-1 do begin
    xx = xclick[i]
    yy = yclick[i]
    calc_look, xx, yy, minL, tp_maglon, mlt_look, spot_average, px, py, pz, 0
    minimuml[i] = minL
    mlt[i]      = mlt_look
    mlon[i]     = tp_maglon
    pxa[i]      = px
    pya[i]      = py
    pza[i]      = pz
    spot[i]     = spot_average

endfor

; ---------------------------------------------------------------------
; sort on magnetic local time to put the points into some kind of
; order
; ---------------------------------------------------------------------
if (sort_clicks) then isort = sort(mlt)

; --------------
; write the file
; --------------
openw, luout, outfile, /get_lun, append=append_to_record

for i=0,nclicks-1 do begin
    if (sort_clicks) then indx = isort[i] else indx = i
    printf, luout, mlon[indx], mlt[indx], minimuml[indx],pxa[indx],pya[indx],pza[indx],spot[indx],$
      get_midpoint(jd),$
      format='(f6.2,2x,f6.2,3x,f6.2,5x,f6.2,2x,f6.2,2x,f6.2,3x,f6.2,2x,a14)'

endfor

close, luout
free_lun, luout

end
