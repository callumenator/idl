pro sdi3k_dial_mapper, tlist, tcen, mm, windfit, cirplot_settings, culz, spekfits, zone_map, images=images, center=center, thick=thk

    use_images = 0

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
       bgnd      = culz.black
       pen_color = culz.white
    endif else begin
       bgnd      = culz.white
       pen_color = culz.black
    endelse
    erase, color=bgnd

    nx           = mm.columns
    ny           = mm.rows
    edge         = (nx < ny)/2

;---Setup the geometry:
    xsize = cirplot_settings.geometry.xsize
    ysize = cirplot_settings.geometry.ysize
    xcen  = xsize/2.
    ycen  = 0.5*xsize
    if keyword_set(center) then begin
       xcen = center(0)*xsize
       ycen = center(1)*ysize
    endif

    ptime = [2., 18.]
;    mbox  = max([xsize, ysize])/2.
    mbox  = 0.5*(max([xcen, ycen]) + max([xsize, ysize])/2.)
    angstep = (15.*cirplot_settings.scale.minute_step/60.)*!pi/180.
    cs    = 0.975*mbox/(1./(0.9*angstep) + 0.7)
    prad  = cs/(0.88*angstep)
    charscale = mbox/500.

    arrow, xcen, ycen, xcen, ycen+prad/4, $
       color=pen_color, hsize=prad/25, thick=2
    arrow, xcen, ycen, xcen, ycen-prad/8, $
       color=pen_color, hsize=prad/25, thick=2
    arrow, xcen, ycen, xcen+prad/8, ycen, $
       color=pen_color, hsize=prad/25, thick=2
    arrow, xcen, ycen, xcen-prad/8, ycen, $
       color=pen_color, hsize=prad/25, thick=2
    xyouts, xcen, ycen + prad/5 + prad/12, 'Sunward', alignment=0.5, $
       charsize=1.5*charscale, color=pen_color, /device, charthick=charscale
    xyouts, xcen, ycen - 0.7*prad, 'Magnetic Midnight', alignment=0.5, $
       charsize=1.8*charscale, color=pen_color, /device, charthick=charscale
    xyouts, xcen-prad/50, ycen + prad/15, 'Magnetic', alignment=1., $
       charsize=1.5*charscale, color=pen_color, /device, charthick=charscale
    xyouts, xcen+prad/50, ycen + prad/15, 'Pole', alignment=0., $
       charsize=1.5*charscale, color=pen_color, /device, charthick=charscale

    oldtime  = -9d9

;---Setup scaling and a mask for the useful area of the image:
    if n_elements(images) gt 2 and use_images then begin
       rad = shift(dist(cs, cs), cs/2, cs/2)
       outerz = where(rad gt cs/2)
       imvalz = images.scale
       imord  = sort(imvalz)
       imlo   = imvalz(imord(0.01*n_elements(imord)))
       imhi   = imvalz(imord(0.98*n_elements(imord)))
       imhi   = imhi + 0.1*(imhi - imlo)
;------Scaling method above doesn't work well for Mawson. Better to use the method below:
       smax = max(images.scale(1) - images.scale(0))
    endif


    tvlct, r, g, b, /get
    for rec=(cirplot_settings.records(0) > 0), (cirplot_settings.records(1) < n_elements(windfit.vertical_wind)-1) do begin
        js2ymds, tcen(rec), yy, mmm, dd, ss
        rotdir = 1
        if mm.latitude lt 0. then rotdir = -1
        hourang = rotdir*15*(ss - 3600*cirplot_settings.scale.magnetic_midnight)/3600.
;        hourang = (hourang - 90.)*!dtor - angstep/2
        hourang = (hourang - 90.)*!dtor
        if abs(tcen(rec) - oldtime)*15.*!dtor/3600. gt angstep then begin
            oldtime = tcen(rec)
        xx = (prad - 1.*cs)*cos(hourang) + xcen
        yy = (prad - 1.*cs)*sin(hourang) + xcen
        xyouts, xx, yy, tlist(rec), align=0.5, /device, color=pen_color, charsize=1.2*charscale, charthick=charscale
        xx = prad*cos(hourang) + xcen
        yy = prad*sin(hourang) + xcen
        rotang = rotdir*15.*(3600D*cirplot_settings.scale.magnetic_midnight - ss)/3600. - rotdir*mm.rotation_from_oval
        if mm.latitude lt 0 then rotang = rotang + 180
        if n_elements(images) gt 2 and use_images then begin
           sdi3k_read_netcdf_data, mm.file_name, metadata=mm, images=iimg, range=[spekfits(rec).record, spekfits(rec).record]
           img = congrid(reform(iimg(0).scene), cs, cs, cubic=0.5)
           img = culz.imgmin + bytscl(img, min=imlo, max=imhi, top=culz.imgmax - culz.imgmin - 1)
;           img = culz.imgmin + bytscl(img, min=iimg.scale(0), max=iimg.scale(0)+smax, top=culz.imgmax - culz.imgmin - 1)
           img = reverse(img, 2)
           img = rot(img, rotang)
           img(outerz) = 0
           tv, img, xx-cs/2, yy-cs/2, /device
        endif else begin
           indata  = [[spekfits(rec).temperature], [spekfits(rec).intensity], [spekfits(rec).temperature]]
           rgblimz = [[cirplot_settings.scale.rbscale], [cirplot_settings.scale.gscale] , [cirplot_settings.scale.pscale]]
           sdi3k_one_rgbmap, mm, cs, indata, rgblimz, zone_map, mapr, mapg, mapb, /map_view, azimuth_rotation=rotang
           loadct, 0, /silent
           oldimg = tvrd(/true)
           erase
           tv, [[[mapr]], [[mapg]], [[mapb]]], xx-cs/2, yy-cs/2, /device, true=3
           newimg = tvrd(/true)
           newimg = oldimg + newimg
           tv, newimg, /true
        endelse
        tvlct, r, g, b
        tvcircle, cs/2-1, xx, yy, culz.ash, thick=1
        geo = {xcen: xx, ycen: yy, radius: cs/2., wscale: cirplot_settings.scale.yrange, $
          perspective: 'Map', orientation: 'Magnetic Noon at Top'}
        sdi3k_one_windplot, windfit, tcen, rec, geo, mm, thick=thk, color=pen_color, index_color=-1, /no_project
    endif
    endfor

    lft = convert_coord(0.025, 0.20, /normal, /to_device)
;    yhi = convert_coord(50, 70, /device, /to_normal)
    scalestr = strcompress(string(cirplot_settings.scale.yrange, format='(i12)'), /remove_all) + ' m/s'
    arrow,  lft(0), lft(1), lft(0) + cs/2., lft(1), hsize=cs/10, color=pen_color, thick=2*charscale, hthick=2*charscale
    xyouts, 0.025, 0.16, scalestr, align=0., /normal, color=pen_color, charsize=2*charscale, charthick=charscale

    datestr = dt_tm_mk(js2jd(0d)+1, mm.start_time, format='Y$-n$-0d$')
    xyouts, 0.025, 0.08, datestr, align=0., /normal, color=pen_color, charsize=2*charscale, charthick=charscale

    ylo = convert_coord(50, 20, /device, /to_normal)
    datestr = dt_tm_mk(js2jd(0d)+1, mm.start_time, format='DOY doy$')
    xyouts, 0.025, 0.04, datestr, align=0., /normal, color=pen_color, charsize=2*charscale, charthick=charscale

    if n_elements(images) le 2 or ~(use_images) then begin
       rgb_vector = {red: 0.7*indgen(256) > 0, $
                   green: intarr(256), $
                    blue: 0.7*(255 - indgen(256)) > 0}

       mccolbar, [0.92, 0.80, 0.95, 0.95], 0, 255, rgblimz(0,0), rgblimz(1,0), $
              parname='', units='K', /both, $
              color=culz.white, thick=charscale, charsize=1.4*charscale, format='(i4)', $
              rgb_vector = rgb_vector

;       tprlab = 'Temperature: ' + strcompress(string(fix(rgblimz(0,0)), format='(i4)'), /remove_all) + 'K - ' + $
;                        strcompress(string(fix(rgblimz(1,0)), format='(i4)'), /remove_all) + 'K'
;       xyouts, 0.55,   0.95, tprlab, align=0.0, /normal, color=pen_color, charthick=2, charsize=2
    endif

end

