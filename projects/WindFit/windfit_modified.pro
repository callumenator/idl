
pro windfit_diff_oper, inarr, outarr
    outarr = inarr
    nx = n_elements(inarr)-1
    if nx lt 1 then return
    out0   = inarr(1)  - inarr(0)
    outnx  = inarr(nx) - inarr(nx-1)
    if nx gt 1 then outarr = (shift(inarr, -1) - shift(inarr, 1))/2
    outarr(0)  = out0
    outarr(nx) = outnx
end

pro windfit_modified, spekfits, $
					  metadata, $
					  windfit, $
					  settings, $
					  zone_centers, $
					  dvdx_zero=dvdx_zero, $
					  no_vz_correction=no_vz_correction, $  ;\\ use this if velocities are already corrected
					  precomputed_dvdx = precomputed_dvdx 	;\\ supply a dvdx value for the given exposure, for each ring

  nz       = metadata.nzones
  ncrecord = n_elements(spekfits)
  ncnrings = metadata.rings
  posarr   = spekfits.velocity
  ulosarr  = 0.*posarr; - 9e9
  uperparr = ulosarr
  wradarr  = ulosarr
  zonal    = ulosarr
  merid    = ulosarr
  fitZonal = ulosarr
  fitMerid = ulosarr
  timarr   = (spekfits.start_time + spekfits.end_time)/2.
  sky_fov  = metadata.sky_fov_deg
  chisqr   = fltarr(ncrecord)

  src_hgt  = 1000.*settings.assumed_height
  split_rings = 1

    sdi3k_zone_angles, metadata, sky_fov, rad, theta, ridx
    xx     = src_hgt*tan(rad)*sin(theta)
    yy     = src_hgt*tan(rad)*cos(theta)

    velarr = spekfits.velocity
    sdi3k_timesmooth_fits,  velarr, 3., metadata
    cenarr = spekfits.velocity
    sdi3k_spacesmooth_fits, cenarr, 0.2, metadata, zone_centers
    outz = where(rad gt 0.2*sky_fov*!pi/180)

;------Now run through and fit each exposure:
       fouriers = fltarr(ncrecord, ncnrings, 3, 2)
       for rcd=0,ncrecord-1 do begin
           wait, 0.001

			ucert = (spekfits[rcd].sigma_velocity - mean(spekfits[rcd].sigma_velocity))/stddev(spekfits[rcd].sigma_velocity)

;----------Correct for vertical wind:
			if not keyword_set(no_vz_correction) then begin
           		posarr(*,rcd) = posarr(*,rcd) - velarr(0,rcd)*cos(rad)
			endif

           ng      = 0
           goods   = where(spekfits(rcd).signal2noise gt -1, ng)
           if ng le 0 then goods   = indgen(nz)

;-Compute the m=0, m=1, and m=2 components of Fourier decomposition:
           wgt = fltarr(nz)
           wgt(goods) = 1
           totwgt = fltarr(ncnrings)

           for j=1,nz-1 do begin
;--------------Accumulate the Fourier sumations:
               fouriers(rcd, ridx(j), 0, 0) = fouriers(rcd, ridx(j), 0, 0) + $
                        posarr(j,rcd)*wgt(j)/sin(rad(j))
               fouriers(rcd, ridx(j), 1, 0) = fouriers(rcd, ridx(j), 1, 0) + $
                        posarr(j,rcd)*cos(theta(j))*wgt(j)/sin(rad(j))
               fouriers(rcd, ridx(j), 1, 1) = fouriers(rcd, ridx(j), 1, 1) + $
                        posarr(j,rcd)*sin(theta(j))*wgt(j)/sin(rad(j))
               fouriers(rcd, ridx(j), 2, 0) = fouriers(rcd, ridx(j), 2, 0) + $
                        posarr(j,rcd)*cos(2.*theta(j))*wgt(j)/sin(rad(j))
               fouriers(rcd, ridx(j), 2, 1) = fouriers(rcd, ridx(j), 2, 1) + $
                        posarr(j,rcd)*sin(2.*theta(j))*wgt(j)/sin(rad(j))
               totwgt(ridx(j)) = totwgt(ridx(j)) + wgt(j)
           endfor

;----------Compute the Fourier coefficients:
           for rng=1,ncnrings-1 do begin
               if totwgt(rng) ne 0 then begin
                  fouriers(rcd, rng, *, *) = fouriers(rcd, rng, *, *) / totwgt(rng)
               endif else begin
                  fouriers(rcd, rng, *, *) = 1e-6
               endelse
               fouriers(rcd, rng, 1:2, *) = fouriers(rcd, rng, 1:2, *)*2.
           endfor
       endfor

;------Compute the meridional wind gradient with longitude, using
;      local time as a dimension proxy:
       mgrad = fltarr(ncrecord, rng)
       if ncrecord gt 6 then begin
      nx = ncrecord-1
      for rng=1,ncnrings-1 do begin
          mgrad(*, rng) = fouriers(*, rng, 1, 0)
          mgrad(nx,rng) = mgrad(nx-1,rng)
      endfor
      for rng=1,ncnrings-1 do begin
          if ncrecord gt 6 then mgrad(*,rng) = smooth(mgrad(*,rng), 5)
      endfor
      maglat = 65*!pi/180.
      earthrad = 6371e3
      rotspeed = 2*!pi*cos(maglat)*earthrad/86400.
      windfit_diff_oper, timarr, deltime
      for rng=1,ncnrings-1 do begin
          sdi_diff_oper, mgrad(*,rng), mg
          if ncrecord gt 6 then mgrad(*,rng) = smooth(mg, 3)
          mgrad(*,rng) = mgrad(*,rng)/(deltime(0:ncrecord-1)*rotspeed)
      endfor
       endif

       if keyword_set(dvdx_zero) or ncrecord lt 6 then mgrad = fltarr(ncrecord, rng)

       if keyword_set(precomputed_dvdx) then begin
       		mgrad = replicate(precomputed_dvdx, ncrecord, ncnrings)
       		uy_atten = [1.00000, 0.847183, 0.630326, 0.382845]
			for rcd=0,ncrecord-1 do mgrad[rcd,4:*] = mgrad[4:*]*uy_atten
       		;mgrad = fltarr(ncrecord, ncnrings)
       		;for ircd = 0, ncrecord - 1 do mgrad[ircd,*] = precomputed_dvdx
       endif

       imgrad = fltarr(ncrecord, rng)

;      Compute the partial derivatives of zonal and meridional wind with
;      respect to x and y displacement from the zenith.  We start at rng=2,
;      since the central and first ring out only have 1 and 4 sectors
;      respectively, not enough to allow partial derivatives to be evaluated:
       dvdx = fltarr(ncrecord, ncnrings)
       dudy = fltarr(ncrecord, ncnrings)
       dvdy = fltarr(ncrecord, ncnrings)
       dudx = fltarr(ncrecord, ncnrings)
       zrad = fltarr(ncnrings)

	   min_six = (where(metadata.zone_sectors ge 6))[0]

       for rng=min_six,ncnrings-1 do begin
           zang = (metadata.zone_radii(rng) + metadata.zone_radii(rng-1))/2
           zang = (zang*sky_fov/100)*!pi/180
           zrad(rng) = zang
           hdis = src_hgt*tan(zang)
           dvdx(*, rng) = mgrad(*, rng)
           dudy(*, rng) = (2*fouriers(*, rng, 2, 1) - hdis*dvdx(*, rng))/hdis
           dvdy(*, rng) = (fouriers(*, rng, 0 ,0)+fouriers(*, rng, 2, 0))/hdis
           dudx(*, rng) = (fouriers(*, rng, 0 ,0)-fouriers(*, rng, 2, 0))/hdis
       endfor

;      Since we are using a first-order Taylor series expansion of the wind
;      about the zenith, it probably makes no sense to compute separate
;      partial derivatives in each ring.  Thus, unless "split_rings=1",
;      we replace each partial derivatives in each ring with the average
;      of that partial derivative over all rings. If split_rings=0, we
;      still need to set the partial derivatives equal to the all-sky
;      averages in the zenith and in reing one, as the derivatives
;       cannot be calculated there directly:

;\\ Ring 1 has enough zones now to calculate derivs... CAL

       for rcd=0,ncrecord-1 do begin
           if not(split_rings) then begin ; ########## minus signs removed, MC Oct 2008
              dvdx(rcd, *) = total(dvdx(rcd, 2:*)*sin(zrad(2:*)))/total(sin(zrad(2:*)))
              dudy(rcd, *) = total(dudy(rcd, 2:*)*sin(zrad(2:*)))/total(sin(zrad(2:*)))
              dvdy(rcd, *) = total(dvdy(rcd, 2:*)*sin(zrad(2:*)))/total(sin(zrad(2:*)))
              dudx(rcd, *) = total(dudx(rcd, 2:*)*sin(zrad(2:*)))/total(sin(zrad(2:*)))
           endif else begin
              dvdx(rcd, 0:min_six-1) = total(dvdx(rcd, 2:*)*sin(zrad(2:*)))/total(sin(zrad(2:*)))
              dudy(rcd, 0:min_six-1) = total(dudy(rcd, 2:*)*sin(zrad(2:*)))/total(sin(zrad(2:*)))
              dvdy(rcd, 0:min_six-1) = total(dvdy(rcd, 2:*)*sin(zrad(2:*)))/total(sin(zrad(2:*)))
              dudx(rcd, 0:min_six-1) = total(dudx(rcd, 2:*)*sin(zrad(2:*)))/total(sin(zrad(2:*)))

              ;uy_atten = dudy[rcd,2:*] / dudy[rcd,2]

           endelse

			;gradux = (linfit(indgen(ncnrings-2), abs(dudx[rcd, 2:*]))[1]
			;graduy = (linfit(indgen(ncnrings-2), abs(dudy[rcd, 2:*]))[1]
			;gradvy = (linfit(indgen(ncnrings-2), abs(dvdy[rcd, 2:*]))[1]

       endfor

;------Compute the first-order Taylor series zonal and meridional winds, and
;      then the component perpendicuar to the LOS:
       for rcd=0,ncrecord-1 do begin
           for zidx=1,nz-1 do begin
               rng = ridx(zidx)
;              First, compute the fitted zonal and meridional winds:
               zonal(zidx, rcd)  = (fouriers(rcd, rng, 1, 1) + $
                                    dudx(rcd, rng)*xx(zidx) + $
                                    dudy(rcd, rng)*yy(zidx))
               merid(zidx, rcd)  = (fouriers(rcd, rng, 1, 0) + $
                                    dvdx(rcd, rng)*xx(zidx) + $
                                    dvdy(rcd, rng)*yy(zidx))

			   fitZonal(zidx, rcd) = zonal(zidx, rcd)
			   fitMerid(zidx, rcd) = merid(zidx, rcd)

;goto, PURE_FIT
;              Now resolve these into LOS and perpendicular winds:
               uperparr(zidx,rcd)= zonal(zidx, rcd)*cos(theta(zidx)) - $
                                   merid(zidx, rcd)*sin(theta(zidx))
               ulosarr(zidx,rcd) = zonal(zidx, rcd)*sin(theta(zidx)) + $
                                   merid(zidx, rcd)*cos(theta(zidx))
;              Finally, recompute zonal and meridional components from the
;              observed LOS and fitted perpendicular components:
;               wradarr(zidx,rcd) = posarr(zidx, rcd)/sin(rad(zidx))
               wradarr(zidx,rcd) = cenarr(zidx, rcd)/sin(rad(zidx))

			if ucert[zidx] lt 2 then begin
               zonal(zidx, rcd)  = wradarr(zidx, rcd)*sin(theta(zidx)) + $
                                   uperparr(zidx, rcd)*cos(theta(zidx))
               merid(zidx, rcd)  = wradarr(zidx, rcd)*cos(theta(zidx)) - $
                                   uperparr(zidx, rcd)*sin(theta(zidx))
            endif
PURE_FIT:
           endfor
;----------Compute the zonal and meridional winds at the zenith:
           zonal(0, rcd) = total(zonal(1:*, rcd))/(nz-1)
           merid(0, rcd) = total(merid(1:*, rcd))/(nz-1)
;----------Compute a chi-squared value for the fit:
           sqdif = (posarr(*,rcd) - ulosarr(*,rcd)*sin(rad))^2
;           denom = (abs(posarr(*,rcd))+1.)*(abs(ulosarr(*,rcd)*sin(rad))+1.)
;           denom = (abs(ulosarr(*,rcd)*sin(rad))+1.)^2
           denom = abs(posarr(*,rcd)/(sin(rad)+.001))
           denom = (0.33*(sin(rad)+0.001)*total(denom(5:*)/(nz-5)))^2
           denom = denom + (abs(spekfits(rcd).sigma_velocity) + 5.)^2
           chisqr(rcd) = total(sqdif(5:*)/denom(5:*))/(nz - 12)
       endfor

;------Construct a structure to hold the results of the fitting:
       latfac = cos(!dtor*metadata.latitude)
       zlat   = metadata.latitude  + 0.001*yy/111.192
       zlon   = metadata.longitude + 0.001*xx/(latfac*111.192)

;---Create a template record for wind data, then replicate it to create an array to hold the requested records:
            windfit =  {valid: 1 + bytarr(ncrecord), $
                       record: indgen(ncrecord), $
                   start_time: spekfits.start_time, $
                     end_time: spekfits.end_time, $
                        scans: spekfits.scans, $
                   zonal_wind: zonal, $
              meridional_wind: merid, $
              	 zonal_fitted: fitZonal, $
              	 merid_fitted: fitMerid, $
                vertical_wind: spekfits.velocity(0), $
              fitted_los_wind: ulosarr, $
    fitted_perpendicular_wind: uperparr, $
                      zeniths: rad/!dtor, $
                     azimuths: theta/!dtor, $
              zonal_distances: xx, $
         meridional_distances: yy, $
               zone_latitudes: zlat, $
              zone_longitudes: zlon, $
          reduced_chi_squared: chisqr, $
                       u_zero: fouriers(*, *, 1, 1), $
                       v_zero: fouriers(*, *, 1, 0), $
                         dudx: dudx, $
                         dudy: dudy, $
                         dvdx: dvdx, $
                         dvdy: dvdy, $
               time_smoothing: settings.time_smoothing, $
              space_smoothing: settings.space_smoothing, $
               assumed_height: src_hgt, $
              dvdx_assumption: settings.dvdx_assumption, $
                    algorithm: settings.algorithm}

;------Now, we do need to recalculate the zonal and meridional distances, as well as
;      the zone lats and lons. We want these to be expressed in geographic, not
;      geomagnetic coordinates.
       theta  = theta - !dtor*metadata.oval_angle
       nw     = 0
       wraps  = where(theta gt 2*!pi, nw)
       if nw gt 0 then theta(wraps) = theta(wraps) - 2*!pi
       wraps  = where(theta lt 0, nw)
       if nw gt 0 then theta(wraps) = theta(wraps) + 2*!pi
       xx     = src_hgt*tan(rad)*sin(theta)
       yy     = src_hgt*tan(rad)*cos(theta)
       zlat   = metadata.latitude  + 0.001*yy/111.192
       zlon   = metadata.longitude + 0.001*xx/(latfac*111.192)
       windfit.azimuths = theta/!dtor
       windfit.zonal_distances = xx
       windfit.meridional_distances = yy
       windfit.zone_longitudes = zlon
       windfit.zone_latitudes = zlat
end
