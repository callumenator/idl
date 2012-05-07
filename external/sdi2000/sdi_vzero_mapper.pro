;==================================================================
; This is a batch-mode program to generate a zero-velocity map
; of the detector zones. In the Poker instrument for times when
; phase maps were shifted through a large wavelength change 
; (e.g. 632.8 nm --> 557.7 nm) chromatic aberration differences
; between the two wavelengths could not be accounted for. The 
; result is that a "flat-field" zero-velocity actual sky scene 
; does not return a flat zero velocity field when observed. By
; averaging exposures from one or more cloudy days, we can estimate
; this departure from flat-field, and correct for it. The resulting 
; flat-field map is saved as an IDL save file, for subsequent
; use by the wind-fitting program.
;
; Mark Conde, Fairbanks, February 2004.



@sdi2kprx.pro
@sdi2k_ncdf.pro

pro vzero_get_filez, filez
    repeat begin
        fname = dialog_pickfile(path='%SDI_DATA_DIR%', filter='sky*.pf', title='Select a zero-velocity obs file, or cancel to continue')
        if fname ne '' then begin
           if n_elements(filez) eq 0 then filez = fname else filez = [filez, fname]
        endif
    endrep until fname eq ''
end

pro vzero_load_fits, filez, fitz, doys_used
@sdi2kinc.pro


;---Initialize various data:
    load_pal, culz, proportion=0.5
    sdi2k_data_init, culz
    view = transpose(view)
;    sdi2k_build_zone_map
    doys_used = strarr(n_elements(filez))


    for j=0, n_elements(filez) - 1 do begin
;-------Open the sky file:
        sdi2k_ncopen, filez(j), ncid, 0
        ncdf_diminq, ncid, ncdf_dimid(ncid, 'Time'),    dummy,  maxrec
        sdi2k_read_exposure, host.netcdf(0).ncid, 0
        ctime = host.programs.spectra.start_time + host.programs.spectra.integration_seconds/2
        doys_used(j) = dt_tm_mk(js2jd(0d)+1, ctime, format='Y$, DOYdoy$')

;-------Get the peak fitting results and condition them as needed:
        if n_elements(resarr) gt 0 then undefine, resarr
        sdi2k_build_fitres, ncid, resarr
        sdi2k_drift_correct, resarr, source_file=filez(j), /force, /data
        if j eq 0 then fitz = resarr else fitz = [fitz, resarr]

;-------Close the skyfile:
        ncdf_close, host.netcdf(0).ncid
        host.netcdf(0).ncid = -1
    endfor
end

pro vzero_build_vzero, fitz, vzero
    vzero = fltarr(n_elements(fitz(0).velocity))
    loav  = 0.1*n_elements(fitz)
    hiav  = 0.9*n_elements(fitz)
    for j=0,n_elements(vzero)-1 do begin
        posis = fitz.velocity(j)
        posis = posis(sort(posis))
        avpos = total(posis(loav:hiav))/(1+hiav-loav)
        vzero(j) = avpos
    endfor
    vzero = vzero - total(vzero)/n_elements(vzero)
end

pro vzero_save_vzero, vzero, doys_used
    fname = dialog_pickfile(path='%SDI_DATA_DIR%', file='sdi_vzero_file.sav', title='Save file name for the zero velocity map?')
    save, vzero, doys_used, file=fname
    setenv, 'SDI_ZERO_VELOCITY_FILE='+fname      
end

;-------------------------------------------------------------------
;   This is the main program:

    vzero_get_filez, filez
    vzero_load_fits, filez, fitz, doys_used
    vzero_build_vzero, fitz, vzero
    vzero_save_vzero, vzero, doys_used
    print, 'DOYS USED: ', doys_used
    print, 'VZERO DATA:', vzero
end