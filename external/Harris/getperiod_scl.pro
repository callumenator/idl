;------------------------------------------------------------------------------
	pro getperiod_scl,Ttickv,Ttickname,Tminortickv,nticks=nticks,$
		scale=scale,xaxis=xaxis,yaxis=yaxis,mnticks=mnticks,$
		factor=factor,labelfraction=labelfraction

;+
; NAME:		getperiod_scl
;
; PURPOSE:	to calculate the positions of the ticks for a period scale,
;		when the main scaling is linear in frequency.
;
; CATEGORY:	utility
;
; CALLING SEQUENCE:
;		getperiod_scl,period_tick_values,period_tick_names,
;		minor_tick_values,nticks=nticks,scale=scale,
;		xaxis=xaxis,yaxis=yaxis,mnticks=mnticks,factor=factor,
;		labelfraction=labelfraction
;
; INPUTS:	none (but the plot scaling must already be defined,
;			so a call to plot,/nodata,/noerase,xstyle=4,ystyle=4
;			may be required before calling this procedure)
;
;		NOTE: set !x.minor or !y.minor = -1 to inhibit auto-minor 
;			ticks when calling axis
;
; OUTPUTS:
;		(all parameters are optional. If no parameters given then the
;			system parameters !(x/y).tickv and !(x/y).tickname will
;			be set. The default axis is the x-axis)
;
;		period_tick_values = an array that can be used in the tickv 
;				parameter in axis to draw a period scale
;		period_tick_names = an array that can be used in the tickname
;				parameter in axis to label the period scale
;		minor_tick_values = an array that can be used in the tickv 
;				parameter in axis to draw minor ticks for the
;				period scale
;
;   KEYWORD PARAMETERS:
;
;		nticks = the nominal number of major ticks to draw
;			The actual number may be different depending on the 
;			frequency limits of the plot scale.
;			The number of minor ticks will be a multiple of this
;			number < 30 unless keyword mnticks set
;			This is output as the correct number of major-ticks
;
;		mnticks = the nominal number of minor ticks to draw
;			This is output as the correct number of minor-ticks
;
;		factor = the number of minor ticks for each major tick
;			(remember that mnticks limitted to < 30)
;
;		scale = the scaling to apply to the frequency, to give
;			appropriate period ranges. 
;			EG: scale=24. for frequencies in cycles/day to give
;				periods in hours
;
;		xaxis,yaxis = which system variable to use to get the plot
;			scaling from. Default is xaxis
;
;		labelfraction = the fraction of the frequency scale to label
;			down to. Default is 0.125
;			Normally, if the frequency scale is linear, then the
;			periods will cluster at the low frequency end.
;			Sometimes this causes a multitude of ticks at the low 
;			frequency end. 
;			Especially as the minimum frequency --> 0
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none if parameters have been passed,
;	otherwise !(x/y).ticks,.tickname,.tickv are changed to be period scales
;		and !(x/y).minor set to -1 to inhibit minor ticks
;
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		May, 1991.
;
;-
	if (not keyword_set(nticks)) then nticks = 5
	if (keyword_set(yaxis)) then begin
		;if (not keyword_set(nticks)) then nticks = !y.ticks
		minf = !y.crange(0)
		maxf = !y.crange(1)
	endif else begin
		;if (not keyword_set(nticks)) then nticks = !x.ticks
		minf = !x.crange(0)
		maxf = !x.crange(1)
	endelse
	frange = maxf-minf
	if (not keyword_set(labelfraction)) then labelfraction = 0.125
	fstep = frange*labelfraction
	nticks = nticks+1

	if (not keyword_set(factor)) then factor = 4.0

	if (not keyword_set(scale)) then scale = 1.

	if (maxf gt 0) then minT = float(scale)/maxf else minT = 0.0
	if (minf gt 0) then maxT = float(scale)/minf else maxT = minT/labelfraction

	Trange = maxT-minT
	if (long(Trange) lt 1) then $
		print,'GETPERIOD_SCL : the scaled Trange is less than 1.0 '
	
	step = rnd(Trange/nticks,factor,/down) > 1.0
	mstep = step/factor
	minT = rnd(minT,mstep,/up)
	maxT = rnd(maxT,mstep,/down)

	if (not keyword_set(mnticks)) then mnticks = factor*nticks+1
	mnticks = mnticks < 28

	Ttickv = fltarr(nticks+1)
	Tminortickv = fltarr(mnticks+1)
	Ttickname = replicate(' ',nticks+1)
	Ttickv(indgen(nticks)) = rnd((indgen(nticks)*step + minT),2,/up)
	Ttickv(0) = rnd(minT,2,/up)
	Ttickv(nticks) = rnd(maxT,2,/down)
	Tminortickv(indgen(mnticks)) = (indgen(mnticks)*mstep + minT) < long(maxT)
	Ttickv = reverse(Ttickv)
	Tminortickv = reverse(Tminortickv)
	Ttickv = scale/float(Ttickv)
	limit = where((Ttickv ge minf)and(Ttickv le maxf),count)
	if (count gt 0) then Ttickv = Ttickv(limit) else Ttickv = [0.0,1.0]
	Tminortickv = scale/float(Tminortickv)
	limit = where((Tminortickv ge minf)and(Tminortickv le maxf),count) 
	if (count gt 0) then Tminortickv = Tminortickv(limit) else Tminortickv = [0.0,1.0]

	Ttickname = strtrim(string(scale/Ttickv,format='(i)'),2)

	;reduce the main tick array to only the unique values
	dist = abs(Ttickv - shift(Ttickv,1))
	unique = where(dist gt 0) > 0
	Ttickv = [Ttickv(unique)]
	Ttickname = [Ttickname(unique)]
	dist = [dist(unique)]

	;
	; ensure that there is enough space between ticks to write labels 
	;
	if (n_elements(unique) gt 3) then begin
		dont_label_these = where(dist lt fstep,count) 
		if (count gt 0) then begin
			dont_label_these = dont_label_these(where(dont_label_these ne dont_label_these+1))
			Ttickname(dont_label_these) = ' '
		endif
	endif

	;reduce the minor tick array to only the unique values
	dist = abs(Tminortickv - shift(Tminortickv,1))
	unique = where(dist gt 0) > 0
	Tminortickv = [Tminortickv(unique)]

	; set the number of tick spacings to the correct values
	nticks = (n_elements(Ttickv)-1) > 1
	mnticks = (n_elements(Tminortickv)-1) > 1

	if (n_params() eq 0) then $
		if (keyword_set(yaxis)) then begin
			!y.ticks = nticks
			!y.tickv = [Ttickv,0]
			!y.tickname = [Ttickname,' ']	
			!y.minor=-1
		endif else begin
			!x.ticks = nticks
			!x.tickv = [Ttickv,0]
			!x.tickname = [Ttickname,' ']	
			!x.minor=-1
		endelse

	return
	end
