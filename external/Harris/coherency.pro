;-----------------------------------------------------------------------
;+
; NAME:			COHERENCY
;
; PURPOSE:		determine the statistical COHERENCY between two 
;			time series
;
; CATEGORY:		Time-series/Spectral analysis
;
; CALLING SEQUENCE:
;			COHERENCY, ts1,ts2, DF=df
;
;			COHERENCY, ts1,ts2, n_smooth
;
;			COHERENCY, ts1,ts2, DF=df
;				SIGLEVELS=siglevels, CONFIDENCE=confidence
;
; INPUTS:
;			ts1,ts2	= input time series vectors, of same length
;   OPTIONAL PARAMETERS:
;		One of n_smooth or DF should be set
;			n_smooth = number of elements to smooth over. The 
;				significance level will increase with greater 
;				smoothing. With no smoothing, all results are  
;				insignificant (siglevel = 0). 
;				n_smooth will default to 0.5*DF if that 
;				keyword is supplied otherwise 3 is used.
;			DF	 = degrees of freedom to be achieved. 
;				NB: there are 2 d.f. per spectral estimate.
;
; OUTPUTS:
;
;   KEYWORD PARAMETERS:
;			XSPEC	= the complex cross-spectrum used.
;				  vector of same length as ts1 and ts2 
;			SMXSPEC	= the smoothed complex cross-spectrum used
;				  vector of same length as ts1 and ts2 
;			SIGLEVELS = normalised significance levels. 
;				  vector of same length as ts1 and ts2 
;					0 ==> not significant
;					1 ==> very highly significant
;			CONFIDENCE = 90% confidence intervals. 
;				 (n,2) element vector where n = length of ts1.
;				 CONFIDENCE(*,0) = lower limit of 90% interval
;				 CONFIDENCE(*,1) = upper limit of 90% interval
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: R.A.Vincent, Physics Dept., University of Adelaide,
;		Early 1989.
;	Enhanced:   T.J.Harris, Physics Dept., University of Adelaide,
;		Late 1989.
;
;-
	function coherency, ts1,ts2, n_smooth, df=df,$
		xspec=xspec, smxspec=smxspec, $
		siglevels=siglevels, confidence=confidence

	t99 = [3182,696,454,375,336,314,300,290,282,276,272,268,265,262,260,258,257,255,254,253,252,251,250,249,248,248,247,247,246]*0.01
	t90 = [308,189,164,153,148,144,142,140,138,137,136,136,135,134,134,134,133,133,133,132,132,132,132,132,132,132,131]*0.01
	t70 = [727,617,584,569,559,553,549,546,543,542,540,539,538,537,536,535,534,534,533,533,532,532,532,531]*0.001

	ft1 = fft(ts1,-1)
	ft2 = fft(ts2,-1)

	xspec  = ((ft1)*conj(ft2))
	aspec1 = float((ft1)*conj(ft1))
	aspec2 = float((ft2)*conj(ft2))
	
	if (n_elements(n_smooth) le 0) then $
		if (keyword_set(df)) then n_smooth = 0.5*df else n_smooth=3

	;need to average the spectra before applying the coherency
	smxspec  = smooth(xspec ,n_smooth)
	smaspec1 = smooth(aspec1,n_smooth)
	smaspec2 = smooth(aspec2,n_smooth)

	coh = smxspec/sqrt(smaspec1*smaspec2)

	df = 2*n_smooth
	if (keyword_set(siglevels)) then $
			siglevels = (1.-(1.-abs(coh)^2)^(0.5*df-1)) > 0.0

	if (keyword_set(confidence)) then begin
		coh_est = abs(coh)
		confidence = fltarr(n_elements(coh_est),2)
		bias_correction = (1-coh_est^2)/(2.*df)
		coh_est = coh_est - bias_correction
		Z = 0.5*(alog(1+coh_est)-alog(1-coh_est)) - 1./(df-2.)
		varZ = 1./(df-2.)
		var90 = t90((df-1)<(n_elements(t90)-1))*varZ
		confidence(*,0) = tanh(Z-var90) > 0.
		confidence(*,1) = tanh(Z+var90) > 0.
		tmp = where(finite(confidence) eq 0, count)
		if (count gt 0) then confidence(tmp) = 0.
	endif

	return,coh
	end


