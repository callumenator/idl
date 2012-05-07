;*****************************************************************************
pro itcent,x,y,z,c,w,tol,xcen,flag
; iterate centroid 
nloop=0
flag=1
diff=999
c1=c
xx=findgen(n_elements(x))
while diff gt tol do begin
   centrd,xx,y,z,c1-w,c1+w,xc1    
   centrd,xx,y,z,xc1-w,xc1+w,xck
;   print,xc1,xck,diff
   diff=abs(xck-xc1)
   c1=xck
   nloop=nloop+1
   if nloop gt 10 then begin
      flag=-nloop
      return
      endif
   endwhile
i=(xck+xc1)/2.
fi=fix(i)>0
xcen=x(fi)+(i-fi)*(x(fi+1)-x(fi))
flag=diff
return
end
