;-----------------------------------------------------------------
		pro daymonth, year, in_days, month, dayofmth, ndays, mthnum, $
					year=yrs, days=day
;+
; NAME:		daymonth
;
; PURPOSE:
;	This subroutine returns a 3 char mnemonic for month (lower case),
;	the day in the month, the number of days in the month,
;	and the month number, when given a year number and day of the year
;	NB: Leap years ARE taken into accoount

;	if the day is invalid then  dayofmth = -1
;
; CATEGORY:	Utility
;
; CALLING SEQUENCE:
;		daymonth, year, days, month, dayofmth, ndays, mthnum, $
;					YEAR=year, DAYS=day
;
; INPUTS:
;		year	= year values of data. May be an array
;		days	= day of year for the input year values.
;			These values may be fractional and may extend beyond 
;			day 366.
;
; OUTPUTS:
;		month	= 3 character mnemonic for the month (in lowercase), 
;			of same dimension as "days"
;		dayofmonth = the day of month for each element in "days"
;		ndays	= the total number of days in the month
;		mthnum	= month number froim 1-12
;
;	KEYWORDS:
;		YEAR	= an array of same dimensions as "days" containing 
;			  the years for each element of "days"
;		DAY	= the day of year (given in output keyword YEAR)
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		17 Nov, 1988.
;
;	modified so that if the doy is greater than the number of days
;	in the year then the year will be incremented
;	T.J.H.  23/10/89
;
;	modified so that the doy can be fractional (by integerising doy)
;	T.J.H.  20/07/91
;-
;
		 
	days_in_mth 	= [31,28,31,30,31,30,31,31,30,31,30,31]
	sum_days_in_mth	= [0,31,59,90,120,151,181,212,243,273,304,334,366]
	mth = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'] 

	sz = size(in_days)
	if (sz(n_elements(sz)-2) ge 4) then $ ;convert to integer type
		day=fix(in_days+0.99999) else day=in_days
	n = n_elements(day)
	if (n_elements(year) eq 1) then yrs=replicate(year(0),n) else yrs=year
	leapyrday = leapyr(yrs)
	daysinyr = 365 + leapyrday
	days_in_mth(1) = days_in_mth(1) + leapyrday(0)
	;sum_days_in_mth(2:*) = sum_days_in_mth(2:*) + leapyrday
	
	count = 1
	while(count gt 0) do begin
		addone = where(day gt daysinyr,count)
		if (count gt 0) then begin
			yrs(addone) = yrs(addone) + 1
			day(addone)  = day(addone) - daysinyr(addone)
		endif
	endwhile

	sum_days = replicate(1,n)#sum_days_in_mth
	for i= 2,12 do sum_days(*,i) = sum_days(*,i) + leapyrday(*)
	mthnum = intarr(n)
	dayofmth = mthnum*0 -1
	
	for i=0L,n-1 do mthnum(i) = (min(where(day(i) le sum_days(i,*)))-1) > 0
	ndays = days_in_mth(mthnum)
	month = mth(mthnum)
	for i=0L,n-1 do dayofmth(i) = (day(i) - sum_days(i,mthnum(i)))>1 
	mthnum = mthnum+1
	return
	end
	

