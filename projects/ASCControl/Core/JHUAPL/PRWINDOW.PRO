;-------------------------------------------------------------
;+
; NAME:
;       PRWINDOW
; PURPOSE:
;       Print current window or gif image on color printer.
; CATEGORY:
; CALLING SEQUENCE:
;       prwindow, pnum
; INPUTS:
;       pnum = optional PS printer numer or tag.   in
;         This may be determined from psinit,/list.
; KEYWORD PARAMETERS:
;       Keywords:
;         FACTOR=fct  Image size factor (default=1.0).
;         GIF=gif  Print the specified gif image instead of the
;           screen window.
;         COMMENT=txt  Optional comment text (printed as small
;           text on side of printout).
;         /TWO  Split image into two printout sheets.
;         /FOUR  Split image into four printout sheets.
; OUTPUTS:
; COMMON BLOCKS:
; NOTES:
;       Notes: the currect window is captured and printed to
;         the specifed or default PS printer.
; MODIFICATION HISTORY:
;       R. Sterner, 1995 May 4
;       R. Sterner, 1995 Aug 7 --- Added gif image support.
;       R. Sterner, 1995 Aug 29 --- Added comment.
;       R. Sterner, 1997 Jun 30 --- Added FACTOR=fct.
;
; Copyright (C) 1995, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
;===============================================================
;	prwindow2 = process a single given image
;	R. Sterner, 1995 Dec 22
;===============================================================
 
	pro prwindow2, pnum, a, r, g, b, comment=cmt, factor=fct
 
	;------  Find image dimensions  -----------
	sz = size(a)
	nx = sz(1)
	ny = sz(2)
 
	;------  Initialize printer and orientation  -----------
	if nx gt ny then begin
	  psinit, pnum, /land, /auto, cflag=flag, comment=cmt
	endif else begin
	  psinit, pnum, /full, /auto, cflag=flag, comment=cmt
	endelse
 
	;---------  Deal with B&W printer  ----------------------
	if flag eq 0 then begin
	  print,' Converting image to Black and White . . .'
	  lum = ROUND(.3 * r + .59 * g + .11 * b) < 255	  ; Image brightness.
	  a = lum(a)					  ; To B&W.
	endif
 
	;---------  Load color table and image  -----------------
	print,' Sending image to printer . . .'
	tvlct,r,g,b
	psimg, a, factor=fct
 
	;---------  Terminate printer  ------------
	psterm
 
	return
	end
 
 
;===============================================================
;	prwindow.pro = Print current window.
;       R. Sterner, 1995 May 4
;===============================================================
 
	pro prwindow, pnum, gif=gif, comment=cmt, $
	  two=two, four=four, factor=fct, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Print current window or gif image on color printer.'
	  print,' prwindow, pnum'
	  print,'   pnum = optional PS printer numer or tag.   in'
	  print,'     This may be determined from psinit,/list.'
	  print,' Keywords:'
	  print,'   FACTOR=fct  Image size factor (default=1.0).'
	  print,'   GIF=gif  Print the specified gif image instead of the'
	  print,'     screen window.'
	  print,'   COMMENT=txt  Optional comment text (printed as small'
	  print,'     text on side of printout).'
	  print,'   /TWO  Split image into two printout sheets.'
	  print,'   /FOUR  Split image into four printout sheets.'
	  print,' Notes: the currect window is captured and printed to'
	  print,'   the specifed or default PS printer.'
	  return
	endif
 
	if n_elements(fct) eq 0 then fct=1.0
 
	if n_elements(gif) eq 0 then begin
	  win = !d.window
	  if win lt 0 then begin
	    print,' Error in prwindow: no active graphics window to print.'
	    return
	  endif
	endif
 
	if n_elements(pnum) eq 0 then pnum = 'color'
 
	if n_elements(cmt) eq 0 then cmt = ''
 
	;------  Get image and color table  -----------
	if n_elements(gif) eq 0 then begin
	  print,' Reading image from window '+strtrim(win,2)+' . . .'
	  a = tvrd()
	  tvlct,r,g,b,/get
	endif else begin
	  print,' Reading image from gif file '+gif+' . . .'
	  read_gif, gif, a, r, g, b
	endelse
 
	pages = 1
	if keyword_set(two) then pages=2
	if keyword_set(four) then pages=4
 
	case pages of
1:	prwindow2,pnum,a,r,g,b,comment=cmt,fact=fct	; 1 Page.
2:	begin						; 2 Pages.
	  sz=size(a) & nx=sz(1) & ix=nx/2 & ny=sz(2) & iy=ny/2
	  if nx gt ny then begin			; Split horizontaly
	    prwindow2,pnum,a(0:ix-1,*),r,g,b,comment=cmt,fact=fct
	    prwindow2,pnum,a(ix:*,  *),r,g,b,comment=cmt,fact=fct
	  endif else begin				; Split verticaly
	    prwindow2, pnum, a(*,0:iy-1), r, g, b, comment=cmt
	    prwindow2, pnum, a(*,  iy:*), r, g, b, comment=cmt
	  endelse
	end
4:	begin						; 4 Pages.
	  sz=size(a) & nx=sz(1) & ix=nx/2 & ny=sz(2) & iy=ny/2
	  prwindow2,pnum,a(0:ix-1,0:iy-1),r,g,b,comment=cmt,fact=fct
	  prwindow2,pnum,a(ix:*,  0:iy-1),r,g,b,comment=cmt,fact=fct
	  prwindow2,pnum,a(0:ix-1,  iy:*),r,g,b,comment=cmt,fact=fct
	  prwindow2,pnum,a(ix:*,    iy:*),r,g,b,comment=cmt,fact=fct
	end
	endcase
 
	return
	end
