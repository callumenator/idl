;****************************************************************
PRO IRPLOT,WAVE,FLUX,XN,YN,FLAG,IGO,FRES,ebar,sr=sr,ieb=ieb, $   ; PLOT LINE FITS
      stp=stp
COMMON VARS,VAR1,VAR2,VAR3
COMMON COM1,H,IK,IFT,NSM,C,ndat,ifsm,kblo
COMMON COM2,A,B,FH,FIXT,ISHAPE
COMMON COMXY,X,Y
common icurunits,xunits,yunits,title,c1,c2,c3,ch
;
if not keyword_set(sr) then sr=0
if n_elements(title) gt 0 then tid=title else tid=''
if rdbit(var3,4) then nocap=1
ILOOP=-1
START:
ILOOP=ILOOP+1
!c=-1
if !d.name eq 'PS' then pcol=4 ELSE PCOL=249
IF ILOOP gt 0 THEN PLOT,WAVE,FLUX,COLOR=pcol,psym=10,title=tid
IK=0
IFT=0
out=-1
case 1 of 
   (FLAG EQ 1) AND (ABS(IGO) EQ 1): RESIDUAL,IGO,WAVE,FLUX,XN,YN,FRES,sr=sr
   (FLAG EQ 1) AND (IGO EQ 4): ocomps,xn,yn           ;overplot components
   FLAG EQ -1: irdefplt,wave,flux,xn,yn,flag,igo      ;autoplot after first pass
   else:       irinit,wave,out                        ;reset axes
   endcase
if keyword_set(ieb) and (n_elements(ebar) eq n_elements(flux)) then begin
   if !d.name eq 'X' then cs=pcol else cs=pcol
   K=WHERE((WAVE GE !X.CRANGE(0)) AND (WAVE LE !X.CRANGE(1)),NK)
   IF NK GT 0 THEN FOR I=0,NK-1 DO oplot,[wave(k(i)),wave(k(i))], $
      [flux(k(i))-ebar(k(i)),flux(k(i))+ebar(k(i))],psym=0,color=cs
   endif
if out eq 1 then goto,start
if out eq 2 then irdefplt,wave,flux,xn,yn,flag,igo
if keyword_set(stp) then stop,'IRPLOT>>>'
return
end
