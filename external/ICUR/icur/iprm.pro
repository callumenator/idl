;*****************************************************************
PRO IPRM,H,WAVE,FLUX,EPS   ; IPRM
COMMON COM2,A,B,FH
COMMON COMXY,X,Y,zerr
X0=X
Y0=Y
IF (ZERR EQ 88) or (zerr eq 120) THEN GOTO,XOUT   ;<X>
     IF (ZERR GE 49) AND (ZERR LE 52) THEN BEGIN
          J=ZERR-49
          NA=(J+2)*3
          IF N_ELEMENTS(A) LT NA THEN A=[A,FLTARR(NA-N_ELEMENTS(A))]
          I=(J+1)*3
          ieff=xindex(wave,x0)     ;TABINV,WAVE,X0,IEFF
          A(I)=Y0          ;  AMPLITUDE OF LINE I
          A(I+1)=IEFF     ;  BIN NUMBER OF LINE I
          FH(J)=X0
          ENDIF
     IF (ZERR EQ 76) or (zerr eq 108) THEN BEGIN   ;<L>
          IF N_ELEMENTS(A) LT 18 THEN A=[A,FLTARR(18-N_ELEMENTS(A))]
          ieff=xindex(wave,x0)     ;TABINV,WAVE,X0,IEFF
          A(15)=Y0
          A(16)=IEFF
          FH(4)=X0
          ENDIF
     IF (ZERR EQ 70) or (zerr eq 102) THEN BEGIN      ; FIXED POSITION
          ieff=xindex(wave,x0)     ;TABINV,WAVE,X0,IEFF
          A(4)=-IEFF
          FH(0)=X0
          A(3)=Y0
          ENDIF
     IF (ZERR GE 53) AND (ZERR LE 57) THEN BEGIN
          I=ZERR-53
          FH(5+I*2)=X0  ; LOWER HALF OF FWHM
          ENDIF
; NEED TO GET upper half OF FWHM - CHARS ARE %^&*
     IF ZERR EQ 37 THEN FH(6)=X0     ;% 
     IF ZERR EQ 94 THEN FH(8)=X0     ;^
     IF ZERR EQ 38 THEN FH(10)=X0     ;&
     IF ZERR EQ 42 THEN FH(12)=X0    ;*
     IF ZERR EQ 40 THEN FH(14)=X0    ;(
     if (ZERR GE 97) AND (ZERR LE 101) then zerr=zerr-32
     IF (ZERR GE 65) AND (ZERR LE 68) THEN BEGIN  ;A,B,C,D 
          I=ZERR-65
          ieff=xindex(wave,x0)            ;TABINV,WAVE,X0,IEFF
          B(I)=FIX(IEFF+.5)
          IF I EQ 0 THEN A(0)=Y0
          ENDIF
     if zerr eq 69 then a(2)=y0                 ;E,e
TKP,1,X0,Y0
RETURN
;
XOUT:
i1=FIX(xindex(wave,x0)+0.5)
opstat,'mark other end of range to ignore'
BLOWUP,-1
i2=FIX(xindex(wave,x)+0.5)
opstat,' '
EPS(I1<I2:I2>i1)=-32000
BDATA,H,-1,WAVE,FLUX,EPS,BW,BF
TKP,7,BW,BF
RETURN
END
