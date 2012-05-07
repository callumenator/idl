;**************************************************************************
pro ixcor,file,hv,records=records,template=template,wavelength=wavelength, $
    noplot=noplot,tv=tv,td=td,auto=auto,save=save,trim=trim, $
    helpme=helpme,stp=stp,prt=prt,voff=voff,do2=do2,halpha=halpha, $
    interact=interact,noprint=noprint,PAUSE=PAUSE, $
    debug=debug
common echelle,arr,xlen,ylen,ys,narr,carr,pflat,head,readnoise,irv,gain,ines
common orderfits,nord,ofits,nrows,wid,delb,widb,bkmode,irt
common comxy,xcur,ycur,zerr,hcdev,lu3
common vars,var1,var2,var3,var4,var5,var6,var7,var8
common dirs,fitsdir,spcdir,datdir,mfile,pdv
common icurunits,xunits,yunits,title,c1,c2,c3,ch,c4,c5,c6,c7,c8,c9
COMMON COMXY,XCUR,YCUR,ZERR,RESETSCALE,lu3
common icdisk,icurdisk,icurdata,ismdata,objfile,stdfile,userdata,recno,linfile
;
td=1
if not keyword_set(noplot) then gc,11
if n_elements(stp) eq 0 then stp=0
if keyword_set(do2) then do2=1 else do2=0
if do2 then narr1=12 else narr1=7
wlo=[6000.,6750.]
wdef=[6580.,6750.]
wha=[6400.,6700.]
if keyword_set(halpha) then wavelength=wha
if n_params(0) eq 0 then helpme=1
if n_params(0) ge 1 then begin
   if ifstring(file) eq -1 then begin
      if file ne -99 then helpme=1 else file='-99'
      endif
   endif
if keyword_set(helpme) then begin
   print,' '
   print,'* IXCOR - cross correlate two spectra (in .ICD files)'
   print,'*    calling sequence: IXCOR,file'
   print,'*       FILE: name of file to cross correlate'
   print,'*             '
   print,'*   KEYWORDS:
   print,'*       INTERACT: set to run interactively'
   print,'*       TEMPLATE: number of (sky) record'
   print,'*       RECORDS: record to process, def=all '
   print,'*       NOPLOT: set to skip plots, 0 to plot all'
   print,'*            TV: template velocity, default=0.0'
   print,'*          AUTO: set for autocorrelation'
   print,'*          SAVE: set to save cross correlations'
   print,'*          WAVELENGTH: 2-element array of wavelength range to correlate'
   print,' '
   return
   endif
;
if keyword_set(auto) then iauto=1 else iauto=0
if keyword_set(td) then itd=1 else itd=0
c=2.9979E5                            ;speed of light
next=-1
if strlen(get_ext(file) eq 0) then file=file
;if iauto eq 0 then begin      ;do cross correlation
orig_file=file
;
if itd eq 1 then next=next+100
print,' Template record: ',template
;  
iplt=1                    ;do plots
if keyword_set(noplot) then iplt=0
;
if not keyword_set(noprint) then begin
   outfile=file+'.ixcor'
   openw,lu,outfile,/get_lun
   printf,lu,' IXCOR  run at ',systime(0)
   if iauto then za='  autocorrelation' else za=''
   printf,lu,' data from file ',file,za
   if not iauto then  printf,lu,' Template file: ',template
   printf,lu,' '
   if do2 then z2=' Second' else z2=''
   if keyword_set(halpha) then printf,lu,' H-alpha correlation '
   if n_elements(wavelength) eq 2 then $
      printf,lu,' Correlation performed from ',wavelength(0),' to ', $
                  wavelength(1),' Angstroms'
   if do2 then printf,lu,z2,' Correlation performed from ',wdef(0),' to ', $
                  wdef(1),' Angstroms'
   printf,lu,' '
   z='       Vel    W    Q  '
   if keyword_set(do2) then z='         Vel1    W1    Q1       Vel2    W2   Q2  '
   printf,lu,z
   endif
;
recloop:
;
if n_elements(records) gt 0 then r=records(0)
gdat,file,head,wave,f,e,r
if n_elements(records) eq 0 then records=r
;
if iauto then begin
   ht=head & twave=wave & ft=f & et=e 
   endif else gdat,file,ht,twave,ft,et,template         ;template
;
v0=0.
z0=1.
nfits=1
arr=fltarr(narr1,2)
if keyword_set(tv) then arr(0,nfits)=-tv else arr(0,nfits)=v0 ;heliocentric velocity of template
heliocor,0,utdat=[head(10),head(11),head(12)], $
   utc=[head(13),head(14),head(15)], $
   ra=hmstodeg(head(40),head(41),head(42)/100.), $
   dec=dmstodeg(head(43),head(44),head(45)/100.)
v1=float(head(30))+float(head(31))/1000.           ;heliocentric correction
if not keyword_set(noprint) then $
   printf,lu,' data file is ',file,' with a heliocentric velocity of ',v1
z1=1.D0-v1/c
if records(0) eq template then iauto=1
if iauto then z1=1.
;
ids=strtrim(byte(head(100:160)),2)
;
print,' data file is ',file,' with a heliocentric correction of ',v1
;
if n_elements(records) eq 0 then records=1
nrecs=n_elements(records)
setxy
np=n_elements(wave)
;
for jrec=0,nrecs-1 do begin                    ;loop through records
   irec=0
   si=strtrim(records(jrec),2)
   restart:      ;**************************************
   f1=f
   f0=ft
   w0=twave*z0             ;heliocentric scale  (template)
   w1=wave*z1              ;heliocentric scale
;
; trim files
   if n_elements(trim) eq 0 then trim=25
   f1=f1(trim:np-1-trim)
   w1=w1(trim:np-1-trim)
   f0=f0(trim:np-1-trim)
   w0=w0(trim:np-1-trim)
   nkw=0
;
   if not keyword_set(interact) then interact=0
   if keyword_set(interact) then begin
      setxy
      gc,13
      !p.title='IXCOR: '+file+' r:'+si+' '+strtrim(ids(irec),2)
      ymax=max(f1)
      !y.range=[min(f1),ymax]
      plot,w1,f1
      wshow
      oplot,w0,f0*total(f1)/total(f0),color=5
      print,' mark range to correlate with cursor, q to quit, 2 to halve max'
      xcur=mean(w1) & ycur=mean(f1)/2.
      go3:
      blowup,-1
      if zerr eq 50 then begin          ;<2>
         ymax=ymax/2.
         !y.range=[min(f1),ymax]
         plot,w1,f1
         oplot,w0,f0*total(f1)/total(f0),color=5
         wshow
         goto,go3
         endif
      IF (ZERR EQ 81) OR (ZERR EQ 26) OR (ZERR EQ 113) THEN GOTO,skip
      IF (ZERR EQ 90) OR (ZERR EQ 122) THEN stop,'HXCOR>>>'
      wavelength=xcur
      blowup,-1
      wavelength=[wavelength,xcur]
      if wavelength(1) lt wavelength(0) then begin
         iw1=wavelength(1)
         wavelength(1)=wavelength(0)
         wavelength(0)=iw1
         endif
      if wavelength(1) eq wavelength(0) then wavelength=-1
      if (n_elements(wavelength) eq 2) and not keyword_set(noprint) then $
         printf,lu,' Correlation performed from ',wavelength(0),' to ', $
                  wavelength(1),' Angstroms'
print,wavelength
      skip:
      endif
;
   if n_elements(wavelength) eq 2 then $
      kw=where((w1 ge wavelength(0)) and (w1 le wavelength(1)),nkw)
   if nkw gt 2 then begin
      f1=f1(kw)
      f0=f0(kw)
      w0=w0(kw)
      w1=w1(kw)
      endif
   if do2 then begin
      kw2=where((w1 ge wdef(0)) and (w1 le wdef(1)),nkw2)
      if nkw2 gt 2 then begin
         f12=f1(kw2)
         f02=f0(kw2)
         w02=w0(kw2)
         w12=w1(kw2)
         endif else do2=0
      endif
   if n_elements(voff) eq 1 then begin
      zoff=1.+voff/c
      w2=w1*zoff
      f2=interpol(f1,w2,w1)
      f1=f2   
      if do2 then begin
         w22=w12*zoff
         f22=interpol(f12,w22,w12)
         f12=f22   
         endif
      endif
   if itd eq 1 then begin
      tdxcor,w0,f0,w1,f1,wta,xc,debug=debug
      xc=xc/max(xc)
      dw=wta(1)-wta(0)                      ;km/sec per bin
      if do2 then begin
         tdxcor,w02,f02,w12,f12,wta2,xc2 
         xc2=xc2/max(xc2)
         dw2=wta2(1)-wta2(0)                      ;km/sec per bin
         endif
      endif else crosscor,w0,f0,w1,f1,dw,xc
   nxxc=n_elements(xc)
   if n_elements(xxc) eq 0 then xxc=fltarr(nxxc,nfits)
   nxxcx=(size(xxc))(1)
   if nxxcx ne nxxc then xxc=fltarr(nxxc,nfits)
   xxc(nxxc*irec)=xc
   mxc=max(xc)
   xcenp=where(xc eq mxc)
   xcen=xc(fix(xcenp(0)+0.5))
   a=[mxc,xcen,4.,mean(xc)]
   x=findgen(nxxc)-nxxc/2.
   y=gaussfit(x,xc,a,order=1)
   k=nxxc/4.+findgen(nxxc/2)              ;second pass
   y=gaussfit(x(k),xc(k),a,order=1)
   arr(narr1*irec)=a
   if not do2 then print,irec,xcen(0),a(0),a(1),a(2)   
   mcz=a(1)*dw
   mwid=a(2)
   hv=mcz-v0
   shv=string(hv,'(F6.1)')
   qual=hxcor_q(x(k),xc(k),y,a,mcz,hv)
   if do2 then begin
      nxxc2=n_elements(xc2)
      if n_elements(xxc2) eq 0 then xxc2=fltarr(nxxc,nfits)
      xxc2(nxxc2*irec)=xc2
      mxc2=max(xc2) 
      xcenp2=where(xc2 eq mxc2)
      xcen2=xc2(fix(xcenp2(0)+0.5))
      a2=[mxc2,xcen2,4.,mean(xc2)]
      x2=findgen(nxxc2)-nxxc2/2.
      y2=gaussfit(x2,xc2,a2,order=1)
      k2=nxxc2/4.+findgen(nxxc2/2)              ;second pass
      y2=gaussfit(x2(k2),xc2(k2),a2,order=1)
;      arr2(narr1*irec)=a2
      print,irec,xcen(0),a(0),a(1),a(2),' * ',xcen2(0),a2(0),a2(1),a2(2)   
      mcz2=a2(1)*dw
      mwid2=a2(2)
      hv2=mcz2-v0
      shv='('+string(hv,'(F6.1)')+', '+string(hv2,'(F6.1)')+')'
      qual2=hxcor_q(x2(k2),xc2(k2),y2,a2,mcz2,hv2)
      endif
   if iplt eq 1 then begin
      setxy
      !p.title='IXCOR: '+file+': record= '+si+' velocity= '+shv
      plot,x(k)*dw,xc(k),psym=10
      oplot,x(k)*dw,y,psym=0,color=1
      if do2 then oplot,x2(k2)*dw,y2,psym=0,color=2
      if do2 then oplot,[a2(1),a2(1)]*dw,!y.crange,psym=0,color=5
      wshow
      endif
;
   if not keyword_set(noprint) then begin
      printf,lu,ids
      endif
   print,z
   arr(0,irec)=mcz
   arr(1,irec)=hv
   arr(2,irec)=mwid
   arr(3,irec)=next      ;type of template
   arr(6,irec)=dw      ;type of template
   IF DO2 THEN BEGIN
      arr(7,irec)=mcz2
      arr(8,irec)=hv2
      arr(9,irec)=mwid2
      arr(10,irec)=next      ;type of template
      arr(11,irec)=dw2      ;type of template
      endif
   tw_flag=0
   if interact eq 1 then begin
      bell
IF N_ELEMENTS(PAUSE) EQ 1 THEN WAIT,PAUSE
      print,' *** TWEAK_HXCOR: interactive fit, ? for help'
      print,' '
      tweak_hxcor,0,irec,xxc,x,arr,ids,tw_flag
      endif
   if tw_flag eq 1 then goto,restart
   if keyword_set(stp) then stop
   endfor     ;irec
if (interact eq 1) and (nrecs eq 1) then begin
   rrec:
   records=''
   rEAD,PROMPT=' Do another star? enter record. ',records
   if strlen(records) eq 0 then records=-1
   if strupcase(records) eq 'Z' then begin
      stop,'IXCOR>>>'
      goto,rrec
      endif
   records=fix(records)
   if records ge 0 then goto,recloop
   endif
;
n0=0 & n1=0 & nc=0 & hc=0 & h1=0 & h0=0              ;save memory
if not keyword_set(noprint) then begin
   close,lu & free_lun,lu
   endif
if keyword_set(prt) then spawn_print,outfile else $
   if not keyword_set(noprint) then print,' Output is in ',outfile
if keyword_set(save) then begin
   if ifstring(save) then fsave=save else fsave=file0+'_xcor'
   if keyword_set(do2) then save,arr,x,xxc,x2,xxc2,ids,file=fsave+zw+'.sav' $
      else save,arr,x,xxc,x2,xxc2,ids,file=fsave+zw+'.sav'
   print,' Correlations saved to ',fsave,'.sav'
   endif
!c=-1
return
end
