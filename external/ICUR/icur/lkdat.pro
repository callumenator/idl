;**********************************************************************
PRO LKDAT,IDAT0,n1,n2    ; LIST CONTENTS OF REDUCED DATA FILES
if n_params() eq 0 then ihlp=1 else ihlp=0
hlp:
if ihlp eq 1 then begin
   print,'**********************************************************'
   print,' LKDAT must be called with at least one argument'
   print,'   The allowable call is: LKDAT,idat,n1,n2'
   print,'      idat:   either an integer or a string'
   print,'              -999 for DAT.TMP'
   print,'              -1    : query for file name+extension'
   print,'              string: file name, assumed .DAT'
   print,'                      ? for help'
   print,'              0-11  : generic file of this type'
   print,'      n1,n2:  optional record limits to print out.'
   print,'              n1 = -1 sends the listing to LKDAT.LST'
   print,'              n1 = -2 sends the listing to LKDAT.LST and'
   print,'                    to the line printer'
   print,'
   print,'**********************************************************'
   return
   endif
idat=idat0
NAME=IDAT
ntype=11
GENFIL=STRARR(ntype)
GENFIL=['LODAT','TKDAT','HIDAT','COUDE','MMT4K','mmt8k','ECHEL','IUEh2', $
         'IUElo','OPT','GHRS','NLOPT']
recfil=[1,1,4,1,1,1,7,11,1,1,1,4]   ;number of records per spectrum
indx=intarr(ntype+1)+6          ;bytes per IAR record
k=[1,6,7,8,9,10,11]
indx(k)=12    ;longwords in IAR
iprt=0        ;listing to terminal
;
IF not ifstring(name) THEN BEGIN        ;idat = number
   CASE 1 OF
   idat gt ntype: return
   idat eq -1: begin   ;enter your own file name
      name=' '
      read,' enter full file name, 0 for help ',name
      if name eq '0' then begin
         ihlp=1
         goto,hlp
         endif
      end
   idat eq -999: begin  ;temporary file
      name='dat.tmp'
      idat=-1
      end
   idat ge 0: NAME=GENFIL(IDAT)
   else:  print,idat
   ENDCASE 
   endif ELSE begin
   if name eq '?' then begin
      ihlp=1
      goto,hlp
      endif else IDAT=-2
   endelse
;
if idat ne -1 then begin
   k=strpos(name,'.')
   if k eq -1 then FILE=NAME+'.DAT' else file=name
   endif else file=name
on_ioerror, errret
if idat eq -2 then idat=get_idat(file)    ;idat unknown
if (idat ge 5) or (idat eq 1) then inew=1 else inew=0
OPENR,LUN,FILE,/get_lun
t=fstat(lun)
zerr=t.rec_len
K=ZERR/4
if (idat eq 1) or (idat eq 6) or (idat ge 9) then ibk=1 else ibk=0
case 1 of
   inew eq 1: p=assoc(lun,bytarr(k*4))
   else:      P=ASSOC(LUN,FLTARR(K))
   endcase
if ibk eq 1 then z=p(1) else z=p(0)
case 1 of
   idat eq 1: iar=long(z,0,3)
   idat eq 5: iar=fix(z,0,3)
   idat ge 6: iar=long(z,0,3)
   else: iar=fix(z(0:2))
   endcase
close,LUN
;
IDAT=IAR(0)
LWAV=3
IF (IDAT EQ 1) OR (IDAT EQ 3) THEN LWAV=2
IF (IDAT EQ 4) or (idat eq 5) THEN LWAV=1
DATE=SysTIME(0)
zz=STRING(FILE)+' LISTED ON '+string(DATE)
if (n_params(0) ge 2) then begin
   if n1 lt 0 then begin
      iprt=abs(n1)     ;listing to LP:
      get_lun,lu
      openw,lu,'lkdat.lst'
      endif
   endif
if iprt eq 0 then print,zz else printf,lu,zz
zz=' Data type '+strtrim(idat,2)
if iprt eq 0 then print,zz else printf,lu,zz
i=-1
if n_params(0) ge 2 then i=n1-1
if i lt -1 then i=-1
if n_params(0) ge 3 then imax=n2 else imax=9999
openr,LUN,file
while not eof(LUN) do begin
   i=i+1
   if i gt imax then goto,donelist
   II=I*recfil(idat)
   if ibk eq 1 then ii=ii+1
   Z=P(II)
   nz=n_elements(z)-1
   case 1 of
      idat eq 1: iar=long(z,0,3)
      idat eq 5: iar=fix(z,0,3)
      idat ge 6: iar=long(z,0,3)
      else: iar=fix(z(0:2))
      endcase
;
   case 1 of                        ;read header
      ibk eq 1: h1=fix(z,indx(idat),iar(2))
      idat eq 2: H1=fix(Z(3:IAR(2)-1))  
      idat eq 5: begin
         ind=indx(idat)+iar(1)*4+iar(1)*2
         h1=fix(z,ind,iar(2))
         end
      (idat eq 7) or (idat eq 8): h1=fix(z,indx(idat),iar(2))
      else: H1=fix(Z(3+LWAV*IAR(1):(3+lwav*iar(1)+IAR(2))<nz))
      endcase
   z=p(ii+recfil(idat)-1)    ;set to end of this spectrum
   H1=FIX(H1)
   NCAM=H1(3)
   if h1(4) lt 0 then image=h1(4)+65536L else IMAGE=H1(4)
   Z0='REC '+STRING(I,'(I3)')+': '
   IDT=FIX(H1(10:12))
   LAB=BYTE(H1(100:159))>32b
   IF NCAM LT 5 THEN BEGIN
      CAMERA=STRMID('    LWP LWR SWP SWR',NCAM*4,4)
      Z=Z0+CAMERA+STRTRIM(STRING(IMAGE),2)
      if (IDAT EQ 0) or (idat eq 8) then z=Z+'L' else z=z+'H'
      endif else begin
   Z=Z0+STRING(IDT(0),'(I2)')+' '+STRING(IDT(1),'(I2)')+' '+STRING(IDT(2),'(I2)')
      if idat eq 10 then z=z+' obs:'+strtrim(image,2)
      z=Z+' '+STRTRIM(LAB,2)
      ENDelse
   if (idat eq 7) or (idat eq 8) then z=z+' '+strtrim(lab,2)
   if iprt eq 0 then print,z else printf,lu,z
   endwhile
donelist:
CLOSE,LUN & FREE_LUN,LUN
if iprt ge 1 then begin
   close,lu
   free_lun,lu
   if iprt eq 2 then spawn_print,'lkdat.lst'
   endif
return
errret:
if not ffile(file) then print,' File ',file,' not found' else print,' I/O error'
RETURN
END
