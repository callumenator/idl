;-------------------------------------------------------------------
;+
; NAME:			demod
;
; PURPOSE:		perform a complex-demodulation
;			Shifts wanted frequency down to base-band.
; 			Then applies a low-pass filter
;
; CATEGORY:		Time-series/Spectral analysis
;
; CALLING SEQUENCE:	demod,time-series,ampl,phase,period,df=df
;			demod,time-series,ampl,phase,period,fil_per,df=df
;
; INPUTS:
;			time-series = input time series (possibly complex)
;			period	    = period for the complex-demodulation

;   OPTIONAL PARAMETERS:
;		One of these parameters must be specified in order to 
;		determine the bandpass to use
;			fil_per     = cutoff index of bandpassed filter 
;					(1 or 2 element vector)
;			DF	    = degrees of freedom to be achieved.
;
; OUTPUTS:
;			ampl,phase  = amplitude and phase of the 
;					complex-demodulated time-series
;
;   OPTIONAL PARAMETERS:
;			DF	    = degrees of freedom achieved.
;
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

		PRO demod,s,amp,phase,period,fil_per,df=df
	;s = input array (float)
	;amp = output amplitude of complex demodulated function
	;phase = phase of above
	;period = index for demodulation
	;fil_per = cut-off index of bandpassed filter (1 or 2 element vector)
	;( or uses df=degrees of freedom to determine bandpass)
	;df = degrees of freedom output from bandpass used
	;Complex demodulation shifts wanted frequency down to base-band. Then
	; applies lo_pass filter
	
	npt = n_elements(s)
	nmax=npt-1

	t = findgen(npt)*2.0*!pi/period
	cdemod = complexarr(npt)
	cdemod = complex(cos(t),-sin(t))
	cdemod = s*cdemod

	if (n_elements(fil_per) gt 0) then pl = fil_per(0) $
	else if (keyword_set(df)) then begin
		;find fil_per from degrees of freedom
		pl = 1./(df*0.5/npt + 1./period)
	     endif else pl = 1.0

	if (n_elements(fil_per) gt 1) then ph = fil_per(1) else ph = pl

	lpass = npt*max(abs([1./pl,1./ph]-1./period))
	cdemod = filter(cdemod,lpass,/lowpass,/freq)
	;lpass = fix(lpass)
	;cdemod1  = fft(cdemod,-1)
	;cdemod1(lpass+1:nmax-lpass)=0.0
	;cdemod1=fft(cdemod1,1)
	amp=abs(cdemod)
	phase=atan(imaginary(cdemod),float(cdemod))

	;degrees of freedom = 2 for each spectral estimate in bandpass
	;bandpass is 2*lpass+1 spectral estimates
	;npt estimates per frequency unit
	df = 2*fix(2.*lpass+1.5)
	return
	end


