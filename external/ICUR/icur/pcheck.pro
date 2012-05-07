;************************************************************************
;+
;
;*NAME:
;
;    PCHECK
;
;*CLASS:
;
;*CATEGORY:
;
;*PURPOSE:
;
;    This procedure is used to check the parameters of
;    a procedure for correct type and dimensions
;
;*CALLING SEQUENCE:
;
;    PCHECK,VARIABLE,POSITION,DIMENSION,TYPE
;
;*PARAMETERS:
;
;    VARIABLE  - Variable to be checked
;    POSITION  - Parameter position of the variable
;    DIMENSION - Valid dimensions (3 digit integer).	
; 	    	 Each digit must be 0 or 1.
;		 1 specifies that the dimension is valid.
;
;		   1st digit  -   scalar
;		   2nd        -   one dimensional array
;		   3rd        -   two dimensional array
;
;    TYPE      - Valid types ( 4 digit integer).
;		 Each digit must be 0 or 1.
;		 1 specifies a valid type.
;
;		   1st digit -  string
;		   2nd       -  byte
;		   3rd       -  integer, or longword integer
;		   4th       -  floating point, double precision or complex
;
;*EXAMPLES:
;
;*SYSTEM VARIABLES USED:
;
;*INTERACTIVE INPUT:
;
;*SUBROUTINES CALLED:
;
;*FILES USED:
;
;*SIDE EFFECTS:
;
;*RESTRICTIONS:
;
;*NOTES:
;
;    tested with IDL Version 2.1.0  (sunos sparc)    28 Jun 91
;    tested with IDL Version 2.1.0  (ultrix mipsel)  N/A
;    tested with IDL Version 2.1.0  (vax vms)        28 Jun 91
;
;*PROCEDURE:
;
;*I_HELP  nn:
;
;*MODIFICATION HISTORY:
;
;    d. lindler dec. 1980
;    version 2 f.h.schiffer 3rd 17 nov 1981
;            copied into [177001] by rwt 1-17-84
;    10-24-85 rwt modify for new didl data types: longword integer,
;             double precision & complex. modified to be compatible
;             with existing version (i.e., no new input parameters)
;    21-sep-88:  converted to sun idl, john hoegy.
;    10 May 91	PJL created a RDAF format prolog
;    28 Jun 91  PJL added npar test; tested on SUN and VAX; updated prolog
;
;-
;*************************************************************************
 pro pcheck,variable,position,dimension,type
;
 npar = n_params(0)
 if npar eq 0 then begin
    print,'PCHECK,VARIABLE,POSITION,DIMENSION,TYPE'
    retall
 endif  ; npar
;
; decode valid dimensions
;
 vdim = bytarr(3)
 idim = dimension
 for i = 0,2 do begin
    itemp = idim / 10*10
    vdim(2 - i) = idim - itemp
    idim = idim / 10
 endfor  ; i
;
; decode valid types
;
 itype = fix(type)
 vtype = bytarr(4)
 for i = 0,3 do begin
    itemp = itype / 10*10
    vtype(i) = itype - itemp
    itype = itype / 10
 endfor  ; i
;
; determine type and dimension of the input variable
;
 s = size(variable)
 ndim = s(0)
 ntype = s(ndim + 1)
;
; check if it is defined
;
 if ntype eq 0 then begin
    print,' Input variable number',position,' is not defined'
    goto,explain
 endif  ; ntype eq 0
;
; check for valid type
;
 if (ntype eq 7) and ( vtype(3) ne 0 ) then goto,checkd ;string
 if (ntype eq 1) and ( vtype(2) ne 0 ) then goto,checkd ;byte
 if (ntype eq 2) and ( vtype(1) ne 0 ) then goto,checkd ;integer
 if (ntype eq 3) and ( vtype(1) ne 0 ) then goto,checkd ;longword integer
 if (ntype eq 4) and ( vtype(0) ne 0 ) then goto,checkd ;floating pt.
 if (ntype eq 5) and ( vtype(0) ne 0 ) then goto,checkd ;double precision
 if (ntype eq 6) and ( vtype(0) ne 0 ) then goto,checkd ;complex
;
 print,'The parameter in position',position,' is of invalid type'
 goto,explain
;
;
; check for a valid dimension
;
 checkd:  if vdim(ndim) ne 0 then return
 print,'Input variable in position',position,' has wrong dimension'
;
; give correct type(s) and dimensions
;
 explain:
 tmsg='     The valid type(s) are: '
 if vtype(3) ne 0 then tmsg = tmsg + ' string '
 if vtype(2) ne 0 then tmsg = tmsg + ' byte '
 if vtype(1) ne 0 then tmsg = tmsg + ' integer '
 if vtype(0) ne 0 then tmsg = tmsg + ' floating point '
 print,tmsg
;
 tmsg='  The valid dimensions are:'
 if vdim(2) ne 0 then tmsg = tmsg + ' 2-d '
 if vdim(1) ne 0 then tmsg = tmsg + ' 1-d '
 if vdim(0) ne 0 then tmsg = tmsg + ' scalar'
 print,tmsg
 print,'Type .con or retall to continue'
 stop
;
 retall
 end  ; pcheck
