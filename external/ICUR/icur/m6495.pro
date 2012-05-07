;*******************************************************************
PRO M6495,file,recs,iprt
if n_params(0) eq 0 then file=1
if n_params(0) lt 2 then recs=indgen(999)    ;all records
if n_params(0) lt 3 then iprt=0    ;no print
if n_elements(recs) eq 1 then recs=intarr(1)+recs
;
if ifstring(file) ne 1 then begin        ;integer file passed
   if file eq -1 then begin    ;help
      print,' ' 
      print,'* M6495  -  measure 6495A magnitude for Stocke''s B-V correlation'
      print,'* calling sequence:  M6495,file,recs,iprt'
      print,'*    file: name of file, -1 for help'
      print,'*          default=TKDAT.DAT '
      print,'*    recs: list or records to measure, default=all in file'
      print,'*    iprt: 1 to print listing; 0 (default) for noprint'
      print,'*          2 generates M6495.dta file (input to M6495cor)'
      print,'*          output is in file M6495.LST on disk'
      print,' ' 
      return
      endif 
   endif
;
if recs(0) eq -1 then recs=indgen(999)
recs=fix(recs)
n=n_elements(recs)
if n eq 999 then print,' Measuring all records' else PRINT,N,' records to measure'
L=[6490.0,6500.0,6445.0,6545.0]
OPENW,lu,'M6495.LST',/get_lun
if iprt eq 2 then OPENW,lu2,'M6495.dta',/get_lun
PRINTF,lu,' John Stocke"s lambda 6495 magnitude/B-V calibration'
PRINTF,lu,' Narrow band: ',L(0),L(1)
PRINTF,lu,' Broad band:  ',L(2),L(3)
printf,lu,' Data from file ',file
printf,lu,' '
FOR I=0,N-1 DO BEGIN
   GDAT,file,H,W,F,E,recs(i)
   if n_elements(h) eq 1 then goto,done    ;no more records
   LAB=STRTRIM(BYTE(H(100:139)>32),2)
   NW=N_ELEMENTS(W)
   IF (L(2) LT W(0)) OR (L(3) GT W(NW-1)) THEN goto,skip
   indx=xindex(w,l)              ;TABINV,W,L,INDX
   INDX=FIX(INDX+0.5)
   IN=INDX(1)-INDX(0)
   DN=W(INDX(1))-W(INDX(0))
   FN=TOTAL(F,INDX(0),IN)/DN
   IB=INDX(3)-INDX(2)
   DB=W(INDX(3))-W(INDX(2))
   FB=TOTAL(F,INDX(2),IB)/DB
   DM=-2.5*ALOG10(FN/FB)
   r=string(recs(i),'(I3)')
   bmv=0.358+6.415*dm
   dbmv=0.041+0.47*dm
   dm=string(dm,'(F4.2)')
   bmv=string(bmv,'(F4.2)')
   dbmv=0.15
   PRINTF,lu,' Rec:',R,' dM = ',DM,' B-V= ',bmv,' +\- ',dbmv,' ',LAB
   if iprt eq 2 then printf,lu2,recs(i),dm,'   ',lab
   SKIP: 
   ENDFOR
done: CLOSE,lu
free_lun,lu
if iprt eq 2 then begin
   close,lu2
   free_lun,lu2
   endif
if abs(iprt) eq 1 then spawn_print,'m6495.lst'
RETURN
END
