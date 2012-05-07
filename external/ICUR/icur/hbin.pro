;**************************************************************************
PRO HBIN,WAVE,FLUX,EPS,F1,E1,E           ; SHIFT WAVELENGTH WITH HALF BINS
COMMON COM1,HD,IK,IFT,NSM,C
;
S0=N_ELEMENTS(FLUX) 
S1=N_ELEMENTS(F1)
tflux=rebin(flux,s0*2)
tf1=rebin(f1,s1*2)
teps=rebin(eps,s0*2)
te1=rebin(e1,s1*2)
disp=(double(wave(s0-1))-double(wave(0)))/(s0-2)                  ;dispersion
tw=wave(0)+(dindgen(2*s0)-1)*disp/2.
HD(39)=HD(39)*2
;
WSHIFT,1,TW,TFLUX,TEPS,TF1,TE1,TE,0.
HD(39)=HD(39)/2
nep=n_elements(te)/2
E=rebin(te,nep,/sample)
F1=rebin(tf1,s1,/sample)
ZERR=98
RETURN
END
