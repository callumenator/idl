;***********************************************************************
PRO PLIHD,H                    ; PLOT HEADER INFORMATION IN ICUR
; MODIFIED 10/29/82 TO HANDLE DATA FROM FUN1
; MODIFIED 11/11/82 AND 1/31/83 TO HANDLE KPNO HEADERS
; CHANGES 3/11/83 FOR NEG ISM
; LAST UPDATE 8/11/86
; VERSION 2: WRITES !P.SUBTITLE
COMMON COM1,H0,IK,IFT,NSM,C,NDAT,IFSM
nosubt=0
Z=''
!p.subtitle=''
IF N_ELEMENTS(H) LT 100 THEN RETURN
iiue=0
iopt=0
ihrs=0
case 1 of
   h(3) lt 5: iiue=1 
   h(3)/10 eq 10: ihrs=1 
   else: iopt=1
   endcase
NAX=rdbit(var3,1)    ;GET BIT 1 OF VAR3
IF (NAX EQ 1) AND ((H(34) EQ 2) OR (NDAT EQ 1)) THEN ZSMTH='Obs_2 ' $
     ELSE ZSMTH=''
H5=H(5)
if h5 lt 0 then begin
   isec='m ' & h5=-h5
   endif else isec='s '
;
IF iiue THEN GOTO,GO1
;
; PROCESS KPNO HEADER
if h(5)+total(h(10:15))+total(h(40:45)) eq 0 then nosubt=1
Z=STRTRIM(STRING(H5),2)+isec+STRTRIM(STRING(H(10)),2)+'/'
Z=Z+STRTRIM(STRING(H(11)),2)+'/'+STRTRIM(STRING(H(12)),2)+' '
Z=Z+STRTRIM(STRING(H(13)),2)+':'+STRTRIM(STRING(H(14)),2)+':'
Z=Z+STRING(FORMAT='(I2)',H(15))
IF H(3) EQ 20 THEN GOTO,GO1
RA=FLOAT(H(40))*15.+FLOAT(H(41))/4.+FLOAT(H(42))/24000.
ds=FLOAT(H(45))/100.
dec=dmstodeg(h(43),h(44),ds)
;DEC=FLOAT(H(43))+FLOAT(H(44))/60.+FLOAT(H(45))/360000.
HA=FLOAT(H(46))*15.+FLOAT(H(47))/4.+FLOAT(H(48))/24000.    ;DEGREES
HA=HA/15.                    ;CONVERT TO HOURS
IF (RA EQ 0.) AND (DEC EQ 0.) THEN POS=0 ELSE POS=1
IF HA LT -12. THEN HA=24.+HA
IF POS THEN Z=Z+' !7a,d!6='+STRING(format='(F7.3)',RA)+','+STRING(format='(F7.3)',DEC)
if not ihrs then begin
   if ha lt 0 then fmt='(F6.2)' else fmt='(F5.2)'
   zair=' HA='+STRING(format=fmt,HA)
   IF NOT POS THEN ZAIR=''
   if (h(34) lt 2) then z=z+zair         ;only print for single spectrum
   endif
;
GO1:
IF (H(34) EQ 2) AND (H(35) NE 0) THEN BEGIN          ;scaling
   S=10.^(FLOAT(H(35))/100.)
   zlg=''
   if (s gt 1000.) or (s lt .001) then begin
      zlg='10^' & s=alog10(s)
      endif
   CASE 1 OF
      S LT  1.: F='(F6.4)' 
      S GT 10.: F='(F6.2)'
      ELSE:     F='(F6.3)' 
      ENDCASE
   Z=Z+' Obs_2 scaled by '+zlg+STRING(FORMAT=F,S)
   ENDIF
IF H(91) GE 1 THEN BEGIN
   Z=Z+' E(B-V)='+STRING(FORMAT='(F5.2)',FLOAT(H(92))/1000.)
   ENDIF
IF ((NDAT EQ 0) AND (NAX EQ 1)) OR (NSM EQ 1) THEN GOTO,NOSM
CASE 1 OF
   ABS(NSM) LT 1000: Z=Z+' '+ZSMTH+'NSM= '+STRTRIM(STRING(FIX(NSM)),2)
   NSM GE 10000: BEGIN
      N=(NSM-10000.)/100.
      Z=Z+' '+ZSMTH+'GSM= '+STRING(FORMAT='(F5.2)',N)+' A'
      END
   ELSE: BEGIN    ;NSM<-1000 -> ROTATION
      N=FIX((-NSM-10000.)/100.)
      Z=Z+' '+ZSMTH+'Rot= '+STRTRIM(STRING(N),2)+' Km/S'
      END
   ENDCASE
;
NOSM:
IF H(2) EQ 999 THEN BEGIN
   NGS=FLOAT(H(51))+FLOAT(H(52))/100.
;   PRINT,'HI-RES data degraded by',H(53),' bins,'
;   PRINT,'and Gsmoothed over',NGS,' Angstroms'
   ENDIF
if nosubt then z=''
!P.SUBTITLE=Z
RETURN
END
