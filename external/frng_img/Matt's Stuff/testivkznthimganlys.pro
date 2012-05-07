;=======================================================================================
;   this program is to read and analyze images from the trailer FPI
;   using Mark's routines.
;   Matt Krynicki, 09-14-99.
;=======================================================================================

;=======================================================================================
; this subroutine puts the time values into a format that is
;readable by my other IDL routines.
;=======================================================================================

pro fixtime, thtime
inbtw=strcompress(thtime,/remove_all)
if thtime lt 10. then begin
 hr=strmid(inbtw,0,1)
 dec=strmid(inbtw,2,2)
endif else begin
 hr=strmid(inbtw,0,2)
 dec=strmid(inbtw,3,2)
endelse
;hr=strcompress(hr,/remove_all)
thtime=hr+dec
thtime=fix(thtime)
return
end
;=======================================================================================

;=======================================================================================
; this function is also used in fitting the prss and temp. to the pkpos drift
;=======================================================================================

function driftcorr, x, m
 common prestempinfo, znthtrlpress, znthtrltemp
 return, [1., znthtrlpress(x), znthtrltemp(x)]
end
;=======================================================================================

;=======================================================================================
; main program
; this program does all the work for creating wind data, but does not do spectra
; generation from fringe images or the fitting to spectra
;=======================================================================================

common prestempinfo, znthtrlpress, znthtrltemp

load_mycolor

cpath='c:\wtsrv\profiles\mpkryn\ivk_wnd_anlys\datafiles\'
spath='f:\users\mpkryn\windows\ivk_wnd_anlys\datafiles\'

thenookie = ''
print,''
print, 'enter the date to be analyzed, YYMMDD format'
print,''
read, thenookie

restore,'f:\users\mpkryn\windows\ivk_wnd_anlys\spctra_arrar_strg\'+thenookie+'arrays.dat'

temppkpos1 = pkpos(0:41)
temppkpos2 = pkpos(42:208)

;newarrsize=arrsize-1
;newpkpos=dblarr(newarrsize)
;newpkposerr=dblarr(newarrsize)
;newintnst=fltarr(newarrsize)
;newintnsterr=fltarr(newarrsize)
;newbckgrnd=fltarr(newarrsize)
;newbckgrnderr=fltarr(newarrsize)
;newtimearr=strarr(newarrsize)
;newazmtharr=intarr(newarrsize)
;newelevarr=intarr(newarrsize)
;j=0
;for i=0,arrsize-1 do begin
;  if i ne 174 then begin
;    newtimearr(j)=timearr(i)
;    newazmtharr(j)=azmtharr(i)
;    newelevarr(j)=elevarr(i)
;    newintnst(j)=intnst(i)
;    newintnsterr(j)=intnsterr(i)
;    newbckgrnd(j)=bckgrnd(i)
;    newbckgrnderr(j)=bckgrnderr(i)
;    newpkpos(j)=pkpos(i)
;    newpkposerr(j)=pkposerr(i)
;    j=j+1
;  endif
;endfor
;pkpos=newpkpos
;pkposerr=newpkposerr
;timearr=newtimearr
;azmtharr=newazmtharr
;elevarr=newelevarr
;intnst=newintnst
;intnsterr=newintnsterr
;bckgrnd=newbckgrnd
;bckgrnderr=newbckgrnderr
;arrsize=newarrsize


load_pal,culz,idl=[3,1]

flttimearr = double(timearr)
;pkposmean = double(mean(pkpos))
;shftdpkpos = double(pkpos - pkposmean)

pkposmean1 = double(mean(temppkpos1))
pkposmean2 = double(mean(temppkpos2))
shftdpkpos1 = double(temppkpos1 - pkposmean1)
shftdpkpos2 = double(temppkpos2 - pkposmean2)

shftdpkpos = dblarr(n_elements(pkpos))
shftdpkpos(0:41) = shftdpkpos1
shftdpkpos(42:208) = shftdpkpos2

;=======================================================================================
; this section opens and reads the trailer press/temp files and stores and sorts the
; info., so that it can be used in the drift correction.
;=======================================================================================

useless=''
d1='' & d2='' & d3='' & d4='' & d5='' & d6='' & d7='' & d8='' & d9='' & d10=''
d11='' & d12='' & d13='' & d14='' & d15=''

;gpath='c:\wtsrv\profiles\mpkryn\imagefiles\houskeep\'
;housekeepfile=pickfile(path=gpath, filter='*.dat', file=fname, $
; title="Select the housekeeping file containing the temperature and pressure values to fit drift to:", /must_exist)

housekeepfile='f:\users\mpkryn\windows\ivk_wnd_anlys\houskeep\hk'+thenookie+'.dat'

old26=0.
seep=0
openr,unit,housekeepfile,/get_lun
readf,unit,format='(a245)',useless
while (not eof(unit)) do begin
 readf,unit,format='(15a6,9f8.1,i6,i10 )', d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,$
   d11,d12,d13,d14,d15,d16,d17,d18,d19,d20,d21,d22,d23,d24,d25,d26
 if strmid(d10,4,2) eq '45' or old26 eq d26 then goto, dontincre
 if strmid(d4,4,2) eq '14' and strmid(d5,4,2) eq '41' then goto, dontincre
 seep=seep+1
 dontincre:
 old26 = d26
endwhile
close,unit
free_lun,unit
biggie=seep
trl_press = dblarr(biggie)
trl_temp = dblarr(biggie)
openr,unit,housekeepfile,/get_lun
readf,unit,format='(a245)',useless
old26=0.
seep=0
while (not eof(unit)) do begin
 readf,unit,format='(15a6,9f8.1,i6,i10 )', d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,$
   d11,d12,d13,d14,d15,d16,d17,d18,d19,d20,d21,d22,d23,d24,d25,d26
 if strmid(d10,4,2) eq '45' or old26 eq d26 then goto, dontstore
 if strmid(d4,4,2) eq '14' and strmid(d5,4,2) eq '41' then goto, dontstore
 trl_press(seep) = double(d16)
 trl_temp(seep) = double(d17)
 seep=seep+1
 dontstore:
 old26 = d26
endwhile
close,unit
free_lun,unit
if biggie ne arrsize then print, 'Houston, we have a problem.'
if biggie ne arrsize then goto, stupid
;=======================================================================================

;=======================================================================================
; this section is not used, keeping in case want to refer to this, was used in
; trying to fit to pressure and temperature info for the drift.
;gauwidth = 10.
;plycoef = dblarr(6)
;wts = fltarr(rrr) + 1.
;wts(0:(rrr/3)-1) = 0.001
;plycoef = poly_fit(dindgen(rrr), double(tempsam), 9, temppoly)
;plycoef = polyfitw(dindgen(rrr), double(tempsam) , wts, 13, temppoly)
;plycoef = poly_fit(tgrid, double(tempsam), 9, temppoly)
;splinez = spline(dindgen(rrr), double(tempsam), dindgen(rrr), 100.)
;a=double(plycoef)
;newplycoef = svdfit(dindgen(rrr),double(tempsam), a=a,double=double,$
;			yfit=yfit,sigma=sigma,variance=variance)
;newplycoef = svdfit(tgrid,double(tempsam), a=a,double=double,$
;			yfit=yfit,sigma=sigma,variance=variance)
;newtemppoly=yfit
;temppoly = gaussfit(tgrid,tempsam,nterms=6)
;a=[1.,1.,1.,1.,1.,1.,1.,1.]
;temppoly = curvefit(tgrid, double(tempsam), wts, a, sigma, function_name = 'tempfunct')
;temppoly = fitgausspolys(tgrid, double(tempsam), nterms=9)
;gaufun  = findgen(n_elements(tempsam))
;gaufun  = reverse(exp(-(gaufun/gauwidth)^2))
;ft_temp = fft(tempsam, -1)
;ft_resp = fft(gaufun,  -1)
;ft_resp = ft_resp/float(ft_resp(0))
;ft_temp(6:*) = 0
;tempsam = fft(ft_temp*ft_resp, 1)
;stop
;=======================================================================================

;=======================================================================================
; this section is to try to fit temp. and press. data to the pkpos drift...
; this section takes care of all drift correction and converts the peaks to velocities.
;=======================================================================================

znthpkpos = dblarr(arrsize)
znthtimes = dblarr(arrsize)
znthtrlpress = dblarr(arrsize)
znthtrltemp = dblarr(arrsize)
znthpkpos = double(shftdpkpos)
znthpkposerr = pkposerr
znthtimes = double(flttimearr)
unshftdtrl_press = trl_press
unshftdtrl_temp = trl_temp
znthtrlpress = double(trl_press) - double(mean(trl_press))
znthtrltemp = double(trl_temp) - double(mean(trl_temp))

;stop

pshift = 15
trange = double((max(znthtimes) - min(znthtimes))*60.)
tgrid  = double(min(znthtimes)) + dindgen(trange)/60.
rrr = n_elements(tgrid)

tempsam =  interpol(double(znthtrltemp), double(znthtimes), tgrid)
;stop
tempsam = mc_im_sm(tempsam, 60)
;stop
temprange = [min(tempsam), max(tempsam)]
tempsam = tempsam + 60.*(tempsam - shift(tempsam, 1))
;stop
tempsam(0)=tempsam(1)
;stop
tempsam = tempsam - min(tempsam)
;stop
tempsam = tempsam/max(tempsam(3:rrr-5))
;stop
tempsam = temprange(0) + (temprange(1) - temprange(0))*tempsam
;stop
nshift  = tempsam
for j=1,pshift do begin
    shf1 = shift(tempsam, j)
    nshift(j+1:*) = shf1(j+1:*)
endfor
;nshift(0) = nshift(1)
tempsam = nshift
;stop
temsave = znthtrltemp
pressave = znthtrlpress
zensam = interpol(double(znthpkpos), double(znthtimes), tgrid)
znthtrlpress =  interpol(double(znthtrlpress), double(znthtimes), tgrid)
znthtrltemp = tempsam
;znthtrltemp =  interpol(double(znthtrltemp), double(znthtimes), tgrid)

weights = fltarr(rrr) + 1.
;weights(rrr-pshift:rrr-1) = 0.0001
;weights(0:pshift) = 0.0001
;weights(rrr/2:rrr-1) = 0.0001
;weights(rrr/4:(3*rrr)/4) = 0.0001
;weights(0:rrr/2) = 0.0001
;weights(0:rrr/3) = 0.1
;weights((rrr/3)+1:(2*rrr)/3) = 0.5
;weights((2*rrr)/3:rrr-1) = 0.001
xxx = findgen(rrr)
a = [1.,1.,1.]
fitcoeffs = svdfit(xxx,zensam,a=a,double=double,yfit=yfit,sigma=sigma,$
				function_name='driftcorr',variance=variance, weight=weights)
thefitcoeffs = fitcoeffs
theerrors = sigma
save, thefitcoeffs, theerrors, filename='f:\users\mpkryn\windows\ivk_wnd_anlys\spctra_arrar_strg\'+thenookie+'prstmpcoeffs.dat'
save, thefitcoeffs, theerrors, filename='c:\wtsrv\profiles\mpkryn\ivk_wnd_anlys\spctra_arrar_strg\'+thenookie+'prstmpcoeffs.dat'
smthznthpkpos = interpol(yfit, tgrid, znthtimes)
yfiterr = sqrt((znthtrlpress*theerrors(1))^2 + (znthtrltemp*theerrors(2))^2)
smthznthpkposerr = interpol(yfiterr, tgrid, znthtimes)

corrznthpkpos = znthpkpos - smthznthpkpos
corrznthpkposerr = (znthpkposerr^2 + smthznthpkposerr^2)^(0.5)

wdth = 0.1 * arrsize
polyznthpkpos = mc_im_sm(corrznthpkpos,wdth)

;=======================================================================================
;znthpkposwts=fltarr(arrsize) + 1.
;znthpkposwts(arrsize/2:arrsize-1)=0.001
;for i=0,arrsize/2 do begin
; znthpkposwts(i)=1.-(2.*(float(i)/float(arrsize)))
; znthpkposwts(arrsize-1-i)=1.-(2.*(float(i)/float(arrsize)))
;endfor
;deg=5
;plycoef=polyfitw(znthtimes,corrznthpkpos,znthpkposwts,deg,polyznthpkpos,polyznthpkposerr)
;=======================================================================================

fnlznthpkpos = corrznthpkpos - polyznthpkpos
;fnlznthpkpos = corrznthpkpos
totalzntherr = corrznthpkposerr
;totalzntherr = (corrznthpkposerr^2 + polyznthpkposerr^2)^(0.5)

znthwnd = -(cnvrsnfctr * fnlznthpkpos)
znthwnderr = cnvrsnfctr * totalzntherr
znthintnst = intnst
znthintnsterr = intnsterr

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


window,12,retain=2,xsize=800,ysize=600
plot,znthtimes,znthpkpos, pos=[0.1,0.15,0.9,0.8],$
 title='Peak position drift correction,!C'+$
 'fitting to the shifted pressure and temp for that night,!C'+$
 'and using the coefficients generated from that fit,!C'+$
 'then using a 5th deg polynomial fit to the prss/tmp corrected peak position!C'+$
 month+' '+day+', '+year,$
 xtitle='Time, UT',$
 subtitle = 'Pressure coeff. is '+strmid(strcompress(thefitcoeffs(1),/rem),0,7)+$
			'!CTemp. coeff. is '+strmid(strcompress(thefitcoeffs(2),/rem),0,7)
oplot,znthtimes,corrznthpkpos,color=culz.blue
oplot,znthtimes,smthznthpkpos,color=culz.red
oplot,znthtimes,polyznthpkpos,color=culz.wheat
oplot,znthtimes,fnlznthpkpos,color=culz.green
;wset,12
;gif_this, file='c:\wtsrv\profiles\mpkryn\imagefiles\datafiles\driftcorrtests\newprstmppoly1\znthpkposfit'+yr+mnthval+day+'.gif'

stop

window,16, retain=2, xsize=800, ysize= 600
plot,znthtimes,znthpkpos,pos=[0.1,0.2,0.9,0.9],$
 xtitle='Time, UT',yrange=[-3., 5.],/ystyle,$
 title='Zenith Peak Position Drift Correction Analysis!C'+$
 		month+' '+day+', '+year,$
 subtitle='Graph includes raw peak position, the fit to the raw peak position!C'+$
      'based on the pressure and response-corrected temperature info.,!C'+$
	  'the shifted pressure and temp. data, and the response-corrected temp. profile!C'+$
	  '!CPressure coeff. is '+strmid(strcompress(thefitcoeffs(1),/rem),0,7)+$
	  '!CTemp. coeff. is '+strmid(strcompress(thefitcoeffs(2),/rem),0,7)
oplot,znthtimes,smthznthpkpos,color=culz.green
oplot,tgrid,znthtrlpress,color=culz.cyan
oplot,tgrid,znthtrltemp,color=culz.blue
oplot,znthtimes,temsave,color=culz.yellow
;wset,16
;gif_this, file='c:\wtsrv\profiles\mpkryn\imagefiles\datafiles\driftcorrtests\newprstmppoly1\presstempfit'+yr+mnthval+day+'.gif'

stop

window,5,retain=2,xsize=800,ysize=600
plot, znthtimes,znthwnd,psym=4,pos=[0.15,0.15,0.9,0.85],$
 title='Vertical Wind, drift correction from the shifted pressure and temp fit!C'+$
  	   'USING the coefficients generated from the fit to THAT days press. and temp.,!C'+$
 	   'and a 5th deg polynomial fit!C'+month+' '+day+', '+year,$
 ytitle='Vertical wind (m/s)',xtitle='Time, UT',$
 charsize=1.125,charthick=1.50
oplot, znthtimes,znthwnd
errplot, znthtimes,znthwnd-znthwnderr, znthwnd+znthwnderr
;wset,5
;gif_this, file='c:\wtsrv\profiles\mpkryn\imagefiles\datafiles\driftcorrtests\newprstmppoly1\vrtwd'+yr+mnthval+day+'.gif'

stop

datfile1=cpath+year+'\ascfiles\ivkrd'+pieceofdate+'.dbt'
openw,unit1,datfile1,/get_lun
datfile3=cpath+year+'\ascfiles\vertdata\ikvrt'+pieceofdate+'.dbt'
openw,unit3,datfile3,/get_lun

datfile2=spath+year+'\ascfiles\ivkrd'+pieceofdate+'.dbt'
openw,unit2,datfile2,/get_lun
datfile4=spath+year+'\ascfiles\vertdata\ikvrt'+pieceofdate+'.dbt'
openw,unit4,datfile4,/get_lun


for i=0,arrsize-1 do begin
 thtime=flttimearr(i)
 call_procedure, 'fixtime', thtime
 printf,unit1,format='(a6,i6,i8,i8,2f8.2,f8.1,f8.1,f8.1,f8.1)',date,thtime,$
  azmtharr(i),elevarr(i),znthwnd(i),znthwnderr(i),bckgrnd(i),bckgrnderr(i),intnst(i),$
  intnsterr(i)
 printf,unit2,format='(a6,i6,i8,i8,2f8.2,f8.1,f8.1,f8.1,f8.1)',date,thtime,$
  azmtharr(i),elevarr(i),znthwnd(i),znthwnderr(i),bckgrnd(i),bckgrnderr(i),intnst(i),$
  intnsterr(i)
 if elevarr(i) eq 90 then begin
  printf,unit3,format='(a6,i6,i8,i8,2f8.2,f8.1,f8.1,f8.1,f8.1)',date,thtime,$
   azmtharr(i),elevarr(i),znthwnd(i),znthwnderr(i),bckgrnd(i),bckgrnderr(i),intnst(i),$
   intnsterr(i)
  printf,unit4,format='(a6,i6,i8,i8,2f8.2,f8.1,f8.1,f8.1,f8.1)',date,thtime,$
   azmtharr(i),elevarr(i),znthwnd(i),znthwnderr(i),bckgrnd(i),bckgrnderr(i),intnst(i),$
   intnsterr(i)
  j=j+1
 endif
endfor

close,unit1
free_lun,unit1
close,unit3
free_lun,unit3
close,unit2
free_lun,unit2
close,unit4
free_lun,unit4

stupid:

end
