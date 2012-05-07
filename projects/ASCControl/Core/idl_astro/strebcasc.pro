function strebcasc,ebcstring
;+
; NAME:
;	STREBCASC
; PURPOSE: 
;	Function to converts an EBCDIC string to its ASCII equivalent
; EXPLANATION:
;	Similar to the IDL Version 1 routine of the same name.
;
; CALLING SEQUENCE:
;	result = STREBCASC( ebcstring )
;
; INPUT PARAMETERS:
;	EBCSTRING -  String scalar or array written in EBCDIC
;
; OUTPUT:
;	RESULT - the input string converted to ASCII
;
; DATA FILES:
;	STREBCASC reads a file EBCASC.DAT containing the EBCDIC-ASCII conversion
;	code.   This file must be in the directory specified by the logical name
;	or the environment variable ASTRO_DATA (see the first line of the 
;	program) 
;
; COMMON BLOCKS:
;	The conversion matrix read in from EBCASC.DAT is saved in the common
;	block EBCASC for subsequent use. 
;
; PROCEDURE:
;	Each EBCDIC character is converted to its ASCII equivalent.
;
; NOTES:
;	The conversion of non-printable characters differs somewhat from the
;	Version 1 procedure.
; MODIFICATION HISTORY:
;	Adapted from the IUE program EBCDIC, Wayne Landsman    December, 1990
;	Converted to IDL V5.0   W. Landsman   September 1997
;-   
 datfile = getenv('ASTRO_DATA') + 'ebcasc.dat'

 On_error,2                         ;Return to caller

 common ebcasc,ref                  ;Save the conversion matrix

 zparcheck, 'STREBCASC', ebcstring, 1, [1,7], [0,1,2], $
                   'EBCDIC string scalar or vector'

 if N_elements(REF) NE 256 then begin
   openr, lun, datfile, error=err, /get_lun
   if err LT 0 then begin
       print,!ERR_STRING
       message,'Unable to locate EBCDIC conversion file'
  endif
  P = ASSOC(lun,bytarr(256)) 
  ref = p[0]  
  free_lun,lun
 endif

 ascstring = REF[ byte(ebcstring) ]

 return,string(ascstring)

 end 
