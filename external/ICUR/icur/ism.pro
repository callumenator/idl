;*********************************************************************
function ISM,wave,nh,file,helpme=helpme,stp=stp,r=r
ismdat=getenv('ISMDATA')
si=n_elements(wave)
if si eq 1 then sii=1 else sii=0
if (si eq 0) then wave=-1
if (n_params(0) le 1) or (wave(0) eq -1) then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* ISM  -- interstellar transmissions'
   print,'* Calling sequence: tr=ISM(wave,nh,file)'
   print,'*    tr:  output transmission vector'
   print,'*  wave:  input wavelength vector'
   print,'*    nh:  optional -Av (if <0), E(B-V) (if 0-100) or NH'
   print,'*  file:  optional file containing reddening > 1000A, default='
   print,'*         '+ismdat+'seaton.dat'
   print,'*'
   print,'* KEYWORDS:'
   print,'*   R: R value, def=3.1'
   print,' '
   return,-1
   endif
;
if n_elements(r) eq 0 then r=3.1
wav=wave
if (si eq 1) then wav=[wav,wav+1.]
ksort=sort(wav)
wav=wav(ksort)
if n_params(0) lt 2 then nh=0.
IF (N_PARAMS(0) lt 2) or ((n_params(0) eq 3) and (nh eq 0.)) then $
     READ,'Enter NH or E(B-V) or -Av: ',NH
if nh lt 0 then nh=-nh/r   ;convert Av to E(B-V)
if nh LT 100. THEN NH=NH*5.9E21   ;assumes R=3.1
SI=N_ELEMENTS(WAV)-1
SIG=WAV*0.
T=SIG
IF NH EQ 0. THEN GOTO,NOCOL
LMAX=max(WAV) & lmin=min(wav)
;APB=(LMAX-lmin)/FLOAT(SI>1)
APB=wav(1:*)-wav & apb=[apb,apb(si-1)]
Q=912.
filename=ismdat+'seaton.dat'
if n_params(0) eq 3 then filename=file+'.dat'
IMIN=(where(wav ge q,nimin))(0)>0       ;(((Q-lmin)/(APB>.000001) > 0) <SI)
;
IF LMAX GT Q THEN BEGIN   ;use the Seaton reddening law
   if (n_params() lt 3) and (r ne 3.1) then x=alam(r,wav)*r else begin
      OPENR,LUN,filename,/get_lun
      trec=fstat(lun)
      if trec.rec_len eq 0 then rl=trec.size/8 else rl=trec.rec_len/4
      Z=ASSOC(LUN,FLTARR(rl))
      XT=Z(0) & YT=Z(1)
      if !version.arch ne 'vax' then begin    ;file was written on a vax
         xt=swap_endian(xt)
         byteorder,xt
         xt=xt/4.
         yt=swap_endian(yt)
         byteorder,yt
         yt=yt/4.
         endif
      CLOSE,LUN & FREE_LUN,LUN
      X=INTERPOL(YT,XT,WAV)
      x=x+3.1
      endelse 
   IMIN=(where(wav ge q,nimin))(0)>0       
   SIG(IMIN)=1.56E-22*(X(IMIN:*))
   LMAX=Q
   ENDIF
;
IF lmin lT Q THEN begin
   imin=xindex(wav,q)
   FOR I=0,IMIN DO BEGIN
      LAM=WAV(I)
      IF (LAM LE 912.) AND (LAM GT 504.) THEN BEGIN  ; H-He 
           SLO=2.58 & INT=-24.86 & GOTO,SIGM
           ENDIF
      IF (LAM LE 504.) AND (LAM GT 43.648) THEN BEGIN  ; He-C 
           SLO=2.72 & INT=-25.05 & GOTO,SIGM
           ENDIF
      IF (LAM LE 43.648) AND (LAM GT 30.99) THEN BEGIN  ;  C-N
           SLO=2.87 & INT=-25.22 & GOTO,SIGM
           ENDIF
      IF (LAM LE 30.99) AND (LAM GT 23.301) THEN BEGIN  ; N-O
           SLO=3.06 & INT=-25.48 & GOTO,SIGM
           ENDIF
      IF (LAM LE 23.301) AND (LAM GT 14.3018) THEN BEGIN  ; N-Ne
           SLO=2.54 & INT=-24.52 & GOTO,SIGM
           ENDIF
      IF (LAM LE 14.3018) AND (LAM GT 9.5122) THEN BEGIN  ;  Ne=Mg
           SLO=2.52 & INT=-24.46 & GOTO,SIGM
           ENDIF
      IF (LAM LE 9.5122) AND (LAM GT 6.738) THEN BEGIN  ;  Mg-Si
           SLO=1.91 & INT=-23.80 & GOTO,SIGM
           ENDIF
      IF (LAM LE 6.738) AND (LAM GT 5.019) THEN BEGIN  ; Si-S
           SLO=3.73 & INT=-25.27 & GOTO,SIGM
           ENDIF
      IF (LAM LE 5.019) AND (LAM GT 3.871) THEN BEGIN  ; S-A
           SLO=2.96 & INT=-24.68 & GOTO,SIGM
           ENDIF
      IF LAM LE 3.871 THEN BEGIN   ;FINALLY SHORTWARD OF ARGON K EDGE
           SLO=2.99 & INT=-24.68 & GOTO,SIGM
           ENDIF
      SIGM:SIG(I)=10.^(((SLO)*ALOG10(LAM))+INT)
      ENDFOR
   endif
if lmin lt 413. then begin    ;use Morrison & McCammon cross sections
   tx=ismx(wav,/lam)
   k=where(wav le 413.,nk)
   if nk gt 1 then sig(k)=tx(k)
   endif
;
;TAU:
T=(SIG*NH<80.)
TRANS=EXP(-T)
trans=trans(ksort)
if sii eq 1 then trans=trans(0)
if n_elements(trans) eq 1 then trans=trans(0)   ;make a scalar
if keyword_set(stp) then stop,'ISM>>>'
RETURN,trans < 1.
;
NOCOL:   TRANS=T+1.
if sii eq 1 then trans=trans(0)
if n_elements(trans) eq 1 then trans=trans(0)   ;make a scalar
if keyword_set(stp) then stop,'ISM>>>'
RETURN,trans
END
