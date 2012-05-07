;  a sorting program

newarrsize=arrsize-46

newthespecs=lonarr(newarrsize,npts)
newpkpos=dblarr(newarrsize)
newpkposerr=dblarr(newarrsize)
newintnst=dblarr(newarrsize)
newintnsterr=dblarr(newarrsize)
newbckgrnd=dblarr(newarrsize)
newbckgrnderr=dblarr(newarrsize)
newtimearr=strarr(newarrsize)
newazmtharr=intarr(newarrsize)
newelevarr=intarr(newarrsize)

j=0
for i=46,arrsize-1 do begin
;  if pkpos(i) gt 4. then begin
    newtimearr(j)=timearr(i)
    newazmtharr(j)=azmtharr(i)
    newelevarr(j)=elevarr(i)
    newintnst(j)=intnst(i)
    newintnsterr(j)=intnsterr(i)
    newbckgrnd(j)=bckgrnd(i)
    newbckgrnderr(j)=bckgrnderr(i)
    newpkpos(j)=pkpos(i)
    newpkposerr(j)=pkposerr(i)
    newthespecs(j,*)=thespecs(i,*)
    j=j+1
;  endif
endfor
pkpos=newpkpos
pkposerr=newpkposerr
timearr=newtimearr
azmtharr=newazmtharr
elevarr=newelevarr
intnst=newintnst
intnsterr=newintnsterr
bckgrnd=newbckgrnd
bckgrnderr=newbckgrnderr
thespecs=newthespecs
arrsize=newarrsize

end
