;----------------------------------------------------------------------------
	function ticklimit,tickvals,ticks,xaxis=xaxis,yaxis=yaxis
;+
; NAME:			ticklimit
;
; PURPOSE:		Ensure that the number of ticks/tickvalues is less 
;			than 30, the limit set by IDL. If the number of  
;			tickvals is larger than 30 then every second tick is  
;			chosen, and the number checked again. The end values  
;			are retained though.
;
; CATEGORY:		Utility
;
; CALLING SEQUENCE:	newtickvals = ticklimit,tickvals
;			newtickvals = ticklimit,tickvals,ticks
;			newtickvals = ticklimit,tickvals,/yaxis
;
; INPUTS:
;			tickvals = vector of tick values whose number of 
;				elements is to be limited
;
;   OPTIONAL PARAMETERS:
;			ticks = if present then use this as the limitting 
;				number of ticks
;   KEYWORD PARAMETERS:
;			XAXIS,YAXIS = if set then use !x.axis/!y.axis as the 
;				limitting number of ticks
;
;
; OUTPUTS:
;   OPTIONAL PARAMETERS:
;			ticks = if present then use the actual number of ticks
;				needed is written out to this variable
;   KEYWORD PARAMETERS:
;			XAXIS,YAXIS = if present then use the actual number of 
;				ticks needed is written out to !x.axis/!y.axis
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:		may change the !x.axis/!y.axis variables
;	
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		August, 1991.
;
;-
;
;	need to reduce the tickvals array down to 30 elements
;	if y or x set then use !x/y.ticks as the limitting number
;	else use ticks
;	

limit=30
if (n_elements(ticks) gt 0) then limit = ticks+1
if (keyword_set(xaxis)) then limit=!x.ticks+1 < 30
if (keyword_set(yaxis)) then limit=!y.ticks+1 < 30

numticks = n_elements(tickvals)-2

if (numticks gt 0) then begin
	tmp = tickvals(1:numticks)
	numticks = n_elements(tmp)
	count = numticks
	while (numticks+2 gt limit) and (count gt 0) do begin
		odds = where((indgen(numticks) mod 2) eq 1,count)
		if (count gt 0) then tmp = tmp(odds)
		numticks = n_elements(tmp)
	endwhile

	tmp = [tickvals(0),tmp,tickvals(n_elements(tickvals)-1)]
endif else $
	tmp = tickvals

if (keyword_set(xaxis)) then !x.ticks=n_elements(tmp)-1
if (keyword_set(yaxis)) then !y.ticks=n_elements(tmp)-1
ticks=n_elements(tmp)-1

return,tmp
end


