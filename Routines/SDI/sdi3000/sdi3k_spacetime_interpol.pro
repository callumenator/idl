pro sdi3k_spacetime_interpol, obs_coords, out_coords, obsarr, outarr, settings, weighting=weighting, progress=progress

    if keyword_set(progress) then begin
       progressBar = Obj_New("SHOWPROGRESS", message='Percent Completion', title='Interpolating...')
       progressBar->Start
    endif


    deg2km = 111.12
    outarr = replicate(obsarr(0), n_elements(out_coords))
    for j=0L,n_elements(outarr)-1 do begin
        dx    = (obs_coords.lons - out_coords(j).lons)*deg2km*cos(!dtor*out_coords(j).lats)
        dy    = (obs_coords.lats - out_coords(j).lats)*deg2km
        dt    = (obs_coords.js   - out_coords(j).js)*settings.charspeed_kmps
        distz = sqrt(dx^2 + dy^2 + dt^2)
        dsrt  = sort(distz)

        mindist = distz(dsrt(0))
        use = dsrt(0:5)
        more = where(distz(dsrt(6:*)) le 5.*mindist, nm)
        if nm gt 0 then use = [use, dsrt(more + 6)]
        distz = distz(use)
        disthere = settings.dist_par_km > 1.2*mindist

        if keyword_set(weighting) then begin
           if strupcase(weighting) eq '1/D' then weights =1/(distz + disthere)
        endif else weights = exp(-(distz/disthere)^2)

        twgt = total(weights)
        if n_tags(outarr(0)) gt 0 then $
           for k=0,n_tags(outarr(0)) - 1 do outarr(j).(k) = total(obsarr(use).(k)*weights)/twgt $
        else $
           outarr(j) = total(obsarr(use)*weights)/twgt
        if keyword_set(progress) then progressbar->update, 100.*j/float(n_elements(outarr)-1)
        wait, 0.00005
    endfor
    if keyword_set(progress) then begin
       progressBar->Destroy
       Obj_Destroy, progressBar
    endif

end