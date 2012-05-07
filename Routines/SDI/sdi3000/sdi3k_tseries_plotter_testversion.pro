pro sdi3k_tseries_plotter, tlist, tcen, mm, resarr, tsplot_settings, culz, sigma_name=signame, units_name=unitname, no_errors=no_errors

    par   = where(tag_names(resarr(0)) eq strcompress(strupcase(tsplot_settings.parameter), /remove_all))
    zspec = tsplot_settings.zones
    nz    = n_elements(resarr(0).(par))

;---Determine if individual zones have been specified. Format is zone 1[,2,3] etc
    zsel = 0
    if strpos(strupcase(zspec), 'ZONE') ge 0 then begin
       zarg = str_sep(zspec, ' ')
       if strpos(zarg(1), ',') lt 0 then zsel = fix(zarg(1)) else begin
          zarg = str_sep(zarg(1), ',')
          zsel = fix(zarg)
       endelse
    endif

;---Get an array of the required parameter values:
    nres = n_elements(resarr)
    yvals = resarr.(par)(zsel)
    if n_elements(zsel) gt 1 then begin
       if zspec eq 'Median' then zsel = indgen(n_elements(resarr(0).(par)))
       for j=0,nres-1 do begin
           yvals(j) = median(resarr(j).(par)(zsel))
       endfor
    endif
    if zspec eq 'All' then yvals = resarr.(par)


;---Get a time array:
    deltime = resarr(nres-1).end_time - resarr(0).start_time
    timlimz = resarr(0).start_time + [tsplot_settings.scale.time_range(0)*deltime, tsplot_settings.scale.time_range(1)*deltime]
    deltime = timlimz(1) - timlimz(0)
    timlimz = timlimz + 0.05*[-deltime, deltime]
    deltime = timlimz(1) - timlimz(0)
    if tsplot_settings.scale.auto_scale then parlimz = [min(yvals), max(yvals)] $
       else parlimz = tsplot_settings.scale.yrange
    tt = (resarr.start_time + resarr.end_time)/2.

;---Build the Y-axis title:
    ytit = tag_names(resarr(0))
    ytit = sentence_case(ytit(par))

;---And add units to the title if possible:
    unipar = where(strpos(tag_names(resarr(0)), 'UNITS_' + strupcase(ytit)) ge 0, nn)
    unitz  = ' '
    if keyword_set(unitname) then begin
       nn = 1
       unipar = where(strpos(tag_names(resarr(0)), unitname) ge 0, nn)
    endif
    if nn gt 0 then unitz = ' [' + resarr(0).(unipar(0)) + ']'

;---Get an array of parameter uncertainties, if available:
    errpar = where(strpos(tag_names(resarr(0)), 'SIGMA_' + strupcase(ytit)) ge 0, nsig)
    if keyword_set(signame) then begin
       nsig = 1
       errpar = where(strpos(tag_names(resarr(0)), signame) ge 0, nn)
    endif
    if nsig gt 0 then begin
       sigvals = resarr.(errpar(0))(zsel)
;       if zspec eq 'Median' then begin
        if n_elements(zsel) gt 1 then begin
          for j=0,nres-1 do begin
;              sigvals(j) = median(resarr(j).(errpar(0)))
               sigvals(j) = 2.*stddev(resarr(j).(par)(zsel))/sqrt(n_elements(zsel))
          endfor
       endif
    endif
    if zspec eq 'All' and nsig gt 0 then sigvals = resarr.(errpar(0))

    erase, color=culz.white
    lamlab  = '!4k!3=' + strcompress(string(mm.wavelength_nm, format='(f12.1)'), /remove_all) + ' nm'

    plot, timlimz, parlimz, /noerase, color=culz.black, /nodata, /xstyle, /ystyle, $
          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=tsplot_settings.style.axis_thickness, ythick=tsplot_settings.style.axis_thickness, $
          charsize=tsplot_settings.style.charsize, charthick=tsplot_settings.style.charthick, $
          title = mm.site + ': ' + dt_tm_mk(js2jd(0d)+1, mm.start_time(0), format='0d$-n$-Y$') + ', ' + lamlab, $
          ytitle=zspec + ' ' + ytit + unitz

          deg_tik, timlimz, ttvals, nttix, minor, minimum=5
          ttvals   = ttvals + 20.
          xttl     = 'Time [Hours UT]'
          tick_fmt = 'h$'
          if max(timlimz) - min(timlimz) lt  5L*3600L then tick_fmt = 'h$:m$'
          if max(timlimz) - min(timlimz) gt 48L*3600L then begin
             tick_fmt = 'n$-0d$'
             xttl     = 'UT Date'
          endif

          xtn = dt_tm_mk(js2jd(0d)+1, ttvals, format=tick_fmt)

          axis, xaxis=0, xtickname=xtn, color=culz.black, xtitle=xttl, charsize=tsplot_settings.style.charsize, charthick=tsplot_settings.style.charthick, $
                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
          axis, xaxis=1, xtickname=replicate(' ', 30), color=culz.black, charsize=tsplot_settings.style.charsize, charthick=tsplot_settings.style.charthick, $
                xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4


    if n_elements(yvals) lt 2 then return

    if zspec ne 'All' then begin
       oplot, tt, yvals, thick=1, color=culz.ash
       if nsig gt 0 then begin
          !p.color = culz.blue
;          oploterr, tt, yvals, sigvals, 3
           if keyword_set(no_errors) then sigvals = sigvals*0.0001
           mc_oploterr, tt, yvals, sigvals/2., thick=tsplot_settings.style.line_thickness, $
           bar_color=culz.blue, line_color=culz.black, errthick=tsplot_settings.style.line_thickness, $
           psym=3, symbol_color=culz.red
       endif
       oplot, tt, yvals, thick=tsplot_settings.style.line_thickness, color=culz.red, psym=1, symsize=tsplot_settings.style.charsize/10
    endif else begin
       linevals = fltarr(nres)
       for j=0,nres-1 do begin
           linevals(j) = median(resarr(j).(par))
       endfor

       for j=0,nres-1 do begin
       for k=0,nz-1 do begin
           clr = culz.imgmin + float(k)*(culz.imgmax - culz.imgmin - 2)/nz
           ;oplot, replicate(tt(j), nz), yvals(*,j), color=clr, psym=1, symsize=0.3, thick=1
           plots, tt(j), yvals(k,j), color=clr, psym=1, symsize=0.3, thick=tsplot_settings.style.line_thickness, clip=[timlimz(0), parlimz(0), timlimz(1), parlimz(1)], noclip=0
       endfor
       endfor
;           oplot, tt, resarr.(par)(0), color=culz.red, thick=tsplot_settings.style.line_thickness/2., clip=[timlimz(0), parlimz(0), timlimz(1), parlimz(1)], noclip=0
           oplot, tt, linevals, color=culz.black, thick=tsplot_settings.style.line_thickness, clip=[timlimz(0), parlimz(0), timlimz(1), parlimz(1)], noclip=0, linestyle=2
;           xyouts, 0.12, 0.03, 'Solid Red: Zone 0,', color=host.colors.red,  align=0, charsize=tsplot_settings.style.charsize/2., /normal
           xyouts, 0.13, 0.03, 'Dashed Black: Median', color=culz.black, align=0, charsize=1.5, /normal
    endelse

    if strupcase(tsplot_settings.parameter) eq 'TEMPERATURE' and tsplot_settings.msis.plot_msis then begin
       msis_dll  = 'c:\Documents and Settings\mark_con\My Documents\IDL\msis\Idlmsis.dll'
       if not(file_test(msis_dll)) then msis_dll = 'c:\users\conde\main\idl\msis\idlmsis.dll'
       if not(file_test(msis_dll)) then msis_dll = 'd:\users\conde\main\idl\msis\idlmsis.dll'
       nmsis     = 16L*(max(timlimz) - min(timlimz))/86400L + 8
       msis_vals = fltarr(nmsis)
       tmx       = findgen(nmsis)*deltime/(nmsis-1) + timlimz(0)
       sec   = 0.
       lat   = mm.latitude
       lon   = mm.longitude
       if lon lt 0 then lon = lon+360.
       f107  = float(tsplot_settings.msis.f10pt7)
       alt   = float(tsplot_settings.msis.msis_height)
       f107a = f107
       ap    = fltarr(7)
       mass  = 48L
       t     = fltarr(2)
       d     = fltarr(8)
       delz  = 20.
       if alt lt 180. then delz = 10.
;       if alt lt 130. then delz = 5.

       for idz=-8,8  do begin
         for j=0,n_elements(msis_vals)-1 do begin
             yyddd  = long(dt_tm_mk(js2jd(0d)+1, tmx(j), format='doy$'))
;             yyddd  = dt_tm_mk(js2jd(0d)+1, tt(j), format='1991doy$')
             js2ymds, tmx(j), yy, mmm, dd, ss
             ss     = float(ss)
             lst    = ss/3600. + lon/15.
             if lst lt 0  then lst = lst + 24.
             if lst gt 24 then lst = lst - 24.
             ap(0)  = tsplot_settings.msis.ap
;             help, ss
;             print, yyddd, ss, lat, lon, lst, f107a, f107, ap, mass
                 zv = alt + idz*delz
             result = call_external(msis_dll,'msis90', $
                                     yyddd, ss, zv, lat, lon, lst, f107a, f107, ap, mass, d, t)
             msis_vals(j) = t(1)
;             print, t(1)
             wait, 0.002
         endfor
         if zv ge 100. and zv le 260. and min(msis_vals) gt parlimz(0) and max(msis_vals) lt parlimz(1) then begin
            thk = (tsplot_settings.style.line_thickness-2) > 1
            if idz eq 0 then begin
               thk = 2
;                  oplot,  tmx, msis_vals, thick=3, linestyle=1, color=host.colors.rose
            endif

            mthk     = 1
            dfrc     = 0.8


            oplot,  tmx, msis_vals, thick=thk, linestyle=1, color=culz.slate
            aplab    = strcompress(string(tsplot_settings.msis.ap,     format='(i8)'), /remove_all)
            f107lab  = strcompress(string(tsplot_settings.msis.f10pt7, format='(i8)'), /remove_all)
            zlab     = strcompress(string(tsplot_settings.msis.msis_height, format='(i8)'), /remove_all)
            hlab     = strcompress(string(zv, format='(i8)'), /remove_all)
            msis_lab = 'MSIS-90 model!C' + 'Ap=' + aplab + ', F10.7=' + f107lab
            tm       = timlimz(0) + 0.97*deltime
            ym       = parlimz(0) - 0.12*dfrc^2*(parlimz(1) - parlimz(0))
            t1       = timlimz(1) - 0.03*deltime
            y1       = msis_vals(n_elements(msis_vals)-1) - (parlimz(1) -parlimz(0))*0.030*dfrc
            xyouts, tm, ym, msis_lab, charsize=1.2, color=culz.slate, align=1, charthick=mthk
            xyouts, t1, y1, hlab +' km', charsize=((tsplot_settings.style.charsize - 4) > 1), color=culz.slate, align=1, charthick=(tsplot_settings.style.charthick-1)>1
         endif
        endfor

    if zspec ne 'All' then begin
       oplot, tt, yvals, thick=1, color=culz.ash
       if nsig gt 0 then begin
          !p.color = culz.blue
          if not(keyword_set(no_errors)) then oploterr, tt, yvals, sigvals, 3
       endif
       oplot, tt, yvals, thick=1, color=culz.red, psym=1, symsize=0.25
    endif else begin
       for j=0,nres-1 do begin
       for k=0,nz-1 do begin
           clr = culz.imgmin + float(k)*(culz.imgmax - culz.imgmin - 2)/nz
;           oplot, replicate(tt(j), nz), yvals(*,j), color=clr, psym=1, symsize=0.3, thick=1
           plots, tt(j), yvals(k,j), color=clr, psym=1, symsize=0.3, thick=tsplot_settings.style.line_thickness
       endfor
       endfor
    endelse

    endif
end
