;*********************************************************************
pro ldetect,image,radius,annrad,x,y
common tvcom,pixf,zerr
if n_elements(pixf) eq 0 then tvinitpixf
if n_params(0) lt 2 then radius=4.
if n_params(0) lt 3 then annrad=2.*radius
if n_params(0) lt 5 then begin
   x=-1 & y=-1
   endif
if radius lt 0 then begin
   radius=abs(radius)
   iloop=1
   endif else iloop=0
iquit=0
;
while iquit ne 1 do begin
   if iloop eq 0 then iquit=1 
   tvcirc,image,radius,tcrc,kcrc,x,y    ;tcirc=counts in circle
   if zerr lt 4 then iquit=1
   ec=sqrt(tcrc)
   tvcirc,image,annrad,anncts,kann,x,y
   nann=kann-kcrc                         ;annulus bins
   bppix=float(anncts-tcrc)/float(nann)   ;back cts/pix
   bcts=bppix*float(kcrc)                 ;background in circle
   sbck=tcrc-bcts                         ;source cts-back
   esbck=sqrt(tcrc+bcts)        ;error
   sigma=sbck/esbck
   print,' '
   print,' source+background:',tcrc,'+/-',sqrt(tcrc),' cts
   print,' source:',sbck,'+/-',esbck,' cts, sigma=',string(sigma,'(F5.2)')
   print,' background counts per pixel=',bppix
   print,' source/background counts, radii:',tcrc,anncts-tcrc,' /',radius,annrad
   if iquit eq 0 then begin
      x=-1 & y=-1
      endif
   endwhile
;
return
end
