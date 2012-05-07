;   this program is for cleaning raw laser images
;   Matt Krynicki, 11-17-99

;   Program Cleanimage

start:

file=''
imagefile=''
cleanfile=''
date=''
piece=''
othpiece=''
thtime=''
type=''
znth=''
azmth=''
dumbo=''
head=bytarr(161)
isig=bytarr(256,255)
isignew=bytarr(256,255)

print,''
print, "enter the date of the image data file"
print, "in format YYMMDD.  this should also be"
print, "the directory that the files are located in"
print,''
read, date
print,''

piece=strmid(date,1,5)
othpiece=strmid(date,3,3)

print,''
print, "enter the last three characters (numbers) of the"
print, "first image data file to begin with.  this should"
print, "be the first dark count image of the night.  e.g. 014"
print,''
read,file

print,''
print, "enter the time, in UT, of the first dark count profile,"
print, "using HR:MIN:SEC format.  e.g.  00:26:44 for 26 minutes"
print, "and 44 seconds past midnight, 13:07:09 for 7 minutes and"
print, "9 seconds past the 13th hour."
print,''
read,thtime
print,''
filenum=fix(file)

if filenum lt 10 then strfile='00'+strcompress(filenum,/remove_all)
if filenum lt 100 then strfile='0'+strcompress(filenum,/remove_all)
if filenum ge 100 then strfile=strcompress(filenum,/remove_all)

imagefile='/home/mpkryn/ivkimgarc/'+date+'/'+piece+strfile+'.raw'
cleanfile='/home/mpkryn/ivkimgarc/'+date+'/'+piece+strfile+'.cln'

openr,unit,imagefile,/get_lun,error=bad

hrs=strmid(thtime,0,2)
min=float(strmid(thtime,3,2))
sec=float(strmid(thtime,6,2))
totalsec=(min*60.)+sec
dec=strmid(strcompress(totalsec/3600.,/remove_all),2,2)
print,''
thtime=hrs+'.'+dec
print,'the time in decimal format is '+thtime
print,''

type='003'
azmth='***'
znth='**'

print,''
print,date,thtime,type,azmth,znth
print,''

openw,unit3,cleanfile,/get_lun
readu,unit,head
readu,unit,isig
close,unit
free_lun,unit

;window,3,xsize=256,ysize=255,retain=2
;loadct,41
;tv,isig

isignew=isig

isignew(0,*)=isignew(1,*)
head(0:5)=byte(date)
head(6:10)=byte(thtime)
head(11:13)=byte(type)
head(14:16)=byte(azmth)
head(17:18)=byte(znth)
writeu,unit3,head,isignew

close,unit3
free_lun,unit3

;window,1,xsize=256,ysize=255,retain=2
;tv,isignew

decision=''
print, "another image?  y/n"
print,''
read,decision
if decision eq 'y' then goto, start

end
