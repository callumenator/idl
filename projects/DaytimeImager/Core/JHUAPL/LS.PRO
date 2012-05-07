;-------------------------------------------------------------
;+
; NAME:
;       LS
; PURPOSE:
;       Scale image between percentiles 1 and 99 (or specified percentiles).
; CATEGORY:
; CALLING SEQUENCE:
;       out = ls(in, [l, u, alo, ahi])
; INPUTS:
;       in = input image.                           in
;       l = lower percentile to ignore (def = 1).   in
;       u = upper percentile to ignore (def = 1).   in
; KEYWORD PARAMETERS:
;       Keywords:
;         SCALE_ON=arr  Array to determine on.  If not given
;           then input image in is used.
;         TOP=t  Max byte value for scaling (def=!d.n_colors-1).
;         /QUIET  Inhibit scaling message.
; OUTPUTS:
;       alo = value scaled to 0.                    out
;       ahi = value scaled to 255.                  out
;       out = scaled image.                         out
; COMMON BLOCKS:
; NOTES:
;       Notes: Uses cumulative histogram.
; MODIFICATION HISTORY:
;       R. Sterner. 7 Oct, 1987.
;       RES 5 Aug, 1988 --- added lower and upper limits.
;       R. Sterner, 1995 Dec 15 --- Added SCALE_ON keyword.
;       R. Sterner, 1998 Jan 15 --- Dropped use of !d.n_colors.
;       Johns Hopkins University Applied Physics Laboratory.
;
; Copyright (C) 1987, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	function ls, a, l, u, alo, ahi, help=hlp, top=top, $
	   scale_on=scale_on, quiet=quiet
 
	np = n_params(0)
 
	if (np lt 1) or keyword_set(hlp) then begin
	  print,' Scale image between percentiles 1 and 99 '+$
	    '(or specified percentiles).' 
	  print,' out = ls(in, [l, u, alo, ahi])' 
	  print,'   in = input image.                           in'
	  print,'   l = lower percentile to ignore (def = 1).   in' 
	  print,'   u = upper percentile to ignore (def = 1).   in'
	  print,'   alo = value scaled to 0.                    out'
	  print,'   ahi = value scaled to 255.                  out'
	  print,'   out = scaled image.                         out'
	  print,' Keywords:'
	  print,'   SCALE_ON=arr  Array to determine on.  If not given'
	  print,'     then input image in is used.'
	  print,'   TOP=t  Max byte value for scaling (def=!d.table_size-1).'
	  print,'   /QUIET  Inhibit scaling message.'
	  print,' Notes: Uses cumulative histogram.'
	  return, -1
	endif
 
	if np lt 2 then l = 1
	if np lt 3 then u = l
	if n_elements(top) eq 0 then top = topc()
 
	clo = l/100.
	chi = (100.-u)/100.
	nbins = 600.
 
	if n_elements(scale_on) eq 0 then begin	; Scale on input image.
	  amn = min(a)				; Find array extremes.
	  amx = max(a)
	  da = amx - amn			; Array range.
	  if da eq 0 then goto, constant	; Error.
	  b = (a - amn)*nbins/da		; Force into NBIN bins.
	endif else begin			; Scale on given array.
	  amn = min(scale_on)			; Find array extremes.
	  amx = max(scale_on)
	  da = amx - amn                        ; Array range.
	  if da eq 0 then goto, constant	; Error.
          b = (scale_on - amn)*nbins/da         ; Force into NBIN bins.
	endelse
	h = histogram(b)			; Histogram.
	c = cumulate(h)				; Look at cumulative histogram.
	c = c - c(0)				; Ignore 0s.
	c = float(c)/max(c)			; Normalize.
	w = where((c gt clo) and (c lt chi),count)	; Pick central window.
	if count gt 0 then begin
	  lo = min(w)				; find limits of rescaled data.
	  hi = max(w)
	endif else begin
	  lo = 0
	  hi = nbins
	  if not keyword_set(quiet) then print,$
	    ' LS Warning: could not scale array properly.'
	endelse
	alo = amn + da*lo/nbins			; Limits in original array.
	ahi = amn + da*hi/nbins
	if not keyword_set(quiet) then print,$
	  ' Scaling image from ',alo,' to ',ahi
	b = bytscl(a>alo<ahi,top=top)		; scale array.
	return, b
 
constant:
	print,' Error in ls: given array is constant, no stretch possible.'
	return, bytscl(a)
 
	end
