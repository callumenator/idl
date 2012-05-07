;*********************************************************
pro ocomps,xn,yn
COMMON COM1,H,IK,IFT,NSM,C
COMMON COM2,A,B,FH,FIXT,ISHAPE
common icurunits,xu,yu,tit,c1,c2
common tvcoltab,rr,gg,bb,opcol,ctnum
;
; set up colors for workstation
;
if !d.NAME NE 'X' then cs=intarr(7) else case 1 of
   n_elements(ctnum) eq 0: cs=intarr(7) 
   ctnum eq 11: cs=[25,55,35,45,5,65,75]
   ctnum eq 13: cs=[2,5,3,4,1,6,7]
   else: cs=intarr(7)
   endcase
;
NB=N_ELEMENTS(YN)
DB=(XN(NB-1)-XN(0))/(NB-1)
XB=FINDGEN(NB)-0.5
Q=A(0)+A(1)*XB+A(2)*XB*XB
XB=XN-DB/2.
IF ISHAPE LE 1 THEN goto,back
FOR I=1,ISHAPE-1 DO BEGIN
   IK=I*3+1
   IF A(IK+1) EQ 0. THEN GOTO,ZWID
   Y1=Q*0.
;   Z=(XB-A(IK))/A(IK+1)/db
   Z=(XB-A(IK)+0.5*db)/A(IK+1)/db
   Z=Z*Z*2. <7. 
   Y1=A(IK-1)*EXP(-Z)+Q
   !c=-1
   OPLOT,XN,Y1,PSYM=0,COLOR=CS(I)
   ZWID:
   ENDFOR
back:
!c=-1
OPLOT,XN,Q,PSYM=0,COLOR=CS(0)
RETURN
end
