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
       positions   = fltarr(64)
       areas       = fltarr(64)
       widths      = fltarr(64)
       sigpos      = fltarr(64)
       sigarea     = fltarr(64)
       sigwid      = fltarr(64)
       backgrounds = fltarr(64)
       sig2noise   = fltarr(64)
       chi_squared = fltarr(64)
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
        spectra (*,zidx) = shift(spectra(*,zidx), 64)
;        if zidx lt 13 then spectra (*,zidx) = smooth(spectra(*,zidx), 3)
;        if zidx ge 13 then spectra (*,zidx) = smooth(spectra(*,zidx), 5)
        insprofs(*,zidx) = fft (spectra(*,zidx), -1)
        nrm              = abs(insprofs(1,zidx)) ;###
        insprofs(*,zidx) = insprofs(*,zidx)/(nrm)
        insprofs(*,zidx) = conj(insprofs(*,zidx)) ;###
    endfor
    inspower = abs(insprofs*conj(insprofs))
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
    spectra = complex(spectra)    
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
    if (getenv('sdi_skip_oldfits') ne 'TRUE') then return
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
        print,  'Rec', ' Zn',  ' Sig/Nse', 'Itn/Pts', 'ChiSq', $
                'Position/Err', 'Width/Err', 'Area/Err',  'Bgnd',   $
                 format='(a3,a3,a8,a9,a7,a15,a15,a12,a7)'
        fitpars   = dblarr(3) ;###
        ncn2      = scan_channels/2
        ncn4      = scan_channels/4
        ncn8      = scan_channels/8
        for zidx=0,ncnzones-1 do begin

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;           Generate initial fit estimates.  Parameters are:
;              0: Related to peak position
;              2: Related to peak width
;              1: Total signal counts
;              3: Background (if implemented)
;           Estimate  for 3 is obtained in the signal domain, 
;           Estimates for 0 and 1 are obtained in the transform domain,
;           Estimate  for 2 is a fixed proportion of the scan channels.


;           Find the DC portion of the observation signal:            
            bget = spectra(*,zidx)
            bget = [bget, bget, bget]
            bget = smooth(bget, ncn8)
            bget = bget(scan_channels:2*scan_channels-1)
            backgrounds(zidx) = min(bget)
            spectra(*,zidx) = spectra(*, zidx) - backgrounds(zidx)
            spx = spectra(*,zidx)
            spectra(0:ncn4, zidx) = smooth(spectra(0:ncn4, zidx), 5)
            spectra(3*ncn4:*, zidx) = smooth(spectra(3*ncn4:*, zidx), 5)
            spectra(*,zidx) = fft (spectra(*,zidx), -1, /overwrite)
            spx = fft (spx, -1, /overwrite)
            fitpars(0) = atan(imaginary(spectra(1,zidx)/insprofs(1,zidx)), $
                                  float(spectra(1,zidx)/insprofs(1,zidx)))
            while (fitpars(0) lt 0) do fitpars(0) = fitpars(0) + 2*!pi
            fitpars(2) = (!pi*25/scan_channels)^2
            fitpars(1) = abs(spectra(0,zidx)) ;###
;###            fitpars(3) = 0 ;###
            chisq  = 9e9
            iters  = 0
            sigfit = fltarr(n_elements(fitpars))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;           Calculate the high-frequency noise power and its standard
;           deviation:
            max_sig_freq    = 0
            pd              = float(abs(spectra(*,zidx)*conj(spectra(*,zidx))))
            pd              = float(abs(spx*conj(spx)))
;####            noise_power     = total(pd(ncn4:ncn2))/(1.+ncn2-ncn4)
            noise_power     = median(pd(ncn4:ncn2))
            if noise_power gt 0 then sig2noise(zidx) = pd(1)/noise_power $
               else                  sig2noise(zidx) = .01
            badcount = 0
            bads = wherenan(sig2noise, badcount)
            if badcount gt 0 then sig2noise(bads) = 0.01
            if (sig2noise(zidx) lt 1.) then fitpars = [0.,-1.,-1.,-1.]
            if (sig2noise(zidx) lt 1.) then goto, SKIPFIT


            noise_level = median(abs(spectra(ncn4:ncn2,zidx)))
            nnrm   = noise_level/abs(spectra(1,zidx))
spx = abs(smooth(spectra(*,zidx),3))*spectra(*,zidx)/abs(spectra(*,zidx))
wgt = findgen(scan_channels)-2
spectra(3:*,zidx) = (spectra(3:*,zidx) + wgt(3:*)*spx(3:*))/(wgt(3:*)+1)
            nrmobs = spectra(*,zidx)/abs(spectra(1,zidx))
            nrmnse = nnrm*(nrmobs/abs(nrmobs))
            ptsel  = where(abs(nrmobs) gt 1.414*abs(nrmnse))
;###            nrmobs(ptsel) = nrmobs(ptsel) - nrmnse(ptsel)
;###            nrmobs = nrmobs/abs(nrmobs(1))

;           Determine how many spectral components to use.  Note that 
;           since IDL uses zero-based indexing we actually use 
;           max_sig_freq+1 components:

            nel = 0
            noisy = [reverse(pd), pd]
            noisy = median(noisy, 3)
            noisy = noisy(n_elements(pd):*)
            noisy = where(noisy lt noise_power, nel)
            minf = 3
            maxf = 7
            if (sig2noise(zidx) gt 300)  then begin
                                         minf = 4
                                         maxf = 9
            endif
            if (sig2noise(zidx) gt 800)  then begin
                                         minf = 5
                                         maxf = 10
            endif
            if (sig2noise(zidx) gt 5000) then begin 
                                         minf = 6
                                         maxf = 11
            endif
            
            max_sig_freq = minf
            if (nel gt 2) then max_sig_freq = noisy(0)+3
            max_sig_freq = max_sig_freq > minf
            max_sig_freq = max_sig_freq < maxf

            sdi_grid_search, fitpars, sigfit, chisq, iters
            fitpars = float(fitpars)
                                 
;           Weed out "NaN"s (Not-A-Number) from the results.  VMS does 
;           not use NANs; unix systems often do.
SKIPFIT:    nancount = 0
            bads     = where(finite(fitpars) lt 1, nancount)
            if (nancount ne 0) or (finite(chisq) lt 1) then begin
                               fitpars = [0.,-1.,-1.,-1.]
                               chisq      = 9e9
                               sig2noise(zidx) = 0
            endif

;           Convert the parameters in the transform domain to the 
;           required signal domain equivalents and print a one-line 
;           summary:
            f1  = scan_channels/!pi
            chl = abs(fitpars(0)*f1/2.)
            while (chl gt scan_channels) do chl = chl - scan_channels
            if (fitpars(2) gt 0) then wdt = sqrt(fitpars(2))*f1 $
            else                      wdt = 0
            chi_squared(zidx) = chisq
            positions(zidx)   = chl
            widths(zidx)      = wdt
            areas(zidx)       = fitpars(1)

            chl = abs(abs(fitpars(0)*f1/2.) - $
                      abs((fitpars(0)+sigfit(0))*f1/2.))
            if (fitpars(2)+sigfit(2) gt 0) then $
                wdt = sqrt(fitpars(2)+sigfit(2))*f1 $
            else  wdt = 9e9

            sigpos(zidx)      = chl
            sigwid(zidx)      = abs(widths(zidx) - wdt)
            sigarea(zidx)     = abs(sigfit(1))
;###            backgrounds(zidx) = backgrounds(zidx) + fitpars(3);####
            if (sig2noise(zidx) lt 999999) then $
                snrstr = string(fix(sig2noise(zidx)), format='(i7)') $
            else $
                snrstr = string(sig2noise(zidx),      format='(g7.0)')
                
            kounts = string(iters, '/', max_sig_freq, $
                            format='(i5,a1, i2)')
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
            format='(i3,i3,a8,a9,f7.2,a15,a15,a12,f7.1)'
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

;  This function returns an unreduced chi-squared goodness of fit
;  indicator for a weighted fit between the fourier transform of the
;  recorded spectrum and a fourier transform of a Gaussian spectrum
;  convolved with the appropriate instrument function for this zone:
function sdi_chigau, fitpars
@sdi_inc.pro

;        Compute the number of statistical degrees of freedom we have:
         df = 1.
         if max_sig_freq gt 2 then df = (float(max_sig_freq) - 1)/max_sig_freq
;        Assign weights to each term in the Fourier expansion:
;####         fwght  = sqrt(inspower(0:max_sig_freq))
;###    fwght  = fltarr(max_sig_freq+1) + 1
         fwght  = sqrt(findgen(max_sig_freq+1) + 1)
         nnrm   = noise_power/(abs(spectra(1,zidx))^2)

         sdi_tgen, trial, fitpars
         trial  = trial/abs(trial(1))
; New test code in here:
         fitdif = nrmobs(0:max_sig_freq) - trial(0:max_sig_freq)

;         fitdif = spectra(0:max_sig_freq,zidx)/ $
;                  abs(spectra(1,zidx)) - $
;                  trial(0:max_sig_freq)
         fitdif = float(fitdif*conj(fitdif))
         return, (total(fitdif(1:*)*fwght(1:*)) / $
                        (df*total(fwght(1:*))*nnrm))
         
end

;  This procedure uses an 'improved grid search' to fit a trial function
;  to the sky spectra.  The fit is done in the transform domain.  The
;  'improvement' to the grid search is that the coefficient for emission
;  intensity is solved analytically.  
;
;                  Mark Conde, Fairbanks, September 1996.

pro sdi_grid_search, fitpars, sigfit, chisq, iters
@sdi_inc.pro

   iters    = 0
   pos_step = 0.01
   brt_step = 2
   wid_step = 0.01
   chisq    = 9e9
   repeat begin
      prev_chi = chisq
      sdi_min_chi, fitpars, 2, wid_step, wid_dist, chisq
      sdi_next_step, wid_step, wid_dist
      sdi_min_chi, fitpars, 0, pos_step, pos_dist, chisq
      sdi_next_step, pos_step, pos_dist
      chisq = sdi_chigau(fitpars)
      iters = iters + 1
   endrep until iters gt 9 and $
               (iters gt 64 or (abs(chisq - prev_chi) lt .0000002)) 
   sdi_trial_brite, fitpars, tb
   fitpars(1) = tb

;  Now find the uncertainies in each parameter.
;  First, Compute the number of statistical degrees of freedom we have:
   df = 1.
   if max_sig_freq gt 2 then df = (float(max_sig_freq) - 1)

   precision = 200.
   delpar = fitpars/precision
   for par=0,n_elements(fitpars)-1 do begin
       if par eq 1 then par = 2 ;### No need to search for brite error
       inc = 0
       pardone = 0
       basechi = df*sdi_chigau(fitpars)
       parshif = fltarr(n_elements(fitpars))
       repeat begin
              inc = inc + 1
              parshif(par) = inc*delpar(par)
              if (df*sdi_chigau(fitpars+parshif) - basechi gt 1) then $
                  pardone = 1
       endrep until (inc gt precision or pardone eq 1)
       sigfit(par) = parshif(par)
   endfor
   sigfit(1) = sqrt(fitpars(1)/scan_channels)
   end

;  This procedure adjusts the step size ('step') after an iteration of the
;  grid search.  The adjustment is based on the number of steps ('dist') 
;  that the previous iteration needed to take to find a minimum.  Step size
;  can increase, decrease, or remain unchanged.
pro sdi_next_step, step, dist
    if dist lt 10  then step = step/2.
    if dist ge 10   and dist lt 17 then step = step/1.5
    if dist ge 25  and dist lt 35 then step = step*2
    if dist ge 35  and dist lt 50 then step = step*3
    if dist ge 50  then step = step*4
end

;  Minimise chi-squared along one dimension by grid searching:
pro sdi_min_chi, fitpars, dim, step, dist, chisq
@sdi_inc.pro
      dir = 1
      prev_chi = sdi_chigau(fitpars)
      fitpars(dim) = fitpars(dim) + dir*step
      test_chi = sdi_chigau(fitpars)
      if test_chi gt prev_chi then dir = -1
      inc = 0
      repeat begin
         prev_chi = test_chi
         fitpars(dim) = fitpars(dim) + dir*step
         inc = inc + 1
         test_chi = sdi_chigau(fitpars)
      endrep until (inc gt 50 or test_chi gt prev_chi)
      fitpars(dim) = fitpars(dim) - dir*step
      chisq = prev_chi
      dist = inc - 1 
end

;  This procedure analytically determines the emission brightness value
;  which will minimise chi-squared for the current width and position
;  values:
pro sdi_trial_brite, fitpars, tb
@sdi_inc.pro
            sdi_tgen, trial, fitpars
            trial = trial(1:max_sig_freq)
            tb = total(abs(spectra(1:max_sig_freq,zidx)*trial))/$
                         total(abs(trial*trial))
end

;  This procedure generates a 'unit brightness' trial Gaussian convolved
;  with the instrument profile.  It is used in both the linear and 
;  non-linear portions of the curve fitting algorithm.
pro sdi_tgen, trial, fitpars
@sdi_inc.pro
         trial  = findgen(max_sig_freq+1)
         trial  = complex(fitpars(2)*trial*trial, fitpars(0)*trial)
         trial  = exp(-trial)
         trial  = trial*insprofs(0:max_sig_freq, zidx)
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
sdi_chanshift = fix(getenv('sdi_chanshift'))
fname  = 'Dummy'
yyddd  = 'Dummy'
;read,    "Enter the year and day number as YYDDD --> ", yyddd
yyddd  = getenv('sdi_yyddd')
fname  = 'ins' + string(yyddd) + '.pf'
sdi_load_insprofs, fname 
fname  = 'sky' + string(yyddd) + '.pf'
sdi_ncopen, fname
sdi_add_fit_vars
ncrecord = fix(getenv('sdi_record_offset'))
sdi_skip_existing_fits
while (avpos gt 0.0001) do begin
    sdi_read_exposure
    spectra = shift(spectra, sdi_chanshift, 0)
    sdi_fit_spectra
    sdi_write_fitpars
    ncrecord = ncrecord + 1
endwhile
ncdf_close, ncid
end


