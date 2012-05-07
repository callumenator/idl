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

dpath='c:\wtsrv\profiles\mpkryn\imagefiles\datafiles\'

thenookie = ''
print,''
print, 'enter the date to be analyzed, YYMMDD format'
print,''
read, thenookie

restore,'c:\wtsrv\profiles\mpkryn\imagefiles\IDL_storage\'+thenookie+'arrays.dat'

load_pal,culz,idl=[3,1]

flttimearr = double(timearr) - double(9./60.)
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
 readf,unit,format='(15a6,9f8.1,i6,i10 )', d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,$
   d11,d12,d13,d14,d15,d16,d17,d18,d19,d20,d21,d22,d23,d24,d25,d26
; if strmid(d4,4,2) eq '16' then begin
;    if strmid(d5,4,2) eq '18' then goto, dontincre
; endif
; timey = double(d4)+(double(d5)/60.)+(double(d6)/3600.)
; if timey lt 5.3 or timey gt 12.04 then goto, dontincre
; if strmid(d4,5,1) eq '3' and strmid(d4,4,1) eq ' ' then begin
; 	if strmid(d5,5,1) eq '0' and strmid(d5,4,1) eq ' ' then goto, dontincre
;	if strmid(d5,5,1) eq '4' and strmid(d5,4,1) eq ' ' then goto, dontincre
; endif
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
old26 = 0.
seep=0
while (not eof(unit)) do begin
 readf,unit,format='(15a6,9f8.1,i6,i10 )', d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,$
   d11,d12,d13,d14,d15,d16,d17,d18,d19,d20,d21,d22,d23,d24,d25,d26
; if strmid(d4,4,2) eq '16' then begin
; 	if strmid(d5,4,2) eq '18' then goto, dontstore
; endif
; timey = double(d4)+(double(d5)/60.)+(double(d6)/3600.)
; if timey lt 5.3 or timey gt 12.04 then goto, dontstore
; if strmid(d4,5,1) eq '3' and strmid(d4,4,1) eq ' ' then begin
; 	if strmid(d5,5,1) eq '0' and strmid(d5,4,1) eq ' ' then goto, dontstore
;	if strmid(d5,5,1) eq '4' and strmid(d5,4,1) eq ' ' then goto, dontstore
; endif
 if strmid(d10,4,2) eq '45' or old26 eq d26 then goto, dontstore
 trl_press(seep) = d16
 trl_temp(seep) = d17
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

g=0
j=0
for i=0,arrsize-1 do begin
 if elevarr(i) eq 90 then j=j+1
 if elevarr(i) ne 90 then g=g+1
endfor
zsize=j
ozsize=g
znthpkpos=dblarr(zsize)
znthtimes=dblarr(zsize)
znthintnst=dblarr(zsize)
znthintnsterr=dblarr(zsize)
znthpkposerr=dblarr(zsize)
znthtrlpress=dblarr(zsize)
znthtrltemp=dblarr(zsize)

offznthpkpos=dblarr(ozsize)
offznthtimes=dblarr(ozsize)
offznthintnst=dblarr(ozsize)
offznthintnsterr=dblarr(ozsize)
offznthpkposerr=dblarr(ozsize)
offznthtrlpress=dblarr(ozsize)
offznthtrltemp=dblarr(ozsize)

unshftdtrl_press = trl_press
unshftdtrl_temp = trl_temp

trl_press = double(trl_press) - double(mean(trl_press))
trl_temp = double(trl_temp) - double(mean(trl_temp))

j=0
g=0
for i=0,arrsize-1 do begin
 if elevarr(i) eq 90 then begin
  znthpkpos(j)=double(shftdpkpos(i))
  znthtimes(j)=double(flttimearr(i))
  znthintnst(j)=intnst(i)
  znthintnsterr(j)=intnsterr(i)
  znthpkposerr(j)=pkposerr(i)
  znthtrlpress(j)=trl_press(i)
  znthtrltemp(j)=trl_temp(i)
  j=j+1
 endif
 if elevarr(i) ne 90 then begin
  offznthpkpos(g)=double(shftdpkpos(i))
  offznthtimes(g)=double(flttimearr(i))
  offznthintnst(g)=intnst(i)
  offznthintnsterr(g)=intnsterr(i)
  offznthpkposerr(g)=pkposerr(i)
  offznthtrlpress(g)=trl_press(i)
  offznthtrltemp(g)=trl_temp(i)
  g=g+1
 endif
endfor

pshift = 15
trange = double((max(znthtimes) - min(znthtimes))*60.)
tgrid  = double(min(znthtimes)) + dindgen(trange)/60.
rrr=n_elements(tgrid)

tempsam = interpol(double(znthtrltemp), double(znthtimes), tgrid)
tempsam = mc_im_sm(tempsam, 60)
;stop
temprange = [min(tempsam), max(tempsam)]
tempsam = tempsam + 120.*(tempsam - shift(tempsam, 1))
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
;znthtrltemp = interpol(double(znthtrltemp), double(znthtimes), tgrid)

weights = fltarr(rrr) + 1.
;weights(rrr-pshift/2:rrr-1) = 0.0001
;weights(0:pshift/2) = 0.0001

restore, 'c:\wtsrv\profiles\mpkryn\imagefiles\IDL_storage\000303prstmpcoeffs.dat'

thecoeffs = thefitcoeffs
error = theerrors

yfit = thecoeffs(1)*znthtrlpress + thecoeffs(2)*znthtrltemp
yfiterr = sqrt((znthtrlpress*error(1))^2 + (znthtrltemp*error(2))^2)
smthznthpkpos = interpol(yfit, tgrid, znthtimes)
smthznthpkposerr = interpol(yfiterr, tgrid, znthtimes)

corrznthpkpos = znthpkpos - smthznthpkpos
corrznthpkposerr = ((znthpkposerr)^2 + (smthznthpkposerr)^2)^(0.5)

znthpkposwts=fltarr(arrsize) + 1.
;znthpkposwts(arrsize/2:arrsize-1)=0.001
;for i=0,arrsize/2 do begin
; znthpkposwts(i)=1.-(2.*(float(i)/float(arrsize)))
; znthpkposwts(arrsize-1-i)=1.-(2.*(float(i)/float(arrsize)))
;endfor

;deg=5
;plycoef=polyfitw(znthtimes,corrznthpkpos,znthpkposwts,deg,polyznthpkpos,polyznthpkposerr)
wdth = 0.2 * zsize
polyznthpkpos = mc_im_sm(corrznthpkpos,wdth)

smthoffznthpkpos = interpol(smthznthpkpos,znthtimes,offznthtimes)
smthoffznthpkposerr = interpol(smthznthpkposerr,znthtimes,offznthtimes)
corroffznthpkpos = offznthpkpos - smthoffznthpkpos
corroffznthpkposerr = ((offznthpkposerr)^2 + (smthoffznthpkposerr)^2)^(0.5)
polyoffznthpkpos = interpol(polyznthpkpos,znthtimes,offznthtimes)
;polyoffznthpkposerr = interpol(polyznthpkposerr,znthtimes,offznthtimes)

fnlznthpkpos = corrznthpkpos - polyznthpkpos
;fnlznthpkpos = corrznthpkpos
totalzntherr = corrznthpkposerr
fnloffznthpkpos = corroffznthpkpos - polyoffznthpkpos
;fnloffznthpkpos = corroffznthpkpos
totaloffzntherr = corroffznthpkposerr

;totaloffzntherr = ((corroffznthpkposerr)^2 + (polyoffznthpkposerr)^2)^(0.5)
;totalzntherr = (corrznthpkposerr^2 + polyznthpkposerr^2)^(0.5)

j=0
g=0
for i=0,arrsize-1 do begin
 if elevarr(i) eq 90 then begin
  finalpkpos(i) = fnlznthpkpos(j)
  finalpkposerr(i) = totalzntherr(j)
  j=j+1
 endif
 if elevarr(i) ne 90 then begin
  finalpkpos(i) = fnloffznthpkpos(g)
  finalpkposerr(i) = totaloffzntherr(g)
  g=g+1
 endif
endfor

wnd = -(cnvrsnfctr * finalpkpos)
wnderr = cnvrsnfctr * finalpkposerr

znthwnd = -(cnvrsnfctr * fnlznthpkpos)
znthwnderr = cnvrsnfctr * totalzntherr

offznthwnd = -(cnvrsnfctr * fnloffznthpkpos)
offznthwnderr = cnvrsnfctr * totaloffzntherr

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
plot,znthtimes,znthpkpos, pos=[0.1,0.1,0.9,0.8],yrange=[-1.,1.],/ystyle,$
 title='Peak position drift correction,!C'+$
 'fitting to the pressure and response-corrected temp for that night,!C'+$
 'AND using the coefficients generated from the 000303 fit,!C'+$
 'then using a 5th deg polynomial fit to the prss/tmp corrected peak position!C'+$
 month+' '+day+', '+year,$
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
 xtitle='Time, UT',yrange=[-2., 2.],/ystyle,$
 title='Zenith Peak Position Drift Correction Analysis!C'+$
 		month+' '+day+', '+year,$
 subtitle='Graph includes raw peak position, the fit to the raw peak position!C'+$
      'based on the pressure and response-corrected temperature info.,!C'+$
	  'the shifted pressure and temp. data, and the response-corrected temp. profile'+$
	  '!CPressure coeff. is '+strmid(strcompress(thefitcoeffs(1),/rem),0,7)+$
	  '!CTemp. coeff. is '+strmid(strcompress(thefitcoeffs(2),/rem),0,7)
oplot,znthtimes,smthznthpkpos,color=culz.green
oplot,tgrid,znthtrlpress,color=culz.cyan
oplot,tgrid,znthtrltemp,color=culz.blue
oplot,znthtimes,temsave,color=culz.yellow
;wset,15
;gif_this, file='c:\wtsrv\profiles\mpkryn\imagefiles\datafiles\driftcorrtests\newprstmppoly3\presstempfit'+yr+mnthval+day+'.gif'

stop

window,1,retain=2,xsize=1000,ysize=800
plot, znthtimes,znthwnd,psym=4,pos=[0.11,0.125,0.92,0.875],$
 title='Vertical Wind, drift correction from the pressure and response-corrected temp fit,!C'+$
 	   'USING the coefficients generated from the 000303 fit,!C'+$
 	   'and a 5th deg polynomial fit!C'+month+' '+day+', '+year,$
 ytitle='Vertical wind (m/s)',xtitle='Time, UT',$
 charsize=1.125,charthick=1.50,yrange=[-100,100],/ystyle
oplot, znthtimes,znthwnd
errplot, znthtimes,znthwnd-znthwnderr, znthwnd+znthwnderr
;wset,0
;gif_this, file='c:\wtsrv\profiles\mpkryn\imagefiles\datafiles\driftcorrtests\newprstmppoly3\vrtwd'+yr+mnthval+day+'.gif'

datfile1=dpath+year+'\ascfiles\ivkrd'+pieceofdate+'.dbt'
openw,unit1,datfile1,/get_lun
datfile3=dpath+year+'\ascfiles\ikvrt'+pieceofdate+'.dbt'
openw,unit3,datfile3,/get_lun

j=0
for i=0,arrsize-1 do begin
 thtime=flttimearr(i)
 call_procedure, 'fixtime', thtime
 printf,unit1,format='(a6,i6,i8,i8,2f8.2,f8.1,f8.1,f8.1,f8.1)',date,thtime,$
  azmtharr(i),elevarr(i),wnd(i),wnderr(i),bckgrnd(i),bckgrnderr(i),intnst(i),$
  intnsterr(i)
 if elevarr(i) eq 90 then begin
  printf,unit3,format='(a6,i6,i8,i8,2f8.2,f8.1,f8.1,f8.1,f8.1)',date,thtime,$
   azmtharr(i),elevarr(i),znthwnd(j),znthwnderr(j),bckgrnd(i),bckgrnderr(i),intnst(i),$
   intnsterr(i)
  j=j+1 
 endif
endfor

close,unit1
free_lun,unit1
close,unit3
free_lun,unit3

stupid:

end