
pro cal_extract_de_reader, filename=filename

@deua_inc.pro

    fail     = 1
    uain     = ua
    parin    = 1.D
    inline   = 'test'
    openr,    pltun, filename, /get_lun
    rex      = 0
    while not eof(pltun) do begin
              readf, pltun, inline
              inline = strcompress(inline)
              inline = strtrim(inline, 2)
              pars = str_sep(inline, ' ')
              for par=0,n_elements(pars)-1 do begin
                  parstr = pars(par)
                  reads, parstr, parin
                  if par eq 1 then parin = float(parin/3600000l)
                  uain.(par) = parin
              endfor
			  ua = [ua, uain]
              rex = rex + 1
    endwhile
    ua = ua(1:*)
    close,    pltun
    free_lun, pltun

end


pro cal_extract_de

@deua_inc.pro

	uarec = {s_ua, _date: 82001, $
               time_ut: 0.d, $
               _orbit: 0, $
               altitude: 500., $
               latitude: 80., $
               longitude: 0., $
               loc_sol_time: 0., $
               loc_mag_time: 0., $
               L_shell: 0., $
               inv_latitude: 0., $
               sol_zen_angle: 0., $
               N2_density: 0., $
               O_density: 0., $
               HE_density: 0., $
               AR_density: 0., $
               N_density: 0., $
               neutral_temp: 0., $
               eastward_wind: 0, $
               upward_wind: 0, $
               plasma_dens: 0., $
               electron_temp: 0., $
               _fpi_wavelength: 0., $
               fpi_tang_alt: 0., $
               northward_wind: 0., $
               fpi_temperature: 0., $
               fpi_intensity: 0., $
               ion_temp: 0., $
               ion_density: 0., $
               eastward_ion_drift: 0., $
               northward_ion_drift: 0., $
               upward_ion_drift:0.}

	list = file_search('C:\Cal\idlgit\projects\de2\DE2_DATA\' + '*.ASC', count = nfiles)

	for fidx = 1, nfiles - 1 do begin
		ua = replicate(uarec, 1)
		cal_extract_de_reader, filename=list(fidx)

		orbits = ua._orbit
		vz = ua.upward_wind
		vz_ion = ua.upward_ion_drift
		ut = ua.time_ut
		lat = ua.latitude
		ilat = ua.inv_latitude
		temp = ua.neutral_temp
		alt = ua.altitude
		mlt = ua.loc_mag_time

		;\\ Count orbits
			so = orbits(sort(orbits))
			uniq_orbs = orbits(uniq(so))
			n_orbs = n_elements(uniq_orbs)

		;\\ Loop through each orbit
			for o = 0, n_orbs - 1 do begin
				orb_num = uniq_orbs(o)
				pts = where(orbits eq orb_num)

				o_vz = vz(pts)
				o_vz_ion = vz_ion(pts)
				o_ut = ut(pts)
				o_lat = lat(pts)
				i_lat = ilat(pts)
				o_temp = temp(pts)
				o_mlt = mlt[pts]
				o_alt = alt[pts]

				nkeep = -1
				keep = where(o_vz ne 0., nkeep)
				if nkeep gt 5 then begin
					k_vz = o_vz(keep)
					k_vz_ion = o_vz_ion(keep)
					k_ut = o_ut(keep)
					k_lat = o_lat(keep)
					k_ilat = i_lat(keep)
					k_temp = o_temp(keep)
					k_mlt = o_mlt[keep]
					k_alt = o_alt[keep]

					;\\ Sort by latitude
						ord = sort(k_ut)
						k_vz = k_vz(ord)
						k_ut = k_ut(ord)
						k_vz_ion = k_vz_ion(ord)
						k_lat = k_lat(ord)
						k_ilat = k_ilat(ord)
						k_temp = k_temp(ord)
						k_mlt = k_mlt(ord)
						k_alt = k_alt(ord)

					;\\ Subtract a 3rd order polynomial from vz...
						poly = poly_fit(k_lat, k_vz, 3, yfit = curve)
						k_vz_poly = curve
						k_vz_mod = k_vz - curve
						k_vz_mod -= median(k_vz_mod)


						date = ua(pts)._date
						date = date(0)
						;fname = save_path + 'DE_' + string(date, f='(i0)') + '_Orbit_' + string(orb_num, f='(i0)') + '.dat'
						;save, filename = fname, k_vz, k_ut, k_vz_ion, k_lat, k_ilat, k_vz_poly, k_vz_mod, k_temp

						for i = 0, nels(k_vz) - 1 do begin
							append, {vz:k_vz_mod[i], $
									 ut:k_ut[i], $
									 vz_ion:k_vz_ion[i], $
								 	 lat:k_lat[i], $
								 	 ilat:k_ilat[i], $
								 	 temp:k_temp[i], $
								 	 mlt:k_mlt[i], $
								 	 alt:k_alt[i]}, $
								 	 all_data
						endfor


				endif else begin
					print, 'No non-zero points from orbit ' + string(orb_num, f='(i0)') + '!'
				endelse

			endfor

			wait, 0.001
			print, fidx, nfiles
		endfor

		stop

end