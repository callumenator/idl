;  this is a program for generating and plotting lomb spectra.

load_mycolor

values=lnp_test(znthtimes,znthwnd,wk1=wk1,wk2=wk2,jmax=jmax)

lasttime=max(znthtimes)
firsttime=min(znthtimes)
ofac=double(4.)
hifac=double(1.)
lombmax=0.
dif=double(lasttime-firsttime)
sum=double(lasttime+firsttime)
nele=n_elements(znthwnd)

nyquist=double(nele/(2.*dif))
hghfrq=double(hifac*nyquist)
lwfrq=double(1./(dif*ofac))
tmpfrq=double(lwfrq)
tave=double(sum/2.)
np=fix((ofac*hifac*nele)/2.)
effm=double(hifac*nele)
signifprob=0.05
signiflomb=-(alog(1-((1-signifprob)^(1/effm))))
dasher=fltarr(fix(0.666666*np))
dasher(*)=signiflomb

freq=wk1
lomb=wk2
freqpeak=freq(jmax)
lombmax=lomb(jmax)
expy=double(exp(-lombmax))
prob=1.-((1.-expy)^effm)

probinfo=strcompress(string(prob,format='(f25.16)'),/remove_all)
probinfo=strmid(probinfo,0,6)
normpower=strmid(strcompress(lombmax,/remove_all),0,5)
peakfreq=strmid(strcompress(freqpeak,/remove_all),0,6)
peakperiod=strmid(strcompress((1./freqpeak),/remove_all),0,6)

lombinfo='!C'+'Peak of the Lomb Spectrum occurs at frequency '+$
  peakfreq+' cycles/hr,!C'+'corresponding to a period of '+peakperiod+$
  ' hrs,!C'+'with a significance level of '+probinfo+'.!C'+$
  'Normalized power at the peak is '+normpower+'.'

window,2,retain=2,xsize=800,ysize=600
 
plot,freq,lomb,xrange=[lwfrq,hghfrq],$
  title='Normalized Lomb Periodogram of!CVertical Wind Time Series from '+$
                     month+' '+day+', '+year+$
					'!CInuvik, NWT, Canada',$
  ytitle='Spectral Power',xtitle='Frequency, cycles/hr',$
  subtitle=lombinfo,xstyle=1,charsize=1.3,charthick=1.5,xcharsize=1.,$
  ystyle=1,pos=[0.1,0.225,0.9,0.825]
;if (lombmax ge signiflomb) then begin
 oplot,freq,dasher,linestyle=2
 xyouts,freq(fix(0.666666*np)+3),signiflomb,'significance level 0.05',$
   /noclip
;endif 

;end
