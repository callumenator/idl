;*************************************************************************
pro readgsc,ra,dec,ras,decs,poserr,mag,cl, $
  helpme=helpme,mounted=mounted,class=class,savedata=savedata,epoch=epoch, $
  stp=stp,file=file,out=out,rad=rad,plt=plt,J2000=J2000,hcpy=hcpy,find=find, $
  markcen=markcen,noplt=noplt,debug=debug,hmsdms=hmsdms,noprint=noprint, $
  inepoch=inepoch
common grid,scale,at,dt,ddec,dr,ep,acen,dcen,atnp,dtnp,xfudge,yfudge,dssastr
common gsc,ram,decm,magm,cls,pe,magerr,id,sid,magband,plate,mult,filename
if not keyword_set(helpme) then helpme=0
if (not keyword_set(file)) and (n_params(0) lt 1) then helpme=1
if helpme eq 1 then begin
   print,' '
   print,'* READGSC - read HST Guide Star catalog from disc'
   print,'*    calling sequence: READGSC,RA,DEC [,ras,decs,poserr,mag,cl]'
   print,'* 
   print,'*       RA,DEC: field center in decimal deg., may be passed as vector'
   print,'*       output is sent to GSC.LST if 2 or fewer arguments are given,'
   print,'*             or if OUT keyword is specified'
   print,'*       optional arguments:
   print,'*          RAS,DECS,POSERR: RA,DEC,position err of stars'
   print,'*          MAG: magnitude of star
   print,'*          CL: class of star
   print,'* '
   print,'*   KEYWORDS:'
   print,'*      CLASS: acceptable values for class'
   print,'*      EPOCH: epoch for positions, default=J2000'
   print,'*      FILE: read SDAS file on disk; no need for CD'
   print,'*      FIND: execute FINDP when done'
   print,'*      HCPY: make hard copy plot'
   print,'*      HMSDMS: input coordinates as H,M,S,D,M,S or H,M,S,D,M or H,M,D,M'
   print,'*      INEPOCH: input epoch, default=J2000'
;   print,'*      J2000: if EPOCH not 2000, set to return epoch 2000 positions'
;   print,'*             otherwise positions are precessed to EPOCH'
   print,'*      PLT: set to plot stars on sky grid (default)'
   print,'*      NOPLT: set to not plot stars on sky grid'
   print,'*      OUT: set to send output to disk file, def name=GSCLST.GSC'
   print,'*      RAD: radius of field (decimal degrees), default=0.1 degree'
   print,'*      SAVEDATA: if not set, the .HHH and HHD files will be deleted'
   print,' '
   return
   endif
;
if not keyword_set(stp) then stp=0
ihc=0
if not keyword_set(plt) then plt=1
if keyword_set(find) then plt=1
if keyword_set(noplt) then begin
   plt=0 & hcpy=0
   endif
if keyword_set(plt) then begin
   if ifstring(plt) then ihc=plt
   endif
if keyword_set(hcpy) then begin
   ihc=hcpy
   plt=1
   endif
case 1 of
   ifstring(ihc) and (not keyword_set(out)): filename=ihc
   ifstring(out): filename=out
   else: filename='gsclst'
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
;
if !version.os eq 'vms' then begin
   sep1='[' & sep2=']' & sep2='.'
   endif else begin
   sep1='/' & sep2='/' & sep3='/'
   endelse
if keyword_set(out) then iprt=1
gsccd=getenv('CDR')
if !version.os eq 'vms' then k=strpos(gsccd,':') else k=strlen(gsccd)-2
gsctables=strmid(gsccd,0,k+1)+sep1+'tables'+sep2+'regions.tbl'
gsccd=strmid(gsccd,0,k+1)+sep1+'gsc'
if not keyword_set(rad) then rad=0.1
if rad le 0. then rad=0.1
if n_elements(inepoch) eq 1 then inep=inepoch else inep=2000. ; input epoch
if n_elements(epoch) eq 1 then ep=epoch else ep=2000. ; output epoch
nkr=1
if keyword_set(file) then savedata=1
if keyword_set(file) then goto,readfile
;
mnd=-90.+7.5*indgen(24)                   ; info on region limits
mxd=mnd+7.5
zones=75*indgen(12)
k=2*indgen(6)+1
zones(k)=zones(k)-2
zones=strtrim(zones*10,2)
k=where(strlen(zones) eq 1,c) & if c gt 0 then zones(k)='000'+zones(k)
k=where(strlen(zones) eq 2,c) & if c gt 0 then zones(k)='00'+zones(k)
k=where(strlen(zones) eq 3,c) & if c gt 0 then zones(k)='0'+zones(k)
zones=['n'+zones,'s'+zones]
regs=[1,594,1178,1729,2259,2781,3246,3652,4014,4294,4492,4615,4663,5260,5838]
regs=[regs,6412,6989,7523,8022,8464,8840,9134,9346,9490,9537]
nregs=regs(1:*)-regs
kreg=[23-indgen(12),indgen(12)]
;
if abs(inep-2000.) gt 0.01 then precess,ra,dec,inep,2000.  ;precess to J2000.
minra=ra-rad & if minra lt 0. then minra=minra+360.
maxra=ra+rad & if maxra gt 360. then maxra=maxra-360.
if minra gt maxra then iswap=1 else iswap=0
mindec=(dec-rad)>(-90.)
maxdec=(dec+rad)<90.
print,'RA range = ',minra,maxra,' DEC range = ',mindec,maxdec
d=mindec-mnd
k=where(d eq min(d(where(d ge 0.))))    ;minimum index
kmin=k(0)
d=mxd-maxdec
k=where(d eq min(d(where(d ge 0.))))    ;maximum index
kmax=k(0)
nr=1+kmax-kmin                          ;number of regions
k1=kreg(kmin) & k2=kreg(kmax)
;print,' regions: ',kmin,kmax,' -> ',k1,k2 
kr=regs(k1)-1+indgen(nregs(k1))
if nr gt 1 then kr=[kr,regs(k2)+indgen(nregs(k2))]
if nr gt 2 then begin
   for i=0,nr-2 do begin
      kk=kreg(kmin+1+i)
      kr=[kr,regs(kk)+indgen(nregs(kk))]
      endfor
   endif
print,' searching file boundaries'
;
on_ioerror,nocd
d=readfits(gsctables,h,ext=1)
on_ioerror,null
;
a1=ftget(h,d,2,kr) & a2=ftget(h,d,3,kr) & a3=ftget(h,d,4,kr)
ralow=hmstodeg(a1,a2,a3)
a1=ftget(h,d,5,kr) & a2=ftget(h,d,6,kr) & a3=ftget(h,d,7,kr)
rahigh=hmstodeg(a1,a2,a3) 
a3=ftget(h,d,8,kr) & a1=ftget(h,d,9,kr) & a2=ftget(h,d,10,kr)
decl=float(a1)+a2/60.
k=where(a3 eq '-',c) & if c gt 0 then decl(k)=-decl(k)
a3=ftget(h,d,11,kr) & a1=ftget(h,d,12,kr) & a2=ftget(h,d,13,kr)
dech=float(a1)+a2/60.
k=where(a3 eq '-',c) & if c gt 0 then dech(k)=-dech(k)
if stp eq 2 then stop
a1=0 & a2=0 & a3=0

k=where(dech lt decl,nk)
if nk gt 0 then begin
   t=decl & t(k)=dech(k)         ;low values
   s=dech & s(k)=decl(k)         ;high values
   decl=t & dech=s
   s=0 & t=0
   endif
;
k=where((decl le maxdec) and (dech ge mindec))
kr=kr(k) & decl=decl(k) & dech=dech(k) & ralow=ralow(k) & rahigh=rahigh(k)
if stp eq 2 then help,k
;
nh=n_elements(rahigh)
if rahigh(nh-1) le 0. then  rahigh(nh-1)=360.
;
case 1 of
   iswap eq 0: k=where((ralow le maxra) and (rahigh ge minra))
   else: k=where((ralow le maxra) or (rahigh ge minra))
   endcase
if stp eq 2 then help,k
kr=kr(k) & decl=decl(k) & dech=dech(k) & ralow=ralow(k) & rahigh=rahigh(k)
kr=kr+1               ;*********************???
;
;kbad=where((kr eq 7916) or (kr eq 0709),nbad)
;if nbad gt 0 then begin
;   print,' *** WARNING: file ',kr(kbad),' is corrupted, and will not be read ***'
;   nkr=n_elements(kr)
;   if (nkr-nbad) le 0 then begin
;      print,' *** WARNING: no records to be read - returning'
;      return
;      endif
;   kgood=where((kr ne 7916) and (kr ne 0709),ngood)
;   kr=kr(kgood)
;   endif
;
nkr=n_elements(kr)          ;number of files to be read
print,' There are ',nkr,' files to be searched'
if nkr le 0 then begin
   stop,' ERROR - no files found'
   return
   endif
imount=0
border=13
case 1 of
   (min(kr) lt regs(border)) and (max(kr) ge regs(border)): begin
      if ffile(gsccd+sep3+'s0730'+sep2+'5260.gsc') eq 1 then begin
         idisk=2 & z='south' 
         endif else begin
         idisk=1 & z='north'
         endelse
      print,' Need to read both disks. This is not yet implemented.'
      print,' '+z+' disk is mounted, and will be read'
      if idisk eq 1 then kr=kr(where(kr lt regs(12))) else $
         kr=kr(where(kr ge regs(12)) )
      end
   min(kr) ge regs(border):begin
      idisk=2     ;south
      if not ffile(gsccd+sep3+'s0730'+sep2+'5260.gsc') then imount=1
      end
   else: begin
      idisk=1                    ;north
      if not ffile(gsccd+sep3+'n0000'+sep2+'0001.gsc') then imount=1
      end
   endcase
if imount eq 1 then begin
   bell
   z=' please mount GSC CD disk #'+strtrim(idisk,2)
   stop,z
   endif
;
k=where(regs gt kr(0)) & zone=zones(k(0)-1)
dir=gsccd+sep1+zone+sep2
rec=strtrim(kr(0),2)
if strlen(rec) eq 1 then rec='000'+rec
if strlen(rec) eq 2 then rec='00'+rec
if strlen(rec) eq 3 then rec='0'+rec
cdfile=dir+rec+'.gsc'
if keyword_set(savedata) then dfitsrd,cdfile,'temp',/n    ;make temporary SDAS files
readfile:                                      ;*********************
if keyword_set(file) then begin
   if keyword_set(debug) then print,' Reading ',file
   ftread,file,h,d 
   rec=file & k=strpos(rec,'_') & if k gt 0 then rec=strmid(rec,0,k)
   endif else if keyword_set(savedata) then ftread,'temp_1',h,d else $
      d=readfits(cdfile,h,ext=1)
id=ftget(h,d,1)
ras=ftget(h,d,2)
decs=ftget(h,d,3)
poserr=ftget(h,d,4)
mag=ftget(h,d,5)
magerr=ftget(h,d,6)
magband=ftget(h,d,7)
cl=ftget(h,d,8)
plate=ftget(h,d,9)
mult=ftget(h,d,10)
sid=strtrim(rec,2)+' '+string(byte(strmid(string(id),8,4))>48b)
;sid=string(byte(strmid(string(id),8,4))>48b)+' '+strtrim(rec,2)
;
if nkr gt 1 then for ikr=1,nkr-1 do begin    
   k=where(regs gt kr(ikr)) & zone=zones(k(0)-1)
   dir=gsccd+sep3+zone+sep2
   rec=strtrim(kr(ikr),2)
   if strlen(rec) eq 1 then rec='000'+rec
   if strlen(rec) eq 2 then rec='00'+rec
   if strlen(rec) eq 3 then rec='0'+rec
   cdfile=dir+rec+'.gsc'
   if keyword_set(savedata) then begin
      dfitsrd,cdfile,'temp',/n
      ftread,'temp_1',h,d
      endif else d=readfits(cdfile,h,ext=1)
   id1=ftget(h,d,1)
   id=[id,id1]
   ras=[ras,ftget(h,d,2)]
   decs=[decs,ftget(h,d,3)]
   poserr=[poserr,ftget(h,d,4)]
   mag=[mag,ftget(h,d,5)]
   magerr=[magerr,ftget(h,d,6)]
   magband=[magband,ftget(h,d,7)]
   cl=[cl,ftget(h,d,8)]
   plate=[plate,ftget(h,d,9)]
   mult=[mult,ftget(h,d,10)]
   sid1=string(id1)
   sid1=strmid(sid1,8,4)
   sid1=byte(sid1)>48b
   sid1=string(sid1)
   sid=[sid,rec+' '+sid1]              ;ID
   sid1='' & id1=0
   endfor
racen=ra & deccen=dec
if n_elements(ra) eq 0 then begin
   ra=mean(ras) & dec=mean(decs)
   endif
dist=angd(ras,decs,racen,deccen)
k=where(dist lt sqrt(2)*rad,nk)
if nk gt 0 then begin
   print,nk,' Stars in region'
   id=id(k) & sid=sid(k)
   ras=ras(k) & decs=decs(k) & poserr=poserr(k)
   mag=mag(k) & magerr=magerr(k) & magband=magband(k)
   cl=cl(k) & plate=plate(k) & mult=mult(k)
   endif else begin
   print,' No stars found'
   goto,bail            ;bail out if no stars found
   endelse
if keyword_set(class) then begin
   nc=n_elements(class)
   for i=0,nc-1 do begin
      k=where(cl eq class(i),nk)
      if nk gt 0 then begin
         id=id(k) & sid=sid(k)
         ras=ras(k) & decs=decs(k) & poserr=poserr(k)
         mag=mag(k) & magerr=magerr(k) & magband=magband(k)
         cl=cl(k) & plate=plate(k) & mult=mult(k)
         endif 
      endfor
   nk=n_elements(ras)
   print,nk,' Stars of this class found'
   if nk eq 0 then goto,bail
   endif
if abs(ep-2000.) gt 0.01 then begin
;keyword_set(epoch) and not keyword_set(j2000) then begin
   precess,racen,deccen,2000.,ep
   precess,ras,decs,2000.,ep
   print,' data precessed to equinox ',ep
   endif
ram=ras & decm=decs & pe=poserr & magm=mag & cls=cl         ;fill common
if iprt eq 1 then begin
   nk=n_elements(ras)
   if not ifstring(out) then out='gsclst'
   if n_elements(out) eq 0 then out='gsclst'
   if get_ext(out) eq '' then ext='.gsc' else ext=''
   openw,lu,out+ext,/get_lun
   filename=out
   printf,lu,'*** GSC STAR LIST ***'
   degtohms,racen,h,m,s & degtodms,deccen,dd,dm,ds
   srad=string(rad,'(F6.2)') & sep=string(ep,'(F8.2)')
   printf,lu,h,m,s,dd,dm,ds,srad,sep, $
      format="(' Center @ ',I2,I3,F7.3,'  ',2I3,F7.3,' Rad= ',A6,' Epoch= ',A8)" 
   printf,lu,'     id        RA            Dec          +/-   mag  +\-   b C Pl  mult'
   degtohms,ras,h,m,s & degtodms,decs,dd,dm,ds
   fmt="(A10,2(I3,I3,F7.3,'  '),F5.1,'  ',F5.2,' ',F4.2,I3,I2,A5,A2)"
   for i=0,nk-1 do printf,lu,sid(i),h(i),m(i),s(i),dd(i),dm(i),ds(i),poserr(i), $
      mag(i),magerr(i),magband(i),cl(i),plate(i),mult(i),format=fmt
   close,lu
   free_lun,lu
   print,' data are in ',out
   endif
if ravect eq 1 then begin   ;shorter input parameters
   dec=ras & ras=decs & decs=poserr & poserr=mag & mag=cl
   endif
if keyword_set(plt) then begin
   if keyword_set(markcen) then begin
      ms=markcen
      plotstars,hcpy=ihc,markcen=[racen,deccen,ms],noprint=noprint
      endif else plotstars,hcpy=ihc,noprint=noprint
   endif
if keyword_set(find) then begin
   wshow
   findp
   endif
if keyword_set(stp) or keyword_set(debug) then stop,'READGSC>>>'
;
;if not keyword_set(savedata) then spawn,'delete temp*.*;*' else $
;   if not keyword_set(file) then print,' The data are in TEMP_1.HHH and .HHD'
return
nocd: print,' CD Not mounted. Please mount CD and try again.'
return
;
bail:
ram=-1 & decm=-1
ras=-1 & decs=-1
return  
end
