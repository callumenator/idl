
function time_smooth, dataIN, show_progress = show_progress, timewin = timewin

       if keyword_set(show_progress) then begin
          progressBar = Obj_New("SHOWPROGRESS", message='Percent Completion', title='Time Smoothing...')
          progressBar->Start
       endif

	   data = dataIN
       nz = n_elements(data(*,0))
       if timewin lt 0.1 then return, 0

       ncrecord = n_elements(data(0,*))

       for zidx=0,nz-1 do begin
           goods = where_reasonable(data(zidx,*), 4)
           if goods(0) ne -1 then begin
              for rcd=0,ncrecord-1 do begin
                  weight = exp(-(((findgen(ncrecord) - rcd)/timewin)^2 < 30))
                  data(zidx,rcd) =  total(data(zidx,goods)*weight(goods)) /$
                                   total(weight(goods))
              endfor
           endif
           if keyword_set(show_progress) then progressbar->update, 100*rcd/float(ncrecord-2)
           wait, 0.00001
       endfor

       if keyword_set(show_progress) then begin
          progressBar->Destroy
          Obj_Destroy, progressBar
       endif

	return, data

end