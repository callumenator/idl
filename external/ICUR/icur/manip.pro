;*******************************************************************
PRO MANIP,FLUX,F1,F,EPS,E1,badf,TIME=TIME      ; ADD,SUBTRACT,MULTIPLY,DIVIDE
COMMON COM1,HD,IK,IFT,NSM,C
COMMON COMXY,XCUR,YCUR,ZERR
nt=1                               ;no time vector
H33=HD(33)
if KEYWORD_SET(TIME) then begin     ;time vector passed
   nt=0
   if total(time) le 0 then nt=1  ;null vector
   endif
FCTN=0
P=NSM
NAX=rdbit(var3,1)
IF P GT 1000 THEN P=-P
CASE 1 OF
   P GE 3: TF=SMOOTH(FLUX,NSM)
   (P GE 0) AND (P LT 3): TF=FLUX
   ELSE: TF=CONVOL(FLUX,C)
   ENDCASE
IF NAX EQ 1 THEN TF=FLUX     ;NOT SMOOTHED
CASE 1 OF
   P GE 3: TF1=SMOOTH(F1,NSM)
   (P GE 0) AND (P LT 3): TF1=F1
   ELSE: TF1=CONVOL(F1,C)
   ENDCASE
;
CASE 1 OF
   ZERR EQ 37: BEGIN     ;<%>
      F=F1/TF
      FCTN=6
     !y.title='!6Fractional Deviation'
      IF H33 EQ 30 THEN e=errdiv(f1,f1/e1,f,f/eps)
      IF H33 EQ 40 THEN e=errdiv(f1,e1,f,eps)
      END
   ZERR EQ 38: BEGIN     ;<&> sums GOOD DATA, WEIGHTED BY TIMES
      IF (HD(5) EQ 0) OR (HD(205) EQ 0) THEN BEGIN  ;TIMES UNKNOWN
         T1=1. & T2=1.
         ENDIF ELSE BEGIN    ;OBSERVATION TIME
         IF HD(5) LT 0 THEN T1=-60.*FLOAT(HD(5)) ELSE T1=FLOAT(HD(5))
         IF HD(205) LT 0 THEN T2=-60.*FLOAT(HD(205)) ELSE T2=FLOAT(HD(205))
         ENDELSE
      TW1=(EPS+201)/ABS(EPS+201) > 0   ;0 IF BAD, 1 IF OK
      TW2=(E1+201)/ABS(E1+201) > 0
      TV1=T1*FLOAT(TW1) & TV2=T2*FLOAT(TW2)
      IF NT EQ 0 THEN TV1=time   ;INPUT VECTOR
      TW=FLOAT(TW1+TW2) > 1.   ;1 OR 2
      F=TF*TV1+TF1*TV2   ;INTEGRATED COUNTS
      time=(TV1+TV2)
      F=F/(time > 1.)
      FCTN=5
      IF H33 EQ 30 THEN e=sqrt(eps*eps*t1*t1+e1*e1*t2*t2)/(t1+t2)
      IF H33 EQ 40 THEN e=sqrt(eps*eps*t1*t1+e1*e1*t2*t2)/2.*(t1+t2)
      END
   ZERR EQ 42: BEGIN     ;<*>
      F=TF*TF1
      FCTN=3
      IF H33 EQ 30 THEN e=sqrt(eps*eps+e1*e1)
      IF H33 EQ 40 THEN e=sqrt(eps*eps+e1*e1)/2.
      END
   ZERR EQ 43: BEGIN     ;<+>
      F=TF+TF1
      FCTN=1
      IF H33 EQ 30 THEN e=sqrt(eps*eps+e1*e1)
      IF H33 EQ 40 THEN e=sqrt(eps*eps+e1*e1)/2.
      END
   ZERR EQ 45: BEGIN     ;<->
      F=TF-TF1
      FCTN=2
      IF H33 EQ 30 THEN e=sqrt(eps*eps+e1*e1)
      IF H33 EQ 40 THEN e=sqrt(eps*eps+e1*e1)/2.
      END
   ZERR EQ 47: BEGIN     ;</>
      F=TF/TF1
      FCTN=4
      !y.title='!6Flux Ratio'
      IF H33 EQ 30 THEN e=errdiv(tf,tf/eps,tf1,tf1/e1)
      IF H33 EQ 40 THEN e=errdiv(tf,eps,tf1,e1)
      END
   ZERR EQ 53: BEGIN     ;<%>
      F=TF-TF1
      K=WHERE(TF EQ 0.,CK)
      TTF=TF 
      IF CK GT 0 THEN TTF(K)=1.
      F=F/TTF
      IF CK GT 0 THEN F(K)=0.
      !y.title='!6Fractional Difference'
      FCTN=7
      IF H33 EQ 30 THEN e=errdiv(f,f/sqrt(eps*eps+e1*e1),ttf,ttf/eps)
      IF H33 EQ 40 THEN e=errdiv(f,sqrt(eps*eps+e1*e1)/2.,ttf,eps)
      END
   ZERR EQ 41:          ;<)>  - DEFINED ELSEQHERE
   ELSE: PRINT,' MANIP: ZERR=',ZERR
   ENDCASE
IF H33 GE 30 THEN bdata,hd,-1,f*0.,f,e,bw,badf
HD(38)=NSM
HD(37)=FCTN
RETURN
END
