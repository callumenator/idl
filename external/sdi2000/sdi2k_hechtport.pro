pro sdi2k_hechtport
common tsplot_resarr, resarr
tcen   = (resarr.start_time + resarr.end_time)/2
tstamp = dt_tm_mak(js2jd(0d)+1, tcen, format='h$:m$:s$   ')

fname  = 'e:\users\sdi2000\hecht\hecht_sdi_' + $
          dt_tm_mak(js2jd(0d)+1, tcen(0), format='Y$-N$-0d$.txt')

nz = n_elements(resarr(0).temperature)
openw, hectun, fname, /get_lun, width=200
printf, hectun, 'HH:MM:SS         Zen Temp     +/-          Median Temp  +/-          Zen Velocity +/-          Zen Inten   +/-'
for j=0,n_elements(tcen)-1 do begin
    printf, hectun, tstamp(j), $
                    resarr(j).temperature(0), $
                    resarr(j).sigma_temperature(0), $
                    median(resarr(j).temperature), $
                    2.*stddev(resarr(j).temperature)/sqrt(nz), $
                    resarr(j).velocity(0), $
                    resarr(j).sigma_velocity(0), $
                    resarr(j).intensity(0), $
                    resarr(j).sigma_intensities(0)
endfor
close, hectun
free_lun, hectun
end