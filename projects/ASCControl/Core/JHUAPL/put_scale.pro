;-------------------------------------------------------------
;+
; NAME:
;       PUT_SCALE
; PURPOSE:
;       Embed in current image values needed to restore scaling.
; CATEGORY:
; CALLING SEQUENCE:
;       put_scale
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         The following are only used to add scaling to an
;         existing image not easily regenerated:
;         IX=[ix1,ix2]  Plot window x device coordinates.
;         IY=[iy1,iy2]  Plot window y device coordinates.
;         X = [x1,x2]   Plot window x data coordinates.
;         Y = [y1,y2]   Plot window y data coordinates.
;         TYPE_X=xtyp    X axis type: 0=linear, 1=log.
;         TYPE_Y=ytyp    Y axis type: 0=linear, 1=log.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: Embeds in dispayed image the following values:
;         1234567890 - Used to determine if scaling available (I10).
;         ix1, ix2 - Plot window device coordinates in X (2I6).
;         iy1, iy2 - Plot window device coordinates in Y (2I6).
;         x1, x2 - Plot window data coordinates in X (2G13.6).
;         y1, y2 - Plot window data coordinates in Y (2G13.6).
;         xtype, ytype - X and Y axis type: 0=linear, 1=log (2I2).
;         For type=1 the data range is really the log10 of
;         the actual data range for that axis.
;       
;         Use set_scale to read these values and set scaling.
;         May also read 90 bytes and convert to string:
;           print,string(tvrd(0,0,90,1))
;         Only works if image stored in non-lossy format.
; MODIFICATION HISTORY:
;       R. Sterner, 1995 Feb 28
;       R. Sterner, 1995 Feb Aug 24 --- Added keywords.
;
; Copyright (C) 1995, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
 
	pro put_scale, help=hlp, ix=ix0, iy=iy0, x=x0, y=y0, $
	  type_x=xtyp0, type_y=ytyp0
 
	if keyword_set(hlp) then begin
	  print,' Embed in current image values needed to restore scaling.'
	  print,' put_scale'
	  print,'   No arguments.'
	  print,' Keywords:'
	  print,'   The following are only used to add scaling to an'
	  print,'   existing image not easily regenerated:'
	  print,'   IX=[ix1,ix2]  Plot window x device coordinates.'
	  print,'   IY=[iy1,iy2]  Plot window y device coordinates.'
	  print,'   X = [x1,x2]   Plot window x data coordinates.'
	  print,'   Y = [y1,y2]   Plot window y data coordinates.'
	  print,'   TYPE_X=xtyp    X axis type: 0=linear, 1=log.'
	  print,'   TYPE_Y=ytyp    Y axis type: 0=linear, 1=log.'
	  print,' Notes: Embeds in dispayed image the following values:'
	  print,'   1234567890 - Used to determine if scaling available (I10).'
	  print,'   ix1, ix2 - Plot window device coordinates in X (2I6).'
	  print,'   iy1, iy2 - Plot window device coordinates in Y (2I6).'
	  print,'   x1, x2 - Plot window data coordinates in X (2G13.6).'
	  print,'   y1, y2 - Plot window data coordinates in Y (2G13.6).'
	  print,'   xtype, ytype - X and Y axis type: 0=linear, 1=log (2I2).'
	  print,'   For type=1 the data range is really the log10 of'
	  print,'   the actual data range for that axis.'
	  print,' '
	  print,'   Use set_scale to read these values and set scaling.'
	  print,'   May also read 90 bytes and convert to string:'
	  print,'     print,string(tvrd(0,0,90,1))'
	  print,'   Only works if image stored in non-lossy format.'
	  return
	endif
 
	;----  Set up needed values  ----------
	m = 1234567890
	ix = round(!x.window*!d.x_size)
	iy = round(!y.window*!d.y_size)
	x = !x.crange
	y = !y.crange
	xtyp = !x.type
	ytyp = !y.type
 
	;----  Deal with keyword overrides  ------------
	if n_elements(ix0) ne 0 then ix=ix0
	if n_elements(iy0) ne 0 then iy=iy0
	if n_elements(x0) ne 0 then x=x0
	if n_elements(y0) ne 0 then y=y0
	if n_elements(xtyp0) ne 0 then xtyp=xtyp0
	if n_elements(ytyp0) ne 0 then ytyp=ytyp0
 
	;-----  Place all values in a string  ----------
	s = string(m, ix, iy, x, y, xtyp, ytyp, $
          form='(I10,4I6,4G13.6,2I2)')
 
	;------  Convert to bytes and write to image  --------
	tv,byte(s),0,0
 
	return
	end
