;========================================================================
;  This is procedure fits position, width, area and background
;  parameters to an exposure of sdi spectra:

pro sdi3k_level1_fit,  record, sectime, spectra, mm, sig2noise, chi_squared, $
                       sigarea, sigwid, sigpos, sigbgnd, $
                       backgrounds, areas, widths, positions, insprofs, no_temperature=notemp, $
                       initial_temp=itmp, min_iters=min_iters, shiftpos = shiftpos

        if (total(abs(spectra)) lt 100) then return

        print,  'Date        HH:MM ', 'Rec', ' Zn',  ' Sig/Nse', 'Iters  ', 'ChiSq', $
                'Position/Err', 'Width/Err', 'Area/Err',  'Bgnd/Err',   $
                 format='(a18, a3,a3,a8,a9,a7,a18,a18,a15,a20)'

;-------Specify the diagnostics that we'd like:
        diagz = ['dummy']
        diagz = [diagz, 'main_loop_wait(ctlz.secwait = 0.00001)']
;       diagz = [diagz, 'basis_plot_molecular']

;-------Describe the species:
        species = {s_spec, name: 'O', $
                           mass:  15.99491, $
                         relint: 1.}
;-------Describe the instrument.
        dellam  = ((mm.wavelength_nm*1e-9)^2)/(2*(mm.gap_mm*1e-3)*1.000276*mm.scan_channels)
        cal     = {s_cal,   delta_lambda: dellam, $
                          nominal_lambda: mm.wavelength_nm*1e-9}
        fix_mask= [0,  1,  0,  0,  0]

    if keyword_set(notemp) then fix_mask= [0,  1,  0,  0,  1]

        nz = mm.nzones
        sig2noise   = fltarr(nz)
        chi_squared = fltarr(nz)
        positions   = fltarr(nz)
        widths      = fltarr(nz)
        areas       = fltarr(nz)
        backgrounds = fltarr(nz)
        sigpos      = fltarr(nz)
        sigwid      = fltarr(nz)
        sigarea     = fltarr(nz)
        sigbgnd     = fltarr(nz)

        for zidx=0,nz-1 do begin
            fitpars = [0., 0., 0., 0., 500.]
            if keyword_set(itmp) then fitpars(4) = itmp
;-----------Fit the spectra:
            if keyword_set(notemp) then fitpars(4) = 2.
            spx = reform(spectra(zidx,*))
            if keyword_set(shiftpos) then spx = shift(spx, shiftpos)
            ipr = reform(insprofs(zidx,*))
            spk = where(mc_im_sm(spx, 5) eq max(mc_im_sm(spx, 5)))
            ipk = where(mc_im_sm(ipr, 3) eq max(mc_im_sm(ipr, 3)))
            fitpars(3) = spk(0) - ipk(0)
            spek_fit, spx, ipr, $
                      species, cal, fix_mask, diagz, fitpars, sigpars, quality, max_iters=200, /passive, min_iters=min_iters
            if quality.iters gt 0 then chisq = quality.chisq(quality.iters-1)/quality.df else chisq = -1.

;-----------Weed out "NaN"s (Not-A-Number) from the results
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
            widths(zidx)      = fitpars(4)
            areas(zidx)       = fitpars(2)
            backgrounds(zidx) = fitpars(0)
            sigpos(zidx)      = sigpars(3)
            sigwid(zidx)      = sigpars(4)
            sigarea(zidx)     = sigpars(2)
            sigbgnd(zidx)     = sigpars(0)

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
                            format='(f8.1, a1, f6.1)')
            arastr = strcompress(arastr, /remove_all)
            bgstr  = string(backgrounds(zidx), '/', sigbgnd(zidx), $
                            format='(f9.1, a1, f8.2)')
            bgstr  = strcompress(bgstr, /remove_all)
            print,  dt_tm_mk(js2jd(0d)+1, sectime, format='d$-n$-Y$ h$:m$ '), $
                    record, zidx, snrstr, kounts, chisq, $
                    posstr, widstr, arastr, bgstr, ' -> ', quality.status, $
            format='(a18,i3,i3,a8,a7,f9.2,a18,a18,a15,a20, a4, a)'
        endfor
end
