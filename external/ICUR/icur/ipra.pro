;*******************************************************************
PRO IPRA,NSM,H,ZZ,SIZE=SIZE    ;   PRINT #S ON PLOT
COMMON COM2,A,B,FH,FIXT,ISHAPE
;
IF NOT KEYWORD_SET(SIZE) THEN SIZE=1.4
;
if n_elements(zz) eq 0 then zz=''
Z=strtrim(zz,2)+' '
nh=n_elements(h)
if nh gt 5 then begin
   IF H(3) LE 4 THEN BEGIN   ;IUE DATA
      CAMERA=STRMID('    LWP LWR SWP SWR',H(3)*4,4)
      if h(4) le 0 then h4=65536L+h(4) else h4=h(4)           ;image overflow
      Z=Z+CAMERA+STRING(FORMAT='(I5,"   NSM:",I5)',H4,NSM)
      ENDIF ELSE BEGIN      ;KPNO DATA
      if nh gt 140 then LAB=BYTE(H(100:139)>32) else lab=' '
      if nh gt 12 then Z=Z+STRING(FORMAT='(I3)',H(10)) $ 
         +STRING(FORMAT='(I3)',H(11))+STRING(FORMAT='(I3)',H(12)) else z=''
      Z=Z+' '+STRTRIM(STRING(LAB))
      ENDELSE
   endif
;
x0=!d.x_size*!x.window(0)+!d.x_ch_size
y0=!d.y_size*!y.window(1)*(1.-!p.ticklen)-!d.y_ch_size
;
IF ISHAPE EQ 1 THEN RETURN
IF ISHAPE EQ 2 THEN PRTA,1,3,Z
IF ISHAPE GE 3 THEN PRTA,2,3,Z
XYOUTS,x0,Y0,Z,/device,CHARSIZE=SIZE
y0=y0-!d.y_ch_size-1
IF ISHAPE GE 4 THEN BEGIN
   IF ISHAPE EQ 4 THEN PRTA,1,9,Z ELSE PRTA,2,9,Z
   XYOUTS,x0,Y0,Z,CHARSIZE=SIZE
   ENDIF
RETURN
END
