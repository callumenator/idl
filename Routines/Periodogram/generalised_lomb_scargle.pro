
;\\ From M. Zechmeister and M. Kurster, 2009, arXive E-Print

;\\ IN_tt = input times
;\\ IN_yy = measured data at each IN_tt
;\\ IN_sigmas = uncertainty in each measurement
;\\ freq = frequency (number of repeats in given time range)
;\\ freq = absolute frequency

function Generalised_Lomb_Scargle, IN_tt, IN_yy, freq, fap=fap, signi=signi, $
								   coeffs=coeffs, sigma=sigma, raw=raw


	yy = IN_yy
	tt = IN_tt
	n0 = float(n_elements(tt))
	Pw = fltarr(n_elements(freq))
	coeffs = fltarr(n_elements(freq), 4)

	;\\ Convert frequency into number of repeats in given time range
	use_freq = freq * (max(IN_tt) - min(IN_tt))

	if keyword_set(sigma) then begin
		ss = sigma
	endif else begin
		ss = fltarr(n_elements(IN_yy))
		ss(*) = 1.0
	endelse

	;\\ Significance
	if keyword_set(fap) then begin
		horne = long(-6.362+1.193*n0+0.00098*n0^2.)
		signi = -alog(  1.D0 - ((1.D0-fap)^(1./horne))  )
	endif

	tt = tt - min(tt)
	tt = 2*!PI* (tt / max(tt))

	W = total( 1./(ss*ss) )
	ww = (1./W) * (1./(ss*ss))

	for fidx = 0, n_elements(use_freq) - 1 do begin

		f = float(use_freq[fidx])

	;\\ Calculate Tau
		CS = total( ww*cos(f*tt)*sin(f*tt)  ) - ( total( ww*cos(f*tt) ) * total( ww*sin(f*tt) ) )
		CC = total( ww*cos(f*tt)*cos(f*tt)  ) - ( total( ww*cos(f*tt) ) * total( ww*cos(f*tt) ) )
		SS = total( ww*sin(f*tt)*sin(f*tt)  ) - ( total( ww*sin(f*tt) ) * total( ww*sin(f*tt) ) )
		tau = atan( (2*CS) / (CC - SS) ) / (2.*f)
		;tau = 0

	;\\ Calculate the sums
		YYt = total( ww*yy*yy ) - (total( ww*yy )*total( ww*yy ))
		YCt = total( ww*yy*cos(f*(tt - tau)) ) - ( total( ww*yy ) * total( ww*cos(f*(tt - tau)) ) )
		YSt = total( ww*yy*sin(f*(tt - tau)) ) - ( total( ww*yy ) * total( ww*sin(f*(tt - tau)) ) )
		CCt = total( ww*cos(f*(tt - tau))*cos(f*(tt - tau)) ) - $
			  (total( ww*cos(f*(tt - tau)) ) * total( ww*cos(f*(tt - tau))))
		SSt = total( ww*sin(f*(tt - tau))*sin(f*(tt - tau)) ) - $
			  (total( ww*sin(f*(tt - tau)) ) * total( ww*sin(f*(tt - tau))))
		CSt = total( ww*cos(f*(tt - tau))*sin(f*(tt - tau)) ) - $
			  (total( ww*cos(f*(tt - tau)) )*total( ww*sin(f*(tt - tau)) ) )
		Dt = (CCt*SSt) - (CSt*CSt)

		coeffA = ((YCt*SSt) - (YSt*CSt))/Dt
		coeffB = ((YSt*CCt) - (YCt*CSt))/Dt
		coeffC = total(ww*yy) - coeffA*(total( ww*cos(f*(tt - tau)) )) - coeffB*(total( ww*sin(f*(tt - tau)) ))
		coeffs(fidx,*) = [coeffA, coeffB, coeffC, tau]

		Pw(fidx) = (1./YYt) * ( ((YCt*YCt)/(CCt)) + ((YSt*YSt)/(SSt))  )

	endfor

	if keyword_set(raw) then begin
		return, Pw
	endif else begin
		return, Pw*( (n0-1)/2. )
	endelse
end