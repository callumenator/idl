;**************************************************************
PRO LDAT,name,rec1,rec2,out=out,print=print,zr0=zr0,helpme=helpme,sun=sun, $
    full=full,lines=lines,stp=stp,page=page,heads=heads,abdor=abdor, $
    master=master
; modification of LKDAT
;
if n_params(0) lt 1 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* LDAT  -    List ICUR format data files'
   print,'*    calling sequence: LDAT,NAME [,rec1,rec2]'
   print,'*       NAME: file name, default = ICUR, extension=.ICD'
   print,'*        REC1,REC2: (optional) first and last record numbers to list.'
   print,'*'
   print,'*    KEYWORDS:'
   print,'*       FULL:  include UT and exposure times in printout'
   print,'*       LINES: number of lines to display to screen (mimics PAGE command)
   print,'*       MASTER: return line for master catalog'
   print,'*       OUT:   disk file for output, default=NAME.CONT'
   print,'*       PAGE:  print 23 lines to screen at a time'
   print,'*       PRINT: spawn output to printer'
   print,'*       SUN:   set to read file written on SUN machine'
   print,'*       ZR0:   set to list rec0 file information'
   print,' '
   return
   endif
;
if n_elements(name) eq 0 then begin
   print,' LDAT: file name is undefined'
   return
   endif
if n_params(0) lt 3 then rec2=999
if n_elements(rec1) eq 0 then rec1=0
igo=''
if keyword_set(abdor) then begin
   phase0=2444296.575D0 & period=0.51479D0
   endif
;
file=STRTRIM(name,2)
n0=file
k=strpos(file,']')>0                     ;location of last directory
if k gt 0 then n0=strmid(name,k+1,99)    ;drop directory
k=strpos(file,'.',k)                     ;is there an extension?
if k eq -1 then file=file+'.icd' else begin ; add .ICD if no extension passed
   k=strpos(n0,'.',k)
   n0=strmid(n0,0,k)
   endelse
if not ffile(file) then begin    ;file does not exist
   icurdata=getenv('icurdata')
   if strlen(icurdata) gt 0 then begin
      if ffile(icurdata+file) then file=icurdata+file
      endif
   if not ffile(file) then begin    ;file does not exist
      print,' file ',file,' does not exist. 
      return
      endif
   endif
;
rec0off=32
btp=[0,1,2,4,4,8]      ;number of bits per data type word
;
page_line=23
if keyword_set(page) then lines=page_line
if keyword_set(lines) then begin
   if lines lt 10 then lines=page_line
   endif else lines=0
if keyword_set(print) or keyword_set(out) then lines=0
;
openr,lu,file,/get_lun
p=assoc(lu,bytarr(512))
rec0=p(0)
recs=where(rec0(rec0off:*) eq 1b,num)
if num le 0 then begin
   print,' no records used'
   close,lu & free_lun,lu
   return
   end
nr=max(recs)
rec1=rec1>recs(0)
rec2=rec2<nr
zcol=':'
if keyword_set(master) then begin
   rec1=0
   rec2=nr
   zrec=strarr(nr+1)
   print=0
   out=0
   zr0=0
   !quiet=3
   full=1
   zcol=' '
   endif
;
doy=systime(0)
zz=STRING(FILE)+' listed on '+string(doy)
if !quiet ne 3 then begin
   print,zz
   print,' '
   endif
;
file='none'
if keyword_set(print) then file='ldat.lst'
if keyword_set(out) then begin
   if not ifstring(out) then out=n0
   file=out
   if strlen(get_ext(file)) eq 0 then file=file+'.cont'
   endif
if file ne 'none' then begin
   openw,lu2,file,/get_lun
   printf,lu2,' '
   printf,lu2,' ** LDAT **'
   printf,lu2,zz
   printf,lu2,' '
   endif
;
; check source of file
;
orig=rec0(0)
if keyword_set(sun) then orig=1b
machine=icbconv(orig)
;
ilin=fix(rec0(3))          ;0 if linear wavelength stored in header 
nh=fix(rec0,8)             ;size of header record
nl=long(rec0,4)            ;size of header record
if machine gt 2 then begin    ;was ne 0
   trans_bytes,nh,2,machine
   trans_bytes,nl,4,machine
   endif
nrec0=fix(rec0(10))        ;number of initial records
sw=fix(rec0(11))           ;types of vectors
sf=fix(rec0(12))
se=fix(rec0(13))
sh=fix(rec0(14))
etype=fix(rec0(15))        ;epsilon vector code
igap=fix(rec0(16))         ;1 if gaps stored
nr=long(rec0(2)+rec0(18)*256)            ;records used
if nr lt 32767 then nr=fix(nr)
nhr=1+nh*sh/512
k=where(rec0(32:*) gt 0b) & nsp=max(k)
;
if n_elements(zr0) eq 1 then begin
   print,'| Vector lengths - Header:',nh,' W,F,E:',nl
   print,'| Number of initial records:',nrec0
   print,'| Vector types (H,W,F,E):',sh,sw,sf,se
   case 1 of
      etype eq 0: zz='no data quality vector stored'
      etype eq 1: zz='unknown format'
      etype eq 10: zz='fractional exposure time (0-127)/127'
      etype eq 20: zz='IUE epsilon vector'
      etype eq 30: zz='S/N vector'
      else: zz=''
      end
   print,'| Data quality code:',etype,' (',zz,')'
   print,'| Number of records used per spectrum:',nr
   print,'| ',strtrim(nsp+1,2),' spectra stored'
   if ilin eq 0 then print,'| Linear wavelength vector'
   print,'----------------------------------------------'
   zrec0=rec0
   endif
if n_elements(zr0) eq 0 then zr0=0
if zr0 gt 1 then return
;
nrecs=rec2-rec1+1
if keyword_set(heads) then heads=strarr(nrecs)
for i=rec1,rec2 do begin
   hrec=nrec0+i*nr
   b=p(hrec)
   if nhr gt 1 then for j=1,nhr do b=[b,p(hrec+j)]
   h=b(0:nh*btp(sh)-1)               ;header
   if machine ne 0 then begin
      if (sh ge 2) and (sh le 5) then trans_bytes,h,sh,machine
      endif         ;translation
;
   case 1 of            ;extract header
      sh eq 2: h=fix(h,0,nh)
      sh eq 3: h=long(h,0,nh)
      sh eq 4: h=float(h,0,nh)
      sh eq 5: h=double(h,0,nh)
      else:
      endcase
   ncam=h(3)
   image=h(4) & if image lt 0 then image=image+65536L
   h19=float(abs(h(19)))
   h7=h(7)
   if h7 lt 0 then h7=h7+65535L
   z='' & zdoy='' & zim=''
   yr=h(12)
   case 1 of
      yr lt 50: yr1=yr+2000
      yr lt 100: yr1=yr+1900
      else: yr1=yr
      endcase
   yfmt='(I2)'
   if yr gt 99 then yfmt='(I4)'
   case 1 of
      (ncam gt 0) and (ncam lt 5): begin                 ;iue data
         camera=strmid('    LWP LWR SWP SWR',ncam*4,4)
         zim=camera+strtrim(string(image),2)
         if ilin eq 0 then dw=h(22)+float(h(23))/h19 else begin
            if h7 lt 1000 then dw=1. else dw=.1
            endelse
         if dw gt 0.9 then zim=zim+'L  ' else zim=zim+'H  ' 
         end
      ncam eq 100: begin
         if image ne 0 then zim='H'+strtrim(image,2)+' '
         zdoy=string(strtrim(h(10),2),'(I2)')+'/'+ $
         string(strtrim(h(11),2),'(I2)')+'/'+string(yr,yfmt)+'  '
         end
      ncam le 0:
      else: zdoy=string(strtrim(h(10),2),'(I2)')+'/'+ $
            string(strtrim(h(11),2),'(I2)')+'/'+string(yr,yfmt)+'  '
      end
   if ilin eq 0 then begin
      w0=h(20)+float(h(21))/h19
      dw=h(22)+float(h(23))/h19
      if h(19) lt 0 then dw=dw/1.e4
      zmw=string(w0+dw*h7/2.,'(F7.1)')+' '    ;mean wavelength
      endif else zmw=''
   title=strtrim(byte(h(100:159>32b)),2)
   bt=byte(title)
   k=where(bt gt 126b,count) 
   if count gt 0 then begin  
      title=32+intarr(60)
      h(100)=title
   endif   
   title=strtrim(byte(h(100:159>32b)),2)
   si=string(i,'(I4)')
   if keyword_set(full) then begin
      tm=abs(h(5))
      if h(5) lt 0 then zs='m' else zs='s'
      integ=string(tm,'(I6)')
      if ncam gt 5 then ut=string(h(13),'(I2)')+':'+string(h(14),'(I2)')+':'+ $
         string(h(15),'(I2)') else ut=''
      zd=ut+integ+zs+' '
      endif else zd=' '
   if keyword_set(abdor) then begin
         jd=julianday(h(10),h(11),yr1)
         jd=jd+(h(13)+(h(14)+(h(15)/60.))/60.)/24.
         ph=(jd-phase0)/period
         zph=string(ph-long(ph),'(F5.3)')
      endif else zph=''
   z=si+zcol+' '+zim+zmw+zdoy+zd+zph+' '+title
   z=strmid(z,0,79)
   if n_elements(heads) gt 0 then heads(i-rec1)=title
   if !quiet ne 3 then print,z
   if file ne 'none' then printf,lu2,z
   if keyword_set(master) then zrec(i)=' '+z
   if lines gt 0 then if (((i+1) mod lines eq 0) and (i ne rec2)) then begin
         igo=''
         read,' Return to Continue',igo
         ib=(byte(igo))(0)
         if ib gt 0 then goto,done
         endif
   endfor
done:
close,lu & free_lun,lu
if file ne 'none' then begin
   close,lu2 & free_lun,lu2
   endif
if keyword_set(print) then spawn_print,file else begin
   if file ne 'none' then print,' Listing in file ',file
   endelse
if keyword_set(master) then rec1=zrec
;
if keyword_set(stp) then stop,'LDAT>>>'
RETURN
END
