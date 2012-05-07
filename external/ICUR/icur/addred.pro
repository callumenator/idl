;*****************************************************************************
PRO ADDRED,IM,WAVE,FLUX,EBMV,trans     ; CORRECT FOR INTERSTELLAR EXTINCTION 
; TAKEN FROM [210,021]NUNRED.PRO 4/5/83
; IM=0,-1 FOR UNRED
COMMON COM1,H
COMMON VARS,VAR1,VAR2,VAR3,VAR4,VAR5
COMMON ICDISK,ICURDISK,ICURDATA,ISMDAT
common comxy,xcur,ycur,zerr,rsc,lu3
if n_elements(var3) eq 0 then var3=(2*256)      ;REDDENING TABLE
nhd=n_elements(h)
TABLE=FIX(VAR3 AND 7*256)/256
TABLE=FIX(TABLE)
IF (TABLE LT 0) OR (TABLE GT 5) THEN TABLE=2
IF N_PARAMS(0) LE 3 THEN begin
   IF N_ELEMENTS(H) GT 92 THEN BEGIN
      if H(92) ne 0 then cext=string(float(H(92))/1000.,'(F6.2)') else cext=''
      z=' Current E(B-V)='+cext
      if strlen(cext) gt 0 then print,z
      endif
   READ,' Enter E(B-V); - to redden: ',EBMV
   endif 
;trans=wave*0.+1.
;EBMV=-FLOAT(EBMV)
IF EBMV EQ 0. THEN begin
   if nhd gt 92 then h(91:92)=0
   RETURN
   endif
;
isign=ebmv/abs(ebmv)              ;1 to unredded, -1 to redden
ebmv=abs(ebmv)
ismtab=['SAVMAT','SEATON','NANDY','ORI','SMC']
tabfile=ismdat+ismtab(table-1)
;IF TABLE EQ 1 THEN TABFILE=ismdat+'SAVMAT.DAT' ; Savage and Mathis
;IF TABLE EQ 2 THEN TABFILE=ismdat+'SEATON.DAT' ; Seaton
;IF TABLE EQ 3 THEN TABFILE=ismdat+'NANDY.DAT'  ; Nandy
;IF TABLE EQ 4 THEN TABFILE=ismdat+'ORI.DAT' ; Bohlin & Savage
;IF TABLE EQ 5 THEN TABFILE=ismdat+'SMC.DAT' ; Sm Magellenic Clouds
trans=ism(wave,ebmv,tabfile)

;IF ABS(EBMV LT 100.) THEN NH=EBMV*5.9E21 ELSE NH=EBMV
;Q=912.
;SI=N_ELEMENTS(WAVE)-1
;SIG=WAVE*0.
;LMAX=WAVE(SI)
;APB=(LMAX-WAVE(0))/FLOAT(SI)
;IMIN=(((Q-WAVE(0))/APB > 0) < SI)
;IF LMAX GT Q THEN BEGIN   ; USE A TABULATED REDDENING LAW
;   ;
;   ; if user is to enter the name of the table file
;   GET_LUN,LUN
;   TABFILE=''
;   IF TABLE EQ 0 THEN REPEAT BEGIN
;      PRINT,'Please enter the name of the file containing the extinction curve'
;      PRINT,'you want to use.  The wavelength information must be in record one'
;      PRINT,'and the flux in record 2.'
;      READ,'What is the name of the file ?',TABFILE
;      OPENR,LUN,TABFILE
;      END UNTIL !ERR GT 0
;   ;
;   IF TABLE EQ 1 THEN TABFILE=ismdat+'SAVMAT.DAT' ; Savage and Mathis
;   IF TABLE EQ 2 THEN TABFILE=ismdat+'SEATON.DAT' ; Seaton
;   IF TABLE EQ 3 THEN TABFILE=ismdat+'NANDY.DAT'  ; Nandy
;   IF TABLE EQ 4 THEN TABFILE=ismdat+'ORI.DAT' ; Bohlin & Savage
;   IF TABLE EQ 5 THEN TABFILE=ismdat+'SMC.DAT' ; Sm Magellenic Clouds
;   OPENR,LUN,TABFILE
;   tlun=fstat(lun) & zlen=tlun.rec_len/4
;   Z=ASSOC(LUN,FLTARR(zlen))          ; Z is always associated variable 
;   XTAB=Z(0)                          ; S & M wavelength in record 0
;   YTAB=Z(1)                          ; S & M flux in record 1
;   CLOSE,LUN & FREE_LUN,LUN
;   I=WHERE(XTAB GT 0)               
;   XTAB=FLOAT(XTAB(I))        ; extract valid points and make sure they 
;   YTAB=FLOAT(YTAB(I))        ;  are floating point format 
;   F=FLOAT(FLUX)                      ; make sure input wave and flux are 
;   W=FLOAT(WAVE)                      ;  floating point format 
;   TAB='??!! SEE DATA AID !!??'
;   IF TABLE EQ 1 THEN TAB=' (Savage and Mathis) '
;   IF TABLE EQ 2 THEN TAB=' (Seaton) '
;   IF TABLE EQ 3 THEN TAB=' (Nandy) '
;   IF TABLE EQ 4 THEN TAB=' (Orion) '
;   IF TABLE EQ 5 THEN TAB=' (SMC) '
;   IF TABLE EQ 0 THEN TAB=TABFILE
;   ;PRINT,'The flux is being unreddened.',TAB,'E(B-V) = ',EBMV
;   X=INTERPOL(YTAB,XTAB,W)         ; interp table to current wavelngth scale
;   SIG(IMIN)=1.65E-22*(X(IMIN:*)+3.1)
;   LMAX=Q
;   ENDIF
;IF WAVE(0) LT Q THEN BEGIN
;   FOR I=0,IMIN DO BEGIN
;      LAM=WAVE(I)
;      IF (LAM LE 912.) AND (LAM GT 504.) THEN BEGIN  ; H-He 
;         SLO=2.58 & INT=-24.86 & GOTO,SIGM
;         ENDIF
;      IF (LAM LE 504.) AND (LAM GT 43.648) THEN BEGIN  ; He-C 
;         SLO=2.72 & INT=-25.05 & GOTO,SIGM
;         ENDIF
;      IF (LAM LE 43.648) AND (LAM GT 30.99) THEN BEGIN  ;  C-N
;         SLO=2.87 & INT=-25.22 & GOTO,SIGM
;         ENDIF
;      IF (LAM LE 30.99) AND (LAM GT 23.301) THEN BEGIN  ; N-O
;         SLO=3.06 & INT=-25.48 & GOTO,SIGM
;         ENDIF
;      IF (LAM LE 23.301) AND (LAM GT 14.3018) THEN BEGIN  ; N-Ne
;         SLO=2.54 & INT=-24.52 & GOTO,SIGM
;         ENDIF
;      IF (LAM LE 14.3018) AND (LAM GT 9.5122) THEN BEGIN  ;  Ne=Mg
;         SLO=2.52 & INT=-24.46 & GOTO,SIGM
;         ENDIF
;      IF (LAM LE 9.5122) AND (LAM GT 6.738) THEN BEGIN  ;  Mg-Si
;         SLO=1.91 & INT=-23.80 & GOTO,SIGM
;         ENDIF
;      IF (LAM LE 6.738) AND (LAM GT 5.019) THEN BEGIN  ; Si-S
;         SLO=3.73 & INT=-25.27 & GOTO,SIGM
;         ENDIF
;      IF (LAM LE 5.019) AND (LAM GT 3.871) THEN BEGIN  ; S-A
;         SLO=2.96 & INT=-24.68 & GOTO,SIGM
;         ENDIF
;      IF LAM LE 3.871 THEN BEGIN ;FINALLY SHORTWARD OF ARGON K EDGE
;         SLO=2.99 & INT=-24.68 & GOTO,SIGM
;         ENDIF
;      SIGM:SIG(I)=10.^(((SLO)*ALOG10(LAM))+INT)
;      ENDFOR
;   ENDIF
;T=(SIG*NH<80.)
;TRANS=EXP(-T)
;
if isign eq 1 then flux=flux/trans else $    ;unredden
     FLUX=Flux*TRANS   ; redden flux
if (im ne -1) and (nhd gt 0) and (n_elements(lu3) gt 0) then begin
   H(91)=TABLE                  ; unreddening flag
   H(92)=H(92)+FIX(isign*1000*EBMV)   ; total E(b-v)*1000 
   IF H(92) EQ 0 THEN H(91)=0   ;NO REDDENING
   printf,lu3,'-5'
   printf,lu3,'Data Unreddened: Table=',TABLE,' ',TABFILE,'; E(B-V)=',EBMV
   endif
RETURN
END
