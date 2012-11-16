PRO TINIT,UNIT
;+
; NAME:
;	TINIT   
; PURPOSE:
;	Position a tape for appending a new file
; EXPLANATION:  
;	To position a tape for append a new file by placing it between the
;	final double EOF marks.   (VMS or Unix IDL only)
;
; CALLING SEQUENCE: 
;	TINIT, UNIT
;
; PARAMETERS: 
;	UNIT  - Integer scalar giving tape drive unit number
;
; SYSTEM VARIABLES USED:
;	!ERR
;
; PROCEDURE: 
;	The SKIPF procedure is used to skip files until a double end of file
;	(EOF) is encountered.  The tape is then positioned between the 2 EOF
;	marks.  TINIT will also display the number of files skipped.
;
; RESTRICTIONS:
;
; MODIFICATION HISTORY:
;    W.B. Landsman   March 1990    Adapted from IUE RDAF
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
 On_error,2                     ;Return to caller

 if N_params() EQ 0 then begin
   print,'Syntax - tinit, unit'
   return
 endif
;
; Keep skipping 10 files until a double EOF is found.  (User can interrupt
; the program with a control_C every 10 files)
;
On_ioerror, BAD_TAPE

skip = 0
message,' Searching for double EOF...', /INF

SKIP_FILES: skipf,unit,10
skip = skip + !ERR
if !ERR EQ 10 then goto, SKIP_FILES    
skipf, unit, -1
print, 'TINIT - ' + strtrim(skip-1,2) + ' files skipped to double EOF'
print,'Tape is positioned for writing new files'
return
;
BAD_TAPE:  print,'TINIT: Error reading magnetic tape'
print,strmessage(-!ERR)
return
end   ;   tinit
