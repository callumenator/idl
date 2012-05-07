	function fmoft, timevals,in_tdata,ft,$
		over_sample=ovrsfactor,weights=datawt

;+
; NAME:			FMOFT
;
; PURPOSE:		Performs a DFT on unequally spaced data by finding 
;			an orthogonal basis set based on the sine function.
;
; CATEGORY:		Signal Processing and Data Analysis
;
; CALLING SEQUENCE:	result = FMOFT(time_values, data, direction)
;
; INPUTS:
;			time_values 	= relative spacing of the data
;			data		= data to be transformed
;			direction	= direction of the transform
;	KEYWORDS:
;			OVER_SAMPLE	= over-sampling factor. Since this is 
;					a DFT, frequency space can be sampled  
;					at any arbitrary resolution. This  
;					gives the integer factor to  
;					over-sample by. Default = 1  
;					(no over-sampling)
;			WEIGHTS		= weights for the data
; OUTPUTS:
;			Result = (n_elements(data)*OVER_SAMPLE) Complex array
;
;   OPTIONAL PARAMETERS:
;
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;	17/9/92 Based on the fortran sub "fmoft.f" in my library source
;
;c	v1.0  T.J.H.  14/11/89  based on method of S. Ferraz-Mello
;c		" Estimation of Periods from Unequally spaced Observations "
;c		'The Astronomical Journal', vol 86, pg 619, 1981
;c
;c	v1.1  T.J.H.  18/01/91  Corrected mintime and maxtime
;
;-

;c...INPUTS
;	integer*4 N, ovrsfactor, ft
;	real   *4 timevals(N),datawt(N)
;	complex*4 tdata(N)
;c...OUTPUTS
;	complex*4 fdata(ovrsfactor*N)
		
;c	the input data, "tdata", is Fourier Transformed into "fdata"
;c	using the data window "datawt" and an orthogonal set h1,h2
;c	(NB: oversample frequency space by factor of 'ovrsfactor')
;c	
        twopi = 2.*!dpi

	N = n_elements(timevals)

	if (not keyword_set(ovrsfactor)) then ovrsfactor = 1
	
	maxtime = max( timevals, min=mintime )
	if ((maxtime le 0)  or (mintime lt 0)) then begin
		print, ' ERROR in time values, all values zero, or some < 0'
		return,-1
	endif else $
		freqstep = 1/(maxtime-mintime)/float(ovrsfactor)

	M = ovrsfactor*N

;	ensure tdata is of complex type
	;;;sz = size(in_tdata)
	;;;if (sz(sz(0)+1) ne 6) then tdata = complex(in_tdata) $
	;;;else tdata = in_tdata
	tdata = complex(in_tdata)

;c...  ..mean correct the data 
	if (not keyword_set(datawt)) then datawt = 1.
	sdx = stdev(float(tdata*datawt),meanx)	& sdy = stdev(imaginary(tdata*datawt),meany)
	tdata = tdata - complex(meanx,meany)

;	Define the output data array
	fdata = complexarr(M)

	if (not keyword_set(datawt)) then datawt = 1./(sdx^2+sdy^2)
	a0 = total(datawt)
	if (a0 gt 0) then a0 = 1/sqrt(a0) $
	else begin
		print,' ERROR in data weights, sum = 0 '
		return,-1
	endelse
	
	CASE (ft) OF
		-1 : begin
			whichway = -1.
 			normfact = sqrt(2.*a0*a0)
			end
		ELSE: begin
			whichway = 1.
 			normfact = 1/sqrt(2.*a0*a0)
			end
	ENDCASE

;c... case freq = 0
	fdata(0) = complex(meanx,meany)*2.*normfact*normfact

;c... case freq > 0, < maxfrequency
	freq = freqstep * findgen(M)
	sumc = freq*0.0
	sums = sumc
	sumcs = sumc
	sumc2 = sumc
	sums2 = sumc
	
	for f = 1,M-1 do begin
		x = freq(f)*(timevals-mintime)
 		cwt = cos(twopi*x)
		swt = sin(twopi*x)
		sumc(f) = total(datawt*cwt)
		sums(f) = total(datawt*swt)
		sumcs(f) = total(datawt*cwt*swt)
		sumc2(f) = total(datawt*cwt*cwt)
		sums2(f) = total(datawt*swt*swt)
	endfor

	a1 = sumc2 - a0*a0*sumc*sumc
	a1 = 1/sqrt(a1)
	temp1 = (sumcs - a0*a0*sumc*sums)*(sumcs - a0*a0*sumc*sums)
	a2 = sums2 - a0*a0*sums*sums - a1*a1*temp1
	a2 = 1/sqrt(a2)
	
	a1(0) = 1
	a2(0) = 1
		
	temp1 = a1*a0*a0*sumc
	temp2 = a2*a0*a0*sums
	temp3 = (a2*a1*sumcs - a2*temp1*sums)
		
	for f = 1,M-1 do begin
		x = freq(f)*(timevals-mintime)
 		cwt = cos(twopi*x)
		swt = sin(twopi*x)
		h1 = (a1(f)*cwt - temp1(f))
		h2 = (a2(f)*swt - temp2(f) - h1*temp3(f)) * whichway
		;;h1 = (a1*cwt - temp1)
		;;h2 = (a2*swt - temp2 - h1*temp3) * whichway
		fdata(f) = normfact*total(tdata*complex(h1,h2))
	endfor
		
	return,fdata
	
	end



