;************************************************************************8
pro wiyn_vel_update,file,velfile,stp=stp,wave=wave,helpme=helpme,do2=do2, $
    auto=auto
;
if n_params(0) eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* WIYN_VEL_UPDATE '
   print,'* updates radial velocity word in .ICD file from data in the _XCOR'
   print,'*    file created by HXCOR'
   print,'* '
   print,'* Calling sequence: wiyn_vel_update,file,velfile'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    AUTO:   use _A filer (autocorrelation)'
   print,'*    DO2:    use _2 file'
   print,'*    WAVE:   use _W file'
   print,'*    HALPHA: use _H file'
   print,' '
   return
   endif
;
icdfile=file+'.icd'
if not ffile(icdfile) then begin
   print,' File ',icdfile,' not found - returning'
   return
   endif
if n_elements(velfile) eq 0 then velfile=file+'_xcor'
case 1 of
   keyword_set(wave): velfile=velfile+'_w'
   keyword_set(halpha): velfile=velfile+'_h'
   keyword_set(do2): velfile=velfile+'_2'
   keyword_set(auto): velfile=velfile+'_a'
   else:
   endcase
velfile=velfile+'.sav'
arr=fltarr(12,100)
ids=strarr(100)
if not ffile(velfile) then begin
   print,' WARNING: cross correlation save file ',velfile,' not found - returning'
   bell,3
   return
   endif
restore,velfile
np=n_elements(ids)
s=size(arr)
if s(1) eq 12 then do2=1 else do2=0
print,s
iicd=-1
for i=0,np-1 do begin
   z=strtrim(ids(i),2)
;   z=strtrim(strmid(z,23,60),2)
   k=strpos(z,'sky')
   if k eq -1 then begin
      iicd=iicd+1
      gdat,file,h,w,f,e,iicd
      title=strtrim(byte(h(100:160)),2)
;      print,title
;      print,z
      if title ne z then begin
         print,'warning:'
         stop
         endif
      vel=arr(0,i)      
      h(28)=fix(vel)
      h(29)=fix((vel-fix(vel))*1000.)
print,vel
      kdat,file,h,w,f,e,iicd
      endif else print,' skipping sky'
   endfor
if keyword_set(stp) then stop,'WIYN_VEL_UPDATE>>>'
return
end
