;************************************************************************
pro FFLPFW,dtype,NCAM,IGAUS,SMTH,lwid=lwid,quiet=quiet, $
    limbdark=limbdark,linext=linext
; called by FFIT2
; lists line parameters for gaussian lines
; lwid permits passing of line width in bins
COMMON CFT,X,Y,SIG,E
COMMON CURVE,A,EA,ifixt
COMMON PLCR,YF
common ffits,lu4
common icurunits,xunits,yunits,title
common custompars,dw,lp,x2,x3,x4,ews,ldp
if n_elements(ldp) eq 0 then ldp=1.
if n_elements(linext) eq 0 then linext=2.0
ldp=ldp>1.
if not keyword_set(quiet) then quiet=0
nterms=n_elements(a)
nlines=(nterms-3)/3
IF NLINES GT 0 THEN ews=fltarr(nlines) ELSE EWS=0
if nlines lt 1 then return
if n_elements(lu4) eq 0 then lu4=-1
errfmt='(F6.3)'
;
if n_elements(lwid) ne 0 then wlin=lwid(0) else wlin=2.  ;default line widths
if dtype ge 1 then wlin=-1.
imax=n_elements(x)-1
AB=(X(IMAX)-X(0))/FLOAT(IMAX-1)   ;AB IS NUMBER OF ANGSTROMS PER BIN
ab2=ab*ab
if n_elements(xunits) eq 0 then xunits=''
if wlin ge 0. then begin
   WL=WLIN*AB                     ;A
   swlin=string(wlin,'(F5.2)')
   swl=string(wl,'(F7.3)')
   if lu4 ne -1 then printf,lu4,'*  Instrumental width=',swlin,' bins=',swl,' ',xunits
   IF  IGAUS eq 1 then begin
      WL=SQRT(WL*WL+SMTH*SMTH)      ;smoothed bins in A
      WLIN=SQRT(WLIN*WLIN+SMTH*SMTH/AB/AB)    ;in bins
      swlin=string(wlin,'(F5.2)')
      swl=string(wl,'(F7.3)')
      if lu4 ne -1 then begin
         printf,lu4,'*  Effective instrumental width=',swlin,' bins; ',swl,' ',xunits
         printf,lu4,'*-- '
         endif
      endif
   EWLIN=0.01*WLIN*WLIN    ;10% error  - in bins
   endif
;
for ilin=1,nlines do begin
   IA=ilin*3      ;amplitude
   IC=ILIN*3+1    ;position
   IE=IC+1        ;width       ;   a(ie) IS IN FWHM (BINS)
   xl=lint(x,a(ic)) & if n_elements(size(xl)) eq 4 then xl=xl(0)
   AD=A(IC)+EA(IC)
   IF AD GT FLOAT(IMAX-1) then AD=A(IC)-EA(IC)
   xd=lint(x,ad)
   XD=ABS(XD-XL)
   sxl=string(xl,'(F9.3)')
   sxd=string(xd,errfmt)
   if lu4 ne -1 then printf,lu4,'*  Line',string(Ilin,'(I2)'),' at',sxl,'+/-',sxd,' ',xunits
   if not quiet then print,' Line',string(Ilin,'(I2)'),' at',sxl,'+/-',sxd,' ',xunits
   f1=a(ie)*ab             ;GAUSSIAN WIDTH   ;******************************8
   IF NTERMS EQ 4 then RETURN
   F2=F1*1.177                           ;FWHM=WIDTH*SIGMA, in A
   sf2=string(f2,errfmt)
   sf1=string(f1,errfmt)
   zz1='  LW='+string(wl/ab,'(F4.1)')+' pix'
   zd1='Gaussian sigma = '+sf1+' '+xunits+'; FWHM='+sf2+' '+xunits+zz1
   if lu4 ne -1 then printf,lu4,'*       ',zd1
   if not quiet then print,'   ',zd1
   if wlin ge 0. then begin
      FWE=SQRT(EA(IE)*EA(IE)*4.*ab2+EWLIN*ab2)    ;in A
      sfwe=string(fwe,errfmt)
      IF F2 ge WL then begin
         FWL=SQRT(F2*F2-WL*WL)
         sfwl=string(fwl,'(F7.3)')
         RV=FWL*2.99792E5/XL/ldp   ;ldp accounts for non-Gaussianity of profile
         srv=string(rv,'(F6.1)')
         srv2=' (RVcal='+string(ldp,'(F4.2)')+')'
         zdev=' Deconv. width ='+sfwl+'+/-'+sfwe+' ' $
                +xunits+'; Vsin i='+srv+' km/s' + srv2
         endif else zdev='Unresolved line; <'+sfwe+' '+xunits
      if lu4 ne -1 then printf,lu4,'*       ',zdev
      if not quiet then print,'   ',zdev
      endif
;
; end of lpfw; EQWID appended
   if dtype ne 1 then begin
      w1=xl-linext*ABS(A(ie))*ab   ;+/- 1.5 FWHMs
      w2=xl+linext*ABS(A(ie))*ab
      BS=ABS(W2-W1)                   ;line full width
      b1=xindex(x,w1)
      b2=xindex(x,w2)
      IB1=fix(B1-0.5)>0    ;- 1 bin
      IB2=fix(B2+1.5)<(imax-1)    ;+ 1 bin
      kx=indgen(ib2-ib1+1)+ib1                
      sk=sig(kx)
      wbad=where(sk eq 0.,NBAD)
      Z=Y(KX)                               ;data
      IF NBAD GT 0 THEN Z(WBAD)=(YF(KX))(WBAD) ;FILL IN BAD VALUES
      EAX=EA(0:2)/EA(0)                         ;normalize
      cb=(yf(kx)-gauslin(kx,a,ilin))     ;fit - line = net background
      cb=total(cb)*ab
      cl=total(Z)*AB                     ;total flux in data = line + background
      CLE=SQRT(total(Sk*sk))*AB          ;uncertainty in total line flux
      cd=cl-cb                           ;net flux in line
      cbe=sqrt(eax(0)*eax(0)+(kx*EAx(1))^2+(KX*KX*EAx(2))^2)  ;unc. in each bin
      cbe=SQRT(TOTAL(CBE*CBE))*ea(0)*AB    ;total uncertainty in line
; apportion uncertainty between net background, total
;      eb1=sk*sqrt(1.+(cb1/yf(kx)))    ;background error
;      ey1=sk*sqrt(1.+(yf(kx)/cb1))      ;line error
;
      FE=SQRT(CLE*CLE+CBE*CBE)
      scl=string(cl,'(g10.3)')
      scle=string(cle,'(g10.3)')
      scb=string(cb,'(g10.3)')
      scbe=string(cbe,'(g10.3)')
      scd=string(cd,'(g10.3)')
      sfe=string(fe,'(g10.3)')
      sl=string(ilin,'(I2)')
      SSP='              '
      if lu4 ne -1 then printf,lu4,'*    Flux in line',sl,' + background: ',scl,' +/-',scle
      if not quiet then print,'  Flux in line',sl,' + background:',scl,' +/-',scle
      if lu4 ne -1 then printf,lu4,'*    Extrapolated background flux:',scb,' +/-',scbe
      if not quiet then print,'  Extrapolated background flux:',scb,' +/-',scbe
      if lu4 ne -1 then printf,lu4,'*  Net Flux, line',sl,' : ',SSP,sCD,' +/-',sfe,' erg/s/cm2'
      if not quiet then print,' Net Flux, line',sl,' =',sCD,' +/-',sfe,' erg/s/cm2'
;
      FNL=A(ia)*AB*ABS(A(ie))*SQRT(3.14159/2.)             ;integrate gaussian
      rgn=STRING(fnl/CD,'(F6.2)')
      srgn=string(rgn,errfmt)
      if abs(rgn-1.) gt 0.2 then sxfl=' ******' else sxfl=' '
      if lu4 ne -1 then printf,lu4,'*  Integrated Gaussian Flux=',fnl,' erg/s/cm2;  G/net=',rgn,sxfl
      if not quiet then print,' Integrated Gaussian Flux=',string(fnl,'(g10.3)'),' erg/s/cm2;  G/net=',rgn,sxfl
;
      cb1=(yf(kx)-gauslin(kx,a,ilin))    ;fit - line  erg/cm2/s/A
      cd1=z-cb1                        ;flux in line - erg/cm2/s/A
      ew=-total(cd1/cb1)*ab
      ewe=abs(errdiv(total(cd1),fe,cb,cbe))
      ews(ilin-1)=ew
      sew=string(ew,'(F9.3)')
      if abs(ewe) ge 100. then sewe='      ' else sewe=string(ewe,errfmt)
      if lu4 ne -1 then printf,lu4,'*  EW of line',sl,' is',sew,' +/-',sewe,' Angstroms'
      if not quiet then print,' EW of line',sl,' is',sew,' +/-',sewe,' Angstroms'
      IF NBAD gt 0 then begin
         if lu4 ne -1 then printf,lu4,'*  INCLUDES ',nbad,' BAD BINS'
         endif
   endif     ; ILIN
   if lu4 ne -1 then printf,lu4,'*-- '
   if not quiet then print,' -- '
   a(ic)=xl                                ;convert to wavelength
   endfor
RETURN
END
