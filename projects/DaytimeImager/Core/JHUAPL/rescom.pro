;-------------------------------------------------------------
;+
; NAME:
;       RESCOM
; PURPOSE:
;       Display values from the results common and also file header.
; CATEGORY:
; CALLING SEQUENCE:
;       rescom
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         FILE=f    RES file to examine (def=one currently open).
;         /NOHEADER skips display of file's header.
;         /NOSTATUS skips display of status (read/write/lun/pointer).
;         TAG=tag   Display only given tag (def=all).
; OUTPUTS:
; COMMON BLOCKS:
;       results_common
; NOTES:
;       Notes: one of the results file utilities.
;         See also resopen, resput, resget, resclose.
; MODIFICATION HISTORY:
;       R. Sterner, 18 Jun, 1991
;       R. Sterner, 1994 Mar 29 --- added /NOSTATUS, TAG, and FILE keywords.
;       R. Sterner, 2000 Apr 11 --- Handled endian problem.
;       R. Sterner, 2000 Aug 14 --- Ignored r_swap if undefined.
;
; Copyright (C) 1991, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	pro rescom, noheader=noheader, nostatus=nostatus, help=hlp, $
	  tag=tag, file=file
 
        common results_common, r_file, r_lun, r_open, r_hdr, r_swap
        ;----------------------------------------------------
        ;       r_file = Name of results file.
        ;       r_lun  = Unit number of results file.
        ;       r_open = File open flag. 0: not open.
        ;                                1: open for read.
        ;                                2: open for write.
        ;       r_hdr  = String array containing file header.
	;       r_swap = Swap endian if set.
        ;----------------------------------------------------
 
	if keyword_set(hlp) then begin
	  print,' Display values from the results common and also file header.'
	  print,' rescom'
	  print,'   No arguments.'
	  print,' Keywords:'
	  print,'   FILE=f    RES file to examine (def=one currently open).'
	  print,"   /NOHEADER skips display of file's header."
	  print,"   /NOSTATUS skips display of status (read/write/lun/pointer)."
	  print,'   TAG=tag   Display only given tag (def=all).'
	  print,' Notes: one of the results file utilities.'
	  print,'   See also resopen, resput, resget, resclose.'
	  return
	endif
 
	if n_elements(r_open) eq 0 then r_open = 0
 
        ;-------  Set up for screen display  --------
	;#####  Should use openw, ..., /MORE but there seems to
	;#####  be a bug in the old PC version.  Check new version.
        lun = -1
        maxline = 15
        lcount = 1
        txt = ''
	tagflag = 0
	if n_elements(tag) ne 0 then begin
	  tagflag = 1
	  tlen = strlen(tag)
	  utag = strupcase(tag)
	endif
 
	;-------  If given a file open it.  ---------
	if n_elements(file) ne 0 then resopen,file
 
	;-------  File open?  ----------
	if r_open eq 0 then begin
	  print,' No results file is open.'
	  goto, done
	endif
 
	;-------  List status variables  -------
	if not keyword_set(nostatus) then begin
	  printf,lun,' '
	  if r_open eq 1 then begin
	    printf,lun,' Results file '+r_file+' is open for read.'
	  endif
	  if r_open eq 2 then begin
	    printf,lun,' Results file '+r_file+' is open for write.'
	  endif
	  printf, lun, ' File unit number = ',strtrim(r_lun, 2)
	  fs = fstat(r_lun)
	  printf, lun, ' Current file pointer = ',strtrim(fs.cur_ptr, 2)
	  if n_elements(r_swap) ne 0 then begin
	    if r_swap eq 1 then txt=' Will swap endian' else $
	      txt=' Will not swap endian'
	    txt = txt + ' ('+endian(/text)+')'
	    printf,lun,txt
	  endif
	  printf,lun,' '
          read, ' <Press RETURN to continue>', txt
	  if strupcase(txt) eq 'Q' then return
	endif
 
	if keyword_set(noheader) then return
 
        ;--------  Display header  ----------
        printf, lun, ' Results header for file '+r_file+':'
        for i=0, n_elements(r_hdr)-1 do begin
	  if strtrim(r_hdr(i),2) ne '' then begin
	    if tagflag eq 0 then begin
              printf,lun,strtrim(i)+' '+strtrim(r_hdr(i))
              lcount = lcount + 1
	    endif else begin
	      if strupcase(strmid(r_hdr(i),0,tlen)) eq utag then begin
	        printf,lun,strtrim(i)+' '+strtrim(r_hdr(i))
	        lcount = lcount + 1
	      endif
	    endelse
            if (lcount mod maxline) eq 0 then begin
              read, ' <Press RETURN to continue>', txt
	      if strupcase(txt) eq 'Q' then return
            endif
          endif
        endfor
 
done:   return
 
	end
