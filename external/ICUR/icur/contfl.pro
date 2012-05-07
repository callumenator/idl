;**************************************************************************
PRO CONTFL,file,RECS,wmin,wmax,fluxes,out=out,helpme=helpme,stp=stp,plt=plt, $
    hcpy=hcpy,abdor=abdor,title=title,two=two
;
if n_params(0) lt 2 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* CONTFL - measure continuum fluxes'
   print,'*    calling sequence: CONTFL,FILE,RECS,wmin,wmax,f'
   print,'*       FILE: name of data file'
   print,'*       RECS: record numbers to be measureD, -1 for all'
   print,'*       WMIN,WMAX: bandpass(es) to be integrated'
   print,'*       F: output integrated fluxes'
   print,'*'
   print,'*   KEYWORDS:'
   print,'*      OUT: set to print listing'
   print,' '
   return
   endif
;
if not ifstring(file) then begin
   print,' file must be a string'
   return
   endif
S=n_elements(RECS)
IF S EQ 1 THEN BEGIN   ;1 ENTRY
   T=RECS
   RECS=INTARR(1)+T
   ENDIF
if recs(0) Le -1 then recs=INDGEN(GET_NSPEC(FILE))
N=N_ELEMENTS(RECS)
PRINT,N,' RECORDS TO BE MEASURED'
fluxes=fltarr(n,3)
jd=dblarr(n)
;
if n_params(0) eq 2 then begin
   WMIN=-1.
   WMAX=-1.
   READ,' ENTER PAIRS OF WAVELENGTHS, -1 TO END'
   READ,WMIN,WMAX
   IF WMIN EQ -2 THEN BEGIN   ;swp continuua
      WMIN=[1350.,1450.,1570.,1680.]
      WMAX=[1390.,1500.,1620.,1730.]
      GOTO,BAIL
      ENDIF
   if WMIN eq -3 then begin   ;MgII basal fluxes
      wmin=[2789.5,2793.5,2800.5,2803.]
      wmax=wmin+4.
      endif
   IF WMIN LT 0. THEN GOTO, BAIL
   while wmin gt 0. do begin
      read,w1,w2
      wmin=[wmin,w1]
      wmax=[wmax,w2]
      endwhile
   endif
BAIL:
if n_elements(wmin) eq 1 then begin
   wmin=wmin+fltarr(1)
   wmax=wmax+fltarr(1)
   endif
;
ffmt='(F9.3)'
tfmt='(E11.3)'
if keyword_set(out) then BEGIN
   IF IFSTRING(out) then ofile=out else ofile='contfl'
   if strlen(get_ext(ofile)) eq 0 then ofile=ofile+'.lst'
   OPENW,lu,ofile,/get_lun 
   endif else lu=-1
PRINTF,lu,' CONTINUUM FLUX MEASUREMENTS'
printf,lu,' Data from ',file
L=WHERE (WMIN GT 0.)
L=MAX(L)
PRINTF,lu,' The ',L+1,' wavelengths ranges are:'
for i=0,l do printf,lu,string(wmin(i),ffmt),string(wmax(i),ffmt)
printf,lu,' '
FOR I=0,N-1 DO BEGIN
   GDAT,file,H,W,F,E,recs(i)
   IF N_ELEMENTS(H) LT 2 THEN GOTO,DONE
   juldate,[1900+h(12),h(10),h(11),h(13),h(14)],jdy
   jd(i)=jdy
   IF h(3) le 4 THEN BEGIN
      CAMERA=STRMID('     LWP LWR SWP SWR',H(3)*4,4)
      image=h(4)
      if image lt 0 then image=image+65636L
      PRINTF,lu,'Record',RECS(I),' IUE camera=',H(3),' image=',image
      endif else BEGIN
    printf,lu,'Record',RECS(I),' NCAM=',string(H(3),'(I4)'), $
       ': ',STRtrim(BYTE(H(100:159)>32),2)
      endelse
   FOR J=0,L DO BEGIN
      IF ((WMIN(J) GT  MAX(W)) OR (WMAX(J) LT  W(0))) THEN GOTO,SKIP
      i1=xindex(w,wmin(j))                  ;TABINV,W,WMIN(J),I1
      i2=xindex(W,WMAX(J))
      I1=FIX(I1+0.5) & I2=FIX(I2+0.5)
      I2=I2+1
      TF=TOTAL(F(I1:I2))*(WMAX(J)-WMIN(J))/(I2-I1)
      k=i1+indgen(i2+1-I1)
      TFA=TF/(WMAX(J)-WMIN(J))
      BADE=E(I1:I2)
      NBADE=WHERE(BADE LE -1600,count)
      IF count gt 0 THEN NB=N_ELEMENTS(NBADE) ELSE NB=0
      z=string(WMIN(J),ffmt)+string(WMAX(J),ffmt)
      Z=Z+' Flux,Flux/A='+string(TF,tfmt)+' '+string(TFA,tfmt)+'  '
      case h(33) of
         30: begin
             k0=where(e eq 0,nk)
             if nk gt 0 then begin
                e(k0)=1.
                eb=f/e
                for ik=0,nk-1 do eb(k0)=(eb((k0-1)>0)+eb(k0+1))/2.
                endif else eb=f/e
             tfe=total(sqrt(eb(k)*eb(k)))/(n_elements(k)-1)
             end
         40: tfe=total(sqrt(e(k)*e(k)))/(n_elements(k)-1)
         else: tfe = 0.
         endcase
      if j eq 0 then begin
         fluxes(i,0)=tf & fluxes(i,1)=tfa & fluxes(i,2)=tfe
         endif
      if h(3) le 4 then $
           z=z+STRING(NB,'(I3)')+' points of'+STRING(I2,'(I4)')+' are saturated'
      PRINTF,lu,'Range:',z
      SKIP:
      ENDFOR
   ENDFOR
DONE:
;
if n_elements(hcpy) gt 0 then plt=1
if keyword_set(plt) then begin
   x=indgen(n)
   !x.title='!6 index'
   ztitle='!6 CONTFL'
   y=fluxes(*,0)
   eb=fluxes(*,2)
   if keyword_set(abdor) then begin
      phase0=2444296.575D0 & period=0.51479D0
      jd=jd+2400000.0D0
      cycle=(jd-phase0)/period
      x=cycle-long(cycle(0))
      !x.title='!6 phase'
      ztitle='!6 AB Dor' 
      if keyword_set(two) then begin
         x=[x,x+1.] & y=[y,y] & eb=[eb,eb]
         endif
      endif
   if n_elements(title) eq 0 then !p.title=ztitle else !p.title=title
   if n_elements(hcpy) gt 0 then sp,'ps'
   plot,x,y,/ynozero
   erbar,2,y,eb,x
   if !d.name eq 'X' then wshow
   make_hcpy,hcpy
   endif
;
if keyword_set(out) then begin
   CLOSE,lu
   free_lun,lu
   print,' Listing is in ',ofile
   endif
if keyword_set(stp) then stop,'CONTFL>>>'
RETURN
END
