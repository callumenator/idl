;***************************************************************
function lint,vect,index     ;linear interpolation routine
if n_params(0) lt 2 then return,-1    ;insufficient parameters
if n_elements(vect) lt 2 then return,-1   ;need at least 2 points
np=n_elements(vect)
ni=n_elements(index)
if ni gt 1 then ind=index else ind=fltarr(1)+index
output=ind
for i=0,ni-1 do begin     ;loop through indices
   jind=fix(ind(i))
   case 1 of
      (ind(i) eq jind) and (ind(i) ge 0) and (ind(i) le (np-1)): $
           output(i)=vect(jind)    ;no interpolation needed
      ind(i) lt 0: output(i)=vect(0)+ind(i)*(vect(1)-vect(0))
      ind(i) gt (np-1): output(i)=vect(np-1)+ind(i)-(np-1)*(vect(np-1)-vect(np-2))
      else: output(i)=vect(jind)+(ind(i)-jind)*(vect(jind+1)-vect(jind))
      endcase
   endfor
if ni eq 1 then output=output(0)   ;convert to scalar
return,output
end
