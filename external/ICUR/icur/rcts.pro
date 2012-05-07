;**********************************************************************
function rcts,image,scale
print,' place cursor on one side of region (4 times)'
tvrdc,x0,y0,1
tvrdc,x1,y1,1
tvrdc,x2,y2,1
tvrdc,x3,y3,1
x=[x0,x1,x2,x3]/scale
y=[y0,y1,y2,y3]/scale
x0=min(x) & x1=max(x)
y0=min(y) & y1=max(y)
print,x0,y0,x1,y1
t=image(x0:x1,y0:y1)
tvplot,scale*[x0,x0,x1,x1,x0],[y0,y1,y1,y0,y0]*scale
print,total(t),mean(t)
return,t
end
