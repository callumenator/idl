;******************************************************************************
pro fits_icur,files,out=out,examine=examine,helpme=helpme,stp=stp,bins=bins, $
              nosave=nosave,plt=plt,etype=etype,debug=debug,reduce=reduce
if not ifstring(files) then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* FITS_ICUR - convert one-D spectra in .FITS files to ICD format'
   print,'*    calling sequence: FITS_ICUR,files'
   print,'*       files: list of input file names'
   print,'* '
   print,'*    KEYWORDS:'
   print,'*       BINS:    bin limits (2 element vector)'
   print,'*       OUT:     name of output .ICD file'
   print,'*       PLT:     set to plot spectra'
   print,'*       EXAMINE: set to examine data'
   print,'*       NOSAVE:  set to bypass .ICD file'
   print,' '
   return
   endif
;
if n_elements(files) eq 0 then files=getfilelist('*.fits')
if (n_elements(files) eq 1) and (files(0) eq '*') then $
         files=getfilelist('*.fits')
nf=n_elements(files)    ;number of files
if keyword_set(out) then icdf=out else icdf='fits'
if strlen(get_ext(icdf)) eq 0 then icdf=icdf+'.icd'
if keyword_set(bins) then begin
   case 1 of
      n_elements(bins) ne 2: begin
         bins=0 & examine=1
         end
      else: bins(0)=bins(0)>0
      endcase
   endif   
npmax=32767
;
for i=0,nf-1 do begin             ;loop through files
   file=files(i)
   if strlen(get_ext(file)) eq 0 then file=file+'.fits'
   data=readfits(file,h)
   np=fix(getval('naxis1',h))          ;number of points
   nv=fix(getval('naxis',h))           ;number of vectors
   eps=100
   case 1 of                           ;extract flux vector
      nv eq 1: flux=data(*)
      nv eq 2: flux=data(*,0)
      nv eq 3: begin
         n3=fix(getval('naxis3',h))    ;number of vectors
         flux=data(*,0,0)
         de=data(*,0,n3-1)
         k=where(de le 0.,nk)
         if nk gt 0 then de(k)=1.
         eps=flux/de         ;snr
         if nk gt 0 then eps(k)=0.
         end
      endcase
   case 1 of
      strupcase(getval('ctype1',h,/noap)) eq 'MULTISPE': begin
         ww=getval('wat2_001',h,/noap)
         k=strpos(ww,'1 1 0 ')
         ww=strmid(ww,k+6,60)
         k=strpos(ww,' ')
         w0=double(strmid(ww,0,k)) & dw=double(strmid(ww,k,24))
         end
      strupcase(getval('ctype1',h,/noap)) eq 'LINEAR': begin
         w0=double(getval('crval1',h)) & dw=double(getval('cd1_1',h))
         if dw le 0. then dw=double(getval('cdelt1',h))
         end
      else: begin
         print,' ERROR: unknown CTYPE = ',getval('ctype1',h)
         stop
         return
         end
      endcase
if keyword_set(debug) then stop
;
; fill in header
   title=''
   tel=strtrim(getval('OBSERVAT',h,/noap),2)
   instr=strtrim(getval('instrume',h,/noap),2)
   if strupcase(tel) eq 'EUVE' then ieuve=1 else ieuve=0
   head=intarr(512)
   case 1 of
      ieuve: begin
             head(3)=80
             title=tel+' '+instr+' '+strtrim(getval('irafname',h,/noap),2)
             end
      strupcase(getval('detector',h,/noap)) eq 'GCAM': head(3)=10 
      else: head(3)=11
      endcase
   time=double(getval('exptime',h))
   if time lt 32767. then head(5)=fix(time) else head(5)=-fix(time/60.)
   head(6)=1
   head(7)=np
   d=getval('date-obs',h,/noap)              ;date
   if ifstring(d) then begin
      head(10)=fix(strmid(d,3,2)) & head(11)=fix(strmid(d,0,2))
      head(12)=fix(strmid(d,6,2))
      print,d,head(10:12)
      endif
   if ifstring(d) then begin
      d=getval('ut',h,/noap)              ;UT
      head(13)=fix(strmid(d,0,2)) & head(14)=fix(strmid(d,3,2))
      head(15)=fix(strmid(d,6,2))
      print,d,head(13:15)
      endif
   if ifstring(d) then begin
      d=getval('st',h,/noap)              ;ST
      head(16)=fix(strmid(d,0,2)) & head(17)=fix(strmid(d,3,2))
      head(18)=fix(strmid(d,6,2))
      print,d,head(16:18)
      endif
   head(19)=30000
   head(20)=fix(w0) & head(21)=head(19)*(w0-fix(w0))
   head(22)=fix(dw) & head(23)=head(19)*(dw-fix(dw))
   head(199)=333
print,w0,dw,head(20:23)
   if nv eq 3 then head(33)=30 else head(33)=0
   d=getval('ra',h,/noap)              ;RA
   if ifstring(d) then begin
      head(40)=fix(strmid(d,0,2)) & head(41)=fix(strmid(d,3,2))
      head(42)=fix(strmid(d,6,4)*100.)
      print,d,head(40:42)
      d=getval('dec',h,/noap)              ;DEC
      sign=strmid(d,0,1)
      if sign ne '-' then d='+'+d
      head(43)=fix(strmid(d,0,3)) & head(44)=fix(strmid(d,4,2))
      head(45)=fix(strmid(d,7,4)*100.)
      print,d,head(43:45)
      endif
; compute HA
   dra=hmstodeg(head(40),head(41),head(42)/100.)
   dst=hmstodeg(head(16),head(17),head(18))
   dha=dst-dra & if dha lt -180. then dha=360.-dha
   degtohms,dha,ha1,ha2,ha3
   head(46)=fix(ha1) & head(47)=fix(ha2) &    head(48)=fix(ha3*100.)
print,dha,ha1,ha2,ha3,head(46:48)
   airmass=float(getval('airmass',h))
   if ieuve then airmass=0.
   head(49)=fix(100.*airmass)
print,'airmass: ',airmass,head(49)
   title=title+getval('object',h,/noap)
   k=strpos(title,'- Aperture')
   if k gt 0 then title=strmid(title,0,k-1)
   title=title+'                                                           '
   title=strmid(title,0,59)
   head(100)=byte(title)
print,title          ;,string(byte(head(100:159)))
;
   wave=w0+dw*findgen(np)
   npmax=npmax<n_elements(flux)
   if (keyword_set(examine)) or (keyword_set(plt)) then begin
      npmax=npmax<n_elements(flux)
      plot,wave,flux,title=file+': '+strtrim(title,2)
      if !d.name eq 'X' then wshow
      if keyword_set(bins) then begin
         b1=bins(1)<n_elements(flux)
         oplot,[wave(bins(0)),wave(bins(0))],!y.crange,ps=0
         oplot,[wave(b1),wave(b1)],!y.crange,ps=0
         endif
      if keyword_set(examine) then begin
         stop,' FITS_ICUR:  examine data, type .CON when done'
         endif
      npmax=npmax<n_elements(flux)
      endif 
;
   if keyword_set(bins) then begin
      b1=bins(1)<n_elements(flux)
      wave=wave(bins(0):b1)
      flux=flux(bins(0):b1)
      if n_elements(eps) ge b1 then eps=eps(bins(0):b1)
      npmax=npmax<n_elements(flux)
      head(6)=fix(bins(0))
      head(7)=n_elements(flux)
      endif
;
   if n_elements(flux) gt npmax then begin           ;truncate
      wave=wave(0:npmax-1)
      flux=flux(0:npmax-1)
      if n_elements(eps) ge (npmax-1) then eps=eps(0:npmax-1)
      head(7)=npmax
      endif
   if keyword_set(reduce) then begin
      case 1 of
         ieuve: begin
                caldir='udisk:[fwalter.euve]'
                eafile=caldir+instr+'1ea.tbl'
                openr,lu,eafile,/get_lun
                wea=0. & ea=0.
                genrd,lu,wea,ea
                free_lun,lu
                fea=interpol(ea,wea,wave)
                flux=flux/time/fea
                ew=1.986E-8/wave      ;hc/lambda
                flux=flux*ew          ;convert photons to ergs
                if (keyword_set(examine)) or (keyword_set(plt)) then $
                   plot,wave,flux,title=strtrim(title,2)
                end
         else:
         endcase
      endif
      if not keyword_set(nosave) then begin
      if keyword_set(etype) then $
         kdat,icdf,head,wave,flux,eps,-1,/islin,epstype=etype else $
         kdat,icdf,head,wave,flux,eps,-1,/islin
      endif
   endfor
;
if keyword_set(stp) then stop
return
end
