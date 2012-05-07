	pro get_times, fulldates, mdate, num_plts, title=title

;+
; NAME:
;	GET_TIMES
;
; PURPOSE:
;	To allow interactive selection from a series of dates
;
; CATEGORY:
;	Utility
;
; CALLING SEQUENCE:
;	GET_TIMES, fullsetdates, mdate, num_plts, TITLE=title
;
; INPUTS:
;	fullsetdates = array(5,*) containing the full set of dates from
;		which the choice can be made. Must be an integer or real
;		array 5xNUMBERCHOICES.
;		The 5 elements are assumed to be [day,mth,year,hour,minutes]
;	TITLE = this will be the title displayed (replacing the default)
;
; OUTPUTS:
;	mdate = array(5,num_plts) will contain the "num_plts" selected dates, 
;	by recursively calling DATE_SEL
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		March, 1991
;
;-
	    if (n_elements(title) le 0) then title=' '
	    plotloop = 1
	    answer = ' '
	    while (plotloop le num_plts) do begin
		looptitle = strtrim(title,2)+string(plotloop,format="(' TIME (',i2,')')")
		tmpdate = mdate(*,plotloop-1)
		date_sel, fulldates,tmpdate,title=looptitle
		if (tmpdate(0) le 0) then begin
			print,' Enter the NEW '+strtrim(title,2)+' DATES (dd/mm/yy hhmm) '
			read,answer
			index = strpos(answer,'/')
			day = strcompress(strmid(answer,0,index),/rem)
			if (strpos('*??',day) lt 0) then day=fix(day) $
			else day = fulldates(0,0:num_plts-1)
			i = strpos(answer,'/',index+1)
			mth = strcompress(strmid(answer,index+1,i-index),/rem)
			if (strpos('*??',mth) lt 0) then mth=fix(mth) $
			else mth = fulldates(1,0:num_plts-1)
			index = strpos(answer,' ',i+1)
			yr = strcompress(strmid(answer,i+1,index-i),/rem)
			if (strpos('*??',yr) lt 0) then yr=fix(yr) $
			else yr = fulldates(2,0:num_plts-1)
			hr = strcompress(strmid(answer,index+1,77),/rem)
			if (strpos('*??',hr) lt 0) then hr=fix(strmid(hr,0,2))$
			else hr = fulldates(3,0:num_plts-1)
			tmpdate = intarr(5,num_plts)
			tmpdate(0,*) = day
			tmpdate(1,*) = mth
			tmpdate(2,*) = yr
			tmpdate(3,*) = hr
			tmpdate(4,*) = 0

			if (min(tmpdate eq shift(tmpdate,1))) then begin
				mdate(*,plotloop-1) = tmpdate(*,0) 
			endif else begin
				mdate = tmpdate
				plotloop = num_plts
			endelse
		endif else mdate(*,plotloop-1) = tmpdate
		plotloop = plotloop+1
	    endwhile

	return
	end






