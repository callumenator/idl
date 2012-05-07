;   this program is to read and analyze images from the trailer FPI
;   using Mark's routines.
;   Matt Krynicki, 09-14-99.




; this subroutine puts the time values into a format that is
; readable by my other IDL routines.

pro fixtime, thtime

;thtime=strcompress(thtime,/remove_all)
hr=strmid(thtime,0,2)
dec=strmid(thtime,3,2)
hr=strcompress(hr,/remove_all)
thtime=hr+dec
thtime=fix(thtime)

return

end

; main program
; this program does all the work for creating wind data, but does not do spectra
; generation from fringe images or the fitting to spectra

; this section takes care of all drift correction and mean shift of peak
; position, and converts the peaks to velocities.  also, interpolationis
; done here to correct off-zenith measurements.

;truepkpos=dblarr(arrsize)

flttimearr = double(timearr)
pkposmean = double(mean(pkpos))
truepkpos = double(pkpos - pkposmean)
;truepkpos(0:91)=tmppkpos1
;truepkpos(92:199)=tmppkpos2

g=0
j=0
;n=0
;s=0
;w=0
;e=0
for i=0,arrsize-1 do begin
 if elevarr(i) eq 90 then j=j+1
 if elevarr(i) ne 90 then g=g+1
; if azmtharr(i) eq 0 and elevarr(i) eq 30 then n=n+1
; if azmtharr(i) eq 180 and elevarr(i) eq 30 then s=s+1
; if azmtharr(i) eq 270 and elevarr(i) eq 30 then w=w+1
; if azmtharr(i) eq 90 and elevarr(i) eq 30 then e=e+1
endfor
zsize=j
ozsize=g
znthpkpos=dblarr(zsize)
znthtimes=dblarr(zsize)
znthintnst=fltarr(zsize)
znthintnsterr=fltarr(zsize)
znthpkposerr=fltarr(zsize)
offznthpkpos=dblarr(ozsize)
offznthtimes=dblarr(ozsize)
offznthintnst=fltarr(ozsize)
offznthintnsterr=fltarr(ozsize)
offznthpkposerr=fltarr(ozsize)
;nrthpkpos=fltarr(n)
;sthpkpos=fltarr(s)
;wstpkpos=fltarr(w)
;estpkpos=fltarr(e)
;nrthtimes=fltarr(n)
;sthtimes=fltarr(s)
;wsttimes=fltarr(w)
;esttimes=fltarr(e)
;nrthwnderr=fltarr(n)
;sthwnderr=fltarr(s)
;wstwnderr=fltarr(w)
;estwnderr=fltarr(e)
j=0
g=0
for i=0,arrsize-1 do begin
 if elevarr(i) eq 90 then begin
  znthpkpos(j)=double(truepkpos(i))
  znthtimes(j)=double(flttimearr(i))
  znthintnst(j)=intnst(i)
  znthintnsterr(j)=intnsterr(i)
  znthpkposerr(j)=pkposerr(i)
  j=j+1
 endif
 if elevarr(i) ne 90 then begin
  offznthpkpos(g)=double(truepkpos(i))
  offznthtimes(g)=double(flttimearr(i))
  offznthintnst(g)=intnst(i)
  offznthintnsterr(g)=intnsterr(i)  
  offznthpkposerr(g)=pkposerr(i)
  g=g+1
 endif
endfor

polydeg=7
znthpkposwts=fltarr(zsize)
znthpkposwts(*)=1.

;for i=0,arrsize/2 do begin
; znthpkposwts(i)=1.-(2.*(float(i)/float(zsize)))
; znthpkposwts(arrsize-1-i)=1.-(2.*(float(i)/float(zsize)))
;endfor

;smthwdth = 0.3 * zsize
;smthznthpkpostmp1 = mc_im_sm(znthpkpos,smthwdth)

plynmialcoeffs = polyfitw(znthtimes,znthpkpos,znthpkposwts,polydeg,smthznthpkpos,smthznthpkposerr)

;plynmialcoeffs = poly_fit(znthtimes,znthpkpos,polydeg,smthznthpkpos)

corrznthpkpos = znthpkpos - smthznthpkpos
totalzntherr = ((znthpkposerr)^2 + (smthznthpkposerr)^2)^(0.5)

smthoffznthpkpos = interpol(smthznthpkpos,znthtimes,offznthtimes)
smthoffznthpkposerr = interpol(smthznthpkposerr,znthtimes,offznthtimes)
corroffznthpkpos = offznthpkpos - smthoffznthpkpos
totaloffzntherr = ((offznthpkposerr)^2 + (smthoffznthpkposerr)^2)^(0.5)

;ggg=0
;for i=0,arrsize-1 do begin
; if i eq 0 then begin
;  tempy1 = [corrznthpkpos(0),corrznthpkpos(1),corrznthpkpos(2)]
;  tempy2 = [znthtimes(0),znthtimes(1),znthtimes(2)]
;  tempy3 = [flttimearr(i),flttimearr(i+1),flttimearr(i+2),flttimearr(i+3)]
;  result=interpol(tempy1,tempy2,tempy3)
;  nextggg:
;  smthoffznthpkpos(ggg) = result(ggg)
;  ggg=ggg+1
;  if ggg le 3 then goto, nextggg
; endif
; if i eq 0 then goto,finish
;; print,elevarr(i), i+4, arrsize-1
; if i+4 le arrsize-1 and elevarr(i) ne 90 and elevarr(i-1) eq 90 then begin
;  for pp=0,zsize-1 do begin
;   if flttimearr(i-1) eq znthtimes(pp) then begin
;    tempy1 = [corrznthpkpos(pp),corrznthpkpos(pp+1)]
;;    print,tempy1
;   endif
;  endfor
;  tempy2 = [flttimearr(i-1),flttimearr(i+4)]
;;  print,tempy2
;  tempy3 = [flttimearr(i),flttimearr(i+1),flttimearr(i+2),flttimearr(i+3)]
;;  print,tempy3
;  result=interpol(tempy1,tempy2,tempy3)
;;  print,result
;  kk=0
;  nextkk:
;  smthoffznthpkpos(ggg) = result(kk)
;  ggg=ggg+1
;  kk=kk+1
;  if kk le 3 then goto,nextkk
; endif
; if i+4 gt arrsize-1 and elevarr(i) ne 90 and elevarr(i-1) eq 90 then begin
;  tempy1 = [corrznthpkpos(zsize-3),corrznthpkpos(zsize-2),corrznthpkpos(zsize-1)]
;  tempy2 = [znthtimes(zsize-3),znthtimes(zsize-2),znthtimes(zsize-1)]
;  tempy3 = fltarr(arrsize-i)
;  for f=0,arrsize-i-1 do begin
;   tempy3(f)=flttimearr(i+f)
;  endfor
;  result=interpol(tempy1,tempy2,tempy3)
;  kkk=0
;  lastggg:
;  smthoffznthpkpos(ggg) = result(kkk)
;  kkk=kkk+1
;  ggg=ggg+1
;  if ggg le ozsize-1 then goto,lastggg
; endif
; finish:
;endfor

; corroffznthpkpos = offznthpkpos - smthoffznthpkpos

j=0
g=0
for i=0,arrsize-1 do begin
 if elevarr(i) eq 90 then begin
  finalpkpos(i) = corrznthpkpos(j)
  finalpkposerr(i) = totalzntherr(j)
  j=j+1
 endif
 if elevarr(i) ne 90 then begin
  finalpkpos(i) = corroffznthpkpos(g)
  finalpkposerr(i) = totaloffzntherr(g)
  g=g+1
 endif
endfor

;n=0
;s=0
;w=0
;e=0
;for i=0,arrsize-1 do begin
; if azmtharr(i) eq 0 and elevarr(i) eq 30 then begin
;  nrthpkpos(n)=finalpkpos(i)
;  nrthtimes(n)=flttimearr(i)
;  n=n+1
; endif
; if azmtharr(i) eq 180 and elevarr(i) eq 30 then begin
;  sthpkpos(s)=finalpkpos(i)
;  sthtimes(s)=flttimearr(i)
;  s=s+1
; endif
; if azmtharr(i) eq 270 and elevarr(i) eq 30 then begin
;  wstpkpos(w)=finalpkpos(i)
;  wsttimes(w)=flttimearr(i)
;  w=w+1
; endif
; if azmtharr(i) eq 90 and elevarr(i) eq 30 then begin
;  estpkpos(e)=finalpkpos(i)
;  esttimes(e)=flttimearr(i)
;  e=e+1
; endif
;endfor

wnd = cnvrsnfctr * finalpkpos
wnd = -wnd
wnderr = cnvrsnfctr * finalpkposerr
znthwnd = cnvrsnfctr * corrznthpkpos
znthwnd = -znthwnd
znthwnderr = cnvrsnfctr * totalzntherr
offznthwnd = cnvrsnfctr * corroffznthpkpos
offznthwnd = -offznthwnd
offznthwnderr = cnvrsnfctr * totaloffzntherr
;nrthwnd = cnvrsnfctr * nrthpkpos
;nrthwnd = -nrthwnd
;sthwnd = cnvrsnfctr * sthpkpos
;sthpkpos = -sthpkpos
;wstwnd = cnvrsnfctr * wstpkpos
;wstwnd = -wstwnd
;estwnd = cnvrsnfctr * estpkpos
;estwnd = -estwnd
;n=0
;s=0
;w=0
;e=0
;dflctdeg=35.
;dflctrad = (3.141593/180)*dflctdeg
;for i=0,arrsize-1 do begin
; if i+4 le arrsize-1 then begin
;  if azmtharr(i) eq 0 and elevarr(i) eq 30 then begin
;   nrthtmp = wnd(i)
;   crrct1 = nrthtmp*cos(dflctrad)
;   crrct2 = nrthtmp*sin(dflctrad)
;  endif
;  if azmtharr(i) eq 270 then begin
;   wsttmp = wnd(i)
;   crrct3 = wsttmp*cos(dflctrad)
;   crrct4 = wsttmp*sin(dflctrad)
;  endif
;  if azmtharr(i) eq 180 then begin
;   sthtmp = wnd(i)
;   crrct5 = sthtmp*cos(dflctrad)
;   crrct6 = sthtmp*sin(dflctrad)
;  endif
;  if azmtharr(i) eq 90 then begin
;   esttmp = wnd(i)
;   crrct7 = esttmp*cos(dflctrad)
;   crrct8 = esttmp*sin(dflctrad)
;   nrthprm = crrct2 + crrct3
;   wstprm = crrct4 + crrct5
;   sthprm = crrct6 + crrct7
;   estprm = crrct8 + crrct1
;   wnd(i) = estprm & estwnd(e) = estprm
;   wnd(i-1) = sthprm & sthwnd(s) = sthprm
;   wnd(i-2) = wstprm & wstwnd(w) = wstprm
;   wnd(i-3) = nrthprm & nrthwnd(n) = nrthprm
;   n=n+1
;   e=e+1
;   s=s+1
;   w=w+1
;  endif
; endif
; if i+4 gt arrsize-1 and elevarr(i) ne 90 then begin
;  thetest = arrsize - i
;  if thetest eq 1 then begin
;   nrthtmp = wnd(i)
;   crrct1 = nrthtmp*cos(dflctrad)
;   crrct2 = nrthtmp*sin(dflctrad)
;   nrthprm = crrct2
;   wnd(i) = nrthprm & nrthwnd(n) = nrthprm
;   goto, done
;  endif
;  if thetest eq 2 then begin
;   nrthtmp = wnd(i)
;   crrct1 = nrthtmp*cos(dflctrad)
;   crrct2 = nrthtmp*sin(dflctrad)
;   wsttmp = wnd(i+1)
;   crrct3 = wsttmp*cos(dflctrad)
;   crrct4 = wsttmp*sin(dflctrad)
;   nrthprm = crrct2 + crrct3
;   wstprm = crrct4
;   wnd(i) = nrthprm & nrthwnd(n) = nrthprm
;   wnd(i+1) = wstprm & wstwnd(w) = wstprm
;   goto,done
;  endif
;  if thetest eq 3 then begin
;   nrthtmp = wnd(i)
;   crrct1 = nrthtmp*cos(dflctrad)
;   crrct2 = nrthtmp*sin(dflctrad)
;   wsttmp = wnd(i+1)
;   crrct3 = wsttmp*cos(dflctrad)
;   crrct4 = wsttmp*sin(dflctrad)
;   sthtmp = wnd(i+2)
;   crrct5 = sthtmp*cos(dflctrad)
;   crrct6 = sthtmp*sin(dflctrad)
;   nrthprm = crrct2 + crrct3
;   wstprm = crrct4 + crrct5
;   sthprm = crrct6
;   wnd(i) = nrthprm & nrthwnd(n) = nrthprm
;   wnd(i+1) = wstprm & wstwnd(w) = wstprm
;   wnd(i+2) = sthprm & sthwnd(s) = sthprm
;   goto,done
;  endif
; endif
;endfor

;done:

j=0
g=0
;n=0
;s=0
;e=0
;w=0
;znthwnderr=fltarr(zsize)
;offznthwnderr=fltarr(ozsize)
;for i=0,arrsize-1 do begin
; if elevarr(i) eq 90 then begin
;  znthwnderr(j) = wnderr(i)
;  j=j+1
; endif
; if elevarr(i) ne 90 then begin
;  offznthwnderr(g) = wnderr(i)
;  offznthwnd(g) = wnd(i)
;  g=g+1
; endif
; if elevarr(i) eq 30 and azmtharr(i) eq 0 then begin
;  nrthwnderr(n)=wnderr(i)
;  n=n+1
; endif
; if elevarr(i) eq 30 and azmtharr(i) eq 180 then begin
;  sthwnderr(s)=wnderr(i)
;  s=s+1
; endif
; if elevarr(i) eq 30 and azmtharr(i) eq 270 then begin
;  wstwnderr(w)=wnderr(i)
;  w=w+1
; endif
; if elevarr(i) eq 30 and azmtharr(i) eq 90 then begin
;  estwnderr(e)=wnderr(i)
;  e=e+1
; endif
;endfor

mnth=strmid(date,2,2)
pieceofdate=strmid(date,3,3)

if mnth eq '10' then pieceofdate = 'A'+strmid(date,4,2)
if mnth eq '11' then pieceofdate = 'B'+strmid(date,4,2)
if mnth eq '12' then pieceofdate = 'C'+strmid(date,4,2)
month=''
year=''

yr=strmid(date,0,2)
if yr eq '00' then year='2000'
if yr eq '99' then year='1999'
mnthval=strmid(date,2,2)
day=strmid(date,4,2)
;if fix(day) lt 10 then day=strmid(day,1,1)

if (mnthval eq '01') then month='January'
if (mnthval eq '02') then month='February'
if (mnthval eq '03') then month='March'
if (mnthval eq '04') then month='April'
if (mnthval eq '05') then month='May'
if (mnthval eq '06') then month='June'
if (mnthval eq '07') then month='July'
if (mnthval eq '08') then month='August'
if (mnthval eq '09') then month='September'
if (mnthval eq '10') then month='October'
if (mnthval eq '11') then month='November'
if (mnthval eq '12') then month='December'

datfile1=dpath+year+'\ivkrd'+pieceofdate+'.dbt'
openw,unit1,datfile1,/get_lun
;datfile2=dpath+'ikmrd'+pieceofdate+'.dbt'
;openw,unit2,datfile2,/get_lun
datfile3=dpath+year+'\ikvrt'+pieceofdate+'.dbt'
openw,unit3,datfile3,/get_lun
;datfile4=dpath+'ikhrz'+pieceofdate+'.dbt'
;openw,unit4,datfile4,/get_lun
;datfile5=dpath+'ikzon'+pieceofdate+'.dbt'
;openw,unit5,datfile5,/get_lun

j=0
;g=0
;n=0
;s=0
;w=0
;e=0
for i=0,arrsize-1 do begin
 thtime=timearr(i)
 call_procedure, 'fixtime', thtime
 printf,unit1,format='(a6,i6,i8,i8,2f8.3,f8.1,f8.2,f8.1,f8.2)',date,thtime,$
  azmtharr(i),elevarr(i),wnd(i),wnderr(i),bckgrnd(i),bckgrnderr(i),intnst(i),$
  intnsterr(i)
; if elevarr(i) eq 30 and azmtharr(i) eq 0 then begin
;  printf,unit2,format='(a6,i6,i8,i8,2f8.3,f8.1,f8.2,f8.1,f8.2)',date,thtime,$
;   azmtharr(i),elevarr(i),nrthwnd(n),nrthwnderr(n),bckgrnd(i),bckgrnderr(i),intnst(i),$
;   intnsterr(i)
;  n=n+1
; endif
; if elevarr(i) eq 30 and azmtharr(i) eq 180 then begin
;  printf,unit2,format='(a6,i6,i8,i8,2f8.3,f8.1,f8.2,f8.1,f8.2)',date,thtime,$
;   azmtharr(i),elevarr(i),sthwnd(s),sthwnderr(s),bckgrnd(i),bckgrnderr(i),intnst(i),$
;   intnsterr(i)
;  s=s+1
; endif
; if elevarr(i) eq 30 and azmtharr(i) eq 270 then begin
;  printf,unit5,format='(a6,i6,i8,i8,2f8.3,f8.1,f8.2,f8.1,f8.2)',date,thtime,$
;   azmtharr(i),elevarr(i),wstwnd(w),wstwnderr(w),bckgrnd(i),bckgrnderr(i),intnst(i),$
;   intnsterr(i)
;  w=w+1
; endif
; if elevarr(i) eq 30 and azmtharr(i) eq 90 then begin
;  printf,unit5,format='(a6,i6,i8,i8,2f8.3,f8.1,f8.2,f8.1,f8.2)',date,thtime,$
;   azmtharr(i),elevarr(i),estwnd(e),estwnderr(e),bckgrnd(i),bckgrnderr(i),intnst(i),$
;   intnsterr(i)
;  e=e+1
; endif 
 if elevarr(i) eq 90 then begin
  printf,unit3,format='(a6,i6,i8,i8,2f8.3,f8.1,f8.2,f8.1,f8.2)',date,thtime,$
   azmtharr(i),elevarr(i),znthwnd(j),znthwnderr(j),bckgrnd(i),bckgrnderr(i),intnst(i),$
   intnsterr(i)
  j=j+1 
 endif
; if elevarr(i) ne 90 then begin
;  printf,unit4,format='(a6,i6,i8,i8,2f8.3,f8.1,f8.2,f8.1,f8.2)',date,thtime,$
;   azmtharr(i),elevarr(i),offznthwnd(g),offznthwnderr(g),bckgrnd(i),bckgrnderr(i),intnst(i),$
;   intnsterr(i)
;  g=g+1
; endif
endfor

close,unit1
free_lun,unit1
;close,unit2
;free_lun,unit2
close,unit3
free_lun,unit3
;close,unit4
;free_lun,unit4
;close,unit5
;free_lun,unit5

end


