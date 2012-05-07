head = bytarr(161)
isig = bytarr(256,255)
thefile=''
filepath = 'C:\Cal\IDLSource\Code\frng_img\nice_raw_images\'

load_pal,culz,idl=[3,1]

print,'input the filename'
print,'do not include the .cln file extension'
print,''
read,thefile

openr, unit, filepath+thefile+'.cln', /get_lun
readu, unit, head
readu, unit, isig
close, unit
free_lun, unit

window,/free, xsize=256, ysize=255

tvscl, isig

end