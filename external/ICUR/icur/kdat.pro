;**************************************************************
PRO KDAT,name,H0,WAVE0,FLUX0,EPS0,REC,nonlinear=nonlinear,linear=linear, $
   stp=stp,vlen=vlen,notitle=notitle,title=title,helpme=helpme,islin=islin, $
   epstype=epstype,headonly=headonly,newfile=newfile
; modification of KEEPDAT for generalized data storage.
;Record 0:
;Byte  Int  Long FP
; 2                 number of records needed per spectrum
; 3                 0 if linear, 1 if not
;4-7           1    max length of W,F,E vectors
;8-9     4          max length of H vector
;10                 # initial records
;11                 type of W vector
;12                 type of F vector
;13                 type of E vector
;14                 type of H vector
;15                 E vector descriptor
;16                 1 if gaps are stored (idat=7) 
;17                 .std file code
;18                 MSB of rec0(2)
;19-31              unused
;32-511             for data storage (480 records max)
;
if (n_params(0) lt 4) and not keyword_set(headonly) then helpme=1
if keyword_set(helpme) then begin
   print,'* KDAT  -    store spectral data in ICUR format data files'
   print,'*    calling sequence: KDAT,NAME,H,W,F [,E,REC]'
   print,'*       NAME: file name, default = ICUR, default extension= .ICD'
   print,'*    H,W,F,E: standard input flux vectors'
   print,'*             E defaults to 0.'
   print,'*        REC: (optional) record number to store in. Prompted for.'
   print,'*'
   print,'*    KEYWORDS:'
   print,'*      EPSTYPE: set to epsilon vector code to force first record'
   print,'*     HEADONLY: only update header records
   print,'*        ISLIN: data are already linearized - use if H undefined'
   print,'*       LINEAR: force linear wavelength solution'
   print,'*      NEWFILE: set to create new file, def appends if file exists'
   print,'*    NONLINEAR: store non-linear wavelength solution'
   print,'*      NOTITLE: do not query for title if none is present'
   print,'*        TITLE: title for entry'
   print,'*         VLEN: flux vector length, overrides length of first F vector'
   print,' '
   return
   endif
;
if keyword_set(headonly) then begin
   if n_params() eq 3 then rec=wave0
   if n_elements(flux0) eq 0 then flux0=0
   wave0=0
   endif
if keyword_set(headonly) and (n_elements(rec) eq 0) then begin
   print,' To update header you must specify a record number'
   print,' Call: KDAT,H,REC'
   print,' - KDAT RETURNING -'
   return
   endif
if n_elements(eps0) le 0 then eps0=0
if n_elements(h0) lt 7 then begin
   h0=intarr(512)
   h0(3)=-1
   h0(7)=n_elements(flux0)
   endif
wave=wave0
flux=flux0
z=finite(flux) & k=where(z eq 0,nk) & if nk gt 0 then flux(k)=0
eps=eps0
z=finite(eps) & k=where(z eq 0,nk) & if nk gt 0 then eps(k)=0
h=h0
;
; Figure out name of file, defaults to ICUR
;
if n_elements(name) eq 0 then name='ICUR'            ;undefined
if not ifstring(name) then name='ICUR'              ;not a string
;
Z=strtrim(name,2)
if noext(z) then z=z+'.icd'   ; add .ICD if no extension passed
if not ffile(z) then begin    ;file does not exist
   if keyword_set(headonly) then begin
      print,' You cannot update a new file'
      print,' Call: KDAT,H,REC'
      print,' - KDAT RETURNING -'
      return
      endif
    print,' The file does not exist. ',z,' will be created'   
    ifx=-1
    endif else ifx=1
if keyword_set(newfile) then begin
   ifx=-1
   print,' A new version of ',z,' will be created'
   endif
;
iwarn=0
rec0off=32
bt=[0,1,2,4,4,8]      ;number of bits per data type word
ln=n_elements(flux)   ;longword integer
;if ln gt 32767L then begin
;   h7=(h(8)>0)*32767L+h(7)>0
;   (8)
;   endif else 
if h(7) ne ln then h(7)=fix(ln)
hn=fix(n_elements(h)<32767) ;short integer
;
if n_elements(rec) eq 0 then rec=-1
if ifx eq -1 then rec=0           ;put in first record if new file
NREC=FIX(REC)
;
wscale=30000                         ;scaling for fractional part of wavelength
h19=h(19)
if hn lt 199 then h199=0 else h199=h(199)
if keyword_set(islin) then h199=333
case 1 of
   ifx eq -1: begin                   ;******************* initialize record 0
      w0=wave(0)                      ;initial wavelength
      wmax=max(wave)                  ;maximum wavelength
      dw=(wmax-w0)/(ln-1)                 ;mean dispersion
      ilin=0                          ; is wavelength scale linear?
      case 1 of
         keyword_set(linear): begin              ;force linear scale
            linearwave,h,wave,flux,eps,wfact=wscale
            ilin=1
            end
         keyword_set(nonlinear): ilin=-1        ;save as is
         h199 eq 333: begin                   ;restored from GETDAT as linear
            ilin=1                              ;&
            if (h(20) ne fix(w0)) or (h(19) ne wscale) then begin
               h(20)=fix(w0) & h(21)=fix((w0-h(20))*wscale)
               h(22)=fix(dw) & h(23)=fix((dw-h(22))*wscale)
               if h(22) eq 0 then begin    ;longlam=1
                  h(22)=fix(dw*1.e4)
                  h(23)=fix((dw*1.e4-h(22))*wscale)
                  wscale=-wscale
                  endif
               h(19)=fix(wscale)
               endif
            if hn ge 199 then h(199)=333
;            if h19 ne wscale then begin       ;&
;               h(21)=fix(h(21)/(float(h19)>1.)*float(wscale))   ;&
;               h(23)=fix(h(23)/(float(h19)>1.)*float(wscale))   ;&
;               h(19)=wscale                     ;&
;               endif                            ;&
            end                                 ;&
         else: begin                             ;test
            if h(20) ne fix(w0) then ilin=-1     ;not stored as linear
            if h(19) lt 1000 then ilin=0
            end
         endcase
;
      if ilin eq 0 then begin
         print,' is this a linear spectrum? '
         print,' h(20:23)=',h(20:23)
         print,' wave(0)=',w0
         read,' Enter 0 to linearize, -1 to store as is, 1 if already linear: ',ilin
         case ilin of
            1: begin                     ;only update header
               if (h(20) ne fix(w0)) or (h(19) ne wscale) then begin
                  h(20)=fix(w0) & h(21)=fix((w0-h(20))*wscale)
                  h(22)=fix(dw) & h(23)=fix((dw-h(22))*wscale)
                  if h(22) eq 0 then begin    ;longlam=1
                     h(22)=fix(dw*1.e4)
                     h(23)=fix((dw*1.e4-h(22))*wscale)
                     wscale=-wscale
                     endif
                  h(19)=fix(wscale)
print,h(19:23),wscale
                  endif
               h(199)=333
               end
            0: begin
               linearwave,h,wave,flux,eps,wfact=wscale
               ilin=1
               end
            else:
            endcase
         endif
      rec=0
      rec0=bytarr(512)                     ;initialize record zero
      case 1 of            ;defines origin of file
         !version.arch eq 'vax': rec0(0)=0b          ;VAX/VMS
         !version.arch eq 'sparc': rec0(0)=1b        ;Sparcstations, Sun4
         !version.arch eq 'alpha': rec0(0)=1b        ;alpha
         !version.arch eq 'mipsel': rec0(0)=2b       ;DECstation, 386
         else: rec0(0)=3b          ;other
         endcase
      if ilin eq 1 then rec0(3)=0b else rec0(3)=1b  ;WAVE vector is linear - byte3=0
      rec0(10)=1b                          ;number of initial records, def=1
      if keyword_set(vlen) then ln=long(vlen)
      b=byte(ln,0,4) & rec0(4)=b           ;length of W,F,E vectors - bytes 4-7
      b=byte(hn,0,2) & rec0(8)=b           ;length of H vector - bytes 8-9
      s=size(wave) & s=s(s(0)+1) & rec0(11)=byte(s)  ;type of WAVE
      s=size(flux) & s=s(s(0)+1) & rec0(12)=byte(s)  ;type of FLUX
      s=size(eps) & s=s(s(0)+1) & rec0(13)=byte(s)   ;type of EPS
      s=size(h) & s=s(s(0)+1) & rec0(14)=byte(s)     ;type of H
;
      if n_elements(epstype) eq 1 then begin         ;force epsilon type
         rec015=byte(epstype)
         case 1 of
            rec015 eq 0b: if n_elements(eps) eq 0 then eps=100 else $
                               eps=fix(eps(0))
            rec015 eq 10b: if rec0(13) ne 1b then eps=byte(eps) 
            rec015 eq 20b: rec0(13)=2b 
            rec015 eq 30b: begin  ;S/N vector
               rec0(13)=2.
               eps=fix(((eps*100.)+0.5)<32767.)         ;convert to integer
               end
            rec015 ge 40b: begin
               rec0(13)=4b
               if n_elements(eps) le 1 then begin
                  eps=flux*0.+1.E10 & eps(0)=0.
                  endif
               end
               else: rec0(13)=2b
            endcase
         endif else case 1 of          ;determine type
         n_elements(eps) le 1: rec0(15)=0b    ;no epsilon vector
         max(eps) eq min(eps): rec0(15)=0b
         rec0(13) eq 1: rec0(15)=10b          ;exposure time fraction (0-127)/127
         rec0(13) eq 2: begin
            if (max(eps) le 100) then rec0(15)=20b   ;IUE epsilon
            if (max(eps) gt 100) then rec0(15)=30b   ;S/N
            end
         rec0(13) eq 4b: begin                        ; FP vector
            if mean(eps) lt mean(flux) then begin    ;error bars
               rec0(13)=4b                           ;store as F/P
               rec0(15)=40b
               endif else begin                      ;S/N vector saved
               rec0(13)=2b                           ;store as integer
               eps=fix(((eps*100.)+0.5)<32767.)         ;convert to integer
               rec0(15)=30b
               endelse
            end
         else: rec0(15)=1b                        ;unknown
         endcase
      if keyword_set(epstype) then rec0(15)=rec015       ;force epsilon type
      nb=ln*bt(rec0(12))+hn*bt(rec0(14))      ;Flux,H
      if rec0(15) gt 0b then nb=nb+ln*bt(rec0(13))  ;EPS stored
      if rec0(3) eq 1b then nb=nb+ln*bt(rec0(11))   ;WAVE stored
      nrecs=((nb-1)/512)+1
      rec0(2)=byte(nrecs)
      if nrecs gt 255 then rec0(18)=byte(nrecs/256)
; set bit 16 if gaps stored
   if (h(0) eq 7) and (hn ge 901) then begin   ;test for gaps in IDAT=7 data
      if h(900) gt 0 then  rec0(16)=1b         ;gaps exist
      endif
;bits 17 reserved for .std code
;bits 18-31 unused
;bits 32-511 for data storage (480 records max)
      openw,lu,z,512,/get_lun
      p=assoc(lu,bytarr(512))
      p(0)=rec0
      end                ;ifx=-1
   else: begin          ;*************************************** file exists
      openu,lu,z,/get_lun
      p=assoc(lu,bytarr(512))
      rec0=p(0)
      nb=512L*(rec0(2)+rec0(18)*256)               ;maximum number of bytes
      s=size(wave) & sw=s(s(0)+1) ;type of WAVE
      s=size(flux) & sf=s(s(0)+1) ;type of FLUX
      s=size(h) & sh=s(s(0)+1) ;type of H
      s=size(eps) & se=s(s(0)+1) ;type of EPS
;      if (se eq 4) and (rec0(15) eq 30b) then begin         ;convert to integer
      if rec0(15) eq 30b then begin         ;convert to integer
         se=2                                     ;save as integer
         eps=fix(((eps*100.)+0.5)<32767.)         ;convert to integer
         endif
      lns=long(rec0,4)            ;length of stored W,F,E vectors - bytes 4-7
      hns=fix(rec0,8)             ;length of stored H vector - bytes 8-9
      case 1 of                    ;force header lengths to be commensurate
         hn gt hns: h=h(0:hns-1)   ;truncate
         hn lt hns: begin          ;insert
            hh=intarr(hns)
            hh(0)=h
            h=hh
            hh=0
            end
         else:
         endcase
      hn=hns
      nbinp=ln*(bt(sf)+rec0(3)*bt(sw))+hn*bt(sh)
      if rec0(15) gt 0b then nbinp=nbinp+ln*bt(se)
      bpp=bt(sf)+rec0(3)*bt(sw)                       ;bytes per point
      if rec0(15) gt 0b then bpp=bpp+bt(se) 
      nvs=1+rec0(3) & if rec0(15) gt 0b then nvs=nvs+1  ;number of vectors stored
      if not keyword_set(headonly) then begin
         if rec0(3) eq 0 then begin    ;WAVE not to be stored
            case 1 of
               keyword_set(linear): begin              ;force linear scale
                  linearwave,h,wave,flux,eps,wfact=wscale
                  end
               h199 ne 333: linearwave,h,wave,flux,eps,wfact=wscale
         h199 eq 333: begin                   ;restored from GETDAT as linear
            w0=wave(0)                        ;initial wavelength
            dw=(max(wave)-w0)/(ln-1)          ;dispersion
            ilin=1                              ;&
            if (h(20) ne fix(w0)) or (h(19) ne wscale) then begin
               h(20)=fix(w0) & h(21)=fix((w0-h(20))*wscale)
               h(22)=fix(dw) & h(23)=fix((dw-h(22))*wscale)
               if h(22) eq 0 then begin    ;longlam=1
                  h(22)=fix(dw*1.e4)
                  h(23)=fix((dw*1.e4-h(22))*wscale)
                  wscale=-wscale
                  endif
               h(19)=fix(wscale)
               endif
            if hn ge 199 then h(199)=333
            end                                 ;&
;               h199 eq 333: begin             ;restored from GETDAT as linear
;                  if (h(19) ne fix(wscale)) then begin
;                     h(21)=fix(h(21)/float(abs(h(19)))*float(wscale))
;                     h(23)=fix(h(23)/float(abs(h(19)))*float(wscale))
;                     h(19)=wscale
;                     endif
;                  end
               endcase
            endif
;
         if nbinp gt nb then begin
            d=nbinp-nb
            np=(d/bpp)+1
            veclen=h(7)                          ;length of input vector
            if veclen lt 0 then veclen=65535L+h(7)
            veclen=veclen-np
            h(7)=fix(veclen)
       print,' WARNING: input data lengths exceeds storage limits by',d,' bytes'
         print,' truncating input vectors by ',np,' points to ',veclen,' points'
            wave=wave(0:veclen-1)
            flux=flux(0:veclen-1)
            if rec0(15) gt 0b then eps=eps(0:veclen-1)
            ln=n_elements(flux)
;           iwarn=1
            endif
         endif    ;not /headonly
      end
   endcase
if iwarn eq 1 then stop
;
; now store the data
;
   if nrec lt 0 then begin
   z=p(0)
   k=where(z(rec0off:*) gt 0b)   ;bytes 0:rec0off-1 reserved
   nrec=max(k)+1        ;next free record
   print,' data to be stored in record',nrec
   endif 
;
IF (rec0(3) eq 0) and not keyword_set(headonly) THEN begin   ;store current wavelength vector in header
   h(20)=fix(wave(0))
   nw=n_elements(wave)
   if h(0) eq 7 then begin          ;test for gaps in data
      if h(900) gt 0 then begin     ;gaps exist
         wgap=h(901)+h(902)/30000.
         nw=where(wave lt wgap) & nw=max(nw)
         rec0=p(0)
         rec0(16)=1b
         p(0)=rec0
         endif
      endif
;print,h(19),wscale,h(20),fix(wave(0))
;print,h(19:23)
   if (abs(h(19)) ne abs(wscale)) or (h(20) ne fix(wave(0))) then begin 
      h(20)=fix(wave(0))
      h(21)=fix((wave(0)-float(h(20)))*wscale)
      dw=(wave(nw-1)-wave(0))/(nw-1)
      h(22)=fix(dw)
      h(23)=fix((dw-float(h(22)))*wscale)
      if h(22) eq 0 then begin                ;longlam=1
         h(22)=fix(dw*1.e4)
         h(23)=fix((dw*1.e4-h(22))*wscale)
         wscale=-wscale
         endif
      h(19)=wscale
      endif
   endif
;
h(33)=fix(rec0(15))
if n_elements(eps0) le 1 then h(33)=0
if keyword_set(title) then begin           ;replace/insert header
   if ifstring(title) eq 1 then begin      ; but only if a string is passed
      h(100:159)=32                        ; clear the space first
      h(100)=byte(title)                   ; insert the title
      endif
   endif
title=strtrim(byte(h(100:159)>32b),2)
k=where(byte(title) gt 126b,count)
if ((count gt 1) or (strlen(title) eq 0)) and (not keyword_set(notitle)) then begin
   print,' No title has been stored. Please enter one here'
   bell
   title=''
   read,title
   h(100:159)=32
   h(100)=byte(title)
   endif
;
ln0=n_elements(flux)
b=byte(h,0,hn*bt(rec0(14)))                    ;header
if keyword_set(headonly) then begin
   nb=n_elements(b)          ;number of bytes in header
   nbs=nb/512.               ;number of records
   rem=nbs-fix(nbs)
   if rem gt 1./1024. then nbs=fix(nbs)+1 else nbs=fix(nbs)
   roff=rec0(2)+rec0(18)*256       ;offset 
   i0=rec0(10)+roff*long(nrec)     ;starting record
   oldhead=p(i0)
   if nbs gt 1 then for i=1,nbs-1 do oldhead=[oldhead,p(i0+i)]
   oldhead(0)=b
   for i=0L,nbs-1L do p(i0+i)=oldhead(512L*i:512L*i+511L)
   goto,ret
   endif  
;
b=[b,byte(flux,0,ln0*bt(rec0(12)))]
if rec0(15) gt 0b then begin
   if n_elements(eps) lt ln0 then begin
      npad=(ln0-n_elements(eps))>0
      if npad gt 0 then case 1 of
         rec0(13) eq 1b: epad=bytarr(npad)
         rec0(13) eq 2b: epad=intarr(npad)
         rec0(13) eq 3b: epad=lonarr(npad)
         rec0(13) eq 4b: epad=fltarr(npad)
         rec0(13) eq 5b: epad=complexarr(npad)
         else:           ;?????
         endcase
      eps=[eps,epad]
      endif
   b=[b,byte(eps,0,ln0*bt(rec0(13)))]
   endif
if rec0(3) eq 1 then b=[b,byte(wave,0,ln0*bt(rec0(11)))]
;
roff=rec0(2)+rec0(18)*256       ;offset 
i0=rec0(10)+roff*long(nrec)     ;starting record
nb=n_elements(b)
nbs=roff*512L
npad=nbs-nb
if npad gt 0 then b=[b,bytarr(npad)]
for i=0L,roff-2L do p(i0+i)=b(512L*i:512L*i+511L)
p(i0+roff-1)=b(512L*(roff-1):*)
;
z=p(0)                 ;update index block
z(rec0off+nrec)=1b     ;amend index record; offset=2
p(0)=z
;
ret:
if keyword_set(stp) then stop,'KDAT>>>'
CLOSE,LU
FREE_LUN,LU
RETURN
END
