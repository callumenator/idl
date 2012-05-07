;=======================================================================================
;   this program is to read and analyze images from the trailer FPI
;   using Mark's routines.
;   Matt Krynicki, 09-14-99.
;=======================================================================================


;=======================================================================================
; this subroutine puts the time values into a format that is
; readable by my other IDL routines.
;=======================================================================================

pro fixtime, thtime
;thtime=strcompress(thtime,/remove_all)
hr=strmid(thtime,0,2)
dec=strmid(thtime,3,2)
hr=strcompress(hr,/remove_all)
thtime=hr+dec
thtime=fix(thtime)
return
end
;=======================================================================================

;=======================================================================================
; this function is used in fitting the prss and temp. to the pkpos drift
;=======================================================================================

;function driftcorr, x, m
; common prestempinfo, znthtrlpress, znthtrltemp
; return, [1., znthtrlpress(x), znthtrltemp(x)]
;end
;=======================================================================================

;=======================================================================================
;   this is the main program.
;   Analyzeimg
;=======================================================================================

;common prestempinfo, znthtrlpress, znthtrltemp

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

fpath='f:\users\mpkryn\windows\ivk_img_strg\'
epath='f:\users\mpkryn\windows\ivk_img_strg\'
dpath='f:\users\mpkryn\windows\ivk_img_strg\'

load_pal,culz,idl=[3,1]

;question=''
;print,''
;print,"do you want to fit to the laser file?  y/n"
;print,''
;read,question

laserfile=pickfile(path=fpath, filter='*.cln', file=fname, get_path=fpath, $
 title="Select the laser file to fit parameters to:", /must_exist)

skyfile1=pickfile(path=epath, filter='*.cln', file=fname, get_path=epath, $
 title="Select the first file in the list of files to analyze:", /must_exist)
skyfile2=pickfile(path=epath, filter='*.cln', file=fname, get_path=epath, $
 title="Select the last file to analyze:", /must_exist)

;gpath='c:\wtsrv\profiles\mpkryn\imagefiles\houskeep\'
;housekeepfile=pickfile(path=gpath, filter='*.dat', file=fname, $
; title="Select the housekeeping file containing the temperature and pressure values to fit drift to:", /must_exist)
 
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
					   center=[135., 128.], $
;                       center=[127.634, 127.917], $
;                       center=[132.8, 108.2], $
                       ordwin=[0.1,8.1], $
                       phisq =0.00312098, $
                       R=0.7  
while (!D.window ge 0) do wdelete, !D.window
;window, 0, xsize=256, ysize=256

;if question eq 'n' then goto,skipfit
frng_fit, lref, php, culz
;skipfit:

npts = 32

;  converting factor for going from peakpositions to winds, 
;  for Lambdafsr= 0.09925 Angstroms, Vfsr=4725 meters/sec, no. of points is ?
cnvrsnfctr = 4725./npts

samp_range = [0.2, 3.2]
lref = lref - mc_im_sm(lref, 50)
llas = lref
frng_spx, lref, llas, php, npts, samp_range, 0.95, culz, insprof
wshow, 2
empty
insprof = insprof - min(insprof)
insprof = insprof/max(insprof)

;stop

flist=findfile(epath+"*.cln")
if (flist(0) eq '') then flist=findfile(epath+"*.cln")
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

thespecs=lonarr(arrsize,npts)
pkpos=dblarr(arrsize)
pkposerr=dblarr(arrsize)
;znthpkpos=dblarr(arrsize)
;znthpkposerr=dblarr(arrsize)
;wnd=fltarr(arrsize)
;wnderr=fltarr(arrsize)
;znthwnd=fltarr(arrsize)
;znthwnderr=fltarr(arrsize)
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
   print,skyfile
   
   spek_fit, skyspec, insprof, species, cal, fix_mask, diagz, fitpars, $
    sigpars, quality
    
   fittedspec = quality.fitfunc
   
   plot, skyspec, /xstyle, /ystyle, color=culz.white
   oplot, fittedspec, color=culz.green
   empty

   if fitpars(3) lt 0. then fitpars(3) = npts + fitpars(3)
   pkpos(incre) = double(fitpars(3))
   pkposerr(incre) = double(sigpars(3)) 
   thespecs(incre,*) = skyspec(*)
   bckgrnd(incre) = fitpars(0)
   bckgrnderr(incre) = sigpars(0)
   intnst(incre) = fitpars(2)
   intnsterr(incre) = sigpars(2)
   incre=incre+1
  endif
 endif
endfor

save, /all, filename='c:\wtsrv\profiles\mpkryn\ivk_wnd_anlys\spctra_arrar_strg\'+date+'arrays.dat'
save, /all, filename='f:\users\mpkryn\windows\ivk_wnd_anlys\spctra_arrar_strg\'+date+'arrays.dat'

stop

;=======================================================================================
; this section opens and reads the trailer press/temp files and stores and sorts the
; info., so that it can be used in the drift correction.
;=======================================================================================

useless=''
d1='' & d2='' & d3='' & d4='' & d5='' & d6='' & d7='' & d8='' & d9='' & d10=''
d11='' & d12='' & d13='' & d14='' & d15=''

seep=0
openr,unit,housekeepfile,/get_lun
readf,unit,format='(a245)',useless
while (not eof(unit)) do begin
 readf,unit,format='(15a6,9f8.1,i6,i10 )', d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,$
   d11,d12,d13,d14,d15,d16,d17,d18,d19,d20,d21,d22,d23,d24,d25,d26
 if strmid(d10,4,2) eq '45' then goto, dontincre
 seep=seep+1
 dontincre:
endwhile
close,unit
free_lun,unit
biggie=seep
trl_press = dblarr(biggie)
trl_temp = dblarr(biggie)
openr,unit,housekeepfile,/get_lun
readf,unit,format='(a245)',useless
seep=0
while (not eof(unit)) do begin
 readf,unit,format='(15a6,9f8.1,i6,i10 )', d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,$
   d11,d12,d13,d14,d15,d16,d17,d18,d19,d20,d21,d22,d23,d24,d25,d26
 if strmid(d10,4,2) eq '45' then goto, dontstore
 trl_press(seep) = d16
 trl_temp(seep) = d17
 seep=seep+1
 dontstore:
endwhile
close,unit
free_lun,unit
if biggie ne arrsize then print, 'Houston, we have a problem.'
if biggie ne arrsize then goto, stupid

;=======================================================================================
; this section takes care of all drift correction and mean shift of peak
; position, and converts the peaks to velocities.
;=======================================================================================

flttimearr = double(timearr)
pkposmean = double(mean(pkpos))
shftdpkpos = double(pkpos - pkposmean)

znthpkpos=dblarr(arrsize)
znthtimes=dblarr(arrsize)
znthtrlpress=dblarr(arrsize)
znthtrltemp=dblarr(arrsize)

znthpkpos=double(shftdpkpos)
znthpkposerr=pkposerr
znthtimes=double(flttimearr)
znthtrlpress=double(trl_press)
znthtrltemp=double(trl_temp)

;smthwdth = 0.3 * arrsize
;smthznthpkpos = mc_im_sm(znthpkpos,smthwdth)
;plynmialcoeffs=polyfitw(znthtimes,znthpkpos,znthpkposwts,polydeg,smthznthpkpos,smthznthpkposerr)
;plynmialcoeffs = poly_fit(znthtimes,znthpkpos,polydeg,smthznthpkpos)

;=======================================================================================
; this section is to try to fit temp. and press. data to the pkpos drift...
;=======================================================================================

pshift = 15
trange = double((max(znthtimes) - min(znthtimes))*60.)
tgrid  = double(min(znthtimes)) + dindgen(trange)/60.
rrr=n_elements(tgrid)
tempsam =  interpol(double(znthtrltemp), double(znthtimes), tgrid)
tempsam = mc_im_sm(tempsam, 60)
temprange = [min(tempsam), max(tempsam)]
tempsam = tempsam + 120.*(tempsam - shift(tempsam, 1))
tempsam = tempsam - min(tempsam)
tempsam = tempsam/max(tempsam(3:n_elements(tempsam)-5))
tempsam = temprange(0) + (temprange(1) - temprange(0))*tempsam
nshift  = tempsam
for j=1,pshift do begin
    shf1 = shift(tempsam, j)
	nshift(j+1:*) = shf1(j+1:*)
endfor
nshift(0) = nshift(1)
tempsam = nshift

temsave = znthtrltemp
pressave = znthtrlpress

zensam =  interpol(double(znthpkpos), double(znthtimes), tgrid)
znthtrlpress =  interpol(double(znthtrlpress), double(znthtimes), tgrid)
znthtrltemp = tempsam

restore, 'c:\wtsrv\profiles\mpkryn\imagefiles\IDL_storage\prstmpcoeffs.dat'

yfit = fitcoeffs(1)*znthtrlpress + fitcoeffs(2)*znthtrltemp + fitcoeffs(0)

meantrlpress = mean(znthtrlpress)
meantrltemp = mean(znthtrltemp)
shfttrlpress = znthtrlpress - meantrlpress
shfttrltemp = znthtrltemp - meantrltemp
yfiterr = sqrt((shfttrlpress*sigma(1))^2 + (shfttrltemp*sigma(2))^2)

smthznthpkpos = interpol(yfit, tgrid, znthtimes)
smthznthpkposerr = interpol(yfiterr, tgrid, znthtimes)

corrznthpkpos = znthpkpos - smthznthpkpos
totalerr = ((pkposerr)^2 + (smthznthpkposerr)^2)^(0.5)

znthpkposwts=fltarr(arrsize) + 1.
;znthpkposwts(arrsize/2:arrsize-1)=0.001
;for i=0,arrsize/2 do begin
; znthpkposwts(i)=1.-(2.*(float(i)/float(arrsize)))
; znthpkposwts(arrsize-1-i)=1.-(2.*(float(i)/float(arrsize)))
;endfor
deg=5
plycoef=polyfitw(znthtimes,corrznthpkpos,znthpkposwts,deg,polyznthpkpos,polypkposerr)

fnlznthpkpos = corrznthpkpos - polyznthpkpos
totalerr = (corrpkposerr^2 + polypkposerr^2)^(0.5)

wnd = cnvrsnfctr * corrznthpkpos
wnd = -wnd
;wnderr = cnvrsnfctr * pkposerr
wnderr = cnvrsnfctr * totalerr
znthwnd = cnvrsnfctr * corrznthpkpos
znthwnd = -znthwnd
;znthwnderr = cnvrsnfctr * pkposerr
znthwnderr = cnvrsnfctr * totalerr
znthintnst=intnst
znthintnsterr=intnsterr

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
datfile3=dpath+year+'\ikvrt'+pieceofdate+'.dbt'
openw,unit3,datfile3,/get_lun


for i=0,arrsize-1 do begin
 thtime=timearr(i)
 call_procedure, 'fixtime', thtime
 printf,unit1,format='(a6,i6,i8,i8,2f8.2,f8.1,f8.1,f8.1,f8.1)',date,thtime,$
  azmtharr(i),elevarr(i),wnd(i),wnderr(i),bckgrnd(i),bckgrnderr(i),intnst(i),$
  intnsterr(i)

  printf,unit3,format='(a6,i6,i8,i8,2f8.2,f8.1,f8.1,f8.1,f8.1)',date,thtime,$
   azmtharr(i),elevarr(i),znthwnd(i),znthwnderr(i),bckgrnd(i),bckgrnderr(i),intnst(i),$
   intnsterr(i)

endfor

close,unit1
free_lun,unit1
close,unit3
free_lun,unit3

stupid:

end
