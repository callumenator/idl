;******************************************************************************
function twodwhere,arr,k,prt=prt
s=size(arr)
nd=s(0)
nx=s(1)
ny=s(2)
if nd gt 2 then nz=s(3)
case nd of
   2: begin
      y=long(k/nx)
      x=long(k-y*nx)
      if keyword_set(prt) then for i=0,n_elements(x)-1 $
         do print,'(',x(i),y(i),')'
      return,[[x],[y]]
      end
   3: begin
      z=k/(nx*ny)   ;ok
      y=(k-z*ny*nx)/nx
      x=(k-(z*ny-y)*nx) mod (nx)
      return,transpose([[x],[y],[z]])
      end
   else: begin
      print,' This code works for 2 or 3 dimensions'
      return,k
      end
   endcase
return,k
end
