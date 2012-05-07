pro sdi3k_scatter_plotter, mm, xresarr, yresarr, scatplot_settings, culz, xunits=xunits, yunits=yunits

    xpar   = where(tag_names(xresarr(0)) eq strcompress(strupcase(scatplot_settings.xpar), /remove_all))
    ypar   = where(tag_names(yresarr(0)) eq strcompress(strupcase(scatplot_settings.ypar), /remove_all))
    zspec = scatplot_settings.zones
    nz    = n_elements(xresarr(0).(xpar))

    zsel = 0
    if zspec eq 'All' then zsel = indgen(nz)
    if strpos(zspec, 'Zone') ge 0 then begin
       zsel = str_sep(zspec, ' ')
       zsel = fix(zsel(1))
    endif

;---Get an array of the required parameter values:
    xvals = xresarr.(xpar)(zsel)
    yvals = yresarr.(ypar)(zsel)

    nres = n_elements(xresarr)
    if zspec eq 'Median' then begin
       xvals = xresarr.(xpar)(0)
       yvals = yresarr.(ypar)(0)
       for j=0,nres-1 do begin
           xvals(j) = median(xresarr(j).(xpar))
           yvals(j) = median(yresarr(j).(ypar))
       endfor
    endif

;---Build the axis titles:
    xtit = tag_names(xresarr(0))
    xtit = sentence_case(xtit(xpar))
    ytit = tag_names(yresarr(0))
    ytit = sentence_case(ytit(ypar))

;---And add units to the axis titles if possible:
    if keyword_set(xunits) then xtit = xtit + ' [' + xunits + ']'
    if keyword_set(yunits) then ytit = ytit + ' [' + yunits + ']'

    erase, color=culz.white
    lamlab  = '!4k!3=' + strcompress(string(mm.wavelength_nm, format='(f12.1)'), /remove_all) + ' nm'
    if scatplot_settings.scale.auto_scale then xlimz = [min(xvals), max(xvals)] $
       else xlimz = scatplot_settings.scale.xrange
    if scatplot_settings.scale.auto_scale then ylimz = [min(yvals), max(yvals)] $
       else ylimz = scatplot_settings.scale.yrange

    plot, xlimz, ylimz, /noerase, color=culz.black, /nodata, /xstyle, /ystyle, $
          xthick=scatplot_settings.style.axis_thickness, ythick=scatplot_settings.style.axis_thickness, $
          charsize=scatplot_settings.style.charsize, charthick=scatplot_settings.style.charthick, $
          title = mm.site + ': ' + dt_tm_mk(js2jd(0d)+1, mm.start_time(0), format='0d$-n$-Y$') + ', ' + lamlab, $
          xtitle=zspec + ' ' + xtit, ytitle=zspec + ' ' + ytit

    if n_elements(xvals) lt 2 then return

    if zspec ne 'All' then begin
       oplot, xvals, yvals, thick=scatplot_settings.style.line_thickness, color=culz.red, psym=1, symsize=scatplot_settings.style.charsize/10
    endif else begin

       for j=0,nres-1 do begin
           for k=0,nz-1 do begin
               clr = culz.imgmin + float(k)*(culz.imgmax - culz.imgmin - 2)/nz
               plots, xvals(k,j), yvals(k,j), color=clr, psym=1, symsize=0.3, thick=scatplot_settings.style.line_thickness, clip=[xlimz(0), ylimz(0), xlimz(1), ylimz(1)], noclip=0
           endfor
       endfor
    endelse

end
