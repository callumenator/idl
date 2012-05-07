;*******************************************************************
PRO intflux,file,recs,wl,prt=prt
if n_params(0) eq 0 then file=1
if n_params(0) lt 2 then recs=indgen(999)    ;all records
if not keyword_set(prt) then iprt=0 else iprt=prt   ;no print
if n_elements(recs) eq 1 then recs=intarr(1)+recs
ihelp=0
if n_params(0) lt 1 then ihelp=1
if ifstring(file) ne 1 then begin        ;integer file passed
   if file eq -1 then ihelp=1
   endif
if ihelp eq 1 then begin
   print,' ' 
   print,'* intflux  -  measure integrated flux from spectrum
   print,'* calling sequence:  INTFLUX,file,recs,wavelengths'
   print,'*    file: name of file, -1 for help'
   print,'*          default=TKDAT.ICD '
   print,'*    recs: list or records to measure, default=all in file'
   print,'*    wavelengths: array of 2 wavelengths to integrate over'
   print,'*  keywords: PRT:  1 to print listing; 0 (default) for noprint'
   print,'*                  2 generates intflux.dta file'
   print,'*                  output is in file INTFLUX.LST on disk'
   print,' ' 
   return
   endif 
;
if recs(0) eq -1 then recs=indgen(999)
recs=fix(recs)
n=n_elements(recs)
if n eq 999 then print,' Measuring all records' else PRINT,N,' records to measure'
if n_params(0) lt 2 then wl=[3925.,3975.]
get_lun,lu
OPENW,lu,'INTFLUX.LST'
if iprt eq 2 then begin
   get_lun,lu2
   OPENW,lu2,'INTFLUX.dta'
   endif
PRINTF,lu,' INTFLUX,
PRINTF,lu,' Wavelength limits: ',wL(0),wL(1)
printf,lu,' Data from file ',file
printf,lu,' '
FOR I=0,N-1 DO BEGIN
   GDAT,file,H,W,F,E,recs(i)
   if n_elements(h) eq 1 then goto,done    ;no more records
   LAB=STRTRIM(BYTE(H(100:139)>32),2)
   NW=N_ELEMENTS(W)
   IF (wL(0) LT W(0)) OR (wL(1) GT W(NW-1)) THEN goto,skip
   indx=xindex(w,wl)       ;TABINV,W,wL,INDX
   INDX=FIX(INDX+0.5)
   IN=INDX(1)-INDX(0)
   DN=W(INDX(1))-W(INDX(0))
   FN=TOTAL(F,INDX(0),IN)        ;/DN
   r=string(recs(i),'(I3)')
   PRINTF,lu,' Rec:',R,' Integrated flux=',FN,' ',LAB
   if iprt eq 2 then printf,lu2,recs(i),fn,'   ',lab
   SKIP: 
   ENDFOR
done: CLOSE,lu
free_lun,lu
if iprt eq 2 then begin
   close,lu2
   free_lun,lu2
   endif
if abs(iprt) eq 1 then spawn_print,'intflux.lst'
RETURN
END
