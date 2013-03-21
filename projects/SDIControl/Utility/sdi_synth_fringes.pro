;\\ Code formatted by DocGen


;\D\<Function/method/pro documentation here>
pro sdi_synth_frnginit, php, $               ;\A\<Arg0>
                        nx, $                ;\A\<Arg1>
                        ny, $                ;\A\<Arg2>
                        center=center, $     ;\A\<Arg3>
                        censtep=censtep, $   ;\A\<Arg4>
                        mag=mag, $           ;\A\<Arg5>
                        mgstep=magstep, $    ;\A\<Arg6>
                        warp=warp, $         ;\A\<Arg7>
                        wpstep=wpstep, $     ;\A\<Arg8>
                        phisq=phisq, $       ;\A\<Arg9>
                        pstep=phistep, $     ;\A\<Arg10>
                        zerph=zerph, $       ;\A\<Arg11>
                        zrstep=zerstep, $    ;\A\<Arg12>
                        ordwin=ordwin, $     ;\A\<Arg13>
                        R=R, $               ;\A\<Arg14>
                        lambda=lambda, $     ;\A\<Arg15>
                        xcpsave=xcpsave      ;\A\<Arg16>


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
	if not(keyword_set(lambda))   then lambda   = 632.8
	if not(keyword_set(R))        then R        = 0.7
	if not(keyword_set(xcpsave))  then xcpsave  = 'NO'



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
	                lambda:   lambda,        $
	                R:        R}
	   php.xsize = nx
	   php.ysize = ny
 end

;\D\<Function/method/pro documentation here>
pro sdi_synth_fringemap, fringes, $      ;\A\<Arg0>
                         pmap, $         ;\A\<Arg1>
                         php, $          ;\A\<Arg2>
                         field_stop      ;\A\<Arg3>

	circles = 1

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

    if circles then begin
       pmap = php.xymag*xx*xx + php.xymag*yy*yy
    endif else begin
       xx   = xx + php.xwarp*abs(xx)
       yy   = yy + php.ywarp*abs(yy)
       pmap = php.xmag*xx*xx + php.ymag*yy*yy + php.xymag*xx*yy
       pmap = (pmap + php.phisq*pmap*pmap)
    endelse

    if php.lambda ne 630.03 then pmap = pmap*(630.03/php.lambda)

;   Create a mask describing all points within the desired number of orders of the axis:
    field_stop = where(pmap lt maxord and pmap gt php.minord, nout)

    pmap    = (php.zerph - pmap)*!pi
    fringes = sin(pmap)
    fringes = 1./(1 + (4*php.R/(1. - php.r)^2)*fringes*fringes)
    fringes = fringes - min(fringes)
    if max(fringes) ne 0 then fringes = fringes / max(fringes)
end
