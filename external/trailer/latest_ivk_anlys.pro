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
; this function is also used in fitting the prss and temp. to the pkpos drift
;=======================================================================================
function driftcorr, x, m
 common prestempinfo, shftd_trlpress, shftd_trltemp
 return, [1., shftd_trlpress(x), shftd_trltemp(x)]
end
;=======================================================================================

;=======================================================================================
; main program
; this program does all the work for creating wind data, but does not do spectra
; generation from fringe images or the fitting to spectra
;=======================================================================================

common prestempinfo, shftd_trlpress, shftd_trltemp

;@load_pal.pro
;@mc_im_sm.pro

load_pal,culz,idl=[3,1]

cpath='c:\wtsrv\profiles\mpkryn\ivk_wnd_anlys\datafiles\'
spath='f:\users\mpkryn\ivk_wnd_anlys\datafiles\'

thenookie = ''
print,''
print, 'enter the date to be analyzed, YYMMDD format'
print,''
read, thenookie
date = thenookie

xx = dialog_pickfile()

;restore,'f:\users\mpkryn\ivk_wnd_anlys\newest_ivk_anlys\'+thenookie+'smallarrays.dat'
;restore,'f:\users\mpkryn\ivk_wnd_anlys\temp\'+thenookie+'smallarrays.dat'

restore,xx

;stop

;--converting factor for going from peakpositions to winds, 
;--for Lambdafsr= 0.077573 Angstroms, Vfsr=4182.75 meters/sec, no. of points is ?
fsr   = (557.7e-9)^2/40e-3
vfsr = ((3.e8)*fsr)/(557.7e-9)
npts = 64
cnvrsnfctr = vfsr/npts

s_arrsize = n_elements(sky_pkpos)

joe = where(sky_pkpos lt 0.,oops)
if oops gt 0 then sky_pkpos(joe) = sky_pkpos(joe) + npts
;stop
deltol = 1.0	
for j = 1,s_arrsize-1 do begin
   if abs(sky_pkpos(j) - sky_pkpos(j-1)) gt deltol then sky_pkpos(j:*) = sky_pkpos(j:*) - (sky_pkpos(j) - sky_pkpos(j-1))
endfor

;stop
	
sky_flttimes = double(sky_timearr)
sky_pkpos_mean = double(mean(sky_pkpos))
shftd_sky_pkpos = sky_pkpos - sky_pkpos_mean


;=======================================================================================
; this section opens and reads the trailer press/temp files and stores and sorts the
; info., so that it can be used in the drift correction.
;=======================================================================================

useless=''
d1=fix(0) & d2=fix(0) & d3=fix(0) & d4=fix(0) & d5=fix(0) & d6=fix(0)
d7=fix(0) & d8=fix(0) & d9=fix(0) & d10=fix(0) & d11=fix(0) & d12=fix(0)
d13=fix(0) & d14=fix(0) & d15=fix(0) & d25=fix(0) & d26=fix(0)

;housekeepfile='f:\users\mpkryn\ivk_wnd_anlys\houskeep\hk'+thenookie+'.dat'

housekeepfile = dialog_pickfile()

old26=0.
seep=0

openr,unit,housekeepfile,/get_lun
readf,unit,format='(a247)',useless
while (not eof(unit)) do begin
readf,format='(15I6,9F8.1,I6,I10)',unit, d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,$
   d11,d12,d13,d14,d15,d16,d17,d18,d19,d20,d21,d22,d23,d24,d25,d26
; if d4 eq 14 and d5 eq 41 then goto, dontincre
; if d4 eq 12 and d5 eq 34 then goto, dontincre 
; if d4 le 2 then goto, dontincre
; if d4 eq 3 then begin
;   if d5 lt 46 then goto,dontincre
; endif
; if d4 ge 12 then goto, dontincre
;   if d5 ge 15 then goto, dontincre
; endif
; if d4 eq 8 and d5 eq 42 then goto, dontincre
; if d4 eq 6 and d5 eq 46 then goto, dontincre
; if d4 eq 5 and d5 eq 3 then goto, dontincre 
; if d4 eq 10 then begin
;   if d5 eq 10 or d5 eq 18 or d5 eq 22 or d5 eq 26 then goto, dontincre
; endif
 if d10 eq 45 or old26 eq d26 then goto, dontincre
 seep=seep+1
 dontincre:
 old26 = d26
endwhile
close,unit
free_lun,unit

biggie=seep
trl_press = dblarr(biggie)
trl_temp = dblarr(biggie)
old26=0.
seep=0

openr,unit,housekeepfile,/get_lun
readf,unit,format='(a247)',useless
while (not eof(unit)) do begin
readf,unit,format='(15I6,9F8.1,I6,I10)', d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,$
   d11,d12,d13,d14,d15,d16,d17,d18,d19,d20,d21,d22,d23,d24,d25,d26
; if d4 eq 14 and d5 eq 41 then goto, dontstore
; if d4 eq 12 and d5 eq 34 then goto, dontstore
; if d4 le 2 then goto, dontstore
; if d4 eq 3 then begin
;   if d5 lt 46 then goto,dontstore
; endif
; if d4 ge 12 then goto, dontstore
;   if d5 ge 15 then goto, dontstore
; endif
; if d4 eq 8 and d5 eq 42 then goto, dontstore
; if d4 eq 6 and d5 eq 46 then goto, dontstore
; if d4 eq 5 and d5 eq 3 then goto, dontstore
; if d4 eq 10 then begin
;   if d5 eq 10 or d5 eq 18 or d5 eq 22 or d5 eq 26 then goto, dontstore
; endif
 if d10 eq 45 or old26 eq d26 then goto, dontstore
 trl_press(seep) = double(d16)
 trl_temp(seep) = double(d17)
 seep=seep+1
 dontstore:
 old26 = d26
endwhile
close,unit
free_lun,unit

if biggie ne s_arrsize then print, 'Houston, we have a problem.'
if biggie ne s_arrsize then goto, stupid

stop
;=======================================================================================


;=======================================================================================
; this section is to try to fit temp. and press. data to the pkpos drift...
; this section takes care of all drift correction and converts the peaks to velocities.
;=======================================================================================

znth_pkpos = dblarr(s_arrsize)
znth_times = dblarr(s_arrsize)
znth_pkpos = double(shftd_sky_pkpos)
znth_pkposerr = sky_pkposerr
znth_times = double(sky_flttimes)
shftd_trlpress = double(trl_press) - double(mean(trl_press))
shftd_trltemp = double(trl_temp) - double(mean(trl_temp))

pshift = 15
trange = double((max(znth_times) - min(znth_times))*60.)
tgrid  = double(min(znth_times)) + dindgen(trange)/60.
rrr = n_elements(tgrid)

tempsam = interpol(double(shftd_trltemp), double(znth_times), tgrid)
tempsam = mc_im_sm(tempsam, 60)
temprange = [min(tempsam), max(tempsam)]
tempsam = tempsam + 120.*(tempsam - shift(tempsam, 1))
tempsam(0)=tempsam(1)
tempsam = tempsam - min(tempsam)
tempsam = tempsam/max(tempsam(3:rrr-5))
tempsam = temprange(0) + (temprange(1) - temprange(0))*tempsam
nshift  = tempsam
for j=1,pshift do begin
    shf1 = shift(tempsam, j)
    nshift(j+1:*) = shf1(j+1:*)
endfor
;nshift(0) = nshift(1)
tempsam = nshift
temsave = shftd_trltemp
pressave = shftd_trlpress
zensam = interpol(double(znth_pkpos), double(znth_times), tgrid)
shftd_trlpress = interpol(double(shftd_trlpress), double(znth_times), tgrid)
shftd_trltemp = tempsam

weights = fltarr(rrr) + 1.
;weights(rrr-pshift:rrr-1) = 0.0001
;weights(0:pshift) = 100.
;weights(rrr/3:rrr-1) = 4.
;weights(rrr/4:(3*rrr)/4) = 100.
;weights(0:rrr/2) = 0.0001
;weights(0:rrr/3) = 10.
;weights((rrr/3)+1:(2*rrr)/3) = 10.
;weights((2*rrr)/3:rrr-1) = 0.001
xxx = findgen(rrr)
a = [1.,1.,1.]
fitcoeffs = svdfit(xxx,zensam,a=a,double=double,yfit=yfit,sigma=sigma,$
				function_name='driftcorr',variance=variance, weight=weights)
thefitcoeffs = fitcoeffs
theerrors = sigma
;save, thefitcoeffs, theerrors, filename='f:\users\mpkryn\ivk_wnd_anlys\newest_ivk_anlys\'+thenookie+'prstmpcoeffs.dat'
smth_znth_pkpos = interpol(yfit, tgrid, znth_times)
yfiterr = sqrt((shftd_trlpress*theerrors(1))^2 + (shftd_trltemp*theerrors(2))^2)
smth_znth_pkposerr = interpol(yfiterr, tgrid, znth_times)

new_znth_pkpos = znth_pkpos - smth_znth_pkpos
new_znth_pkposerr = (znth_pkposerr^2 + smth_znth_pkposerr^2)^(0.5)

corr_znth_pkpos = new_znth_pkpos

;wdth = 0.1 * s_arrsize
;poly_znth_pkpos = mc_im_sm(corr_znth_pkpos,wdth)
;  new routine for polyfitting to the time series per Mark

mcpoly_filter, znth_times, corr_znth_pkpos, order = 9, /lowpass

poly_znth_pkpos = corr_znth_pkpos 

;stop

fnl_pkpos = new_znth_pkpos - poly_znth_pkpos
;fnl_pkpos = new_znth_pkpos
total_pkposerr = new_znth_pkposerr

;pkpos_drift_corr = interpol(shftd_las_pkpos, las_flttimes, znth_times)
;pkpos_drift_corr_err = interpol(las_pkposerr, las_flttimes, znth_times)
;corr_znth_pkpos = znth_pkpos - pkpos_drift_corr
;corr_znth_pkposerr = (znth_pkposerr^2 + pkpos_drift_corr_err^2)
;fnl_pkpos = corr_sky_pkpos
;total_pkpos_err = corr_sky_pkpos_err

znthwnd = -(cnvrsnfctr * fnl_pkpos)
znthwnderr = cnvrsnfctr * total_pkposerr
znthintnst = sky_intnst
;znthintnsterr = sky_intnsterr
sky_intnsterr = fltarr(s_arrsize)
sky_bckgrnderr = fltarr(s_arrsize)
sky_intnsterr(*) = 1.1
sky_bckgrnderr(*) = 1.1

mnth=strmid(date,2,2)
pieceofdate=strmid(date,3,3)

if mnth eq '10' then pieceofdate = 'A'+strmid(date,4,2)
if mnth eq '11' then pieceofdate = 'B'+strmid(date,4,2)
if mnth eq '12' then pieceofdate = 'C'+strmid(date,4,2)

month=''
year=''

yr=strmid(date,0,2)
if yr eq '01' then year='2001'
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


;window,12,retain=2,xsize=800,ysize=600
;plot,sky_flttimes,shftd_sky_pkpos, pos=[0.1,0.15,0.9,0.8],$
; title='Peak position drift correction,!C'+$
; month+' '+day+', '+year,$
; xtitle='Time, UT',yrange=[-2,3]
;oplot,las_flttimes, shftd_las_pkpos, color=culz.blue
;oplot,sky_flttimes,pkpos_drift_corr,color=culz.red
;oplot,sky_flttimes,fnl_pkpos,color=culz.green

;stop

;window,5,retain=2,xsize=800,ysize=600
;plot, sky_flttimes,znthwnd,psym=4,pos=[0.15,0.15,0.9,0.85],$
; title='Vertical Wind, !C'+month+' '+day+', '+year,$
; ytitle='Vertical wind (m/s)',xtitle='Time, UT',$
; charsize=1.125,charthick=1.50
;oplot, sky_flttimes,znthwnd
;errplot, sky_flttimes,znthwnd-znthwnderr, znthwnd+znthwnderr

;stop

window,12,retain=2,xsize=800,ysize=600
plot,znth_times,znth_pkpos, pos=[0.1,0.15,0.9,0.8],$
 title='Peak position drift correction,!C'+$
 'fitting to the shifted pressure and temp for that night,!C'+$
 'and using the coefficients generated from that fit,!C'+$
 month+' '+day+', '+year, xrange=[1.,17.],xstyle=1,$
 xtitle='Time, UT',yrange=[-3.,3.],ystyle=1,$
 subtitle = 'Pressure coeff. is '+strmid(strcompress(thefitcoeffs(1),/rem),0,7)+$
			'!CTemp. coeff. is '+strmid(strcompress(thefitcoeffs(2),/rem),0,7)
oplot,znth_times,new_znth_pkpos,color=culz.blue
oplot,znth_times,smth_znth_pkpos,color=culz.red
oplot,znth_times,poly_znth_pkpos,color=culz.wheat
oplot,znth_times,fnl_pkpos,color=culz.green

stop

window,16, retain=2, xsize=800, ysize= 600
plot,znth_times,znth_pkpos,pos=[0.1,0.2,0.9,0.9],$
 xtitle='Time, UT',yrange=[-3.,3.],ystyle=1,$
 title='Zenith Peak Position Drift Correction Analysis!C'+$
 		month+' '+day+', '+year,xrange=[1.,17.],xstyle=1,$
 subtitle='Graph includes raw peak position, the fit to the raw peak position!C'+$
      'based on the pressure and response-corrected temperature info.,!C'+$
	  'the shifted pressure and temp. data, and the response-corrected temp. profile!C'+$
	  '!CPressure coeff. is '+strmid(strcompress(thefitcoeffs(1),/rem),0,7)+$
	  '!CTemp. coeff. is '+strmid(strcompress(thefitcoeffs(2),/rem),0,7)
oplot,znth_times,smth_znth_pkpos,color=culz.green
oplot,tgrid,shftd_trlpress,color=culz.cyan
oplot,tgrid,shftd_trltemp,color=culz.blue
oplot,znth_times,temsave,color=culz.yellow

stop

window,5,retain=2,xsize=800,ysize=600
plot, znth_times,znthwnd,psym=4,pos=[0.15,0.15,0.9,0.85],$
 title='Vertical Wind, drift correction from the shifted pressure and temp fit!C'+$
  	   'USING the coefficients generated from the fit to THAT days press. and temp.,!C'+$
 	   month+' '+day+', '+year,xrange=[1.,17.],xstyle=1,ystyle=1,$
 ytitle='Vertical wind (m/s)',xtitle='Time, UT',$
 charsize=1.125,charthick=1.50,yrange=[-150,150]
oplot, znth_times,znthwnd
errplot, znth_times,znthwnd-znthwnderr, znthwnd+znthwnderr

stop

;datfile1=cpath+'ivkrd'+pieceofdate+'.dbt'
;openw,unit1,datfile1,/get_lun
;datfile3=cpath+'ikvrt'+pieceofdate+'.dbt'
;openw,unit3,datfile3,/get_lun

;datfile2=spath+'ivkrd'+pieceofdate+'.dbt'
;openw,unit2,datfile2,/get_lun
;datfile4=spath+'ikvrt'+pieceofdate+'.dbt'
;openw,unit4,datfile4,/get_lun

;for i=0,s_arrsize-1 do begin
;   thtime=znth_times(i)
;   call_procedure, 'fixtime', thtime
;   printf,unit1,format='(a6,i6,i8,i8,2f8.2,6f8.1)',date,thtime,$
;    sky_azmtharr(i),sky_elevarr(i),znthwnd(i),znthwnderr(i),sky_bckgrnd(i),$
;    sky_bckgrnderr(i),sky_intnst(i),sky_intnsterr(i),sky_temp(i),sky_temperr(i)
;   printf,unit2,format='(a6,i6,i8,i8,2f8.2,4f9.1,28.1)',date,thtime,$
;    sky_azmtharr(i),sky_elevarr(i),znthwnd(i),znthwnderr(i),sky_bckgrnd(i),$
;    sky_bckgrnderr(i),sky_intnst(i),sky_intnsterr(i),sky_temp(i),sky_temperr(i)
;   if sky_elevarr(i) eq 90 then begin
;     printf,unit3,format='(a6,i6,i8,i8,2f8.2,6f8.1)',date,thtime,$
;      sky_azmtharr(i),sky_elevarr(i),znthwnd(i),znthwnderr(i),sky_bckgrnd(i),$
;      sky_bckgrnderr(i),sky_intnst(i),sky_intnsterr(i),sky_temp(i),sky_temperr(i)
;     printf,unit4,format='(a6,i6,i8,i8,2f8.2,4f9.1,2f8.1)',date,thtime,$
;      sky_azmtharr(i),sky_elevarr(i),znthwnd(i),znthwnderr(i),sky_bckgrnd(i),$
;      sky_bckgrnderr(i),sky_intnst(i),sky_intnsterr(i),sky_temp(i),sky_temperr(i)
;     j=j+1
;   endif
;endfor

;close,unit1
;free_lun,unit1
;close,unit3
;free_lun,unit3
;close,unit2
;free_lun,unit2
;close,unit4
;free_lun,unit4

stupid:

end
