
; ==================================================================
;
; Example IDL code to demonstrate the HWM07 call external functionality
;
; Douglas P. Drob, NRL 7643.2
;
; ===================================================================

;; =================================================================
;; Define the program variables
;; =================================================================

result = 0L       ; for book keeping should be long (ie. int*4)

;;.......................................................................
;; example of call external inputs  (also see HWM-93/HWM08 FORTRAN source code)
;; Not in order
;;.......................................................................

yyddd = 98091L    ; year and day in yyddd format, must be a long (ie. int*4)
sec = 60.*60.*12.0  ; ut seconds (real) e.g. 8:00 ut

alt = 120.        ; altitude in km (real)
lat = 60.         ; geodetic latitude
lon = 0.		  ; geodetic longitude (can use negative values for west)

f107a = 100.      ; average f107
f107 = 100.       ; daily f107
ap = fltarr(2)    ; Ap solar activity index
ap(0) = 4.
ap(1) = 4.

lst = sec/3600. + lon/15.  ; local time in hours, needs to be match with lon at ut
						   ; and vice versa

;;......................................................
;; call external outputs  w(0) = meridional, W(1) = zonal
;;......................................................

w = fltarr(2)

;; .......................................................
;; Arrays for the demo, single site HWM wind profiles w/ and wo/ tides
;; ............................................................

alt = fltarr(201)
zonal93 = alt
merid93 = alt
zonal = alt
merid = alt

dz = 2.

;;====================================================================
;; Now run the HWM model
;;===================================================================
dir = 'C:\cal\IDLSource\Code\HWM\Win32HWM07+\'

etmod = dir + 'hwm07+.dll'

cd, 'C:\cal\IDLSource\Code\HWM\Win32HWM07+'

for i = 0,200 do begin
	alt(i) = float(i)*dz
    result = call_external(etmod,'hwm93', $
        yyddd,sec,alt(i),lat,lon,lst,f107a,f107,ap,w)
 	merid93(i) = w(0)
	zonal93(i) = w(1)
    result = call_external(etmod,'hwm07', $
       yyddd,sec,alt(i),lat,lon,lst,f107a,f107,ap,w)
    merid(i) = w(0)
    zonal(i) = w(1)
endfor

; ================================================
;  Now take a look at the results
; ================================================

!x.style = 1

!p.multi = [0,1,2]
!p.subtitle = strcompress('yyddd = ' + string(yyddd) + ' Lst = ' + string(lst))
!p.title = strcompress('Lat = ' + string(lat) + ' Long = '+ string(lon))
plot,zonal,alt,xrange = [ min(zonal)- 25.,max(zonal) + 25.], $
    xtitle = 'Zonal Velocity (m/s)',ytitle = 'Altitude (km)'
oplot,zonal93,alt,color=150

plot,merid,alt,xrange = [ min(merid)- 25.,max(merid) + 25.], $
    xtitle = 'Meridional Velocity (m/s)',ytitle = 'Altitude (km)'
oplot,merid93,alt,color=150

;The
end
