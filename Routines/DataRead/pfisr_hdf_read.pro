
pro pfisr_hdf_read, file, data, convection=convection

	hid = h5f_open(file)

	;\\ Both normal data and convection data have these fields
		geoLat = h5d_read(h5d_open(hid, '/Site/Latitude'))
		geoLon = h5d_read(h5d_open(hid, '/Site/Longitude'))
		magLat = h5d_read(h5d_open(hid, '/Site/MagneticLatitude'))
		magLon = h5d_read(h5d_open(hid, '/Site/MagneticLongitude'))
		mltmidnight = h5d_read(h5d_open(hid, '/Site/MagneticLocalTimeMidnight'))
		dectime = h5d_read(h5d_open(hid, '/Time/dtime'))

	if not keyword_set(convection) then begin
		;\\ Normal data file

		doy = h5d_read(h5d_open(hid, '/Time/doy'))
		day = h5d_read(h5d_open(hid, '/Time/Day'))
		month = h5d_read(h5d_open(hid, '/Time/Month'))
		year = h5d_read(h5d_open(hid, '/Time/Year'))
		mlt = h5d_read(h5d_open(hid, '/Time/MagneticLocalTimeSite'))
		beams = h5d_read(h5d_open(hid, '/BeamCodes'))

		fits = h5d_read(h5d_open(hid, '/FittedParams/Fits'))
		mass = h5d_read(h5d_open(hid, '/FittedParams/IonMass'))
		errs = h5d_read(h5d_open(hid, '/FittedParams/Errors'))
		alts = h5d_read(h5d_open(hid, '/FittedParams/Altitude'))

		eldens = h5d_read(h5d_open(hid, '/FittedParams/Ne'))
		eldens_err = h5d_read(h5d_open(hid, '/FittedParams/dNe'))
		range = h5d_read(h5d_open(hid, '/FittedParams/Range'))
		snr = h5d_read(h5d_open(hid, '/NeFromPower/SNR'))

		dens_n2 = h5d_read(h5d_open(hid, '/MSIS/nN2'))
		dens_o = h5d_read(h5d_open(hid, '/MSIS/nO'))
		dens_o2 = h5d_read(h5d_open(hid, '/MSIS/nO2'))
		msis_tn = h5d_read(h5d_open(hid, '/MSIS/Tn'))

		meta = {nbeams:n_elements(beams[0,*]), $
				nranges:n_elements(alts[*,0]), $
				nrecords:n_elements(fits[0,0,0,0,*]), $
				geoLat:geolat, $
				geoLon:geoLon, $
				magLat:magLat, $
				magLon:magLon, $
				mltMidnight:mltMidnight }

		beam_latlon_110 = get_end_lat_lon(geoLat, geoLon, $
						  get_great_circle_length(90-reform(beams[2,*]), 110), reform(beams[1,*]))
		beam_latlon_240 = get_end_lat_lon(geoLat, geoLon, $
						  get_great_circle_length(90-reform(beams[2,*]), 240), reform(beams[1,*]))

		beamInfo = {code:reform(beams[0,*]), $
					az:reform(beams[1,*]), $
					el:reform(beams[2,*]), $
					latlon_110:beam_latlon_110, $
					latlon_240:beam_latlon_240 }

		timeInfo = {decimal:dectime, $
					day:day, $
					month:month, $
					year:year, $
					doy:doy, $
					mlt:mlt}

		fitInfo = {fraction:reform(fits[0, 0, *, *, *]), $
				   temperature:reform(fits[1, 0, *, *, *]), $
				   coll_freq:reform(fits[2, 0, *, *, *]), $
				   los_velocity:reform(fits[3, 0, *, *, *]), $
				   electron_dens:eldens}

		allFits = {fraction:reform(fits[0, *, *, *, *]), $
				   temperature:reform(fits[1, *, *, *, *]), $
				   coll_freq:reform(fits[2, *, *, *, *]), $
				   los_velocity:reform(fits[3, *, *, *, *]), $
				   electron_dens:eldens, $
				   ionMass:mass}

		errInfo = {fraction:reform(errs[0, 0, *, *, *]), $
				   temperature:reform(errs[1, 0, *, *, *]), $
				   coll_freq:reform(errs[2, 0, *, *, *]), $
				   los_velocity:reform(errs[3, 0, *, *, *]), $
				   electron_dens:eldens_err}

		allErrs = {fraction:reform(errs[0, *, *, *, *]), $
				   temperature:reform(errs[1, *, *, *, *]), $
				   coll_freq:reform(errs[2, *, *, *, *]), $
				   los_velocity:reform(errs[3, *, *, *, *]), $
				   electron_dens:eldens_err}

		dens = {o:dens_o, n2:dens_n2, o2:dens_o2}
		msis = {dens:dens, temp:msis_tn}


		altInfo = {altitude:alts, $
				   range:range}

		data = {meta:meta, $
				time:timeInfo, $
				beams:beamInfo, $
				fits:fitInfo, $
				allFits:allFits, $
				allErrs:allErrs, $
				errs:errInfo, $
				alts:altInfo, $
				msis:msis}

	endif else begin
		;\\ Convection data file

		params = {baudlength:h5d_read(h5d_open(hid, '/ProcessingParams/BaudLength')), $
				  correctvap:h5d_read(h5d_open(hid, '/ProcessingParams/CorrectVap')), $
				  covar:h5d_read(h5d_open(hid, '/ProcessingParams/Covar')), $
				  errorelim:h5d_read(h5d_open(hid, '/ProcessingParams/ErrorElim')), $
				  geographicbinning:h5d_read(h5d_open(hid, '/ProcessingParams/GeographicBinning')), $
				  integrationtime:h5d_read(h5d_open(hid, '/ProcessingParams/IntegrationTime')), $
				  maxalt:h5d_read(h5d_open(hid, '/ProcessingParams/MaxAlt')), $
				  minalt:h5d_read(h5d_open(hid, '/ProcessingParams/MinAlt')), $
				  minedens:h5d_read(h5d_open(hid, '/ProcessingParams/MinimumElectronDensity')), $
				  pulselength:h5d_read(h5d_open(hid, '/ProcessingParams/PulseLength')), $
				  rxfrequency:h5d_read(h5d_open(hid, '/ProcessingParams/RxFrequency')), $
				  txfrequency:h5d_read(h5d_open(hid, '/ProcessingParams/TxFrequency')), $
				  veloffsetcorrection:h5d_read(h5d_open(hid, '/ProcessingParams/VelocityOffsetCorrection'))}

		vels = {edir:h5d_read(h5d_open(hid, '/VectorVels/Edir')), $
				eest:h5d_read(h5d_open(hid, '/VectorVels/Eest')), $
				emag:h5d_read(h5d_open(hid, '/VectorVels/Emag')), $
				vdir:h5d_read(h5d_open(hid, '/VectorVels/Vest')), $
				vest:h5d_read(h5d_open(hid, '/VectorVels/Vdir')), $
				vmag:h5d_read(h5d_open(hid, '/VectorVels/Vmag')), $
				maglatitude:h5d_read(h5d_open(hid, '/VectorVels/MagneticLatitude')), $
				nmeas:h5d_read(h5d_open(hid, '/VectorVels/Nmeas')) }

		errs = {edir:h5d_read(h5d_open(hid, '/VectorVels/errEdir')), $
				eest:h5d_read(h5d_open(hid, '/VectorVels/errEest')), $
				emag:h5d_read(h5d_open(hid, '/VectorVels/errEmag')), $
				vdir:h5d_read(h5d_open(hid, '/VectorVels/errVdir')), $
				vest:h5d_read(h5d_open(hid, '/VectorVels/errVest')), $
				vmag:h5d_read(h5d_open(hid, '/VectorVels/errVmag')) }

		meta = {geoLat:geolat, $
				geoLon:geoLon, $
				magLat:magLat, $
				magLon:magLon, $
				mltMidnight:mltMidnight }

		nixtime = h5d_read(h5d_open(hid, '/Time/UnixTime'))

		nels = n_elements(nixtime[0,*])
		yr = fltarr(nels)
		dy = yr
		mn = yr
		doy = yr
		for i = 0, nels - 1 do begin
			js2ymds, dt_tm_tojs(systime(0, nixtime[0,0], /ut)), _y, _m, _d, _s
			yr[i] = _y
			mn[i] = _m
			dy[i] = _d
			doy[i] = ymd2dn(_y, _m, _d)
		endfor

		timeInfo = {decimal:dectime, $
					mlt:h5d_read(h5d_open(hid, '/Time/MagneticLocalTime')), $
					day:dy, $
					month:mn, $
					year:yr, $
					doy:doy}

		data = {meta:meta, $
				time:timeInfo, $
				params:params, $
				vels:vels, $
				errs:errs}

	endelse

	h5f_close, hid

end