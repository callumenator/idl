;*****************************************************************************
pro mk_atlas,h,w,f0,e,wav=wav,dw=dw,yrange=yrange,smooth1=smooth1, $
    linfile1=linfile1,hcpy=hcpy,nozero=nozero,rv=rv,file=file,rec=rec, $
    title=title,helpme=helpme,stp=stp
COMMON ICDISK,ICURDISK,ICURDATA,ismdata,objfile,stdfile,idat,recno,linfile
common radialvelocity,radvel
;
if keyword_set(helpme) then begin
   print,' '
   print,'* MK_ATLAS: print spectra atlas with line identifications'
   print,'* calling sequence: MK_ATLAS,H,W,F or MK_ATLAS,file=file,rec=rec'
   print,'*'
   print,'* KEYWORDS:'
   print,'*    DW:      wavelength increment, def=10A (120% of dw plotted)'
   print,'*    FILE:    name of .ICD file. Needed if data are not passed.'
   print,'*    HCPY:    make .PS files and send to printer'
   print,'*    LINFILE: name of .lin linelist file'
   print,'*    NOZERO   if not setm draw the zero flux line'
   print,'*    REC:     record in FILE (optional)'
   print,'*    RV:      radial velocity shift to apply to lines'
   print,'*    SMOOTH:  If set, FFT smooth by this factor'
   print,'*    WAV:     Wavelength range to be plotted'
   print,'*    YRANGE:  2-element vector containing y.range'
   print,' '
   return
   endif
;
if n_elements(stp) eq 0 then stp=0
if (n_elements(linfile1) eq 0) and (n_elements(linfile) eq 0) then icursetup
if ifstring(linfile1) then linfile=linfile1(0)
nlin=(n_elements(linfile1)-1)>0
if n_elements(wav) eq 0 then wav=[10.*fix(min(w)/10.),max(w)]
if n_elements(wav) eq 1 then wav=[wav,max(w)]
if n_elements(dw) eq 0 then dw=10.
if n_elements(yrange) eq 0 then yrange=[0.,0.]
if n_elements(rv) eq 0 then radvel=0. else radvel=rv
;
if n_params() lt 3 then begin    ;spectrum not passed
   if ifstring(file) then gdat,file,h,w,f,e,rec else begin
      print,' - MK_ATLAS returning - no input found'
      return
      endelse
   endif else f=f0
;
!p.title=strtrim(byte(h(100:159)),2)
if n_elements(title) eq 1 then !p.title=!p.title+'  '+title
if keyword_set(smooth1) then fftsm,f,1,smooth1
;
w0=wav(0)-dw & w1=w0+dw*1.2
while w1 lt wav(1) do begin
   if keyword_set(hcpy) then sp,'ps'
   w0=w0+dw & w1=w1+dw
   setxy,w0,w1,yrange(0),yrange(1)
   plot,w,f
   if not keyword_set(nozero) then drlin,0
   findlin,w,noid=0,/noquery
   if nlin gt 0 then for il=0,nlin-1 do begin
      linfile=linfile1(il+1)
      findlin,w,noid=0,/noquery,/top
      linfile=linfile1(0)
      endfor
   opdate,'MK_ATLAS'
   if !d.name eq 'X' then begin
      wshow & if w1 lt wav(1) then blowup,-1 
      endif else make_hcpy,hcpy
   if stp ge 2 then stop,'MK_ATLAS(2)>>>'
   endwhile
if keyword_set(stp) then stop,'MK_ATLAS>>>'
return
end
