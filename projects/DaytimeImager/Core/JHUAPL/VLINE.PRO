;-------------------------------------------------------------
;+
; NAME:
;       VLINE
; PURPOSE:
;       Plot a vertical line after erasing last plotted line.
; CATEGORY:
; CALLING SEQUENCE:
;       vline, [x]
; INPUTS:
;       x = x coordinate of new line.   in
;         If x not given last line is erased.
; KEYWORD PARAMETERS:
;       Keywords:
;         /DEVICE means use device coordinates (default).
;         /DATA means use data coordinates.
;         /NORM means use normalized coordinates.
;         /NOERASE means don't try to erase last line.
;         /ERASE means just erase last line without plotting another.
;         RANGE=[ymin, ymax] min and max y coordinates of line.
;         NUMBER=n line number (0 to 9, def=0).
;         COLOR=c set plot color.
;         LINESTYLE=s set line style.
; OUTPUTS:
; COMMON BLOCKS:
;       vline_com
;       vline_com
; NOTES:
; MODIFICATION HISTORY:
;       R. sterner, 5 June, 1992
;       R. Sterner, 1998 Jan 15 --- Dropped use of !d.n_colors.
;
; Copyright (C) 1992, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	pro vline, x, range=range, noerase=noerase, erase=erase, $
	  device=device, data=data, norm=norm, number=num, $
	  color=color, linestyle=linestyle, help=hlp
 
	common vline_com, sx, sy, xlst, clst
 
	if keyword_set(hlp) then begin
	  print,' Plot a vertical line after erasing last plotted line.'
	  print,' vline, [x]'
	  print,'   x = x coordinate of new line.   in'
	  print,'     If x not given last line is erased.'
	  print,' Keywords:'
	  print,'   /DEVICE means use device coordinates (default).'
	  print,'   /DATA means use data coordinates.'
	  print,'   /NORM means use normalized coordinates.'
	  print,"   /NOERASE means don't try to erase last line."
	  print,'   /ERASE means just erase last line without plotting another.'
	  print,'   RANGE=[ymin, ymax] min and max y coordinates of line.'
	  print,'   NUMBER=n line number (0 to 9, def=0).'
	  print,'   COLOR=c set plot color.'
	  print,'   LINESTYLE=s set line style.'
	  return
	endif
 
	;------  Define plot values  ------
	if n_elements(color) eq 0 then color = !p.color
	if n_elements(linestyle) eq 0 then linestyle = 0
	if n_elements(num) eq 0 then num = 0
	
 
	;------  Determine coordinate system  -----
	if n_elements(device) eq 0 then device = 0	; Define flags.
	if n_elements(data)   eq 0 then data   = 0
	if n_elements(norm)   eq 0 then norm   = 0
	if device+data+norm eq 0 then device = 1	; Default to device.
 
	;-----  Init common  -----
	if n_elements(sx) eq 0 then begin
	  sx = !d.x_size	; Screen size in X.
	  sy = !d.y_size	; Screen size in Y.
	  xlst = intarr(10)-1	; X of last line plotted.
	  clst = intarr(10,sy)	; Column under last line plotted.
	endif
 
	;------  Just erase last line  ------
	if n_elements(x) eq 0 then erase = 1	; If no x given erase last line.
	if keyword_set(erase) then begin
	  tv, clst(num,*), xlst(num), 0
	  return
	endif
 
	;-----  Set Y range -------
	if device eq 1 then begin
	  range0 = [0,sy-1]
	endif
	if data eq 1 then begin
	  range0 = !y.crange
	endif
	if norm eq 1 then begin
	  range0 = [0.,1.]
	endif
	if n_elements(range) eq 0 then range = range0
 
	;-----  Convert X and range to device -------
	if device eq 1 then begin
	  xc = x
	  y1 = range(0)
	  y2 = range(1)
	endif
	if data eq 1 then begin
	  range0 = !y.crange
	  t = convert_coord([x,x],range, /data, /to_device)
	  xc = t(0,0)
	  y1 = t(1,0)
	  y2 = t(1,1)
	endif
	if norm eq 1 then begin
	  range0 = [0.,1.]
	  t = convert_coord([x,x],range, /norm, /to_device)
	  xc = t(0,0)
	  y1 = t(1,0)
	  y2 = t(1,1)
	endif
	xc = fix(xc+.5)
	y1 = fix(y1+.5)
	y2 = fix(y2+.5)
 
	;-----  Erase last line  ------
	if not keyword_set(noerase) then begin
	  xl = xlst(num)
	  if (xl ge 0) and (xl lt sx) then tv, clst(num,*), xl, 0
	endif
	xlst(num) = xc
 
	;-----  Read new line  --------
	if (xc ge 0) and (xc lt sx) then begin
	  t = tvrd(xc,0,1,sy)
	  clst(num,0) = t
	endif
 
	;-----  Plot new line  ----------
	plots, /device, color=color, $
	  linestyle=linestyle, [xc,xc], [y1,y2]
 
	return
	end
