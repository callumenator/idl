pro sdi2k_scatter_plotter, tlist, tcen, datestr, resarr, scatplot_settings
@sdi2kinc.pro

    par   = scatplot_settings.parameter
    zspec = scatplot_settings.zones

    nz = total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1))
    
    zsel = 0
    if strpos(zspec, 'Zone') ge 0 then begin
       zsel = str_sep(zspec, ' ')
       zsel = fix(zsel(1))
    endif

;---Get arrays of the required parameter values:
    nres = n_elements(resarr)
    xvals = resarr.(par(0))(zsel)
    if zspec eq 'Median' then begin
       for j=0,nres-1 do begin
           xvals(j) = median(resarr(j).(par(zsel)))
       endfor
    endif
    if zspec eq 'All' then xvals = resarr.(par(zsel))
    yvals = resarr.(par(1))(zsel)
    if zspec eq 'Median' then begin
       for j=0,nres-1 do begin
           yvals(j) = median(resarr(j).(par(1)))
       endfor
    endif
    if zspec eq 'All' then yvals = resarr.(par(1))

;---Build the X-axis title:
    xlog=0
    xtit = tag_names(resarr(0))
    xtit = sentence_case(xtit(par(zsel)))
    if xtit eq 'Signal2noise' then begin
       xlog = 1
       xtit = 'Signal to noise ratio'
    endif

;---And add units to the xtitle if possible: 
    unipar = where(strpos(tag_names(resarr(0)), 'UNITS_' + strupcase(xtit)) ge 0, nn)
    xunitz  = ' ' 
    if nn gt 0 then xunitz = ' [' + resarr(0).(unipar(0)) + ']'

;---Build the Y-axis title:
    ylog=0
    ytit = tag_names(resarr(0))
    ytit = sentence_case(ytit(par(1)))
    if ytit eq 'Signal2noise' then begin
       ylog = 1
       ytit = 'Signal to noise ratio'
    endif

;---And add units to the ytitle if possible: 
    unipar = where(strpos(tag_names(resarr(0)), 'UNITS_' + strupcase(ytit)) ge 0, nn)
    yunitz  = ' ' 
    if nn gt 0 then yunitz = ' [' + resarr(0).(unipar(0)) + ']'
    
;---Setup plot ranges:
    if scatplot_settings.scale.auto_scale then begin
       xlimz = [min(xvals), max(xvals)] 
       ylimz = [min(yvals), max(yvals)] 
    endif else begin
       xlimz = scatplot_settings.scale.xrange
       ylimz = scatplot_settings.scale.yrange
    endelse
 
    erase, color=host.colors.white
    plot, reform(xvals), reform(yvals), /noerase, color=host.colors.black, /xstyle, /ystyle, $
          xthick=2, ythick=2, charsize=2.0, charthick=2, psym=1, symsize=0.3, $
          title=host.operation.header.site + ': ' + dt_tm_mk(js2jd(0d)+1, resarr(0).start_time, format='0d$-n$-Y$'), $
          xtitle=zspec + ' ' + xtit + xunitz, $
          ytitle=zspec + ' ' + ytit + yunitz, xlog=xlog, ylog=ylog, $
          xrange=xlimz, yrange=ylimz

end