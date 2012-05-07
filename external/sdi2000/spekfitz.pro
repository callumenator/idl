; A program to fit emission parameters to line spectra recorded by the
; Poker Flat SDI system.
; Mark Conde, Fairbanks, January 1995.

pro sdi_data_init
@sdi_inc.pro
       ipd_pixels = 256
       satval  = 255
       rbwmin  = 1
       rbwmax  = 75
       dopmin  = 76
       dopmax  = 150
       greymin = 151
       greymax = 225
       sectors = intarr(8)
       positions   = fltarr(200)
       areas       = fltarr(200)
       widths      = fltarr(200)
       sigpos      = fltarr(200)
       sigarea     = fltarr(200)
       sigwid      = fltarr(200)
       backgrounds = fltarr(200)
       sig2noise   = fltarr(200)
       chi_squared = fltarr(200)
       zone_map = intarr(ipd_pixels, ipd_pixels)
       frame    = 0
       xpix     = 600
       ypix     = 760
       avpos    = 999
       nc_nodata = -1
       end

;  This procedure opens a netCDF file from which which spectra (either
;  sky spectra or instrument profiles) will be read:

pro sdi_ncopen, file
@sdi_inc.pro

       ncdims    = intarr(4)
       ncvars    = intarr(64) - 1
       ncrecord  = 0
       ncid = ncdf_open (file, /write)
       ncdims(0) = ncdf_dimid (ncid, 'Time')
       ncdims(1) = ncdf_dimid (ncid, 'Zone')
       ncdims(2) = ncdf_dimid (ncid, 'Channel')
       ncdims(3) = ncdf_dimid (ncid, 'Ring')

       ncvars(0) = ncdf_varid (ncid, 'Start_Time')
       ncvars(1) = ncdf_varid (ncid, 'End_Time')
       ncvars(2) = ncdf_varid (ncid, 'Spectra')
       ncvars(3) = ncdf_varid (ncid, 'Number_Summed')
       ncvars(4) = ncdf_varid (ncid, 'Ring_Radius')
       ncvars(5) = ncdf_varid (ncid, 'Sectors')
       ncvars(6) = ncdf_varid (ncid, 'Plate_Spacing')
       ncvars(7) = ncdf_varid (ncid, 'Start_Spacing')
       ncvars(8) = ncdf_varid (ncid, 'Channel_Spacing')
       ncvars(9) = ncdf_varid (ncid, 'Scan_Channels')
       ncvars(10)= ncdf_varid (ncid, 'Gap_Refractive_Index')
       ncvars(11)= ncdf_varid (ncid, 'Sky_Wavelength')
       ncvars(12)= ncdf_varid (ncid, 'Cal_Wavelength')
       ncvars(13)= ncdf_varid (ncid, 'Cal_Temperature')
       ncvars(14)= ncdf_varid (ncid, 'Sky_Mass')
       ncvars(15)= ncdf_varid (ncid, 'Cal_Mass')
       ncvars(16)= ncdf_varid (ncid, 'Sky_Ref_Finesse')
       ncvars(17)= ncdf_varid (ncid, 'Cal_Ref_Finesse')
       ncvars(18)= ncdf_varid (ncid, 'Sky_FOV')

; Read supporting data:
       ncdf_diminq, ncid, ncdims(0),  dummy,   ncmaxrec
       ncdf_diminq, ncid, ncdims(1),  dummy,   ncnzones
       ncdf_diminq, ncid, ncdims(2),  dummy,   ncnchan
       ncdf_diminq, ncid, ncdims(3),  dummy,   ncnrings

;       ncdf_varget, ncid, ncvars(0),  ncstime, offset=(0),          count=(1)
;       ncdf_varget, ncid, ncvars(1),  ncetime, offset=(ncmaxrec-1), count=(1)
       ncdf_varget, ncid, ncvars(4),  ring_radii, offset=0, count=ncnrings
       ncdf_varget, ncid, ncvars(5),  sectors, offset=0, count=ncnrings
       ncdf_varget, ncid, ncvars(6),  plate_spacing, offset=0, count=1
       ncdf_varget, ncid, ncvars(7),  start_spacing, offset=0, count=1
       ncdf_varget, ncid, ncvars(8),  channel_spacing, offset=0, count=1
       ncdf_varget, ncid, ncvars(9),  scan_channels, offset=0, count=1
       ncdf_varget, ncid, ncvars(10), gap_refractive_Index, offset=0, count=1
       ncdf_varget, ncid, ncvars(11), sky_wavelength, offset=0, count=1
       ncdf_varget, ncid, ncvars(12), cal_wavelength, offset=0, count=1
       ncdf_varget, ncid, ncvars(12), cal_temperature, offset=0, count=1
       ncdf_varget, ncid, ncvars(14), sky_mass, offset=0, count=1
       ncdf_varget, ncid, ncvars(15), cal_mass, offset=0, count=1
       ncdf_varget, ncid, ncvars(16), sky_ref_finesse, offset=0, count=1
       ncdf_varget, ncid, ncvars(17), cal_ref_finesse, offset=0, count=1
       ncdf_varget, ncid, ncvars(18), sky_fov, offset=0, count=1
       ncdf_attget, ncid, 'SiteCode', sitecode,  /GLOBAL
       ncdf_attget, ncid, 'Start Day UT', ncdoy, /GLOBAL
       sectors = [sectors, 1]
       ring_radii = [ring_radii, ipd_pixels]
       newid = where(ncvars lt 0)
       newid = newid(0)
       lastvar = newid
       end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  This procedure checks if a variable is already defined in a netCDF
;  file and, if not, adds it to the file.

pro sdi_addvar, vname, dimids, units, byte=bt, char=ch, short=sh, $
                 long=lg, float=fl, double=db
@sdi_inc.pro
       newid = where(ncvars lt 0)
       newid = newid(0)
       lastvar = newid
       ncdf_control, ncid, /noverbose
       if (ncdf_varid(ncid, vname) ne -1) then begin
           ncvars(newid) = ncdf_varid (ncid, vname)
           return
       endif
       ncdf_control, ncid, /verbose
       ncdf_control, ncid, /redef
       if (keyword_set(bt)) then $
           ncvars(newid)  = ncdf_vardef(ncid, vname, dimids, /byte)
       if (keyword_set(ch)) then $
           ncvars(newid)  = ncdf_vardef(ncid, vname, dimids, /char)
       if (keyword_set(sh)) then $
           ncvars(newid)  = ncdf_vardef(ncid, vname, dimids, /short)
       if (keyword_set(lg)) then $
           ncvars(newid)  = ncdf_vardef(ncid, vname, dimids, /long)
       if (keyword_set(fl)) then $
           ncvars(newid)  = ncdf_vardef(ncid, vname, dimids, /float)
       if (keyword_set(db)) then $
           ncvars(newid)  = ncdf_vardef(ncid, vname, dimids, /double)
       ncdf_attput, ncid, ncvars(newid), 'Units', units
       ncdf_control, ncid, /endef
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  This procedure adds variables to the netCDF logfile to store the
;  results of peak fitting.  It only adds the variables if they do not
;  already exist.
;
pro sdi_add_fit_vars
@sdi_inc.pro
       ncdf_control, ncid, /fill, oldfill=nc_nodata
       sdi_addvar, 'Peak_Position',   [ncdims(1), ncdims(0)], $
                   'Scan Channels',   /float
       sdi_addvar, 'Peak_Width',      [ncdims(1), ncdims(0)], $
                   'Scan Channels',   /float
       sdi_addvar, 'Peak_Area',       [ncdims(1), ncdims(0)], $
                   'PMT Counts',      /float
       sdi_addvar, 'Background',      [ncdims(1), ncdims(0)], $
                   'PMT Counts per Channel',      /float
       sdi_addvar, 'Sigma_Position',  [ncdims(1), ncdims(0)], $
                   'Scan Channels',   /float
       sdi_addvar, 'Sigma_Width',     [ncdims(1), ncdims(0)], $
                   'Scan Channels',   /float
       sdi_addvar, 'Sigma_Area',      [ncdims(1), ncdims(0)], $
                   'PMT Counts',      /float
       sdi_addvar, 'Sigma_Bgnd',      [ncdims(1), ncdims(0)], $
                   'PMT Counts per Channel',      /float
       sdi_addvar, 'Chi_Squared',     [ncdims(1), ncdims(0)], $
                   'Dimensionless',   /float
       sdi_addvar, 'Signal_to_Noise', [ncdims(1), ncdims(0)], $
                   'Dimensionless',   /float
       ncdf_control, ncid, /redef
       ncdf_attput, ncid, 'Peak Fitting Time', systime(), /global
       ncdf_attput, ncid, 'Peak Fitting Routine', $
                          'IDL <sdi_fitz.pro> program', /global
       ncdf_control, ncid, /fill, oldfill=nc_nodata
       ncdf_control, ncid, /endef
end

;  This routine attempts to open a file of name 'fname' to use as a
;  source of instrument profiles.  Note: these are assumed to be stored
;  as SPECTRA, not as fourier transforms.  Since we have an imager we
;  need to obtain one insprof for each zone so the insprof array has
;  dimensions of (channel_number, zone_number).  The insprofs are
;  shifted to roughly channel zero so that fitted positions for sky
;  spectra allowing for convolution of the insprofs will be close to
;  the actual recorded positions.  Currently this is done simply by a
;  fixed 64-channel shift - better to come later maybe.  (The commented
;  out stuff is a relic of such an attempt which failed for some
;  reason).  We also remove any backgrounds, normalise to max amplitudes
;  of one and calculate the power spectrum of the insprofs:

pro sdi_load_insprofs, fname
@sdi_inc.pro
    sdi_ncopen, fname
    sdi_read_exposure
    ncdf_close, ncid
    insprofs = complexarr(scan_channels,ncnzones)
    inspower = fltarr(scan_channels,ncnzones)
    ncn8     = scan_channels/8
    for zidx=0,ncnzones-1 do begin
        insprofs(*,zidx) = fft (spectra(*,zidx), -1)
        nrm              = abs(insprofs(1,zidx)) ;###
        insprofs(*,zidx) = insprofs(*,zidx)/(nrm)
        spectra(*,zidx)  = spectra(*,zidx)/(nrm)
    endfor
    inspower = abs(insprofs*conj(insprofs))
    insprofs = spectra
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  This routine reads the times and spectral data corresponding to one
;  "exposure" of scanning Doppler imager data, which is to say
;  "ncnzones" spectra, each of "scan_channels" channels.  The result is
;  a complex array of dimensions (channel number, zone number):

pro sdi_read_exposure
@sdi_inc.pro
    spectra = intarr (scan_channels, ncnzones)
    ncdf_varget, ncid, ncvars(0), stime,   offset=[ncrecord], count=[1]
    ncdf_varget, ncid, ncvars(1), etime,   offset=[ncrecord], count=[1]
    ncdf_varget, ncid, ncvars(2), spectra, offset=[0,0,ncrecord], $
                 count=[scan_channels, ncnzones, 1]
    spectra = long(spectra)
    nneg    = 0
    negz    = where(spectra lt 0., nneg)
    if nneg gt 0 then spectra(negz) = spectra(negz) + 65536
    for j=0,ncnzones-1 do begin
        for k=1,ncnchan-1 do begin
            while spectra(k,j) - spectra(k-1, j) lt -32767 do spectra(k,j) = spectra(k,j) + 65536
        endfor
    endfor
    spectra = float(spectra)
    end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  This routine scans the data file for fit results, looking for the
;  first record with a Chi-Squared value equal to the "no data" fill
;  value for the netCDF file.  This is presumed to be the first record
;  for which fitting needs to be done.  That is, calling this routine
;  will skip all existing fits.
;

pro sdi_skip_existing_fits
@sdi_inc.pro
    if strpos(strupcase(getenv('sdi_skip_oldfits')), 'FALSE') ge 0 then return
    chisq=fltarr(ncnzones)
    ncdf_varget, ncid, lastvar-1, chisq,   offset=[0,ncrecord], $
                                           count=[ncnzones, 1]
    while (max(chisq) ne min(chisq)) do begin
           print, ncrecord, min(chisq), max(chisq), n_elements(chisq)
           ncrecord = ncrecord + 1
           ncdf_varget, ncid, lastvar-1, chisq,   offset=[0,ncrecord], $
                                                   count=[ncnzones, 1]
    endwhile
end


;========================================================================
;
;  This is procedure fits position, width, area and background
;  parameters to an exposure of sdi spectra:

pro sdi_fit_spectra
@sdi_inc.pro
        avpos = 0
        if (total(abs(spectra)) lt 100) then return
        print,  'Rec', ' Zn',  ' Sig/Nse', 'Iters  ', 'ChiSq', $
                'Position/Err', 'Width/Err', 'Area/Err',  'Bgnd',   $
                 format='(a3,a3,a8,a9,a7,a15,a15,a12,a7)'

;       Specify the diagnostics that we'd like:
        diagz    = ['dummy']
;        diagz    = [diagz, 'main_plot_answer(window, 0)']

;       Describe the species:
        species  = {s_spec, name: 'O', $
                            mass:  15.99491, $
                            relint: 1.}
;       Describe the instrument.
        dellam    = ((sky_wavelength*1e-9)^2)/(2*(plate_spacing*1e-3)*1.000276*scan_channels)
        cal       = {s_cal,   delta_lambda: dellam, $
                              nominal_lambda: sky_wavelength*1e-9}
        fix_mask = [0,  1,  0,  0,  0]

        for zidx=0,ncnzones-1 do begin
        fitpars  = [0., 0., 0., 0., 900.]

        spek_fit, spectra(*, zidx), insprofs(*, zidx), $
                  species, cal, fix_mask, diagz, fitpars, sigpars, quality
        if quality.iters gt 0 then chisq = quality.chisq(quality.iters-1)/quality.df

;           Weed out "NaN"s (Not-A-Number) from the results.  VMS does
;           not use NANs; unix systems often do.
            nancount = 0
            bads     = where(finite(fitpars) lt 1, nancount)
            if (nancount ne 0)      or $
               (finite(chisq) lt 1) or $
               (quality.status eq 'Signal/noise too low') or $
               (quality.status eq 'Singular dimensions encountered') then begin
                               fitpars = [-1., -1., -1., -1., -1.]
                               chisq = 9e9
                               quality.snr   = 0
            endif

            sig2noise(zidx)   = quality.snr
            chi_squared(zidx) = chisq
            positions(zidx)   = fitpars(3)
            widths(zidx)      = fitpars(4)*2.
            areas(zidx)       = fitpars(2)
            backgrounds(zidx) = fitpars(0)
            sigpos(zidx)      = sigpars(3)
            sigwid(zidx)      = sigpars(4)
            sigarea(zidx)     = sigpars(2)

            if (sig2noise(zidx) lt 100000) then $
                snrstr = string(long(sig2noise(zidx)), format='(i7)') $
            else $
                snrstr = string(sig2noise(zidx),      format='(g7.0)')

            kounts = string(quality.iters, format='(i5)')
            kounts = strcompress(kounts, /remove_all)
            posstr = string(positions(zidx), '/', sigpos(zidx), $
                            format='(f7.2, a1, f6.2)')
            posstr = strcompress(posstr, /remove_all)
            widstr = string(widths(zidx), '/', sigwid(zidx), $
                            format='(f7.2, a1, f6.2)')
            widstr = strcompress(widstr, /remove_all)
            arastr = string(areas(zidx), '/', sigarea(zidx), $
                            format='(f6.1, a1, f5.1)')
            arastr = strcompress(arastr, /remove_all)
            print,  ncrecord, zidx, snrstr, kounts, chisq, $
                    posstr, widstr, arastr, backgrounds(zidx), $
            format='(i3,i3,a8,a7,f9.2,a15,a15,a12,f7.1)'
        endfor

;        We have now processed all zones. Calculate averages of the
;        fitted quantities across all zones:
         snrtot  = total(sig2noise)
         worthy  = sort(positions(0:ncnzones-1))
         clipnum = ncnzones/10
         worthy  = worthy(clipnum:ncnzones-1-clipnum)
         avpos   = total(positions(worthy))/n_elements(worthy)
         avwid   = total(widths(0:ncnzones-1)*sig2noise)/snrtot
         avarea  = total(areas(0:ncnzones-1)*sig2noise)/snrtot
         badcount= 0
         bads    = where(sig2noise eq 0, badcount)
         if (badcount gt 0) then positions(bads) = avpos
         print, 'AVPOS=', avpos
         end


;  This routine appends the results of the latest fit to the netCDF data
;  file:

pro sdi_write_fitpars
@sdi_inc.pro
         ncdf_varput, ncid, ncvars(lastvar),   sig2noise, $
                      offset=[0, ncrecord], count=[ncnzones, 1]
         ncdf_varput, ncid, ncvars(lastvar-1), chi_squared, $
                      offset=[0, ncrecord], count=[ncnzones, 1]
         ncdf_varput, ncid, ncvars(lastvar-3), sigarea, $
                      offset=[0, ncrecord], count=[ncnzones, 1]
         ncdf_varput, ncid, ncvars(lastvar-4), sigwid, $
                      offset=[0, ncrecord], count=[ncnzones, 1]
         ncdf_varput, ncid, ncvars(lastvar-5), sigpos, $
                      offset=[0, ncrecord], count=[ncnzones, 1]
         ncdf_varput, ncid, ncvars(lastvar-6), backgrounds, $
                      offset=[0, ncrecord], count=[ncnzones, 1]
         ncdf_varput, ncid, ncvars(lastvar-7), areas, $
                      offset=[0, ncrecord], count=[ncnzones, 1]
         ncdf_varput, ncid, ncvars(lastvar-8), widths, $
                      offset=[0, ncrecord], count=[ncnzones, 1]
         ncdf_varput, ncid, ncvars(lastvar-9), positions, $
                      offset=[0, ncrecord], count=[ncnzones, 1]
         ncdf_control, ncid, /sync
end

;========================================================================
;
;  This is the MAIN procedure for the FITZ program.  This version uses
;  the environment variable sdi_yyddd to specify a year and day-number
;  for the data file to be processed.  The data file is expected to
;  reside in the current default directory, and be named like
;  skyyyddd.pf, where 'pf' is the site-code for Poker Flat (sorry, not
;  a general solution yet!).


@sdi_inc.pro
sdi_data_init
if getenv('RUN_BATFITZ') eq 'NO' then goto, NOFITZ
;sdi_chanshift = fix(getenv('sdi_chanshift'))
;fname  = 'Dummy'
;yyddd  = 'Dummy'
;read,    "Enter the year and day number as YYDDD --> ", yyddd
;yyddd  = getenv('sdi_yyddd')
sdi_chanshift = -20
sectm  = systime(1)
sec70cvt, long(sectm), yr, mo, dy, hr, mn, sc
jnow   = ymd2jd(yr, mo, dy)
jjan1  = ymd2jd(yr, 1, 1)
yyddd  = 1000L*(yr - 1900) + 1 + jnow - jjan1
yyddd  = string(yyddd, format='(i5.5)')
if strlen(getenv('BAT_YYDDD')) gt 0 then yyddd = getenv('BAT_YYDDD')

fname  = 'ins' + string(yyddd) + '.pf'
sdi_load_insprofs, fname
fname  = 'sky' + string(yyddd) + '.pf'
sdi_ncopen, fname
sdi_add_fit_vars
ncrecord = fix(getenv('sdi_record_offset'))
;ncrecord = 0
sdi_skip_existing_fits
while (avpos gt 0.0001) do begin
    print, 'YYDDD is: ', yyddd
    sdi_read_exposure
    spectra = shift(spectra, sdi_chanshift, 0)
    sdi_fit_spectra
    sdi_write_fitpars
    ncrecord = ncrecord + 1
endwhile
ncdf_close, ncid
NOFITZ:
end


