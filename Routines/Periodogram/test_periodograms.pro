
pro test_periodograms

	nOrig = 360.*10
	sampFrac = .05

	xx = findgen(nOrig)*!dtor
	yy = 4*sin(xx) + 2*cos(2*xx) + 7*sin(3*xx)

	sampPts = intarr(norig*sampFrac)
	rand = fix(randomu(systime(/sec), norig*sampFrac)*10) + 1
	for k = 1, norig*sampFrac - 1 do sampPts(k) = sampPts(k-1) + rand(k)
	sampPts = sampPts*(norig/max(sampPts))

	sxx = xx(sampPts)
	syy = yy(sampPts)

	sigma = fltarr(n_elements(yy))
	sigma(*) = 1

	freq = findgen(10)+1

	truePower = generalised_lomb_scargle(xx, yy, freq)
	power1 = generalised_lomb_scargle(sxx, syy, freq)
	scargle, sxx, syy, om, power2, omega=freq, numf=n_elements(freq), period=period, signi=signi



	window, 0, xs = 800, ys = 800
	!p.multi = [0,1,2]
	loadct, 39, /silent

	plot, freq, truePower
	oplot, 2*!PI/period, power2/total(power2), color = 150
	oplot, freq, power1, color = 200

	plot, xx, yy
	oplot, sxx, syy, color=50, psym=6, thick=5

	stop


end