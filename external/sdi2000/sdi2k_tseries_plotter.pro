pro sdi2k_tseries_plotter, tlist, tcen, datestr, resarr, tsplot_settings
@sdi2kinc.pro

    ps    = !d.name eq 'PS'
    par   = tsplot_settings.parameter
    zspec = tsplot_settings.zones

    nz = total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1))

    zsel = 0
    if strpos(zspec, 'Zone') ge 0 then begin
       zsel = str_sep(zspec, ' ')
       zsel = fix(zsel(1))
    endif

    lamlab = '!4k!3=' + strcompress(string(host.operation.calibration.sky_wavelength, format='(f12.1)'), /remove_all) + ' nm'

;---Get an array of the required parameter values:
    nres = n_elements(resarr)
    yvals = resarr.(par)(zsel)
    if zspec eq 'Median' then begin
       for j=0,nres-1 do begin
           yvals(j) = median(resarr(j).(par))
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
    if nn gt 0 then unitz = ' [' + resarr(0).(unipar(0)) + ']'

;---Get an array of parameter uncertainties, if available:
    errpar = where(strpos(tag_names(resarr(0)), 'SIGMA_' + strupcase(ytit)) ge 0, nsig)
    if nsig gt 0 then begin
       sigvals = resarr.(errpar(0))(zsel)
       if zspec eq 'Median' then begin
          for j=0,nres-1 do begin
;              sigvals(j) = median(resarr(j).(errpar(0)))
               sigvals(j) = 2.*stddev(resarr(j).(par))/sqrt(nz)
          endfor
       endif
    endif
    if zspec eq 'All' and nsig gt 0 then sigvals = resarr.(errpar(0))

    erase, color=host.colors.white

    plot, timlimz, parlimz, /noerase, color=host.colors.black, /nodata, /xstyle, /ystyle, $
          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=3, ythick=3, charsize=2, charthick=3, $
          title=host.operation.header.site + ': ' + dt_tm_mk(js2jd(0d)+1, tt(0), format='0d$-n$-Y$') + ', ' + lamlab, $
          ytitle=zspec + ' ' + ytit + unitz
;    timeaxis, jd=js2jd(0d)+1, color=host.colors.black, charsize=2., charthick=3, thick=3, title='Hours UT'

			 deg_tik, timlimz, ttvals, nttix, minor, minimum=5
			 xtn = dt_tm_mk(js2jd(0d)+1, ttvals, format='h$')
			 axis, xaxis=0, xtickname=xtn, color=host.colors.black, xtitle='Time [Hours UT]', charsize=2., charthick=3, $
			       xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
			 axis, xaxis=1, xtickname=replicate(' ', 30), color=host.colors.black, charsize=2., charthick=3, $
			       xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4


    if n_elements(yvals) lt 2 then return

    if zspec ne 'All' then begin
       oplot, tt, yvals, thick=1, color=host.colors.ash
       if nsig gt 0 then begin
          !p.color = host.colors.blue
          oploterr, tt, yvals, sigvals, 3
       endif
       oplot, tt, yvals, thick=1, color=host.colors.red, psym=1, symsize=0.25
    endif else begin
       for j=0,nres-1 do begin
       for k=0,nz-1 do begin
           clr = host.colors.imgmin + float(k)*(host.colors.imgmax - host.colors.imgmin - 2)/nz
           ;oplot, replicate(tt(j), nz), yvals(*,j), color=clr, psym=1, symsize=0.3, thick=1
           plots, tt(j), yvals(k,j), color=clr, psym=1, symsize=0.3, thick=1, clip=[timlimz(0), parlimz(0), timlimz(1), parlimz(1)], noclip=0
       endfor
       endfor
    endelse
    
    if tsplot_settings.parameter eq 5 and tsplot_settings.msis.plot_msis then begin
       msis_dll  = 'd:\users\conde\main\idl\msis\idlmsis.dll'
       if not(file_test(msis_dll)) then msis_dll = 'c:\users\conde\main\idl\msis\idlmsis.dll'
       if not(file_test(msis_dll)) then msis_dll = 'e:\users\conde\main\idl\msis\idlmsis.dll'
       nmsis     = 16
       msis_vals = fltarr(nmsis)
       tmx       = findgen(nmsis)*deltime/(nmsis-1) + timlimz(0)
       sec   = 0.
       lat   = float(host.operation.header.latitude)
       lon   = float(host.operation.header.longitude)
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
; 	          yyddd  = dt_tm_mk(js2jd(0d)+1, tt(j), format='1991doy$')
  	         js2ymds, tmx(j), yy, mm, dd, ss
  	         ss     = float(ss)
  	         lst    = ss/3600. + lon/15.
  	         if lst lt 0  then lst = lst + 24.
  	         if lst gt 24 then lst = lst - 24.
  	         ap(0)  = tsplot_settings.msis.ap
; 	          help, ss
; 	          print, yyddd, ss, lat, lon, lst, f107a, f107, ap, mass
                 zv = alt + idz*delz
  	         result = call_external(msis_dll,'msis90', $
  	                                 yyddd, ss, zv, lat, lon, lst, f107a, f107, ap, mass, d, t)
  	         msis_vals(j) = t(1)
; 	          print, t(1)
  	         wait, 0.002
  	     endfor
  	     if zv ge 100. and zv le 260. and min(msis_vals) gt parlimz(0) and max(msis_vals) lt parlimz(1) then begin
  	        thk = 1
  	        if idz eq 0 then begin
  	           thk = 2
;   	           oplot,  tmx, msis_vals, thick=3, linestyle=1, color=host.colors.rose
   	        endif
   	        
   	        mthk     = 1 & if ps then mthk = 2
   	        dfrc     = 1 & if ps then dfrc = 1.5
   	        
  	           
   	        oplot,  tmx, msis_vals, thick=thk, linestyle=1, color=host.colors.red
  	        aplab    = strcompress(string(tsplot_settings.msis.ap,     format='(i8)'), /remove_all)
  	        f107lab  = strcompress(string(tsplot_settings.msis.f10pt7, format='(i8)'), /remove_all)
  	        zlab     = strcompress(string(tsplot_settings.msis.msis_height, format='(i8)'), /remove_all)
  	        hlab     = strcompress(string(zv, format='(i8)'), /remove_all)
  	        msis_lab = 'MSIS-90 model!C' + 'Ap=' + aplab + ', F10.7=' + f107lab
  	        tm       = timlimz(0) + 0.97*deltime
  	        ym       = parlimz(0) - 0.09*dfrc^2*(parlimz(1) - parlimz(0))
  	        t1       = timlimz(1) - 0.03*deltime
  	        y1       = msis_vals(n_elements(msis_vals)-1) - (parlimz(1) -parlimz(0))*0.030*dfrc
  	        xyouts, tm, ym, msis_lab, charsize=1.2, color=host.colors.red, align=1, charthick=mthk
  	        xyouts, t1, y1, hlab +' km', charsize=1.2, color=host.colors.red, align=1, charthick=mthk
  	     endif
        endfor
        
    if zspec ne 'All' then begin
       oplot, tt, yvals, thick=1, color=host.colors.ash
       if nsig gt 0 then begin
          !p.color = host.colors.blue
          oploterr, tt, yvals, sigvals, 3
       endif
       oplot, tt, yvals, thick=1, color=host.colors.red, psym=1, symsize=0.25
    endif else begin
       for j=0,nres-1 do begin
       for k=0,nz-1 do begin
           clr = host.colors.imgmin + float(k)*(host.colors.imgmax - host.colors.imgmin - 2)/nz
;           oplot, replicate(tt(j), nz), yvals(*,j), color=clr, psym=1, symsize=0.3, thick=1
           plots, tt(j), yvals(k,j), color=clr, psym=1, symsize=0.3, thick=1
       endfor
       endfor
    endelse        
        
    endif
end
