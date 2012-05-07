;   this program is to read and analyze images from the trailer FPI
;   using Mark's routines.
;   Matt Krynicki, 09-14-99.

pro readlaser,isig

laserfile=''
date=''
thtime=''
type=''
znth=''
azmth=''
head=bytarr(161)
isig=uintarr(256,255)

fpath='c:/wtsrv/profiles/mpkryn/imagefiles/'

laserfile=pickfile(path=fpath, filter='*.cln', file=fname, get_path=fpath, $
    title="Select the laser file to fit parameters to:", /must_exist)

openr,unit,laserfile,/get_lun
readu,unit,head
readu,unit,isig
close,unit
free_lun,unit

date=string(head(0:5))
thtime=string(head(6:10))
type=string(head(11:13))
azmth=string(head(14:16))
znth=string(head(17:18))

return

end