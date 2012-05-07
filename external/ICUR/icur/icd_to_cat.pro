;***********************************************************************
pro icd_to_cat,file,catfile=catfile,stp=stp,helpme=helpme,epoch=epoch
;
if not ifstring(file) then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* icd_to_cat,file,catfile=catfile'
   print,' '
   endif
if not ifstring(catfile) then catfile=file
if strlen(get_ext(catfile)) eq 0 then catfile=catfile+'.cat'
if n_elements(epoch) eq 0 then begin
   if strpos(strupcase(file),'IDS') ne -1 then begin
      gdat,file,h,w,f,e,0
      epoch=h(12)+1900.+((h(10)-1)*30.+h(11))/365.   ;approximate epoch
      endif else epoch=2000
   endif
epoch=string(epoch,'(F6.1)')
print,epoch
nspec=get_nspec(file)
openw,lu,catfile,/get_lun
printf,lu,' Catalog file transcribed from ',file
printf,lu,' Wrought by ICD_TO_CAT on ',systime(0)
printf,lu,'  #     RA      DEC   ----------------------------------------'
printf,lu,epoch,' 1'
;
pmsflag=' 0'
xrsflag=' 0'
for i=0,nspec-1 do begin
   gdat,file,h,w,f,e,i
   rn=string(i,'(I3)')
   ra=string(h(40),'(I3)')+string(h(41),'(I3)')+ $
      string(float(h(42))/100.,'(F6.2)')+'  0 '
   dec=string(h(43),'(I4)')+string(h(44),'(I4)')+ $
      string(float(h(45))/100.,'(F5.1)')+'  0 '
   title=strtrim(byte(h(100:160)>32b),2)
   printf,lu,rn,ra,dec,pmsflag,xrsflag,pmsflag,xrsflag,xrsflag,' ',title
   endfor
printf,lu,'0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 end'
close,lu & free_lun,lu
print,' catalog file ',catfile,' created'
if keyword_set(stp) then stop,'ICD_TO_CAT>>>'
return
end
