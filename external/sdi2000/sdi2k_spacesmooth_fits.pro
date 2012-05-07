pro sdi2k_map_zoneseps, sepmap
@sdi2kinc.pro
       nz = fix(total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1)))
       sepmap = fltarr(nz, nz)
       for i=0,nz-1 do begin
           xsep = (zone_centers(*, 0) - zone_centers(i, 0))
           ysep = (zone_centers(*, 1) - zone_centers(i, 1))
           sepmap(*, i) = float(sqrt(xsep^2 + ysep^2))
       endfor
       end

pro sdi2k_spacesmooth_fits, wot, spacewin, progress=progress
@sdi2kinc.pro

       if keyword_set(progress) then begin
          progressBar = Obj_New("SHOWPROGRESS", message='Percent Completion', title='Spatial Smoothing...')
          progressBar->Start
       endif
       ncrecord = n_elements(wot(0,*))
       if ncrecord lt 2 then return
       
       nz = fix(total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1)))
       if spacewin lt 0.01 then return
       sdi2k_map_zoneseps, sepmap
       weight = fltarr(nz)
       for zidx = 0,nz-1 do begin
           weight = (sepmap(*,zidx)/spacewin)^2
           weight = weight < 30
           weight = exp(-weight)
           for rcd=0,ncrecord-2 do begin
               goods = where_reasonable(wot(*, rcd), 4)
               if goods(0) ne -1 then begin
                  wot(zidx,rcd) =  total(wot(goods, rcd)*weight(goods)) /$
                                   total(weight(goods))
               endif
           endfor
           if keyword_set(progress) then progressbar->update, 100*zidx/float(nz)
	   wait, 0.001
       endfor
       if keyword_set(progress) then begin
          progressBar->Destroy
          Obj_Destroy, progressBar
       endif
       end