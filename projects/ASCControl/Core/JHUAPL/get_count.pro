;-------------------------------------------------------------
;+
; NAME:
;       GET_COUNT
; PURPOSE:
;       Get next count value, from 1 up.
; CATEGORY:
; CALLING SEQUENCE:
;       c = get_count(tag)
; INPUTS:
;       tag = Any text string.                 in
; KEYWORD PARAMETERS:
;       Keywords:
;         FILE=file  Name of count file to use (def=count_file.txt
;           in current directory.
;         /ZERO  zero counter for given tag.  Does not return
;           a count.  Count for next normal call will be 1.
;         SET=c  set counter to given value for given tag.  Does not
;           return a count. Count for next normal call will be c+1.
; OUTPUTS:
;       c = Count corresponding to given tag.  out
;         Returned as a string.
; COMMON BLOCKS:
; NOTES:
;       Notes: this routine returns the number of times it has
;         been called with the given tag.  The counts are saved
;         in a count file which defaults to count_file.txt in
;         current directory.  This is a simple text file and
;         may be modifed.  Useful for creating a series of
;         related file names.  Could use date2dn to generate
;         a tag value.  Use a unique tag for each purpose.
; MODIFICATION HISTORY:
;       R. Sterner, 1995 Jul 6
;
; Copyright (C) 1995, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
	function get_count, tag, file=file, zero=zero, set=set, help=hlp
 
	if (n_params(0) lt 1) or keyword_set(hlp) then begin
	  print,' Get next count value, from 1 up.'
	  print,' c = get_count(tag)'
	  print,'   tag = Any text string.                 in'
	  print,'   c = Count corresponding to given tag.  out'
	  print,'     Returned as a string.'
	  print,' Keywords:'
	  print,'   FILE=file  Name of count file to use (def=count_file.txt'
	  print,'     in current directory.'
	  print,'   /ZERO  zero counter for given tag.  Does not return'
	  print,'     a count.  Count for next normal call will be 1.'
	  print,'   SET=c  set counter to given value for given tag.  Does not'
	  print,'     return a count. Count for next normal call will be c+1.'
	  print,' Notes: this routine returns the number of times it has'
	  print,'   been called with the given tag.  The counts are saved'
	  print,'   in a count file which defaults to count_file.txt in'
          print,'   current directory.  This is a simple text file and'
	  print,'   may be modifed.  Useful for creating a series of'
	  print,'   related file names.  Could use date2dn to generate'
	  print,'   a tag value.  Use a unique tag for each purpose.'
	  return,''
	endif
 
	if n_elements(file) eq 0 then file = 'count_file.txt'
 
	;------  Create count file if it does not exist  -----------
	f = findfile(file,count=c)	; Does count file exists?
	if c eq 0 then begin		; No, create it.
	  t = [tag+'      1']		; Add new tag line.
	  putfile,file,t		; Update count file.
	  return,'1'			; And return 1 for tag.
	endif
 
	;------  Read in count file  ------------
	t = getfile(file, err=err)
	if err ne 0 then begin
	  print,' Error in get_count: no such count file:'
	  print,'   '+file
	  return,'0'		; Error value.
	endif
 
	;-------  Zero a count  ------------------
	if keyword_set(zero) then begin
	  val = txtgetkey(init=t,del=' ',tag,index=i)	; Find tag.
	  if val eq '' then begin			; No such tag.
	    print,' Error in get_count: no such tag: '+tag
            return,'0'                    		; Return 0 for error.
          endif
	  t(i) = tag+'      0'				; Clear counter to 0.
	  putfile,file,t				; Save changes.
	  return,''					; Nothing to return.
	endif
 
	;-------  Set a count  ------------------
	if n_elements(set) ne 0 then begin
	  val = txtgetkey(init=t,del=' ',tag,index=i)	; Find tag.
	  if val eq '' then begin			; No such tag.
	    print,' Error in get_count: no such tag: '+tag
            return,'0'                    		; Return 0 for error.
          endif
	  t(i) = tag+'      '+strtrim(set,2)		; Set counter.
	  putfile,file,t				; Save changes.
	  return,''					; Nothing to return.
	endif
 
	;-------  Add tag if new  ----------------
	val = txtgetkey(init=t,del=' ',tag,index=i)  ; Find tag.
	if val eq '' then begin			; Handle new tag.
	  t = [t,tag+'      1']			; Add new tag line.
          putfile,file,t			; Update count file.
          return,'1'                    	; And return 1 for tag.
        endif
 
	;--------  Find and update tag count  ----------
	val = string(val+1,form='(I8)')		; Increment count.
	t(i) = tag+val  	               	; Add new tag line.
        putfile,file,t				; Update count file.
        return,strtrim(val,2)			; And return count for tag.
 
	end
