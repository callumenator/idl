;---------------------------------------------------------------------
	pro date_label,year,range,yaxis=yaxis,xaxis=xaxis,first=first,mid=mid,$
		title=title, none=none, num_ticks=num_ticks, nminor=nminor, $
		noyear=noyear, allmonths=allmonths
;+
; NAME:				date_label
;
; PURPOSE:			Label a time axis with meaningful dates/time
;				The JHUAPL routine "timeaxis" generally does 
;				a better job, with more flexible labelling 
;				format. DATE_LABEL works best for time ranges 
;				from a few days to several years.
;
; CATEGORY:			Utility
;
; CALLING SEQUENCE:		
;		date_label, year, range, YAXIS=yaxis, XAXIS=xaxis, $
;			FIRST=first, MID=mid, TITLE=title, NONE=none, $
;			NUM_TICKS=num_ticks, NMINOR=nminor, $
;			NOYEAR=noyear, ALLMONTHS=allmonths
;
; INPUTS:
;		year	= the year of the first day in the range
;		range 	= the range of the data in DAYS 
;			  (will default to one of !x.range or !y.range)
;	KEYWORDS:
;		yaxis,xaxis	= set one or the other to define either the 
;				  x or y axis as the time-axis
;		first,mid	= put ticks either at the first or at the 
;				  middle day of each month
;		title		= title to label axis with
;		none		= dont put the days in the labels
;		num_ticks	= number of ticks to use (a suggestion only)
;		nminor		= number of minor ticks
;		noyear		= dont put years in the label
;		allmonths	= put every month in the labels. 
;				  The default is to choose the middle months  
;				  of each season, or every second month  
;				  (dependent on the time range),  
;				  if the time range allows.
;
; OUTPUTS:		none
;
; COMMON BLOCKS:
;			none.
; SIDE EFFECTS:
;			Changes either the !x or !y system variables.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-

; NOTE: 
;	year			-- is the year of the first day in the range
;	range (or !x/y.range)	-- the range of the data in DAYS
;
	nticks = 24
	nminor = 3
	if (keyword_set(xaxis)) then begin 
		trange=!x.range
		nticks = !x.ticks
	endif
	if (keyword_set(yaxis)) then begin
		trange=!y.range
		nticks = !y.ticks
	endif
	if (keyword_set(num_ticks)) then nticks = num_ticks
	if (n_elements(range) le 0) then range = trange
	if (n_elements(range) le 0) then range = [0,0]
	if (nticks le 0) then nticks = 24

	if (range(0) ne range(1)) then begin
		days = findgen(range(1)-range(0)+1)+range(0)
		daymonth,year,days, months,dom,ndays,mthnum,year=yrs
		mths = mthnum
		first_of_mth = dom
		labelthese = 0
		numjans = 0 & numjuls = 0 & numaprs = 0 & numocts = 0
		if (keyword_set(first)) then begin
			st_day = 1
			first_of_mth = where(dom eq st_day,count) 
		endif else if (keyword_set(mid)) then begin
			st_day = 15
			first_of_mth = where(dom eq st_day,count) 
		endif else begin
			st_day = 1
			first_of_mth = where(dom eq st_day,count) 
			if (count le 0) then begin
				st_day = 15
				first_of_mth = where(dom eq st_day,count) 
			endif 
		endelse
		if (count gt 0) then begin
		    title = 'Time'

		    mthnum = mthnum(first_of_mth)
		    jans = where(mthnum eq 1,numjans)
		    juls = where(mthnum eq 7,numjuls)
		    aprs = where(mthnum eq 4,numaprs)
		    octs = where(mthnum eq 10,numocts)

		    if (keyword_set(allmonths)) then begin
			labelthese = first_of_mth
			nminor = -1
		    endif else begin
			nminor = 3
			if (numjans gt 0) then begin
			    if (numjans lt nticks/2) then $
				if (numjuls gt 0) then $
				     labelthese = first_of_mth([jans,juls])$
				else labelthese = first_of_mth(jans) $
			    else labelthese = first_of_mth(jans)
			endif else $
			    if (numjuls gt 0) then $
				 labelthese = first_of_mth(juls) $
			    else labelthese = first_of_mth
			if (n_elements(labelthese) lt (nticks+1)/2) then begin
				;add on aprils and octobers
				if (numaprs gt 0) then $
				     labelthese=[labelthese,first_of_mth(aprs)]
				if (numocts gt 0) then $
				     labelthese=[labelthese,first_of_mth(octs)]
			endif
		    endelse
		endif
		;if (keyword_set(allmonths)) or ((n_elements(labelthese) lt 3) $
		if (n_elements(labelthese) lt 3) $
		and ((numjans<numjuls<numaprs<numocts) eq 1) then begin
			;add the rest of the months
			title = 'Time of Year'
			tmp = [2,3,5,6,8,9,11,12]
			for i=0,n_elements(tmp)-1 do begin
			  mths = where(mthnum eq tmp(i),count)
			  if (count gt 0) then $
			     labelthese=[labelthese,first_of_mth(mths)]
			endfor
		endif
		day_vals = 0	&	hrs_vals = 1
		if (n_elements(labelthese) lt 3) then begin
			;use days instead
			title = 'Days'
			day_vals = 1
			labelthese = indgen(n_elements(days))
		endif

		labelthese = ticklimit(labelthese,nticks)
		if (keyword_set(noyear)) then yrstr = ' ' $
			else yrstr = string(yrs(labelthese),format='(i2.2)')
		months = months(labelthese)
		dom = dom(labelthese)
		if (keyword_set(none)) then daystr = ' '  $
			else daystr = string(st_day,format='(i2.2)')
		if (day_vals) then daystr = string(dom,format='(i2.2)')

		tickname = strcompress(daystr+months+yrstr,/rem)
		;tickv = days(labelthese)
		yrs = yrs(labelthese)
		mths = mths(labelthese)
		n = n_elements(dom)
		ydhms = timfmtconv(transpose([[dom],[mths],[yrs],[findgen(n)],[findgen(n)],[findgen(n)]]))
		tickv = ydhms(1,*)+leapyr(yrs)-leapyr(year)+365*(yrs-year)
		order = sort(tickv)
		tickv = tickv(order)
		tickname = tickname(order)
		months = months(order)
		daystr = daystr(order)
		yrstr = yrstr(order)
		if (day_vals) then begin
			if (n_elements(tickv) lt 3) then begin
				;use hours instead
				daystr = tickname(0)
				title = 'Hours from '+daystr
				;tick every 3 hours
				tickv = dindgen((range(1)-range(0)+1)*24./3.)*3./24.+range(0)
				tickv = (tickv > range(0)) < range(1)
				;round down to nearest hour
				tickv = fix(tickv*24.)/24.
				tickv = tickv(uniq(tickv,sort(tickv)))
				tickname = string(tickv*24. mod 24.,$
								form='(i2.2)')
				nminor = 3
			
				if (n_elements(tickv) lt 3) then begin
					;use minutes instead
					title = 'Minutes from '+daystr+' '+tickname(0)+':00'
					;tick every 5 minutes
					tickv = dindgen((range(1)-range(0)+1)*24*60./5.)*5./60./24.+range(0)
					;round down to nearest minute
					tickv = fix(tickv*24.*60.)/24./60.
					tickv = (tickv > range(0)) < range(1)
					tickv = tickv(uniq(tickv,sort(tickv)))
					tickname = string(tickv*24.*60. $
						mod 60., form='(i2.2)')
					nminor = 5
			
				endif
			endif else begin
				tickname(1:n_elements(tickname)-2) $
					= [' ',strmid(tickname(2:n_elements(tickname)-3),0,2),' ']
				nminor = dom(1) - dom(0)
			endelse
		endif else if (numjuls+numjans ge 7) then begin
			tmp = where( months eq 'Jul', count)
			if (count gt 0) then begin
				tickname = '19'+yrstr(tmp)
				tickv = tickv(tmp)
				;;;;;nticks = count-1
				nminor = 4
				if (st_day eq 15) then tickv = tickv - 14
			endif
		endif
		nticks = n_elements(tickv)-1
		if (keyword_set(xaxis)) then begin
			!x.tickname = tickname
			!x.tickv = tickv
			!x.ticks = nticks
			!x.minor = nminor
		endif else begin
			!y.tickname = tickname
			!y.tickv = tickv
			!y.ticks = nticks
			!y.minor = nminor
		endelse
	endif
	
	return
	end

