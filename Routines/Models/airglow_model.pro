
pro airglow_chapman_func, z, a, F, pder

	a0 = a[0]
	a1 = a[1]
	a2 = a[2]
	z0 = a[3]
	h0 = a[4]
	b = a[5]

	H = h0 + b*(z-z0)
	inner = a1*( 1 - ((z-z0)/H) - a2*exp(-1*((z-z0)/H)))

	f = a0*exp(inner)


	;\\ Partial derivs
	p_g = (z-z0)/H

	p_dgdz0 = (-1.0/H) + b*(z-z0)/(H*H)
	p_dgdh0 = -(z-z0)/(H*H)
	p_dgdb =  -((z-z0)*(z-z0))/(H*H)

	p_f = a1 - a1*p_g - a1*a2*exp(-1*p_g)
	p_dfda1 = 1 - p_g - a2*exp(-p_g)
	p_dfda2 = -a1*exp(-p_g)
	p_dfdg = -a1 + a1*a2*exp(-p_g)

	pder = [ [exp(inner)], $
			 [a0*exp(p_f)*p_dfda1], $
			 [a0*exp(p_f)*p_dfda2], $
			 [a0*exp(p_f)*p_dfdg*p_dgdz0], $
			 [a0*exp(p_f)*p_dfdg*p_dgdh0], $
			 [a0*exp(p_f)*p_dfdg*p_dgdb]]

end



;\\ LMFIT VERSION
function airglow_chapman_func, z, a

	a0 = a[0]
	a1 = a[1]
	a2 = a[2]
	z0 = a[3]
	h0 = a[4]
	b = a[5]

	H = h0 + b*(z-z0)
	inner = a1*( 1 - ((z-z0)/H) - a2*exp(-1*((z-z0)/H)))

	f = a0*exp(inner)


	;\\ Partial derivs
	p_g = (z-z0)/H

	p_dgdz0 = (-1.0/H) + b*(z-z0)/(H*H)
	p_dgdh0 = -(z-z0)/(H*H)
	p_dgdb =  -((z-z0)*(z-z0))/(H*H)

	p_f = a1 - a1*p_g - a1*a2*exp(-1*p_g)
	p_dfda1 = 1 - p_g - a2*exp(-p_g)
	p_dfda2 = -a1*exp(-p_g)
	p_dfdg = -a1 + a1*a2*exp(-p_g)

	return, [ [f], $
			 [exp(inner)], $
			 [a0*exp(p_f)*p_dfda1], $
			 [a0*exp(p_f)*p_dfda2], $
			 [a0*exp(p_f)*p_dfdg*p_dgdz0], $
			 [a0*exp(p_f)*p_dfdg*p_dgdh0], $
			 [a0*exp(p_f)*p_dfdg*p_dgdb]]

end




pro airglow_model, yymmdd, ut_hour, lat, lon, $
				   model_params, $
				   airglow_out, $	;\\ OUT: {alt:arr, v:arr= volume emission rate, peak:val}
				   model = model

	;\\ Supported models:
	;\\ 'meneses' - model_params = {el_dens:arr, oplus_dens:arr, el_dens_err:arr, dens_alt:arr}
	;\\ 'vlasov' - model_params = {el_dens:arr, el_dens_err:arr, dens_alt:arr, ti:arr}




	if not keyword_set(model) then begin
		model = 'meneses'
	endif else begin
		if size(model, /type) ne 7 then model = 'meneses'
	endelse


	if model eq 'meneses' then begin
		good = where(finite(model_params.el_dens) eq 1 and $
					 finite(model_params.oplus_dens) eq 1 and $
					 finite(model_params.dens_alt) eq 1 and $
					 finite(model_params.el_dens_err) eq 1, ngood)
		if ngood lt 2 then begin
			airglow_peak = -1
			return
		endif

		edens = model_params.el_dens[good]
		edens_err = model_params.el_dens_err[good]
		ealts = model_params.dens_alt[good]
		eop = model_params.oplus_dens[good] / model_params.el_dens[good]
	endif


	if model eq 'vlasov' then begin
		good = where(finite(model_params.el_dens) eq 1 and $
					 finite(model_params.dens_alt) eq 1 and $
					 finite(model_params.el_dens_err) eq 1, ngood)
		if ngood lt 2 then begin
			airglow_peak = -1
			return
		endif

		edens = model_params.el_dens[good]
		edens_err = model_params.el_dens_err[good]
		ealts = model_params.dens_alt[good]
		ti = model_params.ti[good]
	endif

	nh = 500.
	lo_alt = min(ealts)
	hi_alt = max(ealts)
	alt = fltarr(nh)
	O = fltarr(nh)
	O2 = fltarr(nh)
	N2 = fltarr(nh)
	Tn = fltarr(nh)

	cnd = get_geomag_conditions(yymmdd, /quick)
	ap_hour = intarr(8)
	ap_value = intarr(8)
	for j = 0, 7 do begin
		ap_hour[j] = 3*j
		ap_value[j] = cnd.mag.(15 + j)
	endfor
	ap_interpol = interpol(ap_value, ap_hour, ut_hour)

	for j = 0, nh - 1 do begin
		h = ((hi_alt-lo_alt)/nh)*j + lo_alt
		msis = get_msis2000_params(200, ut_hour*3600., h, lat, lon, cnd.mag.f107, cnd.mag.f107, ap_interpol)
		O(j) = msis.dens.o
		O2(j) = msis.dens.o2
		N2(j) = msis.dens.n2
		Tn(j) = msis.temp
		alt(j) = h
	endfor

	if model eq 'meneses' then begin
		y1 = 2E-11
		k1 = 8E-12
		k2 = 3.2E-11
		k3 = 2.3E-11
		k4 = 6.2E-10
		Ad = 7.45E-3
		A = 5.63E-3
		f1D = 1.2

		if nels(edens) gt 6 then begin
			gxx = ealts
			gyy = edens
			wgts = 1./edens_err
			fita = [max(gyy), 0.8, 0.8, 280, 30, -0.05]
			ne_chap = curvefit(gxx, $
			  					gyy, $
								wgts, $
								fita, $
								sigmas, $
								function_name='airglow_chapman_func', $
								iter = niters, $
								chisq=chi, /double)
			ne_chap = curvefit(gxx, $
			  					gyy, $
								wgts, $
								fita, $
								sigmas, $
								function_name='airglow_chapman_func', $
								iter = niters, $
								chisq=chi, /double)

			airglow_chapman_func, alt, fita, elec, pder
			max_density = fita[0]
			elec = elec*1E-6

		endif else begin
			elec = interpol(edens, ealts, alt)*1E-6
			max_density = max(edens)
		endelse

		elec = interpol(edens, ealts, alt)*1E-6
		max_density = max(edens)

		elec_err = interpol(edens_err, ealts, alt)*1E-6
		Op_ratio = interpol(eop, ealts, alt)/100.


		V = (A * Op_ratio * f1D * y1 * elec * O2)
		V = V / (k1*O + k2*O2 + k3*N2 + k4*elec + Ad)

	endif

	if model eq 'vlasov' then begin

		A1D = 7.1E-3
		A2D = 2.2E-3
		muD = 1.

		if nels(edens) gt 6 then begin
			gxx = ealts
			gyy = edens
			wgts = 1./edens_err
			fita = [max(gyy), 0.8, 0.8, 280, 30, -0.05]
			ne_chap = curvefit(gxx, $
			  					gyy, $
								wgts, $
								fita, $
								sigmas, $
								function_name='airglow_chapman_func', $
								iter = niters, $
								chisq=chi, /double)

			airglow_chapman_func, alt, fita, elec, pder
			max_density = fita[0]
			elec = elec*1E-6
		endif else begin
			elec = interpol(edens, ealts, alt)*1E-6
			max_density = max(edens)
		endelse



		ion_temp = interpol(ti, ealts, alt)*1E-6
		Teff = (2./3.)*ion_temp + (1./3.)*Tn

		y1 = 1.53E-12 - (5.92E-13 * (Teff/300)) + (8.6E-14 * (Teff/300)^2.)

		y2 = 2.82E-11 - ( 7.74E-12 * (Teff/300.)) + (1.073E-12 * (Teff/300.)^2.) $
			 - (5.17E-14 * (Teff/300.)^3.) + ( 9.65E-16 * (Teff/300.)^4.)

		B = .76

		yO = 4E-13
		yD = 5.3E-12

		k1 = 2E-11 * exp(107.8/Tn)
		k2 = 2.9E-11 * exp(67.5/Tn)
		k3 = (3.73 + (1.1965E-1 * Tn^0.5) - (6.5898E-4 * Tn)) * 1E-12

		;elec = interpol(edens, ealts, alt)*1E-6
		elec_err = interpol(edens_err, ealts, alt)*1E-6

		V = A1D * ( (muD*y2*O2*elec) + (B*y1*N2*elec*yD*O2)/(yD*O2 + yO*O) )
		V = V / (k1*N2 + k2*O2 + k3*O + A1D + A2D)


	endif

	gauss = gaussfit(alt, V, coeffs, nterms=4, measure_errors = elec_err)
	airglow_peak = coeffs[1]

		gxx = alt
		gyy = V
		wgts = 1./elec_err
		fita = [max(V), 0.8, 0.8, 260, 60, -0.05]
		ne_chap = curvefit(gxx, $
		  					gyy, $
							wgts, $
							fita, $
							sigmas, $
							function_name='airglow_chapman_func', $
							iter = niters, $
							chisq=chi, itmax=100, tol=1E-10, /double)

		ne_chap_2 = lmfit(gxx, $
		  				  gyy, $
						  fita, $
						  function_name='airglow_chapman_func', $
						  tol=1E-10, itmax = 100, convergence=cnvd, /double)



	;plot, gyy, gxx
	;oplot, ne_chap, gxx, psym=1
	;oplot, ne_chap_2, gxx, psym=2


	pk = gxx[(where(gyy eq max(gyy)))[0]]
	airglow_out = {alt:alt, v:v, peak:airglow_peak, peak2:fita[3], max_density:max_density}


end