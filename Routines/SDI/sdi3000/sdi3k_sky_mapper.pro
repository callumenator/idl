pro sdi3k_sky_mapper, tlist, tcen, mm, smootharr, skymap_settings, culz, zone_map, map_view=map_view, azimuth_rotation=azimuth_rotation, rainbow_intensities=rainbow_intensities

    par   = where(tag_names(smootharr(0)) eq strcompress(strupcase(skymap_settings.parameter), /remove_all))

;---Set the parameter value scaling limits:
    parlimz = skymap_settings.scale.yrange
    if skymap_settings.scale.auto_scale then begin
       pv = smootharr.(par)
       pv = pv(sort(pv))
       nv = n_elements(pv)
       parlimz = [pv(0.05*nv), pv(0.95*nv)]
    endif

;---Choose the color palette:
    tvlct, r,g,b, /get
    loshade = culz.imgmin+1
    hishade = culz.imgmax-1
    ncul    = culz.imgmax - culz.imgmin - 3
    if skymap_settings.parameter eq 'Intensity' and not(keyword_set(rainbow_intensities))then begin
       loshade = culz.greymin+1
       hishade = culz.greymax-1
       ncul    = culz.greymax - culz.greymin - 3
    endif
    if skymap_settings.parameter eq 'Velocity' then begin
;------Setup the Doppler blue...red colours:
       satval = 255
       tvlct, r, g, b, /get

       f = 2.0
       p = 0.25
       q = 0.40
       i = indgen(1 + hishade - loshade)
       imgcen = (loshade+hishade)/2
       step = f*satval/(1. + hishade - loshade)
       b(loshade:hishade) = (satval - step*i) > 0
       g(loshade:hishade) = 0
       r(loshade:hishade) = satval < ((satval - step*(1 + hishade - loshade -i)) $
                                 > 0)
       b(loshade:hishade) = satval < 1.1*b(loshade:hishade)
       r(loshade:hishade) = satval < 1.1*r(loshade:hishade)

       nb = imgcen  - loshade + 1
       nr = hishade - imgcen  + 1
       bb = reverse(indgen(nb))
       rr = indgen(nr)
       rb = exp(-((bb - 0.60*nb)/(0.4*nb))^2)*(abs(bb/(0.60*nb)))^1.
       gb = exp(-((bb - 0.98*nb)/(0.8*nb))^2)*(abs(bb/(0.98*nb)))^1.
       br = exp(-((rr - 0.65*nr)/(0.4*nr))^2)*(abs(rr/(0.65*nr)))^1.
       gr = exp(-((rr - 0.98*nr)/(0.8*nr))^2)*(abs(rr/(0.98*nr)))^1.

;       r(loshade:imgcen) = p*b(loshade:imgcen)
;       g(loshade:imgcen) = q*b(loshade:imgcen)
       r(loshade:imgcen) = p*rb*satval
       g(loshade:imgcen) = 1.2*q*gb*satval
;       b(imgcen:hishade) = p*r(imgcen:hishade)/2
;       g(imgcen:hishade) = q*r(imgcen:hishade)/4
       b(imgcen:hishade) = p*br*satval
       g(imgcen:hishade) = 0.8*q*gr*satval
       tvlct, r,g,b
    endif
    palette = {r: r, g:g, b: b}

;---Setup background and pen colors:
    if skymap_settings.black_bgnd then begin
       bgnd      =culz.black
       pen_color = culz.white
    endif else begin
       bgnd      = culz.white
       pen_color = culz.black
    endelse
    erase, color=bgnd

    nx           = n_elements(zone_map(*,0))
    ny           = n_elements(zone_map(0,*))
    edge         = (nx < ny)/2
    skyidx = zone_map((mm.x_center_pix - edge + 1) > 0 : (mm.x_center_pix + edge - 1) < nx-1, $
                      (mm.y_center_pix - edge + 1) > 0 : (mm.y_center_pix + edge - 1) < ny-1)

;---Figure out how big to make each individual sky map:
    xsize = skymap_settings.geometry.xsize
    ysize = skymap_settings.geometry.ysize
    count = skymap_settings.records(1) - skymap_settings.records(0) + 1.01
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

    panel = bytarr(cs + ymarg+mtop, cs + ymarg+mtop) + bgnd
    zsize = size(skyidx)

    for rec=(skymap_settings.records(0) > 0), (skymap_settings.records(1) < n_elements(smootharr)-1) do begin
    skymap = intarr(zsize(1), zsize(2)) + bgnd
    yvals  = smootharr(rec).(par)
    yvals  = loshade + ncul*(yvals - parlimz(0))/(parlimz(1) - parlimz(0))
    nsat   = 0
    sat    = where(yvals ge hishade, nsat)
    if nsat gt 0 then yvals(sat) = hishade
    sat    = where(yvals le loshade, nsat)
    if nsat gt 0 then yvals(sat) = loshade
    nz = mm.nzones
    for zidx=0,nz-1 do begin
        this_zone = where(skyidx eq zidx)
        skymap(this_zone) = yvals(zidx)
    endfor

    if keyword_set(map_view) then skymap = reverse(skymap, 2)
    if keyword_set(azimuth_rotation) then skymap = rot(skymap, azimuth_rotation, /interp)
    skymap(where(skyidx eq -1)) = bgnd
    panel((ymarg+mtop)/2:(ymarg+mtop)/2+cs-1,ymarg:ymarg+cs-1) = congrid(skymap, cs, cs)

;-------Display the skymap for this exposure:
    tv, panel, rec - skymap_settings.records(0)
    wait, 0.001
    endfor

    for rec=(skymap_settings.records(0) > 0), (skymap_settings.records(1) < n_elements(smootharr)-1) do begin
        rr = rec - (skymap_settings.records(0) > 0)
    yy = ysize - fix(rr/cols)*(cs + ymarg+mtop) - (cs + ymarg + mtop) + 0.2*ymarg
        cy = ysize - fix(rr/cols)*(cs + ymarg+mtop) - cs/2 - mtop
    xx = (rr mod cols)*(cs + ymarg+mtop) + (cs + ymarg+mtop)/2
        tvcircle, cs/2-1, xx, cy, culz.ash, thick=1
        tvcircle, cs/2,   xx, cy, bgnd, thick=1
        tvcircle, cs/2+1, xx, cy, bgnd, thick=1
        tvcircle, cs/2+2, xx, cy, bgnd, thick=1
        tvcircle, cs/2+3, xx, cy, bgnd, thick=1
        xyouts, xx, yy, tlist(rec), align=0.5, /device, color=pen_color, charthick=1, charsize=1.2
    endfor

    ylo = convert_coord(50, 50, /device, /to_normal)
    yhi = convert_coord(50, 70, /device, /to_normal)

;---Add an orientation key:
    cx = 0.95*xsize
    cy = 50
    cr = 0.05*xsize
    tvcircle, cr/2, cx, cy+4, pen_color, thick=1
    bc = 'N'
    tc = 'S'
    if keyword_set(map_view) then begin
       bc = 'S'
       tc = 'N'
    endif
    xyouts, cx, cy + cr/3.5,  tc, alignment=0.5, charsize=1, color=pen_color, /device
    xyouts, cx + cr/3.5, cy, 'E', alignment=0.5, charsize=1, color=pen_color, /device
    xyouts, cx, cy - cr/3.5,  bc, alignment=0.5, charsize=1, color=pen_color, /device
    xyouts, cx - cr/3.5, cy, 'W', alignment=0.5, charsize=1, color=pen_color, /device


;---Build the color bar titles:
    ytit = sentence_case(skymap_settings.parameter)

;---And add units to the title if possible:
    unipar = where(strpos(tag_names(smootharr(0)), 'UNITS_' + strupcase(ytit)) ge 0, nn)
    unitz  = ' '
    if nn gt 0 then unitz = ' [' + smootharr(0).(unipar(0)) + ']'

    mccolbar, [0.3, ylo(1), 0.7, yhi(1)], loshade, hishade, parlimz(0), parlimz(1), $
                  parname=ytit, units=unitz, $
                  color=pen_color, thick=2, charsize=1.8, format='(i6)', $
              /horizontal, /both_units
    datestr = dt_tm_mk(js2jd(0d)+1, mm.start_time, format='Y$-n$-0d$')
    xyouts, 0.015, ylo(1), datestr, align=0., /normal, color=pen_color, charthick=2, charsize=2

    ylo = convert_coord(50, 20, /device, /to_normal)
    datestr = dt_tm_mk(js2jd(0d)+1, mm.start_time, format='DOY doy$')
    xyouts, 0.015, ylo(1), datestr, align=0., /normal, color=pen_color, charthick=2, charsize=2
    ;load_pal, culz, proportion=0.5
end

