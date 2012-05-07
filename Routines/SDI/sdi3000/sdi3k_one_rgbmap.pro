pro sdi3k_one_rgbmap, mm, cs, indata, parlimz, zone_map, mapr, mapg, mapb, map_view=map_view, azimuth_rotation=azimuth_rotation

    nx           = n_elements(zone_map(*,0))
    ny           = n_elements(zone_map(0,*))
    edge         = (nx < ny)/2
    skyzns = zone_map((mm.x_center_pix - edge + 1) > 0 : (mm.x_center_pix + edge - 1) < nx-1, $
                      (mm.y_center_pix - edge + 1) > 0 : (mm.y_center_pix + edge - 1) < ny-1)

;stop
    skyidx = intarr(n_elements(skyzns(*,0)) + 2, n_elements(skyzns(0,*)) + 2) + min(skyzns)
    skyidx(1:n_elements(skyzns(*,0)), 1:n_elements(skyzns(0,*))) = skyzns

    panel = congrid(skyidx, cs, cs)
    bg = where(panel lt 0)


    zsize = size(skyidx)
    loshade = 1
    hishade = 255
    rgb_vex = {red: bytarr(255), green: bytarr(255), blue: bytarr(255)}

    devtol = 0.9
;    rbdev = abs(median(indata(*,0)))/median(abs(indata(*,0)))
    poz = where(indata(*,0) gt 0., npoz)
    rbdev = npoz/n_elements(indata(*,0))

    if rbdev lt devtol then bgoff = 128 else bgoff = 0

        for par = 0,2 do begin
            rgbmap = intarr(zsize(1), zsize(2))
          ;  if par eq 0 then rgbmap = rgbmap + bgoff
            panel  = bytarr(cs, cs)
          ;  if par eq 0 then panel = panel + bgoff
        yvals  = indata(*,par)
        yvals  = loshade+(hishade-loshade-2)*(yvals - parlimz(0,par))/(parlimz(1,par) - parlimz(0,par))
        nsat   = 0
        sat    = where(yvals ge hishade, nsat)
        if nsat gt 0 then yvals(sat) = hishade
        sat    = where(yvals le loshade, nsat)
        if nsat gt 0 then yvals(sat) = loshade

        nz = mm.nzones
        for zidx=0,nz-1 do begin
            this_zone = where(skyidx eq zidx)
            rgbmap(this_zone) = yvals(zidx)
        endfor
;if par eq 2 then stop
        if keyword_set(map_view) then rgbmap = reverse(rgbmap, 2)
        if keyword_set(azimuth_rotation) then rgbmap = rot(rgbmap, azimuth_rotation, /interp)

        panel = congrid(rgbmap, cs, cs)
        if par eq 0 then map1 = panel
        if par eq 1 then map2 = panel
        if par eq 2 then map3 = panel
    endfor
;stop
;-----------Build the R, G, and B maps:
       if rbdev lt devtol then begin
          mapr =   2.*(map1 - 128) > 0
          mapb =  -2.*(map1 - 128) > 0
          mapr(bg) = 0
          mapb(bg) = 0
       endif else begin
          mapr = 0.7*map1
          mapb = 0.7*(255 - map1)
;          bg = where(map1 eq 0)
          mapr(bg) = 0
          mapb(bg) = 0
       endelse

        mapg = map2
        mapr = sqrt(mapr^2 + (map3*0.7)^2)
        mapb = sqrt(mapb^2 + (map3*0.7)^2)

        mapr = mapr < 255
        mapg = mapg < 255
        mapb = mapb < 255
end

