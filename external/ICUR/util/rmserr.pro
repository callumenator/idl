;**************************************************************************
function rmserr,x,y,ex,ey
; return error for z=sqrt(x^2+y^2)
return,sqrt(2.*(x*x*ex*ex+y*y*ey*ey))/sqrt(x*x+y*y)
end

