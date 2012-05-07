pro sdi2k_wind_mapper, tlist, tcen, datestr, windfit, windmap_settings
@sdi2kinc.pro

;---Set the parameter value scaling limits:
    parlimz = windmap_settings.scale.yrange
    if windmap_settings.scale.auto_scale then begin
       pv = [windfit.meridional_wind, windfit.zonal_wind]
       sv = sort(pv)
       nv = n_elements(sv)
       parlimz = [pv(sv(0.05*nv)), pv(sv(0.95*nv))]
    endif

;---Setup background and pen colors:
    if windmap_settings.black_bgnd then begin
       bgnd      = host.colors.black
       pen_color = host.colors.white
    endif else begin
       bgnd      = host.colors.white
       pen_color = host.colors.black
    endelse
    erase, color=bgnd

;---Figure out how big to make each individual sky map:
    xsize = windmap_settings.geometry.xsize
    ysize = windmap_settings.geometry.ysize
    count = windmap_settings.records(1) - windmap_settings.records(0) + 1.01
    cols  = 0
    repeat begin
       cols  = cols + 1
       wdt   = xsize/cols
       rows  = count/cols
       hgt   = rows*wdt
    endrep until hgt lt ysize - 120
    
    mtop  = 4
    ymarg = 24
    cs    = fix(xsize/cols - ymarg - mtop)

    for rec=(windmap_settings.records(0) > 0), (windmap_settings.records(1) < n_elements(windfit.vertical_wind)-1) do begin
        rr = rec - (windmap_settings.records(0) > 0)
	yy = ysize - fix(rr/cols)*(cs + ymarg+mtop) - (cs + ymarg + mtop) + 0.2*ymarg
        cy = ysize - fix(rr/cols)*(cs + ymarg+mtop) - cs/2 - mtop
	xx = (rr mod cols)*(cs + ymarg+mtop) + (cs + ymarg+mtop)/2
        tvcircle, cs/2-1, xx, cy, host.colors.ash, thick=1
        xyouts, xx, yy, tlist(rec), align=0.5, /device, color=pen_color, charthick=1, charsize=1.2
    endfor

    for rec=(windmap_settings.records(0) > 0), (windmap_settings.records(1) < n_elements(windfit.vertical_wind)-1) do begin
        rr = rec - (windmap_settings.records(0) > 0)
	yy = ysize - fix(rr/cols)*(cs + ymarg+mtop) - (cs + ymarg + mtop) + 0.2*ymarg
        cy = ysize - fix(rr/cols)*(cs + ymarg+mtop) - cs/2 - mtop
	xx = (rr mod cols)*(cs + ymarg+mtop) + (cs + ymarg+mtop)/2
	geo = {xcen: xx, ycen: cy, radius: cs/2., wscale: windmap_settings.scale.yrange, $
	       perspective: windmap_settings.perspective, orientation: windmap_settings.orientation}
        sdi2k_one_windplot, windfit, tcen, rec, geo, thick=1, color=pen_color, index_color=host.colors.red
    endfor

    ylo = convert_coord(50, 50, /device, /to_normal)
    yhi = convert_coord(50, 70, /device, /to_normal)


;---Add an orientation key:
    if windmap_settings.orientation ne 'Magnetic Noon at Top' then begin
       cx   = 0.95*xsize
       cy   = 0.07*ysize
       cr   = 0.05*xsize
       flip = 1
       if windmap_settings.perspective eq 'Map' then flip = -1
       tvcircle, cr/2, cx, cy+4, pen_color, thick=1
       xyouts, cx, cy + flip*cr/3.5, 'S', alignment=0.5, charsize=1, color=pen_color, /device
       xyouts, cx, cy - flip*cr/3.5, 'N', alignment=0.5, charsize=1, color=pen_color, /device
       xyouts, cx + cr/3.5, cy,      'E', alignment=0.5, charsize=1, color=pen_color, /device
       xyouts, cx - cr/3.5, cy,      'W', alignment=0.5, charsize=1, color=pen_color, /device
    endif

    scalestr = strcompress(string(windmap_settings.scale.yrange, format='(i12)'), /remove_all) + ' m/s'
    arrow, xsize/2. - cs/4., 0.03*ysize, xsize/2. + cs/4., 0.03*ysize, hsize=cs/10, color=pen_color, thick=2, hthick=2
    xyouts, 0.5,   ylo(1), scalestr, align=0.5, /normal, color=pen_color, charthick=2, charsize=2
    xyouts, 0.015, ylo(1), datestr,  align=0.,  /normal, color=pen_color, charthick=2, charsize=2
end
