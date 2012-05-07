;**********************************************************************
pro icurspc,h,w,f,e
;
; read .SPC data file and create ICUR vectors
;
common dirs,fitsdir,spcdir,datdir
common echelle,arr,xlen,ylen,ys,narr,carr,pflat,head,readnoise,irv
common icdisk,icurdisk,icurdata,ismdat
spcdir=''
spcfil=''
k=strpos(icurdata,'.')
spcroot=strmid(icurdata,0,k)
read,' enter spcdir (e.g., apr05)',spcdir
spcdir=spcroot+'.ech.spc.'+spcdir+']'
read,' enter .SPC file name',spcfil
getspc,spcfil
proc=head(1)
irv=rdbit(proc,8)
read,' which order',m
getwav,m,w
getdvect,m,f,e
h=head
return
end
