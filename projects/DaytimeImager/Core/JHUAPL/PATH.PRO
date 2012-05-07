;-------------------------------------------------------------
;+
; NAME:
;       PATH
; PURPOSE:
;       Examine and modify the IDL path.
; CATEGORY:
; CALLING SEQUENCE:
;       path, new
; INPUTS:
;       new = new path name to add to existing path.     in
; KEYWORD PARAMETERS:
;       Keywords:
;         /LAST forces new path to be added to end of existing
;            path instead of front which is default.
;         /LIST displays a numbered list of all the paths.
;         /RESET restores initial path (found on first call).
;         FRONT=n move the n'th directory to the front.
; OUTPUTS:
; COMMON BLOCKS:
;       path_com
; NOTES:
;       Notes: can use paths like ../xxx or [-.xxx] as a shortcut.
;         Useful to turn on & off libraries of IDL routines.
; MODIFICATION HISTORY:
;       R. Sterner, 20 Sep, 1989
;       R. Sterner, 24 Sep, 1991 --- Added DOS.
;       R. Sterner, 24 Jan, 1994 --- Added MACOS.
;
; Copyright (C) 1989, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	pro path, in, help=hlp, last=aftr, reset=rst, list=lst, front=front
 
	common path_com, firstpath
 
	if keyword_set(hlp) then begin
	  print,' Examine and modify the IDL path.'
	  print,' path, new'
	  print,'   new = new path name to add to existing path.     in'
	  print,' Keywords:'
	  print,'   /LAST forces new path to be added to end of existing'
	  print,'      path instead of front which is default.'
	  print,'   /LIST displays a numbered list of all the paths.'
	  print,'   /RESET restores initial path (found on first call).'
	  print,"   FRONT=n move the n'th directory to the front."
	  print,' Notes: can use paths like ../xxx or [-.xxx] as a shortcut.'
	  print,'   Useful to turn on & off libraries of IDL routines.'
	  return
	endif
 
	if n_elements(firstpath) eq 0 then firstpath = !path
 
	os = strupcase(!version.os)
	case os of
'VMS':    delim = ','
'DOS':    delim = ';'
'MACOS':  delim = ','
else:	  delim = ':'
	endcase
 
	if n_params(0) gt 0 then begin
	  if keyword_set(aftr) then begin
	    !path = !path + delim + in	
	  endif else begin
	    !path = in + delim + !path
	  endelse
	endif
 
	if keyword_set(rst) then begin
	  !path = firstpath
	endif
 
	if keyword_set(lst) then begin
	  for i = 0, nwrds(!path,delim=delim)-1 do begin
	    print,i+1,'  ',getwrd(!path,i,delim=delim)
	  endfor
	endif
 
	if n_elements(front) ne 0 then begin
	  n = front - 1
          txt = repchr(!path,delim)	; Get current path.
	  nw = nwrds(txt)		; # directories.
	  new = strarr(nw)		; New directory list.
	  for i = 0, nw-1 do new(i) = getwrd(txt,i)
	  new = [new(n), new(where(indgen(nw) ne n))]
	  txt = new(0)
	  for i = 1, nw-1 do txt = txt + delim + new(i)
	  !path = txt
	endif
 
	return
	end
