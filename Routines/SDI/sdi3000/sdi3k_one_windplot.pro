;==========================================================================================
; This is the routine that draws one vector wind map:
pro sdi3k_one_windplot, windfit, timez, rcd, geo, mm, thick=thick, color=color, index_color=idc, zone_mask=zone_mask, no_project=no_project

  ncnzones = n_elements(windfit(0).zeniths)
  mpx  = geo.radius*2
  js2ymds, timez(rcd), yy, mmm, dd, ss
  ho = fix(dt_tm_mk(js2jd(0d)+1, timez(rcd), format='h$'))
  mi = fix(dt_tm_mk(js2jd(0d)+1, timez(rcd), format='m$'))
  if not(keyword_set(color)) then color = 1
  if not(keyword_set(idc))   then idc   = color
  if not(keyword_set(zone_mask)) then zone_mask = intarr(ncnzones) + 1

  rotdir = 1
  if mm.latitude lt 0. then rotdir = -1
  case geo.orientation of
       'Geographic North at Top': hourangle = -rotdir*(mm.oval_angle)*!pi/180.
       'Magnetic Noon at Top':    hourangle = -rotdir*!pi*15.*(mm.magnetic_midnight - (ho + mi/60.))/180.
       else:                      hourangle = 0.
  endcase

  if geo.orientation eq 'Magnetic Noon at Top' and idc ge 0 then begin
     arrow, geo.xcen, geo.ycen, $
            geo.xcen + sin(hourangle + !pi)*geo.radius, geo.ycen - cos(hourangle +!pi)*geo.radius, $
            hsize=geo.radius/5., color=idc
  endif


  maxd = max([windfit.zonal_distances, windfit.meridional_distances])
  for zidx=0,ncnzones-1 do begin
      if zone_mask(zidx) then begin
;    zon = windfit.zonal_wind(zidx, rcd)*cos(hourangle) - $
;          windfit.meridional_wind(zidx, rcd)*sin(hourangle)
;    mer = windfit.zonal_wind(zidx, rcd)*sin(hourangle) + $
;          windfit.meridional_wind(zidx, rcd)*cos(hourangle)
;    cx = -geo.radius*windfit.zonal_distances(zidx)/maxd
;    cy = -geo.radius*windfit.meridional_distances(zidx)/maxd
;       ;mer = -mer
;       cx  = -cx
;       cy  = -cy
;    if geo.perspective eq 'Sky' then begin
;       mer = -mer
;       cy  = -cy
;    endif
;
;    ;if geo.orientation eq 'Geographic North at Top' then hourangle = -hourangle
;    xb =-cx*cos(hourangle) + cy*sin(hourangle) + geo.xcen
;    yb = cx*sin(hourangle) + cy*cos(hourangle) + geo.ycen

;hourangle=0
 ;hourangle = 22*!pi/180.

     zon = windfit(rcd).zonal_wind(zidx)*cos(hourangle) - $
           windfit(rcd).meridional_wind(zidx)*sin(hourangle)
     mer =-windfit(rcd).zonal_wind(zidx)*sin(hourangle) - $
           windfit(rcd).meridional_wind(zidx)*cos(hourangle)

     zon = zon*rotdir
     mer = mer*rotdir
     cx =  geo.radius*windfit(rcd).zonal_distances(zidx)/maxd
     cy =  geo.radius*windfit(rcd).meridional_distances(zidx)/maxd
     if keyword_set(no_project) then begin
        cx =  geo.radius*windfit(rcd).zeniths(zidx)*sin(!dtor*windfit(rcd).azimuths(zidx))/mm.sky_fov_deg
        cy =  geo.radius*windfit(rcd).zeniths(zidx)*cos(!dtor*windfit(rcd).azimuths(zidx))/mm.sky_fov_deg
     endif
        mer = -mer
        cy  = -cy
        cx  = -cx

     if geo.perspective eq 'Sky' then begin
        mer = -mer
        cy  = -cy
     endif

     ;if geo.orientation eq 'Geographic North at Top' then hourangle = -hourangle
     xb = -cx*cos(hourangle) + cy*sin(hourangle) + geo.xcen
     yb =-cx*sin(hourangle) - cy*cos(hourangle) + geo.ycen



;--------Displace beginning positions so that the center of the vector will lie at the observing location:
     xb = xb - mpx*zon/(4*geo.wscale)
     yb = yb - mpx*mer/(4*geo.wscale)
;--------Now add the vector displacement to the vector base, to get the endpoints:
     xe = xb + mpx*zon/(2*geo.wscale)
     ye = yb + mpx*mer/(2*geo.wscale)

;--------Draw the arrow:
     arrow, xb, yb, xe, ye, color=color, hsize=mpx/25., thick=thick
      endif
  endfor
end
