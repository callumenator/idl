pro snr_test, profile, snr, nsig, nwid, variance
    npts     = n_elements(profile)
    ncn2     = npts/2
    ncn4     = npts/4
    ftspec   = fft(profile, -1)
    pd       = float(abs(ftspec*conj(ftspec)))
    mnp      = total(pd(ncn4:ncn2))/(ncn2 - ncn4 + 1)
    noisep   = (mnp + 2*median(pd(ncn4:ncn2)))/3
    variance = sqrt(2)*noisep*npts

 ;  Compute the signal/noise ratio:
    if noisep gt 0 then snr = pd(1)/noisep $
       else             snr = -1.
    nsig=1
    nwid=1
;    plot, pd, /ylog
;    oplot, [0,npts-1], [noisep, noisep]
    while (nsig lt npts-1) and (pd(nsig) gt noisep)     do nsig=nsig+1
    while (nwid lt npts-1) and (pd(nwid) - noisep gt 0.05*(pd(1) - noisep)) do nwid=nwid+1
    

end