pro sdi2k_wpar_plotter, tlist, tcen, datestr, resarr, windparplot_settings
@sdi2kinc.pro

    par     = windparplot_settings.parameter

;---Get an array of the required parameter values:
    nres = n_elements(resarr)
    yvals = resarr.(par)

;---Get a time array:
    deltime = resarr(nres-1).end_time - resarr(0).start_time
    timlimz = [resarr(0).start_time, resarr(nres-1).end_time]
    deltime = timlimz(1) - timlimz(0)
    timlimz = timlimz + 0.05*[-deltime, deltime]
    deltime = timlimz(1) - timlimz(0)

    if windparplot_settings.scale.auto_scale then parlimz = [min(yvals), max(yvals)] $
       else parlimz = windparplot_settings.scale.yrange
    tt = (resarr.start_time + resarr.end_time)/2.

;---Build the Y-axis title:
    ytit = tag_names(resarr(0))
    ytit = sentence_case(ytit(par))

;---And add units to the title if possible:
    unipar = where(strpos(tag_names(resarr(0)), 'UNITS_' + strupcase(ytit)) ge 0, nn)
    unitz  = ' '
    if nn gt 0 then unitz = ' [' + resarr(0).(unipar(0)) + ']'

    lamlab = '!4k!3=' + strcompress(string(host.operation.calibration.sky_wavelength, format='(f12.1)'), /remove_all) + ' nm'

    erase, color=host.colors.white

    plot, timlimz, parlimz, /noerase, color=host.colors.black, /nodata, /xstyle, /ystyle, $
          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=3, ythick=3, charsize=2, charthick=3, $
          title=host.operation.header.site + ': ' + dt_tm_mk(js2jd(0d)+1, tt(0), format='0d$-n$-Y$') + ', ' + lamlab, $
          ytitle=ytit + unitz
        ;  ytitle='Divergence [1000/s]'

			 deg_tik, timlimz, ttvals, nttix, minor, minimum=5
			 xtn = dt_tm_mk(js2jd(0d)+1, ttvals, format='h$')
			 axis, xaxis=0, xtickname=xtn, color=host.colors.black, xtitle='Time [Hours UT]', charsize=2., charthick=3, $
			       xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4
			 axis, xaxis=1, xtickname=replicate(' ', 30), color=host.colors.black, charsize=2., charthick=3, $
			       xminor=minor, xticks=nttix, xticklen=0.02, xtickv=ttvals, xthick=4

;    plot, timlimz, parlimz, /noerase, color=host.colors.black, /nodata, /xstyle, /ystyle, $
;          xticks=1, xtickname=[' ', ' '], xminor=1, xthick=2, ythick=2, charsize=2, charthick=2, $
;          title=host.operation.header.site + ': ' + dt_tm_mk(js2jd(0d)+1, tt(0), format='0d$-n$-Y$'), $
;          ytitle=ytit + unitz
;    timeaxis, jd=js2jd(0d)+1, color=host.colors.black, charsize=2., charthick=2, thick=2, title='Hours UT'

    if n_elements(yvals) lt 2 then return

    if size(yvals, /n_dimensions) eq 1 then begin
       oplot, tt, yvals, thick=1, color=host.colors.black
       oplot, tt, yvals, thick=1, color=host.colors.red, psym=1, symsize=0.25
    endif else begin
       for j=2,n_elements(yvals(*,0))-1 do begin
       	   cidx = host.colors.imgmin + (j/float(n_elements(yvals(*,0))) * (host.colors.imgmax - host.colors.imgmin)) mod (host.colors.imgmax - host.colors.imgmin)
           oplot, tt, yvals(j, *), thick=1, color=cidx
;           oplot, tt, yvals(j, *), thick=1, color=host.colors.black, psym=1, symsize=0.25
           oplot, tt, resarr.(par-1), thick=2, color=host.colors.black
           oplot, tt, resarr.(par-1), thick=4, color=host.colors.black, psym=1, symsize=0.25
       endfor
    endelse

;---Plot HWM model curves if required:

    if (windparplot_settings.parameter eq 3 or windparplot_settings.parameter eq 4) and windparplot_settings.hwm.plot_hwm then begin
       hwm_dll  = 'd:\users\conde\main\idl\hwm\nrlhwm93.dll'
       if not(file_test(hwm_dll)) then hwm_dll = 'c:\users\conde\main\idl\hwm\nrlhwm93.dll'
       nhwm     = 16
       hwm_vals = fltarr(nhwm)
       tmx       = findgen(nhwm)*deltime/(nhwm-1) + timlimz(0)
       sec   = 0.
       lat   = float(host.operation.header.latitude)
       lon   = float(host.operation.header.longitude)
       if lon lt 0 then lon = lon+360.
       f107  = float(windparplot_settings.hwm.f10pt7)
       alt   = float(windparplot_settings.hwm.hwm_height)
       f107a = f107
       ap    = fltarr(7)
       mass  = 48L
       t     = fltarr(2)
       d     = fltarr(8)
       delz  = 20.
       if alt lt 180. then delz = 10.
       if alt lt 115. then delz = 5.
       flags = fltarr(25) + 1; Control flags (see HWM-93 FORTRAN source code for usage)
       w     = fltarr(2)

       for idz=-1,1  do begin
	 for j=0,n_elements(hwm_vals)-1 do begin
	     yyddd  = long(dt_tm_mk(js2jd(0d)+1, tmx(j), format='doy$'))
; 	          yyddd  = dt_tm_mk(js2jd(0d)+1, tt(j), format='1991doy$')
	     js2ymds, tmx(j), yy, mm, dd, ss
	     ss     = float(ss)
	     lst    = ss/3600. + lon/15.
	     if lst lt 0  then lst = lst + 24.
	     if lst gt 24 then lst = lst - 24.
	     ap(0)  = windparplot_settings.hwm.ap
; 	          help, ss
; 	          print, yyddd, ss, lat, lon, lst, f107a, f107, ap, mass
		 zv = alt + idz*delz
             result = call_external(hwm_dll,'nrlhwm93', $
		                     yyddd, ss, zv, lat, lon, lst, f107a, f107, ap, flags,w)

	     hwm_vals(j) = w(4 - windparplot_settings.parameter)
; 	          print, t(1)
	     wait, 0.002
	 endfor
	 if ((zv ge 100. and zv le 260.) or alt lt 100.) and min(hwm_vals) gt parlimz(0) and max(hwm_vals) lt parlimz(1) then begin
	    thk = 1
	    if idz eq 0 then begin
	       thk = 2
;   	           oplot,  tmx, hwm_vals, thick=3, linestyle=1, color=host.colors.rose
	    endif

	    oplot,  tmx, hwm_vals, thick=thk, linestyle=1, color=host.colors.blue
	    aplab    = strcompress(string(windparplot_settings.hwm.ap,     format='(i8)'), /remove_all)
	    f107lab  = strcompress(string(windparplot_settings.hwm.f10pt7, format='(i8)'), /remove_all)
	    zlab     = strcompress(string(windparplot_settings.hwm.hwm_height, format='(i8)'), /remove_all)
	    hlab     = strcompress(string(zv, format='(i8)'), /remove_all)
	    hwm_lab = 'NRL-HWM93 model at ' + 'Ap=' + aplab + ', F10.7=' + f107lab
	    tm       = timlimz(0) + 0.97*deltime
	    ym       = parlimz(0) - 0.09*(parlimz(1) - parlimz(0))
	    t1       = timlimz(1) - 0.03*deltime
	    y1       = hwm_vals(n_elements(hwm_vals)-1) - (parlimz(1) -parlimz(0))*0.025
	    xyouts, tm, ym, hwm_lab, charsize=1.2, color=host.colors.blue, align=1
	    xyouts, t1, y1, hlab +' km', charsize=0.9, color=host.colors.blue, align=1
	 endif
	endfor
     endif

end
