;*********************************************************************
pro heliocor,mode,vhel,vlsr,tdel,x,obslat=obslat,ra=ra,dec=dec,utdat=utdat, $
   utc=utc,ha=ha,helpme=helpme,stp=stp,quiet=quiet
;compute heliocentric velocity corrections
common echelle,arr,xlen,ylen,ys,darr,sig,pflat,head,readnoise,irv,gain,dtyp,ol
if n_params(0) eq 0 then mode=0
if mode eq -1 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* HELIOCOR  -  compute heliocentric velocity correction'
   print,'* calling sequence: HELIOCOR,mode,vhel,vlsr,tdel'
   print,'*             - or: HELIOCOR,2,h,vhel,vlsr,tdel'
   print,'*    mode: 0 (default) all I/O in common header file'
   print,'*          1  pass heliocentric and LSR velocity corrections VH,VL'
   print,'*          2  pass header information'
   print,'*    vhel: heliocentric velocity correction'   
   print,'*    vlsr: velocity correction to local standard of rest'   
   print,'*
   print,'*    KEYWORDS:'
   print,'*       OBSLAT: observatory latitude. default=32'
   print,'*       UTDAT: UT date (format=[m,d,y] or yyyy.mm.dd)'
   print,'*       UTC:   UT      (format=[h,m,s])'
   print,'*       RA:    right ascension (format=[h,m,s])'
   print,'*       DEC:   declination (format=[d,m,s])'
   print,'*       HA:    hour angle (format=[h,m,s]), default=0'
   print,'* unless specified, UTDAT,UTC,RA,DEC, and HA are read from header vector'
   print,' '
   return
   end
if n_params(0) eq 5 then mode=2
if n_elements(vhel) eq 0 then vhel=0.
if n_elements(vlsr) eq 0 then vlsr=0.
if n_elements(x) eq 0 then x=-99.
if mode eq 2 then begin
   head=vhel
   vhel=vlsr
   vlsr=tdel
   tdel=x
   endif
if keyword_set(obslat) eq 0. then obslat=32. ;default latitude
dpm=[31,28,31,30,31,30,31,31,30,31,30,31]
DOY=1+15*indgen(25)
doy=[doy,366]
SRA=[280.6,297.0,312.8,327.8,342.1,356.0,9.6,23.4,37.4,52.0,67.0,82.5, $
     98.1,113.5,128.4,142.8,156.7,170.3,183.7,197.4,211.5,226.3,241.9,  $
     258.2,274.8,280.6]
for i=0,5 do sra(i)=sra(i)-360.
SDEC=[-23.08,-21.13,-17.67,-13.03,-7.6,-1.75,4.15,9.75,14.77,18.87,21.77, $
      23.27,23.23,21.68,18.77,14.68,9.73,4.2,-1.62,-7.38,-12.77,-17.42,   $
      -20.93,-23.0,-23.37,-23.08]
d=indgen(366)         ;day of year
sunra=spline(doy,sra,d)
sundec=spline(doy,sdec,d)
obslat=obslat/!radeg       ;CTIO
;
; read header information
;
if not keyword_set(utdat) then begin
   if n_elements(head) lt 12 then goto,badinp else utdat=head(10:12)
   endif
if n_elements(utdat) eq 1 then begin   ;yr.mm.dd
   utd=utdat
   utdat=intarr(3)
   utdat(2)=fix(utd)
   utd=(utd-utdat(2))*100
   utdat(0)=fix(utd)
   utdat(1)=fix((utd-utdat(0))*100)
   endif
if utdat(2) gt 1900 then utdat(2)=utdat(2)-1900
if not keyword_set(utc) then begin
   if n_elements(head) ge 15 then utc=head(13:15)
   endif
if n_elements(utc) lt 3 then utc=[0,0,0]
ut=utc
if not keyword_set(ra) then begin
   if n_elements(head) lt 42 then goto,badinp else ra=head(40:42)
   endif else begin
   if n_elements(ra) eq 1 then begin
      degtohms,ra,i,j,k
      ra=[i,j,k]
      endif
   endelse
if not keyword_set(dec) then begin
   if n_elements(head) lt 45 then goto,badinp else dec=head(43:45)
   endif else begin
   if n_elements(dec) eq 1 then begin
      degtodms,dec,i,j,k
      dec=[i,j,k]
      endif
   endelse

if not keyword_set(ha) then begin
   if n_elements(head) lt 48 then ha=[0,0,0] else ha=head(46:48)
   endif
;st=head(13:18)
;
yr=utdat(2)
fyr=utdat(0)/12.
T=(yr+fyr)/100.     ; number tropical centuries since 1900.0
;
adtec,sunra,sundec,lamsun,betasun
lamsun=lamsun/!radeg & betasun=betasun/!radeg
;
gam=281.2208D0+1.7192D0*T+.000453D0*t*t+3.33333D-6*t*t*t
gam=gam/!radeg         ;convert to radians
;
alpha=15.*ra(0)+ra(1)/4.+ra(2)/24000.   ;ra(deg)
delta=dec(0)+dec(1)/60.+dec(2)/360000.  ;dec(deg)
ha=ha(0)*15.+ha(1)/4.+ha(2)/24000.      ;ha(deg)
ha=ha/!radeg
adtec,alpha,delta,lam,beta,t0=t              ;i/o in degrees
lam=lam/!radeg & beta=beta/!radeg
;
v0=29.974D0     ;km/s
ecc=0.0167D0    ;orbital eccentricity
;
; compute solar longitude
;
case 1 of
   utdat(0) eq 1: ndays=0                ;January
   else:  ndays=total(dpm(0:utdat(0)-2))
   endcase
ndays=ndays+utdat(1)
if (((utdat(2)+2) mod 4) eq 0) and (utdat(0) gt 2) then ndays=ndays+1
ndays=fix(ndays)
;
lsun=lamsun(ndays)      ;ecliptic longitude of sun
ptarg=[alpha,delta]
delta=delta/!radeg
alpha=alpha/!radeg
;
vhel=v0*cos(beta)*(ecc*sin(gam-lam)-sin(lsun-lam))
ver=0.465*sin(ha)*cos(delta)*cos(obslat)
if not keyword_set(quiet) then $
    print,'heliocentric velocity=',vhel,' Vrot=',ver,' DOY=',ndays
vhel=vhel+ver
if n_elements(head) gt 31 then begin
   head(30)=fix(vhel)
   head(31)=fix((vhel-head(30))*1000.)
   endif
;
; correction to local standard of rest
;
sa0=18.*15./!radeg      ;apex of solar motion to RA=18h
sd0=30./!radeg          ;apex of solar motion to DEC=+30deg
vlsr=cos(sa0)*cos(sd0)*cos(alpha)*cos(delta)
vlsr=vlsr+sin(sa0)*cos(sd0)*sin(alpha)*cos(delta)+sin(sd0)*sin(delta)
vlsr=19.5*vlsr
if n_elements(head) gt 33 then begin
   head(32)=fix(vlsr)
   head(33)=fix((vlsr-head(32))*1000.)
   endif
if not keyword_set(quiet) then print,'Vlsr=',vlsr,' km/s'
;
;time delay
del=1.5E13/3.e10    ;seconds
tdel=cos(angd(ptarg(0),ptarg(1),sunra(ndays),sundec(ndays))/!radeg)*del
if not keyword_set(quiet) then print,' Time delay = ',tdel,' seconds'
;
if mode eq 2 then begin    ;reset variables
   x=tdel
   tdel=vlsr
   vlsr=vhel
   vhel=head
   endif
;
if keyword_set(stp) then stop,'HELIOCOR>>>'
return
badinp:
bell,3
print,' You must specify the values of UTDAT, UTC, RA, DEC and (optionally) HA'
print,'    via keywords if they are not in the header vector.' 
print,' Type HELIOCOR,/HELP for on-line help
if keyword_set(stp) then stop,'HELIOCOR>>>'
return
end
