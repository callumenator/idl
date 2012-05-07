;*************************************************************************
pro readusno,ra0,dec0,ras,decs,poserr,mag, $
  helpme=helpme,mounted=mounted,epoch=epoch, $
  stp=stp,out=out,rad=rad,plt=plt,J2000=J2000,hcpy=hcpy,find=find, $
  markcen=markcen,noplt=noplt,debug=debug,hmsdms=hmsdms,noprint=noprint, $
  inepoch=inepoch,a1=a1,minimal=minimal
common grid,scale,at,dt,ddec,dr,ep,acen,dcen,atnp,dtnp,xfudge,yfudge,dssastr
;common gsc,ram,decm,magm,cls,pe,magerr,id,sid,magband,plate,mult,filename
;common usno,ram,decm,bmag,rmag,zone,cd0,igsc,iprob
common usnocat,usno,usno1,cd0
if not keyword_set(helpme) then helpme=0
if (not keyword_set(file)) and (n_params(0) lt 1) then helpme=1
if helpme eq 1 then begin
   print,' '
   print,'* READUSNO - read USNO astrometric catalog from disc'
   print,'*    calling sequence: READUSNO,RA,DEC [,ras,decs,bmag,rmag]'
   print,'* 
   print,'*       RA,DEC: field center in decimal deg., may be passed as vector'
   print,'*       output is placed in common block usno'
   print,'*       optional output arguments:'
   print,'*          RAS, DECS: RA,DEC, of stars'
   print,'*          BMAG, RMAG: blue and red magnitudes of star
   print,'* '
   print,'*   KEYWORDS:'
   print,'*      A1:    set to use A1.0 disks, default = A2.0
   print,'*      EPOCH: epoch for positions, default=J2000'
   print,'*      FIND: execute FINDP when done'
   print,'*      HCPY: make hard copy plot'
   print,'*      HMSDMS: input coordinates as H,M,S,D,M,S or H,M,S,D,M or H,M,D,M'
   print,'*      INEPOCH: input epoch, default=J2000'
   print,'*      MINIMAL: if set, only position and magnitudes passed
   print,'*      PLT: set to plot stars on sky grid'
   print,'*      NOPLT: set to not plot stars on sky grid (default)'
   print,'*      OUT: set to send output to disk file, def name=USNOLST.USNO'
   print,'*      RAD: radius of field (decimal degrees), default=0.05 degree'
   print,'* '
   print,'*  note: the CD is refered to by the logical name CDR in VMS. Add to your'
   print,'*        LOGIN.COM file a statement to the effect of '
   print,'*        define/tran=(conc,term)/exec cdr sbast1$dka400:'
   print,' '
   return
   endif
;
ra=ra0 & dec=dec0
if n_elements(cd0) eq 0 then cd0=-1      ;current CD
if not keyword_set(stp) then stp=0
ihc=0
if not keyword_set(plt) then plt=0
if keyword_set(find) then plt=1
if keyword_set(noplt) then begin
   plt=0 & hcpy=0 & find=0
   endif
if ifstring(plt) then ihc=plt
if keyword_set(hcpy) or ifstring(hcpy) then begin
   ihc=hcpy
   plt=1
   endif
case 1 of
   ifstring(ihc) and (not keyword_set(out)): filename=ihc
   ifstring(out): filename=out
   else: filename='usnolst'
   endcase
;
if keyword_set(hmsdms) then begin
   if n_params(0) lt 3 then begin
      print,' You must specify at least 3 arguments when setting \hms'
      return
      end
   case n_params(0) of
   3: begin
      ra=hmstodeg(ra,dec) & dec=ras
      end
   4: begin
      ra=hmstodeg(ra,dec) & dec=dmstodeg(ras,decs)
      end
   5: begin
      ra=hmstodeg(ra,dec,ras) & dec=dmstodeg(decs,poserr)
      end
   else: begin
      ra=hmstodeg(ra,dec,ras) & dec=dmstodeg(decs,poserr,mag)
      end
   endcase
   endif
;
if n_elements(ra) eq 2 then begin
   ravect=1
   dec=ra(1) & ra=ra(0)
   endif else ravect=0
iprt=0
if keyword_set(out) then iprt=1
gsccd=getenv('CDR')
;
if n_elements(rad) eq 0 then rad=0.05
if rad le 0. then rad=0.05
if n_elements(inepoch) eq 1 then inep=inepoch else inep=2000. ; input epoch
if n_elements(epoch) eq 1 then ep=epoch else ep=2000. ; output epoch
;
if abs(inep-2000.) gt 0.01 then precess,ra,dec,inep,2000.  ;precess to J2000.
minra=ra-rad & if minra lt 0. then minra=minra+360.
maxra=ra+rad & if maxra gt 360. then maxra=maxra-360.
if minra gt maxra then iswap=1 else iswap=0
mindec=(dec-rad)>(-90.)
maxdec=(dec+rad)<90.
print,'RA range = ',string(minra,'(F7.3)'),string(maxra,'(F8.3)'), $
    ' DEC range = ',string(mindec,'(F8.3)'),string(maxdec,'(F8.3)') 
minra=minra/15. & maxra=maxra/15.
spd=((dec+90.)>0)<180.     ;south polar distance
minspd=(mindec+90.)>0     ;south polar distance
maxspd=(maxdec+90.)<180.  ;south polar distance
; which CD?
band1=fix(minspd*10.)/75
band2=fix(maxspd*10.)/75
nbands=(1+band2-band1)>1
print,'BANDS:',band1,band2,' NBANDS=',nbands
;
nstars=0
for icd=0,nbands-1 do begin
   bnd=band1+icd
   if icd gt 0 then begin
      usno_1=usno & usno1_1=usno1
      usno=0 & usno1=0
      endif
   cd=which_usno_cd(band=bnd,a1=a1)
   if cd ne cd0 then begin 
      if !version.os eq 'vms' then spawn,'dismount cdr'
      if !version.os_family eq 'unix' then spawn,'umount $CDR'
      bell
      z=' please insert USNO CD #'+strtrim(cd,2)+' and continue' 
      stop,z
      if !version.os eq 'vms' then spawn,'MOUNT/MEDIA=CDROM/OVER=ID CDR'
      if !version.os_family eq 'unix' then spawn,'mount $CDR'
      endif
   cd0=cd
   spd=fix(bnd*75)      ;south polar zone
   nst=rd_usno_cat(spd,minra,maxra,mindec,maxdec,minimal=minimal)
   nstars=nst+nstars
   print,nstars,' retained'
   if icd gt 0 then begin
      usno=[temporary(usno),usno_1]
      usno1=[temporary(usno1),usno1_1]
      endif
   endfor    ;icd
;
case iswap of
   0: k=where((usno.ra ge minra) and (usno.ra le maxra) and $
             (usno.dec ge mindec) and (usno.dec le maxdec),nk)
   else: k=where(((usno.ra ge minra) or (usno.ra le maxra)) and $
             (usno.dec ge mindec) and (usno.dec le maxdec),nk)
   endcase
print,nk,' stars left'
if nk gt 0 then begin
   usno=usno(k) & usno1=usno1(k)
   usno.ra=usno.ra*15.
;   ram=ram(k)*15. & decm=decm(k) 
;   bmag=bmag(k) & rmag=rmag(k) & zone=zone(k)
;   igsc=igsc(k) & iprob=iprob(k)
   endif ;else stop
;
racen=ra & deccen=dec
;
if abs(ep-2000.) gt 0.01 then begin
   precess,racen,deccen,2000.,ep
   precess,usno.ra,usno.dec,2000.,ep
   print,' data precessed to equinox ',ep
   endif
if iprt eq 1 then begin
   nk=n_elements(usno.ra)
   if not ifstring(out) then out='usnolst'
   if n_elements(out) eq 0 then out='usnolst'
   if get_ext(out) eq '' then ext='.usno' else ext=''
   filename=out+ext
   openw,lu,filename,/get_lun
   if keyword_set(a1) then zver='A1.0' else zver='A2.0'
   printf,lu,'*** USNO '+zver+' STAR LIST ***'
   degtohms,racen,h,m,s & degtodms,deccen,dd,dm,ds
   srad=string(rad,'(F6.2)') & sep=string(ep,'(F8.2)')
   printf,lu,h,m,s,dd,dm,ds,srad,sep, $
      format="(' Center @ ',I2,I3,F7.3,'  ',2I3,F7.3,' Rad= ',A6,' Epoch= ',A8)" 
   printf,lu,'     RA            Dec          B mag    R mag  G P'
   degtohms,usno.ra,h,m,s & degtodms,usno.dec,dd,dm,ds
   fmt="(2(I3,I3,F7.3,'  '),2F7.2,' ',2A1)"
   gscflg=strarr(nk)+' '
   kgsc=where(usno1.igsc lt 0,ngsc)
   if ngsc gt 0 then gscflg(kgsc)='*'
   probflg=strarr(nk)+' '
   kgsc=where(usno1.iprob gt 0,ngsc)
   if ngsc gt 0 then probflg(kgsc)='P'
   for i=0,nk-1 do printf,lu,h(i),m(i),s(i),dd(i),dm(i),ds(i), $
      usno(i).bmag,usno(i).rmag,gscflg(i),probflg(i),format=fmt
   close,lu & free_lun,lu
   print,' data are in ',filename
   endif
if keyword_set(plt) then begin
   if keyword_set(markcen) then begin
      ms=markcen
      plotstars,hcpy=ihc,markcen=[racen,deccen,ms],noprint=noprint,rad=rad
      endif else plotstars,hcpy=ihc,noprint=noprint,rad=rad
   endif
if keyword_set(find) then begin
   wshow
   findp
   endif
if n_params(0) gt 2 then begin
   ras=usno.ra & decs=usno.dec & poserr=usno.bmag & mag=usno.rmag
   endif
if keyword_set(stp) or keyword_set(debug) then stop,'READGSC>>>'
;
return
;
bail:
;ram=-1 & decm=-1
return  
end
