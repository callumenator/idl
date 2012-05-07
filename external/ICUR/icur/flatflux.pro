;***********************************************************************
pro fLATflux,file,rec,w0=w0,ffx=ffx,add=add,all=all,stp=stp,helpme=helpme, $
   dw=dw,ddw=ddw,nsm=nsm
common comxy,xcur,ycur,zerr
; reset flux calibration near H-alpha
; w,fact are output correction vectors
iall=0
w0def=6563.
if n_params(0) eq 0 then helpme=1
if n_elements(file) eq 0 then file='-1'
if strtrim(string(file),2) eq '-1' then helpme=1
hlp:
if keyword_set(helpme) then begin
   print,' '
   print,'* FLATFLUX - procedure to tweak up flux corrections'
   print,'*   This is designed primarily to flatten spectra near H-alpha'
   print,'*'
   print,'*   Calling sequence: FLATFLUX,file,recs,w0
   print,'*      file: name of data file, 6 = ECHEL.DAT, -1 for this help message.'
   print,'*      recs: -1 for listing of records'
   print,'*            the record numbers to be fudged interactively'
   print,'*   KEYWORDS:
   print,'*            FFX: name of .FLX file, default=FUDGE'
   print,'*            ADD: append to existing .FLX file'
   print,'*            ALL: do all at once.'
   print,'*            DW: the half width of the plot region, def=100'
   print,'*        w0: wavelength of the region to be corrected; default=',strtrim(w0def,2)
   print,' '
   return
   endif
;
if n_params(0) lt 2 then read,' enter record number, -1 for list: ',rec
if ifstring(rec) eq 1 then begin   ;string passed
   print,' FLATFLUX cannot accept ',rec, ' as a parameter'
   rec=-1
   endif 
if rec eq -1 then begin
   ldat,file
   read,' choose one record to produce as a template correction: ',rec
   rec=fix(rec)
   endif
if rec eq -1 then begin
   helpme=1
   goto,hlp
   endif
;
if n_elements(dw) eq 0 then dw=100.
if n_params(0) lt 3 then w0=w0def 
if w0 le 0. then w0=w0def
if not keyword_set(ffx) then fname='FUDGE' else fname=ffx
;
setxy
if not keyword_set(all) then !x.range=[w0-dw,w0+dw]
nrec=n_elements(rec)
!p.title='!6FLATFLUX'
igo=0
;
gdat,file,h,w,f0,e,rec
if n_elements(h) eq 1 then goto,done
fact1=1.
if (keyword_set(add)) and (not keyword_set(all)) then begin
   i=ffile(fname+'.ffl')
   if i eq 1 then begin    ;.FFL file exists
      fact1=get_ffl(fname,w0)
      diff=w-w0
      if max(abs(diff)) gt (w(1)-w(0)) then fact1=interpol(fact1,w0,w)
      endif
   endif
f=f0*fact1                   ;apply old corrections, if warranted
plot,w,f
if !d.name eq 'X' then wshow
print,' place cursor on continuum regions and hit left button; right if done'
wl=0 & fl=0
cursor,wl,fl
zerr=0
while zerr ne 4 do begin
   cursor,i1,i2
   zerr=!err
   wl=[wl,i1]
   wait,0.2
   endwhile
help,wl
;print,wl
fl=wl
np=n_elements(wl)
if np lt 2 then return
if n_elements(ddw) eq 0 then ddw=4
if ddw lt 0 then ddw=4
for i=0,np-1 do begin
   k=fix(xindex(w,wl(i))+0.5)
   fl(i)=total(f(k-ddw:k+ddw))/(w(k+ddw+1)-w(k-ddw))
   endfor
cf=mean(fl)/fl
fact=interpol(cf,wl,w)
k1=fix(xindex(w,wl(0))+0.5)
k2=fix(xindex(w,wl(np-1))+0.5)
fact(0:k1-ddw>0)=1.
fact(k2+ddw:*)=1.
if n_elements(nsm) eq 0 then nsm=5
if nsm le 0 then nsm=5
fact=smooth(fact,nsm)
if keyword_set(add) then fact=fact*fact1
nf=n_elements(fact)
h(7)=nf
sav_ffl,fname,wl
oplot,w,f0*fact,color=85
print,' use GET_FFL to get correction factor vector'
if keyword_set(stp) then stop,'FLATFLUX>>>'
;
done:
return
end
