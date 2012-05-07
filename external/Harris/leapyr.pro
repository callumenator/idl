;-----------------------------------------------------------------
	function leapyr,year
;+
; NAME:			leapyr
;
; PURPOSE:		determine whether the input year is a leap year or not
;			Very useful for finding number of days in a year.
;			eg. NUM_DAYS_IN_YR = 365 + leapyr(year)
;
; CATEGORY:		Utility
;
; CALLING SEQUENCE:	result = leapyr(year)
;
; INPUTS:		year	= test if year is a leap year 
;				  year may be a vector and may be in the  
;				  form MCDU eg. 1788 else defaults to 19XX
;
; OUTPUTS:		result 	= 0 then not a leap year
;				= 1 then year is a leap year
;				= (399+(yr mod 400))/400 - (3+(yr mod 4))/4
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		20/09/88
;
;-

;	this function returns with an I*4 value of :-
;						1  if year is a leap year
;						0  if year is not a leap year
;	T.J.H. 20/09/88

;   	Note:  year must be in the form MCDU eg. 1788  else defaults to 19XX

	
	yr = year
	tmp = where(yr lt 100,count)
	if (count gt 0) then yr(tmp) = yr(tmp)+1900 ;make it the 20th century 
	
	return,(399+(yr mod 400))/400 - (3+(yr mod 4))/4
	
	end
