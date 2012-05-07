;****************************************************************
PRO PSTAT,ILOOP,WAVE                      ; PRINT CURRENT STATUS (ICUR)
COMMON COM1,H,IK,IFT,NSM,C,NDAT,IFSM,kblo,h1
COMMON COMXY,X,Y,ZERR,RESETSCALE
common icdisk,icurdisk,icurdata,ismdata,objfile,stdfile,userdata,recno,linfile
COMMON VARS,VAR1,VAR2,VAR3,Vrot,bdf,psdel,prffit,vrot2
common radialvelocity,radvel,linid,orv,vc,rvflag
;
if !d.name eq 'TEK' then erase
zhelcor=''
PRINT,' '
IK=0
IFT=0
LOOP='ICUR'
IF ILOOP EQ 1 THEN LOOP=LOOP+' (FUN1)'
IF ILOOP EQ 2 THEN LOOP=LOOP+' (FUN2)'
ncam=h(3)
if ncam/10 eq 10 then ghrsgrat=ncam-100 else ghrsgrat=-1
imno=h(4)
if imno lt 0 then imno=imno+65536L    ;IUE image numbers >2^15
yr=h(12)
if yr ge 2000 then yr=yr-2000
if yr ge 1900 then yr=yr-1900
;
PRINT,' ** CURRENT STATUS, ',LOOP,' Version 3.0 ',SysTIME(0),' **'
if n_elements(objfile) ne 0 then $
   print,' Data file = ',objfile,'    Current data record = ',STRTRIM(recno,2)
IF (ncam LT 5) AND (H(34) LE 2) THEN $
      TDAT=STRMID('    LWP LWR SWP SWR ',ncam*4,4) $
      ELSE begin
         TDAT=STRTRIM(STRING(BYTE(H(100:139)>32)),2)    ;get title
         helcor=float(h(30))+h(31)/1000.                ;heliocentric correction
      zhelcor='   *  Heliocentric correction: '+string(helcor,'(F7.1)')+' km/s'
         endelse
IF ncam lt 5 then IF H(14) EQ 2 THEN PRINT,' Small Aperture' $
        ELSE PRINT,' Large Aperture'
H5=H(5)
IF (NDAT NE 1) OR (H(34) GT 2) THEN case 1 of
    (ncam LT 5) AND (H(34) LE 2): PRINT,TDAT,imno 
    ghrsgrat ne -1: print,' GHRS grating ',strtrim(ghrsgrat,2),'  ',tdat
    ncam eq 90: print,' SYNTHE model : ',tdat
    ELSE: PRINT,' ',TDAT,zhelcor
   endcase ELSE BEGIN   ;2 DATA SETS
   IF H(34) NE 2 THEN FCTN=0 ELSE FCTN=H(37)
   IF H(37) EQ 1 THEN H5=H(5)+H(205)
   WORD=STRMID('  ,  +  -  *  /  &  -% ',FCTN*3,5)
   IF H1(3) LT 5 THEN BEGIN
      if h1(4) lt 0 then imno1=h1(4)+65536L else imno1=h1(4)
      CAM2=STRMID('    LWP LWR SWP SWR ',H1(3)*4,4)
      PRINT,TDAT,imno,WORD,CAM2,imno1
      ENDIF ELSE BEGIN
      PRINT,TDAT,WORD,STRTRIM(STRING(BYTE(H1(100:139)>32)),2)
      ENDELSE
;
IF H(35) NE 0 THEN PRINT,' Second spectrum scaled by ',10.^(FLOAT(H(35))/100.)
IF H(39) NE 0 THEN PRINT,' Second spectrum rebinned and shifted by',H(39),' bins'
   ENDELSE
IF ncam LT 5 THEN GOTO,GO1
;
; PROCESS KPNO HEADER
PRINT,"$(' TIME=',I6,' DATE=',3I3,' UT:',I3,2(':',I2))",H5,H(10:11),yr,H(13:15)
IF ncam EQ 20 THEN GOTO,GO1
if total(h(40:48)) eq 0 then print,' No coordinates stored' else begin
   sra=string(h(40),'(I3)')+string(h(41),'(I3)')+ $
      string(float(h(42))/100.,'(F6.2)')
   sdec=string(h(43),'(I5)')+string(h(44),'(I3)')+ $
      string(float(h(45))/100.,'(F6.2)')
   sha=string(h(46),'(I3)')+string(h(47),'(I3)')+ $
      string(float(h(48))/100.,'(F6.2)')
   zpos=' RA,DEC='+sRA+sDEC
   if total(h(46:48)) ne 0 then zpos=zpos+' HA='+sHA
   PRINT,zpos
   endelse
;
GO1:
if n_elements(stdfile) ne 0 then print,' Current standard file = ',stdfile
print,' '
N=N_ELEMENTS(WAVE)-1
i1=0
i2=n
IF !X.crange(1) ne 0. THEN begin
   PRINT,' Plotted wavelength range:',!X.crange(0),' to ',!X.crange(1)
   i1=fix(xindex(wave,!x.crange(0))+0.5)>0
   i2=fix(xindex(wave,!x.crange(1))+0.5)<N
   if (i1 ge i2) then begin
      i1=0 & i2=n
      endif
   endif
disp=(wave(i2)-wave(i1))/float(i2-i1)
print,' Average dispersion (plotted range) = ',disp,' A/pixel.'
PRINT,' Useable wavelength range:',WAVE(0),' to ',WAVE(N)
IF (!Y.range(0) EQ 0.) AND (!Y.range(1) EQ 0.) THEN PRINT,' Y axis free. '
if resetscale eq 0 then print,' Y axis scaling fixed, range=',!y.crange
;
Z=' Plotting mode:'
case 1 of
   !P.PSYM EQ 10: Z=Z+' Histogram' 
   !P.PSYM EQ 0: Z=Z+' Connect the points'
   ELSE: Z=Z+' Unknown, !p.PSYM= '+strtrim(!p.PSYM,2)
   ENDcase
print,z
if bdf eq 3 then print,' Bad data flag enabled.' else  print,' Bad data flag disabled.' 
;
WL=X
FL=Y
PRINT,' Cursor position:',X,Y
IF VAR1 GT 0 THEN PRINT,' Current fits stored in FFIT.FIT' ELSE PRINT, $
     ' No fits stored this session. '
if !d.name eq 'PS' then print,' Currently plotting to Postscript printer'
if (!d.name eq 'X') or (!d.name eq 'TEK') then $
     print,' Currently plotting to screen'
IF VAR2 EQ 1 THEN PRINT,' A log file (-.LST) is being updated.' ELSE PRINT, $
     ' No log being maintained. '
IF rdbit(var3,0) EQ 0 THEN Z='enabled.' ELSE Z='disabled.'
PRINT,' Automatic axis scaling ',Z
IF rdbit(var3,2) EQ 0 THEN Z='enabled.' ELSE Z='disabled.'
PRINT,' FUN1 autoscaling ',Z
IF rdbit(var3,1) EQ 1 THEN PRINT,' Smoothing disabled for first data vector.'
;
if vrot gt 0. then begin
   print,' Data rotationally broadened by Vsin i =',vrot,' km/sec'
   endif
if (iloop gt 0) and (vrot2 gt 0.) then begin
   print,' Second spectrum rotationally broadened by Vsin i =',vrot2,' km/sec'
   endif
IF IFSM NE 0 THEN BEGIN            ;Fourier filtering
   ZF=' Fourier filtered:'
   TF=IFSM/10000   ;1 FOR COS, 2 FOR GAUSS, 0 FOR ZERO
   CUT=(IFSM-10000*TF)/5000   ;1 IF LOW FREQ NOT FILTERED
   case 1 of
      TF EQ 0: ZF=ZF+' low pass filter'
      TF EQ 1: ZF=ZF+' Cosine filter'
      TF EQ 2: ZF=ZF+' Gaussian filter'
      else: zf=zf
   endcase
   IF CUT EQ 1 THEN ZF=ZF+', low f unfiltered'
   LEN=FLOAT(IFSM-10000*TF-5000*CUT)/1000.
   if len gt 0.0 then begin
      PRINT,ZF
      IF TF EQ 0 THEN ZF='    High frequencies zeroed at ' ELSE $
         ZF='    Half power point at '
      zf=zf+strtrim(string(len,'(F6.3)'),1)+' of the Nyquist frequency'
      print,zf
      endif
   endif
;
IF (rdbit(var3,1) EQ 1) AND (NDAT EQ 1) THEN ZSMTH='Second scan ' ELSE ZSMTH=''
IF NSM GT 1 THEN BEGIN
   IF NSM LT 1000 THEN PRINT,ZSMTH,'smoothed over',FIX(NSM),' bins'
   IF NSM GE 10000 THEN BEGIN
      N=(NSM-10000.)/100.
      PRINT,ZSMTH,' Gaussian smoothed over',N,' Angstroms'
      ENDIF
   ENDIF
IF NSM LT 1 THEN BEGIN
   N=-NSM
   IF N LT 1000 THEN PRINT,ZSMTH,' Triangle smoothed over',FIX(N),' bins'
   IF N GT 10000 THEN BEGIN
      N=FIX((N-10000.)/100.)
      PRINT,ZSMTH,'Rotated by',N,' Km/S'
      ENDIF
   ENDIF
IF H(91) GE 1 THEN begin
   tabs=['?','SAVMAT','SEATON','NANDY','ORION','SMC','?']
   tab=(var3 and 7*256)/256
   PRINT,'Dereddened by E(B-V)=',-FLOAT(H(92))/1000.,'; reddening table=',tabs(tab<6)
   endif
if (ncam/10 eq 10) and (h(2) ge 1001) then begin
   nlg=h(2)-1000
   print,' Spectrum deconvolved with',nlg,' iterations of LUCY_GUESS'
   endif
IF H(2) EQ 999 THEN BEGIN
   NGS=FLOAT(H(51))+FLOAT(H(52))/100.
PRINT,'HI-RES data degraded by',H(53),' bins and Gsmoothed over',NGS,' Angstroms'
   ENDIF
if rdbit(var3,4) eq 1 then print,' Plot captioning turned off'
if rdbit(var3,5) eq 1 then print,' Using default continuum fit'
IF PSDEL EQ 0 THEN PRINT,' Plot files automatically deleted after printing' $
   else print,' Plot files not deleted after printing'
if rvflag then zrad=' * Velocities updated from header' else zrad=''
IF RADVEL(0) ne 0. then print,' Line ID radial velocity:',radvel,zrad
RETURN
END
