pro sdi3k_histogram_plotter, tlist, tcen, resarr, mm, histplot_settings, culz

    par   = where(tag_names(resarr(0)) eq strcompress(strupcase(histplot_settings.parameter), /remove_all))
    zspec = histplot_settings.zones

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
                        binsize=abs(parlimz(1)-parlimz(0))/histplot_settings.scale.nbins)
    bs = (parlimz(1) - parlimz(0))/histplot_settings.scale.nbins
    bx = parlimz(0) + findgen(histplot_settings.scale.nbins)*bs + 0.5*bs

    erase, color=culz.white
    lamlab  = '!4k!3=' + strcompress(string(mm.wavelength_nm, format='(f12.1)'), /remove_all) + ' nm'
    plot, parlimz, [0, 1.1*max(h)], /noerase, color=culz.black, /nodata, /xstyle, /ystyle, $
          xthick=3, ythick=3, charsize=1.8, charthick=3, $
          title = mm.site + ': ' + dt_tm_mk(js2jd(0d)+1, mm.start_time(0), format='0d$-n$-Y$') + ', ' + lamlab, $
          xtitle=zspec + ' ' + xtit + unitz, ytitle='Occurrence Frequency'
    oplot, bx, h, color=culz.black, thick=2, psym=10


end
