;*****************************************************************************
pro linterpl,vect,k1,k2,sz
if n_params(0) lt 4 then sz=1
n=(sz-1)/2
if sz eq 1 then n=0
nm=n_elements(vect)-1
if k1 le 0 then v1=median(vect(0:n-1)) else $
     v1=mean(vect((k1-n)>0:((k1+n)<nm)>0))
if k2 ge nm then v2=median(vect(nm-n+1:nm)) else $
      v2=mean(vect(((k2-n)>0)<nm:((k2+n)<nm)>0))
np=(k2-k1+1)<(nm-k1+1)
v=v1+(v2-v1)/np*findgen(np)
vect(k1>0)=v
return
end
