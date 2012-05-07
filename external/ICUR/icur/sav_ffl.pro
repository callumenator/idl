;************************************************************************
pro sav_ffl,fname,wl,stp=stp
openw,lu,fname+'.ffl',/get_lun
nl=n_elements(wl)
printf,lu,nl
printf,lu,wl
close,lu
free_lun,lu
if keyword_set(stp) then stop,'SAV_FFL>>>'
return
end
