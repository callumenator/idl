pro sdi3k_map_zoneseps, sepmap, zone_centers
       nz = n_elements(zone_centers(*,0))
       sepmap = fltarr(nz, nz)
       for i=0,nz-1 do begin
           xsep = (zone_centers(*, 0) - zone_centers(i, 0))
           ysep = (zone_centers(*, 1) - zone_centers(i, 1))
           sepmap(i, *) = float(sqrt(xsep^2 + ysep^2))
       endfor
       end

pro sdi3k_spacesmooth_fits, wot, spacewin, mm, zone_centers, progress=progress

       if keyword_set(progress) then begin
          progressBar = Obj_New("SHOWPROGRESS", message='Percent Completion', title='Spatial Smoothing...')
          progressBar->Start
       endif
       ncrecord = n_elements(wot(0,*))
       ;if ncrecord lt 2 then return

       nz = mm.nzones
       if spacewin lt 0.01 then return
       sdi3k_map_zoneseps, sepmap, zone_centers
       weight = fltarr(nz)
       for rcd=0,ncrecord-1 do begin
           goods = where_reasonable(wot(*, rcd), 4)
           if goods(0) ne -1 then begin
              for zidx = 0,nz-1 do begin
                  weight = (sepmap(*,zidx)/spacewin)^2
                  weight = weight < 30
                  weight = exp(-weight)
                  wot(zidx,rcd) =  total(wot(goods, rcd)*weight(goods)) /$
                                   total(weight(goods))
              endfor
           endif
           if keyword_set(progress) then progressbar->update, 100*zidx/float(nz)
       wait, 0.00001
       endfor
       if keyword_set(progress) then begin
          progressBar->Destroy
          Obj_Destroy, progressBar
       endif
       end