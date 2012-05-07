;************************************************************
pro gnd,h,wave,flux,eps,flag,recno,badw,badf,reset=reset,stp=stp,std=std
COMMON COM1,H0,IK,IFT,NSM,C,NDAT,IFSM,KBLO,H1
COMMON COMXY,XCUR,YCUR,ZERR,RS,LU3,ieb
COMMON ICDISK,ICURDISK,ICURDATA,ISMDATA,OBJFILE,STDFILE
;
IMN=0
ZCAM='     LWP LWR SWP SWR '
IF KEYWORD_SET(RESET) THEN !y.range(*)=0.
IF N_ELEMENTS(RECNO) GT 0 THEN OLDREC=RECNO
if flag eq 0 then recno=-9     ;CALLED FROM <ESC>
;
if keyword_set(std) then vfile=stdfile else vfile=objfile
if vfile eq 'nofile' then begin
   print,' There is no data file defined'
   return
   endif
;
SEARCHDIR,vfile,'.icd'
;
IF N_ELEMENTS(H) GT 0 THEN HSAVE=H
IF N_ELEMENTS(WAVE) GT 0 THEN WSAVE=WAVE
IF N_ELEMENTS(FLUX) GT 0 THEN FSAVE=FLUX
IF N_ELEMENTS(EPS) GT 0 THEN ESAVE=EPS
;
GDAT,vfile,H,WAVE,FLUX,EPS,RECNO
IF RECNO EQ -99 THEN BEGIN
   IF N_ELEMENTS(OLDREC) GT 0 THEN RECNO=OLDREC
   IF N_ELEMENTS(HSAVE) GT 0 THEN H=HSAVE
   IF N_ELEMENTS(WSAVE) GT 0 THEN WAVE=WSAVE
   IF N_ELEMENTS(FSAVE) GT 0 THEN FLUX=FSAVE
   IF N_ELEMENTS(ESAVE) GT 0 THEN EPS=ESAVE
   PRINT,' Aborting GND: Old data retained'
   RETURN
   ENDIF
nh=n_elements(h)
if nh eq 1 then begin
   h=intarr(1)+h
   if h(0) lt 0 then return
   endif      
if h(3) le 4 then begin                      ;change time
   if h(39) gt 540 then h(5)=-h(39) else h(5)=60*h(39)+h(40)
   h(39:41)=0
   endif
if h(8) eq 1 then begin    ;convert vacuum wavelengths to air wavelengths
   if max(wave) gt 2000. then vactoair,wave
   endif
if nh gt 33 then begin
   IF H(33) EQ 30 then begin     ;correct S/N vector - force positive
      k=where((eps lt 0.) and (eps gt -1000.),nk)   ;retain very negative as flags
      if nk gt 0 then eps(k)=abs(eps(k))
      endif
   endif
;
if not keyword_set(std) then begin
   bdata,h,-1,wave,flux,eps,badw,badf
   h0=h
   IFSM=0
   if n_elements(lu3) eq 1 then begin
      PRINTF,lu3,'-1' & PRINTF,lu3,'*** New data retrieved'
      PRINTF,lu3,' 0'
      endif
   IF H(3) LE 4 THEN BEGIN
      CAMERA=STRMID(ZCAM,H(3)*4,4)
      if h(4) lt 0 then imn=65536L+h(4) else imn=h(4)
      if n_elements(lu3) eq 1 then $
         PRINTF,lu3,H(3),IMN,' IUE camera= ',CAMERA ,' IMAGE=',imn
      ENDIF ELSE begin
      if n_elements(lu3) eq 1 then $
         PRINTF,lu3,H(3),H(4),' : ',string(byte(h(100:159))>32b)
      endelse
   case 1 of
      h(33) eq 30:
      h(33) eq 40:
      else: ieb=0
      endcase
   IF H(34) NE 2 THEN BEGIN
      H(35)=0 & H(39)=0
      ENDIF
   case 1 of
    H(3) LE 4: !P.TITLE=STRTRIM(STRMID(ZCAM,H(3)*4,4),2)+' '+ STRTRIM(imn,2)+' '
      h(3) eq 100: begin    ;GHRS data
         if h(4) ne 0 then !p.title='H'+strtrim(h(4),2)+' ' else !p.title=''
         end
      ELSE: !P.TITLE=''
      endcase
;
   !P.TITLE=!p.title+STRTRIM(BYTE(H(100:139))>32b,2)
   case 1 of
      h(3) eq 80: !y.title=ytit(9)
      h(3) eq 81: !y.title=ytit(10)
      h(3) eq 82: !y.title=ytit(0)
      else:
      endcase
   endif     ;not std
;
if keyword_set(stp) then stop,'GND>>>'
return
end
