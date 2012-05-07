;******************************************************************
pro op_ne,h,orient=orient,length=length,origin=origin,thick=thick, $
    helpme=helpme,stp=stp
;
if (n_elements(orient) eq 0) and (n_elements(h) le 1) then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* OP_NE : overplot N/E direction vector '
   print,'* calling sequence: OP_NE,h or OP_NE,orient=orient'
   print,' '
   return
   endif
;
if n_elements(orient) eq 0 then orient=sxpar(h,'orientat')
if n_elements(length) eq 0 then length=30
if n_elements(thick) eq 0 then thick=1
if (n_elements(origin) eq 0) and (!d.name eq 'X') then begin
   a=tvrd()
   nx=(size(a))(1) & ny=(size(a))(2)
   origin=[nx-length*2,ny-length*2]
   endif
;
r=orient/!radeg
x1=origin(0)-length*cos(r)
y1=origin(1)-length*sin(r)
x2=origin(0)+length*sin(r)
y2=origin(1)-length*cos(r)
oplot,[x1,origin(0),x2]-nx/2.,[y1,origin(1),y2]-nx/2.,thick=thick
;
if keyword_set(stp) then stop,'OP_NE>>>'
return
end
