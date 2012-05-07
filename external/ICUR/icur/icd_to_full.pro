;**************************************************************************
pro icd_to_full,file,head,w,f,e,wave=wave,rec=rec,smoo=smoo,stp=stp,plt=plt, $
    debug=debug,helpme=helpme,save=save
;
if n_params() eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* ICD_TO_FULL - make 1-d spectrum from echelle format spectrum'
   print,'* calling sequence: ICD_TO_FULL,FILE,H,W,F,E'
   print,'*    FILE: name of .ICD file'
   print,'*    H,W,F,E:  standard output vectors'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    PLT: set to plot W,F'
   print,'*    REC:  ICD file records to include; 2-element vector'
   print,'*    SAVE: set to save 1-d spectrum in .icd format'
   print,'*    SMO: set to FFT smooth, value = HW in Nyquist units'
   print,'*    WAVE: wavelengths to include; 2-element vector'
   print,' '
   return
   endif
;
nr=get_nspec(file)            ;number of records
if nr le 0 then begin
   print,' File not found - returning'
   return
   endif
;
if n_elements(stp) eq 0 then stp=0
if n_params() lt 3 then plt=1
;
i1=0 & i2=nr-1
wl0=0. & wl00=100000.
case n_elements(rec) of
   2: begin
      i1=rec(0) & i2=rec(1)
      end
   1: i1=rec(0)
   else:
   endcase
if n_elements(rec) gt 0 then nolam=1 else nolam=0
case n_elements(wave) of
   2: begin
      wl0=wave(0) & wl00=wave(1)
      end
   1: wl0=wave(0)
   else:
   endcase
;
ncoadd=0
if keyword_set(debug) then print,i1,i2,wl0,wl00
if n_elements(smoo) eq 0 then smoo=0
sm0=smoo
gdat,file,h1,w1,f1,e1,i1
w1=double(w1)
h0=h1
inst=h1(3) & time=h1(5)
if keyword_set(smoo) then fftsm,f1,1,sm0
;
for i=i1+1,i2 do begin
   gdat,file,h2,w2,f2,e2,i
   w2=double(w2)
   wr1=min(w2) & wr2=max(w2)
   if nolam and (i eq i1) then wl00=wr2-1.
   if (wr2 ge wl0) and (wr1 le wl00) then begin
      if stp ge 2 then stop
      sm0=smoo
      if keyword_set(smoo) then fftsm,f2,1,sm0
      if ncoadd eq 0 then begin
         w1=w2 & f1=f2 & h1=h2 & e1=e2
         endif
      vmerge,h1,w1,f1,e1,h2,w2,f2,e2,head,w,f,e
      ncoadd=ncoadd+1
      w1=w & f1=f & e1=e
      help,w
      endif else begin
         w1=w2 & f1=f2 & e1=e2
         endelse
   if wl00 le wr1 then goto,skipout
   endfor
;
head(5)=time & head(3)=inst
head(10:15)=h0(10:15)
skipout:
if keyword_set(plt) then begin
   !x.title='!6 Angstroms'
   !y.title=ytit(0)
   !p.title='!6'+file
   wl0=min(w) & wl00=max(w)
   setxy,wl0,wl00 & svp
   plot,w,f
   if !d.name eq 'X' then wshow
   endif
;
if keyword_set(save) then begin
   if not ifstring(save) then save=file+'_1d'
   kdat,save,head,w,f,e,/islin
   endif
;
if keyword_set(stp) then stop,'ICD_TO_FULL>>>'
return
end




