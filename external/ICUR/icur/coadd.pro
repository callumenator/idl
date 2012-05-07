;**********************************************************************
PRO COADD,W,F,E,nbin,error=error,wave=wave,helpme=helpme 
     ;COADD DATA INTO COARSER BINS
common com1,h,IK,IFT,NSM,C,NDAT,IFSM,KBLO,H1,ipdv,ihcdev
npar=n_params(0)
if npar eq 0 then helpme=1
if npar eq 1 then begin
   if n_elements(w) le 2 then helpme=1
   endif
if keyword_set(helpme) then begin
   print,' '
   print,'* COADD - coadd bins together'
   print,'*    calling sequence: COADD,W,F,E,NBINS, or COADD,W,F,NBINS,'
   print,'*                      or COADD,W,NBINS, or COADD,W'
   print,'*       W,F,E : 1-3 variables. if 2 or 3 are passed, first is treated'
   print,'*               as a wavelength or a time'
   print,'*               a mean F is returned; E returns minimum of E'
   print,'*       NBINS: if the last parameter is an integer, it is the'
   print,'*              number of bins to coadd, otherwise input will be requested'
   print,'*'
   print,'* KEYWORDS:'
   print,'*    ERROR: if set, W is treated as errors and added in quadrature'
   print,'*    WAVE:  if set, W is treated as a wavelength vector'
   print,' '
   return
   endif
;
if n_elements(h) lt 33 then h33=0 else h33=h(33)
if n_params(0) lt 4 then nbin=-1 else nbin=abs(fix(nbin))>1
case 1 of
   npar eq 2: if n_elements(f) eq 1 then nbin=abs(fix(f))>1
   npar eq 3: if n_elements(e) eq 1 then nbin=abs(fix(e))>1
   else:
   endcase
if nbin ne -1 then nvars=npar-1 else nvars=npar     ;number of variables passed
;
if nbin eq -1 then begin
   PRINT,' '
   READ,' HOW MANY BINS TO COADD? ',NBIN
   endif
IF NBIN LE 1 THEN RETURN
;
np=n_elements(w)
if np le 1 then np=n_elements(f)
S=np/NBIN
tw=w
;
case 1 of
   keyword_set(error): begin       ;vector is SNR vector
      w=fltarr(s)
      ii=nbin*indgen(s)
      for i=0,nbin-1 do w=w+tw(ii+i)*tw(ii+i)
      w=sqrt(w)/float(nbin)
      end
;
   keyword_set(wave): begin     ;wavelength or time vector
      i=indgen(s)*nbin
      w=tw(i)
      end
;
   nvars eq 1: begin    ;only one vector passed
      w=fltarr(s)
      ii=nbin*indgen(s)
      for i=0,nbin-1 do w=w+tw(ii+i)
      w=w/float(nbin)
      end
;
   (nvars gt 1) and (n_elements(w) gt 1): begin     ;wavelength or time vector
      i=indgen(s)*nbin
      w=tw(i)
      end
   nvars ge 2: begin
      tf=f
      F=FLTARR(S)
      ii=nbin*indgen(s)
      for i=0,nbin-1 do f=f+tf(ii+i)
      f=f/float(nbin)
      end
   (nvars eq 3) and (n_elements(e) gt 1): begin
      if (h33 eq 30) or (h33 eq 40) then te=e*e else te=e
      e=FLTARR(S)
      ii=nbin*indgen(s)
      for i=0,nbin-1 do e=e+te(ii+i)
      case 1 of
         h33 eq 30: e=sqrt(e)           ;add S/N vectors
         h33 eq 40: e=sqrt(e)/float(nbin)
         else:
         endcase
      end
   endcase
;
if n_elements(h) gt 52 then h(53)=nbin
RETURN
END
