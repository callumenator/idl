;-------------------------------------------------------------
;+
; NAME:
;       TARCLR
; PURPOSE:
;       Find closest match to given target color in current color table.
; CATEGORY:
; CALLING SEQUENCE:
;       in = tarclr(tclr)
; INPUTS:
;       tclr = target color.  Flexible format see notes.    in
; KEYWORD PARAMETERS:
;       Keywords:
;         SET=i  If given set color index i to specified color.
;           Ignored if in high color mode (> 256).
; OUTPUTS:
;       in = index in current color table of closest match. out
; COMMON BLOCKS:
; NOTES:
;       Notes: input target color may be given in one of many ways.
;       It may be given in a single argument or in 3 arguments.  The
;       required order in either case is Red, Green, and Blue and
;       the target values of each are assumed to be in the range
;       0-255.  Some example single arg entries:
;       '100 120 255', '80,20,0', ['200','200','0'], [0,50,100]'
;       The 3 values may also be given in 3 args.
;       A special case single arg entry may be in hex such as:
;       '#ffaa77' to match WWW format.'
;       If using high color (more than 8 bits) then the actual
;       color values is returned for use with the COLOR keyword.
; MODIFICATION HISTORY:
;       R. Sterner, 1996 Oct 30
;       R. Sterner, 1997 Dec  3 --- Upgraded for high color use.
;
; Copyright (C) 1996, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	function tarclr, a1, a2, a3, set=set, help=hlp
 
	if keyword_set(hlp) then begin
	  print,' Find closest match to given target color in current color table.'
	  print,' in = tarclr(tclr)'
	  print,'   tclr = target color.  Flexible format see notes.    in'
	  print,'   in = index in current color table of closest match. out'
	  print,' Keywords:'
	  print,'   SET=i  If given set color index i to specified color.'
	  print,'     Ignored if in high color mode (> 256).'
	  print,' Notes: input target color may be given in one of many ways.'
	  print,' It may be given in a single argument or in 3 arguments.  The'
	  print,' required order in either case is Red, Green, and Blue and'
	  print,' the target values of each are assumed to be in the range'
	  print,' 0-255.  Some example single arg entries:'
	  print," '100 120 255', '80,20,0', ['200','200','0'], [0,50,100]'
	  print,' The 3 values may also be given in 3 args.'
	  print,' A special case single arg entry may be in hex such as:'
	  print," '#ffaa77' to match WWW format.'
	  print,' If using high color (more than 8 bits) then the actual'
	  print,' color values is returned for use with the COLOR keyword.'
	  return,''
	endif
 
	if n_elements(a1) eq 0 then a1=[255,255,255]	  ; Def=white.
	if n_params(0) eq 3 then a=[a1,a2,a3] else a=a1	  ; 1 or 3 args.
 
	if strmid(a(0),0,1) eq '#' then begin		  ; WWW format.
	  a=strmid(a,1,2)+' '+strmid(a,3,2)+' '+strmid(a,5,2)
	  wordarray,a,t
	  a = basecon(t,from=16)
	endif
 
        ;-------  Make sure target color is defined and in correct format  ----
        wordarray,string(a),tclr & tclr=tclr+0
 
	;-------  Deal with high color  -----------------
	if !d.n_colors gt 256 then begin
	  clr = tclr(0) + 256L*(tclr(1) + 256L*tclr(2))
	  return, clr
	endif
 
	;-------  Set color if index given  -------------
	if n_elements(set) ne 0 then begin
	  tvlct,tclr(0),tclr(1),tclr(2), set
	endif
 
        ;-------  Find image color closest to given target color  --------
	tvlct,r,g,b,/get
        d = float(r-tclr(0))^2+float(g-tclr(1))^2+float(b-tclr(2))^2
	dmin =  min(d)
        clr = (where(d eq dmin))(0)
 
	return,clr
 
	end
