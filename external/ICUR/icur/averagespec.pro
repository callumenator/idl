;*******************************************
function AVerageSPEC,FILE,i1,i2,w,save=save,helpme=helpme,noweight=noweight
if n_params(0) lt 2 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* AVERAGESPEC - average spectra in .ICD file '
   print,'* calling sequence: f=averagespec(file,i1,i2,w) or f=averagespec(file,rec,w)'
   print,'* default uses time weighting'
   print,'*    FILE: name of .ICD file'
   print,'*    I1,I2: first and last records to be averaged'
   print,'*    REC:  list of records to be averaged'
   print,'*    W:    output wavelength vector (optional)'
   print,'* '
   print,'* KEYWORDS'
   print,'*    NOWEIGHT: if set, do straight average, default weights by times'
   print,'*    SAVE: if set, append average spectrum to end of input .ICD file'
   print,' '
   return,0
   end
;
ext=get_ext(file)
if strlen(ext) eq 0 then ext='.icd'
if not ffile(file+ext) then begin
   ic=getenv('icurdata')
   if ffile(ic+file+ext) then file=ic+file else begin
      print,' file ',file,' not found - returning'
      return,0
      endelse
   endif
if n_elements(i1) gt 1 then irec=1 else irec=0
if irec then k=i1 else k=i1+indgen(i2-i1+1)
nr=n_elements(k)
if nr lt 2 then begin
   print,' AVERAGESPEC error: less than 2 files specified - returning'
   if keyword_set(stp) then stop,'AVERAGESPEC>>>'
   return,0
   endif
gdat,file,h,w,f,e,k(0)
time=h(5)
if time lt 0 then time=-60.*time
if time eq 0 then noweight=0
if not keyword_set(noweight) then f=f*time
for j=1,nr-1 do begin
   i=k(j)
   gdat,file,h,w1,f1,e,i
   f1=interpol(f1,w1,w)
   if not keyword_set(noweight) then f1=f1*time
   f=f+f1
   t=h(5)
   if t lt 0 then t=-60.*t
   time=time+t
   endfor
f=f/nr
if not keyword_set(noweight) then f=f/time
if irec then i2=w
print,'Total time in average spectrum = ',time,' seconds'
if keyword_set(save) then begin
   if time gt 32767 then time=-fix(time/60.) else time=fix(time)
   h(5)=time
   h(100)=byte('Average of records '+strtrim(i1,2)+' - '+strtrim(i2,2))
   kdat,file,h,w,f,e,-1
   endif
if keyword_set(stp) then stop,'AVERAGESPEC>>>'
return,f
end
