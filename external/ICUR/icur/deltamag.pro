;*******************************************************************
PRO deltamag,file,recs,w0,dw1,dw2,prt=prt
if n_params(0) eq 0 then file=-1
if ifstring(s) ne 1 then begin    ;integer file passed
   if file eq -1 then begin    ;help
      print,' ' 
      print,'* DELTAMAG  -  narrow band magnitude index
      print,'* calling sequence:  DELTAMAG,file,recs,w0,dw1,dw2,'
      print,'*    file: name of file, no default'
      print,'*    recs: list or records to measure, default(-1)=all in file'
      print,'*      w0: central wavelength, defaults: (0) = 6563.'
      print,'*          w0=-1 for Stocke''s 6495A correlation'
      print,'*     dw1: narrow band width,  default (0) = 5A'
      print,'*     dw2: broad band width,   default (0) = 50A'
      print,'*'
      print,'* KEYWORDS:
      print,'*    IPRT: 1 to print listing; 0 (default) for noprint'
      print,'*          2 generates deltamag.dta file (input to deltamagcor)'
      print,'*          output is in file DELTAMAG.LST on disk'
      print,'*'
      print,'*   magnitude index = f(narrow)/f(broad)
      print,' ' 
      return
      endif
   endif
k=strpos(string(file),'jacobyatlas')
if k ne -1 then ibmv=1 else ibmv=0      ;1 if B-V stored in header
if n_params(0) lt 2 then recs=indgen(999)
if n_elements(recs) eq 1 then recs=intarr(1)+recs
if recs(0) eq -1 then recs=indgen(999)
;
if n_params(0) lt 3 then w0=0
case 1 of
   w0 eq 0: begin
      w0=6563. & dw1=5. & dw2=50.
      idef=0
      end
   w0 eq -1: begin
      w0=6495. & dw1=5. & dw2=50.
      idef=1
      end
   else: begin
      idef=-999
      if n_params(0) lt 4 then dw1=5.
      if dw1 lt 0. then dw1=5.
      if n_params(0) lt 5 then dw2=50.
      if dw2 lt 0. then dw2=50.
      end
   endcase
;
if dw1 gt dw2 then begin    ;flip band widths
   t=dw1
   dw1=dw2
   dw2=t
   endif
if dw1 eq dw2 then begin
   print,' band widths equal - null measurement'
   return
   endif
;
recs=fix(recs)
n=n_elements(recs)
if n eq 999 then print,' Measuring all records' else PRINT,N,' records to measure'
L=[w0-dw1,w0+dw1,w0-dw2,w0+dw2]
get_lun,lu
k=strpos(file,']')
if k eq -1 then ff=file else ff=strmid(file,k+1,32)
k=strpos(ff,'.')
if k ne -1 then ff=strmid(ff,0,k)
outfile='dm'+ff+strtrim(string(fix(w0)),2)+'.lst'
OPENW,lu,outfile
printf,lu,' Central wavelength:',w0,'A'
if idef eq 0 then printf,lu,' H-alpha dM/log B-V calibration'
if idef eq 1 then printf,lu,' John Stocke''s lambda 6495/B-V calibration'
PRINTF,lu,' Narrow band: ',L(0),L(1),' width=',dw1,'A'
PRINTF,lu,' Broad band:  ',L(2),L(3),' width=',dw2,'A'
if n_params(0) gt 1 then printf,lu,' Data from file ',file
if iprt eq 2 then begin
   OPENW,lu2,'DELTAMAG.dta',get_lun
   printf,lu2,w0,dw1,dw2
   endif
printf,lu,' '
FOR I=0,N-1 DO BEGIN
   GDAT,file,H,W,F,E,recs(i)
   if n_elements(h) eq 1 then goto,done    ;no more records
   LAB=STRTRIM(BYTE(H(100:139)>32),2)
   NW=N_ELEMENTS(W)
   IF (L(2) LT W(0)) OR (L(3) GT W(NW-1)) THEN goto,skip
   indx=fix(xindex(w,l)+0.5)                    ;TABINV,W,L,INDX
   IN=INDX(1)-INDX(0)
   DN=W(INDX(1))-W(INDX(0))
   FN=TOTAL(F,INDX(0),IN)/DN
   IB=INDX(3)-INDX(2)
   DB=W(INDX(3))-W(INDX(2))
   FB=TOTAL(F,INDX(2),IB)/DB
   DM=-2.5*ALOG10(FN/FB)
   bmv0=float(h(63))/1000.
   r=string(recs(i),'(I3)')
   case 1 of
      idef eq 0: begin      ;Halpha
         bmv=10^(0.18-2.17*dm)
         dbmv=10^(0.006+0.06*dm)
         dm=string(dm,'(F4.2)')
         bmv=string(bmv,'(F5.2)')
         printf,lu,' Rec:',r,' dM = ',dm,' B-V=',bmv,' +/- ',dbmv,'  ',lab
         end
      idef eq 1: begin      ; 6495
         bmv=0.358+6.415*dm
         dbmv=0.041+0.47*dm
         dm=string(dm,'(F4.2)')
         bmv=string(bmv,'(F5.2)')
         dbmv='0.15'
         printf,lu,' Rec:',r,' dM = ',dm,' B-V=',bmv,' +/- ',dbmv,'  ',lab
         end
      else: begin
         PRINTF,lu,' Rec:',R,'  delta magnitude (narrow-broad) =',DM,' ',LAB
         end
      endcase
   if iprt eq 2 then begin
      if ibmv eq 1 then printf,lu2,recs(i),' ',dm,bmv0,'   ',lab $
         else printf,lu2,recs(i),' ',dm,'   ',lab
      endif
   SKIP: 
   ENDFOR
done: CLOSE,lu
free_lun,lu
if iprt eq 2 then begin
   close,lu2
   free_lun,lu2
   endif
print,' Output file is named ',outfile
if abs(iprt) eq 1 then spawn_print,outfile
RETURN
END
