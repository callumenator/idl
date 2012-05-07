;-------------------------------------------------------------
;+
; NAME:
;       SUN_COLORS
; PURPOSE:
;       Load sun color table
; CATEGORY:
; CALLING SEQUENCE:
;       sun_colors
; INPUTS:
; KEYWORD PARAMETERS:
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: loads color table from sun_colors_xdr.res
;         in routine source directory.
;         Colors above index 180 are untouched.
; MODIFICATION HISTORY:
;       R. Sterner, 1996 Sep 17
;       R. Sterner, 1997 Dec 30 --- converted color table to a text file.
;       R. Sterner, 1998 Jan 15 --- Dropped use of !d.n_colors.
;
; Copyright (C) 1996, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro sun_colors, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Load sun color table'
	  print,' sun_colors'
	  print,'   No args.'
	  print,' Notes: loads color table from sun_colors_xdr.res'
	  print,'   in routine source directory.'
	  print,'   Colors above index 180 are untouched.'
	  return	
	endif
 
	whoami, dir
	f = filename(dir,'sun_colors.txt',/nosym)
	openr,lun,f,/get_lun
	a = bytarr(3,181)
	readf,lun,a
	free_lun,lun
	tvlct,a(0,*),a(1,*),a(2,*)
	tvlct,0,0,0,topc()		; Make last color black.
 
	return
	end
