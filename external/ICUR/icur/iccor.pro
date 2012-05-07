;************************************************************************
PRO iccor,im,w0,fa,wb,fb,hb,a,NP=NP,flat=flat,delay=delay,NOSMOOTH=NOSMOOTH, $
    fwid=fwid
; CROSS/AUTO CORRELATIONS
; IM=1 FOR AUTO CORRELATION; IM=2 FOR CROSS CORRELATION
COMMON COM1,H,IK,IFT,NSM,C,NDAT,IFSM
COMMON COMXY,Xcur,Ycur,zerr
if n_params(0) lt 3 then return
IF (IM LE 0) OR (IM GT 2) THEN RETURN
if n_params(0) lt 5 then im=1
;
f0=fa
zt='auto-correlation'
if (nsm ge 3) and (nsm lt 1000) then f0=smooth(fa,nsm)
if n_elements(c) gt 1 then f0=convol(fa,c)
IF IM EQ 2 THEN BEGIN
   W1=WB
   f1=fb
   if (nsm ge 3) and (nsm lt 1000) then f1=smooth(fb,nsm)
   if n_elements(c) gt 1 then f1=convol(fb,c)
   zt='cross-correlation'
   ENDIF else begin
   w1=w0 & f1=f0
   hb=h
   endelse
PS=!p.PSYM
WSHOW
z=' mark range to correlate, 0 for all, Q to quit'
print,z
k0=indgen(n_elements(w0)) 
k1=indgen(n_elements(w1)) 
blowup,-1
if (zerr eq 81) or (zerr eq 113) then return    ;quit
if zerr ne 48 then begin
      xa=xcur
      blowup,-1
      xb=xcur
      x1=xa<xb
      x2=xa>xb
      if x2 gt x1 then k0=where((w0 ge x1) and (w0 le x2))
      kmin=(k0(0))>0
      npt=n_elements(w0)-1 
      kmax=(max(k0))<(npt-1)
      k0=kmin+indgen(kmax-kmin+1)
      if x2 gt x1 then k1=where((w1 ge x1) and (w1 le x2))
      kmin=(k1(0))>0
      npt=n_elements(w1)-1 
      kmax=(max(k1))<(npt-1)
      k1=kmin+indgen(kmax-kmin+1)
      endif
;
if n_elements(np) eq 0 then np=100<N_ELEMENTS(K0)/3
if np le 0 then np=100<N_ELEMENTS(K0)/3
print,np
bell,1
crosscor,w0(k0),f0(k0),w1(k1),f1(k1),dw,xc,0,np,NOSMOOTH=NOSMOOTH,fwid=fwid
x=indgen(2*np+1)-np
mxc=max(xc)
xcen=X(where(xc eq mxc))
a=[mxc,xcen,2.,0.]
if keyword_set(flat) then y=gaussfit(x,xc,a,order=2) else y=gaussfit(x,xc,a)
;
iplt=1
;
if iplt eq 1 then begin
   mt=!p.title
   xt=!x.title
   yt=!y.title
   !p.title=mt+' '
   if (im eq 2) and (n_elements(hb) gt 160) then $
      !p.title=!p.title+strtrim(byte(hb(100:159)),2)+' '
   !p.title=!p.title+zt
   !x.title='shift'
   !y.title='!6 Correlation '
   plot,x,xc,psym=10,XRANGE=[0.,0.],YRANGE=[0.,0.]
   oplot,x,y,psym=0,color=15
   !p.title=mt
   !x.title=xt
   !y.title=yt
   endif
;
c=2.99792E5
vcal=2.40
VHEL0=FLOAT(H(30))+FLOAT(H(31))/1000.
if n_elements(hb) lt 31 then vhel1=0. else $
   VHEL1=FLOAT(HB(30))+FLOAT(HB(31))/1000.
pix=dw*c*vcal                ;one pixel
mz=a(1)*pix-VHEL1+VHEL0  ;velocity
mw=a(2)*pix              ;width
print,'shift=',mz,' km/s; one pixel uncertainty= +/-',pix,' km/s'
print,'width=',mw,' km/s (uncalibrated)'
yb=x*a(4)+a(3)                                 ;linear background
if not keyword_set(flat) then yb=yb+x*x*a(5)
yd=y-yb
i1=xindex(x,a(1)-a(2))
i2=xindex(x,a(1)+a(2))
CENTRD,x,yd,0,i1,i2,XCEN
oplot,[xcen,xcen],!y.crange,color=75
dif=abs(a(1)-xcen)
sfmt='(F6.3)'
print,'fit: ',string(a(1),sfmt),' centroid: ',string(xcen,sfmt), $
      '  difference=',string(dif,sfmt),' pix => ',string(dif*pix,sfmt),' km/s'
if n_elements(delay) eq 1 then wait,delay
RETURN
END
