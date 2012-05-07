
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; calculate the Greenwich Mean Sidereal Time from
; the Julian day
;
; Note: the IDL routine juldate defines the
; reduced Julian date as:
; 
;    RJD = Julian_day - 2400000
;
; which is what is input to this function,                       
; but it uses the modified Julian date, defined
; as:
;
;    MJD = Julian_day - 2400000.5
;                       
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 17-Apr-2000

function gmst, rjd

; -------------------------------------------
; calculate modified Julian date and UT hours
; -------------------------------------------
mjd = rjd - 0.5
uthours = ( mjd mod 1.0 ) * 24.0

; ----------------------------------
; calculate time in Julian centuries
; ----------------------------------
t0 = (mjd - 51544.5) / 36525.0

; -------------------------------------
; calculate sidereal time and return it
; -------------------------------------
sidtime = 100.461 + 36000.77*t0 + 15.04107*uthours
sidtime = sidtime mod 360.0
return, sidtime


end
