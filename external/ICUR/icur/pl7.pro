;********************************************************************
pro pl7,i1,i2,i3,i4
; plot mode 7 data
if n_params(0) eq 0 then begin
   print,' PL7  -  plot mode 7 data'
   print,' calling sequences: PL7,recno
   print,'                    PL7,recno,file
   print,'                    PL7,w,f    
   print,'                    PL7,h,w,f,e
   print,'      recno:   record number in data file'
   print,'      file:    name of data file, default=IUEH2.DAT'
   print,'      h,w,f,e: standard IUE vectors
   return
   endif
cams=['   ','LWP','LWR','SWP','SWR']
if n_params(0) eq 1 then begin
   file=' '
   print,' enter file name: ',file
   if n_elements(i1) eq 1 then gdat,file,h,w,f,e,i1 else gdat,file,h,w,f,e
   endif                   ;1 param
if n_params(0) eq 2 then begin
   if n_elements(i1) eq 1 then gdat,file,h,w,f,e,i1 else begin
      w=i1 & f=i2
      if n_elements(i1) ne n_elements(i2) then begin
         print,' WARNING: W and F vectors not same length'
         endif
      endelse
   endif                    ;2 params
if n_params(0) eq 4 then begin
   h=i1 & w=i2 & f=i3 & e=i4
   endif                    ;4 params
if n_elements(h) eq 0 then begin
   image='' & title=''
   endif else begin
   title=strtrim(byte(h(100:159)>32),2)
   if h(4) ne 0 then begin
      imno=h(4) & if imno lt 0 then imno=imno+65536L
      image=cams(h(3))+' '+strtrim(imno,2)+' '
      endif else image=''
      endelse
!p.charsize=7./5. & !p.fonts=-1     ;fancy=3
!x.title='!6Angstroms'
!y.title=ytit(0)
!p.title=image+title
if n_elements(e) gt 0 then begin
   f=avspt(f,e)
   k=wherebad(e,0)
   !c=-1
   plot,w(k),f(k),psym=0
   endif else plot,w,f,psym=0
return
end
