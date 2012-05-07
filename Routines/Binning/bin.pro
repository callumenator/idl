

pro bin, xparam, $
		 yparam, $
		 binwidth, $
		 xBin, $
		 yBin, $
		 ysigma=ysigma, $
		 xsigma=xsigma, $
		 numEls=numEls, $
		 xmedian=xmedian, $
		 ymedian=ymedian, $
		 lognormal=lognormal, $	;\\ Assume a lognormal distribution of the dependent variable
		 bmin=bmin ;\\ Start binning at this value

		nbins = ceil((max(xparam) - min(xparam)) / float(binwidth))
		xBin = fltarr(nbins)
		yBin = xBin
		xsigma = xBin
		ysigma = xBin
		numEls = xBin

		xsigma(*) = -1
		ysigma(*) = -1

		if size(bmin, /type) ne 0 then min_x = bmin else min_x = min(xparam)

		for b = 0L, nbins - 1 do begin
			pts = where(xparam ge min_x + b*binwidth and $
						xparam le min_x + (b+1)*binwidth, npts)

			numEls[b] = npts

			if keyword_set(xmedian) then begin
				if npts gt 2 then begin
					xBin(b) = median(xparam(pts))
					xsigma(b) = meanabsdev(xparam(pts), /median)
				endif
				if npts eq 1 then begin
					xBin(b) = xparam(pts)
					xsigma(b) = 0
				endif
			endif else begin
				if npts gt 1 then begin
					xBin(b) = mean(xparam(pts))
					xsigma(b) = stdev(xparam(pts))
				endif
				if npts eq 1 then begin
					xBin(b) = xparam(pts)
					xsigma(b) = 0
				endif
			endelse






			if keyword_set(ymedian) then begin
				if npts gt 2 then begin
					yBin(b) = median(yparam(pts))
					ysigma(b) = meanabsdev(yparam(pts), /median)
				endif
				if npts eq 2 then begin
					yBin(b) = mean(yparam(pts))
					ysigma(b) = stddev(yparam(pts))
				endif
				if npts eq 1 then begin
					yBin(b) = yparam(pts)
					ysigma(b) = 0
				endif
			endif else begin
				if npts gt 1 then begin
					yBin(b) = mean(yparam(pts))
					ysigma(b) = stdev(yparam(pts))
				endif
				if npts eq 1 then begin
					yBin(b) = yparam(pts)
					ysigma(b) = 0
				endif
			endelse

			if keyword_set(lognormal) then begin
				if npts gt 1 then begin
					logmean =  total(alog(yparam[pts]), /nan)/float(npts)
					logdev = sqrt(total(  (alog(yparam[pts]) - logmean)^2, /nan  )/float(npts))
					ysigma[b] = logdev
				endif else begin
					ysigma[b] = 0
				endelse
			endif



		endfor

		pts = where(ysigma ne -1 and xsigma ne -1, npts)
		if npts gt 0 then begin
			xBin = xBin[pts]
			yBin = yBin[pts]
			xsigma = xsigma[pts]
			ysigma = ysigma[pts]
			numEls = numEls[pts]
		endif


end