;*********************************************************************
pro op_bb,wave,f,bbt=bbt,nh=nh,rd=rd,apcor=apcor,ns=ns,kt=kt,ev=ev, $
   quiet=quiet,helpme=helpme,stp=stp
;
if n_elements(wave) eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* OP_BB : overplot BB spectrum'
   print,'* calling sequence: OP_BB,WAVE(,FLUX)'
   print,'*    WAVE: wavelength in Angstroms'
   print,'*    FLUX: if passed, normalize BB to data'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    APCOR: aperture correction, def=1.0'
   print,'*    BBT:   temperature (no default except /NS)'
   print,'*    EV: temperature in eV'
   print,'*    KT: temperature in K (default)'
   print,'*    Nh: column in units of 10^20 /cm^2'
   print,'*    NS: use defaults for 1856 (bbt=52eV, Nh=2.0, apcor=0.8, rd=0.09)'
   print,'*    RD: R/D normalization in km/pc'
   print,' '
   return
   endif
;
if keyword_set(ns) then begin
   if n_elements(bbt) eq 0 then bbt=52.0     ;eV
   if n_elements(nh) eq 0 then nh=2.0     ;10^20
   if n_elements(rd) eq 0 then rd=0.09    ;km/pc
   if n_elements(apcor) eq 0 then apcor=0.8
   ev=1
   endif
if n_elements(apcor) eq 0 then apcor=1.0
if n_elements(bbt) eq 0 then begin
   print,' You must supply a temperature'
   return
   endif
;
if keyword_set(ev) then temp=11604.*bbt
;
bb=bbflux(wave/1.e4,temp)                ;Planck spectrum
if n_elements(nh) eq 1 then begin              ;ISM absorption
   nh1=nh*1.e20
   tr=ism(wave,nh1)
   bb=bb*tr
   endif
;
if n_elements(f) gt 2 then begin
   k=where(f gt 0.0)
   sc=total(f(k))/total(bb(k))
   rd2=sqrt(sc*apcor)*3.e13
   bb2=bb*sc
   oplot,wave,bb2,color=2    ;normalized
   if not keyword_set(quiet) then print,' Normalization R/D=',rd2,'km/pc'
   endif
;
if n_elements(rd) eq 1 then begin
   rd1=rd/3.e13
   bb1=bb*rd1*rd1
   bb1=bb1/apcor         ;aperture correction
   oplot,wave,bb1,color=5    ;exact
   endif
;
if not keyword_set(quiet) then begin
   y1=!p.position(3)-0.05
   x1=0.65
   if keyword_set(ev) then zt=string(bbt,'(F7.1)')+' eV' else $
      zt=string(bbt,'(I7)')+' K'
   z='BB:'+zt
   xyouts,x1,y1,z,charsize=1.4,/norm
   y1=y1-0.04
   if keyword_set(nh) then begin
      znh=string(nh,'(F6.2)')+'E20 cm^-2'
      z='   '+znh
      xyouts,x1,y1,z,charsize=1.4,/norm
      y1=y1-0.04
      endif
   if keyword_set(rd) then begin
      zrd=string(rd,'(F7.3)')+' km/pc'
      z='   '+zrd
      xyouts,x1,y1,z,charsize=1.4,/norm
      y1=y1-0.04
      endif
   if keyword_set(rd2) then begin
      zrd=string(rd2,'(F7.3)')+' km/pc (fit)'
      z='   '+zrd
      xyouts,x1,y1,z,charsize=1.4,/norm
      y1=y1-0.04
      endif
   endif
;
if keyword_set(stp) then stop,'OP_BB>>>'
return
end
