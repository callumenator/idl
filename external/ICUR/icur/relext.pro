;***********************************************************************
function relext,indx,w,ebmv
if n_params(0) eq 0 then indx=-1
if (indx le 0) or (n_params(0) lt 2) then begin
   print,' '
   print,'* RELEXT - relative extinctions '
   print,'* calling sequence: R=RELEXT(INDX,W,EBMV)'
   print,'* R is ratio of extinction to Savage and Mathis curve. R is logarithmic'
   print,'*  if EBMV is omitted (Relext=10^(R x E(B-V)), or linear otherwise.'
   print,'*    INDX: specification of extiction curve (see below)'
   print,'*       W: output wavelength vector'
   print,'*    EBMV: optional input E(B-V)'
   print,'*  Extinction curves:'
   print,'*     1: Galactic: Savage and Mathis,  1979.  R=3.1 ARAA 17, 73.'
   print,'*        (the extinction curve is saved; all others are relative to this)'
   print,'*     2: Galactic: Seaton,   1979.  R=3.1 M.N.R.A.S. 187, 73p.'
   print,'*     3: Galactic: Nandy et al. 1975. R=3.0. A & A 44, 195.'
   print,'*     4: Galactic: Theta 2B Ori. Bohlin and Savage, 1981 R=3.1 ApJ 249,109'
   print,'*     5: SMC:  Hutchings,  1982.  R=3.1 Ap.J. 255, 70.'
   print,'*     6: LMC:  Nandy et al. M.N.R.A.S. 196, 955.'
   print,'*     7: LMC:  Koornneef and Code (1981) Ap.J. 247, 860.'
   print,'*     8: LMC:  30 Dor Region:  Fitzpatrick, (1985) Ap.J.'
   print,'*     9: LMC:  non-30 Dor   :  Fitzpatrick, (1985) Ap.J.'
   print,' '
   if n_params(0) ge 2 then read,'enter extinction curve index',indx else return,-1
   endif
if (indx le 0) or (indx gt 9) then return,-1
ismdat=get_symbol('ISMDATA')
openr,lu1,ismdat+'relext.tab',get_lun
k=fstat(lu1)
trec=k.rec_len/4
z=assoc(lu1,fltarr(k))
w=z(0)
r=z(indx)
close,lu1
free_lun,lu1
if n_elements(ebmv) eq 0 then return,r       ;logarithmic ratio
if indx eq 1 then return,10^(-0.4*EBMV*(r+3.1))   ;S&M transmission
return,10^(ebmv*R)
end
