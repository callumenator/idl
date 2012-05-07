;***********************************************************************
PRO LOCATE,IN,WAVE,FLUX,nbins=nbins,draw=draw,LAMBDA=LAMBDA,HELPME=HELPME
                                 ; PLACE CURSOR AT GIVEN POSITION
; IN=0 MERELY MOVES CURSOR
; IN=1 ALSO REPLOTS +/- 100 BINS CENTERED UPON POSITION
; IN=2 USED BY RWAVE
; in = -1  like 1, but uses xcur for center
COMMON COM1,H,IK,IFT,NSM,C,NDAT,ifsm,kblo,h2,ipdv,ihcdev
COMMON COMXY,Xcur,Ycur
common vars,var1,var2,var3,var4,BDF
IF N_PARAMS(0) LT 2 THEN HELPME=1
IF KEYWORD_SET(HELPME) THEN BEGIN
   print,' '
   print,'* LOCATE'
   print,'* calling sequence: LOCATE,in,wave,flux'
   print,'*    IN:0  MOVES CURSOR, 1: ALSO PLOTS +/- 100 BINS CENTERED ON POSITION'
   print,'*    WAVE: wavelength vector (required)'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    DRAW: set to plot vertical line at wavelength'
   print,'*    LAMBDA: array of wavelengths for plotting - for non-interactive use\'
   print,'* '
   print,' '
   return
   end
S=N_ELEMENTS(WAVE)-1
npp=fix(((s/1024.*100.)>100)<200)
z0='                           '
XL=WAVE(0)
XH=WAVE(S)
IF IN EQ 2 THEN GOTO,VIEW
if in eq -1 then lambda=xcur else $
   if n_elements(lambda) eq 0 then read,' ENTER WAVELENGTH: ',LAMBDA
IF abs(IN) EQ 1 THEN GOTO,VIEW
nl=n_elements(lambda)
for i=0,nl-1 do begin
   lam=lambda(i)
   IF (LAM GT !X.crange(1)) OR (LAM LT !X.crange(0)) THEN begin
      if nl eq 1 then goto,goret else GOTO,skip
      endif
   Xcur=LAM
   IF (YCUR LT !Y.CRANGE(0)) OR (YCUR GT !Y.CRANGE(1)) THEN YCUR=MEAN(!Y.CRANGE)
   if keyword_set(draw) then oplot,[lam,lam],!y.crange,ps=0,linestyle=2
   skip:
   endfor
RETURN
VIEW:   ; |IN|=1 OR 2
IF abs(IN) EQ 1 THEN begin
   if keyword_set(nbins) then nb=nbins else NB=npp
   endif
IF IN EQ 2 THEN BEGIN
   NB=20
   LAMBDA=Xcur
   ENDIF
IF (LAMBDA GT WAVE(S)) OR (LAMBDA LT WAVE(0)) THEN GOTO,GORET
ic=xindex(wave,lambda)              ;TABINV,WAVE,LAMBDA,IC
I1=IC-NB
IF I1 LT 0 THEN I1=0
I2=IC+NB
IF I2 GT S THEN I2=S
ymax=max(flux(i1:i2))
; check for Lyman alpha contamination
if (wave (i1) lt 1222.) and (wave(i2) gt 1210.) then begin   ;LyA in band
   if abs(wave(ic)-1216.) gt 10. then begin                  ;not measuring LyA
      tw=wave(i1:i2)
      tf=flux(i1:i2)
      k=where(abs(tw-1216.) gt 10.) 
      ymax=max(tf(k))
      endif
   endif
!x.range=[WAVE(long(I1)),WAVE(long(I2))]
!y.range=[MIN(FLUX(I1:I2)),ymax]
PLDATA,0,WAVE,FLUX
Xcur=LAMBDA
IF (YCUR LT !Y.CRANGE(0)) OR (YCUR GT !Y.CRANGE(1)) THEN YCUR=MEAN(!Y.CRANGE)
RETURN
GORET: PRINT,' DESIRED WAVELENGTH OUT OF RANGE',string(7b)
RETURN
END
