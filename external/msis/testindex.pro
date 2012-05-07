;;
;;	Test of geophysical indicies program
;;
;;	Author: Douglas P. Drob (drob@uap2.nrl.navy.mil)
;;			E.O. Hulburt Center for Space Reseach
;;			Naval Research Laboratory
;;			Washington, Dc 20375
;;
;;
;;

yyddd = 96103L
sec = 100.
f107a = 0.
f107 = 0.
ap = fltarr(7)
storm = 0

nrec = 15035 - 366 - 365
x = fltarr(nrec)
y = fltarr(nrec)
z = fltarr(nrec)

year = 57
day = 0
for i = 0,nrec - 1 do begin

	day = day + 1
	yyddd = year*1000L + day

	result = call_external('idlgetindex.dll','getgeoindex', $
		yyddd,sec,storm,f107a,f107,ap)

	x(i) = float(i)
	y(i) = f107
	z(i) = ap(1)
	if (f107 le 0.) then print,yyddd,year,day,f107

	leap = (year + 1900) mod 4.
	if (day ge 366 and leap eq 0) then begin
		day = 0
		print,year
		print,day
		year = year + 1
	endif

	if (day ge 365 and leap ne 0) then begin
		year = year + 1
		day = 0
	endif

endfor

plot,x,y
end
