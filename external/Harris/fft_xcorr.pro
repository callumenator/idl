;------------------------------------------------------------------
		function fft_xcorr, tdata1, tdata2, normal_factor=nf
;+
; NAME:			fft_xcorr
;
; PURPOSE:		Perform a cross-correlation using an FFT
;
; CATEGORY:		Time-Series/Spectral analysis
;
; CALLING SEQUENCE:	fft_xcorr, tdata1, tdata2, NORMAL_FACTOR=nf
;
; INPUTS:		tdata1,tdata2 = (Complex) vectors containing the 
;					time series
;
; OUTPUTS:
;   KEYWORD PARAMETERS:	NORMAL_FACTOR = the normalisation factor used. 
;					This allows the user to recreate the  
;					Covariance function
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
	MOD 6/11/92	T.J.H.	needed to shift the function by n/2
;
;-

	mean1 = total(tdata1)/n_elements(tdata1)
	mean2 = total(tdata2)/n_elements(tdata2)

	mctdata1 = tdata1 - mean1
	mctdata2 = tdata2 - mean2

	freq1 = fft(mctdata1,1)
	freq2 = fft(mctdata2,1)

	xcov = fft(freq1*conj(freq2),-1)
	;;MOD 6/11/92		need to shift the function by n/2
	xcov = shift(xcov,n_elements(xcov)/2)

	nf1 = sqrt(total(mctdata1*mctdata1))
	nf2 = sqrt(total(mctdata2*mctdata2))
	nf = nf1*nf2

	return,xcov/nf
	end


