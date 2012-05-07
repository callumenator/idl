pro sdi2k_timesmooth_fits,  wot, timewin, progress=progress
@sdi2kinc.pro
       if keyword_set(progress) then begin
          progressBar = Obj_New("SHOWPROGRESS", message='Percent Completion', title='Time Smoothing...')
          progressBar->Start
       endif
       nz = fix(total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1)))
       if timewin lt 0.1 then return
       ncrecord = n_elements(wot(0,*))
       for rcd=0,ncrecord-2 do begin
           weight = findgen(ncrecord) - rcd
           weight = (weight/timewin)^2
           weight = weight < 30
           weight = exp(-weight)
           for zidx=0,nz-1 do begin
               goods = where_reasonable(wot(zidx,*), 4)
               if goods(0) ne -1 then begin
                  wot(zidx,rcd) =  total(wot(zidx,goods)*weight(goods)) /$
                                   total(weight(goods))
               endif
           end
           if keyword_set(progress) then progressbar->update, 100*rcd/float(ncrecord-2)
           wait, 0.001
       endfor
       if keyword_set(progress) then begin
          progressBar->Destroy
          Obj_Destroy, progressBar
       endif
       end
