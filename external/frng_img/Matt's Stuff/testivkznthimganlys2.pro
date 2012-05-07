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
;   this is the main program.
;   Analyzeimg
;=======================================================================================

cpath='c:\wtsrv\profiles\mpkryn\ivk_wnd_anlys\datafiles\'
fpath='f:\users\mpkryn\windows\ivk_wnd_anlys\datafiles\'

thenookie = ''
print,''
print, 'enter the date to be analyzed, YYMMDD format'
print,''
read, thenookie

restore,'c:\wtsrv\profiles\mpkryn\imagefiles\IDL_storage\'+thenookie+'arrays.dat'

load_pal,culz,idl=[3,1]

flttimearr = double(timearr)
pkposmean = double(mean(pkpos))
shftdpkpos = double(pkpos - pkposmean)

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

housekeepfile='c:\wtsrv\profiles\mpkryn\imagefiles\houskeep\hk'+thenookie+'.dat'

old26 = 0.
seep=0
openr,unit,housekeepfile,/get_lun
readf,unit,format='(a245)',useless
while (not eof(unit)) do begin
 readf,unit,format='(15a6,9f8.1,i6,i10)', d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,$
   d11,d12,d13,d14,d15,d16,d17,d18,d19,d20,d21,d22,d23,d24,d25,d26
 if strmid(d10,4,2) eq '45' or old26 eq d26 then goto, dontincre
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
 readf,unit,format='(15a6,9f8.1,i6,i10)', d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,$
   d11,d12,d13,d14,d15,d16,d17,d18,d19,d20,d21,d22,d23,d24,d25,d26
 if strmid(d10,4,2) eq '45' or old26 eq d26 then goto, dontstore
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
; this section is to try to fit temp. and press. data to the pkpos drift...
; takes care of all drift correction and converts the peaks to velocities.
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
rrr=n_elements(tgrid)

tempsam = interpol(double(znthtrltemp), double(znthtimes), tgrid)
;stop
tempsam = mc_im_sm(tempsam, 60)
;stop
temprange = [min(tempsam), max(tempsam)]
tempsam = tempsam + 50.*(tempsam - shift(tempsam, 1))
;stop
tempsam(0)=tempsam(1)
;stop
tempsam = tempsam - min(tempsam)
;stop
tempsam = tempsam/max(tempsam(3:rrr-5))
;stop
tempsam = temprange(0) + (temprange(1) - temprange(0))*tempsam
;stop
nshift = tempsam
for j=1,pshift do begin
	shf1 = shift(tempsam, j)
	nshift(j+1:*) = shf1(j+1:*)
endfor
;nshift(0) = nshift(1)
tempsam = nshift
;stop
temsave = znthtrltemp
pressave = znthtrlpress
zensam =  interpol(double(znthpkpos), double(znthtimes), tgrid)
znthtrlpress = interpol(double(znthtrlpress), double(znthtimes), tgrid)
znthtrltemp = tempsam
;znthtrltemp =  interpol(double(znthtrltemp), double(znthtimes), tgrid)

weights = fltarr(rrr) + 1.
;weights(rrr-pshift:rrr-1) = 0.0001
;weights(0:pshift) = 0.0001
;weights(rrr/2:rrr-1) = 0.0001
;weights(rrr/4:(3*rrr)/4) = 0.0001
;weights(0:rrr/2) = 0.0001
;weights(0:rrr/3) = 0.001
;weights((2*rrr)/3:rrr-1) = 0.001

restore, 'c:\wtsrv\profiles\mpkryn\imagefiles\IDL_storage\000303prstmpcoeffs.dat'

thecoeffs = thefitcoeffs
error = theerrors

yfit = thecoeffs(1)*znthtrlpress + thecoeffs(2)*znthtrltemp
yfiterr = sqrt((znthtrlpress*error(1))^2 + (znthtrltemp*error(2))^2)
smthznthpkpos = interpol(yfit, tgrid, znthtimes)
smthznthpkposerr = interpol(yfiterr, tgrid, znthtimes)

corrznthpkpos = znthpkpos - smthznthpkpos
corrpkposerr = ((pkposerr)^2 + (smthznthpkposerr)^2)^(0.5)

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
;plycoef=polyfitw(znthtimes,corrznthpkpos,znthpkposwts,deg,polyznthpkpos,polypkposerr)
;=======================================================================================

fnlznthpkpos = corrznthpkpos - polyznthpkpos
;fnlznthpkpos = corrznthpkpos
totalzntherr = corrznthpkposerr
;totalzntherr = (corrznthpkposerr^2 + polyznthpkposerr^2)^(0.5)

znthwnd = -(cnvrsnfctr * fnlznthpkpos)
znthwnderr = cnvrsnfctr * totalzntherr
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


window,20,retain=2,xsize=1000,ysize=800
plot,znthtimes,znthpkpos, pos=[0.1,0.1,0.9,0.8],$
 title='Peak position drift correction,!C'+$
 'fitting to the pressure and response-corrected temp for that night,!C'+$
 'AND using the coefficients generated from the 000303 fit,!C'+$
 'then using a 5th deg polynomial fit to the prss/tmp corrected peak position!C'+$
 month+' '+day+', '+year, $
 xtitle='Time, UT',$
 subtitle = 'Pressure coeff. is '+strmid(strcompress(thecoeffs(1),/rem),0,7)+$
			'!CTemp. coeff. is '+strmid(strcompress(thecoeffs(2),/rem),0,7)
oplot,znthtimes,corrznthpkpos,color=culz.blue
oplot,znthtimes,smthznthpkpos,color=culz.red
oplot,znthtimes,polyznthpkpos,color=culz.wheat
oplot,znthtimes,fnlznthpkpos,color=culz.green
;wset,20
;gif_this, file='c:\wtsrv\profiles\mpkryn\imagefiles\datafiles\driftcorrtests\newprstmppoly3\znthpkposfit'+yr+mnthval+day+'.gif'

stop

window,15, retain=2, xsize=1000, ysize= 800
plot,znthtimes,znthpkpos,pos=[0.1,0.2,0.9,0.9],$
 xtitle='Time, UT',yrange=[-1.5, 1.5],/ystyle,$
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
;wset,15
;gif_this, file='c:\wtsrv\profiles\mpkryn\imagefiles\datafiles\driftcorrtests\newprstmppoly3\presstempfit'+yr+mnthval+day+'.gif'

stop

window,2,retain=2,xsize=1000,ysize=800
plot, znthtimes,znthwnd,psym=4,pos=[0.11,0.125,0.92,0.875],$
 title='Vertical Wind, drift correction from the pressure and response-corrected temp fit,!C'+$
 	   'USING the coefficients generated from the 000303 fit,!C'+$
 	   'and a 5th deg polynomial fit!C'+month+' '+day+', '+year,$
 ytitle='Vertical wind (m/s)',xtitle='Time, UT',$
 charsize=1.125,charthick=1.50
oplot, znthtimes,znthwnd
errplot, znthtimes,znthwnd-znthwnderr, znthwnd+znthwnderr
;wset,2
;gif_this, file='c:\wtsrv\profiles\mpkryn\imagefiles\datafiles\driftcorrtests\newprstmppoly3\vrtwd'+yr+mnthval+day+'.gif'

stupid:

end