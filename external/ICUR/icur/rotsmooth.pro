;******************************************************************************
pro rotsmooth,vsini,w,f
common dataparams,instres                           ;hook for new data format
if n_params(0) lt 3 then begin
   print,' '
   print,'* ROTSMOOTH'
   print,'*    Calling sequence: ROTSMOOTH,vsini,w,f
   print,'*       Rotationally broadened flux vector overwrites input F'
   print,' '
   return
   endif
;
if vsini lt 0. then read,' Enter Vsin i (km/sec): ',vsini
if vsini le 0. then return
;
npts=n_elements(w)   
if npts lt 2 then return
nf=n_elements(f)   
IF nf NE NPTS THEN BEGIN
   IF Nf GT NPTS THEN f=f(0:NPTS-1) ELSE f=[f,FINDGEN(NPTS-Nf)+f(Nf-1)]
   ENDIF
w0=w(0)
disp=w(1)-w0                                ;dispersion
if n_elements(instres) eq 0 then instres=2.
res=instres*disp/w0*2.99792E5               ;resolution in km/sec
;veff=vsini
veff=sqrt((vsini*vsini-res*res)>0.)
if veff le 0. then return
;
dlw=(alog(w(npts-1))-alog(w0))/npts         ;log dispersion
lw=alog(w0)+findgen(npts)*dlw               ;linearized log(W)
IF N_ELEMENTS(LW) NE NPTS THEN BEGIN
   NLW=N_ELEMENTS(LW)
   IF NLW GT NPTS THEN LW=LW(0:NPTS-1) ELSE LW=[LW,FINDGEN(NPTS-NLW)+LW(NLW-1)]
   ENDIF
lf=interpol(f,alog(w),lw)                     ;linearize flux
;
vtmplt=vsinitmplt(veff,w0)
lw0=alog(w0) & llw0=max(lw0)-min(lw0)
np=fix(llw0/dlw)+1                        ;number of points
if np le 1 then return
lw1=lw0(0)+findgen(np)*dlw
c=interpol(vtmplt,lw0,lw1)              ;rotation profile
c=c/total(c)                            ;normalize
cv=convol(lf,c)
w2=exp(lw)                                 ;wavelength
f=interpol(cv,w2,w)                       ;linear
bell
return
end
