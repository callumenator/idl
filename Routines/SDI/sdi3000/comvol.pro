restore, 'C:\Users\Conde\Main\Latrobe\Mawson_FPS\Results\Common_volume\CommonVol_070622.dat'

;--I think Mawson UTs less than 10 might actually be those of the next day:
tomorrow    = where(maw_cv_ut lt 10.)
maw_cv_ut(tomorrow) = maw_cv_ut(tomorrow) + 24.
maw_cv_los  = maw_cv_los(sort(maw_cv_ut))
maw_cv_ut   = maw_cv_ut(sort(maw_cv_ut))
tomorrow    = where(maw_zen_ut lt 10.)
maw_zen_ut(tomorrow) = maw_zen_ut(tomorrow) + 24.
maw_zen_los = maw_zen_los(sort(maw_zen_ut))
maw_zen_ut  = maw_zen_ut(sort(maw_zen_ut))

;--Only interpolate in the time interval during which we have data from both sites:
mc_cv_ut = [dav_cv_ut, maw_cv_ut]
mc_cv_ut = mc_cv_ut(sort(mc_cv_ut))

lotime    = min(dav_cv_ut) > min(maw_cv_ut)
hitime    = max(dav_cv_ut) < max(maw_cv_ut)
keepers   = where(mc_cv_ut ge lotime and mc_cv_ut le hitime)
mc_cv_ut  = mc_cv_ut(keepers)

;--Interpote each site's data to each other's observation times:
mc_dav_cv_los = interpol(dav_cv_los, dav_cv_ut, mc_cv_ut)
mc_maw_cv_los = interpol(maw_cv_los, maw_cv_ut, mc_cv_ut)

;--Setup and then invert the view direction matrix:
viewmat = fltarr(2,2)
viewmat(0,0) =  sin(!dtor*maw_cv_zenang)
viewmat(1,0) =  cos(!dtor*maw_cv_zenang)
viewmat(0,1) = -sin(!dtor*dav_cv_zenang)
viewmat(1,1) =  cos(!dtor*dav_cv_zenang)
viewmat      =  invert(viewmat)

;--Comput the horizontal and vertical wind at the common volume point:
cv_vx = fltarr(n_elements(mc_cv_ut))
cv_vz = fltarr(n_elements(mc_cv_ut))
for j=0,n_elements(mc_cv_ut)-1 do begin
    cv_vvec  = viewmat##[mc_maw_cv_los(j), mc_dav_cv_los(j)]
    cv_vx(j) = cv_vvec(0)
    cv_vz(j) = cv_vvec(1)
endfor

;--For some reason, we get an offset in the compute CV_VZ. Subtract a linear background:
cfs = linfit(mc_cv_ut, cv_vz, yfit=yf)
;cv_vz = cv_vz - yf

;--Now start plotting:
load_pal, culz
while !d.window gt 0 do wdelete, !d.window
window, xsize=1800, ysize=1200
erase, color=culz.white

lotime = min([dav_cv_ut, dav_zen_ut, maw_cv_ut, maw_zen_ut]) - 0.5
hitime = max([dav_cv_ut, dav_zen_ut, maw_cv_ut, maw_zen_ut]) + 0.5

    !p.position = [0.14, 0.65, 0.88, 0.93]
    plot,        [lotime, hitime], [0,0], /noerase, color=culz.black, xthick=3, ythick=3, thick=2, charthick=2, charsize=1.8, $
                 xticks=1, xtickname=[' ', ' '], xminor=1, $
                 ytitle='DAVIS LOS!C !CSpeed / m s!U-1!N', yrange=[-223,223], /ystyle, /nodata, /xstyle
    oplot, [lotime, hitime], [0,0], color=culz.ash, linestyle=2
    dt    = fltarr(n_elements(mc_cv_ut))
    for j=0,n_elements(mc_cv_ut)-1 do begin
        dt(j) = min(abs(mc_cv_ut(j) - dav_cv_ut))
    endfor
    fills = where(dt ge 0.002)
    oplot, mc_cv_ut(fills), mc_dav_cv_los(fills), color=culz.olive, thick=2, psym=4
    mc_oploterr, dav_cv_ut, dav_cv_los, dav_cv_err, bar_color=culz.ash, thick=2, symbol_color=culz.black, line_color=culz.slate, /two, psym=6, symsize=.8

    !p.position = [0.14, 0.37, 0.88, 0.65]
    plot,        [lotime, hitime], [0,0], /noerase, color=culz.black, xthick=3, ythick=3, thick=2, charthick=2, charsize=1.8, $
                 xticks=1, xtickname=[' ', ' '], xminor=1, $
                 ytitle='MAWSON LOS!C !CSpeed / m s!U-1!N', yrange=[-223,223], /ystyle, /nodata, /xstyle
    oplot, [lotime, hitime], [0,0], color=culz.ash, linestyle=2
    dt    = fltarr(n_elements(mc_cv_ut))
    for j=0,n_elements(mc_cv_ut)-1 do begin
        dt(j) = min(abs(mc_cv_ut(j) - maw_cv_ut))
    endfor
    fills = where(dt ge 0.002)
    oplot, mc_cv_ut(fills), mc_maw_cv_los(fills), color=culz.olive, thick=2, psym=4
    mc_oploterr, maw_cv_ut, maw_cv_los, maw_cv_err, bar_color=culz.ash, thick=2, symbol_color=culz.black, line_color=culz.rose, /two, psym=6, symsize=.8

    !p.position = [0.14, 0.09, 0.88, 0.37]
    plot,        [lotime, hitime], [0,0], /noerase, color=culz.black, xthick=3, ythick=3, thick=2, charthick=2, charsize=1.8, $
                 xticks=1, xtickname=[' ', ' '], xminor=1, $
                 ytitle='VERTICAL!C !CSpeed / m s!U-1!N', yrange=[-163,163], /ystyle, /nodata, /xstyle
    oplot, [lotime, hitime], [0,0], color=culz.ash, linestyle=2
    mc_oploterr, dav_zen_ut, dav_zen_los, dav_zen_err, bar_color=culz.ash, thick=2, symbol_color=culz.black, line_color=culz.slate, /two, psym=6, symsize=.5
    mc_oploterr, maw_zen_ut, maw_zen_los, maw_zen_err, bar_color=culz.ash, thick=2, symbol_color=culz.black, line_color=culz.rose,  /two, psym=6, symsize=.5
    oplot, mc_cv_ut, cv_vz, thick=2, color=culz.olive
    oplot, derived_cv_ut, derived_cv_vert, thick=2, color=culz.orange
    oplot, mc_cv_ut, cv_vz - yf, thick=2, color=culz.black

    !p.position = [0.14, 0.09, 0.88, 0.93]
    plot,        [lotime, hitime], [0,0], /noerase, color=culz.black, xthick=3, ythick=3, thick=2, charthick=2, charsize=1.8, $
                 yticks=1, ytickname=[' ', ' '], yminor=1, $
                 xtitle='Time UT', /nodata, /xstyle

!p.position = 0
end