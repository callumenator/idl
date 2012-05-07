;-----------------------------------------------------------------
		pro mthnumday,mthnumber,year,stday,ndays,month
;+
; NAME:		mthnumday
;
; PURPOSE:
;	This subroutine calculates the day number of the start of the month,
;	the number of days in the month, and a 3 char mnemonic for month 
;	(lower case), when given a year number and the month number
;	if the month number is invalid then stday=-1
;
; CATEGORY:	Utility
;
; CALLING SEQUENCE:
;		mthnumday,mthnumber,year,stday,ndays,month
;
; INPUTS:
;		mthnumber = months from the set [1,12]
;		year	= year values of data. May be an array
;
; OUTPUTS:
;		stday	= start day of year for the months
;		ndays	= number of days in the months
;		month	= 3 character mnemonic for the month (in lowercase), 
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		17 Nov, 1988.
;
;-
;
;	this subroutine calculates the day number of the start of the month,
;	the number of days in the month, and a 3 char mnemonic for month 
;	(lower case), when given a year number and the month number
 
;	if the month number is invalid then stday=-1
 
	
	days_in_mth 	= [31,28,31,30,31,30,31,31,30,31,30,31]
	stday_of_mth	= [0,31,59,90,120,151,181,212,243,273,304,334,366]
	mth = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'] 
	sz = size(reform(year))
	sum_days = stday_of_mth#(year*0+1)
	for i=2,12 do sum_days(i,*) = sum_days(i,*) + leapyr(year)

	mthnum = mthnumber - 1
	
	sz = size(reform(mthnum))
	ndays = reform(mthnum*0)
	month = replicate('xxx',sz(1))
	stday = reform(mthnum*0)-1
	good = where((mthnum ge 0) and (mthnum le 11),count)
	
	if (count gt 0) then begin
		stday(good) = sum_days(mthnum(good),good)+1
		ndays(good) = days_in_mth(mthnum(good))
		month(good) = mth(mthnum(good))
	endif
		
	return
	end
	

