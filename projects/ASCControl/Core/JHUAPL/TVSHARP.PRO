;-------------------------------------------------------------
;+
; NAME:
;       TVSHARP
; PURPOSE:
;       Redisplay a sharpened version of the current screen image.
; CATEGORY:
; CALLING SEQUENCE:
;       tvsharp
; INPUTS:
; KEYWORD PARAMETERS:
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: BW images only.
; MODIFICATION HISTORY:
;       R. Sterner, 1997 Feb 17
;
; Copyright (C) 1997, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro tvsharp, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Redisplay a sharpened version of the current screen image.'
	  print,' tvsharp'
	  print,'   No args.'
	  print,' Notes: BW images only.'
	  return
	endif
 
	tvlct,r,g,b,/get
	color_convert,r,g,b,h,s,v,/rgb_hsv
	if max(s) gt 0 then begin
	  print,' Only works for BW images.'
	  return
	endif
 
	a = float(tvrd())
	s = a-.75*smooth(a,3)
	s = s*sdev(a)/sdev(s)
	s = s+mean(a)-mean(s)
	tv,byte(s>0<255)
 
	return
	end
