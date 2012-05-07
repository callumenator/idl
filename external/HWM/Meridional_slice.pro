pro crosssection

;; ===============================================================
;c
;c     Date: 4/25/99
;c
;c     Description: This program demonstrated the HWM93 call_external'
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

yyddd = 98186L    ; year and day in yyddd format, must be a long (ie. int*4)
sec = 0.  ; ut seconds (real) e.g. 8:00 ut

alt = 120.        ; altitude in km (real)
lat = 40.         ; geodetic latitude
lon = 0.		  ; geodetic longitude (can use negative values for west)

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
;; Arrays for the demo, zonal and meridional winds (0,100 km)
;; zonal mean circulation
;; ............................................................

alt = fltarr(121)
zonal = fltarr(36,121)
merid = fltarr(36,121)

;;====================================================================
;; Now run the HWM model
;;===================================================================


flags(6) = 0.  ; no diurnal tide
flags(7) = 0.  ; no semidiurnal tide
flags(13) = 0. ; no terdiurnal tide

;; You can also really see the effects of the tides by turning these back on

flags(10) = 1. ; longitudinal effects ie Stationary waves; Turn this on and off to note effect
			   ; of NMC planetary waves 1 and 2 spectral parameterization on meridional winds down low
			   ; might want to turn off for zonal means, see documentation


alt = findgen(121)
lat = findgen(36)*5. - 87.5

for j = 0,35 do begin
  for i = 0,120 do begin
 	result = call_external('d:\users\conde\main\idl\hwm\nrlhwm93.dll','nrlhwm93',/Portable, $
		yyddd,sec,alt(i),lat(j),lon,lst,f107a,f107,ap,flags,w)
	merid(j,i) = w(0)
	zonal(j,i) = w(1)
  endfor
endfor

; now with tides off (remember fortran array index starts at 1, idl at 0)


; ================================================
;  Now take a look at the results
; ================================================

!x.style = 1

!x.title = 'Latitude'
!y.title = 'Altitude (km)'

window,0
windlevels = findgen(20)*10 - 100.
!p.title = strcompress('Zonal Wind (No Tides), yyddd = ' + string(yyddd))
contour,zonal,lat,alt,nlevels = 20,levels = windlevels,c_label = string(windlevels)

window,1
windlevels = findgen(20)*2 - 20.
!p.title = strcompress('Meridional Wind (No Tides), yyddd = ' + string(yyddd))
contour,merid,lat,alt,nlevels = 20,levels = windlevels,c_label = string(windlevels)


; The
end
