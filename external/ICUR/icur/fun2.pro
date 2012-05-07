;*************************************************************************
PRO FUN2,WAVE,FLUX,EPS,BADW,BADF,F1   ; ICUR LOOP 3
;vax version 1.0 8/19/86
;  CURSOR COMMANDS:
; A:  PLOT ALL DATA                       a:  ADD A LINE TO THE DATA
; B:  BLOWUP PLOT                         b:  REDEFINE BAD DATA
; C:  COMPUTE CENTROID OF FEATURE         c:  COADD BINS
; D:  INDICATE BAD DATA (SAME AS R)       d:  error analysis
; E:  GET EQUIVALENT WIDTHS               e:  RESTORE EPS VECTOR
; F:  ENTER ICFIT TO FIT LINES            f:  LINE IDENTIFICATIONS
; G:  FOLD DATA                           g:  MULTIPLE SUM/CONCATENATION
; H:                                      h:  update current record
; I:  INITIALIZE SCREEN                   i:  LINEAR INTERPOLATION ,X ONLY 
; J:  JUMP IN X DIRECTION;                j:  LINEAR INTERP W BOTH X,Y GIVEN
; K:  SAVE DATA ON GENERIC DISK FILES     k:  PERMANENTLY SMOOTH FLUX 
; L:  LOCATE WAVELENGTH USING CURSOR
; M:  PLOT MEAN BETWEEN LIMITS
; N:  RESET !Y.RANGE TO 0.
; O:  OVERPLOT FOLDED DATA                o:  OVERWRITE INPUT W/CURRENT VECTORS
; P:  TOGGLE !P.PSYM 0<->10               p:  PRINT CURRENT STATUS
; Q:  QUIT
; R:  REPLOT, WITH CURRENT NSM            r:  ROTATIONAL BROADENING
; S:  SMOOTH DATA                         s:  GAUSSIAN SMOOTHING
; T:  SUM TOTAL FLUX                      t:  CHANGE TITLE
; U:  FLUX HIGH RESOLUTION DATA           u:  UNREDDEN DATA
; V:  LOCATE AND EXPAND PLOT              v:  CHANGE WAVE VECTOR TO VELOCITY
; W:  RETURN WAVELENGTH AND FLUX          w:  RESTORE WAVE VECTOR
; X:  EXPAND IN X DIRECTION               x:  RESET EPSILON VALUE TO -1111
; Y:  EXPAND IN Y DIRECTION               y:  CHANGE FLUX VECTOR UNITS
; Z:  STOP
; 0:  DRAW ZERO LINE                      1:  DRAW LINE AT UNIT VALUE
; 2:  HALVE F VECTOR
; +-*/&%:  AS IN FUNCTION
; ?: LIST CURSOR COMMANDS
COMMON COM1,HD,IK,IFT,NSM,C,NDAT,IFSM,KBLO
COMMON COMXY,X,Y,ZERR,resetsscale,lu3
common vars,var1,var2,var3,var4,bdf,psdel
COMMON ICURUNITS,XUNITS,YUNITS,TITLE,C1,C2,C3
common icdisk,icurdisk,icurdata,ismdata,objfile,stdfile,userdata,recno
RESET=0
F=FLUX
W=WAVE
E=EPS
H=HD
NDAT=0
IK=0
IFT=0
IFLX=0
IWAV=0
e1=0
PRINT,' *** FUN2 ***'
;
BDATA,h,-1,W,F,E,BADW,BADF
GO1:   ; LABEL FOR LOOP START
hc=hd
BLOWUP,-1
IF (zerr eq 26) or (ZERR EQ 81) or (ZERR eq 113) THEN GOTO,GO2    ;<Q>
Z=WHERE(ZERR EQ KBLO,kz) & IF kz GT 0 THEN BLOWUP,ZERR   ;(>,<,^,6,[)
IF ZERR EQ 63 THEN icur_help,3         ;<?>
IF ZERR EQ 65 THEN PLDATA,-2,W,F   ;<A>
IF ZERR EQ 66 THEN BLOWUP,0        ;<B>
IF ZERR EQ 67 THEN FTOT,2,W,F      ;<C>
IF ZERR EQ 68 THEN pldata,0,w,f,badw,badf     ;<D>
IF ZERR EQ 69 THEN IFEAT,W,F,BADF   ;<E>
IF ZERR EQ 70 THEN ICFITmp,W,F,E     ;<F>
IF ZERR EQ 71 THEN FOLD,0,X,W,F,F1  ;<G>
IF ZERR EQ 73 THEN PLDATA,-1,0.,0. ;<I>
IF ZERR EQ 74 THEN jump            ;<J>
IF ZERR EQ 75 THEN KDAT,objfile,HC,W,F,E     ;<K>
IF ZERR EQ 76 THEN LOCATE,0,W,F    ;<L>
IF ZERR EQ 77 THEN FTOT,1,W,F      ;<M>
IF ZERR EQ 78 THEN !y.range(*)=0.  ;<N>
IF (ZERR EQ 79) AND (NDAT EQ 1) THEN PLDATA,1,W,F1,PCOL=C2  ;<O>
IF ZERR EQ 80 THEN !P.PSYM=((!P.PSYM/10+1) MOD 2)*10  ;<P>
IF ZERR EQ 82 THEN PLDATA,0,W,F    ;<R>
IF ZERR EQ 83 THEN ROTVEL,0,W      ;<S>
IF ZERR EQ 84 THEN FTOT,0,W,F      ;<T>
IF ZERR EQ 85 THEN RECALH,HD,W,F,E ;<U>
IF ZERR EQ 86 THEN LOCATE,1,W,F    ;<V>
IF ZERR EQ 87 THEN WAVEL           ;<W>
IF ZERR EQ 88 THEN BLOWUP,1        ;<X>
IF ZERR EQ 89 THEN BLOWUP,2        ;<Y>
IF ZERR EQ 90 THEN STOP,'    FUN2 STOP '  ;<Z>
IF (ZERR GE 37) AND (ZERR LT 48) THEN BEGIN  ;<+-*/&> 
     MANIP,F,F1,TF,E,e1,badf
     F=TF
     ENDIF
IF ZERR EQ 48 THEN DRLIN,0.        ;<0>
IF ZERR EQ 49 THEN DRLIN,1.        ;<1>
IF ZERR EQ 50 THEN F=F/2.          ;<2>
IF ZERR EQ 97 THEN ADDLINE,W,F     ;<a>
; ZERR EQ 98 <b> moved down
IF ZERR EQ 99 THEN begin           ;<c>
   COADD,WAVE,F,E   
   if n_elements(lu3) eq 1 then begin
      printf,lu3,'-4' & printf,lu3,hd(53),' bins coadded'
      endif
   zerr=98
   endif
IF ZERR EQ 100 THEN IC_ERR_ANAL,hd,wave,flux,eps      ;<d>  analyze errors
IF ZERR EQ 101 THEN E=EPS      ;<e>
IF ZERR EQ 102 THEN FINDLIN,W  ;<f>
IF ZERR EQ 103 THEN MULTSUM,W,F,E,BADW,BADF   ;<g>
IF ZERR EQ 104 THEN KDAT,objfile,HC,W,F,E,recno     ;<h>  update current record
IF ZERR EQ 105 THEN FTOT,3,W,F ;<i>
IF ZERR EQ 106 THEN FTOT,4,W,F ;<j>
IF ZERR EQ 107 THEN FOLD,-1,X,W,F,F1  ;<k>
if zerr eq 108 then ldat,objfile         ;<l>
if zerr eq 109 then begin                ;<m>
   r2=0 & fl2='0'
   read,' SPECMERGE: enter record and file name of second spectrum: ',r2,fl2
   if r2 lt 0 then r2=recno+1
   if strupcase(objfile) eq 'NOFILE' then begin
      read,' enter name of data file',objfile
      endif else fl1=objfile
   if (fl2 eq '') or (fl2 eq ' ') then fl2=objfile
   case 1 of
      ifstring(fl2) eq 1: if strtrim(fl2,2) eq '' then fl2=fl1
      else: if fl2 lt 0 then fl2=fl1
      endcase
   if (recno eq r2) and (fl1 eq fl2) then print,' WARNING: you are coadding the same data'
   specmerge,w,f,e,recno,r2,fl1,fl2    ;overwrite input vector
   zerr=111
   bdf1=bdf
   BDATA,h,-1,W,F,E,BADW,BADF,bdf      ;set up bad data vector
   bdf=bdf1
   endif
IF ZERR EQ 111 THEN OVERWRT,2,FLUX,EPS,WAVE,F,E,W,RESET   ;<o>
IF ZERR EQ 112 THEN PSTAT,2,W               ;<p>
IF ZERR EQ 114 THEN ROTVEL,1,WAVE           ;<r>
IF ZERR EQ 115 THEN ROTVEL,-1,WAVE          ;<s>
IF ZERR EQ 116 THEN FUN3,0,0,0,H,HD         ;<t>
IF ZERR EQ 117 THEN ADDRED,0,HD,W,F         ;<u>
IF ZERR EQ 118 THEN RWAVE,W,F               ;<v>
IF ZERR EQ 119 THEN BEGIN                   ;<w>
   FUN3,-1,IWAV,0,WAVE,W
   NSM=1
   ENDIF
IF ZERR EQ 120 THEN BDATA,h,X,W,F,E,BADW,BADF ;<x>
IF ZERR EQ 121 THEN FUN3,1,IFLX,WAVE,FLUX,F ;<y>
IF ZERR EQ 122 THEN BADF=BADF*0.            ;<z>
IF ZERR EQ 98 THEN BDATA,h,-1,W,F,E,BADW,BADF,bdf ;<b>
IF ZERR EQ 64 THEN IBIT,var3,0,-1           ;<@>
IF ZERR EQ 35 THEN IBIT,var3,1,-1           ;<#>
if (zerr lt 26) or (zerr gt 122) then zrecover
GOTO,GO1
GO2:
IF RESET EQ 0 THEN HD=H
ZERR=112   ;<p>
RETURN
END
