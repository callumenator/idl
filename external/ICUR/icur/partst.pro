;******************************************************************
PRO PARTST,WAVE,NCAM,NFIT,X,noquery,pc=pc
COMMON COM2,A,B,FH,FIXT,ISHAPE
common custompars,dw,lp,flatback,x3,x4,x5
X=-1
IF B(0) LE -1 THEN GOTO,GA
IF B(1) LE B(0) THEN GOTO,GB
IF B(2) LT B(0) THEN B(2)=B(0)
IF B(3) GT B(1) THEN B(3)=B(1)
ISHAPE=6
IF A(15) EQ 0. THEN ISHAPE=5
IF A(12) EQ 0. THEN ISHAPE=4
IF A(9) EQ 0. THEN ISHAPE=3
IF A(6) EQ 0. THEN ISHAPE=2
IF A(3) EQ 0. THEN ISHAPE=1
nterms=ishape*3
pc=strarr(nterms)
;
if a(2) ne 0. then begin                  ;parabolic arc specified
   a(2)=-4.*(a(2)-a(0))/((b(1)-b(0))*(b(1)-b(0)))
   a(1)=-a(2)*(b(1)-b(0))
   endif
;
IF ISHAPE EQ 1 THEN GOTO,RET
;COMPUTE FWHM
ASAVE=A
FOR I=2,ISHAPE DO BEGIN
     ILIN=(I-1)*3+2
     i1=xindex(wave,fh(i*2+2))             ;TABINV,WAVE,FH(I*2+2),I1
     ieff=xindex(wave,fh(i*2+1))           ;TABINV,WAVE,FH(I*2+1),IEFF
     A(ILIN)=ABS(I1-IEFF)
     IF A(ILIN) EQ 0. THEN CASE 1 OF
        NCAM LE 5: A(ILIN)=5.         ;IUE
        NCAM EQ 10: A(ILIN)=3.7       ;GOLDCAM
        NCAM/10 EQ 10: A(ILIN)=5.     ;GHRS
        ELSE: A(ILIN)=2.5
        ENDCASE
     ENDFOR
;
FOR I=1,ISHAPE-1 DO BEGIN
     ILIN=I*3 & IPOS=ILIN+1 & IWID=ILIN+2
     IF A(IWID) LE 0. THEN A(IWID)=5.
     IF A(IPOS) LE 0. THEN GOTO,GLIN
     IF A(ILIN) EQ 0. THEN GOTO,GLIN
     A(ILIN)=A(ILIN)-A(0)-a(1)*a(ipos)      ;estimate level above background
     IF I GT 2 THEN BEGIN
          D=ABS(A(IPOS)-ABS(A(IPOS-3)))
          IF D LE A(IWID-3) THEN A(ILIN)=A(ILIN)-A(ILIN-3)
          ENDIF
     ENDFOR
RET: X=0
NP=ISHAPE*3
if n_elements(flatback) eq 0 then flatback=0
if flatback then begin
   A(1)=0. & A(2)=0.
   FIXT(1)=0 & FIXT(2)=0
   endif else begin
   FIXT(1)=1 & FIXT(2)=1
   endelse
IF NFIT EQ 0 THEN RETURN       
NLINE=ISHAPE-1
IF NLINE GE 1 THEN FOR I=1,NLINE DO IF FIXT(I*3+2) EQ 0 THEN A(I*3+2)=ASAVE(I*3+2)
if noquery eq 1 then begin
   print,' parameter inquiry turned off, type P to reset'
   print,' A vector:'
   print,'background:',a(0:2)
   if nline ge 1 then for i=1,nline do print,' line',i,a(i*3:i*3+2)
   goto,fixend
   endif
;
PRINT,' '
PRINT,' '
PRINT,' There are',NP,' parameters in',NLINE,' lines + background'
PRINT,' You may fix parameters by their ordinal (0 - ',NP-1,'), or by'
PRINT,' the negative of the line #.'
PRINT,' -9 ends, -10 stops, -8 resets,-7=flat b, -6=expert mode'
IL=0                                                                     
WHILE IL NE -9 DO BEGIN
     READ,IL
     IF IL EQ -10 THEN BEGIN
         PRINT,' A vector:',a
         print,' set parameter constraints in pc'
         STOP,' PARTST: check and/or reset parameters A'
         ENDIF
     IF IL EQ -9 THEN GOTO,FIXEND
     IF IL EQ -8 THEN begin         ;reset fixed and constrained parameters
         FIXT=INTARR(18)+1
         pc=strarr(nterms)
         endif
     IF IL EQ -7 THEN BEGIN
          A(1)=0. & A(2)=0.
          FIXT(1)=0 & FIXT(2)=0
          ENDIF
     if il eq -6 then amod,a,ishape
     IF (IL GE 0) AND (IL LT NP) THEN FIXT(IL)=0
     IF (IL LT 0) AND (IL GE (-NLINE)) THEN FOR J=0,2 DO FIXT(J-IL*3)=0
     ENDWHILE
FIXEND:
FOR I=0,NLINE DO BEGIN
   J=I*3
   Z=STRING(FORMAT='(I1,A2,3I1)',I,': ',FIXT(J:J+2))
   PRINT,Z
   ENDFOR
RETURN
GLIN: z=' REENTER LINE'+string(FORMAT='(I2)',I)
print,z
RETURN
GA: print,' ** Reenter A'
RETURN
GB: print,' ** Reenter B'
RETURN
END
