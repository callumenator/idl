;*******************************************************************
PRO FFTSM,FLUX,MODE,IFSM,helpme=helpme
; MODE=0 IS INTERACTIVE, MODE=1 IS AUTOMATIC, WITH GAUSSIAN FILTER AND
; DEFAULT HALF-POWER POINT AT THE NYQUIST FREQUENCY
COMMON COMXY,XCUR,YCUR,ZERR,hcdev,lu3,zzz
common icurunits,xunits,yunits,title,c1,c2,c3,ch,c4,c5,c6,c7,c8,c9
IF N_PARAMS(0) EQ 0 THEN helpme=1
if keyword_set(helpme) then BEGIN
   print,' '
   print,'* FFTSM --  Fourier smoothing'
   print,'* Minimum call is FFTSM,F,M,FSM'
   print,'*    F: vector to be smoothed'
   print,'*    M: 0 for interactive (default), 1 for automatic'
   print,'*    FSM: if mode=1, optional input half power width in units of the'
   print,'*               Nyquist frequency (default=1.0).'
   print,'*         if mode=0, FSM is the HPP output in units of the Nyquist Frequency.'
   print,' '
   return
   endif
;
if n_elements(xunits) eq 0 then xunits=''
if n_params(0) eq 1 then mode=0   ;default=interactive
if n_elements(c2) eq 0 then c2=!p.color
if n_elements(c3) eq 0 then c3=!p.color
if strupcase(!d.name) eq 'X' or strupcase(!d.name) eq 'WIN' then $
     iscr=1 else iscr=0
if n_elements(xcur) eq 0 then xcur=0
if n_elements(ycur) eq 0 then ycur=0
X0=XCUR & Y0=YCUR
IGS=0
FORIG=FLUX
PI=180./!RADEG
NMAX0=N_ELEMENTS(FLUX)
; EXPAND VECTOR LENGTH TO FACTOR OF 2
L=ALOG10(NMAX0)/ALOG10(2.)
IEXPAND=0
IF (L - FIX(L)) NE 0. THEN BEGIN
   IEXPAND=1
   MEAN=TOTAL(FLUX)/FLOAT(NMAX0)
   L=long(L)+1l
   F=FLTARR(2L^L)+MEAN  ;PAD WITH MEAN LEVEL
   F(0)=FLUX
   FLUX=F
   ENDIF
NMAX=N_ELEMENTS(FLUX)
NM2=NMAX/2L
IX=FINDGEN(NM2) & IX2=FINDGEN(NMAX)
FFL=FLUX
FLUX=FFT(FLUX,-1)
Z1=' '
NIT=0
YM=MAX(FLUX(1:NM2-1))
I1=NM2/2.-0.5  ;POSITION AT NYQUIST FREQUENCY
I0=0L
KGO=0
if n_elements(ifsm) gt 0 then begin
   if (mode eq 1) and (ifsm gt 0.) then i1=(i1/ifsm>0)<nm2
   endif
IF MODE EQ 1 THEN GOTO,AUTO
; set up plot parameters
XTIT=!X.TITLE & YTIT=!Y.TITLE & mt=!p.title
X1=!X.range(0)
X2=!X.range(1)
Y1=!Y.range(0)
Y2=!Y.range(1)
;
PLT:
!x.ticks=0
!X.TITLE=''
!Y.TITLE='Amplitude'
SETXY,0.,0.,-YM,YM
!C=-10
PLOT,IX,FLUX,xr=[0,n_elements(ix)-1],/xsty               ;FFT
oplot,[NM2/2.-0.5,NM2/2.-0.5],!y.crange,linestyle=1,psym=0,color=c2  ;Nyquist freq.
IF n_elements(gsn) gt 1 THEN OPLOT,IX,GSN*YM,color=c3
IF NIT EQ 0 THEN BEGIN
   XCUR=NM2/2.-0.5   ;MOVE X TO NYQUIST FREQUENCY
   YCUR=!Y.CRANGE(0)+0.75*(!Y.CRANGE(1)-!Y.CRANGE(0))
   ENDIF
!p.NOERASe=0
if iscr then wshow
Z='MARK HALF WIDTH (C->cosine;also c,g), > to zero, Q TO ABORT'+Z1
print,z
MVCUR:
opstat,'  Waiting'
xu0=xunits & xunits='f/Nyquist f'
BLOWUP,-1,readout=101
xunits=xu0
opstat,'  Working'
if zerr eq 13 then zerr=32  ;CR valid response
if (zerr lt 26) or (zerr gt 122) then zrecover
IF (ZERR EQ 90) or (zerr eq 122) THEN BEGIN   ;<Z,z>
   STOP,' FFTSM STOP'
   GOTO,PLT
   ENDIF
IF (ZERR EQ 81) or (zerr eq 113) THEN BEGIN   ;<Q,q>
   FLUX=FORIG
   I1=0L
   GOTO,QUIT
   ENDIF
IF (ZERR EQ 78) or (zerr eq 110) or (ZERR EQ 82) or (zerr eq 114) $
      THEN BEGIN   ;<N,R> MOVE CURSOR TO NYQUIST FREQUENCY
   XCUR=NM2/2.-0.5
   YCUR=!Y.CRANGE(0)+0.75*(!Y.CRANGE(1)-!Y.CRANGE(0))
   GOTO,MVCUR
   ENDIF
IF (ZERR EQ 50) or (zerr eq 72) or (ZERR EQ 104) $
      THEN BEGIN   ;<2,h> MOVE CURSOR TO half NYQUIST FREQUENCY
   XCUR=NM2/4.-0.5
   YCUR=!Y.CRANGE(0)+0.75*(!Y.CRANGE(1)-!Y.CRANGE(0))
   GOTO,MVCUR
   ENDIF
IF (NIT GT 0) AND (ZERR EQ 48) THEN GOTO,GOON
I1=XCUR
NIT=1
;
IF ZERR EQ 62 THEN BEGIN   ;> ; ZERO POWER IN HIGH FREQUENCIES
   IGS=-1
   K=FLTARR(NMAX-(I1<NM2)*2)
   FFL=FLUX & FFL(I1)=K
   GOTO,CFT
   ENDIF
;
IF ZERR EQ 60 THEN BEGIN   ;> ; ZERO POWER IN Low FREQUENCIES
   IGS=-1
   K=FLTARR(I1<(nmax-1))
   FFL=FLUX & FFL(0)=K
   GOTO,CFT
   ENDIF
;
KGO=ZERR
IF (ZERR EQ 99) OR (ZERR EQ 103) THEN BEGIN   ; SECOND CURSOR CALL
   print,' hit cursor again'
   opstat,'  Waiting'
   BLOWUP,-1,readout=101
   opstat,'  Working'
   if (zerr lt 26) or (zerr gt 122) then zrecover
   I=XCUR
   IF I LT 0. THEN I=0L
   I0=LONG(I<I1) & I1=LONG(I>I1)
   ENDIF ELSE I0=0L
AUTO:
   GSN=FLTARR(NMAX)+1.
   G0=GSN*0.
IF (KGO EQ 67) OR (KGO EQ 99) THEN BEGIN   ;<C,c> USE COSINE FILTER
   IGS=1
   V=PI/2.*FINDGEN(((I1-I0)*2)<NMAX)/FLOAT(I1-I0)
   C=(COS(V)+1.)/2.
   G0(0)=C
   GSN(I0)=G0(0:nmax-i0-1)
   GOTO,PFILT
   ENDIF                       ; CREATE GAUSSIAN FILTER
  IGS=2
  EXPT=(IX2/(I1-I0))<9.
  EXPT=-ALOG(2.)*EXPT*EXPT
  G0=(EXP(EXPT)>1.E-18)
  GSN(I0)=G0(0:nmax-i0-1)
PFILT:                         ; REFLECT FILTER FUNCTION
FOR I=0L,NM2-1L DO GSN(NMAX-1-I)=GSN(I)
!C=-10
IF MODE EQ 0 THEN begin
   OPLOT,IX,GSN*YM,color=c3
   oplot,[NM2/2.-0.5,NM2/2.-0.5],!y.crange,linestyle=1,psym=0,color=c2
   endif
FFL=FLUX*GSN
CFT:
FFL=FFT(FFL,1)
IF MODE EQ 1 THEN GOTO, GOON   ;AUTOMATIC FIT
;
!p.position=[.2,.5,.9,.9]
!X.RANGE(*)=0.
!Y.RANGE(*)=0.
!C=-10
!y.title=ytit
!p.title=mt
!x.tickname=' '
PLOT,FFL(0:nmax0-1)
!x.tickname=''
!p.position=[.2,.1,.9,.5]
!p.NOERASE=1
!p.title=''
Z1='; TYPE 0 IF OK
GOTO,PLT
;
GOON: FLUX=FLOAT(FFL)
IF IEXPAND EQ 1 THEN FLUX=FLUX(0:NMAX0-1)
QUIT:
Z='                                                                         '
IF MODE EQ 0 THEN begin
   print,z
   SETXY,X1,X2,Y1,Y2
;   !x.range=[X1,X2]
;   !y.range=[Y1,Y2]
   !p.position=[.2,.2,.9,.9]
   !y.title=ytit
   !x.title=xtit
   !p.title=mt
   !x.ticks=0
   endif
IFSM=FIX(FLOAT(I1)/FLOAT(NM2)*1000.)
IF IGS EQ -1 THEN IFSM=-IFSM ELSE IFSM=IFSM+10000*IGS+5000*(I0/(I0>1))
zerr=68
XCUR=X0 & YCUR=Y0
RETURN
END
