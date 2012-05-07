pro sdi3k_wind_mapper, tlist, tcen, mm, winds, windmap_settings, culz, spekfits, zone_map, cadence=cadence, images=images

use_images = 0

if not(keyword_set(cadence)) then cadence = 1

;---Set the parameter value scaling limits:
    parlimz = windmap_settings.scale.yrange
    if windmap_settings.scale.auto_scale then begin
       pv = [winds.meridional_wind, winds.zonal_wind]
       sv = sort(pv)
       nv = n_elements(sv)
       parlimz = [pv(sv(0.05*nv)), pv(sv(0.95*nv))]
    endif

;---Setup background and pen colors:
    if windmap_settings.black_bgnd then begin
       bgnd      = culz.black
       pen_color = culz.white
    endif else begin
       bgnd      = culz.white
       pen_color = culz.black
    endelse
    erase, color=bgnd

;---Figure out how big to make each individual sky map:
    xsize = windmap_settings.geometry.xsize
    ysize = windmap_settings.geometry.ysize
    count = (windmap_settings.records(1) - windmap_settings.records(0))/cadence + 1.01
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

;---Setup scaling and a mask for the useful area of the image:
    if n_elements(images) gt 2 then begin
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
    for rec=(windmap_settings.records(0) > 0), (windmap_settings.records(1) < n_elements(winds.vertical_wind)-1), cadence do begin
        js2ymds, tcen(rec), yy, mmm, dd, ss
        rr = (rec - (windmap_settings.records(0) > 0))/cadence
        yy = ysize - fix(rr/cols)*(cs + ymarg+mtop) - (cs + ymarg + mtop) + 0.2*ymarg
        cy = ysize - fix(rr/cols)*(cs + ymarg+mtop) - cs/2 - mtop
        xx = (rr mod cols)*(cs + ymarg+mtop) + (cs + ymarg+mtop)/2
        rotdir = 1
        if mm.latitude lt 0. then rotdir = -1
        rotang = rotdir*15.*(3600D*mm.magnetic_midnight - ss)/3600.  - rotdir*mm.rotation_from_oval
        if mm.latitude lt 0 then rotang = rotang + 180
        if windmap_settings.orientation ne 'Magnetic Noon at Top' then rotang = 0.
        if n_elements(images) gt 2 and use_images then begin
           rx = winds(rec).record
           ri = where(images.record eq rx, ng)
           ri = ri(0) > 0
           img = congrid(reform(images(ri).scene), cs, cs, cubic=0.5)
;           img = culz.imgmin + bytscl(img, min=imlo, max=imhi, top=culz.imgmax - culz.imgmin - 1)
           img = culz.imgmin + bytscl(img, min=images(rr).scale(0), max=images(rr).scale(0)+smax, top=culz.imgmax - culz.imgmin - 1)
           img = reverse(img, 2)
;           if windmap_settings.orientation eq 'Magnetic Noon at Top' then img = rot(img, rotang)
           img(outerz) = 0
           tv, img, xx-cs/2, cy-cs/2, /device
        endif else begin
           indata  = [[spekfits(rec).temperature], [spekfits(rec).intensity], [spekfits(rec).temperature]]

           rgblimz = [[windmap_settings.scale.rbscale], [windmap_settings.scale.gscale] , [windmap_settings.scale.pscale]]
;           indata  = [[spekfits(rec).velocity], [0.*spekfits(rec).intensity], [0.*spekfits(rec).temperature]]
;           rgblimz = [[-300,300], [0,9e9] , [0,9e9]]
           sdi3k_one_rgbmap, mm, cs, indata, rgblimz, zone_map, mapr, mapg, mapb, /map_view, azimuth_rotation=rotang
           loadct, 0, /silent
           tv, [[[mapr]], [[mapg]], [[mapb]]], xx-cs/2, cy-cs/2, /device, true=3
        endelse
        tvlct, r, g, b
        tvcircle, cs/2-1, xx, cy, culz.ash, thick=1
        xyouts, xx, yy, tlist(rec), align=0.5, /device, color=pen_color, charthick=1, charsize=1.2
        wait, 0.003
    endfor
    tvlct, r, g, b

    for rec=(windmap_settings.records(0) > 0), (windmap_settings.records(1) < n_elements(winds.vertical_wind)-1), cadence do begin

        rr = (rec - (windmap_settings.records(0) > 0))/cadence
        yy = ysize - fix(rr/cols)*(cs + ymarg+mtop) - (cs + ymarg + mtop) + 0.2*ymarg
        cy = ysize - fix(rr/cols)*(cs + ymarg+mtop) - cs/2 - mtop
        xx = (rr mod cols)*(cs + ymarg+mtop) + (cs + ymarg+mtop)/2
        geo = {xcen: xx, ycen: cy, radius: cs/2., wscale: windmap_settings.scale.yrange, $
               perspective: windmap_settings.perspective, orientation: windmap_settings.orientation}
        sdi3k_one_windplot, winds, tcen, rec, geo, mm, thick=1, color=pen_color, index_color=culz.red, /no_project
        wait, 0.003
    endfor

    ylo = convert_coord(50, 50, /device, /to_normal)
    yhi = convert_coord(50, 70, /device, /to_normal)


;---Add an orientation key:
    if windmap_settings.orientation ne 'Magnetic Noon at Top' then begin
       cx   = 0.96*xsize
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
    arrow, xsize/3. - cs/4., cs/6, xsize/3. + cs/4., cs/6, hsize=cs/10, color=pen_color, thick=2, hthick=2
    xyouts, 0.33,   ylo(1), scalestr, align=0.5, /normal, color=pen_color, charthick=2, charsize=2
    xyouts, 0.93,   ylo(1), 'Cadence: ' + strcompress(string(cadence, format='(i2)'), /remove_all), align=1.0, /normal, color=pen_color, charthick=2, charsize=2
    if n_elements(images) le 2 or ~(use_images) then begin
;       tprlab = 'Velocity: ' + strcompress(string(fix(rgblimz(0,0)), format='(i4)'), /remove_all) + ' to ' + $
;                        strcompress(string(fix(rgblimz(1,0)), format='(i4)'), /remove_all) + ' m/s'
       tprlab = 'Temperature: ' + strcompress(string(fix(rgblimz(0,0)), format='(i4)'), /remove_all) + ' to ' + $
                        strcompress(string(fix(rgblimz(1,0)), format='(i4)'), /remove_all) + ' K'
       xyouts, 0.45,   ylo(1), tprlab, align=0.0, /normal, color=pen_color, charthick=2, charsize=2
    endif

    datestr = dt_tm_mk(js2jd(0d)+1, mm.start_time, format='Y$-n$-0d$')
    xyouts, 0.015, ylo(1), datestr, align=0., /normal, color=pen_color, charthick=2, charsize=2

    ylo = convert_coord(50, 20, /device, /to_normal)
    datestr = dt_tm_mk(js2jd(0d)+1, mm.start_time, format='DOY doy$')
    xyouts, 0.015, ylo(1), datestr, align=0., /normal, color=pen_color, charthick=2, charsize=2

end
