;-------------------------------------------------------------
;+
; NAME:
;       SCREENTIFF
; PURPOSE:
;       Display a tiff image in a screen window.
; CATEGORY:
; CALLING SEQUENCE:
;       screentiff, [file]
; INPUTS:
;       file = name of TIFF file.   in
; KEYWORD PARAMETERS:
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: Prompts for file if called with no args.
; MODIFICATION HISTORY:
;       R. Sterner, 1997 Feb 4
;
; Copyright (C) 1997, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	pro screentiff, file, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Display a tiff image in a screen window.'
	  print,' screentiff, [file]'
	  print,'   file = name of TIFF file.   in'
	  print,' Notes: Prompts for file if called with no args.'
	  return
	endif
 
	if n_elements(file) eq 0 then begin
	  print,' '
	  print,' Display a TIFF image in a screen window.'
	  file = ''
	  read,' Enter name of TIFF file: ',file
	  if file eq '' then return
	endif
 
	;---------  Handle file name  -------------
	filebreak,file,dir=dir,name=name,ext=ext
	if ext eq '' then begin
	  print,' Adding .tif as the file extension.'
	  ext = 'tif'
	endif
	if ext ne 'tif' then begin
	  print,' Warning: non-standard extension: '+ext
	  print,' Standard extension is tif.'
	endif
	name = name + '.' + ext
	fname = filename(dir,name,/nosym)
 
	;--------  Read TIFF file  -------------
	print,' Reading '+fname
	order = 0
	r=bindgen(256) & g=r & b=r
	img = tiff_read(fname,r,g,b,order=order)
	if order eq 1 then img = reverse(img,2)
 
	;---------  Display  --------------------
	sz=size(img) & nx=sz(1) & ny=sz(2)
	tt = fname+'  ('+strtrim(nx,2)+','+strtrim(ny,2)+')'
	if (nx gt 1200) or (ny gt 900) then begin
	  swindow,xs=nx,ys=ny,x_scr=nx<1200,y_scr=ny<900,titl=tt
	endif else begin
	  window,xs=nx,ys=ny,titl=tt
	endelse
	tv, img
	tvlct,r,g,b
 
	return
 
	end
