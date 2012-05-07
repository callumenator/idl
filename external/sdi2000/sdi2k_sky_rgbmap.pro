pro sdi2k_sky_rgbmap, tlist, tcen, datestr, smootharr, skymap_settings, palette=palette, map_view=map_view, azimuth_rotation=azimuth_rotation, no_purple=no_purple
@sdi2kinc.pro
@sdi2kinc.pro

;---Set the parameter value scaling limits:
    parlimz = skymap_settings.scale.yrange
;    if skymap_settings.scale.auto_scale then begin
;       pv = smootharr.(skymap_settings.parameter)
;       pv = pv(sort(pv))
;       nv = n_elements(pv)
;       parlimz = [pv(0.05*nv), pv(0.95*nv)]
;    endif



;---Setup background and pen colors:
    if skymap_settings.black_bgnd then begin
       bgnd      =host.colors.black
       pen_color = host.colors.white
    endif else begin
       bgnd      = host.colors.white
       pen_color = host.colors.black
    endelse
    erase, color=bgnd

    nx           = n_elements(zone_map(*,0))
    ny           = n_elements(zone_map(0,*))
    edge         = (nx < ny)/2
    skyidx = zone_map((host.operation.zones.x_center - edge + 1) > 0:(host.operation.zones.x_center + edge - 1) < nx-1, $
                              (host.operation.zones.y_center - edge + 1) > 0:(host.operation.zones.y_center + edge - 1) < ny-1)

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
;    mtop  = 8
;    ymarg = 30
    cs    = fix(xsize/cols - ymarg - mtop)
    ylo   = convert_coord(50, 50, /device, /to_normal)
    yhi   = convert_coord(50, 70, /device, /to_normal)


    zsize = size(skyidx)
    loshade = 1
    hishade = 255
    rgb_vex = {red: bytarr(255), green: bytarr(255), blue: bytarr(255)}

    rbdev = abs(median(smootharr.(skymap_settings.parameter(0))))/median(abs(smootharr.(skymap_settings.parameter(0))))
    if rbdev lt 0.1 then bgoff = 128 else bgoff = 0
    
    for rec=(skymap_settings.records(0) > 0), (skymap_settings.records(1) < n_elements(smootharr)-1) do begin
        for par = 0,2 do begin
            skymap = intarr(zsize(1), zsize(2))
            if par eq 0 then skymap = skymap + bgoff
            panel  = bytarr(cs + ymarg+mtop, cs + ymarg+mtop)
            if par eq 0 then panel = panel + bgoff
	    yvals  = smootharr(rec).(skymap_settings.parameter(par))
;	    if skymap_settings.parameter(par) eq 6 then yvals = sqrt(yvals)
	    yvals  = loshade+(hishade-loshade-2)*(yvals - parlimz(0,par))/(parlimz(1,par) - parlimz(0,par))
	    nsat   = 0
	    sat    = where(yvals ge hishade, nsat)
	    if nsat gt 0 then yvals(sat) = hishade
	    sat    = where(yvals le loshade, nsat)
	    if nsat gt 0 then yvals(sat) = loshade
	    nz = total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1))
	    for zidx=0,nz-1 do begin
		this_zone = where(skyidx eq zidx)
		skymap(this_zone) = yvals(zidx)
	    endfor
	    
	    if keyword_set(map_view) then skymap = reverse(skymap, 2)
	    if keyword_set(azimuth_rotation) then skymap = rot(skymap, azimuth_rotation, /interp)

	    panel((ymarg+mtop)/2:(ymarg+mtop)/2+cs-1,ymarg:ymarg+cs-1) = congrid(skymap, cs, cs)
	    if par eq 0 then map1 = panel
	    if par eq 1 then map2 = panel
	    if par eq 2 then map3 = panel
	endfor
;-----------Display the zone map as a background for the spectra plots:

        if rbdev lt 0.1 then begin
	   mapr =   2.*(map1 - 128) > 0
	   mapb =  -2.*(map1 - 128) > 0
	endif else begin
	   mapr = 0.7*map1
	   mapb = 0.7*(255 - map1)
	   bg = where(map1 eq 0)
	   mapr(bg) = 0
	   mapb(bg) = 0
	endelse
        mapg = map2
        mapr = sqrt(mapr^2 + (map3*0.7)^2)
        mapb = sqrt(mapb^2 + (map3*0.7)^2)

        mapr = mapr < 255
        mapg = mapg < 255
        mapb = mapb < 255
        
        if keyword_set(palette) then begin
           tvlct, rin, gin, bin, /get
           img8bit = color_quan(mapr, mapg, mapb, r, g, b, cube=6) + 20
           rin(20:20+215) = r(0:215)
           gin(20:20+215) = g(0:215)
           bin(20:20+215) = b(0:215)
           tvlct, rin, gin, bin
           tv, img8bit, rec - skymap_settings.records(0)
        endif else begin
           loadct, 0, /silent
           tv, [[[mapr]], [[mapg]], [[mapb]]], rec - skymap_settings.records(0), true=3
        endelse

    endfor
    load_pal, culz, proportion=0.5

    for rec=(skymap_settings.records(0) > 0), (skymap_settings.records(1) < n_elements(smootharr)-1) do begin
        rr = rec - (skymap_settings.records(0) > 0)
	yy = ysize - fix(rr/cols)*(cs + ymarg+mtop) - (cs + ymarg + mtop) + 0.2*ymarg
        cy = ysize - fix(rr/cols)*(cs + ymarg+mtop) - cs/2 - mtop
	xx = (rr mod cols)*(cs + ymarg+mtop) + (cs + ymarg+mtop)/2
        tvcircle, cs/2-1, xx, cy, host.colors.ash, thick=1
        tvcircle, cs/2,   xx, cy, bgnd, thick=1
        tvcircle, cs/2+1, xx, cy, bgnd, thick=1
        tvcircle, cs/2+2, xx, cy, bgnd, thick=1
        tvcircle, cs/2+3, xx, cy, bgnd, thick=1
;        xyouts, xx, yy, tlist(rec), align=0.5, /device, color=pen_color, charthick=2, charsize=1.7
        xyouts, xx, yy, tlist(rec), align=0.5, /device, color=pen_color, charthick=1, charsize=1.2
    endfor

;---Add an orientation key:
    cx = 0.95*xsize
    cy = 50
    cr = 0.05*xsize
    tvcircle, cr/2, cx, cy+4, pen_color, thick=1
    xyouts, cx, cy + cr/3.5, 'S', alignment=0.5, charsize=1, color=pen_color, /device
    xyouts, cx + cr/3.5, cy, 'E', alignment=0.5, charsize=1, color=pen_color, /device
    xyouts, cx, cy - cr/3.5, 'N', alignment=0.5, charsize=1, color=pen_color, /device
    xyouts, cx - cr/3.5, cy, 'W', alignment=0.5, charsize=1, color=pen_color, /device
    xyouts, 0.015, ylo(1), datestr, align=0., /normal, color=pen_color, charthick=2, charsize=2

    for par = 0,2 do begin
;-------Build the color bar titles:
        ytit = tag_names(smootharr(0))
        ytit = sentence_case(ytit(skymap_settings.parameter(par)))

;-------And add units to the title if possible:
        unipar = where(strpos(tag_names(smootharr(0)), 'UNITS_' + strupcase(ytit)) ge 0, nn)
        unitz  = ' '
        if nn gt 0 then unitz = ' [' + smootharr(0).(unipar(0)) + ']'
            
        if par eq 0 then begin
           if rbdev lt 0.1 then begin
	      rgb_vex.red  =  2.*(bindgen(255) - 128) > 0
	      rgb_vex.blue = -2.*(bindgen(255) - 128) > 0
	   endif else begin
	      rgb_vex.red  = 0.7*bindgen(255)
	      rgb_vex.blue = 0.7*(255 - bindgen(255))
	   endelse
	   rgb_vex.green = bytarr(255)
        endif 

        if par eq 1 then begin
           rgb_vex.red   = bytarr(255)
           rgb_vex.blue  = bytarr(255)
	   rgb_vex.green = bindgen(255)
        endif 
        
         if par eq 2 then begin
           rgb_vex.red   = 0.7*bindgen(255)
           rgb_vex.blue  = 0.7*bindgen(255)
	   rgb_vex.green = bytarr(255)
        endif 
        
        xlo = 0.2 + 0.25*par
        xhi = xlo + 0.16
        if par ne 2 or not(keyword_set(no_purple)) then $
;            mccolbar, [xlo, ylo(1), xhi, yhi(1)], loshade, hishade, parlimz(0,par), parlimz(1,par), $
;                      parname=ytit + '!C', units=unitz, $
;                      color=pen_color, thick=2, charsize=1.7, format='(i6)', $
;                     /horizontal, /both_units, rgb_vector=rgb_vex, reserved_colors=20
            mccolbar, [xlo, ylo(1), xhi, yhi(1)], loshade, hishade, parlimz(0,par), parlimz(1,par), $
                      parname=ytit + '!C', units=unitz, $
                      color=pen_color, thick=1, charsize=1.5, format='(i6)', $
                     /horizontal, /both_units, rgb_vector=rgb_vex, reserved_colors=20
    endfor
    if keyword_set(palette) then begin
       tvlct, rin, gin, bin
       palette.r = rin
       palette.g = gin
       palette.b = bin
    endif
end

