;**********************************************************************
pro stis_to_icd,files,all=all,plt=plt,icdfile=icdfile,append=append, $
    stp=stp,helpme=helpme
if (n_elements(files) eq 0) and not keyword_set(all) then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* STIS_TO_ICD - convert data in STIS *_X1D files to ICD format '
   print,'* calling sequence: STIS_TO_ICD,files'
   print,'*    FILES: names of *_x1d.fits files to use (overridden by /ALL)'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    ALL:     if set, read all *_x1d.fits files in directory'
   print,'*    APPEND:  if set, append output to named .ICD file'
   print,'*    ICDFILE: name of output file, def=STIS.ICD'
   print,'*    PLT:     set to plot orders as they are processed'
   print,' '
   return
   endif
;
if keyword_set(all) then files=getfilelist('*_x1d.fits',/noext)
if n_elements(icdfile) eq 0 then icdfile='STIS'
if ifstring(append) and icdfile eq 'STIS' then icdfile=append
if keyword_set(plt) then gc,13
if n_elements(stp) eq 0 then stp=0
nf=n_elements(files)
;
k=strpos(strupcase(files(0)),'_X1D',0)
if k gt 0 then root=strmid(files(0),0,k) else root=files(0)
read_x1d,w,f,err,dq,root=root,head=h0
t0=sxpar(h0,'exptime')
if t0 le 0 then t0=getval('texptime',h0,/noap)
t00=t0
f=f*(t0>0.1) & err=err*(t0>0.1)                          ;units of erg/cm2/A
s=size(w)
np=s(1)
nord=s(2)     ;number of orders
;
if nf gt 1 then for ifiles=1,nf-1 do begin
   k=strpos(strupcase(files(ifiles)),'_X1D',0)
   if k gt 0 then root=strmid(files(ifiles),0,k) else root=files(ifiles)
   print,root
   read_x1d,w1,f1,err1,dq1,root=root,head=h1
   if n_elements(h1) le 1 then goto,skipfile
   t1=sxpar(h1,'exptime')
   if t1 le 0 then t1=getval('texptime',h1,/noap)
   f1=f1*t1 & err1=err1*t1                    ;units of erg/cm2/A
   t0=t0+t1
   for iord=0,nord-1 do begin           ;rectify orders   
      vmerge,0,w(*,iord),f(*,iord),err(*,iord), $
             0,w1(*,iord),f1(*,iord),err1(*,iord), $
             h,ww,ff,ee,etype=40
      s=size(ww) & s=s(1)
      case 1 of
         s gt np: begin
            ww=ww(0:np-1)
            ff=ff(0:np-1)
            ee=ee(0:np-1)
            end
         s lt np: begin
            pad=fltarr(np-s)
            ww=[ww,ww(s-1)+(ww(1)-ww(0))*findgen(np-s)]
            ff=[ff,pad]
            ee=[ee,pad]
            end
         else:
         endcase
      if keyword_set(plt) then begin
         setxy
         plot,w(*,iord),f(*,iord)/t00,title='order:'+strtrim(iord,2)
         oplot,w1(*,iord),f1(*,iord)/t1,color=1
         oplot,ww,2.*ff/t0,color=5
         if stp ge 2 then stop,'STIS_TO_ICD>>>'
         endif
      w(*,iord)=ww
      f(*,iord)=2.*ff    ;*2 because vmerge averages
      err(*,iord)=2.*ee
      endfor              ;iord
   skipfile:
   endfor                 ;ifiles
f=float(f/t0) & err=float(err/t0)
;
; write ICD file
print,' Writing file ',icdfile+'.ICD'
if keyword_set(stp) then stop,'STIS_TO_ICD>>>'
head=intarr(512)
head(3)=110            ;stis
if t0 lt 32767. then head(5)=fix(t0) else head(5)=-fix(t0/60.)
head(6)=1
head(7)=np
d=getval('date-obs',h0,/noap)              ;date
if ifstring(d) then begin
   if strlen(d) le 8 then dfmt=1 else dfmt=0
   if dfmt then begin
      if strlen(d) eq 7 then d=' '+d
      head(10)=fix(strmid(d,3,2)) & head(11)=fix(strmid(d,0,2))
      head(12)=fix(strmid(d,6,2))
      endif else begin
      head(10)=fix(strmid(d,5,2)) & head(11)=fix(strmid(d,8,2))
      head(12)=fix(strmid(d,0,4))
      endelse
   print,d,head(10:12)
   endif
d=getval('time-obs',h0,/noap)              ;UT
if strtrim(d,2) eq '-1' then d=getval('ttimeobs',h0,/noap)
if ifstring(d) then begin
   head(13)=fix(strmid(d,0,2)) & head(14)=fix(strmid(d,3,2))
   head(15)=fix(strmid(d,6,2))
   print,d,head(13:15)
   endif
head(19)=30000
head(33)=40
head(100)=fix(byte(sxpar(h0,'targname'))>32b)
head(199)=333
;
for i=0,nord-1 do begin
  if (i eq 0) and not keyword_set(append) then newf=1 else newf=0
  j=nord-1-i
  w0=w(0,j)
  dw=(w(100,j)-w(0,j))/100.
  head(20)=fix(w0) & head(21)=head(19)*(w0-fix(w0))
  head(22)=fix(dw) & head(23)=head(19)*(dw-fix(dw))
  kdat,icdfile,head,w(*,j),f(*,j),err(*,j),/islin,epstype=40,newfile=newf
  endfor
if keyword_set(stp) then stop,'STIS_TO_ICD>>>'
return
end
