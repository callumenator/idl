
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
t = fltarr(2)
d = fltarr(8)

lst = sec/3600. + lon/15.
ap(0) = 4.


press = fltarr(100)
alt = fltarr(100)

for i = 0,99 do begin
	press(i) = 1000.*exp(-i/4.)
	z = 0.
	result = call_external('d:\users\conde\main\idl\msis\idlmsispress.dll','msis_press2alt', $
		yyddd,sec,z,lat,lon,lst,f107a,f107,ap,d,t,press(i))
		alt(i) = z
endfor

plot_oi,press,alt,ytitle = 'Altitude',xtitle = 'Pressure',title = 'Altitude vs Pressure (MSIS 90)'

end
