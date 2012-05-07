;***************************************************************************
pro ghrstoicur,file,h,nw,f,sn,rec,outfil=outfil,type=type,ddlink=ddlink, $
    drec=drec,title=title,helpme=helpme,nonlinear=nonlinear,stp=stp, $
    nostore=nostore,podps=podps,noplot=noplot,hcpy=hcpy,nowave=nowave, $
    debug=debug,readouts=readouts
if n_params(0) lt 1 then file='-1'
if string(file) eq '-1' then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* GHRStoICUR - convert calibrated .SCI data to ICUR format (type 10)'
   print,'* calling sequence: GHRStoICUR,file,h,w,f,e,rec'
   print,'*               or  GHRStoICUR,file,rec'
   print,'*    file:   name of .SCI file. Searches _R, _S. '
   print,'*            H prefix added if integer'
   print,'*    h,w,f:  standard vectors'
   print,'*    sn:     S/N vector (not epsilon vector)'
   print,'*    rec:    optional output record number in OUTFIL, def (-1) = next'
   print,'*  KEYWORDS:
   print,'*    ddlink: set if direct downlink data (type=2)'
   print,'*    drec  : type of data, def=ABS  (GRO, NET, RAW)'
   print,'*    hcpy  : set for hardcopy plot'
   print,'*    nonlinear : set to skip linearization of wavelength scale'
   print,'*    noplot  : set to avoid plotting to screen'
   print,'*    nostore : set to skip disk data storage'
   print,'*    outfil: optional output file name, default=GHRS.ICD '
   print,'*    podps  : set to use _S file'
   print,'*    readouts : use to select readouts 1-N, 0 to query'
   print,'*    title : title to be inserted into header'
   print,'*    type  : default=0 to cross correlate spectra, 1 to shift and add'
   print,' '
   return
   endif
;
if keyword_set(debug) then nostore=1
if keyword_set(debug) then stp=1
if keyword_set(nostore) and (n_params(0) lt 4) and (not keyword_set(stp)) $
       then begin
   bell
   print,' data will neither be passed not stored - Why bother?"
   print,' GHRSTOICUR: RETURNING'
   return
   endif
;
wfact=30000.D0
pdv=!d.name
dqlevel=0
if not keyword_set(type) then type=0              ;default to cross correlate
if keyword_set(ddlink) then type=2
if not keyword_set(drec) then drec='ABS'          ;default data type
if not keyword_set(outfil) then outfil='ghrs.icd'
if strupcase(drec) ne 'ABS' then dqlevel=100
if n_elements(h) eq 0 then h=-1
if n_params(0) le 4 then rec=h
if n_elements(rec) eq 0 then rec=-1
;
if not keyword_set(nostore) then print,' data to be written to ',outfil
;
if ifstring(file) ne 1 then file='H'+strtrim(long(abs(file)),2)   ;convert to string
;
in=-999
f=file
kred=strpos(f,'_')     ;-1 if no extension
if (kred eq -1) and (keyword_set(podps)) then begin
   file=file+'_s'
   f=file
   kred=strpos(f,'_')     ;-1 if no extension
   endif
if kred eq -1 then begin      ;look first for reduced data files
   f=file+'_r'
   fex=ffile('zdata:'+f+'.sci')
   if fex eq 1 then goto,readdata
   f=file+'_s'               ;try _S as second best
   fex=ffile('zdata:'+f+'.sci')
   if fex eq 1 then goto,readdata
   endif
fex=ffile('zdata:'+file+'.sci')       ;does specified file exist?
if fex eq 1 then goto,readdata
print,' cannot find file ',file,' with either _R or _S extensions in zdata'
return
;
readdata:
;
kred=strpos(f,'_')     ;-1 if no extension
hrs_open,f,in,'R','',log
obsmode=sxpar(log,'OBSMODE')
if strtrim(obsmode,2) eq 'DIRECT READOUT' then begin
   ddlink=1
   type=2
   endif
print,' Data from file ',f,'   Observing mode=',obsmode
print,' data specification= ',drec,'   Coadd type=',type,' DQLEVEL=',dqlevel
;
hrs_read,in,'wave',ihw,wave                        ;read wavelength vactor
if !version.arch eq 'alpha' then case 1 of
      not finite(mean(wave)): doswap=1
      not finite(total(wave)): doswap=1
      min(wave) lt 0.: doswap=1      
      max(wave) gt 1.e4: doswap=1
      else: doswap=0
      endcase else doswap=0
if doswap then print,' Swapping VAX to IEEE'
if doswap then vswap,wave,/quiet
hrs_read,in,drec,ih1,flux                          ;read flux vector
if doswap then vswap,flux,/quiet
vs=ih1(4,0)
ns=(size(flux))(2)
if strupcase(drec) ne 'NET' then begin
   hrs_read,in,drec+'/EPS',ihe,fluxeps
   if doswap then vswap,fluxeps,/quiet
   endif else fluxeps=flux*0+100                    ;read data quality vector
if (strupcase(drec) eq 'ABS') or (strupcase(drec) eq 'GRO') then begin
   hrs_read,in,drec+'/ERR',ihe,fluxerr 
   if doswap then vswap,fluxerr,/quiet
   endif else fluxerr=flux*0.   ;read error vector
hrs_close,in
;
if keyword_set(nowave) then begin
   nonlinear=1
   z=findgen(vs)+0.5
   wave=z
   for i=0,ns-2 do wave=[[wave],[z]]
   z=0
   dw=1.0
   endif
;
; is the header OK?
;
ks=strpos(strupcase(f),'_S')
if ks ne -1 then begin     ;use header from raw data because -S header bad
   hrs_open,strmid(f,0,ks),inraw
   hrs_read,inraw,'RAW',ihf
   hrs_close,inraw
   endif else ihf=ih1
;
s=size(flux)
tzr=''
nk=-1
if n_elements(readouts) ge 1 then begin
   readouts=readouts-1
   nfp=s(2)
   case 1 of
      n_elements(readouts) gt 1: begin
         k=where((readouts ge 0) and (readouts lt nfp),nk)
         if nk eq 0 then begin
            print,' You have entered an inappropriate list of records'
            print,' There are ',s(2),' readouts
            print,' specify a vector READOUTS containing the records to be coadded'
            stop,' >>>'
            if n_elements(readouts) lt 1 then return
            readouts=readouts-1
            endif 
         end
      n_elements(readouts) eq 1: begin
         if readouts lt 0 then begin
            print,' There are ',s(2),' readouts
            print,' specify a vector readouts containing the records to be coadded'
            stop,' >>>'
            endif
         end
      else:
      endcase
   k=where((readouts ge 0) and (readouts lt nfp),nk)
   readouts=readouts(k)
      print,' Inappropriate record list'
      return
      endif
   if nk eq 0 then begin
   flux=flux(*,readouts)
   fluxerr=fluxerr(*,readouts)
   wave=wave(*,readouts)
   ihf=ihf(*,readouts)
   if n_elements(readouts) eq 1 then tzr=' readout '+strtrim(readouts(0)+1,2) $
      else tzr=strtrim(n_elements(readouts),2)+' readouts selected'
   endif
;
if not keyword_set(title) then title=''
title=title+tzr
h=ghrsicurhead(ihf,flux,log,title)
;
;linearize wavelength vector
;
if not keyword_set(nonlinear) then begin
   dw=wave(1:*)-wave
   k=where(dw le 0.,cnt) & if cnt gt 0 then dw(k)=100.
   dw=min(dw)                ;minimum wavelength interval
   wmin=min(wave)
   wmax=max(wave)
   nb=fix((wmax-wmin)/dw)+1
   h(19)=fix(wfact)
   h(20)=fix(wmin)
   h(21)=fix((wmin-h(20))*wfact+0.5)
   h(22)=fix(dw)
   h(23)=fix((dw-h(22))*wfact+0.5)
   h(199)=333
   wmin=h(20)+h(21)/wfact & dw=h(22)+h(23)/wfact
   nw=wmin+dindgen(nb)*dw  ;linear wavelength vector
   print,wmin,wmax,dw,n_elements(nw)
   endif else begin
      nw=wave & dw=1.
   endelse
;
s=size(flux)
nfl=s(1)
if s(0) eq 2 then nfp=s(2) else nfp=1
if nfp le 1 then begin                ;single spectrum
   sn=flux/fluxerr
   f=flux
   w=wave
   if type eq 0 then print,' Carrousel is fixed - no cross correlations will be done'
;
   endif else begin             ;combine spectra
;
   case 1 of
      type eq 0: begin    ;cross correlate before adding
         print,' Individual readouts to be cross-correlated'
         print,' '
         if h(7)/nfl eq 1 then cut=50 else cut=100
         t=fltarr(2100)    ;100 bin pad
         good=intarr(2100)
         f=t & f(98)=flux(*,0)
         feps=t & feps(98)=fluxeps(*,0)             ;data quality flags
         ferr=t & ferr(98)=fluxerr(*,0) & ferr=ferr*ferr      ;sum of squares
         w=t-1. & w(98)=wave(*,0)
         tw=t-1.
         k=where(w gt 0.) & good(k)=good(k)+1
         w0=wave(*,0)
         f0=dqcheck(flux(*,0),fluxeps(*,0),dqlevel)
         print,"$(A1,' shifts:')",string(0b)
;
         for i=1,nfp-1 do begin
            f1=dqcheck(flux(*,i),fluxeps(*,i),dqlevel)
            crosscor,w0,f0,wave(*,i),f1,dw,xc,1,cut,m    ;m(1)=shift
; check m
            m=m(1)
            db=(w0(0)-wave(0,i))/dw
;print,'                           ',db,m
            if abs(m-db) gt 3 then m=db
            print,"$(A1,I5)",string(0b),-fix(m+0.5)
            m=98-fix(m+0.5)
            t=t*0. & t(m)=flux(*,i) & f=f+t     ;sum data
;            t=t*0. & t(m)=fluxerr(m:*,i) & ferr=ferr+t*t    ;sum noise ???????
            t=t*0. & t(m)=fluxerr(*,i) & ferr=ferr+t*t    ;sum noise
            tw=t*0.-1. & tw(m)=wave(*,i)                  ;current wavelengths
            k=where(tw gt 0.) & if k(0) ne -1 then good(k)=good(k)+1
            k=where((w eq -1.) and (ferr ge 0.))
            if k(0) ne -1 then w(k)=tw(k)
            endfor
         k=where(good gt 0,nk)
         if nk gt 0 then begin
            f=f(k) & ferr=ferr(k) & w=w(k) & good=good(k)
            endif
         kb=where(ferr le 0.) & if kb(0) ne -1 then ferr(kb)=1.
         ferr=sqrt(ferr)
         sn=abs(f)/ferr             ;s/n vector
         f=f/float(good)
         end
      type eq 1: begin      ;shift and add
         print,' Individual readouts to be shifted by respective wavelengths'
         f=nw*0. & ferr=f & w=nw
         good=fix(f)
         for i=0,nfp-1 do shadd,nw,good,wave(*,i),flux(*,i),fluxerr(*,i),f,ferr
         k=where(good gt 0)
         if k(0) ne -1 then begin
            f=f(k) & ferr=ferr(k) & good=good(k)
            endif
         kb=where(ferr le 0.) & if kb(0) ne -1 then ferr(kb)=1.
         sn=abs(f)/ferr             ;s/n vector
         f=f/float(good)
         end
      type eq 2: begin         ;direct downlink - straight addition
         k=where(fluxerr le 0.) & fluxerr(k)=1.
         f=sum(flux,1)/nfp
         sn=sqrt(sum(flux*flux/fluxerr/fluxerr,1))
         end
      endcase
   endelse
vs=n_elements(f)
print,' vector size =',vs
if keyword_set(debug) then stop
if not keyword_set(nonlinear) then begin
   f=interpol(f,w,nw)
   sn=interpol(sn,w,nw)
   h(199)=333
   endif
;
h(7)=fix(n_elements(f))
h(33)=30                     ;etype code
!p.title=''
if h(4) gt 0 then !p.title='H'+strtrim(h(4),2)
if n_elements(title) gt 0 then !p.title=!p.title+' '+title
if strlen(!p.title) le 1 then !p.title='GHRS to ICUR'
if keyword_set(hcpy) then begin
   sp,'ps' & noplot=0
   endif
if not keyword_set(noplot) then begin
   plot,nw,f
   if (!d.name eq 'PS') and (not keyword_set(hcpy)) then lplt else begin
      if keyword_set(hcpy) then begin
         if ifstring(hcpy) then lplt,pdv,file=hcpy else lplt,pdv
         endif
      endelse
   endif
if keyword_set(nonlinear) then nl=1 else nl=0
IF KEYWORD_SET(NOWAVE) THEN BEGIN
   nl=0
   nw=0.5+findgen(h(7))
   endif
if not keyword_set(nostore) then $
      kdat,outfil,h,nw,float(f),float(sn),rec,nonlinear=nl
if keyword_set(stp) then stop,' GHRStoICUR>>>'
return               
end
