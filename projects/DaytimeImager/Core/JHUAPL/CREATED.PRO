;-------------------------------------------------------------
;+
; NAME:
;       CREATED
; PURPOSE:
;       Return file creation host, user, and time stamp or tag.
; CATEGORY:
; CALLING SEQUENCE:
;       txt = created()
; INPUTS:
; KEYWORD PARAMETERS:
; OUTPUTS:
;       txt = returned text.        out
;       Ex: Created on tesla by Sterner on Tue Jul  1 14:22:15 1997
; COMMON BLOCKS:
; NOTES:
; MODIFICATION HISTORY:
;       R. Sterner, 1997 Jul 1
;
; Copyright (C) 1997, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function created, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Return file creation host, user, and time stamp or tag.'
	  print,' txt = created()'
	  print,'   txt = returned text.        out'
	  print,'   Ex: Created on tesla by Sterner on Tue Jul  1 14:22:15 1997'
	  return,''
	endif
 
	host = getenv('HOST')
	user = upcase1(getenv('USER'))
	time = systime()
 
	txt = ' Created on '+host+' by '+user+' on '+time
 
	return, txt
	end
