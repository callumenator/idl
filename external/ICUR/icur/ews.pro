;**********************************************************************
pro ews,file,r1,r2
ihlp=0
if n_params(0) eq 0 then file=-1
if not ifstring(file) then begin
   if file eq -1 then ihlp=1
   endif
if ihlp eq 1 then begin
   print,' '
   print,'* EWS - loop on EQWID through ICUR data file'
   print,'*    calling sequence: EWS,file,r1,r2'
   print,'*       file: name of .data file, or type for generic file'
   print,'*       r1,r2: records to measure, default=all'
   print,'*    output in EQWID.LST'
   print,' '
   return
   endif
;
if not ifstring(file) then begin
   if (file lt 0) or (file gt 110) then begin
      print,' generic file type = ',file,' outside valid range'
      return
      endif
   endif
if n_params(0) lt 3 then r2=9999
if n_params(0) lt 2 then r1=0
;
;set up eqwid params
;
print,' enter -1 for defaults'
read,' Enter wavelength of feature: ',lamcen
read,' Enter width for feature extraction: ',dl
read,' Enter wavelength of first background region: ',b1
read,' Enter wavelength of second background region: ',b2
read,' Enter width of first background region: ',db1
if db1 eq -1 then db2=-1 else read,' Enter width of second background region: ',db2
;
outfile='eqwid.lst'
openw,lu,outfile,/get_lun
printf,lu,' EQWID output, data file=',file,'  run at ',systime(0)
printf,lu,'   Feature at ',lamcen,' A, box width=',dl,' A.'
printf,lu,'   Background bins begin at ',b1,b2,' A., box widths=',db1,db2
printf,lu,' '
printf,lu,'Record   Equivalent width    Object'
;
for i=r1,r2 do begin
   gdat,file,h,w,f,e,i
   if n_elements(h) eq 1 then goto,done      ;record does not exist
   ew=eqwid(w,f,lamcen,dl,b1,b2,db1,db2)
   if ew gt -9998. then begin
      sew=string(ew,format='(F6.2)')
      printf,lu,i,sew,'  ',strtrim(byte(h(100:158)),2)
      print,i,sew,'  ',strtrim(byte(h(100:158)),2)
      endif    ;-9999 if invalid region
   endfor
;
done:
close,lu
free_lun,lu
print,' output in ',outfile
return
end
