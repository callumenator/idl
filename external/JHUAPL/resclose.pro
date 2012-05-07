;-------------------------------------------------------------
;+
; NAME:
;       RESCLOSE
; PURPOSE:
;       Close results file.
; CATEGORY:
; CALLING SEQUENCE:
;       resclose
; INPUTS:
; KEYWORD PARAMETERS:
;       Keywords:
;         /QUIET suppresses error messages.
; OUTPUTS:
; COMMON BLOCKS:
;       results_common
; NOTES:
;       Notes: one of the results file utilities.
;         See also resopen, resput, resget, rescom.
; MODIFICATION HISTORY:
;       R. Sterner, 19 Jun, 1991
;       R. Sterner, 14 Feb, 1992 --- added /QUIET.
;
; Copyright (C) 1991, Johns Hopkins University/Applied Physics Laboratory
; This software may be used, copied, or redistributed as long as it is not
; sold and this copyright notice is reproduced on each copy made.  This
; routine is provided as is without any express or implied warranties
; whatsoever.  Other limitations apply as described in the file disclaimer.txt.
;-
;-------------------------------------------------------------
 
	pro resclose, help=hlp, quiet=quiet
 
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
	  print,' Close results file.'
	  print,' resclose'
	  print,'   No arguments.'
	  print,' Keywords:'
	  print,'   /QUIET suppresses error messages.'
	  print,' Notes: one of the results file utilities.'
	  print,'   See also resopen, resput, resget, rescom.'
	  return
	endif
 
	if n_elements(r_open) eq 0 then r_open = 0
	;-------  File open?  ----------
	if r_open eq 0 then begin
	  if not keyword_set(quiet) then print,' No results file is open.'
	  return
	endif
 
	;------  Close file that was open for reading  -----
	if r_open eq 1 then begin
	  close, r_lun
	  free_lun, r_lun
	  r_open = 0
	  return
	endif
 
	;------  Close file that was open for writing  ------
	;---  Must first write header at end of file  -------
	if n_elements(r_hdr) eq 1 then begin	; NULL file.
	  if not keyword_set(quiet) then print,' Nothing written to file.'
	  goto, skip
	endif
 
	fs = fstat(r_lun)		; Get file status.
	fp = fs.cur_ptr			; Get file pointer.
	fp = 4L*ceil(fp/4.)		; Force to multiple of 4.
	front = lonarr(3)		; Set up first thing in file.
	front(0) = fp			; Item 1 is header position.
	r_hdr = r_hdr(1:*)		; Trim leading null.
	r_hdr = [r_hdr,'END']		; Add END.
	b = byte(r_hdr)			; Convert header to a byte array.
	sz = size(b)			; Get size.
	front(1) = sz(1:2)		; Move header size to FRONT array.
	point_lun, r_lun, fp		; Set file pointer to header position.
	writeu, r_lun, b		; Write header as byte array.
	point_lun, r_lun, 0		; Set file pointer to file start.
	writeu, r_lun, front		; Write header pointer and size.
skip:	close, r_lun			; Close file.
	free_lun, r_lun
	r_open = 0			; Flag as closed.
	return
 
	end
