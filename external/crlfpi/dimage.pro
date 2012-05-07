pro dimage, pmode, ch, csize, ccolor, dd

COMMON Hdr_para, header, yy, mo, day, hh, mm, ss, stime, etime, $
       ch_a, ch_b, sum_a, sum_b, thld_a, thld_b
COMMON Dsp_para, window, dfname, d_err, dd_a, dd_b
COMMON Dat_dir, ddir

CASE pmode OF
   'crt': BEGIN
       ;; Display an image on a CRT
;       set_plot, 'X'
       set_plot, 'win'
    END

   'bw_ps': BEGIN
       ;; Make B&W ps-file
       set_plot, 'PS'
       device, bits_per_pixel=8, FILE=ddir+'idl.ps'
       loadct, 0
    END

    'color_ps': BEGIN
       ;; Make color ps-file
       set_plot, 'PS'
       device, /color, bits=8, FILE=ddir+'idl.ps', xsize=15.0, xoffset=3.0, ysize=15.0, yoffset=12.5
       loadct, 3
    END

    ELSE:

ENDCASE
;;
IF d_err EQ 0 THEN BEGIN
   IF ch EQ 'A' THEN BEGIN
      dd = poly_2d(dd_a,[[0,0],[512./500.,0]],[[0,480./500.],[0,0]],0,500,500)
      tvscl, hist_equal(bytscl(dd))
      xyouts, /norm, 0.025, 0.95, $
      '[A-ch] Thld : ' + thld_a + ' Sum : ' + sum_a, $
      charsize =2.0, color=ccolor
   ENDIF ELSE BEGIN
      dd = poly_2d(dd_b,[[0,0],[512./500.,0]],[[0,480./500.],[0,0]],0,500,500)
      tvscl, hist_equal(bytscl(dd))
      xyouts, /norm, 0.025, 0.95, $
      '[B-ch] Thld : ' + thld_b + ' Sum : ' + sum_b, $
      charsize =2.0, color=ccolor
   ENDELSE
   xyouts, /norm, 0.025, 0.025, $
   strmid(header, 0, 8) + ' ' + stime + ' - ' + etime, $
   charsize = 2.0, color=ccolor
ENDIF ELSE BEGIN
   dd(*, *) = 0
   tvscl, dd
   xyouts, /norm, 0.200, 0.500, '  NO DATA ', $
   charsize = 5.0, color=ccolor
ENDELSE
;;
IF pmode NE 'crt' THEN BEGIN
      device, /close
      set_plot, 'X'
ENDIF
;;
END


