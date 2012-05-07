;***********************************************************************
pro sqplot,image,helpme=helpme
if n_elements(image) eq 1 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* SQPLOT - set system variables to make square plot on Laser printer'
   print,'*    calling sequence: SQPLOT,image'
   print,'*       IMAGE: optional 2-d array'
   print,'*          use before CONTOUR or SURFACE'
   print,'*          if no parameter is passed, !sc2 is reset assuming square array'
   print,' '
   return
   endif
!x.window=[.2,.9]
!y.window=!x.window
xyrat=float(!d.x_size)/float(!d.y_size)
rx=!x.window(1)-!x.window(0)
ry=!y.window(1)-!y.window(0)
x0=!x.window(0) & y0=!y.window(0)
case 1 of
   xyrat eq 0.: begin
      print,' SQPLOT error: xyrat=0
      return
      end
   xyrat eq 1.:
   xyrat lt 1.: !p.position=[x0,y0,x0+rx,y0+rx*xyrat]
   xyrat gt 1.: !p.position=[x0,y0,x0+rx/xyrat,y0+rx]
   endcase
;
if n_params(0) eq 0 then return
s=size(image)
if s(0) ne 2 then return     ;not 2-d array
f=float(s(1))/float(s(2))
rx=!x.window(1)-!x.window(0)
ry=!y.window(1)-!y.window(0)
x0=!x.window(0) & y0=!y.window(0)
case 1 of
   s(1) eq s(2): return      ;scaling not necessary

   s(1) lt s(2): !p.position=[x0,y0,x0+rx,y0+rx*f]
;!x.window(1)=!x.window(0)+(!y.window(1)-!y.window(0))*f ;shorten X
   s(1) gt s(2): !p.position=[x0,y0,x0+rx/f,y0+rx]
;!y.window(1)=!y.window(0)+(!x.window(1)-!x.window(0))/f ;shorten y
   endcase
return
end
