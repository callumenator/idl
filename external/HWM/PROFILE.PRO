;pro profile

;; ===============================================================
;c
;c     Date: 5/23/03
;c
;c     Description: This program demonstrats the HWM93 call_external
;c 					for IDL 5.6 on Windows-2000
;c
;c     Authors:   (Driver and Win32 DLL)
;c                Douglas P. Drob (drob@uap2.nrl.navy.mil)
;c                Research Physicist
;c                Upper Atmospheric Physics Branch (Code 7643.2)
;c                E.O. Hulburt Center for Space Research
;c                Naval Research Labortory
;c                4555 Overlook Ave.
;c                Washington, DC
;c                           20375
;c
;c                (HWM-93 and MSIS-90)
;c                Alan Hedin
;c                Consultant
;c                Universities Space Research Corperation
;c                10277 Wisconsin Circle
;c                Columbia, MD
;c                            21044
;c
;c ##############################################################
;c               *** Usage Notes ***
;c ##############################################################
;c
;c   Notice:
;c
;c 		'nrlhwm93.dll' is required to be in the directory where the
;c       IDL source file resides or else the name and location must
;c       specified in the first argument of the call_external statement
;c
;c *  Distribution policy:
;c
;c         ----------------------------------------------
;c         Distribution limited to selected US government
;c         agencies only; Proprietary Information. Other
;c         requests for this source code must be refered to
;c         the performing organization.
;c         ----------------------------------------------
;c
;c		If you have this code proper acknowledgement of the authors
;c      and NRL code-7643 should be made if it is used in any operational,
;c      commercial, or scientific applications.
;c
;c                      *** Disclaimer ***
;c
;c        You are using this source at your own risk,
;c        which is provided by the authors as is. Therefore
;c        you are also responsible for the integrity of any
;c        results, especially if you make your own modifications.
;c
;c        This HWM DLL source file has been created with the Compaq
;c        visual Fortran compiler (version 6.6B) running on
;c        Windows2000. The IDL subroutine has been test under WIN32 -
;c        IDL version 5.6
;c
;c
;c  * Bugs:
;c
;c        Please report any bugs to drob@uap2.nrl.navy.mil
;c
;;####################################################################

;; =================================================================
;; Define the program variables
;; =================================================================

result = 0L       ; for book keeping should be long (ie. int*4)

;;.......................................................................
;; example of call external inputs  (also see HWM-93 FORTRAN source code)
;; Not in order
;;.......................................................................

yyddd = 98212L    ; year and day in yyddd format, must be a long (ie. int*4)
sec = 60.*60.*8.  ; ut seconds (real) e.g. 8:00 ut

alt = 120.        ; altitude in km (real)
lat = 40.         ; geodetic latitude
lon = -80.		  ; geodetic longitude (can use negative values for west)

f107a = 150.      ; average f107
f107 = 150.       ; daily f107
ap = fltarr(2)    ; Ap solar activity index
ap(0) = 4.
ap(1) = 4.

flags = fltarr(25); Control flags (see HWM-93 FORTRAN source code for usage)
flags(*) = 1.

lst = sec/3600. + lon/15.  ; local time in hours, needs to be match with lon at ut
						   ; and vice versa

;;......................................................
;; call external outputs  w(0) = meridional, W(1) = zonal
;;......................................................

w = fltarr(2)

;; .......................................................
;; Arrays for the demo, single site HWM wind profiles w/ and wo/ tides
;; ............................................................

alt = fltarr(101)
zonal = alt
merid = alt
zonal_notides = alt
merid_notides = alt

;;====================================================================
;; Now run the HWM model
;;===================================================================

for i = 0,100 do begin
	alt(i) = float(i)
	result = call_external('nrlhwm93.dll','nrlhwm93', $
		yyddd,sec,alt(i),lat,lon,lst,f107a,f107,ap,flags,w)
	merid(i) = w(0)
	zonal(i) = w(1)
endfor

; now with tides off (remember fortran array index starts at 1, idl at 0)

flags(6) = 0.  ; no diurnal tide
flags(7) = 0.  ; no semidiurnal tide
flags(13) = 0. ; no terdiurnal tide

for i = 0,100 do begin
	alt(i) = float(i)
	result = call_external('d:\users\conde\main\idl\hwm\nrlhwm93.dll','nrlhwm93', $
		yyddd,sec,alt(i),lat,lon,lst,f107a,f107,ap,flags,w)
	merid_notides(i) = w(0)
	zonal_notides(i) = w(1)
endfor

; ================================================
;  Now take a look at the results
; ================================================

!x.style = 1

!p.multi = [0,1,2]
!p.subtitle = strcompress('yyddd = ' + string(yyddd) + ' Lst = ' + string(lst))
!p.title = strcompress('Lat = ' + string(lat) + ' Long = '+ string(lon))
plot,zonal,alt,xrange = [ min(zonal)- 5.,max(zonal) + 5.],xtitle = 'Zonal Velocity (m/s)',ytitle = 'Altitude (km)'
oplot,zonal_notides,alt,linestyle = 1
plot,merid,alt,xrange = [ min(merid)- 5.,max(merid) + 5.],xtitle = 'Meridional Velocity (m/s)',ytitle = 'Altitude (km)'
oplot,merid_notides,alt,linestyle = 1

; The
end
