;***********************************************************
function sinfunc,x,params
; x=phase (0-1)
model=params(0)*sin((x+params(1))*2.*!pi)
return,model
end
