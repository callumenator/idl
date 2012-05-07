;*****************************************************
pro drlin,w,ls=ls,COLOR=COLOR,vertical=vertical,helpme=helpme,thick=thick, $
    identity=identity
  ; PROCEDURE DRLIN TO DRAW LINE AT LEVEL W
if keyword_set(helpme) then begin
   print,' '
   print,'* DRLIN - draw horizontal line on plot '
   print,'* calling sequence: DRLIN,Y '
   print,'*    Y: height of line, default=0'
   print,'* '
   print,'*    KEYWORD:'
   print,'*       IDENTITY: draw line of slope 1.
   print,'*       LS:       linestyle value, default=0'
   print,'*       COLOR:    color of line, default=!p.color'
   print,'*       VERTICAL: draw vertical line'
   print,' '
   return
   endif
if n_elements(w) eq 0 then w=0.            ;default
w=w(0)
do1=0
;
case 1 of
   keyword_set(identity): begin
      ll=min(!x.crange)<min(!y.crange)
      ur=max(!x.crange)>max(!y.crange)
      x=[ll,ur] & y=x
      do1=1
      end
   keyword_set(vertical): begin
      yt=!x.type 
      yrange=!x.crange 
      xt=!y.type
      xrange=!y.crange
      end
   else: begin
      yt=!y.type
      xt=!x.type
      yrange=!y.crange
      xrange=!x.crange
      end
   endcase
;
if not do1 then begin
   if (yt eq 1) and (w le 0.) then return ; out of bounds
   y1=yrange(0) & y2=yrange(1)
   if y2 lt y1 then begin
      y2=yrange(0) & y1=yrange(1)
      endif
   case 1 of           ;return if out of bounds
      yt eq 1: IF (alog10(W) GT Y2) OR (alog10(W) LT Y1) THEN RETURN
      else:         IF (W GT Y2) OR (W LT Y1) THEN RETURN
      endcase
   if xt eq 1 then x=10^(xrange) else X=xrange
   Y=X*0.+W
   if keyword_set(vertical) then begin
      t=x & x=y & y=t
      endif
   endif
if not keyword_set(ls) then ls=0
;if not keyword_set(color) then color=!p.color
if n_elements(thick) eq 0 then thick=1
OPLOT,X,Y,psym=0,linestyle=ls,color=color,thick=thick
return
END
