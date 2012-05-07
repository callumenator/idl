;   this program is to read and analyze images from the trailer FPI
;   using Mark's routines.
;   Matt Krynicki, 09-14-99.




; this subroutine puts the time values into a format that is
; readable by my other IDL routines.

pro fixtime, thtime

;thtime=strcompress(thtime,/remove_all)
hr=strmid(thtime,0,2)
dec=strmid(thtime,3,2)

hr=fix(hr)-2
hr=strcompress(hr,/remove_all)
dec=float(dec)-0.5
dec=strmid(strcompress(dec,/remove_all),2,2)
thtime=hr+dec
thtime=fix(thtime)

return

end

;   this is the main program.
;   Analyzeimg

@frngprox.pro

laserfile=''
skyfile=''
skyfile1=''
skyfile2=''
date=''
pieceofdate=''
thtime=''
type=''
elev=''
azmth=''
head=bytarr(161)
isig=bytarr(256,255)
datfile=''

fpath='d:\'
epath='d:\'
dpath='d:\inv_data\'

load_pal,culz,idl=[3,1]

question=''
print,''
print,"do you want to fit to the laser file?  y/n"
print,''
read,question

laserfile=pickfile(path=fpath, filter='*.cln', file=fname, get_path=fpath, $
 title="Select the laser file to fit parameters to:", /must_exist)

skyfile1=pickfile(path=epath, filter='*.cln', file=fname, get_path=epath, $
 title="Select the first file in the list of files to analyze:", /must_exist)
skyfile2=pickfile(path=epath, filter='*.cln', file=fname, get_path=epath, $
 title="Select the last file to analyze:", /must_exist)
 
;load_pal, culz, idl=[3,1]

openr,unit,laserfile,/get_lun
readu,unit,head
readu,unit,isig
close,unit
free_lun,unit

date=string(head(0:5))
thtime=string(head(6:10))
type=string(head(11:13))
azmth=string(head(14:16))
elev=string(head(17:18))

lref = isig
nx = n_elements(isig(*,0))
ny = n_elements(isig(0,*))

frnginit, php, nx, ny, mag=[0.000242873, 0.000243025, -3.71441e-7], $
                       warp = [-0.0033846, -0.00656352], $
                       center=[127.634, 127.917], $
                       ordwin=[0.1,8.1], $
                       phisq =0.00312098, $
                       R=0.7  


frnginit, php, nx, ny, mag=[0.000242873, 0.000243025, -3.71441e-7], $
                       warp = [-0.0233846, -0.00656352], $
                       center=[134.634, 127.917], $
                       ordwin=[0.1,8.1], $
                       phisq =0.00312098, $
                       R=0.7  


while (!D.window ge 0) do wdelete, !D.window
window, 0, xsize=256, ysize=256

if question eq 'n' then goto,skipfit
frng_fit, lref, php, culz
stop ;############
skipfit:

npts = 32

;  converting factor for going from peakpositions to winds, 
;  for Lambdafsr= 0.09925 Angstroms, Vfsr=4725 meters/sec, no. of points is ?
cnvrsnfctr = 4725./npts

samp_range = [0.2, 3.2]
lref = lref - mc_im_sm(lref, 50)
llas = lref
frng_spx, lref, llas, php, npts, samp_range, 0.98, culz, insprof
wshow, 2
empty

insprof = insprof - min(insprof)
insprof = insprof/max(insprof)

flist=findfile(epath+"*.cln")
flist=flist(sort(flist))
nfiles=0
filez=where(flist ge skyfile1 and flist le skyfile2, nfiles)

arrsize = 0
for findex=0,nfiles-1 do begin
 skyfile=flist(filez(findex))
 if skyfile ne '' then begin
  openr,unit,skyfile,/get_lun
  readu,unit,head
  readu,unit,isig
  close,unit
  free_lun,unit
  date=string(head(0:5))
  thtime=string(head(6:10))
  type=string(head(11:13))
  azmth=string(head(14:16))
  elev=string(head(17:18))
  if type eq '001' then begin
   arrsize=arrsize + 1
  endif
 endif
endfor

incrementval=intarr(arrsize)
thespecs=lonarr(arrsize,npts)
pkpos=fltarr(arrsize)
pkposerr=fltarr(arrsize)
wnd=fltarr(arrsize)
wnderr=fltarr(arrsize)
intnst=fltarr(arrsize)
intnsterr=fltarr(arrsize)
bckgrnd=fltarr(arrsize)
bckgrnderr=fltarr(arrsize)
timearr=strarr(arrsize)
azmtharr=intarr(arrsize)
elevarr=intarr(arrsize)

;  Describe the instrument.  Initially assume 20 mm
;  etalon gap, 1 order scan range, ?? channel spectrum:
   cal = {s_cal,   delta_lambda: 3.1e-13, $
    nominal_lambda: 630.03e-9}

;  Describe the molecular scattering species:
   species = {s_spec, name: 'O', $
    mass:  16., $
    relint: 1.}

incre=0
for findex=0,nfiles-1 do begin
 skyfile=flist(filez(findex))
 if skyfile ne '' then begin
  openr,unit,skyfile,/get_lun
  readu,unit,head
  readu,unit,isig
  close,unit
  free_lun,unit
  date=string(head(0:5))
  thtime=string(head(6:10))
  type=string(head(11:13))
  azmth=string(head(14:16))
  elev=string(head(17:18))
  if type eq '001' then begin
   timearr(incre)=thtime
   azmtharr(incre)=fix(azmth)
   elevarr(incre)=fix(elev)
   wshow, 0
   empty
   lref = isig
   lref = lref - mc_im_sm(lref, 50)
   frng_spx, lref, lsky, php, npts, samp_range, 0.95, culz, skyspec
;   skyspec = skyspec - min(skyspec)
;   skyspec = skyspec/max(skyspec)
;   skyspec = shift(skyspec, npts/2)
;   skyfft = fft(skyspec, 0)
   wshow, 2
   empty

;  Specify the diagnostics that we'd like:
   diagz = ['dummy']
;   diagz = [diagz, 'main_plot_pars(window, 3)']
;   diagz = [diagz, 'main_plot_fitz(window, 2)']
;   diagz = [diagz, 'main_loop_wait(ctlz.secwait = .1)']
   diagz = [diagz, 'main_print_answer']

;  Specify initial guesses for fit routine, along with
;  the mask indicating which of these will remain fixed:

   skyspec = skyspec - min(skyspec)
   ipeak = where(insprof eq max(insprof))
   speak = where(skyspec eq max(skyspec))
   fitpars   = [0., 0., 0., speak(0) - ipeak(0), 600.]
   fix_mask  = [0, 1, 0, 0, 0]
   
;   window, 15
;   plot, skyspec, color=culz.white
;   window, 16
;   plot, insprof, color=culz.green
 ;  stop
   if azmth eq '000' and elev eq '90' then print, 'zenith looking'
   if azmth eq '000' and elev eq '30' then print, 'northward looking'
   if azmth eq '090' then print, 'eastward looking'
   if azmth eq '180' then print, 'southward looking'
   if azmth eq '270' then print, 'westward looking'
   print,'current time is '+thtime
   print,'date is '+date
   
   
   spek_fit, skyspec, insprof, species, cal, fix_mask, diagz, fitpars, $
    sigpars, quality
    
   fittedspec = quality.fitfunc
   
   plot, skyspec, /xstyle, /ystyle, color=culz.white
   oplot, fittedspec, color=culz.green
   empty

   pkpos(incre) = fitpars(3)
   pkposerr(incre) = sigpars(3)
   thespecs(incre,*) = skyspec(*)
   incrementval(incre) = incre
   bckgrnd(incre) = fitpars(0)
   bckgrnderr(incre) = sigpars(3)
   intnst(incre) = fitpars(2)
   intnsterr(incre) = sigpars(2)
   incre=incre+1
  endif
 endif
endfor

; this section takes care of all drift correction and mean shift of peak
; position, and converts the peaks to velocities.  also, interpolation is
; done here to correct off-zenith measurements.

flttimearr = float(timearr)
pkposmean = mean(pkpos)
pkpos = pkpos - pkposmean

g=0
j=0
n=0
s=0
w=0
e=0
for i=0,arrsize-1 do begin
 if elevarr(i) eq 90 then j=j+1
 if elevarr(i) ne 90 then g=g+1
 if azmtharr(i) eq 0 and elevarr(i) eq 30 then n=n+1
 if azmtharr(i) eq 180 and elevarr(i) eq 30 then s=s+1
 if azmtharr(i) eq 270 and elevarr(i) eq 30 then w=w+1
 if azmtharr(i) eq 90 and elevarr(i) eq 30 then e=e+1
endfor
zsize=j
ozsize=g
znthpkpos=fltarr(zsize)
znthtimes=fltarr(zsize)
znthpkposwts=fltarr(zsize)
znthpkposwts(*)=1.
znthpkposwts(0)=0.5
znthpkposwts(zsize-1)=0.5
offznthpkpos=fltarr(ozsize)
corroffznthpkpos=fltarr(ozsize)
smthoffznthpkpos=fltarr(ozsize)
offznthtimes=fltarr(ozsize)
nrthpkpos=fltarr(n)
sthpkpos=fltarr(s)
wstpkpos=fltarr(w)
estpkpos=fltarr(e)
nrthtimes=fltarr(n)
sthtimes=fltarr(s)
wsttimes=fltarr(w)
esttimes=fltarr(e)
nrthwnderr=fltarr(n)
sthwnderr=fltarr(s)
wstwnderr=fltarr(w)
estwnderr=fltarr(e)
polydeg=7
j=0
g=0
for i=0,arrsize-1 do begin
 if elevarr(i) eq 90 then begin
  znthpkpos(j)=pkpos(i)
  znthtimes(j)=flttimearr(i)
  j=j+1
 endif
 if elevarr(i) ne 90 then begin
  offznthpkpos(g)=pkpos(i)
  offznthtimes(g)=flttimearr(i)
  g=g+1
 endif
endfor

;smthwdth = 0.3 * zsize
;smthznthpkpostmp1 = mc_im_sm(znthpkpos,smthwdth)
plynmialcoeffs = polyfitw(znthtimes,znthpkpos,znthpkposwts,polydeg,smthznthpkpos)
;plynmialcoeffs = poly_fit(znthtimes,znthpkpos,polydeg,smthznthpkpos)
;smthznthpkpos=smthznthpkpostmp1
;smthznthpkpos(0)=smthznthpkpostmp2(0) & smthznthpkpos(zsize-1)=smthznthpkpos(zsize-1)
corrznthpkpos = znthpkpos - smthznthpkpos

smthoffznthpkpos = interpol(smthznthpkpos,znthtimes,offznthtimes)
corroffznthpkpos = offznthpkpos - smthoffznthpkpos

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
  pkpos(i) = corrznthpkpos(j)
  j=j+1
 endif
 if elevarr(i) ne 90 then begin
  pkpos(i) = corroffznthpkpos(g)
  g=g+1
 endif
endfor

n=0
s=0
w=0
e=0
for i=0,arrsize-1 do begin
 if azmtharr(i) eq 0 and elevarr(i) eq 30 then begin
  nrthpkpos(n)=pkpos(i)
  nrthtimes(n)=flttimearr(i)
  n=n+1
 endif
 if azmtharr(i) eq 180 and elevarr(i) eq 30 then begin
  sthpkpos(s)=pkpos(i)
  sthtimes(s)=flttimearr(i)
  s=s+1
 endif
 if azmtharr(i) eq 270 and elevarr(i) eq 30 then begin
  wstpkpos(w)=pkpos(i)
  wsttimes(w)=flttimearr(i)
  w=w+1
 endif
 if azmtharr(i) eq 90 and elevarr(i) eq 30 then begin
  estpkpos(e)=pkpos(i)
  esttimes(e)=flttimearr(i)
  e=e+1
 endif
endfor

wnd = cnvrsnfctr * pkpos
wnd = -wnd
wnderr = cnvrsnfctr * pkposerr
znthwnd = cnvrsnfctr * corrznthpkpos
znthwnd = -znthwnd
offznthwnd = cnvrsnfctr * corroffznthpkpos
offznthwnd = -offznthwnd
nrthwnd = cnvrsnfctr * nrthpkpos
nrthwnd = -nrthwnd
sthwnd = cnvrsnfctr * sthpkpos
sthpkpos = -sthpkpos
wstwnd = cnvrsnfctr * wstpkpos
wstwnd = -wstwnd
estwnd = cnvrsnfctr * estpkpos
estwnd = -estwnd
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
n=0
s=0
e=0
w=0
znthwnderr=fltarr(zsize)
offznthwnderr=fltarr(ozsize)
for i=0,arrsize-1 do begin
 if elevarr(i) eq 90 then begin
  znthwnderr(j) = wnderr(i)
  j=j+1
 endif
 if elevarr(i) ne 90 then begin
  offznthwnderr(g) = wnderr(i)
  offznthwnd(g) = wnd(i)
  g=g+1
 endif
 if elevarr(i) eq 30 and azmtharr(i) eq 0 then begin
  nrthwnderr(n)=wnderr(i)
  n=n+1
 endif
 if elevarr(i) eq 30 and azmtharr(i) eq 180 then begin
  sthwnderr(s)=wnderr(i)
  s=s+1
 endif
 if elevarr(i) eq 30 and azmtharr(i) eq 270 then begin
  wstwnderr(w)=wnderr(i)
  w=w+1
 endif
 if elevarr(i) eq 30 and azmtharr(i) eq 90 then begin
  estwnderr(e)=wnderr(i)
  e=e+1
 endif
endfor

mnth=strmid(date,2,2)
pieceofdate=strmid(date,3,3)

if mnth eq '10' then pieceofdate = 'A'+strmid(date,4,2)
if mnth eq '11' then pieceofdate = 'B'+strmid(date,4,2)
if mnth eq '12' then pieceofdate = 'C'+strmid(date,4,2)

datfile1=dpath+'ivkrd'+pieceofdate+'.dbt'
openw,unit1,datfile1,/get_lun
datfile2=dpath+'ikmrd'+pieceofdate+'.dbt'
openw,unit2,datfile2,/get_lun
datfile3=dpath+'ikvrt'+pieceofdate+'.dbt'
openw,unit3,datfile3,/get_lun
datfile4=dpath+'ikhrz'+pieceofdate+'.dbt'
openw,unit4,datfile4,/get_lun
datfile5=dpath+'ikzon'+pieceofdate+'.dbt'
openw,unit5,datfile5,/get_lun

j=0
g=0
n=0
s=0
w=0
e=0
for i=0,arrsize-1 do begin
 thtime=timearr(i)
 call_procedure, 'fixtime', thtime
 printf,unit1,format='(a6,i6,i8,i8,2f8.3,f8.1,f8.2,f8.1,f8.2)',date,thtime,$
  azmtharr(i),elevarr(i),wnd(i),wnderr(i),bckgrnd(i),bckgrnderr(i),intnst(i),$
  intnsterr(i)
 if elevarr(i) eq 30 and azmtharr(i) eq 0 then begin
  printf,unit2,format='(a6,i6,i8,i8,2f8.3,f8.1,f8.2,f8.1,f8.2)',date,thtime,$
   azmtharr(i),elevarr(i),nrthwnd(n),nrthwnderr(n),bckgrnd(i),bckgrnderr(i),intnst(i),$
   intnsterr(i)
  n=n+1
 endif
 if elevarr(i) eq 30 and azmtharr(i) eq 180 then begin
  printf,unit2,format='(a6,i6,i8,i8,2f8.3,f8.1,f8.2,f8.1,f8.2)',date,thtime,$
   azmtharr(i),elevarr(i),sthwnd(s),sthwnderr(s),bckgrnd(i),bckgrnderr(i),intnst(i),$
   intnsterr(i)
  s=s+1
 endif
 if elevarr(i) eq 30 and azmtharr(i) eq 270 then begin
  printf,unit5,format='(a6,i6,i8,i8,2f8.3,f8.1,f8.2,f8.1,f8.2)',date,thtime,$
   azmtharr(i),elevarr(i),wstwnd(w),wstwnderr(w),bckgrnd(i),bckgrnderr(i),intnst(i),$
   intnsterr(i)
  w=w+1
 endif
 if elevarr(i) eq 30 and azmtharr(i) eq 90 then begin
  printf,unit5,format='(a6,i6,i8,i8,2f8.3,f8.1,f8.2,f8.1,f8.2)',date,thtime,$
   azmtharr(i),elevarr(i),estwnd(e),estwnderr(e),bckgrnd(i),bckgrnderr(i),intnst(i),$
   intnsterr(i)
  e=e+1
 endif 
 if elevarr(i) eq 90 then begin
  printf,unit3,format='(a6,i6,i8,i8,2f8.3,f8.1,f8.2,f8.1,f8.2)',date,thtime,$
   azmtharr(i),elevarr(i),znthwnd(j),znthwnderr(j),bckgrnd(i),bckgrnderr(i),intnst(i),$
   intnsterr(i)
  j=j+1 
 endif
 if elevarr(i) ne 90 then begin
  printf,unit4,format='(a6,i6,i8,i8,2f8.3,f8.1,f8.2,f8.1,f8.2)',date,thtime,$
   azmtharr(i),elevarr(i),offznthwnd(g),offznthwnderr(g),bckgrnd(i),bckgrnderr(i),intnst(i),$
   intnsterr(i)
  g=g+1
 endif
endfor

close,unit1
free_lun,unit1
close,unit2
free_lun,unit2
close,unit3
free_lun,unit3
close,unit4
free_lun,unit4
close,unit5
free_lun,unit5

end


