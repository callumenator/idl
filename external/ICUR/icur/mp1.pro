;***********************************************************************
pro mp1,file0,recs,scale0=scale0,lambda=lambda,offset=offset,exact=exact, $
      yt=yt,publ=publ,ymax=ymax,fmax=fmax, $
      label=label,color=color,helpme=helpme,ynz=ynz,date=date,norm=norm, $
      shft=shft,hcpy=hcpy,spt=spt,td=td,fftsmooth=fftsmooth,rectify=rectify, $
      mfact=mfact,subtr=subtr,noscale=noscale,ymin=ymin,stp=stp,marklam=marklam
;
common mp1shft,mshift
;
if not keyword_set(helpme) then begin
   if n_params(0) eq 0 then begin
      file=''
      read,' Enter file name, -1 for help',file
      endif else file=file0
   if file eq '-1' then helpme=1
   endif
;
if keyword_set(helpme) then begin
   print,' '
   print,'* MP1.PRO   -   multiple, scaled plots'
   print,'*    calling sequence: MP1,file,recs'
   print,'*    FILE:  data file name'
   print,'*    RECS:  input array of record numbers in FILE'
   print,'*'
   print,'* KEYWORDS:'
   print,'*    COLOR : set to color individual spectra, run GC first'
   print,'*    DATE  : set to label with date and time, =-1 to left-justify'
   print,'*    EXACT:      set to inhibit axis rounding'
   print,'*    FFTSMOOTH:   apply FFT smoothing'
   print,'*    HCPY:   set for hard copy plot, =name to save'
   print,'*    LABEL:      set to label spectrum, =-1 to left-justify (TD controls height)'
   print,'*    LAMBDA: 2 element vector containing wavelength limits for plot'
   print,'*    SCALE : 1 (def) to max, 2 to mean, 3 to |max|, 4 to 2 x max'
   print,'*            5 for median, <0 to scale to first record'
   print,'*    OFFSET:     plot offset, default=1.'
   print,'*    MARKLAM:    mark specified lambda(s) with dotted line'
   print,'*    NORM:       plot fractional residuals (SUBTR must be set)'
   print,'*    NOSCALE:    set to suppress scaling'
   print,'*    PUB:        if set, no OPDATE; set >1 to truncate labels'
   print,'*    RECTIFY:    rectify wavelength scales to first'
   print,'*    SHFT:       shift in wavelengths of spectra, def=0, -1 to mark'
   print,'*    SPT:        label with spectral types, =-1 to left-justify'
   print,'*    SUBTR:      vector to subtract from each line'
   print,'*    YMIN:       set !y.range(0)'
   print,'*    YNZ:        set to set YNOZERO plot keyword'
   print,'*    YT:         Y axis title'
   print,' '
   return
   endif
;
if n_elements(subtr) le 1 then norm=0
if n_elements(recs) lt 2 then begin
   res=0
   read,' Enter record numbers, -1 to end',recs
   r1=0
   if recs ne -1 then while r1 ne -1 do begin
      read,r1
      recs=[recs,r1]
      endwhile
   endif
if n_elements(recs) lt 2 then return
;
np=n_elements(recs)
if recs(np-1) eq -1 then recs=recs(0:np-2)
np=n_elements(recs)
;
if n_elements(publ) gt 0 then begin
   pub=publ
   nplab=pub
   case 1 of
      n_elements(nplab) eq 1:  nplab=nplab+intarr(np)
      n_elements(nplab) gt np: nplab=nplab(0:np-1)
      n_elements(nplab) lt np: nplab=[nplab,intarr(np-n_elements(pub))]
      else:
      endcase
   k=where(nplab le 1,nk) & if nk gt 0 then nplab(k)=0
   pub=1
   endif
;
recs=fix(recs)
file=file+'.ICD'
icurdata=getenv('icurdata')
if not ffile(file) then file=icurdata+file
if not ffile(file) then begin
   print,' File ',file,' not found in user directory or ',icurdata
   bell
   return
   endif
plabel=''
tdoff=1.3 & tdoff1=0.5
if n_elements(td) ne 0 then tdoff=td
if keyword_set(lambda) then begin
   if n_elements(lambda) lt 2 then lambda=[0.,0.]
   l1=lambda(0) & l2=lambda(1)
   endif else begin
   l1=0. & l2=0.
   endelse
if (l1 eq 0.) and (l2 eq 0.) then noxlim=1 else noxlim=0
if not keyword_set(offset) then d=1. else d=offset
if not keyword_set(scale0) then scale=1 else scale=scale0
if n_elements(scale) eq 2 then begin
   sclam=scale & scale=1
   if sclam(0) lt 0 then scale=-1
   sclam=abs(sclam)
   endif else sclam=0
lpos=0   ;right justified
if keyword_set(date) then label=date
if keyword_set(spt) then begin
   label=0
   if spt eq -1 then lpos=1
   endif
if n_elements(label) gt 0 then begin
   case 1 of
      label eq -1: lpos=1
      (label gt 0.) and (label lt 1.): lpos=label
      else: lpos=0
      endcase
   endif
if n_elements(fftsmooth) gt 0 then ffts=fftsmooth else ffts=0
ffts0=ffts
dev=!d.name
;
if n_elements(shft) ne 0 then begin
   if shft eq 1 and n_elements(mshift) ne np then begin
      print,' You must initialize the shifts by running MP1 with shft=-1'
      return
      endif
   endif else shft=0
;
if n_elements(shft) eq 1 then begin
   if shft eq -1 then ms=1 else ms=0
   endif else ms=0
if ms eq 1 then hcpy=0
;
if keyword_set(hcpy) then sp,'PS'
svp
minx=0. & maxx=1.+np*d
if keyword_set(noscale) then scale=99
if keyword_set(exact) then begin            ;set upper and lower limits
   gdat,file,h,w,f0,e,recs(0) & f=f0
   if n_elements(subtr) gt 0 then f=f-subtr
   if keyword_set(norm) then f=f/f0
   if n_elements(mfact) gt 0 then f=f*mfact
   if ffts gt 0 then begin
      if ffts eq 1 then fftsm,f,1 else fftsm,f,1,ffts
      ffts=ffts0
      endif
   case 1 of
      n_elements(sclam) eq 2: k=where((w ge sclam(0)) and (w le sclam(1)))
      noxlim: k=indgen(n_elements(w))
      else: k=where((w ge l1) and (w le l2))
      endcase
   case 1 of
      abs(scale) eq 1:     ft=max(f(k))      ;max level
      abs(scale) eq 2:     ft=mean(f(k))     ;mean level
      abs(scale) eq 3:     ft=max(abs(f(k))) ;max of abs(f)
      abs(scale) eq 4:     ft=0.5*max(f(k))  ;twice max level
      abs(scale) eq 5:     ft=fmedn(f(k))    ;median level
      scale eq 99:         ft=1.
      else:           ft=max(f(k))     ;max level
      endcase
   f=f/ft            ;normalize
   if keyword_set(lambda) then minx=(1.-d)<min(f(k)) else minx=(1.-d)<min(f) 
   gdat,file,h,w,f0,e,recs(np-1)
   f=f0
   if n_elements(subtr) gt 0 then f=f-subtr
   if keyword_set(norm) then f=f/f0
   if n_elements(mfact) gt 0 then f=f*mfact
   if ffts gt 0 then begin
      if ffts eq 1 then fftsm,f,1 else fftsm,f,1,ffts
      ffts=ffts0
      endif
   case 1 of
      n_elements(sclam) eq 2: k=where((w ge sclam(0)) and (w le sclam(1)))
      noxlim: k=indgen(n_elements(w))
      else: k=where((w ge l1) and (w le l2))
      endcase
   case 1 of
      abs(scale) eq 1:     ft=max(f(k))      ;max level
      abs(scale) eq 2:     ft=mean(f(k))     ;mean level
      abs(scale) eq 3:     ft=max(abs(f(k))) ;max of abs(f)
      abs(scale) eq 4:     ft=0.5*max(f(k))  ;twice max level
      abs(scale) eq 5:     ft=fmedn(f(k))    ;median level
      scale eq 99:         ft=1.
      else:           ft=max(f(k))     ;max level
      endcase
   f=f/ft            ;normalize
if ft le 0 then ft1=1
   if keyword_set(lambda) then mf=(np-1)*d+max(f(k)) else mf=(np-1)*d+max(f)
   maxx=(1.+np*d)>mf
   endif
xold=!x.range & yold=!y.range
if keyword_set(ymin) then minx=ymin
if keyword_set(ymax) then maxx=ymax
setxy,l1,l2,minx,maxx
;
xys=1.2
if not keyword_set(yt) then !y.title=ytit(0) else !y.title=yt
!x.title='!6Angstroms'
gdat,file,h,w0,f0,e,recs(0) & f=f0 & w=w0
if n_elements(subtr) gt 0 then f=f-subtr
if keyword_set(norm) then f=f/f0
plabel=strtrim(byte(h(100:159)>32),2)
sp=get_spt(plabel)
if keyword_set(date) then begin
   dtime=string(h(10),'(I2)')+'/'+string(h(11),'(I2)')+'/'
   dtime=dtime+string(h(12),'(I2)')+' '
   if h(13) lt 10 then zd=' ' else zd=''
   h13=strtrim(h(13),2)
   h14=h(14) & h14=string(h14,'(I2)')
   if h(14) lt 10 then h14='0'+string(h(14),'(I1)')
   plabel=dtime+zd+h13+':'+h14
   endif
if not keyword_set(label) then plabel=''
case 1 of
   n_elements(sclam) eq 2: k=where((w ge sclam(0)) and (w le sclam(1)))
   noxlim: k=where((w gt !x.crange(0)) and (w lt !x.crange(1)))
   else: k=where((w ge l1) and (w le l2))
   endcase
if k(0) eq -1 then  k=indgen(n_elements(f))-1
;if noxlim eq 1 then k=indgen(n_elements(f))-1
mk=max(k)
if ffts gt 0 then begin
   if ffts eq 1 then fftsm,f,1 else fftsm,f,1,ffts
   ffts=ffts0
   endif
case 1 of
   abs(scale) eq 1:     ft=max(f(k))      ;max level
   abs(scale) eq 2:     ft=mean(f(k))     ;mean level
   abs(scale) eq 3:     ft=max(abs(f(k))) ;max of abs(f)
   abs(scale) eq 4:     ft=0.5*max(f(k))  ;twice max level
   abs(scale) eq 5:     ft=fmedn(f(k))    ;median level
   scale eq 99:         ft=1.
   else:           ft=max(f(k))     ;max level
   endcase
ft0=ft
f=f/ft            ;normalize
if n_elements(fmax) eq 1 then f=f<fmax
c=-1
i=0
;
if keyword_set(ynz) then ynz=1 else ynz=0
if n_elements(mfact) gt 0 then f=f*mfact
if ffts gt 0 then begin
   if ffts eq 1 then fftsm,f,1 else fftsm,f,1,ffts
   ffts=ffts0
   endif
if keyword_set(exact) then plot,w,f,ystyle=1,xstyle=1,ynoz=ynz else $
      plot,w,f,ynoz=ynz
if strupcase(!d.name) eq 'X' then wshow
if nplab(0) gt 1 then plabel=strmid(plabel,0,nplab(0))
case 1 of
   lpos ge 1: wlab=!x.crange(0)
   lpos le 0: begin
      sl=strlen(plabel)+3
      dp=!p.position(2)-!p.position(0)
      dl=(!d.x_size*dp-sl*!d.X_CH_SIZE*xys)/(!d.x_size*dp)
      wlab=!x.crange(0)+dl*(!x.crange(1)-!x.crange(0))
      end
   else: wlab=!x.crange(0)+lpos*(!x.crange(1)-!x.crange(0))
   endcase
if d lt .01 then dx=(!y.crange(1)-(1.-d))/np/2. else dx=d
xyouts,wlab,1-d+tdoff*dx,'!6'+plabel,size=xys
if keyword_set(spt) then xyouts,!x.crange(1),1-d+tdoff1*dx,'!6 '+sp,size=xys
;
for i=1,np-1 do begin
   gdat,file,h,w,f0,e,recs(i) & f=f0
   if keyword_set(rectify) then begin
      f=[0.,0.,0.,f,0.,0.,0.]
      dw=w(1)-w(0)
      w=[dw*(indgen(3)-3)+w(0),w,max(w)+dw*(1+indgen(3))]
      f=interpol(f,w,w0)
      endif
   if n_elements(subtr) gt 0 then f=f-subtr
   if keyword_set(norm) then f=f/f0
   plabel=strtrim(byte(h(100:159)>32),2)
   sp=get_spt(plabel)
   if keyword_set(date) then begin
      dtime=string(h(10),'(I2)')+'/'+string(h(11),'(I2)')+'/'
      dtime=dtime+string(h(12),'(I2)')+' '
      if h(13) lt 10 then zd=' ' else zd=''
      h13=strtrim(h(13),2)
      if h(14) lt 10 then $
         h14='0'+string(h(14),'(I1)') else h14=string(h(14),'(I2)')
      plabel=dtime+zd+h13+':'+h14
      endif
   if not keyword_set(label) then plabel=''
   if nplab(i) gt 1 then plabel=strmid(plabel,0,nplab(i))
   if shft eq 1 then w=w-mshift(i)
   case 1 of
      n_elements(sclam) eq 2: k=where((w ge sclam(0)) and (w le sclam(1)))
      noxlim: k=where((w gt !x.crange(0)) and (w lt !x.crange(1)))
      else: k=where((w ge l1) and (w le l2))
      endcase
   if k(0) eq -1 then  k=indgen(n_elements(f))-1
;   if noxlim eq 1 then k=indgen(n_elements(f))-1
   mk=max(k)
   if ffts gt 0 then begin
      if ffts eq 1 then fftsm,f,1 else fftsm,f,1,ffts
      ffts=ffts0
      endif
   case 1 of
      scale lt 0:     ft=ft0
      scale eq 1:     ft=max(f(k))      ;max level
      scale eq 2:     ft=mean(f(k))     ;mean level
      scale eq 3:     ft=max(abs(f(k))) ;max of abs(f)
      scale eq 4:     ft=0.5*max(f(k))  ;twice max level
      scale eq 5:     ft=fmedn(f(k))    ;median level
      scale eq 99:    ft=1.
      else:           ft=max(f(k))      ;max level
      endcase
   f=f/ft            ;normalize
   if n_elements(fmax) eq 1 then f=f<fmax
   !c=-1
   if keyword_set(color) then c=i*10+5 else c=!p.color
   if n_elements(mfact) gt 0 then f=f*mfact

   oplot,w,f+i*d,color=c
   xyouts,wlab,1-d+i*dx+tdoff*dx,'!6'+plabel,size=xys,color=c
 if keyword_set(spt) then xyouts,!x.crange(1),1-d+(i+tdoff1)*dx,'!6 '+sp,size=xys
   endfor
if ms eq 1 then begin
   mshift=fltarr(np)
   print,' select line and mark X position. Start with lowest plot'
   cursor,x,y,/down & x0=x & mshift(0)=0.
   print,x
   for i=1,np-1 do begin
      print,' Mark spectrum ',i,':'
      cursor,x,y,/down
      print,x
      mshift(i)=x-x0
      endfor
   print,mshift
   print,' Now rerun MP1 with /SHFT'
   endif
;
if n_elements(marklam) gt 0 then begin
   for i=0,n_elements(marklam)-1 do begin
      oplot,[marklam(i),marklam(i)],!y.crange,linestyle=1
      endfor
   endif
;
case 1 of
   keyword_set(pub):
   not keyword_set(spt): opdate,'MP1'
   else:
   endcase
if ifstring(hcpy) eq 1 then lplt,dev,file=hcpy else lplt,dev
if keyword_set(stp) then stop,'MP1>>>'
setxy,xold(0),xold(1),yold(0),yold(1)
return
end
