;*****************************************************************************
function rd_apcor,aperture,file=file,stp=stp
; construct aperture correction
;
if n_elements(aperture) eq 0 then return,1.0
;
if n_elements(file) eq 0 then file='apcor'
if noext(file) then file=file+'.apcor'
if n_elements(stp) eq 0 then stp=0
;
if not ffile(file) then begin
   print,'RD_APCOR: file ',file,' not found'
   return,1.0
   endif
;
openr,lu,file,/get_lun
z=''
for i=0,1 do readf,lu,z
refap=0 & nlines=0
readf,lu,refap,nlines
apc=fltarr(2,nlines)
readf,lu,apc
free_lun,lu
;
apc=reform(apc(1,*))
ref=apc(refap-1)
if keyword_set(stp) then stop,'RD_APCOR>>>'
if aperture lt 0 then return,ref/apc         ;return array
aperture=(aperture>1)<(nlines-1)
return,ref/apc(aperture-1)
end
