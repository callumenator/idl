function wpar_ringav, wot, zrad
   wot = reform(wot)
   nr     = n_elements(zrad)
   ringav = total(wot(1:nr-1)*sin(zrad(1:nr-1)))/total(sin(zrad(1:nr-1)))
   return, ringav
end


pro sdi2k_build_1dwindpars, windfit, rarr, resarr, ringsel=ringsel
@sdi2kinc.pro
   sky_fov  = host.operation.calibration.sky_fov
   nz       = fix(total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1)))
   ncrecord = n_elements(windfit.reduced_chi_squared)
   ncnrings = host.operation.zones.fov_rings
   if not(keyword_set(ringsel)) then ringsel = indgen(ncnrings)

   zrad = fltarr(ncnrings)
   for rng=2,ncnrings-1 do begin
       zang = (host.operation.zones.ring_radii(rng) + host.operation.zones.ring_radii(rng-1))/2
       zang = (zang*sky_fov/100)*!pi/180
       zrad(rng) = zang
   endfor

       resrcd = {record: 0, $
             start_time: 0d, $
               end_time: 0d, $
             zonal_wind: 0., $
        meridional_wind: 0., $
                  du_dx: 0., $
                  du_dy: 0., $
                  dv_dx: 0., $
                  dv_dy: 0., $
              vorticity: 0., $
             divergence: 0., $
    resolved_divergence: fltarr(ncnrings), $
       wind_chi_squared: 0., $
       units_zonal_wind: 'm/s', $
  units_meridional_wind: 'm/s', $
            units_du_dx: '1000/s', $
            units_du_dy: '1000/s', $
            units_dv_dx: '1000/s', $
            units_dv_dy: '1000/s', $
        units_vorticity: '1000/s', $
       units_divergence: '1000/s', $
       units_resolved_divergence: '1000/s'}

   for j=0,ncrecord-1 do begin
       resrcd.record           = j
       resrcd.start_time       = rarr(j).start_time
       resrcd.end_time         = rarr(j).end_time
       resrcd.zonal_wind       = wpar_ringav(windfit.u_zero(j, ringsel), zrad(ringsel))
       resrcd.meridional_wind  = wpar_ringav(windfit.v_zero(j, ringsel), zrad(ringsel))
       resrcd.du_dx            = 1000.*wpar_ringav(windfit.dudx(j, ringsel), zrad(ringsel))
       resrcd.du_dy            = 1000.*wpar_ringav(windfit.dudy(j, ringsel), zrad(ringsel))
       resrcd.dv_dx            = 1000.*wpar_ringav(windfit.dvdx(j, ringsel), zrad(ringsel))
       resrcd.dv_dy            = 1000.*wpar_ringav(windfit.dvdy(j, ringsel), zrad(ringsel))
       resrcd.wind_chi_squared = windfit.reduced_chi_squared(j)
       resrcd.vorticity        = resrcd.dv_dx - resrcd.du_dy
       resrcd.divergence       = resrcd.du_dx + resrcd.dv_dy
       for k=0,ncnrings-1 do begin
           resrcd.resolved_divergence(k) = 1000*(windfit.dudx(j, k)+ windfit.dvdy(j, k))
       endfor
       if j eq 0 then resarr   = resrcd else resarr = [resarr, resrcd]
   endfor
end