;***************************************************************
PRO GETDAT,IDT0,H1,W1,F1,E1,REC,NAME    ;GET DATA FROM DISK
common icdisk,icurdisk,icurdata,ismdata,objfile,stdfile,idata,recno,linfile
if n_params(0) lt 2 then begin
   print,' '
   print,'* GETDAT  -  read spectral data from ICUR format data files'
   print,'*    calling sequence: GETDAT,IDAT,H [,W,F,E,REC,FILE]'
   print,'*       IDAT: file type, 0-11 (generic files) or 99 (.SPC files) '
   print,'*             The file name can also be passed through IDAT'
   print,'*    H,W,F,E: standard output flux vectors'
   print,'*        REC: (optional) record number to extract. Prompted for.'
   print,'*       NAME: (optional) name of data file. Defaults to generic file.'
   print,'*             NAME may also be passed through the IDAT'
   print,'*             NAME searched first in current directory, then in ICURDATA'
   print,' '
   return
   endif
;
RECL=[14400L,6956L,10000L,6144L,9804L,25382L,16384L,16384L,8196L,11608L, $
      13412L,16384L]
idt=idt0
if ifstring(idt) eq 1 then begin     ;string passed
   name=idt
   ext=get_ext(name) 
   if ext eq '' then ext='.dat'
   if n_elements(icurdata) eq 0 then icurdata='[.data]'
   case 1 of
      ffile(name) eq 1:
      ffile(name+ext) eq 1:
      ffile(icurdata+name) eq 1: name=icurdata+name
      ffile(icurdata+name+ext) eq 1: name=icurdata+name
      ffile('[.data]'+name) eq 1: name='[.data]'+name
      ffile('[.data]'+name+ext) eq 1: name='[.data]'+name
      else: begin
         print,' File not found'
         h1=-1
         return         
         end
      endcase
   idt=get_idat(name)          ;determine idat value
   endif 
;
if idt eq 99 then begin        ;read from .SPC file
   icurspc,h1,w1,f1,e1
   h1(0)=99
   return
   endif
;
on_ioerror,erret
AUTO=0    ;full manual
iquery=0  ;1 to query record number
ntype=11
if n_elements(icurdata) gt 0 then ZDDIR=ICURDATA else zddir='[.DATA]'
if idt ge 100 then istd=1 else istd=0  ;standard switch
IF (N_PARAMS(0) GE 6) THEN BEGIN
   IF (REC LT 0) AND (REC NE -999) THEN AUTO=0 ELSE AUTO=1 ;PASS REC IF AUTO=1
   if rec eq -9 then begin
      iquery=1      ;pass recno back
      auto=0
      endif
   ENDIF
GENFIL=STRARR(11)
GENFIL=['LODAT','TKDAT','HIDAT','COUDE','MMT4K','mmt8k','ECHEL','IUEh2', $
         'IUElo','OPT','GHRS','NLOPT']
rpr=[1,1,4,1,1,1,7,11,1,1,1,4]
IDAT=IDT
if (idat eq 1) or (idat eq 6) or (idat ge 9) then ibk=1 else ibk=0
;
if n_elements(name) eq 1 then idat=get_idat(name)
IF IDAT GT 99 THEN IDAT=IDAT-100  ;STANDARD FILES
if (idat eq 0) or (idat eq 2) then iiue=1 else iiue=0    ;iue data
if (idat eq 4) or (idat eq 5) then noeps=1 else noeps=0
if (idat eq 4) or (idat eq 5) then immt=1 else immt=0    ;MMT data
if immt eq 1 then f4=1 else f4=0          ;1 if h(23)*10000. else *1000.
IF iiue eq 1 THEN LWAV=0 else lwav=-1
IF AUTO NE 1 THEN BEGIN
   z='($," Enter record number")'
   print,FORMAT=z
   nrec=''
   READ,NREC
   if strmid(nrec,0,1) eq '[' then nrec=strmid(nrec,4,4)
   ENDIF ELSE NREC=REC
NREC=FIX(NREC)
rec=nrec
;
GET_LUN,LUN
case 1 of
   NREC EQ -999: BEGIN                     ;TEMPORARY STORAGE
      OPENR,LUN,'DAT.TMP'
      NREC=0
      END
   else: BEGIN                             ; NORMAL STORAGE
      IF NREC LT -1 THEN GOTO,RET          ;invalid record
         IF ifstring(name) eq 1 THEN begin     ;file name passed
            if n_elements(name) eq 1 then Z=NAME ELSE $
                        Z=STRTRIM(GENFIL(IDAT),2)+'.DAT'
           endif ELSE BEGIN                 ;IDAT passed
           Z=STRTRIM(GENFIL(IDAT),2)
           IF ISTD EQ 1 THEN Z=ZDDIR+Z+'.STD' ELSE Z=Z+'.DAT'
           endelse
       OPENR,LUN,Z
       if nrec eq -1 then lkdat,z
       if nrec lt 0 then return
      END
   endcase
;
t=fstat(lun)
k=t.rec_len/4
;if !version.os eq 'vms' then begin
;   K=!ERR/4
;   !ERR =-1
;   endif else k=recl(idat)/4
nrec=nrec*rpr(idat)           ;initial record
;
case 1 of
   idat eq 5: begin
      p=assoc(lun,bytarr(k*4))
      f4=1
      end
   ibk eq 1: begin     ;idat=1,6,9,10,11
      p=assoc(lun,bytarr(k*4))
      nrec=1+nrec
      f4=2
      if idat eq 1 then f4=0
      z=p(0)
      k=where(z gt 0b)
      k=max(k)-2
;      print,'records 0 -',fix(k),' used'
      end
   idat eq 7: begin
      p=assoc(lun,bytarr(k*4))
      f4=1
      end
   else: P=ASSOC(LUN,FLTARR(K))
   endcase
Z=P(NREC)
case 1 of
   idat eq 1: iar=long(z,0,3)              ;1
   idat eq 5: iar=fix(z,0,3)               ;5
   idat ge 6: iar=long(z,0,3)              ;6-11
   else: iar=fix(z(0:2))                   ;0,2,3,4
   endcase
IF IAR(0) NE IDAT THEN BEGIN
;     CLOSE,LUN
;     FREE_LUN,LUN
;     RETURN    ; RETURN IF WRONG DATA OR NO DATA
print,' Warning: idat incorrect. Value supplied=',idat,' - file ID=',iar(0)
     ENDIF
;if !version.os eq 'vms' then !ERR=0
;
case 1 of
   idat eq 1: begin    ;general optical format 
      indx=12
      h=fix(z,indx,iar(2))
      h1=intarr(400)
      h1(0)=h
      indx=indx+iar(2)*2
      f1=float(z,indx,iar(1))
      indx=indx+iar(1)*4
      e1=fix(z,indx,iar(1))
      e1=float(e1/10.)        ;10x SNR stored
      lwav=-1
      end
   idat eq 2: begin
      H1=fix(Z(3:IAR(2)-1))
      Z=P(NREC+1)
      W1=Z(0:IAR(1)-1)
      Z=P(NREC+2)
      F1=Z(0:IAR(1)-1)
      Z=P(NREC+3)
      E1=fix(Z(0:IAR(1)-1))
      end
   idat eq 5: begin
      indx=6
      f1=float(z,indx,iar(1))
      indx=6+iar(1)*4
      e1=fix(z,indx,iar(1))
      e1=float(e1)/100.
      indx=indx+iar(1)*2
      h1=fix(z,indx,iar(2))
      end
   idat eq 6: begin    ;long format echelle
      f4=2
      indx=12
      h1=fix(z,indx,iar(2))
      nseg=fix(iar(1)/4096.)+1
      z=p(nrec+1)
      f1=float(z,0,4096)
      for i=1,nseg-1 do begin
         z=p(nrec+1+i)
         f1=[f1,float(z,0,4096)]
         endfor
      f1=f1(0:iar(1)-1)
      z=p(nrec+5)
      e=fix(z,0,8192)
      z=p(nrec+6)
      e1=fix(z,0,8192)
      e=[e,e1]
      e1=e(0:iar(1)-1)/100.
      lwav=-1
      END
   idat eq 7: begin    ;long format IUE data
      indx=12
      h1=fix(z,indx,iar(2))
      z=p(nrec+1)
      f1=float(z,0,4096)
      for i=1,7 do begin
         z=p(nrec+1+i)
         f1=[f1,float(z,0,4096)]
         endfor
      f1=f1(0:(iar(1)-1L)<32767L)
      z=p(nrec+9)
      e=byte(z,0,16384)
      z=p(nrec+10)
      e1=byte(z,0,16384)
      e1=[e,e1]
      e1=e1(0:(iar(1)-1L)<32767L)
      lwav=-1
      END
   idat eq 8: begin    ;new format low dispersion IUE data
      indx=12
      h1=fix(z,indx,iar(2))
      indx=indx+iar(2)*2
      f1=float(z,indx,iar(1))
      indx=indx+iar(1)*4
      e1=fix(z,indx,iar(1))
      lwav=-1
      end
   idat eq 9: begin    ;general optical format 
      indx=12
      h=fix(z,indx,iar(2))
      h1=intarr(400)
      h1(0)=h
      indx=indx+iar(2)*2
      f1=float(z,indx,iar(1))
      e1=f1*0
      lwav=-1
      END
   idat eq 10: begin    ;GHRS format
      f4=2                                   ;double precision
      indx=12
      h1=fix(z,indx,iar(2))
      indx=indx+iar(2)*2
      f1=float(z,indx,iar(1))
      indx=indx+iar(1)*4
      e1=fix(z,indx,iar(1))            ;S/N vector
      e1=e1/100.
      lwav=-1
      END
   idat eq 11: begin    ;non-linear optical format 
      h1=fix(z,12,iar(2))
      z=p(nrec+1)
      f1=float(z,0,iar(1))
      z=p(nrec+2)
      w1=float(z,0,iar(1))
      z=p(nrec+3)
      e1=float(z,0,iar(1))
      lwav=0
      end
   else: begin
   INDX=3
   IF LWAV NE -1 THEN BEGIN
      W1=Z(3:2+IAR(1)) & INDX=INDX+IAR(1)
      ENDIF
   F1=Z(INDX:indx+IAR(1)-1) & INDX=INDX+IAR(1)
   IF noeps eq 0 THEN BEGIN      ;eps not saved for MMT data
      E1=Z(INDX:indx+IAR(1)-1) & INDX=INDX+IAR(1)
      if idat eq 0 then e1=fix(e1)
      ENDIF ELSE E1=F1*0.+100.
   H1=fix(Z(INDX:(indx+IAR(2)-1)<(N_ELEMENTS(Z)-1)))
   end
endcase
CLOSE,LUN & FREE_LUN,LUN
;
h1(7)=iar(1)
IF LWAV EQ -1 THEN BEGIN   ;CONSTRUCT WAVELENGTH VECTOR
   case 1 of
      f4 eq 1: FACT=1.E4
      f4 eq 2: fact=1.D4
      ELSE:    FACT=1000.
      endcase
   W0=FLOAT(H1(20))+FLOAT(H1(21))/FACT
   DW=FLOAT(H1(22))+FLOAT(H1(23))/FACT
   W1=W0+DW*FINDGEN(IAR(1))
   h1(199)=333                       ;linear
   h1(19)=fix(fact)
   ENDIF else h1(199)=0
IF (IDAT EQ 3) or (immt eq 1) THEN F1=F1/DW/H1(5)  ;CONVERT TO F/S/A
if idat eq 7 then begin
      restgap,h1,w1   ;restore gaps in data
;      f1=avspt(f1,e1)   ;cut single point zeros
      endif
H1(0)=IDAT
NCAM=H1(3)
IMAGE=H1(4)
if image lt 0 then image=image+65536L     ;fullword image number
IF NCAM LT 5 THEN BEGIN
   CAMERA=STRMID('    LWP LWR SWP SWR',NCAM*4,4)
   Z=CAMERA+STRTRIM(STRING(IMAGE),2)
   ENDIF
case 1 of
   !QUIET EQ 3: GOTO,RET   ;supress header data
   IDAT EQ 0: PRINT,Z+'L'
   IDAT EQ 2: PRINT,Z+'H'
   IDAT EQ 7: PRINT,Z+'H  ',STRING(BYTE(H1(100:159))>32b)
   IDAT EQ 8: PRINT,Z+'L  ',STRING(BYTE(H1(100:159))>32b)
   NCAM GE 10: PRINT,STRING(BYTE(H1(100:159))>32b)
   else:
   endcase
;
RET:
on_ioerror,null
close,lun
free_lun,lun
RETURN
erret:   ;io error
h1=-1     ;flag
on_ioerror,null
print,' no such record: returning'
close,lun
free_lun,lun
return
END
