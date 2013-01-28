pro mcpoly_filter, xseries, yseries, order=nord, lowpass=lp
    nx   = n_elements(yseries)
    if not(keyword_set(nord ))    then nord  = 7
    if nx lt nord + 1 then return
    badz = where(~(finite((yseries))), nn)
    if nn gt 0 then return

    xseries  = reform(xseries)
    yseries  = reform(yseries)
    xsave    = xseries
    ysave    = yseries

    yseries  = yseries(1:nx-2)
    nnx      = nx - 3
    yseries  = median([reverse(yseries), yseries, reverse(yseries)], 3)
    yseries  = yseries(nnx:nnx+nx-1)


    xtm = dindgen(25*n_elements(yseries))
    xtm = xseries(0) + (xseries(nx-1) - xseries(0))*xtm/(n_elements(xtm))
    dt  = xtm(1) - xtm(0)
    yyy = interpol(yseries, xseries, xtm)
    yyy  = mc_im_sm(yyy, 4800./dt)
    yseries = interpol(yyy, xtm, xseries)
    yfit     = yseries

    goto, skip_poly

;    cfs      = polyfitw(dindgen(n_elements(yseries)), double(yseries), double(1./(0.5 + (yseries-median(yseries))^2)), 3, fy1)
;    cfs      = polyfitw(dindgen(n_elements(yseries)), double(yseries), double(1./(0.5 + (yseries-median(yseries))^2)), 5, fy2)
;    cfs      = polyfitw(dindgen(n_elements(yseries)), double(yseries), double(1./(0.5 + (yseries-median(yseries))^2)), nord, fy3)

    cfs      = poly_fit(dindgen(n_elements(yseries)), double(yseries), 3, fy1)
    cfs      = poly_fit(dindgen(n_elements(yseries)), double(yseries), 5, fy2)
    cfs      = poly_fit(dindgen(n_elements(yseries)), double(yseries), nord, fy3)
;    stop
;      set_plot, 'WIN'
;stop
    yfit = (1.*fy1 + 1.*fy2 + 12.*fy3)/14.
;    yfit = mc_im_sm(ysave, nx/15. > 7)
;      plot, yseries, /ystyle, color=76
;      oplot, yfit, color=55

skip_poly:
    if not(keyword_set(lp)) then begin
       yseries = ysave - yfit
    endif else begin
       yseries  = yfit
    endelse
    return
end