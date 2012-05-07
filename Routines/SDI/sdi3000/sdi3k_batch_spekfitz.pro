; Example call: sdi3k_batch_spekfitz, 'd:\users\sdi2000\data\sky2001282.pf', 'd:\users\sdi2000\data\ins2001282.pf'

pro sdi3k_batch_spekfitz, skyfile, insfile, skip_existing=skip_existing, skip_insfit=skip_insfit, choose=choose

sdi3k_read_netcdf_data, skyfile, metadata=mmsky, zonemap=zonemap, zone_centers=zone_centers, zone_edges=zone_edges, spex=spex
if mmsky.start_time eq mmsky.end_time then return

ncid = sdi3k_nc_get_ncid(skyfile, write_allowed=1)

jlo = 0
jhi = mmsky.maxrec-1

if keyword_set(choose) then begin
   timelis = dt_tm_mk(js2jd(0d)+1, (spex.start_time + spex.end_time)/2, format='h$:m$:s$')
   mcchoice, 'Start Time: ', timelis, choice, $
              heading = {text: 'Start Plot at What Time?', font: 'Helvetica*Bold*Proof*30'}
   jlo = choice.index
   mcchoice, 'End Time: ', timelis, choice, $
              heading = {text: 'End Plot at What Time?', font: 'Helvetica*Bold*Proof*30'}
   jhi = choice.index
endif

    sdi3k_load_insprofs, insfile,     insprofs, norm=inorm
    ncid = sdi3k_nc_get_ncid(insfile, write_allowed=1)
    sdi3k_add_spekfitvars, ncid
    if keyword_set(skip_insfit) then goto, NO_IPR

    sdi3k_read_netcdf_data, insfile, metadata=mmins, spex=inspex, spekfits=insfits
    sdi3k_zenav_peakpos, inspex, mmins, cpos, widths=widths
    ncid = sdi3k_nc_get_ncid(insfile, write_allowed=1)
    for rec=0,mmins.maxrec-1 do begin
        ssec = inspex(rec).start_time
        esec = inspex(rec).end_time
        print, 'Insprof exposure ', rec, ' of ', mmins.maxrec, ' Times: ', $
               dt_tm_mk(js2jd(0d)+1, ssec, format='d$-n$-Y$ h$:m$-'), $
               dt_tm_mk(js2jd(0d)+1, esec, format='h$:m$')
        badz = where(~(finite(insfits(rec).chi_squared)), nf)
        fit_this = (nf ne 0) or (max(insfits(rec).chi_squared) eq min(insfits(rec).chi_squared)) or min(insfits(rec).chi_squared) gt 1000.
        if (fit_this) then begin
           sdi3k_level1_fit, rec, (ssec + esec)/2, inspex(rec).spectra, mmins, sig2noise, chi_squared, $
                          sigarea, sigwid, sigpos, sigbgnd, $
                          backgrounds, areas, widths, positions, insprofs, /no_temperature, min_iters=15, shiftpos = mmins.scan_channels/2 - cpos
           sdi3k_write_spekfitpars, ncid, rec, sig2noise, chi_squared, $
                           sigarea, sigwid, sigpos, sigbgnd, $
                           backgrounds, areas, widths, positions
        endif
    endfor
    sdi3k_ncdf_close, ncid
NO_IPR:

;---Fit the sky profiles:
    ncid = sdi3k_nc_get_ncid(skyfile, write_allowed=1)
    sdi3k_add_spekfitvars, ncid
    sdi3k_read_netcdf_data, skyfile, metadata=mmsky, spex=skyspex, spekfits=skyfits
    sdi3k_zenav_peakpos, skyspex, mmsky, cpos, widths=widths
    ncid = sdi3k_nc_get_ncid(skyfile, write_allowed=1)
    itmp = 700.
    for rec=jlo,jhi do begin
        ssec = skyspex(rec).start_time
        esec = skyspex(rec).end_time
        print, 'Sky exposure ', rec, ' of ', mmsky.maxrec, ' Times: ', $
               dt_tm_mk(js2jd(0d)+1, ssec, format='d$-n$-Y$ h$:m$-'), $
               dt_tm_mk(js2jd(0d)+1, esec, format='h$:m$')
        badz = where(~(finite(skyfits(rec).chi_squared)), nf)
        fit_this = ~(keyword_set(skip_existing)) or (nf ne 0) or (max(skyfits(rec).chi_squared) eq min(skyfits(rec).chi_squared))
        if (fit_this) then begin
           sdi3k_level1_fit, rec, (ssec + esec)/2, skyspex(rec).spectra, mmsky, sig2noise, chi_squared, $
                          sigarea, sigwid, sigpos, sigbgnd, $
                          backgrounds, areas, widths, positions, insprofs, initial_temp=itmp, min_iters=15, shiftpos = mmsky.scan_channels/2 - cpos
           sdi3k_write_spekfitpars, ncid, rec, sig2noise, chi_squared, $
                                           sigarea, sigwid, sigpos, sigbgnd, $
                                           backgrounds, areas, widths, positions
           itmp = median(widths)
        endif
    endfor
    sdi3k_ncdf_close, ncid
end


