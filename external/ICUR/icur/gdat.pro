;**************************************************************
PRO GDAT,name,H,WAVE,FLUX,EPS,REC,linear=linear,zrec0=zrec0,stp=stp, $
         helpme=helpme,sun=sun,plt=plt,headonly=headonly,noprint=noprint
; modification of GETDAT for generalized data storage.
;
case 1 of
   keyword_set(headonly): if n_params(0) lt 2 then helpme=1
   else: if n_params(0) lt 4 then helpme=1
   endcase
if keyword_set(helpme) then begin
   print,' '
   print,'* GDAT  -    extract spectral data from ICUR format data files'
   print,'*    calling sequence: GDAT,NAME,H,W,F [,E,REC]'
   print,'*       NAME: file name, default = ICUR; default extension=ICD'
   print,'*    H,W,F,E: standard input flux vectors'
   print,'*             E defaults to 0.'
   print,'*        REC: (optional) record number of spectrum. Prompted for.'
   print,'*             REC=-1 provides a list of records, REC<0 returns '
   print,'*'
   print,'*    KEYWORDS:'
   print,'*       HEADONLY: only return H vector (call GDAT,NAME,H,REC)'
   print,'*       LINEAR: force linear wavelength solution'
   print,'*       PLT:  set to plot spectrum'
   print,'*       SUN:  set to read file written on SUN machine'
   print,'*       ZREC0: first record; for diagnostic purposes'
   print,' '
   return
   endif
;
h=-1                ;dummy
if !quiet eq 3 then noprint=1
;
; Figure out name of file, defaults to ICUR
;
if n_elements(name) eq 0 then name='ICUR'            ;undefined
if not ifstring(name) then name='ICUR'             ;not a string
defdir=getenv('icurdata')
;
Z=NAME 
k=strpos(z,']')>0               ;location of last directory
k=strpos(z,'.',k)               ;is there an extension?
if k eq -1 then z=z+'.icd'      ; add .icd if no extension passed
if not ffile(z) then begin    ;file does not exist
   if ffile(defdir+z) then z=defdir+z else begin
      print,' file ',z,' does not exist. 
      return
      endelse
   endif
;   
z=STRTRIM(Z,2)
;
rec0off=32
bt=long([0,1,2,4,4,8])      ;number of bits per data type word
;
openr,lu,z,/get_lun
p=assoc(lu,bytarr(512))
rec0=p(0)
if ((rec0(rec0off) eq 1b) and (total(fix(rec0(rec0off+1:*))) eq 0) and $
   (n_elements(rec) eq 0)) then rec=0
;
;if n_params(0) lt 6 THEN rec=-9                  ;rec not passed
if n_elements(rec) eq 0 then rec=-9              ;rec passed, but not defined
if n_elements(rec) gt 1 then rec=rec(0)          ;array not valid
if rec eq -1 then begin
   lst=1
   ldat,z
   endif else lst=0
if rec lt 0 then begin
   read,'GDAT: Enter record number: ',nrec
   ENDIF ELSE NREC=REC
IF NREC LE -99 THEN BEGIN
   REC=-99
   free_lun,lu
   RETURN                 ; ABORT
   ENDIF
nrec=fix(nrec)
rec=nrec
;
if rec lt 0 then begin
   case 1 of
      (lst eq 1) and (rec lt 0): goto,retn          ;you had your listing!
      rec lt -1: goto,retn
      rec eq -1: ldat,z
      else:
      endcase
   if rec lt 0 then begin             ;2ND PASS
      read,'GDAT: Enter record number: ',nrec
      endif else nrec=rec
   NREC=FIX(NREC)
   rec=nrec
   endif             ;rec lt 0
;
if nrec lt 0 then goto,retn
;
if rec0(rec0off+nrec) ne 1b then begin
   print,' This record is not currently in use'
   close,lu
   free_lun,lu
   return
   endif
;
; check origin and host machines
;
orig=rec0(0)
if keyword_set(sun) then orig=1b
machine=icbconv(orig)
;
ilin=fix(rec0(3))          ;0 if stored as linear
nh=fix(rec0,8)             ;size of header record
nl=long(rec0,4)            ;size of header record
;print,machine,nh,nl
case 1 of
   machine eq 0:
   machine eq 1:
   machine eq 6:
   machine gt 2: begin                ;ne 0 then begin
      trans_bytes,nh,2,machine
      trans_bytes,nl,4,machine
      end
   else:
   endcase
;print,nh,nl
;stop
nrec0=fix(rec0(10))        ;number of initial records
sw=fix(rec0(11))           ;types of vectors
sf=fix(rec0(12))
se=fix(rec0(13))
sh=fix(rec0(14))
etype=fix(rec0(15))        ;epsilon vector code
igap=fix(rec0(16))         ;1 if gaps stored
k=where(rec0(32:*) gt 0b)   ;bytes 0:rec0off-1 reserved
nrecused=max(k)
nr=long(rec0(2)+rec0(18)*256L)            ;records used per spectrum
irec=nrec0+nr*nrec         ;beginning record
b=p(irec)
if keyword_set(zrec0) then begin
   print,'vector lengths - Header:',nh,' W,F,E:',nl
   print,' Number of initial records:',nrec0
   print,' Vector types (H,W,F,E):',sh,sw,sf,se
   case 1 of
      etype eq 0: zz='no data quality vector stored'
      etype eq 1: zz='unknown format'
      etype eq 10: zz='fractional exposure time (0-127)/127'
      etype eq 20: zz='IUE epsilon vector'
      etype eq 30: zz='S/N vector'
      etype eq 40: zz='error bars'
      else: zz=''
      end
   print,' Data quality code:',etype,' (',zz,')'
   print,' Number of records used per spectrum:',nr
   print,' Number of spectra stored:',nrecused
   if ilin eq 0 then print,' Linear wavelength vector'
   zrec0=rec0
   endif
for i=1,nr-1 do b=[b,p(irec+i)]  ;complete vector
close,lu
free_lun,lu
;
;extract header
;
h=b(0:nh*bt(sh)-1)
if machine ne 0 then begin
   if (sh ge 2) and (sh le 5) then trans_bytes,h,sh,machine
    endif      ;translation
;
case 1 of
   sh eq 2: h=fix(h,0,nh)
   sh eq 3: h=long(h,0,nh)
   sh eq 4: h=float(h,0,nh)
   sh eq 5: h=double(h,0,nh)
   else:
   endcase
;
if keyword_set(headonly) then return
off=nh*bt(sh)   ;offset
vlen=h(7)       ;vector length
if vlen lt 0 then vlen=65535L+h(7)
;if vlen ne nl then print,' WARNING: vlen=',vlen,' nl=',nl
;
;extract flux vector
;
flux=b(off:off+vlen*bt(sf)-1)
if machine ne 0 then begin
   if (sf ge 2) and (sf le 5) then trans_bytes,flux,sf,machine
    endif      ;translation
;
case 1 of
   sf eq 2: flux=fix(flux,0,vlen)
   sf eq 3: flux=long(flux,0,vlen)
   sf eq 4: flux=float(flux,0,vlen)
   sf eq 5: flux=double(flux,0,vlen)
   else:
   endcase
z=finite(flux) & k=where(z eq 0,nk) & if nk gt 0 then flux(k)=0
;
off=off+vlen*bt(sf)     ;offset
;
if etype gt 0 then begin       ;extract epsilon vector
   eps=b(off:off+vlen*bt(se)-1)
   if machine ne 0 then begin
      if (se ge 2) and (se le 5) then trans_bytes,eps,se,machine
      endif      ;translation
;
   case 1 of
      se eq 2: eps=fix(eps,0,vlen)
      se eq 3: eps=long(eps,0,vlen)
      se eq 4: eps=float(eps,0,vlen)
      se eq 5: eps=double(eps,0,vlen)
      else:
   endcase
;
   if etype eq 30 then eps=float(eps)/100.
   off=off+vlen*bt(se)     ;offset
   endif else eps=100.+intarr(vlen)
;
;h(33)=etype             ; store in header
if (h(33) eq 0) and (etype gt 0) then eps=eps(0)
;
if ilin eq 0 then begin
   if h(19) lt 0 then longlam=1 else longlam=0
   wscale=abs(double(h(19)))
   w0=h(20)+h(21)/wscale
   dw=h(22)+h(23)/wscale
   if longlam then dw=dw/1.e4
   case 1 of
      sw eq 1: wave=bindgen(vlen)
      sw eq 2: wave=indgen(vlen)
      sw eq 3: wave=lindgen(vlen)
      sw eq 4: wave=findgen(vlen)
      else: wave=dindgen(vlen)
      endcase
   wave=w0+dw*wave
   case 1 of
      sw eq 1: wave=byte(wave)
      sw eq 2: wave=fix(wave)
      sw eq 3: wave=long(wave)
      sw eq 4: wave=float(wave)
      else:
      endcase

   endif else begin    ;vector stored
;
;extract wavelength vector
;
   wave=b(off:off+vlen*bt(sw)-1)
   if machine ne 0 then begin
      if (sw ge 2) and (sw le 5) then trans_bytes,wave,sw,machine
       endif      ;translation
;
   case 1 of
      sw eq 2: wave=fix(wave,0,vlen)
      sw eq 3: wave=long(wave,0,vlen)
      sw eq 4: wave=float(wave,0,vlen)
      sw eq 5: wave=double(wave,0,vlen)
      else:
      endcase
;
   if keyword_set(linear) and (h(199) ne 333) then linearwave,h,wave,flux,eps
   endelse
;
if igap eq 1 then restgap,h,w                 ;restore gaps in idat=7 data
ncam=h(3)
image=h(4)
if image lt 0 then image=image+65536L         ;fullword
z=''
if (ncam gt 0) and (ncam lt 5) then begin                 ;iue data
   camera=strmid('    LWP LWR SWP SWR',ncam*4,4)
   z=camera+strtrim(string(image),2)
   dw=mean(wave(1:*)-wave)                ;mean dispersion
   if dw gt 0.9 then z=z+'L  ' else z=z+'H  ' 
   endif
title=strtrim(byte(h(100:159>32b)),2)
bt=byte(title)
k=where(bt gt 126b,count) 
if count gt 0 then begin
   title=32+intarr(60)
   h(100)=title
   endif   
z=z+strtrim(byte(h(100:159>32b)),2)
if not keyword_set(noprint) then print,strtrim(rec,2),': ',z
if keyword_set(plt) then begin
   setxy & plot,wave,flux,title=z
   if !d.name eq 'X' then wshow
   endif
;
if keyword_set(stp) then stop,'GDAT>>>'
RETURN
;
retn:
free_lun,lu
return
END
