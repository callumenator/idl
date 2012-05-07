;******************************************************************
PRO FUN1,WAVE,FLUX,EPS,W1,F1,E1  ; ICUR LOOP 2
; VAX Version 1.0 8/29/86
;  CURSOR COMMANDS:
; A:  PLOT ALL DATA                      a:  ADD A LINE TO THE DATA
; B:  BLOWUP PLOT                        b:  REDEFINE BAD DATA
; C:  COMPUTE CENTROID OF FEATURE        c:  COADD BINS
; D:  INDICATE BAD DATA (SAME AS R)      d:  DIVIDE FLUX BY ND FUNCTION
; E:  GET EQUIVALENT WIDTHS              e:  DIVIDE F1 BY ND FUNCTION
; F:  ENTER ICFIT TO FIT LINES           f:  identify lines
; G:  MANUALLY SHIFT SECOND DATA SET     g:  get new comparison from .STD file
; H:                                     h:  
; I:  INITIALIZE SCREEN                  i:  PERFORM LINEAR INTERPOLATION
; J:  JUMP IN X DIRECTION                j:  LINEAR INTERPOLATION
; K:  SAVE DATA ON GENERIC DISK FILES    k:  DIVIDE F BY ND FUNCTION
; L:  LOCATE WAVELENGTH USING CURSOR
; M:  PLOT MEAN BETWEEN LIMITS           m:  CALL FUN2
; N:  RESET !Y.RANGE TO 0.
; O:  OVERPLOT SECOND DATA SET           o:  OVERWRITE INPUT VECTOR
; P:  TOGGLE !P.PSYM 0<_>10              p:  PRINT STATUS
; Q:  QUIT
; R:  REPLOT, WITH CURRENT NSM           r:  ROTATIONAL BROADENING (#2 only)
; S:  SMOOTH DATA                        s:  GAUSSIAN SMOOTHING
; T:  SUM TOTAL FLUX                     t:  OPLOT BLACK BODY
; U:  SCALE F1 TO FLUX                   u:  UNREDDEN DATA
; V:  LOCATE AND EXPAND PLOT
; W:  RETURN WAVELENGTH AND FLUX
; X:  EXPAND IN X DIRECTION              x:  RESET EPSILON VALUE TO -1111
; Y:  EXPAND IN Y DIRECTION
; Z:  PAUSE                              z:  ZERO BAD FLUX VECTOR
; +:  ADD DATA                           -:  FLUX-F1
; *:  FLUX*F1                            /:  FLUX/F1
; %:  PLOT FRACTION                      &:  ADD ONLY GOOD DATA 
; 0:  DRAW ZERO LINE                     1:  DRAW LINE AT Y=1
; 2:  HALVE FLUX                         !: TOGGLE DEVICE 'X' <-> PS
; 5:  (FLUX-F1)/F1
; ?:  LIST CURSOR COMMANDS               
COMMON COM1,HD,IK,IFT,NSM,C,NDAT,IFSM,KBLO,H1,ipdv,ihcdev
COMMON COMXY,X,Y,ZERR,resetscale,lu3
COMMON VARS,VAR1,VAR2,VAR3,VAR4,bdf,psdel,prffit,vrot2
common icdisk,icurdisk,icurdata,ismdata,objfile,stdfile,userdata,recno
common custompars,dw,lp,flatback,autofft,eafudge,NREC2
common icurunits,xunits,yunits,title,c1,c2,c3,ch
common radialvelocity,radvel,linid,orv,vc
;
autoscale=1
zcam='    LWP LWR SWP SWR '
npx=30              ;number of points in cross correlations
apb=wave(1)-wave(0)
w1save=w1 & f1save=f1
vp0=[.25,.95,.2,.9]
vph=[.2,.9,.2,.9]
vp=vp0
c1save=c1
BDA=-1               ;NOT IN USE
H0=HD
yt=!y.title
!p.color=c1
IF N_ELEMENTS(W1) EQ 0 THEN W1=WAVE
IF N_ELEMENTS(E1) EQ 0 THEN E1=FIX(W1)*0+100
INITF1,WAVE,FLUX,EPS,W1,F1,E1,F,E,RESET,BADW,BADF
XERA=!D.X_CH_SIZE*12
ERAS=INTARR(XERA,!D.Y_CH_SIZE+2)
CMD=''
vfile=stdfile & if strupcase(strmid(vfile,0,6)) eq 'NOFILE' then vfile=objfile
;
WHILE (ZERR NE 81) and (zerr ne 113) and (zerr ne 26) DO BEGIN   ;<Q> to quit
   !p.color=c1
   IF STRUPCASE(!D.NAME) EQ 'X' THEN WSHOW
   STATUS='  Done'
   if (STRUPCASE(!D.NAME) EQ 'X') and (strlen(cmd) gt 0) then opstat,status
   BLOWUP,-1   ; CURSOR CALL
   if zerr eq 33 then cmd='Command: !!' else cmd='Command: '+string(byte(zerr))
   status='  Working'
   IF (STRUPCASE(!D.NAME) EQ 'X') and (strlen(cmd) gt 0) then begin
      tv,eras,0,0 & xyouts,0,2,cmd,/dev
      opstat,status
      endif
;
   if zerr eq 33 then begin      ;!
      if !d.name eq ipdv then begin
         sp,ihcdev
         print,' plot data being output to device ',ihcdev
         c1=!p.color
         !p.position=[.2,.2,.9,.9]
         endif else begin
         c1=c1save
         lplt,ipdv,nodelete=rdbit(psdel,0),noplot=rdbit(psdel,1)
         print,' plot data being output to device ',ipdv
         !p.position=[.15,.15,.95,.95]
         endelse
      endif
   Z=WHERE(ZERR EQ KBLO,kz) & IF kz GT 0 THEN begin         ;{>,<,^,6}
      BLOWUP,ZERR
      IF AUTOSCALE NE -1 THEN autoscale=1
      endif
   IF ZERR EQ 61 THEN BEGIN                                 ;<=>
      !p.position=[vph(0),vph(2),vph(1),vph(3)]
      PLDATA,10,WAVE,FLUX,BADW,BADF,pcol=ch,psdel=psdel
      !p.position=[vp(0),vp(2),vp(1),vp(3)]
      ENDIF
   IF ZERR EQ 41 THEN IBIT,VAR3,4,-1     ;<(>   TOGGLE BIT
   IF ZERR EQ 63 THEN icur_help,2            ;<?>
   IF ZERR EQ 65 THEN begin              ;<A> 
      PLDATA,-2,WAVE,F
      zerr=79
      endif
   IF ZERR EQ 66 THEN BLOWUP,0           ;<B>
   IF ZERR EQ 67 THEN FTOT,2,WAVE,F      ;<C>
   IF ZERR EQ 69 THEN IFEAT,WAVE,F,BADF  ;<E>
   IF ZERR EQ 70 THEN ICFIT2,WAVE,F,E    ;<F> 
   IF ZERR EQ 71 THEN BEGIN
      BDA=BDF                                   ;BAD DATA FLAG
      WSHIFT,1,WAVE,FLUX,EPS,F1,E1,E,W1  ;<G>
      ENDIF
   IF ZERR EQ 73 THEN PLDATA,-1,0.,0.    ;<I>
   IF ZERR EQ 74 THEN BEGIN              ;<J>
      jump 
      IF AUTOSCALE NE -1 THEN AUTOSCALE=1
      ENDIF
   IF ZERR EQ 75 THEN BEGIN              ;<K>
      HX=HD
      KDAT,objfile,HX,WAVE,F,E
      ENDIF
   IF ZERR EQ 76 THEN LOCATE,0,WAVE,F           ;<L>
   IF ZERR EQ 77 THEN FTOT,1,WAVE,F             ;<M> 
   IF ZERR EQ 78 THEN !Y.RANGE(*)=0.            ;<N>
   IF ZERR EQ 80 THEN !P.PSYM=((!P.PSYM/10+1) MOD 2)*10   ;<P>
   IF ZERR EQ 82 THEN PLDATA,0,WAVE,F           ;<R>
   IF ZERR EQ 83 THEN ROTVEL,0,WAVE             ;<S>
   IF ZERR EQ 84 THEN FTOT,0,WAVE,F             ;<T>
   IF ZERR EQ 85 THEN begin                     ;<U>
      SCALE,0,WAVE,FLUX,F1
      autoscale=0            ;turn off oplot autoscaling
      endif
   IF ZERR EQ 86 THEN BEGIN                     ;<V>
      LOCATE,1,WAVE,F
      IF AUTOSCALE NE -1 THEN AUTOSCALE=1
      ENDIF
   IF (ZERR EQ 87) OR (ZERR EQ 32) THEN WAVEL   ;<W>
   IF ZERR EQ 88 THEN begin                     ;<X>
      BLOWUP,1
      IF AUTOSCALE NE -1 THEN autoscale=1
      endif
   IF ZERR EQ 89 THEN BLOWUP,2                  ;<Y>
   IF ZERR EQ 90 THEN STOP,'    FUN1 STOP '     ;<Z>
   IF (ZERR GE 37) AND (ZERR LT 48) THEN BEGIN
      MANIP,FLUX,F1,F,EPS,E1,badf
      AUTOSCALE=-1
      ENDIF
   IF ZERR EQ 48 THEN DRLIN,0.          ;<0>
   IF ZERR EQ 49 THEN DRLIN,1.          ;<1>
   IF ZERR EQ 50 THEN F=F/2.            ;<2>
   IF ZERR EQ 53 THEN MANIP,FLUX,F1,F,EPS,E1,badf   ;<5>
   IF ZERR EQ 97 THEN ADDLINE,WAVE,F    ;<a>
   ;  ZERR EQ 98                        ;<b> moved down 
   IF ZERR EQ 99 THEN begin             ;<c>
      COADD,WAVE,F,E   
      if n_elements(lu3) eq 1 then begin
         printf,lu3,'-4' & printf,lu3,hd(53),' bins coadded'
         endif
      zerr=98
      endif
;   IF (ZERR EQ 100) AND (HD(3) GE 10) THEN DND,IDAT,WAVE,FLUX  ;<d>
   IF ZERR EQ 100 THEN PLDATA,0,WAVE,F,BADW,BADF*0.           ;<d>
   IF (ZERR EQ 101) AND (HD(3) GE 10) THEN DND,h1,W1,F1       ;<e>
   IF ZERR EQ 102 THEN FINDLIN,WAVE,/noquery,noid=linid       ;<f>
   if (zerr eq 58) OR (zerr eq 59) then begin             ;<:,;> next std record
      if n_elements(nrec2) eq 0 then zerr=103 else begin
         if zerr eq 58 then nrec2=nrec2-1 else nrec2=nrec2+1
         if (nrec2 lt 0) or (nrec2 gt get_nspec(stdfile)-1) then begin
            print,' Record out of bounds'
            endif else begin
            GDAT,stdfile,H1,W1,F1,E1,NREC2
            AUTOSCALE=1
            IF n_elements(h1) gt 2 THEN BEGIN
               if h1(3) le 0 then h1(3)=999           ;model
               NDAT=1
               f1save=f1
               if vrot2 gt 0. then rotsmooth,vrot2,w1,f1
               if n_elements(lu3) eq 1 then begin
                  PRINTF,lu3,'-7'
                  IF H1(3) LE 4 THEN PRINTF,lu3,H1(3),H1(4),' IUE camera=', $
                  STRMID(ZCAM,H1(3)*4,4),' IMAGE=',H1(4) $
                 ELSE PRINTF,lu3,H1(3),H1(4),' : ',string(byte(h1(100:159))>32b)
                  endif
               INITF1,WAVE,FLUX,EPS,W1,F1,E1,F,E,RESET,BADW,BADF
               endif     ;header exists
            endelse
         endelse    ;nrec2 exists
      endif
   IF ZERR EQ 103 THEN BEGIN                   ;<g>  GET DATA FROM STANDARD FILE
      check_stdfile
      READ,' Enter record number: ',nrec2
      if nrec2 lt 0 then begin
         if hd(3)/10 eq 5 then echel=1 else echel=0
         twostar,-1,-1,w1,f1,H1,dm=-99.,/noplot,ech=echel
         endif else BEGIN
         GDAT,stdfile,H1,W1,F1,E1,NREC2
         AUTOSCALE=1
         ENDELSE
      NDAT=0
      IF n_elements(h1) gt 2 THEN BEGIN
         if h1(3) le 0 then h1(3)=999           ;model
         NDAT=1
         f1save=f1
         if vrot2 gt 0. then rotsmooth,vrot2,w1,f1
         if n_elements(lu3) eq 1 then begin
            PRINTF,lu3,'-7'
            IF H1(3) LE 4 THEN PRINTF,lu3,H1(3),H1(4),' IUE camera=', $
              STRMID(ZCAM,H1(3)*4,4),' IMAGE=',H1(4) $
              ELSE PRINTF,lu3,H1(3),H1(4),' : ',string(byte(h1(100:159))>32b)
            endif
         INITF1,WAVE,FLUX,EPS,W1,F1,E1,F,E,RESET,BADW,BADF
         ENDIF else print,' File ',idt1,' not found.'
      ENDIF
   IF ZERR EQ 104 THEN HBIN,WAVE,FLUX,EPS,F1,E1,E          ;<h>
   IF ZERR EQ 105 THEN FTOT,3,WAVE,F                       ;<i>
   IF ZERR EQ 106 THEN FTOT,4,WAVE,F                       ;<j>
;   IF (ZERR EQ 107) AND (HD(3) GE 10) THEN DND,h,WAVE,F    ;<k>
   IF ZERR EQ 107 THEN begin                               ;<k>
      iccor,2,wave,flux,wave,f1,0,a,np=npx,/flat,delay=0.5   
      PLDATA,0,WAVE,Flux,BADW,BADF*0.,PCOL=C1 ;<D>
      shft=a(1)*apb
      nw=N_ELEMENTS(WAVE)
      NP=N_ELEMENTS(F1)-NW
      f1=interpol(f1,wave,wave+shft)
      e1=interpol(e1,wave,wave+shft)
      oplot,wave,f1,color=c2
      zerr=32
      endif
   if zerr eq 108 then ldat,vfile                          ;<l>
   IF ZERR EQ 109 THEN FUN2,WAVE,F,E,BADW,BADF,F1          ;<m>
   IF ZERR EQ 111 THEN OVERWRT,1,FLUX,EPS,0,F,E,0,RESET    ;<o>
   IF ZERR EQ 112 THEN PSTAT,1,WAVE                        ;<p>
   IF ZERR EQ 114 THEN begin                               ;<r>
      if vrot2 gt 0. then f1=f1save
      vrot2=-1.
      ROTsmooth,vrot2,W1,f1
      scale,-1,wave,flux,f1
      endif
   IF ZERR EQ 115 THEN ROTVEL,-1,WAVE                      ;<s>
   IF ZERR EQ 116 THEN BBODY,WAVE,F,E                      ;<t>
   IF ZERR EQ 117 THEN BEGIN
      ADDRED,0,WAVE,FLUX                                   ;<u>
      F=FLUX
      scale,-1,wave,flux,f1
      ENDIF
   if zerr eq 118 then fwhm,wave,flux                      ;<v>
   if zerr eq 119 then cwhere                              ;<w>
   IF ZERR EQ 68 THEN BEGIN                                ;<D>
      PLDATA,0,WAVE,F,BADW,BADF*0.,PCOL=C1
      IF AUTOSCALE NE -1 THEN ZERR=79                      ;AUTOMATIC OVERPLOT
      ENDIF  
   IF ZERR EQ 79 THEN begin                                ;<O>
      if (autoscale eq 1) and (rdbit(var3,2) eq 0) then begin ;scale within window
         k=where((wave ge !x.crange(0)) and (wave le !x.crange(1)),nk)
         if nk gt 1 then begin
            fact=total(f(k))/total(f1(k))
            f1=f1*fact
            fact=abs(10^(hd(35)/100.)*fact)
            hd(35)=fix(alog10(fact)*100.)
            endif
         endif
      PLDATA,1,WAVE,F1,PCOL=C2
      endif
   IF ZERR EQ 98 THEN BEGIN                                ;<b>
      BDATA,HD,-1,WAVE,F,E,BADW,BADF,bdf
      IF BDA EQ 0 THEN BDF=0                ;do not reset flag after WSHIFT
      BDA=-1
      ENDIF
   IF ZERR EQ 120 THEN BDATA,HD,X,WAVE,F,E,BADW,BADF          ;<x>
   IF ZERR EQ 64 THEN IBIT,var3,0,-1                       ;<@>
   IF ZERR EQ 35 THEN IBIT,var3,1,-1                       ;<#>
   if (zerr lt 26) or (zerr gt 122) then zrecover
   ENDWHILE
IF RESET EQ 0 THEN HD=H0
!y.title=yt
ZERR=112
RETURN
END
