;*********************************************
function fitsexts,file,enames,nmax=nmax,stp=stp,helpme=helpme,quiet=quiet
if n_elements(file) eq 0 then helpme=1
if not ffile(file) and noext(file) then file=file+'.fits'
if not ffile(file) then helpme=1
if keyword_set(helpme) then begin
   print,''
   print,'* FITSEXTS: return number of FITS extensions'
   print,'* calling sequence: n=FITSEXTS(file,extnames)'
   print,'*    FILE: name of fits file'
   print,'*    EXTNAMES: returned extension names'
   print,'*'
   print,'* KEYWORDS:'
   print,'*   NMAX:  maximum number of extensions to read, def=1000 '
   print,'*   QUIET: set to suppress terminal I/O'
   print,''
   return,0
   endif
if n_elements(stp) eq 0 then stp=0
if n_elements(nmax) eq 0 then nmax=1000
enames=strarr(nmax)
i=0
on_ioerror,done
!error=0
for i=0,nmax-1 do begin
   d=readfits(file,h,ext=i,/nodata,/silent)
   if !error lt 0 then goto,done
   extname=sxpar(h,'extname')
   if not keyword_set(quiet) then print,i,' ',extname
   enames(i)=strtrim(extname,2)
   if stp gt 1 then stop,'FITSEXTS(2)>>>'
   endfor
done:
i=i-1
if i eq 0 then i0='No' else i0=strtrim(i,2)
if not keyword_set(quiet) then print,i0,' extensions found in ',file 
enames=enames(0:i)
if stp then stop,'FITSEXTS>>>'
return,i
end
