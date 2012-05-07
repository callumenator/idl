;****************************************************************************
pro sp,dev,x,y,square=square,yscale=yscale,helpme=helpme,color=color, $
    scalefactor=scalefactor,encapsulate=encapsulate,portrait=portrait
if n_params(0) eq 0 then dev=!d.name
if not ifstring(dev) then helpme=1
if keyword_set(helpme) then begin               ;help on non-string
   print,' '
   print,'* SP - set plot and viewport'
   print,'*   calling sequence: SP,device'
   print,'*            -    or: SP,device,x,y'
   print,'*         DEVICE: device name (''X'',''PS'',''TEK'') '
   print,'*            X,Y: optional x,y vectors for plotting'
   print,'*   KEYWORDS:'
   print,'*      COLOR: generate colored postscript output'
   print,'*      ENCAPSULATE: generate encapsulated postscript output
   print,'*      SQUARE: set viewport for square window'
   print,'*      YSCALE: Y axis shrinking factor (0-1, def=1)'
   print,'*'
   print,'*      effect: SET_PLOT,device'
   print,'*      if 3 parameters are passed, SP calls PLOT,X,Y and LPLT '
   print,'*      Postscript plots (!d.name=''PS'') are produced in landscape mode'
   print,' '
   return
   endif
;
land=1 & port=0
;if keyword_set(square) and keyword_set(yscale) then yscale=1
set_plot,dev
case 1 of
   strupcase(dev) eq 'PS': begin          ;PostScript
      if keyword_set(portrait) then psopen,'p',bpp=8 else device,/landscape
      if keyword_set(color) then device,/color
;print,' PS set for color'
      y0=float(!d.y_size)/!d.y_px_cm       ;in cm
      x0=float(!d.x_size)/!d.x_px_cm       ;in cm
      defrat=y0/x0
      if keyword_set(square) then scalefactor=[defrat,1.0]
      case n_elements(scalefactor) of
         1: begin
               xscale=scalefactor(0)
               yscale=scalefactor(0)
               end
         2: begin
               xscale=scalefactor(0)
               yscale=scalefactor(1)
               end
         else:
         endcase
      if n_elements(yscale) eq 1 then begin
         yscale=yscale/defrat
         if n_elements(xscale) eq 0 then xscale=1.
         if yscale gt 1. then begin
            xscale=1./yscale & yscale=1.
            endif
         if xscale gt 1. then begin
            yscale=1./xscale & xscale=1.
            endif
         if (yscale le 0.) or (yscale gt 1.) then yscale=1.
         if (xscale le 0.) or (xscale gt 1.) then xscale=1.
         ys=y0*yscale
         xs=x0*xscale
         port=0 & land=1
         if keyword_set(portrait) then begin
            port=1 & land=0
            endif
         device,ysize=ys,xsize=xs     ;,landscape=land,portrait=port
         endif   ; else device,landscape=land,portrait=port
      if not keyword_set(color) then !p.color=4
      end
   strupcase(dev) eq 'X': begin          ;X windows
      device,retain=2,/cursor_original
      end
   else:  
   endcase
;
if keyword_set(square) then sqplot else svp
if (strupcase(dev) eq 'PS') then begin
   if keyword_set(encapsulate) then begin $
      device,/encapsulate
      print,' encapsulated'
      endif else device,encapsulate=0
   endif
if n_params(0) lt 2 then return
;
; do optional plot
;
plot,x,y
if !d.name eq 'PS' then lplt                    ;return to default plot device
;
return
end
