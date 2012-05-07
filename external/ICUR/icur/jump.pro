;**********************************************************************
pro jump,nang     ; MOVE ALONG X AXIS A SPECIFIED NUMBER OF ANGSTROMS
COMMON COMXY,XCUR,YCUR,ZERR
if n_params(0) le 0 then begin
   PRINT,' '
   READ,' ENTER NUMBER OF ANGSTROMS TO JUMP: ',NANG
   endif
!X.RANGE=!X.RANGE+NANG
zerr=68
RETURN
end
