
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; calc-midpoint - return the Julian day corresponding to the
;                 midpoint of the combined image. This routine
;                 will return the correct time using either the
;                 original UDF data (with incorrect timestamps)
;                 of the Fall, 2002 revised data that corrected
;                 this problem.
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 25-Sep-2002

pro calc_midpoint,s0,s1,s2,mask

@euv_imtool-commons

m3 = 180.0d0 / 86400.0d0
m5 = 300.0d0 / 86400.0d0
m7 = 420.0d0 / 86400.0d0
m9 = 540.0d0 / 86400.0d0

if ((mask mod 2) ne 0) then begin ; skymap 0 present, use it

    if(s0.processing_flag[0] eq 1) then begin
        jd = load_jdate(s0.btime) + m7
    endif else begin
        jd = load_jdate(s0.btime) - m5
    endelse

endif else if (mask eq 4) then begin ; skymap 2 only, use it

    if(s2.processing_flag[0] eq 1) then begin
        jd = load_jdate(s2.btime) + m3
    endif else begin
        jd = load_jdate(s2.btime) - m9
    endelse

endif else begin ; otherwise, use skymap 1 time

    if(s1.processing_flag[0] eq 1) then begin
        jd = load_jdate(s1.btime) + m5
    endif else begin
        jd = load_jdate(s1.btime) - m7
    endelse

endelse

end
