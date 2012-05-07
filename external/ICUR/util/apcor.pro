;*****************************************************************************
function apcor,image,h,refap=refap,stp=stp,clip=clip,helpme=helpme,out=out, $
         quie=quiet
; construct aperture correction
;
if n_elements(image) lt 4 then helpme=1
if n_elements(refap) eq 0 then refap=12
if n_elements(stp) eq 0 then stp=0
if n_elements(clip) eq 0 then clip=0.005
;
if keyword_set(helpme) then begin
   print,' '
   print,'* APCOR: return aperture correction file for image'
   print,'* calling sequence: apcor=APCOR(image,h)'
   print,'*    image: name of array'
   print,'*    h:     image header (optional)
   print,'* '
   print,'* KEYWORDS'
;   print,'*    CLIP: display clipping value, def=',strtrim(clip,2)
   print,'*    REFAP: reference aperture width, def=',strtrim(refap,2),' (from CIRIMSTD)'
   print,'*    OUT:   set to save as file, def=APCOR.LST'
   print,' '
   return,0
   endif
;
maxi=fix(refap*1.5)
apc=fltarr(maxi)
if n_elements(h) gt 10 then begin
   if strmid(sxpar(h,'instrume'),0,4) eq 'WFPC' then wfpc2=1
   endif
;
;sx=(size(image))(1) & sy=(size(image))(2)
;mj=median(j)
;tvs,j>mj,id=id0,/reset,clip=clip,expand=expand,noplot=np
;print,' Mark source; RIGHT button to exit'
;tvp,image,px,py,/pix,/noprompt
;if !err eq 4 then return
;
radius=refap
apphot,image,px,py,cts0,ects0,radius=radius,gap=gap,nocentrd=nocentrd, $
       annulus=annulus,rcent=rcent,auto=auto,quiet=1,nodisplay=nodisplay, $
       header=h,wfpc2=wfpc2
;print,radius,px,py,cts0,cts0/ects0
for i=1,maxi do begin
   radius=i
   apphot,image,px,py,cts,ects,radius=radius,gap=gap,nocentrd=nocentrd, $
         annulus=annulus,rcent=rcent,auto=auto,quiet=1, $
         nodisplay=nodisplay,header=h,wfpc2=wfpc2
   apc(i-1)=cts/cts0
   if not keyword_set(quiet) then print,string(radius,'(I3)'), $
      string(px,py,format='(2F7.2)'),cts,cts/ects,string(apc(i-1),'(F5.2)')
   endfor
;
if keyword_set(out) then begin
   if not ifstring(out) then out='apcor'
   openw,lu,out+'.apcor',/get_lun
   printf,lu,' aperture corrections, run at ',systime(0)
   printf,lu,' '
   printf,lu,refap,maxi,'   reference aperture and number of steps in pixels'
   for i=1,maxi do printf,lu,string(i,'(I3)'),apc(i-1)
   free_lun,lu
   print,' output is in ',out+'.APCOR'   
   endif
;
if keyword_set(stp) then stop,'APCOR>>>'
bail:
return,apc
end
