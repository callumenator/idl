pro sdi2k_dial_mapper, tlist, tcen, datestr, windfit, cirplot_settings
@sdi2kinc.pro

;---Set the parameter value scaling limits:
    parlimz = cirplot_settings.scale.yrange
    if cirplot_settings.scale.auto_scale then begin
       pv = [windfit.meridional_wind, windfit.zonal_wind]
       sv = sort(pv)
       nv = n_elements(sv)
       parlimz = [pv(sv(0.05*nv)), pv(sv(0.95*nv))]
    endif

;---Setup background and pen colors:
    if cirplot_settings.black_bgnd then begin
       bgnd      = host.colors.black
       pen_color = host.colors.white
    endif else begin
       bgnd      = host.colors.white
       pen_color = host.colors.black
    endelse
    erase, color=bgnd

    nx           = n_elements(zone_map(*,0))
    ny           = n_elements(zone_map(0,*))
    edge         = (nx < ny)/2

;---Setup the geometry:
    xsize = cirplot_settings.geometry.xsize
    ysize = cirplot_settings.geometry.ysize
    ptime = [2., 18.]
    mbox  = max([xsize, ysize])/2.
    angstep = (15.*cirplot_settings.scale.minute_step/60.)*!pi/180.
    cs    = 0.975*mbox/(1./(0.9*angstep) + 0.7)
    prad  = cs/(0.88*angstep)
    xcen  = xsize/2.
    ycen  = 0.57*ysize
    arrow, xcen, ycen, xcen, ycen+prad/4, $
	   color=pen_color, hsize=prad/25, thick=2
    arrow, xcen, ycen, xcen, ycen-prad/8, $
	   color=pen_color, hsize=prad/25, thick=2
    arrow, xcen, ycen, xcen+prad/8, ycen, $
	   color=pen_color, hsize=prad/25, thick=2
    arrow, xcen, ycen, xcen-prad/8, ycen, $
	   color=pen_color, hsize=prad/25, thick=2
    xyouts, xcen, ycen + prad/4 + prad/12, 'Sunward', alignment=0.5, $
		charsize=1.5, color=pen_color, /device
    xyouts, xcen, ycen - 0.5*prad, 'Magnetic Midnight', alignment=0.5, $
		charsize=1.8, color=pen_color, /device
    xyouts, xcen-prad/50, ycen - prad/20, 'Magnetic', alignment=1., $
		charsize=1.5, color=pen_color, /device
    xyouts, xcen+prad/50, ycen - prad/20, 'Pole', alignment=0., $
		charsize=1.5, color=pen_color, /device

    oldang  = -9e9

    for rec=(cirplot_settings.records(0) > 0), (cirplot_settings.records(1) < n_elements(windfit.vertical_wind)-1) do begin
        js2ymds, tcen(rec), yy, mm, dd, ss
        hourang = (15*(ss - 3600*cirplot_settings.scale.magnetic_midnight)/3600. - 90.)*!pi/180
        if (hourang - oldang) gt angstep then begin
            oldang = hourang
	    xx = (prad - 1.*cs)*cos(hourang) + xcen
	    yy = (prad - 1.*cs)*sin(hourang) + xcen
	    xyouts, xx, yy, tlist(rec), align=0.5, /device, color=pen_color, charthick=1, charsize=1.2
	    xx = prad*cos(hourang) + xcen
	    yy = prad*sin(hourang) + xcen
	    tvcircle, cs/2-1, xx, yy, host.colors.ash, thick=1
	    geo = {xcen: xx, ycen: yy, radius: cs/2., wscale: cirplot_settings.scale.yrange, $
		   perspective: 'Map', orientation: 'Magnetic Noon at Top'}
	    sdi2k_one_windplot, windfit, tcen, rec, geo, thick=1, color=pen_color, index_color=-1
	endif
    endfor

    scalestr = strcompress(string(cirplot_settings.scale.yrange, format='(i12)'), /remove_all) + ' m/s'
    arrow,  0.85*xsize - cs/4., 0.03*ysize, 0.85*xsize + cs/4., 0.03*ysize, hsize=cs/10, color=pen_color, thick=2, hthick=2
    xyouts, 0.85,  0.05, scalestr, align=0.5, /normal, color=pen_color, charthick=2, charsize=2
    xyouts, 0.015, 0.05, datestr, align=0., /normal, color=pen_color, charthick=2, charsize=2
    
end

