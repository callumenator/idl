;=======================================================================================
;	this subroutine takes the time values, which are in a decimal format (float),
;	and removes the	actual decimal point, leaving it in an HOURDECIMAL format.
;	this new time format is used in the end result .DBT data files, compatible with
;	Roger's other FPS data formats
;=======================================================================================

pro fixtime, thetime

	inbtw=strcompress(thetime,/remove_all)

	if thetime lt 10. then begin
	  hr=strmid(inbtw,0,1)
	  dec=strmid(inbtw,2,2)
	endif else begin
	  hr=strmid(inbtw,0,2)
	  dec=strmid(inbtw,3,2)
	endelse

	thetime=hr+dec
	thetime=fix(thetime)

return
end
;=======================================================================================
;	this function is also used in fitting the prss and temp. to the pkpos drift
;=======================================================================================

function driftcorr, x, m

	common prestempinfo, shftd_trlpress, shftd_trltemp
	return, [1., shftd_trlpress(x), shftd_trltemp(x)]

end


;-------Main program
common prestempinfo, shftd_trlpress, shftd_trltemp

	epath = 'c:\fps_data\image\'
	dpath = 'c:\fps_data\latest\'
	fpath = 'c:\fps_data\results\'
	cpath = epath
	tlr_fplot = 0
;	temp_path = 'c:\fps_data\temp\'

setenv, "TLR_EPATH=f:\"
setenv, "TLR_DPATH=D:\TRAILER\LATEST\"
setenv, "TLR_FPATH=D:\TRAILER\RESULTS\"
setenv, "TLR_CPATH=D:\TRAILER\IMAGE\"
setenv, "TLR_FPLOT=0"

	if getenv("TLR_EPATH") ne "" then epath = getenv("TLR_EPATH")
	if getenv("TLR_DPATH") ne "" then dpath = getenv("TLR_DPATH")
	if getenv("TLR_FPATH") ne "" then fpath = getenv("TLR_FPATH")
	if getenv("TLR_CPATH") ne "" then cpath = getenv("TLR_CPATH")
	if getenv("TLR_FPLOT") ne "" then tlr_fplot = fix(getenv("TLR_FPLOT"))

	year = dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime())-86400L, format='Y$')
	mnth = dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime())-86400L, format='0n$')
	day  = dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime())-86400L, format='0d$')

	if year eq '2001' then yr = '01'
	if year eq '2002' then yr = '02'
	if year eq '2003' then yr = '03'

	subdir = yr + mnth + day + '\'
	if getenv("SUBDIR") ne "" then subdir = getenv("SUBDIR") + "\"
	if getenv("SUBDIR") ne "" then begin
	  yr = strmid(subdir,0,2)
	  mnth = strmid(subdir,2,2)
	  day = strmid(subdir,4,2)
	  if yr eq '01' then year = '2001'
	  if yr eq '02' then year = '2002'
	  if yr eq '03' then year = '2003'
	endif

        restore, fpath + yr + mnth + day + 'arrays.dat'

;--Reduction to spectra complete.  On to the second stage of analysis.

	joe = where(sky_pkpos lt 0.,oops)
	if oops gt 0 then sky_pkpos(joe) = sky_pkpos(joe) + npts

	deltol = 1.0
	for j = 1,s_arrsize-1 do begin
	   if abs(sky_pkpos(j) - sky_pkpos(j-1)) gt deltol then sky_pkpos(j:*) = sky_pkpos(j:*) - (sky_pkpos(j) - sky_pkpos(j-1))
	endfor

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

	housekeepfile = findfile(epath+subdir+'HK'+yr+mnth+day+'.DAT',count=hkfile)
	if hkfile eq 0 then goto, stupid

	old26=0.
	seep=0

	openr,unit,housekeepfile,/get_lun
	readf,unit,format='(a247)',useless
	while (not eof(unit)) do begin
	readf,format='(15I6,9F8.1,I6,I10)',unit, d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,$
	   d11,d12,d13,d14,d15,d16,d17,d18,d19,d20,d21,d22,d23,d24,d25,d26
	 if d10 eq 45 or old26 eq d26 then goto, dontincre
	 seep=seep+1
	 dontincre:
	 old26 = d26
	endwhile
	close,unit
	free_lun,unit

	biggie=seep
	trl_hrtime = dblarr(biggie)
	trl_press = dblarr(biggie)
	trl_temp = dblarr(biggie)
	old26=0.
	seep=0

	openr,unit,housekeepfile,/get_lun
	readf,unit,format='(a247)',useless
	while (not eof(unit)) do begin
	readf,unit,format='(15I6,9F8.1,I6,I10)', d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,$
	   d11,d12,d13,d14,d15,d16,d17,d18,d19,d20,d21,d22,d23,d24,d25,d26
	 if d10 eq 45 or old26 eq d26 then goto, dontstore
	 trl_press(seep) = double(d16)
	 trl_temp(seep) = double(d17)
	 trl_hrtime(seep) = (d4*3600L + d5*60L + d6)/3600.
	 seep=seep+1
	 dontstore:
	 old26 = d26
	endwhile
	close,unit
	free_lun,unit


;=======================================================================================
; this section is to try to fit temp. and press. data to the pkpos drift...
; this section takes care of all drift correction and converts the peaks to velocities.
;=======================================================================================

	znth_pkpos = dblarr(s_arrsize)
	znth_times = dblarr(s_arrsize)
	znth_pkpos = double(shftd_sky_pkpos)
	znth_pkposerr = sky_pkposerr
	znth_times = double(sky_flttimes)

	if biggie ne s_arrsize then begin
           print, 'Houston, we have a problem...but we can fix it because we are clever.'
           extra_press = fltarr(s_arrsize)
	   extra_temp  = fltarr(s_arrsize)

	   for j=0,s_arrsize-1 do begin
	       tdiff = abs(znth_times(j) - trl_hrtime)
	       tbest = where(tdiff eq min(tdiff))
	       tbest = tbest(0)
	       extra_press(j) = trl_press(tbest)
	       extra_temp(j) = trl_temp(tbest)
	   endfor

	   trl_press = extra_press
	   trl_temp  = extra_temp
	endif


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
	tempsam = nshift
	temsave = shftd_trltemp
	pressave = shftd_trlpress
	zensam = interpol(double(znth_pkpos), double(znth_times), tgrid)
	shftd_trlpress = interpol(double(shftd_trlpress), double(znth_times), tgrid)
	shftd_trltemp = tempsam

	weights = fltarr(rrr) + 1.
	xxx = findgen(rrr)
	a = [1.,1.,1.]
	fitcoeffs = svdfit(xxx,zensam,a=a,double=double,yfit=yfit,sigma=sigma,$
					function_name='driftcorr',variance=variance, weight=weights)
	thefitcoeffs = fitcoeffs
	theerrors = sigma
	save, thefitcoeffs, theerrors, filename = fpath + yr + mnth + day + 'prstmpcoeffs.dat'

	smth_znth_pkpos = interpol(yfit, tgrid, znth_times)
	yfiterr = sqrt((shftd_trlpress*theerrors(1))^2 + (shftd_trltemp*theerrors(2))^2)
	smth_znth_pkposerr = interpol(yfiterr, tgrid, znth_times)

	new_znth_pkpos = znth_pkpos - smth_znth_pkpos
	new_znth_pkposerr = (znth_pkposerr^2 + smth_znth_pkposerr^2)^(0.5)

	corr_znth_pkpos = new_znth_pkpos

	mcpoly_filter, znth_times, corr_znth_pkpos, order = 5, /lowpass

	poly_znth_pkpos = corr_znth_pkpos

	fnl_pkpos = new_znth_pkpos - poly_znth_pkpos
	total_pkposerr = new_znth_pkposerr


	if biggie eq s_arrsize then goto, okay

stupid:

	print,''
	print,'there were problems with the pressure/temperature drift correction'
	print,''

	znth_pkpos = dblarr(s_arrsize)
	znth_times = dblarr(s_arrsize)
	znth_pkpos = double(shftd_sky_pkpos)
	znth_pkposerr = sky_pkposerr
	znth_times = double(sky_flttimes)

	new_znth_pkpos = znth_pkpos
	new_znth_pkposerr = znth_pkposerr

	corr_znth_pkpos = new_znth_pkpos

	mcpoly_filter, znth_times, corr_znth_pkpos, order = 5, /lowpass

	poly_znth_pkpos = corr_znth_pkpos

	fnl_pkpos = new_znth_pkpos - poly_znth_pkpos
	total_pkposerr = new_znth_pkposerr

okay:

	znthwnd = -(cnvrsnfctr * fnl_pkpos)
	znthwnderr = cnvrsnfctr * total_pkposerr
	znthintnst = sky_intnst
	znthintnsterr = sky_intnsterr
	znthtemp = sky_temp
	znthtemperr = sky_temperr

;--Analysis complete, do some plotting and storage to ASCII, and save to proper
;--directory.

	rel_intnst = znthintnst / 10000.

	if (mnth eq '01') then month='Jan'
	if (mnth eq '02') then month='Feb'
	if (mnth eq '03') then month='Mar'
	if (mnth eq '04') then month='Apr'
	if (mnth eq '05') then month='May'
	if (mnth eq '06') then month='Jun'
	if (mnth eq '07') then month='Jul'
	if (mnth eq '08') then month='Aug'
	if (mnth eq '09') then month='Sep'
	if (mnth eq '10') then month='Oct'
	if (mnth eq '11') then month='Nov'
	if (mnth eq '12') then month='Dec'

	if max(rel_intnst) le 10. then maxxiss = 10.
	if max(rel_intnst) gt 10. and max(rel_intnst) le 20. then maxxiss = 20.
	if max(rel_intnst) gt 20. and max(rel_intnst) le 30. then maxxiss = 30.
	if max(rel_intnst) gt 30. and max(rel_intnst) le 40. then maxxiss = 40.
	if max(rel_intnst) gt 40. and max(rel_intnst) le 50. then maxxiss = 50.
	if max(rel_intnst) gt 50. and max(rel_intnst) le 60. then maxxiss = 60.
	if max(rel_intnst) gt 60. and max(rel_intnst) le 70. then maxxiss = 70.
	if max(rel_intnst) gt 70. and max(rel_intnst) le 80. then maxxiss = 80.
	if max(rel_intnst) gt 80. and max(rel_intnst) le 90. then maxxiss = 90.
	if max(rel_intnst) gt 90. and max(rel_intnst) le 100. then maxxiss = 100.
	if max(rel_intnst) gt 100. and max(rel_intnst) le 110. then maxxiss = 110.
	if max(rel_intnst) gt 110. and max(rel_intnst) le 120. then maxxiss = 120.
	if max(rel_intnst) gt 120. and max(rel_intnst) le 130. then maxxiss = 130.
	if max(rel_intnst) gt 130. and max(rel_intnst) le 140. then maxxiss = 140.
	if max(rel_intnst) gt 140. and max(rel_intnst) le 150. then maxxiss = 150.
	if max(rel_intnst) gt 150. and max(rel_intnst) le 160. then maxxiss = 160.
	if max(rel_intnst) gt 160. and max(rel_intnst) le 170. then maxxiss = 170.
	if max(rel_intnst) gt 170. and max(rel_intnst) le 180. then maxxiss = 180.
	if max(rel_intnst) gt 180. and max(rel_intnst) le 190. then maxxiss = 190.
	if max(rel_intnst) gt 190. and max(rel_intnst) le 200. then maxxiss = 200.
	if max(rel_intnst) gt 200. and max(rel_intnst) le 210. then maxxiss = 210.
	if max(rel_intnst) gt 210. and max(rel_intnst) le 220. then maxxiss = 220.
	if max(rel_intnst) gt 220. and max(rel_intnst) le 230. then maxxiss = 230.
	if max(rel_intnst) gt 230. and max(rel_intnst) le 240. then maxxiss = 240.
	if max(rel_intnst) gt 240. and max(rel_intnst) le 250. then maxxiss = 250.
	if max(rel_intnst) gt 250. and max(rel_intnst) le 260. then maxxiss = 260.
	if max(rel_intnst) gt 260. and max(rel_intnst) le 270. then maxxiss = 270.
	if max(rel_intnst) gt 270. and max(rel_intnst) le 280. then maxxiss = 280.
	if max(rel_intnst) gt 280. and max(rel_intnst) le 290. then maxxiss = 290.
	if max(rel_intnst) gt 290. and max(rel_intnst) le 300. then maxxiss = 300.
	if max(rel_intnst) gt 300. and max(rel_intnst) le 310. then maxxiss = 310.
	if max(rel_intnst) gt 310. and max(rel_intnst) le 320. then maxxiss = 320.
	if max(rel_intnst) gt 320. and max(rel_intnst) le 330. then maxxiss = 330.
	if max(rel_intnst) gt 330. and max(rel_intnst) le 340. then maxxiss = 340.
	if max(rel_intnst) gt 340. and max(rel_intnst) le 350. then maxxiss = 350.
	if max(rel_intnst) gt 350. and max(rel_intnst) le 360. then maxxiss = 360.
	if max(rel_intnst) gt 360. and max(rel_intnst) le 370. then maxxiss = 370.
	if max(rel_intnst) gt 370. and max(rel_intnst) le 380. then maxxiss = 380.
	if max(rel_intnst) gt 380. and max(rel_intnst) le 390. then maxxiss = 390.
	if max(rel_intnst) gt 390. and max(rel_intnst) le 400. then maxxiss = 400.

	if max(znthtemp) le 1000. then t_max = 1000.
	if max(znthtemp) gt 1000. and max(znthtemp) le 1200. then t_max = 1200.
	if max(znthtemp) gt 1200. and max(znthtemp) le 1400. then t_max = 1400.
	if max(znthtemp) gt 1400. and max(znthtemp) le 1600. then t_max = 1600.
	if max(znthtemp) gt 1600. and max(znthtemp) le 1800. then t_max = 1800.
	if max(znthtemp) gt 1800. and max(znthtemp) le 2000. then t_max = 2000.
	if max(znthtemp) gt 2000. and max(znthtemp) le 2200. then t_max = 2200.
	if max(znthtemp) gt 2200. and max(znthtemp) le 2400. then t_max = 2400.
	if max(znthtemp) gt 2400. and max(znthtemp) le 2600. then t_max = 2600.
	if max(znthtemp) gt 2600. and max(znthtemp) le 2800. then t_max = 2800.
	if max(znthtemp) gt 2800. and max(znthtemp) le 3000. then t_max = 3000.
	if max(znthtemp) gt 3000. and max(znthtemp) le 3200. then t_max = 3200.
	if max(znthtemp) gt 3200. and max(znthtemp) le 3400. then t_max = 3400.
	if max(znthtemp) gt 3400. and max(znthtemp) le 3600. then t_max = 3600.
	if max(znthtemp) gt 3600. and max(znthtemp) le 3800. then t_max = 3800.


	v_title = 'Inuvik, NWT, Canada, '+month+' '+day+', '+year+'!C'+$
			  'Vertical Winds in the Lower Thermosphere'
	temp_title = 'Inuvik, NWT, Canada, '+month+' '+day+', '+year+'!C'+$
				 'Temperatures in the Lower Thermosphere'
	intnst_title = 'Inuvik, NWT, Canada, '+month+' '+day+', '+year+'!C'+$
				   '557.7 nm Relative Intensity'
load_pal,culz
set_plot,'win'
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

;###MC Mod
set_plot, 'Z'
device, set_resolution=[900,700]
;	window,5,retain=2,xsize=700,ysize=500
	plot, znth_times, znthwnd,psym=4,pos=[0.15,0.15,0.9,0.85],$
		  title = v_title,$
		  ytitle='Vertical wind speed (m/s)',xtitle='Time, UT',$
		  charsize=1.5, xrange=[min(znth_times),max(znth_times)],$
		  xstyle=1,ystyle=1,symsize=0.9,$
		  yrange=[-150,150]
	oplot, znth_times,znthwnd
	errplot, znth_times,znthwnd-znthwnderr, znthwnd+znthwnderr
;	wset,5
;	gif_this, file = dpath + yr + mnth + day + '_vertwind.gif'
;	gif_this, file = fpath + yr + mnth + day + '_vertwind.gif'
        img = tvrd()
        tvlct, r, g, b, /get
        write_gif, dpath + yr + mnth + day + '_vertwind.gif', img, r, g, b
        write_gif, fpath + yr + mnth + day + '_vertwind.gif', img, r, g, b
;        write_gif, temp_path + '_vertwind.gif', img, r, g, b

;	window,6,retain=2,xsize=700,ysize=500
	plot, znth_times, znthtemp,psym=4,pos=[0.15,0.15,0.9,0.85],$
		  title = temp_title,$
		  ytitle='Temperature (K)',xtitle='Time, UT',$
		  charsize=1.5, xrange=[min(znth_times),max(znth_times)],$
		  xstyle=1,ystyle=1,symsize=0.9,$
		  yrange=[0,t_max]
	oplot, znth_times,znthtemp
	errplot, znth_times,znthtemp-znthtemperr,znthtemp+znthtemperr
;	wset,6
;	gif_this, file = dpath + yr + mnth + day + '_temp.gif'
;	gif_this, file = fpath + yr + mnth + day + '_temp.gif'
        img = tvrd()
        tvlct, r, g, b, /get
        write_gif, dpath + yr + mnth + day + '_temp.gif', img, r, g, b
        write_gif, fpath + yr + mnth + day + '_temp.gif', img, r, g, b
;        write_gif, temp_path + '_temp.gif', img, r, g, b

;	window,7,retain=2,xsize=700,ysize=500
	plot, znth_times, rel_intnst,psym=4,pos=[0.15,0.15,0.9,0.85],$
		  title = intnst_title,$
		  ytitle='Normalized Intensity',xtitle='Time, UT',$
		  charsize=1.5, xrange=[min(znth_times),max(znth_times)],$
		  xstyle=1,ystyle=1,symsize=0.9,$
		  yrange=[0,maxxiss]
	oplot, znth_times,rel_intnst
;	wset,7
;	gif_this, file = dpath + yr + mnth + day + '_intnst.gif'
;	gif_this, file = fpath + yr + mnth + day + '_intnst.gif'
        img = tvrd()
        tvlct, r, g, b, /get
        write_gif, dpath + yr + mnth + day + '_intnst.gif', img, r, g, b
        write_gif, fpath + yr + mnth + day + '_intnst.gif', img, r, g, b
;        write_gif, temp_path + '_intnst.gif', img, r, g, b

	date = yr + mnth + day

	datfile3 = dpath + 'ik' + yr + mnth + day + '.dbt'
;	datfile3 = temp_path + 'ik.dbt'
	openw,unit3,datfile3,/get_lun

	datfile4 = fpath + 'ik' + yr + mnth + day + '.dbt'
	openw,unit4,datfile4,/get_lun

	for i = 0,s_arrsize-1 do begin
	   thetime=znth_times(i)
	   call_procedure, 'fixtime', thetime

	   printf,unit3,format='(a6,i6,i8,i8,2f8.2,4f9.1,2f8.1)',date,thetime,$
	    sky_azmtharr(i),sky_elevarr(i),znthwnd(i),znthwnderr(i),sky_bckgrnd(i),$
	    sky_bckgrnderr(i),sky_intnst(i),sky_intnsterr(i),sky_temp(i),sky_temperr(i)

	   printf,unit4,format='(a6,i6,i8,i8,2f8.2,4f9.1,2f8.1)',date,thetime,$
	    sky_azmtharr(i),sky_elevarr(i),znthwnd(i),znthwnderr(i),sky_bckgrnd(i),$
	    sky_bckgrnderr(i),sky_intnst(i),sky_intnsterr(i),sky_temp(i),sky_temperr(i)

	endfor

	close,unit3
	free_lun,unit3
	close,unit4
	free_lun,unit4

	print, ''
	print, 'Analysis is complete.'
	print, 'Well, isnt that special?!'

theend:

end