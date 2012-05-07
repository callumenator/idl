;**************************************************************************
pro crosscor,w1,f10,w2,f20,dw,xc,logl,cut,a,debug=stp,excl=badlam, $
    NOSMOOTH=NOSMOOTH,FWID=FWID,noem=noem,interfit=interfit,optf=optf
common comxy,xcur,ycur,zerr,hcdev,lu3,zzz
xcur=1. & ycur=0.
; cross correlate spectra f1(w1), f2(w2)
; return cross correlation product vector in XC
; if logl eq 0 (default), use log-lambda correlations
;
f1=f10 & f2=f20
if not keyword_set(stp) then stp=0
if keyword_set(interfit) then stp=3
if not keyword_set(badlam) then badlam=-1
if n_elements(badlam) lt 2 then iexcl=0 else iexcl=1
if iexcl eq 1 then begin
   nb=n_elements(badlam)
   odd=nb mod 2
   if odd eq 1 then badlam=badlam(0:nb-2)
   endif
if n_params(0) lt 7 then logl=0                ;default to log-lambda scale
np=n_elements(f2)
if n_elements(cut) eq 0 then cut=(50<(np/3))
;
IF NOT KEYWORD_SET(NOSMOOTH) THEN BEGIN              ;FFT-smooth data
   fftsm,f1,1
   fftsm,f2,1
   ENDIF
;
if keyword_set(noem) then begin              ;exclude emission lines
   filt1=optfilt(f1)
   y=f1-filt1
   var=stddev(y)
   k=where(y gt 3.*var,nk)
   if nk gt 0 then begin
      f1(k)=filt1(k)
      filt1=optfilt(f1)
      y=f1-filt1
      var=stddev(y)
      k=where(y gt 3.*var,nk)
      if nk gt 0 then f1(k)=filt1(k)
      endif
;
   filt1=optfilt(f2)
   y=f2-filt1
   var=stddev(y)
   k=where(y gt 3.*var,nk)
   if nk gt 0 then begin
      f2(k)=filt1(k)
      filt1=optfilt(f2)
      y=f2-filt1
      var=stddev(y)
      k=where(y gt 3.*var,nk)
      if nk gt 0 then f2(k)=filt1(k)
      endif
   endif                  ;noem
;
if logl eq 0 then begin     ;put on log-lambda scale
   loglam,w1,f1,lw1,lf1
   np=n_elements(lw1)
   dw=(lw1(np-1)-lw1(0))/(np-1)
   loglam,w2,f2,lw1,lf2,1
   if iexcl eq 1 then bl=alog10(badlam)
   endif else begin
   lf1=f1 & lf2=f2
   bl=badlam
   endelse
;
if (n_elements(w1) le 1) or (n_elements(w2) le 1) then goto,nowave
if iexcl eq 1 then begin             ;exclude data segments
   nb=n_elements(bl)/2
   if nb ge 1 then for i=0,nb-1 do begin
      bw1=bl(i*2) & bw2=bl(i*2+1)
      k=where((lw1 gt bw1) and (lw1 lt bw2))
      if k(0) ne -1 then linterpl,lf1,(k(0)-1)>0,k(n_elements(k)-1)
      if k(0) ne -1 then linterpl,lf2,(k(0)-1)>0,k(n_elements(k)-1)
      endfor
   endif
;
nowave:
IF N_ELEMENTS(FWID) EQ 0 THEN FWID=51
if fwid le 0 then fwid=51
if keyword_set(optf) then begin
   filt1=optfilt(lf1)
   filt2=optfilt(lf2)
   endif else begin
   filt1=smooth(maxfilt(lf1),FWID)
   filt2=smooth(maxfilt(lf2),FWID)
   endelse
;
ff1=lf1/filt1             ;divide out continuum
ff2=lf2/filt2
ff1=ff1-mean(ff1)         ;subtract mean
ff2=ff2-mean(ff2)
;
if iexcl eq 1 then begin             ;re-exclude data segments
   if nb ge 1 then for i=0,nb-1 do begin
      bw1=bl(i*2) & bw2=bl(i*2+1)
      k=where((lw1 gt bw1) and (lw1 lt bw2))
      if k(0) ne -1 then ff1(k)=0.
      if k(0) ne -1 then ff2(k)=0.
      endfor
   endif
spxcor,ff1,ff2,xc,cut
;
if n_params(0) ge 9 then begin    ;do not fit here
   x=findgen(n_elements(xc))
   xcc=xc
   if stp eq 3 then begin
      plot,x,xc
      if !d.name eq 'X' then wshow
      print,' put cursor on peak'
      bell
      blowup,-1
      c=xcur
      xcc=xc
      k=where(x lt c-15) & if k(0) ne -1 then xcc(k)=0
      k=where(x gt c+15) & if k(0) ne -1 then xcc(k)=0
      endif else begin
      c=where(xc eq max(xc)) & c=c(0)
      endelse
;
   a=[max(xc((c-5)>0:(c+5)<(n_elements(x)-1)))-mean(xc),c,5.,mean(xc),0.,0.]
   z=gaussfit(x,xcc,a)
   a(1)=a(1)-max(x)/2.    ;shift
   endif
;
if stp gt 0 then begin
   !p.position=[.2,.55,.9,.95]
;set_viewport,.2,.9,.55,.95
   plot,lw1,ff1 & oplot,lw1,ff2,color=15
   endif
return
end
