;************************************************************************
PRO DEGRADE,W,F,E,BW,BF          ; DEGRADE IUE HI-RES DATA INTO LO-RES DATA
; W,F,E ARE OVERWRITTEN, AND IDAT IS SET TO 0 (LO-RES)
COMMON COM1,H,IK,IFT,NSM,C
common comxy,xcur,ycur,zerr
csave=c & nsave=nsm
IF h(3) gt 4 THEN BEGIN
   PRINT,' You cannot DEGRADE this type of data.'
   zerr=68                          ;do plot
   RETURN
   ENDIF
S=N_ELEMENTS(W)
T1=F
T2=W
DISP=(W(50)-W(0))/50.
if disp gt 1. then begin
   print,' This is not high resolution data.'
   return
   endif
case 1 of
   h(3) ge 3: lodisp=1.2                       ;SW
   (h(3) eq 1) or (h(3) eq 2): lodisp=1.88     ;LW
   else: begin
      print,'DEGRADE:  invalid camera - returning'
      return
      end
   endcase
IDIM=FIX(lodisp/DISP)
if idim le 1 then begin
   print,'DEGRADE: dispersion ratios =',idim,'  Returning'
   return
   endif
;
V=8.0                                ;LWP 
IF h(3) ge 3 THEN V=6.0              ;SWP
ROTVEL,-2,W,V/2.
S=N_ELEMENTS(C)
IF S gt 1 THEN F=CONVOL(F,C)
c=csave & nsm=nsave
coadd,w,f,e,idim
;
H(51)=FIX((V-10000)/10.)
H(52)=100*FIX(V-FIX(V))
H(1)=2
H(2)=999
BDATA,H,-1,W,F,E,BW,BF
ZERR=68
RETURN
END
