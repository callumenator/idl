;-------------------------------------------------------------
;+
; NAME:
;       TXTGETKEY
; PURPOSE:
;       Get a keyword value from a string array.
; CATEGORY:
; CALLING SEQUENCE:
;       val = txtgetkey(key)
; INPUTS:
;       key = keyword to find. Case ignored.    in
; KEYWORD PARAMETERS:
;       Keywords:
;         INIT=txtarr  string array to search.  Must be given as an
;           initialization array before asking for values. If txtarr
;           stays the same it need be given only on first call.
;         DELIMITER=del  Set keyword/value delimiter (def is =).
;         /LIST lists keywords and values.
;         /START  start search at beginning of array, else
;           continue from last position (can pick up multiple
;           copies of a keyword by not using /START).
;         INDEX=indx  Index where key was found.
; OUTPUTS:
;       val = returned value of keyword.        out
;         Null string if key not found.
; COMMON BLOCKS:
;       txtgetkey_com
; NOTES:
;       Notes: File must contain keywords and values separated by an
;         equal sign (=) or DELIM.  When a matching keyword is found
;         everything following the equal is returned as a text
;         string.  Spaces are optional.  Some examples:
;           title = This is a test.
;           n=128
;           xrange = 10, 20
;         Example call: v = txtgetkey(init=txt, key).
; MODIFICATION HISTORY:
;       R. Sterner, 17 Mar, 1993
;       R. Sterner, 25 Oct, 1993 --- Added DELIMITER keyword.
;       R. Sterner, 1994 May 6 --- Added /START and fixed minor bugs.
;       R. Sterner, 1995 Jun 26 --- Added INDEX keyword.
;
; Copyright (C) 1993, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	function txtgetkey, key, initialize=init, list=list, $
	  delimiter=del, start=start, index=indx, help=hlp
 
	common txtgetkey_com, keywds, val, last, curr
 
	if keyword_set(hlp) or $
	  ((n_params(0) eq 0) and $
	   (n_elements(init) eq 0) and $
	   (n_elements(list) eq 0)) then begin
	  print,' Get a keyword value from a string array.'
	  print,' val = txtgetkey(key)'
 	  print,'   key = keyword to find. Case ignored.    in'
 	  print,'   val = returned value of keyword.        out'
	  print,'     Null string if key not found.'
	  print,' Keywords:'
 	  print,'   INIT=txtarr  string array to search.  Must be given as an'
	  print,'     initialization array before asking for values. If txtarr'
	  print,'     stays the same it need be given only on first call.'
	  print,'   DELIMITER=del  Set keyword/value delimiter (def is =).'
	  print,'   /LIST lists keywords and values.'
	  print,'   /START  start search at beginning of array, else'
	  print,'     continue from last position (can pick up multiple'
	  print,'     copies of a keyword by not using /START).'
	  print,'   INDEX=indx  Index where key was found.'
	  print,' Notes: File must contain keywords and values separated by an'
	  print,'   equal sign (=) or DELIM.  When a matching keyword is found'
	  print,'   everything following the equal is returned as a text'
	  print,'   string.  Spaces are optional.  Some examples:'
	  print,'     title = This is a test.'
	  print,'     n=128'
	  print,'     xrange = 10, 20
	  print,'   Example call: v = txtgetkey(init=txt, key).'
	  return,''
	endif
 
	if n_elements(del) eq 0 then del = '='
 
	;-------  Initialize  ------------
	if n_elements(init) ne 0 then begin
	  w = where(strcompress(init,/rem) ne '', cnt)	
	  if cnt gt 0 then txt = init(w)
	  w = where(strmid(txt,0,1) ne '*', cnt)
 	  if cnt gt 0 then txt = txt(w)
	  keywds = txt
	  val = txt
	  last = n_elements(txt)-1
	  for i=0, last do begin
	    keywds(i) = strupcase(getwrd(txt(i),delim=del)) 
	    val(i) = getwrd(txt(i),1,99,delim=del)
	  endfor
	  curr = 0	; Search start.
	endif
 
	;----------  List keyword/value pairs  ----------
	if keyword_set(list) then begin
	  if n_elements(keywds) eq 0 then begin
            print,' Error in txtgetkey: must initialize first.'
            return,''
          endif
	  for i = 0, n_elements(keywds)-1 do begin
	    out = strtrim(i)+' --- '+keywds(i)+' = '+val(i)
	    if strlen(out) ge 79 then out = strmid(out,0,75)+'...'
	    print,out
	  endfor
	endif
 
	if n_params(0) eq 0 then return, ''
 
	;---------  Search  ---------
	if n_elements(keywds) eq 0 then begin
	  print,' Error in txtgetkey: must initialize first.'
	  return,''
	endif
 
	if keyword_set(start) then curr = 0
	if curr gt last then begin
	  curr = 0
	  indx = -1		; Not found.
	  return, ''
	endif
	w = where(strupcase(key) eq keywds, cnt)
	if cnt eq 0 then begin
	  curr = 0		; Reset search to array start.
	  indx = -1		; Not found.
	  return, ''
	endif
	w2 = where(w ge curr,cnt)
	if cnt eq 0 then begin
	  curr = 0		; Reset search to array start.
	  indx = -1		; Not found.
	  return, ''
	endif
	ww = w(w2)
	curr = ww(0)
	out = val(curr)
	indx = curr		; Index found.
	curr = curr + 1
 
	return, out
 
	end
