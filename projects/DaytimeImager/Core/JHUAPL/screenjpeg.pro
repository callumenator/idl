;-------------------------------------------------------------
;+
; NAME:
;       SCREENJPEG
; PURPOSE:
;       Display a jpeg image in a screen window.
; CATEGORY:
; CALLING SEQUENCE:
;       screenjpeg, [file]
; INPUTS:
;       file = name of JPEG file.   in
; KEYWORD PARAMETERS:
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: Prompts for file if called with no args.
; MODIFICATION HISTORY:
;       R. Sterner, 1996 Jan 17
;
; Copyright (C) 1996, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro screenjpeg, file, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Display a jpeg image in a screen window.'
	  print,' screenjpeg, [file]'
	  print,'   file = name of JPEG file.   in'
	  print,' Notes: Prompts for file if called with no args.'
	  return
	endif
 
	if n_elements(file) eq 0 then begin
	  print,' '
	  print,' Display a jpeg image in a screen window.'
	  file = ''
	  read,' Enter name of JPEG file: ',file
	  if file eq '' then return
	endif
 
	;---------  Handle file name  -------------
	filebreak,file,dir=dir,name=name,ext=ext
	if ext eq '' then begin
	  print,' Adding .jpg as the file extension.'
	  ext = 'jpg'
	endif
	if ext ne 'jpg' then begin
	  print,' Warning: non-standard extension: '+jpg
	  print,' Standard extension is jpg.'
	endif
	name = name + '.' + ext
	fname = filename(dir,name,/nosym)
 
	;--------  Read JPEG file  -------------
	print,' Reading '+fname
	read_jpeg,fname,img,rgb,/dither,/two_pass,colors=256
 
	;---------  Display  --------------------
	sz=size(img) & nx=sz(1) & ny=sz(2)
	tt = fname+'  ('+strtrim(nx,2)+','+strtrim(ny,2)+')'
	if (nx gt 1200) or (ny gt 900) then begin
	  swindow,xs=nx,ys=ny,x_scr=nx<1200,y_scr=ny<900,titl=tt
	endif else begin
	  window,xs=nx,ys=ny,titl=tt
	endelse
	tv, img
	tvlct,rgb
 
	return
 
	end
