;***********************************************************************
PRO RREBIN,WAVE,W1,F1,E1,flag                  ; REBIN DATA IF DISPERSIONS DIFFER
flag=0
OFF=WAVE(0)-W1(0)    ;offset of first points
S0=N_ELEMENTS(WAVE)
k=where((w1 ge wave(0)) and (w1 le wave(s0-1)))   ;overlap region
if k(0) eq -1 then begin
   print,' ERROR in REBIN: no overlap'
   flag=-1
   return
   endif
;
;help,k
w1=w1(k)
f1=f1(k)
e1=e1(k)
S1=N_ELEMENTS(W1)
;
; COMPUTE DISPERSION
;
D0=(WAVE(S0-1)-WAVE(0))/FLOAT(S0)
D1=(W1(S1-1)-W1(0))/FLOAT(S1)
DD=D0/D1   ; RATIO OF DISPERSIONS
;
DEL=0.00005
DELTA=ABS(DD-1.)
IF DELTA LT DEL THEN RETURN   ; EQUAL DISPERSIONS, ADJUST SCALE LATER
;
; REBIN THE DATA
ST=S1>FIX(S0/DD)
;ST=ST<2050
ST=ST+1+FIX(DD)
T=FLTARR(ST)
T(0)=F1
TE=INTARR(ST)-700
TE(0)=E1
F1=FLTARR(S0) & E1=INTARR(S0)+100
FOR I=0,S0-1 DO BEGIN      ; LOOP TO REBIN SECOND DATA SET
     BL=DD*I & BH=BL+DD
     IBL=FIX(BL) & IBH=FIX(BH)
     IF IBH GE ST THEN GOTO,BAIL
     IF IBL EQ IBH THEN BEGIN    ; IN SAME BIN
          F1(I)=T(IBL)*DD
          IF TE(IBL) LT 0 THEN E1(I)=TE(IBL)
          ENDIF
     IF IBH GT IBL THEN BEGIN
          DEL=IBH-IBL
          LL=BL-FLOAT(IBL)
          LL=1.-LL
          UL=BH-FLOAT(IBH)
          F1(I)=T(IBL)*LL+T(IBH)*UL
          IF TE(IBL) LT 0 THEN E1(I)=TE(IBL)
          IF TE(IBH) LT 0 THEN E1(I)=TE(IBH)
          IF DEL GT 1 THEN BEGIN
               N=DEL-1
               FOR J=1,N DO BEGIN
                    F1(I)=F1(I)+T(IBL+J)
                    IF TE(IBL+J) LT 0 THEN E1(I)=TE(IBL+J)
                    ENDFOR
               ENDIF
          ENDIF
     ENDFOR
BAIL:   ;BAIL OUT IF IBH TOO BIG
F1=F1/DD   ; PUT PER ANGSTROM
w1=w1(0)+findgen(n_elements(f1))*dd
;W1=WAVE-OFF    ; make W1,F1 vectors consistent
RETURN
END
