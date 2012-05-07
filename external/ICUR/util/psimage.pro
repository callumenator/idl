;******************************************************************
pro psimage,array,black=black,nbits=nbits,portrait=portrait,save=save, $
    noplot=noplot,helpme=helpme,opgrid=opgrid,gifscl=gifscl,xs=xs,ys=ys, $
    scalefact=scalefact,encapsulate=encapsulate,noscl=noscl,stp=stp, $
    color=color
common tvcoltab,r,g,b,opcol,ctnum
if n_params(0) eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* PSIMAGE - send image to HP printer for grayscale plot'
   print,'*    Calling sequence: PSIMAGE,ARRAY'
   print,'*    KEYWORDS:'
   print,'*       BLACK: set to color maxima black, default=white'
   print,'*      GIFSCL: set to transform GIF intensity scale into linear BW'
   print,'*       NBITS: number of greyscale bits (1,2,4,8), default=8'
   print,'*      NOPLOT: set to create .PS file, but do not send to printer'
   print,'*    PORTRAIT: set for portrait mode; default=landscape'
   print,'*        SAVE: name of .PS file'
   print,'*   SCALEFACT: scaling factor (1.0 =  default)'
   print,' '
   return
   endif
;
s=size(array)
if s(0) ne 2 then begin
   print,' PSIMAGE: argument must be a 2-dimensional array'
   return
   end
;
d=!d.name
a=array
if not keyword_set(encapsulate) then encapsulate=0
if not keyword_set(nbits) then nbits=8
nbits=((nbits>1)<8)
if keyword_set(gifscl) then begin
   if (n_elements(r) eq 0) or (n_elements(g) eq 0) or (n_elements(b) eq 0) $
      then gifscl=0
   endif
if keyword_set(encapsulate) then noplot=1
if keyword_set(xs) then xs0=xs
if keyword_set(ys) then ys0=ys
if not keyword_set(scalefact) then scalefact=1.
if keyword_set(gifscl) then begin
   a=fix(r(array))+fix(g(array))+fix(b(array))
   rr=r & bb=b & gg=g                  ;save GIF color table
   gc,1                                ; load BW color table
   endif
;
set_plot,'ps' 
if keyword_set(portrait) then device,/portrait else device,/landscape
if keyword_set(color) then device,/color
device,encap=encapsulate,bits_per_pixel=nbits,scale=scalefact
;
if keyword_set(black) then a=-a
if keyword_set(noscl) then tv,a else tvscl,a
!p.color=255
if keyword_set(opgrid) then plotsky,oplot=a
if keyword_set(save) then lplt,d,file=save,noplot=noplot else $
   lplt,d,noplot=noplot
if keyword_set(gifscl) then tvlct,rr,gg,bb    ;restore gif color scale
if keyword_set(stp) then stop,'PSIMAGE>>>'
return
end
