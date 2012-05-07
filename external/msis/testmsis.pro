pro testmsis

; This program tests the MSIS call_external

result = 0L

yyddd = 98165L
sec = 0.
alt = 120.
lat = 4.56
lon = 99.53
f107a = 150.
f107 = 150.
ap = fltarr(7)
mass = 48L
t = fltarr(2)
d = fltarr(8)

lst = sec/3600. + lon/15.
ap(0) = 4.


alt = fltarr(101)
temp = fltarr(101)

for i = 0,100 do begin
	alt(i) = float(i)
	result = call_external('d:\users\conde\main\idl\msis\idlmsis.dll','msis90', $
		yyddd,sec,alt(i),lat,lon,lst,f107a,f107,ap,mass,d,t)
	temp(i) = t(1)
           print, yyddd, sec, lst
endfor

plot,temp,alt


yyddd = 98001L
for i = 0,100 do begin
	alt(i) = float(i)
	result = call_external('d:\users\conde\main\idl\msis\Idlmsis.dll','msis90', $
		yyddd,sec,alt(i),lat,lon,lst,f107a,f107,ap,mass,d,t)
	temp(i) = t(1)
endfor

oplot,temp,alt,color = 100


end
