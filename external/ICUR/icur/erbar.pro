;*************************************************************************
PRO ERBAR,IXY,a1,a2,a3,a4,a5,a6,color=color,helpme=helpme
; ixy=1 (X), 2 (Y), 3 (X+Y) 
;
if n_params(0) lt 3 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,' * ERBAR - overplot error bars'
   print,' *   calling sequences: ERBAR,i,y,y1,y2,x,x1,x2'
   print,' *                      ERBAR,i,x,dx,y,dy'
   print,' *                      ERBAR,i,z,z1,z2,w'
   print,' *                      ERBAR,i,z,dz,w'
   print,' *      I: 1: error bar in X'
   print,' *      I: 2: error bar in Y'
   print,' *      I: 3: error bars in both coordinates'
   print,' *      X,Y: X,Y points'
   print,' *      dX,dY : 1 sigma error'
   print,' *      y1,y2,x1,x2: actual values of ends of error bars'
   print,' *      Z,W: X or Y, depending on I
   print,' *'
   print,' *   KEYWORDS:'
   print,' *      COLOR: plot color'
   print,' '
   return
   endif
if (ixy le 0) or (ixy gt 3) then return
case 1 of
   (n_params(0) eq 4) or (n_params(0) eq 3): begin
      if ixy eq 3 then return    ;invalid
      if ixy eq 1 then begin 
         x0=a1
         x1=a1-a2 & x2=a1+a2
         if n_params(0) eq 4 then y0=a3 else y0=indgen(n_elements(x0))
         y1=y0 & y2=y0
         endif else begin
         y0=a1 & y1=a1-a2 & y2=a1+a2
         if n_params(0) eq 4 then x0=a3 else x0=indgen(n_elements(y0))
         x1=x0 & x2=x0
         endelse
      end
   (n_params(0) eq 5) and (ixy lt 3): begin
      if ixy eq 1 then begin 
         x0=a1 & x1=a2 & x2=a3
         y0=a4 & y1=a4 & y2=a4
         endif else begin
         y0=a1 & y1=a2 & y2=a3
         x0=a4 & x1=a4 & x2=a4
         endelse
      end
   (n_params(0) eq 5) and (ixy eq 3): begin
      x0=a1 & x1=a1-a2 & x2=a1+a2
      y0=a3 & y1=a3-a4 & y2=a3+a4
      end
   n_params(0) eq 7 : begin
      ixy=3
      x0=a1 & x1=a2 & x2=a3
      y0=a4 & y1=a5 & y2=a6
      end
   else: begin
      print,' Invalid input'
      return
      end
   endcase
;
ix=ixy and 1
iy=ixy and 2
if !y.type eq 1 then y1=y1>10^(!y.crange(0))
;
NST=N_ELEMENTS(X0)
ny=n_elements(y)
if not keyword_set(color) then color=!p.color
if nst gt ny then begin
   if n_elements(y0) gt 0 then y0=[y0,replicate(0,nst-ny)]
   if n_elements(y1) gt 0 then y1=[y1,replicate(0,nst-ny)]
   if n_elements(y2) gt 0 then y2=[y2,replicate(0,nst-ny)]
   endif
FOR I=0L,NST-1L DO BEGIN
   if iy gt 0 then begin
      x=[x0(i),x0(i)]
      y=[y1(i),y2(i)]
      oplot,x,y,psym=0,color=color
      endif
   if ix gt 0 then begin
      x=[x1(i),x2(i)]
;      x=[x1(i)>!x.crange(0),x2(i)<!x.crange(1)]
      y=[y0(i),y0(i)]
      oplot,x,y,psym=0,color=color
      endif
   ENDFOR
RETURN
END
