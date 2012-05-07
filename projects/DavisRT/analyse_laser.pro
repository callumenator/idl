

;\\ ----------------------------------NINT---------------------------------------

; This function returns the nearest integer to "floatin".
function nint, floatin
   ninteger    = long(floatin)
   chopper = floatin - ninteger
   if chopper gt 0.5 then ninteger = ninteger+1
   if abs(ninteger) lt 32768l then ninteger = fix(ninteger)
   return, ninteger
end


;\\ ----------------------------------IMAGE CLEANER------------------------------------------

function imageclean, isig

    isignew = isig
    nbad = 0

;---First, fix really big blotches:
    medsig = median(isignew, 15)
    difsig = abs(isignew - medsig)
    bads   = where(difsig/(medsig + max(medsig/200.)) gt 0.5, nbad)
    if nbad gt 0 then isignew(bads) = medsig(bads)

;---Then look closer:
    medsig = median(isignew, 10)
    difsig = abs(isignew - medsig)
    bads   = where(difsig/(medsig + max(medsig/200.)) gt 0.3, nbad)
    if nbad gt 0 then isignew(bads) = medsig(bads)

;---Then look even closer:
    medsig = median(isignew, 5)
    difsig = abs(isignew - medsig)
    bads   = where(difsig/(medsig + max(medsig/200.)) gt 0.2, nbad)
    if nbad gt 0 then isignew(bads) = medsig(bads)

return, isignew

end



;\\ ----------------------------------PARAMS INITIALISER------------------------------------------



pro frnginit, php, nx, ny, center=center, censtep=censtep, $
                           mag=mag,       mgstep=magstep, $
                           warp=warp,     wpstep=wpstep, $
                           phisq=phisq,   pstep=phistep, $
                           zerph=zerph,   zrstep=zerstep, $
                           ordwin=ordwin, R=R, lambda=lambda, $
                           xcpsave=xcpsave, time=time, exp_time = exp_time, $
                           elevation = elevation, azimuth = azimuth, $
                           tube = tube


if not(keyword_set(center))   then center   = [nx/2., ny/2.]
if not(keyword_set(censtep))  then censtep  = 0.01*center
if not(keyword_set(mag))      then mag      = [0.01, 0.01, 0.0001]
if not(keyword_set(magstep))  then magstep  = 0.01*mag
if not(keyword_set(warp))     then warp     = [0.0, 0.0]
if not(keyword_set(wpstep))   then wpstep   = [0.001, 0.001]
if not(keyword_set(phisq))    then phisq    = 0.0
if not(keyword_set(phstep))   then phstep   = 0.0001
if not(keyword_set(zerph))    then zerph    = 0.5
if not(keyword_set(zrstep))   then zrstep   = 0.01
if not(keyword_set(ordwin))   then ordwin   = [0.1, 5.1]
if not(keyword_set(lambda))   then lambda   = 630.03e-9
if not(keyword_set(R))        then R        = 0.95
if not(keyword_set(xcpsave))  then xcpsave  = 'NO'
if not(keyword_set(time))     then time     = 0
if not(keyword_set(exp_time)) then exp_time     = 0
if not(keyword_set(elevation)) then elevation     = 0
if not(keyword_set(azimuth)) then azimuth     = 0
if not(keyword_set(tube)) then tube = 0


  php = {s_php, xcen:     center(0),     $
                xcstp:    censtep(0),    $
                ycen:     center(1),     $
                ycstp:    censtep(1),    $
                xwarp:    warp(0),       $
                xwstp:    wpstep(0),     $
                ywarp:    warp(1),       $
                ywstp:    wpstep(1),     $
                nx:       nx,            $
                ny:       ny,            $
                xmag:     mag(0),        $
                xmstp:    magstep(0),    $
                ymag:     mag(1),        $
                ymstp:    magstep(1),    $
                xymag:    mag(2),        $
                xymstp:   magstep(2),    $
                phisq:    phisq,         $
                phistp:   phstep,        $
                zerph:    zerph,         $
                zerstp:   zrstep,        $
                resfac:   1.,            $
                xsize:    0.,            $
                ysize:    0.,            $
                delord:   ordwin(1) - ordwin(0),         $
                minord:   ordwin(0),     $
                fplot:    1,             $
                xcpsave:  xcpsave,       $
                lambda:   632.8,         $
                time: double(time),              $
                exp_time: float(exp_time),		$
                elevation: float(elevation), $
                azimuth: float(azimuth), $
                tube: float(tube), $
                R:        R}
   php.xsize = nx
   php.ysize = ny
 end

;\\ ----------------------------------FRINGE FIT------------------------------------------


pro frng_fit, fringe_img, php, culz, draw, skip_rough=skip_rough, progress=progress
;   First, do some fitting to a lower resolution version of the image.  This allows
;   the initial "rough searching" to proceed much faster:
    job0 = ['zerph', '20']
    job1 = ['zerph', '8']
    job1 = [[job1],  ['xcen',   '8']]
    job1 = [[job1],  ['ycen',   '8']]
    job1 = [[job1],  ['xmag',   '8']]
    job1 = [[job1],  ['ymag',   '8']] ;\\###############
    job1 = [[job1],  ['xymag',  '8']] ;\\###############
    job1 = [[job1],  ['xwarp',  '8']] ;\\###############
    job1 = [[job1],  ['ywarp',  '8']] ;\\###############
    job1 = [[job1],  ['phisq',  '8']] ;\\###############
    job2 = ['zerph', '8']
    job2 = [[job2],  ['xcen',   '6']]
    job2 = [[job2],  ['ycen',   '6']]
    job2 = [[job2],  ['xmag',   '6']]
    job2 = [[job2],  ['ymag',   '6']] ;\\###############
    job2 = [[job2],  ['xymag',  '6']] ;\\###############
    job2 = [[job2],  ['xwarp',  '6']] ;\\###############
    job2 = [[job2],  ['ywarp',  '6']] ;\\###############
    job2 = [[job2],  ['phisq',  '8']] ;\\###############

    job3 = ['zerph', '8']
    job3 = [[job3],  ['phisq',  '8']]

    if keyword_set(progress) then begin
       progressBar = Obj_New("SHOWPROGRESS", message='Percent Completion', title='Fitting...')
       progressBar->Start
    endif

    pbase = 0
    pinc = 12.5

    if not(keyword_set(skip_rough)) then begin
       pbase = 42
       pinc  = 7.25
       frng_setres, fringe_img, img, php, 0.70

       if keyword_set(progress) then progressbar->update, 0

       imgfit, img, php, job0, culz, draw
       if keyword_set(progress) then progressbar->update, 4

       imgfit, img, php, job1, culz, draw
       if keyword_set(progress) then progressbar->update, 10

       imgfit, img, php, job2, culz, draw

       frng_setres, fringe_img, img, php, 0.80

       if keyword_set(progress) then progressbar->update, 16

       imgfit, img, php, job1, culz, draw
       if keyword_set(progress) then progressbar->update, 22

       imgfit, img, php, job2, culz, draw
       if keyword_set(progress) then progressbar->update, 30

       imgfit, img, php, job1, culz, draw

       frng_setres, fringe_img, img, php, 0.90

       if keyword_set(progress) then progressbar->update, 36

       imgfit, img, php, job1, culz, draw
       if keyword_set(progress) then progressbar->update, 42

       imgfit, img, php, job2, culz, draw
    endif

    frng_setres, fringe_img, img, php, 1.0

    if keyword_set(progress) then progressbar->update, pbase

    imgfit, img, php, job2, culz, draw
    if keyword_set(progress) then progressbar->update, pbase + 1*pinc

    imgfit, img, php, job2, culz, draw
    if keyword_set(progress) then progressbar->update, pbase + 2*pinc

    imgfit, img, php, job2, culz, draw
    if keyword_set(progress) then progressbar->update, pbase + 3*pinc

    imgfit, img, php, job2, culz, draw
    if keyword_set(progress) then progressbar->update, pbase + 4*pinc

    imgfit, img, php, job2, culz, draw
    if keyword_set(progress) then progressbar->update, pbase + 5*pinc

    imgfit, img, php, job2, culz, draw
    if keyword_set(progress) then progressbar->update, pbase + 6*pinc

    imgfit, img, php, job2, culz, draw
    if keyword_set(progress) then progressbar->update, pbase + 7*pinc

    imgfit, img, php, job3, culz, draw

    if keyword_set(progress) then begin
       progressBar->Destroy
       Obj_Destroy, progressBar
    endif

end

;\\ ----------------------------------SET RESOLUTION------------------------------------------


pro frng_setres, refim, img, php, resfac

  modfac     = resfac/php.resfac
  php.resfac = resfac

  get_tagnum, php, 'ycstp', znum
  for j = 0,znum do begin
     php.(j) = php.(j)*modfac
  endfor
  get_tagnum, php, 'ywstp', znum
  get_tagnum, php, 'xymstp', ynum
  for j = znum+1,ynum do begin
     php.(j) = php.(j)/(modfac^2)
  endfor

  fnx    = resfac*php.xsize
  fny    = resfac*php.ysize
  php.nx = nint(fnx)
  php.ny = nint(fny)

  img = congrid(refim, php.nx, php.ny, /interp)

end


;\\ ----------------------------------IMG FIT------------------------------------------

; This procedure executes a series of fitting tasks, defined by the
; array "jobs".

pro imgfit, img, php, jobs, culz, draw


for j = 0, n_elements(jobs(0, *)) - 1 do begin
    get_tagnum, php, jobs(0, j), znum ; Get the tag number of the j-th job parameter
    if php.(znum+1) gt 0 then begin   ; Only fit it if the stepsize is gt 0
       co=0
       repeat begin
              co=co+1
              parname  = jobs(0, j)
              parsteps = fix(jobs(1, j))
              frng_pft, img, php, parname, parsteps, culz, status, draw
              get_tagnum, php, parname, znum
              stepsize   = php.(znum+1)
              if status ge 0 then begin
                 php.(znum+1) = abs((0.5 + 1.0*status)*stepsize)
              endif else begin
                 php.(znum+1) = abs(1.7*stepsize)
              endelse
       endrep until status ge 0
    endif
endfor
end


;\\ ----------------------------------FRINGE PFT------------------------------------------

; This procedure finds the best choice for one parameter in the fringe
; model - within a search range defined by the "stepsize" and "nsteps"
; values passed in.

pro frng_pft, img, php, parname, nsteps, culz, status, draw

    wait, 0.0001
    get_tagnum, php, parname, znum
    stepsize   = php.(znum+1)
    phq        = php
    parbase    = phq.(znum) - stepsize*nsteps/2.
    crosscor   = fltarr(nsteps+1)
    corx       = fltarr(nsteps+1)

    if parname eq 'xcen' or parname eq 'ycen' then begin
     if stepsize lt 0.05 then begin
      status = 0.5
      goto, SKIP_FIT
     endif
    endif

    if parname eq 'xmag' or parname eq 'ymag' then begin
     if stepsize lt 1e-8 then begin
      status = 0.5
      goto, SKIP_FIT
     endif
    endif

    if parname eq 'xwarp' or parname eq 'ywarp' then begin
     if stepsize lt 1e-4 then begin
      status = 0.5
      goto, SKIP_FIT
     endif
    endif

    if parname eq 'xymag' then begin
     if stepsize lt 1e-10 then begin
      status = 0.5
      goto, SKIP_FIT
     endif
    endif

    if parname eq 'zerph' then begin
     if stepsize lt 1e-7 then begin
      status = 0.5
      goto, SKIP_FIT
     endif
    endif

    if parname eq 'phisq' then begin
     if stepsize lt 1e-7 then begin
      status = 0.5
      goto, SKIP_FIT
     endif
    endif

    for j = 0,nsteps do begin
        phq.(znum) = parbase + stepsize*float(j)
        get_xcorr, xcorr, img, phq, culz, parname, draw, area = area
        crosscor(j) = xcorr/float(area > 1)
        corx(j)     = phq.(znum)
    endfor
        ccr = crosscor
    bx = where(crosscor eq max(crosscor))
    bx = bx(0)

    if bx gt 0 and bx lt nsteps then begin
       bstep      = 0.5*(crosscor(bx-1) - crosscor(bx+1))/(crosscor(bx-1) - 2.*crosscor(bx) + crosscor(bx+1))
       php.(znum) = parbase + stepsize*(bx+bstep)
       status     = abs(bx - nsteps/2.)/(nsteps/2.)
    endif else begin
       php.(znum) = parbase + stepsize*bx
       status     = -1
    endelse

    ccr = ccr/max(ccr)

SKIP_FIT:
end


;\\ ----------------------------------GET TAGNUM----------------------------------

; This procedure returns the tag number for the tag in structure "php"
; whose name matches that given by "key"

pro get_tagnum, php, key, nbr
    nbr   = -1
    namz  = strupcase(tag_names(php))
    for j = 0, n_elements(namz) -1 do begin
        if strpos(namz(j), strupcase(key)) eq 0 then nbr = j
    endfor
end


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

pro frng_spx, refim, img, php, nchan, ordwin, r, culz, spectrum, draw, tstamp = tstamp, zerph=zerph, scan_range=scan_range
  if not(keyword_set(tstamp))    then tstamp = ' ' else tstamp = ': ' + tstamp
  if not keyword_set(scan_range) then scan_range = 1.0
  if not(keyword_set(zerph))     then zerph = php.zerph

  phsave = php
  php.r = r
  php.minord = ordwin(0)
  php.delord = ordwin(1) - ordwin(0)
  frng_setres, refim, img, php, 1.0
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



;\\ **************************************** MAIN PROGRAM *********************************************


pro analyse_laser, im_full, save_name, culz, las_time, npts, lasers_done, draw, app_base, exp_time, elevation, azimuth, tube, skip_rough = skip_rough, noplot=noplot


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

frnginit, php, nx, ny

widget_control, /show, app_base

if lasers_done eq 0 then begin 	;\\first laser, fit all params and save params in base_las.dat
								;\\ array called las_params


   frnginit, php, nx, ny, mag=[6e-006,  6e-006,  1e-008], $
                          warp = [  0.0, 0.00], $
                          center=[471.995, 298.007], $
                          ordwin=[0.0,1.0], $
                          phisq = 1.0, $
                          zerph = 0.354925, $
                          R=0.85, $
                          time = las_time, $
                          exp_time = exp_time, $
                          elevation = elevation, $
                          azimuth = azimuth, $
                          tube = tube, $
                          xcpsave='NO'

   if noplot eq 1 then php.fplot = 0 else php.fplot = 1

   php.xcstp = .1*php.xcen & php.ycstp = .1*php.ycen
   php.zerstp = 0.01 & php.xmstp = 0 & php.ymstp = 0 & php.xymstp = 0
   php.xwstp = 0 & php.ywstp = 0 & php.phistp = 0

   frng_fit, ll, php, culz, draw, skip_rough = skip_rough
   wait, .1

   php.minord = 0 & php.delord = 1
   php.zerstp = 0 & php.xcstp = .1*php.xcen
   php.ycstp = .1*php.ycen & php.xmstp = 1e-6 & php.ymstp = 1e-6
   php.xymstp = 2e-8 & php.xwstp = 0.1 & php.ywstp = 0.1 & php.phistp = 0

   frng_fit, ll, php, culz, draw, skip_rough = skip_rough
   wait, .1

   ;\\ Save the php generated so far as base_params to be saved in save_name lasers.dat file
   base_params = php

   php.minord = 0    & php.delord = 3
   php.zerstp = 0.01 & php.xcstp =  0
   php.ycstp =  0    & php.xmstp =  0 & php.ymstp = 0
   php.xymstp = 0    & php.xwstp =  0 & php.ywstp = 0 & php.phistp = 0.1

   frng_fit, ll, php, culz, draw, skip_rough = skip_rough
   wait, .1


   ;\\ Scan the laser spectrum
   frng_spx, ll, ll, php, npts, [0.0, 3.0], 0.9, culz, las_spec, draw, zerph=php.zerph ; Raised finesse to 0.975 from 0.97

   fitpars   = [0., 0., 0., 0., 150.]
   fix_mask  = [0, 1, 0, 0, 0]

   ;\\ Make an Airy function to use as an "instrument function":
   x       = (findgen(npts) - npts/2.)*!pi/npts
   fringes = sin(x)
   fringes = 1./(1 + ( (4*php.R) / ((1. - php.r)^2) )*fringes*fringes)
   fringes = fringes - min(fringes)
   las_ip  = fringes/max(fringes)

   ;\\ Now fit an emission spectrum to the laser spectrum, using the instrument profile obtained from the laser fringes:
   spek_fit, las_spec, las_ip, species, cal, fix_mask, diagz, fitpars, sigpars, quality, /passive, max_warps=5, max_iters=2390, chisq_tolerance=0.001
   wait, .1


   ;\\ Make the initial arrays that will live in the save_name lasers.dat file
   thelas_specs    = dblarr(1,npts)
   fittedlas_specs = dblarr(1,npts)
   las_pkpos       = dblarr(1)
   las_pkposerr    = dblarr(1)
   las_temp        = dblarr(1)


   ;\\ Store the params in the arrays
   las_params           = replicate(php,1)
   las_params(0).time   = las_time
   las_params(0).exp_time = exp_time
   las_pkpos(0)         = double(fitpars(3))
   las_pkposerr(0)      = double(sigpars(3))
   las_temp(0)          = double(fitpars(4))
   thelas_specs(0,*)    = las_spec(*)
   fittedlas_specs(0,*) = quality.fitfunc(*)


   lasers_done = lasers_done + 1


   save, filename = save_name, base_params, lasers_done, las_params, las_pkpos, las_pkposerr, $
   							   las_temp, thelas_specs, fittedlas_specs


 endif else begin         	;\\ not the first laser, so restore base params and fit zerph and phisq only :)


  restore, save_name

   php = base_params
   php.time = las_time
   php.exp_time = exp_time
   php.elevation = elevation
   php.azimuth = azimuth
   php.tube = tube

   if noplot eq 1 then php.fplot = 0 else php.fplot = 1

   php.minord = 0    & php.delord = 3
   php.zerstp = 0.01 & php.xcstp =  0
   php.ycstp =  0    & php.xmstp =  0 & php.ymstp = 0
   php.xymstp = 0    & php.xwstp =  0 & php.ywstp = 0 & php.phistp = 0.1

   frng_fit, ll, php, culz, draw, skip_rough = skip_rough
   wait, .1

   ;\\ Scan the laser spectrum
   frng_spx, ll, ll, php, npts, [0.0, 3.0], 0.9, culz, las_spec, draw, zerph=las_params(0).zerph ; Raised finesse to 0.975 from 0.97

   fitpars   = [0., 0., 0., 0., 150.]
   fix_mask  = [0, 1, 0, 0, 0]

   ;\\ Make an Airy function to use as an "instrument function":
   x       = (findgen(npts) - npts/2.)*!pi/npts
   fringes = sin(x)
   fringes = 1./(1 + ( (4*php.R) / ((1. - php.r)^2) )*fringes*fringes)
   fringes = fringes - min(fringes)
   las_ip  = fringes/max(fringes)

   ;\\ Now fit an emission spectrum to the laser spectrum, using the instrument profile obtained from the laser fringes:
   spek_fit, las_spec, las_ip, species, cal, fix_mask, diagz, fitpars, sigpars, quality, /passive, max_warps=5, max_iters=2390, chisq_tolerance=0.001
   wait, .1


   ;\\ Add entries to the save arrays
   temparr = replicate(php, lasers_done+1)
   temparr(0:lasers_done-1) = las_params
   temparr(lasers_done) = php

   las_params = temparr

   temparr = dblarr(n_elements(thelas_specs(*,0))+1,npts)
   temparr(0:lasers_done-1,*) = thelas_specs
   temparr(lasers_done,*) = las_spec(*)

   thelas_specs = temparr

   temparr = dblarr(n_elements(fittedlas_specs(*,0))+1,npts)
   temparr(0:lasers_done-1,*) = fittedlas_specs
   temparr(lasers_done,*) = quality.fitfunc(*)

   fittedlas_specs = temparr

   temparr = dblarr(n_elements(las_pkpos)+1)
   temparr(0:lasers_done-1) = las_pkpos
   temparr(lasers_done) = double(fitpars(3))

   las_pkpos = temparr

   temparr = dblarr(n_elements(las_pkposerr)+1)
   temparr(0:lasers_done-1) = las_pkposerr
   temparr(lasers_done) = double(sigpars(3))

   las_pkposerr = temparr

   temparr = dblarr(n_elements(las_temp)+1)
   temparr(0:lasers_done-1) = las_temp
   temparr(lasers_done) = double(fitpars(4))

   las_temp = temparr

   lasers_done = lasers_done + 1

   save, filename = save_name, base_params, lasers_done, las_params, las_pkpos, las_pkposerr, $
   							   las_temp, thelas_specs, fittedlas_specs

endelse


END_ANALYSE_LASER:

end


