;****************************************************************************
pro combine,infile,inrec,outfile,outrec,average=average,noscale=noscale, $
            sumup=sumup,examine=examine,helpme=helpme,stp=stp,edit=edit, $
            xcorx=xcorx,nosave=nosave,title=title   ;,etype=etype,sigma=sigma
if keyword_set(helpme) then begin
   print,' '
   print,'* COMBINE - combine 3 or more spectra with median filtering'
   print,'*           averages 2 spectra'
   print,'*    calling sequence: COMBINE,infile,inrec,outfile,outrec'
   print,'*       INFILE:  input .ICD file'
   print,'*       INREC:   array of record numbers to combine'
   print,'*       OUTFILE: output .ICD file, default=INFILE'
   print,'*       OUTREC:  output record, default=next free record'
   print,'*'
   print,'*    KEYWORDS:'
   print,'*       AVERAGE: use averaging, not median filtering'
;   print,'*       ETYPE:   set to force ETYPE when .ICD file is created'
   print,'*       EXAMINE: examine data at all stages.'
   print,'*       NOSCALE: do not scale flux vectors'
;   print,'*       SIGMA:   sigma limit for median filtering
   print,'*       SUMUP:   sum all flux, no scaling - weights by exp. time'
   print,'*       TITLE:   new title for combined spectrum'
   print,'*       XCOR: set to cross-correlate, pass wavelength band, def=all'
   print,' '
   return
   endif
;
if keyword_set(edit) then examine=1
if n_elements(infile) eq 0 then begin
   infile=''
   read,' Enter name of .ICD file: ',infile
   endif
if n_elements(inrec) eq 0 then begin
   inrec=-1 & ii=0
   print,' Enter list of record numbers, -1 to end'
   while ii ge 0 do begin
      read,'>>',ii
      inrec=[inrec,ii]
      endwhile
   k=where(inrec ge 0,nk)
   if nk lt 2 then begin
      print,' Fewer than 2 records specified - returning'
      return
      endif
   inrec=inrec(k)
   endif
if n_elements(outfile) eq 0 then outfile=infile
if n_elements(outrec) eq 0 then outrec=-1
nrec=n_elements(inrec)
if nrec lt 2 then begin
   print,' Fewer than 2 records specified - returning'
   return
   endif 
;
gdat,infile,h,w0,f,e,inrec(0)
if keyword_set(examine) then begin
   plot,w0,f,/ynoz
   wshow
   endif
if keyword_set(xcorx) then begin
   if n_elements(xcorx) eq 1 then xcorx=[w0(0),max(w0)]
   xa=xcorx(0)>w0(0)
   xb=xcorx(1)<max(w0)
   xcorx=[xa,xb]
   if xcorx(0) ge xcorx(1) then xcorx=[w0(0),max(w0)]
   xcorx=xindex(w0,xcorx)
   w1=w0(xcorx(0):xcorx(1))
   endif
ft=f*h(5)                   ;flux
epstype=h(33)
taccum=f*0.+h(5)
if (epstype eq 30) or (epstype eq 40) then begin
   kz=where(e eq 0.,nkz) & if nkz gt 0 then taccum(kz)=0.
   endif
funs=ft
np=h(7)
kp=indgen(np/2)+np/4            ;middle half of vector for scaling
tf=total(f(kp))
h0=h
h0(9)=1
darr=fltarr(np,nrec) & earr=darr
darr(0,0)=f & earr(0,0)=e
darr1=darr
scalef=fltarr(nrec)+1.
;
for i=1,nrec-1 do begin
   gdat,infile,h,w,f,e,inrec(i)
   tac=f*0.+h(5)
   if (epstype eq 30) or (epstype eq 40) then begin
      kz=where(e eq 0.,nkz) & if nkz gt 0 then tac(kz)=0.
      endif
   taccum=taccum+tac
   f=interpol(f,w,w0)                      ;INTERPOLATE TO FIRST SCALE
   e=interpol(e,w,w0)
   funs=funs+f*h(5)                   ;total flux
   darr1(0,i)=f
   if keyword_set(xcorx) then begin        ;cross-correlate for residual shifts
      npx=N_ELEMENTS(w1)/3
      crosscor,w1,ft(xcorx(0):xcorx(1)),w1,f(xcorx(0):xcorx(1)),dw,xc,1,npx
      x=indgen(2*npx+1)-npx
      mxc=max(xc)
      xcen=X(where(xc eq mxc))
      a=[mxc,xcen,2.,0.]
      y=gaussfit(x,xc,a,order=2)
      zdw=' shift='+strtrim(a(1),2)
      f=shift(f,-a(1))
      e=shift(e,-a(1))
      endif else zdw=''
   ft=ft+f*h(5)                   ;total flux
   scalef(i)=tf/total(f(kp))
   darr(0,i)=f & earr(0,i)=e
   h0(5)=h0(5)+h(5)                   ;increment time
   h0(9)=h0(9)+1
   if keyword_set(examine) then begin
      print,' Record',string(i,'(I3)'), $
         ':  scale factor= ',scalef(i),' Accum time= ',h0(5),zdw
      if not keyword_set(noscale) then sf=scalef(i) else sf=1.
      oplot,w0,f*sf
      endif
   endfor   
if keyword_set(edit) then stop,' Edit data now'
;
if (epstype eq 0) and (not keyword_set(sumup)) then average=1
if (nrec eq 2) and (not keyword_set(sumup)) then average=1
;
if keyword_set(noscale) then scale=0 else scale=1         ;scaling turned off
;
if scale eq 1 then for i=1,nrec-1 do begin                ;scale flux vector
   f=darr(*,i)*scalef(i)
   darr(0,i)=f
   endfor
kz=where(taccum eq 0,nkz) & if nkz gt 0 then taccum(kz)=1    ;accumulated time
fbar=total(darr,2)/nrec*h0(5)/taccum     ;average flux
;
if keyword_set(examine) then begin
   if not keyword_set(sumup) then sumup=0
   if not keyword_set(average) then average=0
   if not keyword_set(noscale) then noscale=0
   print,'Average:',average,' Sumup:',sumup,' Noscale:',noscale,' Etype:',epstype
   endif
;
case 1 of
   keyword_set(sumup):   f=ft/taccum             ;total flux
   keyword_set(average): f=fbar                 ;average flux
   else: begin                                  ;median filter
      f=medarr(darr)                           ;median array
      end
   endcase
;
case 1 of             ;coadd errors
   epstype eq 30: begin    
      e=sqrt(total(earr*earr,2))         ;s/n vector
      end
   else: begin
      e=fltarr(np)
      for i=0,np-1 do e(i)=f(i)/(stddev(darr(i,*))>1.e-25)   ;standard deviation
      h0(33)=30
      end
   endcase
;
if nkz gt 0 then begin
   f(kz)=0 & e(kz)=0
   endif
;
if keyword_set(examine) then begin
   gc,13
   oplot,w0,f,color=5
   erbar,2,f,f/e,w0,color=1
   wshow
   endif
;
if n_elements(title) gt 0 then begin
    bt=[fix(byte(title)),intarr(60)] & bt=bt(0:59)
    h0(100)=bt
   endif
;
if not keyword_set(nosave) then kdat,outfile,h0,w0,f,e,outrec    ;,epstype=etype
;
if keyword_set(stp) then stop,'COMBINE>>>'
return
end
