
function myperiodogram, IN_tt, IN_yy, IN_sigmas, freq, coeffs=coeffs

	ss = IN_sigmas
	yy = IN_yy
	tt = IN_tt
	f = float(freq)

	;\\ My way
		tYS = total(yy*sin(f*tt))
		tYC = total(yy*cos(f*tt))
		tSS = total(sin(f*tt)*sin(f*tt))
		tCC = total(cos(f*tt)*cos(f*tt))
		tSC = total(sin(f*tt)*cos(f*tt))

		myB =  ((tYS/tSS) - ((tYC*tSC)/(tCC*tSS))) / (1 + ( (tSC*tSC)/(tCC*tSS) ) )
		myA = (tYC - myB*tSC) / (tCC)
		coeffs = [myA, myB, mean(yy)]

	return, 0

end