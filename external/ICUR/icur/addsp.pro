;**************************************************************************
pro addsp,file,h0,w,f0,e0,prlog=prlog,debug=debug
common trim,ntr,ntr1,range,kr,irg,r2
;
;
swlw=1255. & swuw=1265.                  ;Si
lwlw=2794. & lwuw=2797.                  ;MgII k
print,' ADDSP : procedure to coadd spectra'
print,' set debug=-1 to turn off cross correlation and add with no bin shift'
print,' set debug=2  to run fully interactively and query about all shifts'
print,' '
shftmode=1
if n_params(0) eq 0 then file=''
if file eq '' then read,' enter name of data file: ',file
!quiet=1
;
if not ffile(file) then begin
   print,' data file not found: returning
   return
   endif
;
get_lun,lu
print,' these are the current data file contents:'
ldat,file
read,' enter record number for storage, -1 to append, -9 to skip: ',savrec
if (savrec lt -1) and (n_params(0) lt 4) then begin
   print,' WARNING: no data being saved or passed to MAIN'
   print," To pass data back, call ADDSP,'',H,W,F,E"
   return
   endif
savrec=fix(savrec)
title=''
read,' enter title for header: ',title
;
free_lun,lu
print,' what records do you wish? (or first, -#) -1 to end'
print,' Note that the first record is the template, and should be properly exposed'
read,recs
if recs eq -1 then return
a=0
while a ge 0 do begin
   read,a
   recs=[recs,a]
   endwhile
nr=n_elements(recs)
if (nr eq 2) and (recs(1) lt 0) then begin
   nr=abs(recs(1))+1
   recs=recs(0)+indgen(nr)
   endif
nr=fix(nr)-1
recs=fix(recs(0:nr-1))    ;cut last value
print,nr,' Records chosen:',recs
if nr le 1 then stop
if not keyword_set(debug) then debug=0
if debug eq -1 then iccr=0 else iccr=1
if debug ne -1 then begin
   read,' if you wish to cross correlate the spectra, enter 1',iccr
   print,' You have 2 choices: automatic cross correlations (0) or'
   print,'                     manual shifting (default) (1)'
   read,' Enter your choice: ',iccr2
   if iccr2 ne 0 then iccr2=1
   print,' '
   eta=(nr-1)*7+3
;   if iccr eq 1 then print,'*** Estimated time to completion is',eta,' minutes ***'
   endif
;
get_lun,lu
openw,lu,'addsp.log'
print,' '
printf,lu,' ADDSP processing log'
print,' processing starting at ',systime(0)
printf,lu,' ADDSP processing starting at ',systime(0)
printf,lu,nr,' Records chosen:',recs
printf,lu,' Title:',title
if iccr eq 1 then z=' ' else z=' not '
printf,lu,' Spectra will',z,'be cross correlated'
print,' '
gdat,file,h0,w0,f0,e0,recs(0)
ncam=h0(3)
image=h0(4)
if (ncam le 4) and (image lt 0) then image=image+65636L
if ncam le 4 then printf,lu,' this camera is number ',ncam,' image',image $
   else printf,' Data is ',strtrim(byte(h(100:159)>32),2)
addspwl,h0,w0,lam1,lam2,dl,krange
printf,lu,' Wavelengths limits are ',lam1,' to',lam2,' ; increment=',dl
printf,lu,' '
w=lam1+dl*findgen((lam2-lam1)/dl)
e0=fix(e0)
finter,w,w0,f0,e0
if (ncam le 4) and (n_elements(w) gt 4000) then kgap,h0,w,wgap,ngap,e0
fref=f0
eref=e0     ;
if (ncam le 4) and (n_elements(w) gt 4000) then begin
   ksplice,h0,w,eref
;   fftsm,fref,1,0.6
   endif
f0=f0*(h0(5)>1)   ;multiply by observing time
time=long(h0(5))>1L
h0(180)=h0(4)
k=wherebad(e0,1)    ;bad data
f0(k)=0.
e0=long(e0)*0+(long(h0(5))>1L)
e0(k)=0
;
nrecs=nr-1
if nr eq 2 then nit=-1 else nit=0
for irecs=1,nrecs do begin
   gdat,file,h1,w1,f1,e1,recs(irecs)
   im2=h1(4)
   if (h1(3) le 4) and (im2 lt 0) then im2=im2+65636L
   if h1(3) ne ncam then begin
      print,' Warning: camera =',h1(3),' not ',ncam
      printf,lu,' Warning: camera =',h1(3),' not ',ncam
      if ((ncam eq 1) and (h1(3) eq 2)) or ((ncam eq 2) and (h1(3) eq 1)) then $
         goto, camok
      stop
      irecs=irecs+1
      nr=nr-1
      goto,done
      endif
   camok:
   if ncam le 4 then printf,lu,' Processing camera number',h1(3),', image',im2 $
      else printf,lu,' Processing record ',strtrim(byte(h(100:159)>32b),2)
   e1=fix(e1)
   finter,w,w1,f1,e1
   if (ncam le 4) and (n_elements(w) gt 4000) then begin
      kgap,h1,w,wg1,ng,e1
      for i=0,ng-1 do begin
         if i lt ngap then if abs(wg1(i,0)-wgap(i,0)) lt 3. then begin
            wgap(i,0)=(wgap(i,0)>wg1(i,0))
            wgap(i,1)=(wgap(i,1)<wg1(i,1))
            endif   ;reset gaps
         endfor    ;gap loop
      endif   ;idat = 7 gap loop
   e2=e1
   if (ncam le 4) and (n_elements(w) gt 4000)  then begin
      ksplice,h1,w,e2
;      fftsm,f1,1,0.6
      endif
;
   if iccr eq 1 then begin
      if debug ne 0 then print,' beginning SPSHFT'
      nit=nit+1
      s=spshft(fref,f1,eref,e2,nit) 
      if iccr2 eq 0 then begin   ; autoshift
         wk=where(w gt lw) & kw1=(wk(0)-150)>0
         wk=where(w gt uw) & kw2=(wk(0)+150)<(n_elements(w)-1)
         print,' bin limits=',kw1,kw2
         print,systime(0)
         s=spshft(fref(kw1:kw2),f1(kw1:kw2),eref(kw1:kw2),e2(kw1:kw2),nit)
         print,' SPSHFT done, s=',s,systime(0)
         endif else begin                        ;manual shift
         s=shfth2(w,fref,f1,lw,uw)
         print,' SHFTH2 done, s=',s
         ;s=0
         endelse          ;iccr2
      endif else s=0.     ;iccr
;
   igo=0
   case 1 of
      s eq -1000: begin
         printf,lu,' WARNING: file number',irecs+1,': peak too close to edge'
         end
      s lt -8000: begin
        printf,lu,' file number',irecs+1,' WARNING: NO SIGNIFICANT PEAK FOUND'
         s=s+9000
         igo=1
         end
      abs(s) gt krange: begin
         z=string(s,'(I2)')
         printf,lu,' file number',irecs+1,' WARNING: PEAK @ ',z,' OUTSIDE BOUNDS - RESETTING'
         igo=1
         end
      else:
      endcase
   if (igo eq 1) or (debug eq 2) then begin         
      if debug gt 0 then begin           ;check manually
         print,string(7b),' shift=',s
         igo=0.0
    read,' is this shift OK? enter 99 to accept,-99 to omit, other to set: ',igo
         case 1 of
            igo ge 98.9:
            igo le -98.9: s=-1000
            else: s=igo
            endcase
         endif else s=-1000     ;ignore data if running on auto
      endif   ;igo
   if s eq -1000 then begin     ;skip this record
      printf,lu,' file number',irecs+1,' not added'
      nr=nr-1 & goto,done
      endif
   f1=f1*(h1(5)>1)
   time=time+(long(h1(5))>1L)
   h0(180+irecs)=h1(4)
   k=wherebad(e1,1)                   ;bad data
   f1(k)=0.
   e1=long(e1)*0+(long(h1(5))>1L)
   e1(k)=0
   if s ne 0 then begin    ;apply shift
      if (shftmode eq 0) or (abs(s-fix(s)) lt 0.01)  then begin
         s=fix(s)
         f1=shift(f1,s)
         e1=shift(e1,s)
         case 1 of
            s gt 0: begin
               f1(n_elements(f1)-1-s:*)=0.
               e1(n_elements(f1)-1-s:*)=0
               end
            s lt 0: begin
               f1(0:abs(s)-1)=0.
               e1(0:abs(s)-1)=0
               end
            else:
            endcase
         endif else begin
         dl=w(1)-w(0)
         shft=s*dl
         f1=interpol(f1,w,w+shft)
         e1=interpol(e1,w,w+shft)
         endelse
      endif
   f0=f0+f1
   e0=e0+e1
   print,' file number',irecs+1,' added, shift=',s,' accumulated time=',time
   printf,lu,' file number',irecs+1,' added, shift=',s,' accumulated time=',time
   done:
   endfor     ;irecs
f0=f0/(e0>1)    ;flux/sec
;
if (ncam le 4) and (n_elements(w) gt 4000) then cutgaps,h0,w,f0,e0,ngap,wgap(*,0),wgap(*,1)
;
h0(4)=0     ;dummy record number
if time gt 32767L then h0(5)=-fix(time/60) else h0(5)=time
h0(9)=nr    ;records added
title=title+' sum of '+strtrim(nr,2)+' spectra'
title=byte(title)
h0(100)=title
;
print,h0(20:23)
e0=byte(127.*float(e0)/max(e0))
if savrec ne -1 then begin
   kdat,file,h0,w,f0,e0,savrec
   printf,lu,' data saved to ',file,' record #',savrec
   endif
!x.title='!6 Angstroms'
!y.title=ytit(0)
!p.title=strtrim(byte(title),2)
!p.font=-1
!p.charsize=7./5.       ;!fancy=3
print,' '
printf,lu,' '
print,' Done at ',systime(0)
printf,lu,' ADDSP done at ',systime(0)
close,lu
free_lun,lu
if !version.os eq 'vms' then z='delete/noconfirm spshft.tmp;*' $
      else z='rm spshft.tmp'
spawn,z
if keyword_set(prlog) then spawn_print,'addsp.log' else print,' Log in addsp.log'
print,' '
return
end
