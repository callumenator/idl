
function phasemap_unwrap, xcen, ycen, radial_chunk, channels, threshold, wavelength, phasemap, show=show, tv_id=tv_id, dims=dims

    phase_cpy = phasemap

    ;\\ Show the initial phasemap
       if keyword_set(show) then begin
         wset, tv_id
         loadct, 0, /silent
         tvscl, congrid(phase_cpy, dims[0], dims[1])
       endif

    ;\\ Start a progress bar
       progressBar = Obj_New("SHOWPROGRESS", message = 'Unwrapping phasemap...')
       progressBar->Start

    ;\\ Get array dimensions
       nx = n_elements(phase_cpy(*,0))
       ny = n_elements(phase_cpy(0,*))

    ;\\ Generate an array filled with values of distance from nominal center
        xx  = transpose(lindgen(ny,nx)/ny) ;    - xcen
        yy  = lindgen(nx,ny)/nx          ;  - ycen
       dst = (xx - xcen)*(xx - xcen) + (yy - ycen)*(yy - ycen)

    ;\\ Indices of previous array sorted in order of lowest to highest distance from center
        dord = sort(dst)

;-------First, we just unwrap 10% of the phase map area near the center. This will help us find the center based on the actual data:
        for j=1l, n_elements(dord)/10. do begin

         ;\\ Lower index for the radial chunk - upper is 'j'
               jlo = ((j - radial_chunk) > (0))

         ;\\ Average phase in the radial chunk
               phase_here = total(phase_cpy(dord(jlo:j)))/(j-jlo)

         ;\\ Keep adding 'channels' until phase at point is not different from average phase
         ;\\ in the radial chunk by more than 'threshold'
             if phase_here - phase_cpy(dord(j)) gt threshold then phase_cpy(dord(j)) = phase_cpy(dord(j)) + channels*fix((phase_here - phase_cpy(dord(j)))/channels)
             while phase_here - phase_cpy(dord(j)) gt threshold do phase_cpy(dord(j)) = phase_cpy(dord(j)) + channels
         endfor

         phase_cpy = median(phase_cpy, 5)
         cenidx = where(phase_cpy(dord(0:n_elements(dord)/10.)) eq min(phase_cpy(dord(0:n_elements(dord)/10.))))
         cenidx = dord(cenidx)
         xcen   = median(xx(cenidx))
         ycen   = median(yy(cenidx))

;---Now go for the full unwrap, using our data-based estimate of the center location:
    phase_cpy = phasemap
    dst = (xx - xcen)*(xx - xcen) + (yy - ycen)*(yy - ycen)
    ;\\ Indices of previous array sorted in order of lowest to highest distance from center
        dord = sort(dst)


    ;\\ Unwrap the phase_cpy
        dcnt = 0

        for j=1l, n_elements(dord)-1 do begin

         ;\\ Lower index for the radial chunk - upper is 'j'
               jlo = ((j - radial_chunk) > (0))

         ;\\ Average phase in the radial chunk
               phase_here = total(phase_cpy(dord(jlo:j)))/(j-jlo)

         ;\\ Keep adding 'channels' until phase at point is not different from average phase
         ;\\ in the radial chunk by more than 'threshold'
             if phase_here - phase_cpy(dord(j)) gt threshold then phase_cpy(dord(j)) = phase_cpy(dord(j)) + channels*fix((phase_here - phase_cpy(dord(j)))/channels)
             while phase_here - phase_cpy(dord(j)) gt threshold do phase_cpy(dord(j)) = phase_cpy(dord(j)) + channels

         ;\\ Insert some short waits, to allow the program to be cancelled:
               dcnt = dcnt + 1
               if dcnt gt 500 then begin
                   dcnt = 0
                   wait, 0.05
                   progressBar -> update, (float(j)/float(n_elements(dord)))*100.
              ;\\ If show = 1, update the display
                 if keyword_set(show) then begin
                   tvscl, congrid(phase_cpy, dims[0], dims[1])
                   ;wset, 11
                   ;erase, 0
                   ;tvscl, congrid(phase_cpy,256,256), 128, 0
                   ;pic = tvrd(/true)
                   ;write_jpeg, 'C:\Documents and Settings\Administrator\Desktop\object\MawsonCode\ScreenCaps\unwrap'+ $
                           ;string(j,f='(i6.6)')+'.jpg', pic, quality = 100, /true
                 endif
               endif

        endfor
;---Now a final pass to try to catch any artifacts still remaining:
    seq = dord(0:0.6*n_elements(dst))
    cfs = linfit(dst(seq), phase_cpy(seq))
    pred = cfs(0) + cfs(1)*dst
    nb = 0
    bads = where(pred - median(phase_cpy, 7) gt channels/4, nb)
    if nb gt 1 then phase_cpy(bads) = phase_cpy(bads) + channels*long((pred(bads) - phase_cpy(bads))/channels)

    ;\\ Make the phasemap general
       ;final = phase_cpy * float(wavelength)    \\\\ 9/2/07 Phasemap interpolation
       final = phase_cpy

       progressBar -> destroy

    ;\\ Return the unwrapped phasemap
       return, final

end
