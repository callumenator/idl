;**********************************************************************
pro specmerge,w,f,e,r1,r2,f10,f20,wtype,stp=stp,weight=weight,head=head, $
    vector=vector,helpme=helpme
if n_params(0) lt 4 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* SPECMERGE - merge two spectra into one   (10/29/98)'
   print,'*    calling sequence: SPECMERGE,W,F,E,R1,R2,F1,F2,WTYPE'
   print,'*       W,F,E : output wavelength, flux, and epsilon vectors'
   print,'*       R1,R2 : input record numbers. R2 default=R1+1
   print,'*       F1,F2 : input file(s), def F2=F1, def F1=LODAT.DAT'
   print,'*       WTYPE : def=0 to merge W vectors, >0 to interpolate to WTYPE bins'
   print,'*'
   print,'* KEYWORDS:'
   print,'*    VECTOR: set if W,F,E are input vectors
   print,'*    WEIGHT: set to weight by S/N'
   print,'*'
   print,'*  method: does disk I/O, then calls VMERGE'
   print,' '
   return
   endif
;
if n_params(0) lt 5 then r2=r1+1
if n_params(0) lt 6 then f10='LODAT'
if n_params(0) lt 7 then f20=f10
if n_params(0) lt 8 then wtype=0
f1=f10 & f2=f20
wtype=wtype>0
if keyword_set(vector) then begin
   w1=w & f1=f & e1=e
   r2=r1 & f20=f10
   endif else begin
   gdat,f10,h1,w1,f1,e1,r1
   if n_elements(h1) eq 1 then begin
      print,' Record',r1,' of file ',f10,' not found: returning'
      endif
   endelse
;
f20=strtrim(f20,2)
if not ffile(f20+'.icd') then begin
   f2a=getenv('icurdata')+f20
   if not ffile(f2a+'.icd') then begin
      f2a=getenv('userdata')+f2
      if not ffile(f2a+'.icd') then begin
         bell
         print,' file ',f2,' not found in working directory, userdata, or icurdata'
stop
         return
         endif else f2=f2a
      endif else f2=f2a
   endif
gdat,f2,h2,w2,f2,e2,r2
if n_elements(h2) eq 1 then begin
   print,' Record',r2,' of file ',f2,' not found: returning'
   endif
;
if keyword_set(vector) then h1=h2
;
vmerge,h1,w1,f1,e1,h2,w2,f2,e2,head,w,f,e,weight=weight,wtype=wtype
;
if keyword_set(stp) then stop,'SPECMERGE>>>'
return
end
