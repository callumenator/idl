;----------------------------------------------------------------------------
FUNCTION Th_nearest, limit, value
;+
; NAME:
;	TH_NEAREST
;
; PURPOSE:
;	This function will find the nearest multiple or fraction of VALUE
;	that is just under or just over LIMIT.
;	Particularly useful for REBINning.
;
; CATEGORY:
;	utilities
;
; CALLING SEQUENCE:
;	newvalue = TH_NEAREST(limit,value)
;
; INPUTS:
;	LIMIT = the value that we want the result to be near
;	VALUE = the value we want to find the multiple or fraction of
;
; OUTPUTS:
;	NEWVALUE = the nearest multiple or fraction of VALUE to LIMIT
;
;   OPTIONAL PARAMETERS:
;	none
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;       23-May-1994 T Harris, IE Group, HFRD, DSTO. 
;		renamed from NEAREST to TH_NEAREST
;
;-

  intvalue = fix(value)
  nearest_value = intvalue
  i = 1

  IF (intvalue GT limit) THEN BEGIN
    WHILE ((nearest_value GT limit) AND (intvalue/i GT 0) AND $
           (float(intvalue/i) EQ float(intvalue)/i) ) DO BEGIN
      nearest_value = intvalue/i
      i = i+1
    ENDWHILE
  ENDIF ELSE BEGIN
    WHILE (nearest_value LT limit) DO BEGIN
      nearest_value = i*intvalue
      i = i+1
    ENDWHILE
  ENDELSE

  RETURN, nearest_value
END





