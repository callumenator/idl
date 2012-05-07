;***********************************************************
pro bits,inp
in=long(inp)
out=intarr(32)
for i=0,30 do out(31-i)=(in and 2L^i)/2L^i
print,'$(4(8I1,1X))',out
return
end
