;**********************************************************************
PRO ICUR,HH,WAVE,FLUX,EPS,helpme=helpme,smallw=smallw          ; ICUR.PRO
; VAX VERSION 1.0 8/19/86
;     version 2.0 8/17/87
; COPIED FROM PDP VERSION 7.3
;  CURSOR COMMANDS:
; A:  PLOT ALL DATA             a:  ADD A LINE TO THE DATA
; B:  BLOW UP PLOT              b:  FLAG BAD DATA  ;toggle to oplot Xs
; C:  COMPUTE CENTROID          c:  COADD BINS
; D:  PLOT W/BAD DATA           d:  IUE HI->LO, /KPNO ND function, deconv GHRS
; E:  GET EQUIVALENT WIDTHS     e:  FFT smoothing
; F:  FIT DATA                  f:  LIST LINES FROM LINELIST
; G:  RETRIEVE DATA FROM DISK   g:  RETRIEVE DATA FROM STANDARD FILE
; H:  restore saved vectors     h:  FFT smooth second spectrum
; I:  INITIALIZE SCREEN         i:  PERFORM LINEAR INTERPOLATION
; J:  JUMP X POSITION           j:  LINEAR INTERPOLATION WITH Y SPECIFIED
; K:  SAVE DATA TO DISK FILES   k:  AUTO CORRELATION
; L:  LOCATE WAVELENGTH         l:  LIST CONTENTS OF GENERIC FILE
; M:  PLOT MEAN and compute s/n m:  CALL FUN2
; N:  RESET !Y.RANGE TO 0.      n:  normalize data
; O:  OVERPLOT SECOND spectrum  o:  reset NDAT=0
; P:  toggle !P.PSYM  0<->10    p:  print current status
; Q:  QUIT                      q:  quit
; R:  Revise name of OBJFILE    r:  ROTATIONALLY BROADEN DATA
; S:  SMOOTH DATA               s:  SMOOTH WITH A GAUSSIAN
; T:  SUM TOTAL FLUX            t:  OVERPLOT BLACK BODY
; U:  CALL FUN1                 u:  UNREDDEN DATA
; V:  LOCATE AND plot           v:  FWHM
; W:  CURSOR POSITION           w:  CWHERE
; X:  EXPAND IN X DIRECTION     x:  RESET EPSILON VECTOR TO -1111
; Y:  EXPAND IN Y DIRECTION     y:  Filter spectrum
; Z:  PAUSE                     z:  ZERO BADF VECTOR
; 0:  DRAW ZERO LEVEL           1:  draw line at 1
; 2:  oplot +/- 1 sigma envelope 3: call specmerge
; ESC:  READ NEW DATA FROM GENERIC DISK FILE
; #:  smooth second vector      $: call USERPRO
; ?:  LIST CURSOR COMMANDS      
; [:  EXPAND PLOT BY 2 times    -: disable autoscaling in FUN1
; ;:  plot next record          !: toggle PLOT device 'X'<-> 'PS'
; ` toggle big to little TVwindow
; Flag VARIABLES: VAR1 - INCREMENTED BY ICFIT
;                 VAR2 - 1 TO LIST MEASUREMENTS
;                 VAR3 - bit 0=1 TO FORGO AUTOSCALING
;                        bit 1=1 to smooth only second spectrum
;                        bit 2=1 to turn off autoscaling in FUN1
;                        bit 3=1 to set \YNOZERO in plot
;                        bit 4=1 to turn off all legends and captions in plot
;                        bit 5=1 if ysing default yfit for % command
;                 bdf  - bad data flag
; cursor timing problem solved 7/10/87
;
COMMON COM1,H,IK,IFT,NSM,C,NDAT,IFSM,KBLO,H1,ipdv,ihcdev
common radialvelocity,radvel,linid,orv,vc,rvflag
COMMON COMXY,XCUR,YCUR,ZERR,RESETSCALE,lu3,ieb
COMMON VARS,VAR1,VAR2,VAR3,Vrot,bdf,psdel,prffit,vrot2
common icdisk,icurdisk,icurdata,ismdata,objfile,stdfile,userdata,recno,linfile
common icurunits,xunits,yunits,title,c1,c2,c3,ch,c4,c5,c6,c7,c8,c9
common custompars,dw,lp,flatback,autofft,eafudge,NREC2,ldp
;
if n_params(0) lt 3 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* ICUR - interactive cursor-controlled spectral analysis package'
   print,'* calling sequence: ICUR,H,W,F (,E) '
   print,'* '
   print,'* Use of GOICUR as a driver for ICUR is recommended'
   print,' '
   return
   end   
;
if (!d.n_colors ge 256) then hexcol=1 else hexcol=0
if n_elements(ipdv) eq 0 then ipdv=!d.name
zcam='    LWP LWR SWP SWR '
zkey=[26,27,32+INDGEN(7),41,42,45,48,49,50,51,54,58+indgen(34), $
      94+indgen(29),124,126]
;zkey=[26,27,32,33,35,36,38,41,45,48,49,54,58-64,65-90,91,94,95,96,97-122,126]
;unused: 13,28-31,39,40,43,44,46,47,52,53,55-57,92,93,123,125
;        CR        '  (  +  ,  .  /  45  789  \   ]  {}
;28-31 nonprinting, 32=space
;
if strupcase(!d.name) eq 'X' or strupcase(!d.name) eq 'WIN' then iscr=1 else iscr=0
iscr0=iscr
flevel=0                                ;used in findlin
linid=1                                 ;do not print findlin line IDs on plot
longid=1                                ; set to 0 to skip lambdas
rvflag=1                                ;adjust RADVEL if specified in header
radvel=0.
nonorm=0                                ;Y units are per Angstrom
keeprv=0                                ;if set, do not reset RV each time
ieb=0                                   ;plot error bars
oldicfit=0                              ;set to call ICFIT2
pcsz=!p.charsize
if n_elements(autofft) eq 0 then autofft=0     ;set to automate FFT smoothing
if n_elements(xunits) eq 0 then xunits=''
if n_elements(yunits) eq 0 then yunits=''
customshow=0
VC=2.99792E5                                   ;speed of light
vp0=[.25,.95,.2,.9]
vp1=[.15,.95,.15,.95]
vph=[.2,.9,.2,.9]
vp=vp0
npdeg=3       ;polynomial degree in % command
ibit,var3,5,0
defyfit=0
yfit0=0
ldp0=[-1.0,-0.6,-0.2,0.0,0.3,0.6,1.0]    ;values of limb-darkening epsilon
ldv0=[1.31,1.27,1.24,1.21,1.18,1.13,1.05]     ;radial velocity scaling
ldeps=0.6 & ldp=1.13                          ;photosphere
if not monvect(wave) then print,' *** WARNING: wavelength vector is not monotonic ***'
if n_elements(eps) eq 0 then eps=100
if n_elements(hh) eq 0 then hh=0
wsave=wave & fsave=flux & esave=eps
vrot=0.
if n_elements(c1) eq 0 then begin
   if hexcol then c1='ffffff'x else c1=255
   endif
if n_elements(c2) eq 0 then begin
   if hexcol then c2='ffffff'x else c2=255
   endif
if n_elements(c3) eq 0 then begin
   if hexcol then c3='ffffff'x else c3=255
   endif
;if hexcol then begin
;   c4='00ffff'x & c5='00ff00'x & c6='ff7f00'x
;   c7='ff007f'x & c8='ffff00'x & c9='007fff'x
;   endif else begin
;      c4=4 & c5=5 & c6=6 & c7=7 & c8=1 & c9=9
;   endelse
;
if n_elements(resetscale) eq 0 then resetscale=0
if n_elements(ch) eq 0 then ch=4           ;for hard copy plots (= command)
if n_elements(hh) lt 159 then begin            ;check header
   h=intarr(200)
   h(0)=hh
   endif else h=hh
c1save=c1
!p.color=c1
!p.noclip=0
ps=!p.psym
if n_elements(var2) eq 0 then var2=0
if n_elements(vrot2) eq 0 then vrot2=0
if n_elements(psdel) eq 0 then psdel=0
;psdel=0                   ;automatically delete IDL.PS files after plotting
xmin=!x.range(0) & xmax=!x.range(1) & ymin=!y.range(0) & ymax=!y.range(1)
if n_elements(recno) eq 0 then recno=-9
irecno=-1
KBLO=[54,60,62,91,94]   ;6,<,>,[,^
IF H(34) NE 2 THEN BEGIN
   H(35)=0 & H(39)=0
   ENDIF
H0=H            ;initial header
NDAT=0
IFSM=0
nsm=1 & c=FLTARR(1)+1.
NCAM=H(3)
if ncam eq 800 then nonorm=1
smlen=49                       ;used by FILTSPEC
H(61)=0
case 1 of
   h(33) eq 30:
   h(33) eq 40:
   else: ieb=0
   endcase
rv=float(h(28))+h(29)/1000.
helcor=float(h(30))+h(31)/1000.
if rvflag then radvel=rv-helcor
S=n_elements(WAVE)
VAR1=0 ; VAR 1 INCREMENTED BY 1 EACH TIME ICFIT IS ENTERED
if n_elements(lu3) eq 0 then get_lun,lu3
if lu3 eq -1 then get_lun,lu3
if n_elements(zerr) eq 0 then zerr=32
CLOSE,lu3
FNAME='NOFILE'
nulldev='NL0' & if !version.os eq 'vms' then nulldev=nulldev+':'
OPENW,lu3,nulldev
;
!p.title=get_title(h,inm)
pt0=!p.title
;
if iscr then begin
   if keyword_set(smallw) then $
      window,0,xsize=640,ysize=512,title='ICUR',retain=2 else $
      window,0,xsize=1000,ysize=750,title='ICUR',retain=2
   !p.position=[vp(0),vp(2),vp(1),vp(3)]
   tvsize=0
   endif else tvsize=-1
PLDATA,-2,WAVE,FLUX,eps=eps,EBCOL=C8                    ;initial plot
BDATA,h,-1,WAVE,FLUX,EPS,BADW,BADF 
if h(33) eq 30 then bdf=0 else bdf=1   ;overplot bad data flags?
if bdf ne 0 then TKP,7,BADW,BADF
XCUR=mean(!x.crange) & YCUR=mean(!y.crange)     ;initial pos in data coords
;
;***************************************************
;
xera=!d.x_ch_size*12
eras=intarr(xera,!d.y_ch_size+2)
cmd=''
fstatus='  Done'
;
GO1:   ; LABEL FOR LOOP START
t=fstat(lu3)
if t.open ne 1 then OPENW,lu3,nulldev
zk=where(zerr eq zkey,ck) & if ck eq 0 then fstatus='  Invalid'
!p.color=c1
if iscr then wshow
if iscr and (strlen(cmd) gt 0) then opstat,fstatus ;begin
fstatus='  Done' 
;
; customshow : customize
;
case customshow of
   1: begin           ;AUTO-SMOOTH, AND DO NOT ID LINES TO SCREEN
      rvflag=1  
      autofft=-abs(autofft)
      if autofft eq 0 then autofft=-1
      end
   2: begin           ;AUTO-SMOOTH
      autofft=-abs(autofft)
      if autofft eq 0 then autofft=-1
      end
   else:
   endcase
;
if rvflag then radvel=rv+helcor
BLOWUP,-1   ; CURSOR CALL
if zerr eq 32 then zerr=87           ; space = W
if zerr eq 33 then cmd='Command: !!' else cmd='Command: '+string(byte(zerr))
status='  Working'
if iscr and (strlen(cmd) gt 0) then begin
   tv,eras,0,0 & xyouts,0,2,cmd,/dev
   opstat,status
   endif
if zerr eq 33 then begin                     ;<!>
   if !d.name eq ipdv then begin
      sp,ihcdev
      iscr=0
      print,' plot data being output to device ',ihcdev
      c1=!p.color
      !p.position=[vph(0),vph(2),vph(1),vph(3)]
      endif else begin
      print,' plot data being output to device ',ipdv
      iscr=iscr0
      lplt,ipdv,nodelete=rdbit(psdel,0),noplot=rdbit(psdel,1)   ;!
      c1=c1save
      !p.position=[vp(0),vp(2),vp(1),vp(3)]
      endelse
   endif
IF (ZERR EQ 81) OR (ZERR EQ 26) OR (ZERR EQ 113) THEN GOTO,GO2    ;<Q,q,^Z>
if (zerr eq 95) then begin                             ;<_> toggle 0<->1
   resetscale=(resetscale+1) mod 2
   if resetscale eq 0 then !y.range=!y.crange
   ENDIF
if (zerr eq 96) and (strupcase(!d.name) eq 'X' ) then begin        ;<`>
; toggle window size
   case 1 of
      tvsize eq 0: begin
         window,0,xsize=1000,ysize=750,title='ICUR'
         vp=vp1
         end
      tvsize eq 1: begin
         window,0,xsize=640,ysize=512,title='ICUR'
         vp=vp0
         end
      else:
      endcase
   !p.position=[vp(0),vp(2),vp(1),vp(3)]
   tvsize=(tvsize+1) mod 2              ;toggle 0<->1
   zerr=68
   endif
IF (ZERR EQ 27) OR (ZERR EQ 126) THEN begin            ;<ESC or ~>
   gnd,h,wave,flux,eps,0,recno,badw,badf,reset=resetscale   ;get new data
   pt0=!p.title
   helcor=float(h(30))+h(31)/1000.
   if not keyword_set(keeprv) then rv=float(h(28))+h(29)/1000.
   zerr=68 
   if customshow ge 1 then zerr=101     ;smooth first
   if not monvect(wave) then $
      print,' *** WARNING: wavelength vector is not monotonic ***'
   wsave=wave & fsave=flux & esave=eps
   if (!x.range(0) ne 0.) and (!x.range(1) ne 0.) then begin
      if (wave(0) gt !x.crange(1)) or (max(wave) lt !x.crange(0)) then setxy
      endif
   if h(3) eq 800 then nonorm=1 else nonorm=0
   endif
if (zerr eq 58) OR (zerr eq 59) then begin                 ;<:,;> next record
   if recno ge 0 then begin
      if zerr eq 59 then recno=recno+1 else recno=(recno-1)>0
      gnd,h,wave,flux,eps,1,recno,badw,badf,reset=resetscale
      pt0=!p.title
      if n_elements(h) eq 1 then begin
         print,' Use <ESC> to call up new data' 
         h=intarr(100)-1
         endif else begin
         helcor=float(h(30))+h(31)/1000.
         if not keyword_set(keeprv) then rv=float(h(28))+h(29)/1000.
         zerr=68 
         if customshow ge 1 then zerr=101     ;smooth first
         if not monvect(wave) then $
            print,' *** WARNING: wavelength vector is not monotonic ***'
         wsave=wave & fsave=flux & esave=eps
         if h(3) eq 800 then nonorm=1 else nonorm=0
         endelse
      if (!x.range(0) ne 0.) and (!x.range(1) ne 0.) then begin
         if (wave(0) gt !x.crange(1)) or (max(wave) lt !x.crange(0)) then setxy
         endif
      endif else print,' Use <ESC> to call up new data' 
   endif
if zerr eq 51 then begin                     ;<2>  merge 2 spectra
   nsp=get_nspec(objfile)
   if recno le nsp-2 then begin
      specmerge,wave,flux,eps,recno,recno+1,objfile
      if customshow ge 1 then zerr=101 else zerr=68    ;smooth first
      if not monvect(wave) then $
            print,' *** WARNING: wavelength vector is not monotonic ***'
      wsave=wave & fsave=flux & esave=eps
      if (!x.range(0) ne 0.) and (!x.range(1) ne 0.) then begin
         if (wave(0) gt !x.crange(1)) or (max(wave) lt !x.crange(0)) then setxy
         endif
      endif   ;valid record number
   endif                                    ;specmerge(2)
Z=WHERE(ZERR EQ KBLO,COUNT) &  IF COUNT EQ 1 THEN BLOWUP,ZERR   ;(>,<,^,6,[)
if zerr eq 41 then begin
   ibit,var3,4,-1                   ;<)>  turn captioning on/off
   if !p.charsize eq pcsz then !p.charsize=(pcsz>2.0) else !p.charsize=pcsz
   endif
IF ZERR EQ 61 THEN BEGIN
   !p.position=[vph(0),vph(2),vph(1),vph(3)]
   PLDATA,10,WAVE,FLUX,BADW,BADF,pcol=ch,psdel=psdel,eps=eps,EBCOL=C8 ;<=>
   !p.position=[vp(0),vp(2),vp(1),vp(3)]
   ENDIF
IF ZERR EQ 63 THEN icur_help,0                    ;<?>
IF ZERR EQ 64 THEN begin                  ;<@> toggle axis rounding
   v=!y.style & IBIT,v,0,-1 & !y.style=v
   v=!x.style & IBIT,v,0,-1 & !x.style=v
   ZERR=68
   endif
if ZERR eq 38 then BEGIN                      ;<&>
   CASE 1 OF
      var2 eq 0: begin    ;no current log file
         close,3
         IF STRUPCASE(FNAME) EQ 'NOFILE' THEN BEGIN    ;initialize file
            s=systime(0)
            fname='icur_'+strmid(s,4,3)+strtrim(strmid(s,8,2),2)+'.log'
            openw,lu3,fname,/get_lun
            print,' Logging enabled to file ',fname
            PRINTF,lu3,'-1' & PRINTF,lu3,' Listing of ICUR measurements'
            PRINTF,lu3,' 0'
            IF NCAM LE 4 THEN begin
               CAMERA=STRMID(ZCAM,H(3)*4,4)
               PRINTF,lu3,NCAM,inm,' IUE camera=',CAMERA ,' IMAGE=',inm
               endif ELSE PRINTF,lu3,NCAM,H(4),' : ',string(byte(h(100:159)>32b))
            endif else begin
               openu,lu3,fname
               print,' Logging resumed to file ',fname
               endelse
         end
      var2 eq 1: begin    ; current log file
         close,lu3 & openw,lu3,nulldev
         print,' Logging turned off'
         end
      else: var2=1
      endcase
   var2=((var2+1) mod 2)
   endif
IF ZERR EQ 65 THEN PLDATA,-2,WAVE,FLUX,pcol=c1,eps=eps        ;<A> 
IF ZERR EQ 66 THEN BLOWUP,0                           ;<B>
IF ZERR EQ 67 THEN FTOT,2,WAVE,FLUX                   ;<C>
IF ZERR EQ 69 THEN IFEAT,WAVE,FLUX,EPS,nonorm=nonorm  ;<E>
IF ZERR EQ 70 THEN begin                              ;<F>   Fit data
   ldp=lint(ldv0,xindex(ldp0,ldeps))       ; update limb darkening RV term
   if oldicfit then ICFIT2,WAVE,FLUX,EPS,psdel=psdel $      ;<F> 
      else ICFITmp,WAVE,FLUX,EPS,psdel=psdel          ;use MPCURVEFIT
   endif
IF (ZERR EQ 71) OR (ZERR EQ 103) THEN BEGIN   ;<G,g>, grab second data set
pt0=!p.title
; GET DATA FROM STANDARD FILE (103) OR Object FILE (71)
   case 1 of
      ZERR EQ 103: begin                  ;<g>
         if strupcase(stdfile) eq 'NOFILE' then begin
            STDFILE=' '
            read,' Standard file currently undefined. Please enter name: ',stdfile
            endif
         searchdir,stdfile,'.icd'
         if strupcase(stdfile) eq 'NOFILE' then goto,go1
         idt1=stdfile & std=1
         end
      zerr eq 71: begin                        ;<G>
         std=0
         if strupcase(objfile) eq 'NOFILE' then begin
            OBJFILE=' '
            read,' Object file currently undefined. Please enter name',objfile
            endif
         searchdir,objfile,'.icd'
         if strupcase(objfile) eq 'NOFILE' then goto,go1
         idt1=objfile
         end
      endcase
   nrec2=0
   READ,' Enter record number: ',nrec2
   nrec2=nrec2(0)
   IF NREC2 EQ -99 THEN goto,go1            ;abort on -99
   if nrec2 lt 0 then twostar,-1,-1,w1,f1,H1,dm=-99.,/noplot else $
         GND,H1,W1,F1,E1,1,NREC2,std=std
   ZERR=71
   IF n_elements(h1) gt 1 THEN BEGIN
      NDAT=1
      PRINTF,lu3,'-7'
      IF H1(3) LE 4 THEN BEGIN
         if h1(4) lt 0 then inm=h1(4)+65536L else inm=h1(4)
         CAMERA=STRMID(ZCAM,H1(3)*4,4)
         PRINTF,lu3,H1(3),H1(4),' IUE camera=',CAMERA ,' IMAGE=',H1(4)
         t=strtrim(byte(h1(100:159)>32b),2)
         k=where(byte(t) gt 126b,count)
         if (count gt 1) or (strlen(t) eq 0) then begin      ;no title
            H1(100:159)=32b
            H1(100)=BYTE(strtrim(CAMERA,2)+strtrim(inm,2))
            endif
         ENDIF ELSE PRINTF,lu3,H1(3),H1(4),' : ',string(byte(h1(100:159)>32))
      ENDIF ELSE NDAT=0
   pt1=!p.title
   !p.title=pt0     ;+', '+pt1
   ENDIF    ;g,G
IF ZERR EQ 72 THEN begin                         ;<H>
   wave=wsave & flux=fsave & eps=esave & h=h0
   endif
IF ZERR EQ 73 THEN PLDATA,-1,0.,0.               ;<I>
IF ZERR EQ 74 THEN jump                          ;<J>
IF ZERR EQ 75 THEN KDAT,objfile,H,WAVE,FLUX,EPS,irecno  ;<K>
IF ZERR EQ 76 THEN LOCATE,0,WAVE,FLUX,/draw            ;<L>
IF ZERR EQ 77 THEN FTOT,1,WAVE,FLUX              ;<M>
IF ZERR EQ 78 THEN begin                         ;<N>
   !y.range(*)=0.
   ibit,var3,3,2             ;   print,rdbit(var3,3)
   if resetscale eq 0 then resetscale=1
   endif
IF ZERR EQ 79 THEN BEGIN                         ;<O>
   if NDAT EQ 1 THEN PLDATA,1,W1,F1,pcol=c2 else fstatus='  Invalid'
   endif
IF ZERR EQ 80 THEN !p.PSYM=((!P.pSYM/10+1) MOD 2)*10  ;<P> toggle 0<->10
IF ZERR EQ 82 THEN BEGIN                         ;<R>
      PRINT,' OBJFILE=',OBJFILE
      tobj=''
      READ,' Enter new file name: ',tobj
      if tobj ne '' then objfile=TOBJ
      searchdir,objfile,'.icd'
      endif
IF ZERR EQ 83 THEN ROTVEL,0,WAVE          ;<S>
IF ZERR EQ 84 THEN FTOT,0,WAVE,FLUX,nonorm=nonorm       ;<T>
IF ZERR EQ 85 then begin                  ;<U>
   if NDAT EQ 1 THEN FUN1,WAVE,FLUX,EPS,W1,F1,E1 else begin
      print,' Two spectra must be specified to call FUN1'
      fstatus='  Invalid'
      endelse
   endif
IF ZERR EQ 86 THEN LOCATE,1,WAVE,FLUX  ;<V>
IF ZERR EQ 87 THEN WAVEL               ;<W>
IF ZERR EQ 88 THEN BLOWUP,1            ;<X>
IF ZERR EQ 89 THEN begin               ;<Y>
   BLOWUP,2
   if resetscale eq 0 then resetscale=1
   IBIT,VAR3,3,1         ;plot rescaled
   endif
IF ZERR EQ 90 THEN BEGIN               ;<Z> 
   OPSTAT,'  stopped'
   STOP,' ICUR STOP'
   endif
IF ZERR EQ 48 THEN DRLIN,0.            ;<0>
IF ZERR EQ 49 THEN DRLIN,1.            ;<1>
if zerr eq 50 then op_1sig,h,wave,flux,esave     ;<2>
IF ZERR EQ 97 THEN ADDLINE,WAVE,FLUX   ;<a>
;ZERR=98 moved past 99
IF ZERR EQ 99 THEN begin               ;<c>
   coadd,wave,/wav,nb=nbn
   coadd,flux,nb=nbn
   coadd,eps,/err,nb=nbn
   nbn=0
;   COADD,WAVE,FLUX,EPS
   if n_elements(lu3) eq 1 then begin
      printf,lu3,'-4' & printf,lu3,h(53),' bins coadded'
      endif
   zerr=98
   endif
IF ZERR EQ 98 THEN BDATA,h,-1,WAVE,FLUX,EPS,BADW,BADF,bdf ;<b>
if zerr eq 100 then begin                             ;<d>
   case 1 of
      ncam LT 4: DEGRADE,WAVE,FLUX,EPS,BADW,BADF
      ncam EQ 10: DND,H,WAVE,FLUX  ;<d>
      ncam/10 eq 10: flux=deconv_ghrs(wave,flux,ncam-100)
      else: fstatus='  Invalid'
      endcase
   endif
IF ZERR EQ 101 THEN begin       ;<e>
   case 1 of
      autofft gt 0: begin
         ifsm=autofft & fftmode=1
         end
      autofft lt 0: begin
         ifsm=abs(autofft) & fftmode=1
         end
      else: fftmode=0
      endcase
   FFTSM,FLUX,fftmode,IFSM 
   TF=IFSM/10000   ;1 FOR COS, 2 FOR GAUSS, 0 FOR ZERO
   IF TF gt 0 then begin
      CUT=(IFSM-10000*TF)/5000   ;1 IF LOW FREQ NOT FILTERED
      LEN=FLOAT(IFSM-10000*TF-5000*CUT)/1000.
      LEN=SQRT(1./LEN)
      CASE H(33) OF
         30: eps=eps*len   ;S/N
         40: eps=eps/len   ; error
         else:
         endcase
      endif
   if customshow ge 1 then zerr=68
   endif                              ;<e>
; f (102) moved down under 68
IF (ZERR EQ 104) and (ndat eq 1) THEN begin    ;<h>
   FFTSM,F1,0,IFSM2            ;<h>
   TF=IFSM2/10000   ;1 FOR COS, 2 FOR GAUSS, 0 FOR ZERO
   IF TF gt 0 then begin
      CUT=(IFSM2-10000*TF)/5000   ;1 IF LOW FREQ NOT FILTERED
      LEN=FLOAT(IFSM2-10000*TF-5000*CUT)/1000.
      LEN=SQRT(1./LEN)
      CASE H1(33) OF
         30: e1=e1*len   ;S/N
         40: e1=e1/len   ; error
         else:
         endcase
      endif
   endif                              ;<e>
IF ZERR EQ 105 THEN FTOT,3,WAVE,FLUX,eps=eps ;<i>
IF ZERR EQ 106 THEN FTOT,4,WAVE,FLUX,eps=eps ;<j>
IF ZERR EQ 107 THEN ICCOR,NDAT+1,WAVE,FLUX,W1,F1,H1,FWID=FWID    ;<k>
;     FWID is width of filter for continuum smoothing, def=51
IF ZERR EQ 108 THEN LDAT,OBJFILE                       ;<l>
IF ZERR EQ 109 THEN FUN2,WAVE,FLUX,EPS,BADW,BADF,F1    ;<m>
IF ZERR EQ 110 THEN FLUX=FLUX/MAX(FLUX)                ;<n>
IF ZERR EQ 111 THEN NDAT=0                             ;<o>
IF ZERR EQ 112 THEN PSTAT,0,WAVE                       ;<p> status plot
IF ZERR EQ 114 THEN begin                              ;<r>
   vrot=-1.
   if rdbit(var3,1) eq 1 then begin
      print,' Warning: smoothing prime data vector. Smooth second vector in FUN1''
      endif
   ROTsmooth,vrot,WAVE,flux
   endif
IF ZERR EQ 115 THEN ROTVEL,-1,WAVE                     ;<s>
IF ZERR EQ 116 THEN BBODY,WAVE,FLUX,EPS                ;<t>
IF ZERR EQ 117 THEN ADDRED,0,WAVE,FLUX                 ;<u>
if ZERR eq 118 then fwhm,wave,flux                     ;<v>
if ZERR eq 119 then cwhere                             ;<w>
IF ZERR EQ 120 THEN BDATA,h,XCUR,WAVE,FLUX,EPS,BADW,BADF   ;<x>
IF ZERR EQ 121 THEN BEGIN                              ;<y>
   h1=h & w1=wave & e1=eps
   f1=filtspec(flux,eps,smlen)
   ndat=1
   IBIT,var3,2,1         
   endif
IF (ZERR EQ 122) AND (H(33) NE 30) THEN BADF=BADF*0. ;<z>
if zerr eq 37 then begin                  ;<%> normalize and flatten spectrum
   if rdbit(var3,5) eq 1 then yfit=yfit0 else begin    ;use default
      f11=optfilt(flux,eps)
      fc=poly_fit(wave-wave(0),f11,npdeg,yfit)
      endelse
   flux=flux/yfit
   zerr=68
   endif
if zerr eq 42 then begin                    ;<*>
   ibit,var3,5,-1       ;toggle flag
   if rdbit(var3,5) eq 1 then begin         ; update continuum fit
      if n_elements(yfit) eq n_elements(wave) then begin
         yfit0=yfit/max(yfit)
         print,' Continuum fit updated'
         endif else ibit,var3,5,0
      endif
   endif      
if (zerr eq 34) and (ndat eq 1) then begin    ;<"> replace marked pts
   k=where((eps gt -1111.1) and (eps lt -1110.9),nk)
   if nk gt 0 then flux(k)=f1(k)
   PRINT,NK,' Points replaced'
   endif
IF ZERR EQ 35 THEN IBIT,var3,1,-1         ;<#> toggle bit 1 of VAR3
IF ZERR EQ 36 THEN USERPRO,WAVE,FLUX,EPS  ;<$> USER DEFINED PROCEDURE
if zerr eq 124 then begin                 ;<|>
   if irecno eq -1 then irecno=recno else irecno=-1 
   if irecno eq -1 then print,' Use K to write data to end of file' else $
      print,' Use K to overwrite data in record ',strtrim(irecno,2)
   endif
;IF ZERR EQ 42 THEN BLOWUP,-2              ;<*>         ???
IF ZERR EQ 45 THEN BEGIN
   IBIT,var3,2,-1         ;<-> toggle bit 2 of VAR3
   IF rdbit(var3,2) EQ 0 THEN Z='enabled.' ELSE Z='disabled.'
   PRINT,' FUN1 autoscaling ',Z
   ENDIF
IF ZERR EQ 68 THEN begin
   PLDATA,0,WAVE,FLUX,BADW,BADF,pcol=c1,eps=eps,EBCOL=C8  ;<D>
   if customshow eq 1 then zerr=102
   endif
IF ZERR EQ 102 THEN begin                                  ;<f>
   longid=linid
   FINDLIN,WAVE,noid=linid,/noquery,level=flevel,longid=longid
   endif
if (zerr lt 26) or (zerr gt 126) then zrecover     ;cursor timing problem
GOTO,GO1
;
GO2:            ;CLOSE OUT THE RUN
if iscr then begin
   tv,eras,0,0 & tv,eras,xera,0 
   opstat,'ICUR done'
   endif
IF VAR1 GT 0 THEN case 1 of
   n_elements(prffit) eq 0:
   PRFFIT EQ 1: SPAWN_PRINT,'FFIT.FIT'
   ELSE: PRINT,' Fit Log is in FFIT.FIT'
   endcase
;
if !version.os eq 'vms' then z='delete/noconfirm FFIT.TMP;*' else z='rm ffit.tmp'
if ffile('ffit.tmp') eq 1 THEN SPAWN,z
if !version.os eq 'vms' then z='delete/noconfirm IUEFIT.TMP;*' else z='rm iuefit.tmp'
if ffile('iuedat.tmp') eq 1 then SPAWN,z
if !version.os ne 'vms' then spawn,'cp ffit.fit ffit.fit.old'
if strupcase(fname) ne 'NOFILE' then begin
   close,lu3
   PRINT,' Log file is ',fname,'  It will not be printed automatically.'
;   spawn_print,fname
   endif
if !version.os ne 'vms' then spawn,'rm -f '+nulldev 
!x.range=[xmin,xmax]
!y.range=[ymin,ymax]
!P.PSYM=ps
!p.charsize=pcsz
PRINT,' '
VAR1=0
RETURN
END
