

;\\ ----------------------------------GET XCORR----------------------------------

; This procedure returns the cross-correlation between "img" and a
; Fabry-Perot fringe pattern defined by parameters in the structure "php".

pro get_xcorr, xcorr, img, php, culz, paramname, draw, power=power, area = ntop
    fringemap, fringes, pmap, php, field_stop
    if keyword_set(power) then fringes=(abs(fringes))^power
    cutoff = 0.5
    view  = culz.imgmin + bytscl(img, top=culz.imgmax-culz.imgmin)
    seen  = view(field_stop)
    used  = fringes(field_stop)
    ntop  = 0
    tops  = where(used gt cutoff, ntop)
    xcorr = total(    fringes(field_stop)*(img(field_stop) - min(img(field_stop))   ))
    if php.fplot eq 1 then begin
       seen(tops) = culz.greymin + (culz.greymax - culz.greymin)*(used(tops) - cutoff + 0.09)/(1.1 - cutoff)
       view(field_stop) = seen
       wset, draw.one
       tv, congrid(view,447,354,/interp)
       ;xyouts, 0.8, 0.95, paramname, /normal, charsize=2, charthick=2
    endif
end


;\\ ----------------------------------FRINGEMAP----------------------------------

; This procedure generates a Fabry-Perot fringe pattern defined
; parameters in the structure "php".

pro fringemap, fringes, pmap, php, field_stop

;   Determine the range of orders to be used:
    nout       = 0
    if php.minord ge 0. then begin
       maxord  = php.minord+php.delord
    endif else begin
       maxord = php.delord
    endelse

;   Warping also shifts the apparent center of the fringes - make a crude correction
;   for that:
    shiftcoef = 0.5/sqrt(maxord/(0.5*php.xmag+0.5*php.ymag))
    shiftcoef = 0.

    xx   = transpose(lindgen(php.ny,php.nx)/php.ny) - (php.xcen - php.xwarp*shiftcoef)
    yy   = lindgen(php.nx,php.ny)/php.nx            - (php.ycen - php.ywarp*shiftcoef)
    xx   = xx + php.xwarp*abs(xx)
    yy   = yy + php.ywarp*abs(yy)

    ;pmap = php.xmag*xx*xx + php.xmag*yy*yy + php.xymag*xx*yy ;\\Circular Fringes
    ;pmap = php.xmag*xx*xx + php.ymag*yy*yy + php.xymag*xx*yy

    ;pmap = (pmap + php.phisq*pmap*pmap)
    ;\\ Not enough fringes to fit phisq, so this paramter is used as a 'global' magnifier

    pmap = (php.xmag*php.phisq)*xx*xx + (php.ymag*php.phisq)*yy*yy + (php.xymag*php.phisq)*xx*yy

    if php.lambda ne 632.8 then pmap = pmap*(632.8/php.lambda)

    ;\\ Create a mask describing all points within the desired number of orders of the axis:
    field_stop = where(pmap lt maxord and pmap gt php.minord, nout)

    pmap    = (php.zerph - pmap)*!pi
    fringes = sin(pmap)
    fringes = 1./(1 + ( (4*php.R) / ((1. - php.r)^2) )*fringes*fringes)
    fringes = fringes - min(fringes)
    fringes = fringes/max(fringes)

end


;\\ ----------------------------------FRINGE SPX---------------------------------------

; Now make spectrum spanning "nchan" channels using the fitted fringe pattern:

pro sky_frng_spx, refim, img, php, nchan, ordwin, r, culz, spectrum, draw, tstamp = tstamp, zerph=zerph, scan_range=scan_range
  if not(keyword_set(tstamp))    then tstamp = ' ' else tstamp = ': ' + tstamp
  if not keyword_set(scan_range) then scan_range = 1.0
  if not(keyword_set(zerph))     then zerph = php.zerph

  phsave = php
  php.r = r
  php.minord = ordwin(0)
  php.delord = ordwin(1) - ordwin(0)
  ;frng_setres, refim, img, php, 1.0
  ;if strupcase(!d.name) ne 'Z' then window, 0, xsize=php.nx, ysize=php.ny, xpos=2, ypos=2, title="Scanning..."
  spectrum   = fltarr(scan_range*nchan)

  for j=0,scan_range*nchan-1 do begin
      zinc       = (float(j) - nchan/2.)/nchan
;      php.minord = php.minord + 1./float(nchan)
      php.zerph  = zerph + zinc
      get_xcorr, xcorr, img, php, culz, 'Channel: ' + string(j,format='(i0)'), draw, power=4, area = area
      spectrum(j) = xcorr/float(area > 1)
      wait, 0.0001
  endfor

  php = phsave

end



;\\ ********************************** MAIN PROGRAM **********************************************



pro analyse_sky, im_full, sky_parameters, save_name, culz, file_time, sky_time_js, npts, skies_done, insprof, image_type, draw, noplot=noplot


;\\ converting factor for going from peakpositions to winds,
;\\ for Lambdafsr= 0.0777573 Angstroms, Vfsr=4182.75 meters/sec, no. of points is ?
	Lambdafsr = (630.0311e-9)^2/(2*12.948e-3)
	Vfsr = ((3.e8)*Lambdafsr)/630.0311e-9
	cnvrsnfctr = Vfsr/npts ;\\approx = 114m/s/channel

;\\ Describe the species that emitted the airglow signal that we observed:
	species = {s_spec, name: 'O', mass:  16., relint: 1.}

;\\ Describe the instrument.  In this case we have a 12.948 mm etalon gap,
;  1 order scan range, npts channels in the spectrum:
	gap    = 12.948e-3
	lambda = 630.0311e-9
	fsr    = lambda^2/(2*gap)

	cal    = {s_cal, delta_lambda: fsr/npts, nominal_lambda: 630.0311e-9}

;\\ Specify the diagnostic messages/plots that we'd like 'spek_fit' to produce:
	diagz = ['dummy']
;	diagz = [diagz, 'main_print_answer']
;	diagz = [diagz, 'main_plot_pars(window, 3)']
;	diagz = [diagz, 'nonlin_print_lambda']
; 	diagz = [diagz, 'main_plot_fitz(window, 0)']
;        diagz = [diagz, 'main_loop_wait(ctlz.secwait = 0.01)']


;\\ read in the image and clean it

ll = imageclean(read_tiff(im_full))

nx = n_elements(ll(*,0))
ny = n_elements(ll(0,*))


if noplot eq 1 then sky_parameters.fplot = 0 else sky_parameters.fplot = 1

;\\ Scan the sky spectrum
   sky_frng_spx, ll, ll, sky_parameters, npts, [0.0, 3.0], 0.9, culz, sky_spec, draw, zerph=0

   ipeak = where(insprof eq max(insprof))
   speak = where(sky_spec eq max(sky_spec))

   fitpars   = [0., 0., 0., speak(0) - ipeak(0), 600.]
   fix_mask  = [0, 1, 0, 0, 0]


   ;\\ Now fit an emission spectrum to the sky spectrum, using the instrument profile obtained from the laser fringes:
   spek_fit, sky_spec, insprof, species, cal, fix_mask, diagz, fitpars, sigpars, quality, /passive, max_warps=5, max_iters=2390, chisq_tolerance=0.001
   wait, .1



if skies_done eq 0 then begin


 ;\\ Make the initial arrays
 iter_num 			= intarr(1)
 sky_pkpos 			= dblarr(1)
 sky_pkposerr 		= dblarr(1)
 thesky_specs 		= dblarr(1,npts)
 fittedsky_specs 	= dblarr(1,npts)
 sky_bckgrnd 		= fltarr(1)
 sky_bckgrnderr  	= fltarr(1)
 sky_temp 			= fltarr(1)
 sky_temperr 		= fltarr(1)
 sky_intnst	        = fltarr(1)
 sky_intnsterr      = fltarr(1)
 sky_title 			= strarr(1)
 sky_time 			= dblarr(1)
 sky_jtime 			= dblarr(1)
 sky_chisq 			= fltarr(1)
 sky_params 		= replicate(sky_parameters,1)

 ;\\ Fill the initial arrays
 iter_num(0) 			= quality.iters
 sky_pkpos(0) 			= double(fitpars(3))
 sky_pkposerr(0) 		= double(sigpars(3))
 thesky_specs(0,*) 		= sky_spec(*)
 fittedsky_specs(0,*) 	= quality.fitfunc(*)
 sky_bckgrnd(0) 		= fitpars(0)
 sky_bckgrnderr(0) 		= sigpars(0)
 sky_intnst(0) 			= fitpars(2)/sky_parameters.exp_time
 sky_intnsterr(0) 		= sigpars(2)
 sky_temp(0) 			= fitpars(4)
 sky_temperr(0) 		= sigpars(4)
 sky_title(0) 			= image_type
 sky_time(0) 			= file_time
 sky_jtime(0) 			= sky_time_js
 sky_chisq(0) 			= quality.chisq(quality.iters)
 sky_params(0)			= sky_parameters

 skies_done = skies_done + 1

 save, filename = save_name, iter_num, sky_pkpos, sky_pkposerr, thesky_specs, $
 						     fittedsky_specs, sky_bckgrnd, sky_bckgrnderr, $
 							 sky_intnst, sky_intnsterr, sky_temp, sky_temperr, $
 							 sky_title, sky_time, sky_chisq, skies_done, sky_params, sky_jtime, /compress

endif else begin

  restore, save_name

   ;\\ Add to the save arrays
   temparr = replicate(sky_parameters, skies_done+1)
   temparr(0:skies_done-1) = sky_params
   temparr(skies_done) = sky_parameters

   sky_params = temparr

   temparr = intarr(n_elements(iter_num)+1)
   temparr(0:skies_done-1) = iter_num
   temparr(skies_done) = quality.iters

   iter_num = temparr

   temparr = dblarr(n_elements(sky_pkpos)+1)
   temparr(0:skies_done-1) = sky_pkpos
   temparr(skies_done) = double(fitpars(3))

   sky_pkpos = temparr

   temparr = dblarr(n_elements(sky_pkposerr)+1)
   temparr(0:skies_done-1) = sky_pkposerr
   temparr(skies_done) = double(sigpars(3))

   sky_pkposerr = temparr

   temparr = dblarr(n_elements(thesky_specs(*,0))+1,npts)
   temparr(0:skies_done-1,*) = thesky_specs
   temparr(skies_done,*) = sky_spec(*)

   thesky_specs = temparr

   temparr = dblarr(n_elements(fittedsky_specs(*,0))+1,npts)
   temparr(0:skies_done-1,*) = fittedsky_specs
   temparr(skies_done,*) = quality.fitfunc(*)

   fittedsky_specs = temparr

   temparr = fltarr(n_elements(sky_bckgrnd)+1)
   temparr(0:skies_done-1) = sky_bckgrnd
   temparr(skies_done) = fitpars(0)

   sky_bckgrnd = temparr

   temparr = fltarr(n_elements(sky_bckgrnderr)+1)
   temparr(0:skies_done-1) = sky_bckgrnderr
   temparr(skies_done) = sigpars(0)

   sky_bckgrnderr = temparr

   temparr = fltarr(n_elements(sky_intnst)+1)
   temparr(0:skies_done-1) = sky_intnst
   temparr(skies_done) = fitpars(2)/sky_parameters.exp_time

   sky_intnst = temparr

   temparr = fltarr(n_elements(sky_intnsterr)+1)
   temparr(0:skies_done-1) = sky_intnsterr
   temparr(skies_done) = sigpars(2)

   sky_intnsterr = temparr

   temparr = fltarr(n_elements(sky_temp)+1)
   temparr(0:skies_done-1) = sky_temp
   temparr(skies_done) = fitpars(4)

   sky_temp = temparr

   temparr = fltarr(n_elements(sky_temperr)+1)
   temparr(0:skies_done-1) = sky_temperr
   temparr(skies_done) = sigpars(4)

   sky_temperr = temparr

   temparr = strarr(n_elements(sky_title)+1)
   temparr(0:skies_done-1) = sky_title
   temparr(skies_done) = image_type

   sky_title = temparr

   temparr = dblarr(n_elements(sky_time)+1)
   temparr(0:skies_done-1) = sky_time
   temparr(skies_done) = file_time

   sky_time = temparr

   temparr = dblarr(n_elements(sky_jtime)+1)
   temparr(0:skies_done-1) = sky_jtime
   temparr(skies_done) = sky_time_js

   sky_jtime = temparr

   temparr = fltarr(n_elements(sky_chisq)+1)
   temparr(0:skies_done-1) = sky_chisq
   temparr(skies_done) = quality.chisq(quality.iters)

   sky_chisq = temparr


   skies_done = skies_done + 1

   save, filename = save_name, iter_num, sky_pkpos, sky_pkposerr, thesky_specs, $
 							   fittedsky_specs, sky_bckgrnd, sky_bckgrnderr, $
 							   sky_intnst, sky_intnsterr, sky_temp, sky_temperr, $
 							   sky_title, sky_time, sky_chisq, skies_done, sky_params, sky_jtime, /compress


endelse





end