	function season, doy, year
;+
; NAME:	season
;
; PURPOSE:
;	given input date outputs season in code
;		0  -- summer
;		1  -- autumn
;		2  -- winter
;		3  -- spring
;
;	handles doy > 365, given year = startyr 
;	leap years are handled using routine LEAPYR
;
; CATEGORY:	Utility function
;
; CALLING SEQUENCE:	result = season(doy, year)
;			summer = where(season(doy, year) eq 0)
;
; INPUTS:
;		doy  = vector containing the day-of-year. Handles doy > 365
;		year = either vector containing the year for each doy or a 
;		       single year which applies to all the doy
;
; OUTPUTS:
;		result = vector of same number of elements as doy containing
;			the code for each season
;			0  -- summer
;			1  -- autumn
;			2  -- winter
;			3  -- spring
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-

;	from the fortran function of 18/10/90 T.J.H.
;
;	given input date outputs season in code
;		0  -- summer
;		1  -- autumn
;		2  -- winter
;		3  -- spring
;
;	Mod 18/10/90 to handle doy > 365, given year = startyr 
;								T.J.H

	;limits = [ 335, 244, 152, 60, 0 ]
	limits = [ 0, 60, 152, 244, 335 ]
		
	cdoy = doy
	if (n_elements(year) lt n_elements(doy)) then $
		cyear = replicate(year(0),n_elements(doy)) $
	else cyear = year
	anotheryr = where(cdoy gt 365+leapyr(cyear),count)
	while (count gt 0) do begin
		cdoy(anotheryr) = cdoy(anotheryr)-365-leapyr(cyear(anotheryr))
		cyear(anotheryr) = cyear(anotheryr)+1
		anotheryr = where(cdoy gt 365+leapyr(cyear),count)
	endwhile

	output = cdoy*0+99
	for i=0,4 do begin
		season = where(cdoy gt limits(i),count)
		if (count gt 0) then output(season) = (i mod 4)
	endfor
	
	return,output

	end





