;-------------------------------------------------------------------
		function filter,in,pl,ph,freq=freq,time=time,notch=notch,$
		       	lowpass=lowpass,highpass=highpass,bandpass=bandpass,$
                        type=type, wts=freq_filter_wts
;+
; NAME:			filter
;
; PURPOSE:		perform digital filtering in the frequency domain 
;			via FFT
;
; CATEGORY:		Time-series/Spectral analysis
;
; CALLING SEQUENCE:	
;			result = filter(time_series, /TIME, $
;			     lowperiod_cutoff, highperiod_cutoff, /BANDPASS)
;
;			result = filter(time_series, /FREQ, $
;			     lowfreq_cutoff, highfreq_cutoff, /BANDPASS)
;
;			result = filter(time_series, /FREQ, $
;			     lowfreq_cutoff, highfreq_cutoff, /NOTCH)
;
;			result = filter(time_series, maxperiod, /LOWPASS)
;
;			result = filter(time_series, $
;			     highfreq_cutoff, /FREQ, /LOWPASS)
;
;			result = filter(time_series, $
;			     lowfreq_cutoff, /FREQ, /HIGHPASS)
;
;			result = filter(time_series, /FREQ, WTS = wts)
;
; INPUTS:	time_series = input time series to filter
;		low_cutoff, high_cutoff = the limits (either in 
;			frequency or time, dependent on the keyword usage) for 
;			the filter. Only one paramter is required if the filter
;			is one-sided (LOWPASS or HIGHPASS). These paramters 
;			are ignored if the WTS keyword is used
;	KEYWORD PARAMETERS:
;		FREQ, TIME = signals how the cutoff parameters will be 
;			interpretted. Either as PERIODS in the time domain or 
;			FREQUENCIES in the frequency domain. Default is /TIME
;			These paramters	are ignored if the WTS keyword is used
;		LOWPASS = low-pass filter. Use the first cutoff parameter as 
;			the step function cutoff value 
;		HIGHPASS = high-pass filter. Use the first cutoff parameter as 
;			the step function cutoff value  
;		BANDPASS = band-pass filter. Use both cutoff parameters as 
;			the limits of the rectangular pass window. 
;		NOTCH    = notch filter. Use both cutoff parameters as 
;			the limits of the rectangular rejection window.
;		WTS 	= independently set the window weights in the 
;			frequency domain. This will override all other 
;			parameters.
;		TYPE 	= can have 1 of four values (case insensitive). 
;			"LOWPASS", "HIGHPASS", "NOTCH", "FREQ_FILTER_WTS"
; OUTPUTS:
;		result  = filtered time series 
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

	;in = input time series (may be complex)
	;pl and ph are the appropriate cutoff periods in time units
	; or freq units if keyword 'freq' set.
	;pl,ph included in the pass band
	;freq_filter_wts will override all other parameters and be used as 
	;the filter weights


	if (keyword_set(lowpass))  then type = 'lowpass'
	if (keyword_set(highpass)) then type = 'highpass'
	if (keyword_set(bandpass)) then type = 'bandpass'
	if (keyword_set(notch))    then type = 'notch'
	if (keyword_set(freq_filter_wts)) then begin
		type = 'freq_filter_wts'
		pl = 0	& ph = 0
	endif
	
	sz = size(in)
	nmax = sz(sz(0)+2)
	datatype = sz(sz(0)+1)
	ntop = nmax-1
	temp = complexarr(nmax)
	if (datatype ne 6) then temp = complex(in) else temp = in
	temp = fft(temp,-1)

	if (n_elements(ph) le 0) then ph = pl
	temp2 = ph > pl
	pl = pl < ph
	ph = temp2

	if (keyword_set(freq)) then begin
		;the bandpass limits are in frequency units 0 --> ntop/2
		npl = (fix(pl) > 0) < ntop
		nph = (fix(ph) > 0) < ntop
	endif else begin
		;the bandpass limits are in time units 0 --> nmax
		npl = (fix(float(nmax)/ph) > 0) < ntop
		nph = (fix(float(nmax)/pl) > 0) < ntop
	endelse

	temp2 = nph > npl
	npl = npl < nph
	nph = temp2

	CASE (strupcase(type)) OF
	'LOWPASS':  begin
        	       	if (npl lt ntop) then temp(npl+1:ntop-npl) = 0.0
        	    end
	'HIGHPASS': begin
		       	if (npl gt 0) then temp(0:npl-1) = 0.0
		       	if (npl gt 2) then temp(ntop-npl+2:ntop) = 0.0
	   	    end
	'BANDPASS': begin
		       	;if (npl gt 0) then temp(0:npl-1) =0.0
		       	;if (nph lt ntop) then temp(nph+1:ntop-nph) =0.0
		       	;if (npl gt 2) then temp(ntop-npl+2:ntop) =0.0
			temp2 = temp
			temp = temp2 * 0.0
		       	temp(npl:nph) = temp2(npl:nph)
		       	temp(ntop-nph+1:ntop-npl+1)=temp2(ntop-nph+1:ntop-npl+1)
		    end
	'NOTCH':    begin
		       	temp(npl:nph) =0.0
		       	temp(ntop-nph+1:ntop-npl+1)=0.0
        	    end
	'FREQ_FILTER_WTS': temp = temp*freq_filter_wts
	ENDCASE        
	return,fft(temp,1)
	end


