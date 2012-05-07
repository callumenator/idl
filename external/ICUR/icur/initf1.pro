;**********************************************************************
PRO INITF1,WAVE,FLUX,EPS,W1,F1,E1,F,E,RESET,BADW,BADF,noplot=noplot, $
    noerase=noerase,stp=stp  ; INITIALIZE DATA
COMMON COM1,HD,IK,IFT,NSM,C,NDAT,IFSM,KBLO,H1
COMMON COMXY,X,Y,ZERR
COMMON VARS,VAR1,VAR2,VAR3
common icurunits,xu,yu,title,c1,c2
if keyword_set(helpme) then begin
   print,' '
   print,'* INITF1 - initialize second flux vector in FUN1'
   print,'*'
   print,'* KEYWORDS: '
   print,'*    NOPLOT: if not set, both data vectors will be plotted'
   print,'*    NOERASE: if set, only second data vector will be over plotted'
   print,'*'
   print,' '
   return
   endif
NSC=rdbit(var3,2)      ;AUTOSCALE?
OVERWRT,0,FLUX,0,0,F,0,0,RESET
HD(200)=H1(0:199)
FOR I=0,2 DO HD(35+2*I)=0 ;  LOG OF SCALING FACTOR, FCTN, OFFSET
HD(34)=2   ;  TWO DATA SETS
HD(38)=1   ;  NSM
RREBIN,WAVE,W1,F1,E1,flag
nw=N_ELEMENTS(WAVE)
NF=N_ELEMENTS(F1)
NP=NF-NW
   case 1 of
      np lt 0: begin   ;pad vector
         f1=[f1,flUX(NF:NW-1)]
         e1=[e1,flTARR(-NP)-1000]
         end
      np gt 0: begin   ; shorten vector
         f1=f1(0:nw-1)
         e1=e1(0:nw-1)
         end
      else:
      endcase
 
zerr=81
if flag eq -1 then return
WSHIFT,0,WAVE,FLUX,EPS,F1,E1,E,W1
IF NSC EQ 0 THEN SCALE,-1,WAVE,FLUX,F1
BDATA,HD,-1,WAVE,F,E,BADW,BADF
if not keyword_set(noplot) then begin
   if not keyword_set(noerase) then PLDATA,0,WAVE,FLUX,psm=0
;
   if rdbit(var3,2) eq 0 then begin                         ;scale within window
      k=where((wave ge !x.crange(0)) and (wave le !x.crange(1)),nk)
      if nk gt 1 then begin
         fact=total(flux(k))/total(f1(k))
         f1=f1*fact
         fact=10^(hd(35)/100.)*fact
         hd(35)=fix(alog10(fact)*100.)
         endif
      endif
;
   pldata,1,wave,f1,pcol=c2,psm=0
   IF ((N_ELEMENTS(Hd) GE 33) AND (hd(33) eq 30)) then sn=1 else sn=0 ;SN vector?
   IF SN EQ 0 THEN TKP,7,BADW,BADF*0.
   endif
ZERR=32
if keyword_set(stp) then stop
RETURN
END
