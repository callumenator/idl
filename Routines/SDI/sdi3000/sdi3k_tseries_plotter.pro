function get_yvals, resarr, par, zspec, zsel=zsel

;---Get an array of the required parameter values:
        nz   = n_elements(resarr(0).(par))
        zsel = 0
        if strpos(strupcase(zspec), 'ZONE') ge 0 then begin
           zsel = str_sep(zspec, ' ')
           zsel = fix(zsel(1:*))
        endif
        if strpos(strupcase(zspec), 'ALL') ge 0 then zsel = findgen(n_elements(resarr(0).(par)))

        nres = n_elements(resarr)
        yvals = resarr.(par)(zsel)
        if strpos(strupcase(zspec), 'MEDIAN') ge 0 then begin
           for j=0,nres-1 do begin
               if nz gt 1 then yvals(j) = median(resarr(j).(par)) else yvals(j) = resarr(j).(par)
           endfor
        endif
        return, yvals
end

pro sdi3k_tseries_plotter, tlist, tcen, mm, resin, tsplot_settings, culz, $
                           sigma_name=signame, units_name=unitname, $
                           colors=colors, quality_filter=quality_filter, $
                           pastel=pastel, epoints=epoints, notitle=notitle

    resarr = resin

    if not(keyword_set(colors))         then colors = {bar_color: culz.blue, line_color: culz.black, symbol_color: culz.black}
    if not(keyword_set(quality_filter)) then quality_filter = {snr: 200., chisq: 2.2}
    if not(keyword_set(pastel))         then pastel = 0

    par   = where(tag_names(resarr(0)) eq strcompress(strupcase(tsplot_settings.parameter), /remove_all))
    zspec = tsplot_settings.zones
    nz    = n_elements(resarr(0).(par))
    nres  = n_elements(resarr)
    resarr = resarr(tsplot_settings.records(0):tsplot_settings.records(1))
    nres  = n_elements(resarr)

;---Get a time array:
    deltime = resarr(nres-1).end_time - resarr(0).start_time
    timlimz = resarr(0).start_time + [tsplot_settings.scale.time_range(0)*deltime, tsplot_settings.scale.time_range(1)*deltime]
    deltime = timlimz(1) - timlimz(0)
    timlimz = timlimz + 0.05*[-deltime, deltime]
    deltime = timlimz(1) - timlimz(0)

    ylo = 9e9
    yhi = -9e9
    for j=0,n_elements(zspec)-1 do begin
        yy  = get_yvals(resarr, par, zspec(j))
        xlo = min(yy)
        xhi = max(yy)
        ylo = min(ylo, xlo)
        yhi = max(yhi, xhi)
    endfor

    if tsplot_settings.scale.auto_scale then parlimz = [ylo, yhi] $
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

    erase, color=culz.white
    lamlab  = ' !4k!3=' + strcompress(string(mm.wavelength_nm, format='(f12.1)'), /remove_all) + ' nm'
    ttl = mm.site + ': ' + dt_tm_mk(js2jd(0d)+1, mm.start_time(0), format=date_form)  + lamlab
    if keyword_set(notitle) then ttl = ' '
    date_form = '0d$-n$-Y$'
    if abs(timlimz(1) - timlimz(0)) gt 86400L*1.5 then date_form = 'n$-Y$, '
    if abs(timlimz(1) - timlimz(0)) gt 86400L*32. then date_form = ' '

    for item=0,n_elements(zspec)-1 do begin
    yvals = get_yvals(resarr, par, zspec(item), zsel=zsel)
;---Get an array of parameter uncertainties, if available:
    errpar = where(strpos(tag_names(resarr(0)), 'SIGMA_' + strupcase(ytit)) ge 0, nsig)
    if keyword_set(signame) then begin
       nsig = 1
       errpar = where(strpos(tag_names(resarr(0)), signame) ge 0, nn)
    endif
    if nsig gt 0 then begin
       sigvals = resarr.(errpar(0))(zsel)
       if strpos(strupcase(zspec(item)), 'MEDIAN') ge 0 then begin
          for j=0,nres-1 do begin
;              sigvals(j) = median(resarr(j).(errpar(0)))
               sigvals(j) = 2.*stddev(resarr(j).(par))/sqrt(nz)
          endfor
       endif
    endif
    if zspec(item) eq 'All' and nsig gt 0 then sigvals = resarr.(errpar(0))

    plot, timlimz, parlimz, /noerase, color=culz.black, /nodata, /xstyle, /ystyle, $
          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=tsplot_settings.style.axis_thickness, ythick=tsplot_settings.style.axis_thickness, $
          charsize=tsplot_settings.style.charsize, charthick=tsplot_settings.style.charthick, $
          title = ttl, $
          ytitle=' '

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

    if keyword_set(epoints) then oplot, epoints.time, epoints.y, psym=epoints.psym, linestyle=epoints.style, color=epoints.color, thick=epoints.thick, symsize=epoints.symsize

    if n_elements(yvals) lt 2 then return

    if zspec(item) ne 'All' then begin
       oplot, tt, yvals, thick=1, color=culz.ash
       if nsig gt 0 then begin
          !p.color = culz.blue
;          oploterr, tt, yvals, sigvals, 3
           mc_oploterr, tt, yvals, sigvals/2., thick=tsplot_settings.style.line_thickness, $
           bar_color=colors.bar_color, line_color=colors.line_color, $
           psym=3, symbol_color=colors.symbol_color
       endif
       oplot, tt, yvals, thick=tsplot_settings.style.line_thickness, color=colors.symbol_color, psym=1, symsize=tsplot_settings.style.charsize/10
    endif else begin
       linevals = fltarr(nres)
       for j=0,nres-1 do begin
           linevals(j) = median(resarr(j).(par))
       endfor

       if pastel(item) ne 0 then pastel_palette, factor=pastel(item)

       for j=0,nres-1 do begin
       for k=0,nz-1 do begin
           clr = culz.imgmin + float(k)*(culz.imgmax - culz.imgmin - 2)/nz
           ;oplot, replicate(tt(j), nz), yvals(*,j), color=clr, psym=1, symsize=0.3, thick=1
           qalok = resarr(j).signal2noise(k) gt quality_filter.snr and resarr(j).chi_squared(k) lt quality_filter.chisq
           if qalok then plots, tt(j), yvals(k,j), color=clr, psym=1, symsize=0.3, thick=tsplot_settings.style.line_thickness, clip=[timlimz(0), parlimz(0), timlimz(1), parlimz(1)], noclip=0
       endfor
       endfor
       if pastel(item) ne 0 then pastel_palette, factor=-1./pastel(item)
;           oplot, tt, resarr.(par)(0), color=culz.red, thick=tsplot_settings.style.line_thickness/2., clip=[timlimz(0), parlimz(0), timlimz(1), parlimz(1)], noclip=0
           oplot, tt, linevals, color=culz.black, thick=tsplot_settings.style.line_thickness, clip=[timlimz(0), parlimz(0), timlimz(1), parlimz(1)], noclip=0, linestyle=2
;           xyouts, 0.12, 0.03, 'Solid Red: Zone 0,', color=host.colors.red,  align=0, charsize=tsplot_settings.style.charsize/2., /normal
;           xyouts, 0.13, 0.03, 'Dashed Black: Median', color=culz.black, align=0, charsize=1.5, /normal
    endelse

    if strupcase(tsplot_settings.parameter) eq 'TEMPERATURE' and tsplot_settings.msis.plot_msis and item eq n_elements(zspec)-1 then begin
       msis_dll  = 'c:\Documents and Settings\mark_con\My Documents\IDL\msis\Idlmsis.dll'
       if not(file_test(msis_dll)) then msis_dll = 'c:\users\conde\main\idl\msis\idlmsis.dll'
       if not(file_test(msis_dll)) then msis_dll = 'd:\users\conde\main\idl\msis\idlmsis.dll'
       if not(file_test(msis_dll)) then msis_dll = 'C:\cal\IDLSource\Code\msis\idlmsis.dll'
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
               thk = thk + 2
;                  oplot,  tmx, msis_vals, thick=3, linestyle=1, color=host.colors.rose
            endif

            mthk     = 1
            dfrc     = 0.8


            oplot,  tmx, msis_vals, thick=thk, linestyle=1, color=culz.red
            aplab    = strcompress(string(tsplot_settings.msis.ap,     format='(i8)'), /remove_all)
            f107lab  = strcompress(string(tsplot_settings.msis.f10pt7, format='(i8)'), /remove_all)
            zlab     = strcompress(string(tsplot_settings.msis.msis_height, format='(i8)'), /remove_all)
            hlab     = strcompress(string(zv, format='(i8)'), /remove_all)
            msis_lab = 'MSIS-90 model!C' + 'Ap=' + aplab + ', F10.7=' + f107lab
            tm       = timlimz(0) + 0.97*deltime
            ym       = parlimz(0) - 0.12*dfrc^2*(parlimz(1) - parlimz(0))
            t1       = timlimz(1) - 0.03*deltime
            y1       = msis_vals(n_elements(msis_vals)-1) - (parlimz(1) -parlimz(0))*0.030*dfrc
            xyouts, tm, ym, msis_lab, charsize=1.2, color=culz.red, align=1, charthick=mthk
            xyouts, t1, y1, hlab +' km', charsize=((tsplot_settings.style.charsize - 4) > 1.2), color=culz.red, align=1, charthick=(tsplot_settings.style.charthick-1)>1
         endif
        endfor

    if zspec(item) ne 'All' then begin
;       if colors.line_color ne culz.white then oplot, tt, yvals, thick=1, color=culz.ash
       if nsig gt 0 and colors.bar_color ne culz.white then begin
          !p.color = colors.bar_color
          oploterr, tt, yvals, sigvals, 3
       endif
       oplot, tt, yvals, thick=1, color=colors.symbol_color, psym=1, symsize=0.25
    endif else begin
       if pastel(item) ne 0 then pastel_palette, factor=pastel(item)
       for j=0,nres-1 do begin
       for k=0,nz-1 do begin
           clr = culz.imgmin + float(k)*(culz.imgmax - culz.imgmin - 2)/nz
;           oplot, replicate(tt(j), nz), yvals(*,j), color=clr, psym=1, symsize=0.3, thick=1
           qalok = resarr(j).signal2noise(k) gt quality_filter.snr and resarr(j).chi_squared(k) lt quality_filter.chisq
           if qalok then plots, tt(j), yvals(k,j), color=clr, psym=1, symsize=0.3, thick=tsplot_settings.style.line_thickness
       endfor
       endfor
       if pastel ne 0 then pastel_palette, factor=-1./pastel
       oplot, tt, linevals, color=culz.black, thick=tsplot_settings.style.line_thickness, clip=[timlimz(0), parlimz(0), timlimz(1), parlimz(1)], noclip=0, linestyle=2
    endelse

    endif
    endfor
    plot, timlimz, parlimz, /noerase, color=culz.black, /nodata, /xstyle, /ystyle, $
          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=tsplot_settings.style.axis_thickness, ythick=tsplot_settings.style.axis_thickness, $
          charsize=tsplot_settings.style.charsize, charthick=tsplot_settings.style.charthick, $
          title = ttl, $
          ytitle=zspec(item-1) + ' ' + ytit + unitz
end
