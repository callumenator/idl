;********************************************************************
pro prt_fits,file,ext,out=out,helpme=helpme,stp=stp,short=short
if n_elements(file) eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* PRT_FITS: print ascii fits extension into text file'
   print,'* calling sequence: PRT_FITS,FILE,EXT'
   print,'*    FILE: name of input fits file'
   print,'*    EXT: number of FITS extension, def=1'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    OUT: name of output .prt file, def=FILE.PRT'
   print,' '
   return
   endif
;
if n_elements(out) eq 0 then out=file
out=out+'.prt'
if n_elements(ext) eq 0 then ext=1
;
d=readfits(file,h,ext=ext)
t=string(d)
if keyword_set(short) then t=strmid(t,0,78)
nl=n_elements(t)
;
openw,lu,out,/get_lun
printf,lu,t
close,lu
free_lun,lu
print,' Output is in ',out
;
if keyword_set(stp) then stop,'PRT_FITS>>>'
return
end
