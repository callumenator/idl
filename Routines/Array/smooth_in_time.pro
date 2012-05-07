
;\\ Resolution is number of points in interpolated curve...
function smooth_in_time, time, var, resolution, timeSmooth, $
						 gauss=gauss, $
						 gauss_convol=gauss_convol

	if not keyword_set(gauss) and not keyword_set(gauss_convol) then begin
		resolution = double(resolution)
		intTime = (dindgen(resolution)/(resolution-1)) * double((max(time) - min(time))) + min(time)
		deltaTime = intTime[1] - intTime[0]
		nPtsSmooth = double(timeSmooth) / deltaTime
		intVar = interpol(var, time, intTime)

		if nptsSmooth gt n_elements(intVar) then begin
			nptsSmooth = n_elements(intVar)*.9
			print, 'Reducing Smoothing window to fit...'
		endif

		smoothVar = smooth(intVar, nPtsSmooth, /edge, /nan)
		retVar = interpol(smoothVar, intTime, time)
		return, retVar
	endif

	if keyword_set(gauss) then begin

		retvar = fltarr(n_elements(time))
		for tt = 0L, n_elements(time) - 1 do begin
			t_dists = time[tt] - time
			weight = exp( -(t_dists)^2./(2*timeSmooth^2.) )
			weight = weight/total(weight)
			retvar[tt] = total(var*weight)
		endfor
		return, retvar
	endif

	if keyword_set(gauss_convol) then begin

		resolution = double(resolution)
		intTime = (dindgen(resolution)/(resolution-1)) * double((max(time) - min(time))) + min(time)
		deltaTime = intTime[1] - intTime[0]
		nPtsSmooth = double(timeSmooth) / deltaTime
		intVar = interpol(var, time, intTime)

		s = 1./nPtsSmooth
		xx = intTime[0:nPtsSmooth*10 < (resolution-10)]
		gauss = (1./(2*!PI*s*s)) * exp(-((xx-mean(xx))^2.)/(2*s*s))
		gauss /= total(gauss)
		retvar = interpol(convol(intVar, gauss, /center, /edge_wrap), intTime, time)
		return, retvar

	endif

end


