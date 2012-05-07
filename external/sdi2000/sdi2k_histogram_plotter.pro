pro sdi2k_histogram_plotter, tlist, tcen, datestr, resarr, histplot_settings
@sdi2kinc.pro

    par   = histplot_settings.parameter
    zspec = histplot_settings.zones

    nz = total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1))

    zsel = 0
    if strpos(zspec, 'Zone') ge 0 then begin
       zsel = str_sep(zspec, ' ')
       zsel = fix(zsel(1))
    endif

;---Get an array of the required parameter values:
    nres = n_elements(resarr)
    yvals = resarr.(par)(zsel)
    if zspec eq 'Median' then begin
       for j=0,nres-1 do begin
           yvals(j) = median(resarr(j).(par))
       endfor
    endif
    if zspec eq 'All' then yvals = resarr.(par)
    
;---Build the X-axis title:
    xtit = tag_names(resarr(0))
    xtit = sentence_case(xtit(par))

;---And add units to the title if possible: 
    unipar = where(strpos(tag_names(resarr(0)), 'UNITS_' + strupcase(xtit)) ge 0, nn)
    unitz  = ' ' 
    if nn gt 0 then unitz = ' [' + resarr(0).(unipar(0)) + ']'

    if histplot_settings.scale.auto_scale then parlimz = [min(yvals), max(yvals)] $
       else parlimz = histplot_settings.scale.xrange

    h  = histogram(yvals, min=parlimz(0), $
                          max=parlimz(1), $
                        nbins=histplot_settings.scale.nbins)
    bs = (parlimz(1) - parlimz(0))/histplot_settings.scale.nbins
    bx = parlimz(0) + findgen(histplot_settings.scale.nbins)*bs + 0.5*bs
 
    erase, color=host.colors.white
 
    plot, parlimz, [0, 1.1*max(h)], /noerase, color=host.colors.black, /nodata, /xstyle, /ystyle, $
          xthick=2, ythick=2, charsize=2, charthick=2, $
          title=host.operation.header.site + ': ' + datestr, $
          xtitle=zspec + ' ' + xtit + unitz, ytitle='Occurrence Frequency'
    oplot, bx, h, color=host.colors.black, thick=2, psym=10
 
 
end  
