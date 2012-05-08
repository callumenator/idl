
function space_smooth, pkpos, rads, secs, show_progress = show_progress, spacewin = spacewin

	if not keyword_set(spacewin) then spacewin = 2

	smoothed_pkpos = pkpos

	;nums = secs
	;nums(0) = 0
	;for n = 1, n_elements(secs) - 1 do nums(n) = total(secs(0:n-1))

	zmap = zonemapper(512,512,[256,256],rads,secs,nums)
	zone_centers = get_zone_centers(zmap)

	nzones = n_elements(pkpos(*,0))
	nexps = n_elements(pkpos(0,*))

	if keyword_set(show_progress) then begin
          progressBar = Obj_New("SHOWPROGRESS", message='Percent Completion', title='Spatial Smoothing...')
          progressBar->Start
    endif


	;\\ Compute a 'separation map' between the centers of each zone
		sepmap = fltarr(nzones, nzones)
		for z = 0, nzones - 1 do begin
			dx = float(zone_centers(z,0) - zone_centers(*,0))
			dy = float(zone_centers(z,1) - zone_centers(*,1))
			sepmap(z,*) = sqrt(dx^2 + dy^2)
		endfor

		weight = fltarr(nzones)
		;spacewin = 100

       	for zidx = 0, nzones - 1 do begin

           	weight = (sepmap(zidx,*)/spacewin)^2
           	weight = weight < 30
           	weight = exp(-weight)

           	for tidx = 0, nexps - 1 do begin
               	goods = where_reasonable(pkpos(*, tidx), 4)
               	if goods(0) ne -1 then begin
                  	smoothed_pkpos(zidx, tidx) = total(pkpos(goods, tidx)*weight(goods)) / $
                                   				 total(weight(goods))
               	endif
           	endfor
			    if keyword_set(show_progress) then progressbar->update, 100*zidx/float(nzones)
	   		wait, 0.001
       	endfor

	if keyword_set(show_progress) then begin
          progressBar->Destroy
          Obj_Destroy, progressBar
    endif

	return, smoothed_pkpos

end