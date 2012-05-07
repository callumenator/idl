pro sdi3k_timesmooth_fits,  wot, timewin, mm, progress=progress
       if keyword_set(progress) then begin
          progressBar = Obj_New("SHOWPROGRESS", message='Percent Completion', title='Time Smoothing...')
          progressBar->Start
       endif
       nz = mm.nzones
       if timewin lt 0.1 then return
       ncrecord = n_elements(wot(0,*))
       for zidx=0,nz-1 do begin
           goods = where_reasonable(wot(zidx,*), 4)
           if goods(0) ne -1 then begin
              for rcd=0,ncrecord-1 do begin
                  weight = exp(-(((findgen(ncrecord) - rcd)/timewin)^2 < 30))
                  wot(zidx,rcd) =  total(wot(zidx,goods)*weight(goods)) /$
                                   total(weight(goods))
              endfor
           endif
           if keyword_set(progress) then progressbar->update, 100*rcd/float(ncrecord-2)
           wait, 0.00001
       endfor
       if keyword_set(progress) then begin
          progressBar->Destroy
          Obj_Destroy, progressBar
       endif
       end
