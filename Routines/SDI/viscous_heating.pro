

pro viscous_heating, yymmdd, heating

	meta_loader, out, ymd=yymmdd

	bi_grads = (out.hrp_pkr_usolve.avegrad) / 1E3
	bi_grads = rotate_wind_gradients(bi_grads[*,0],bi_grads[*,1],bi_grads[*,2],bi_grads[*,3], 40.)

	dudx = bi_grads[*,0]
	dudy = bi_grads[*,1]
	dvdy = bi_grads[*,2]
	dvdx = bi_grads[*,3]

	amu = 1.66053886E-27

	nt = nels(bi_grads[*,0])

	cnd = get_geomag_conditions(yymmdd, /quick)

	numdens = fltarr(nt)
	massdens = fltarr(nt)
	visc_coeff = fltarr(nt)
	for j = 0, nt - 1 do begin

		secs = out.pkr_mono[j,0].time*3600.
		msis = get_msis2000_params(out.day, secs, 240.0, out.pkr.meta.latitude, $
								   out.pkr.meta.longitude, cnd.mag.f107, cnd.mag.f107, cnd.mag.apmean)

		tviscc = (1e-7) * (msis.dens.he*3.84 + msis.dens.o*3.9 + msis.dens.n2*3.43 + msis.dens.o2*4.03) / $
			  			  (msis.dens.he + msis.dens.o + msis.dens.n2 + msis.dens.o2)

		visc_coeff[j] = tviscc
	endfor


	pkr_temp = interpol( median(out.pkr.speks.temperature, dim=1), out.pkr.ut, reform(out.pkr_mono[*,0].time))
	hrp_temp = interpol( median(out.hrp.speks.temperature, dim=1), out.hrp.ut, reform(out.pkr_mono[*,0].time))
	aveTemp = (pkr_temp + hrp_temp)/2.
	mu = visc_coeff * (aveTemp^0.69)

	visc_heat = 2*(dudx*dudx) + 2*(dvdy*dvdy) + (dudy + dvdx)*(dudy + dvdx) - (2./3.)*(dudx + dvdy)*(dudx + dvdy)
	visc_heat = visc_heat * mu

	heating = {heating:visc_heat, time:reform(out.pkr_mono[*,0].time)}

end