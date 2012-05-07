;  a sorting program

newarrsize=arrsize-1

newthespecs=lonarr(newarrsize,npts)
newpkpos=dblarr(newarrsize)
newpkposerr=dblarr(newarrsize)
newintnst=fltarr(newarrsize)
newintnsterr=fltarr(newarrsize)
newbckgrnd=fltarr(newarrsize)
newbckgrnderr=fltarr(newarrsize)
newtimearr=strarr(newarrsize)
newazmtharr=intarr(newarrsize)
newelevarr=intarr(newarrsize)

j=0
for i=0,arrsize-1 do begin
  if pkpos(i) lt 4. then begin
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
  endif
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
