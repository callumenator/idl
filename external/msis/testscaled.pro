pro testscaled

;=========================================================
; This program tests the MSISSCALED call external program
; Douglas P. Drob 10/07/99
;
; Tons of stuff is hardwired in
;
;=========================================================

!p.thick = 1.25


; define the program variables

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
dens = fltarr(101)
temp0 = temp
dens0 = dens

;====================================================================
; Set scalars to 1. to get the unscaled values
;====================================================================

tinfscale = 1.
tlbscale = 1.
shapescale = 1.

for i = 0,100 do begin
	alt(i) = float(i)*2.5 + 100.
	result = call_external('msis90scaled.dll','msis90scaled', $
		yyddd,sec,alt(i),lat,lon,lst,f107a,f107,ap,mass,$
		tinfscale,tlbscale,shapescale,d,t)
		temp0(i) = t(1)
		dens0(i) = d(1)
endfor
plot_oi,dens0,alt,yrange = [70.,400.]

;====================================================================
; Now step through a range of scalar values
;====================================================================

for j = 0,10 do begin

;	shapescale = .5 + j*.1
	tlbscale = 	.8 + j*.04
	print,tlbscale
;	tinfscale = .5 + j*.1

	for i = 0,100 do begin
		result = call_external('msis90scaled.dll','msis90scaled', $
			yyddd,sec,alt(i),lat,lon,lst,f107a,f107,ap,mass,$
			tinfscale,tlbscale,shapescale,d,t)
			temp(i) = t(1)
			dens(i) = d(1)
	endfor

	if (j ne 5) then oplot,dens,alt,color = 150

endfor


end
