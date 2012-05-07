pro mcpoly_filter, xseries, yseries, order=nord, lowpass=lp
    nx   = n_elements(yseries)
    if not(keyword_set(nord ))    then nord  = 7
    if nx lt nord + 1 then return

    xseries  = reform(xseries)
    yseries  = reform(yseries)
    xsave    = xseries
    ysave    = yseries

    yseries  = yseries(2:nx-3)
    nnx      = nx - 5

    yseries  = median([reverse(yseries), yseries, reverse(yseries)], 5)
    yseries  = yseries(nnx:nnx+nx-1)
    
    cfs      = polyfitw(dindgen(n_elements(yseries)), double(yseries), double(1./(0.5 + (yseries-median(yseries))^2)), 3, fy1)
    cfs      = polyfitw(dindgen(n_elements(yseries)), double(yseries), double(1./(0.5 + (yseries-median(yseries))^2)), 5, fy2)
    cfs      = polyfitw(dindgen(n_elements(yseries)), double(yseries), double(1./(0.5 + (yseries-median(yseries))^2)), nord, fy3)

;      set_plot, 'WIN'
;      plot, yseries, /ystyle, color=76
;      oplot, (fy1 + fy2 + fy3)/3., color=55



    if not(keyword_set(lp)) then begin
       yseries = ysave - (3*fy1 + 2*fy2 + fy3)/6.
    endif else begin
       yseries  = (3*fy1 + 2*fy2 + fy3)/6.
    endelse
    return
end