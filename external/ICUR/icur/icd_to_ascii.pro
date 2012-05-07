;****************************************************************************
pro icd_to_ascii,file,rec,out=out,helpme=helpme,stp=stp
if n_elements(file) eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'ICD_TO_ASCII,file,rec,out=out '
   print,' '
   return
   endif
;
if n_elements(rec) eq 0 then begin
   rec=-1
   read,rec,prompt=' Please enter record number: '
   endif
;
nr=n_elements(rec)
get_lun,lu
if n_elements(out) eq 1 then begin
   outfile=out+'.acd'
   openw,lu,outfile
   endif
for i=0,nr-1 do begin
   r=rec(i)
   gdat,file,h,w,f,e,r
   if n_elements(out) eq 0 then begin
      outfile=file+'_'+strtrim(r,2)+'.acd'
      openw,lu,outfile
      endif
   ncam=h(3)
   if ncam/10 eq 10 then ghrsgrat=ncam-100 else ghrsgrat=-1
   imno=h(4)
   if imno lt 0 then imno=imno+65536L    ;IUE image numbers >2^15
   len=h(7)
   IF (ncam LT 5) AND (H(34) LE 2) THEN $
      Title=STRMID('    LWP LWR SWP SWR ',ncam*4,4)+' '+strtrim(imno,2) $
      ELSE Title=STRTRIM(STRING(BYTE(H(100:160)>32)),2)
   IF ncam lt 5 then IF H(14) EQ 2 THEN title=title+' Small Aperture' $
        ELSE title=title+' Large Aperture'
   exptime=H(5)
   if exptime lt 0 then exptime=-long(exptime)*60
   if ghrsgrat ne -1 then title=title+'  GHRS grating '+strtrim(ghrsgrat,2)
   if ncam eq 90 then title=' SYNTHE model : '+title

   if total(h(40:48)) ne 0 then begin
      sra=string(h(40),'(I3)')+string(h(41),'(I3)')+ $
         string(float(h(42))/100.,'(F6.2)')
      sdec=string(h(43),'(I5)')+string(h(44),'(I3)')+ $
         string(float(h(45))/100.,'(F6.2)')
      sha=string(h(46),'(I3)')+string(h(47),'(I3)')+ $
         string(float(h(48))/100.,'(F6.2)')
      zpos=' RA,DEC='+sRA+sDEC
      if total(h(46:48)) ne 0 then zpos=zpos+' HA='+sha
      endif else zpos=''
   zt=string(h(10),'(I3)')+'/'+string(h(11),'(I2)')+'/'+string(h(12),'(I4)')
   zt=zt+'  '+string(h(13),'(I3)')+':'+string(h(14),'(I2)')+':'
   zt=zt+string(h(15),'(I2)')+' UT'
;
   z=' ASCII spectrum from '+file+'.icd, record # '+strtrim(r,2)
   printf,lu,z
   printf,lu,title
   printf,lu,zt
   printf,lu,' Exposure time = '+strtrim(exptime,2)+' seconds
   printf,lu,zpos
   ht=h(33)
   if len le 0 then len=n_elements(w)
   printf,lu,len,' points in spectrum'
   zh='      WAVELENGTH       FLUX         '
   case ht of
       1: zh=zh+' +/-'
      30: zh=zh+' S/N'
      40: zh=zh+' +/-'
      else: zh=zh+' epsilon'
      endcase
   printf,lu,' '
   printf,lu,zh
   printf,lu,' '
;
   np=n_elements(w)
   for j=0L,np-1L do printf,lu,w(j),' ',f(j),' ',e(j)
   if n_elements(out) eq 0 then close,lu
   print,' File ',outfile,' written'
   endfor  ;i
if n_elements(out) eq 1 then close,lu
free_lun,lu
if keyword_set(stp) then stop,'ICD_TO_ASCII>>>'
return
end
