PRO R_data, dfname, d_err, dd_a, dd_b
;;
COMMON Hdr_para, header, yy, mo, day, hh, mm, ss, stime, etime, $
       ch_a, ch_b, sum_a, sum_b, thld_a, thld_b
;;
header = bytarr(256)
dd_a = intarr(512, 480)
dd_b = intarr(512, 480)
;;
ON_IOERROR, no_data
;;
close, 1
openr, 1, dfname
readu, 1, header
;;
get_head
;;
IF ch_a EQ '1' THEN BEGIN
;   dummy = bytarr(1)
;   readu, 1, dummy
   readu, 1, dd_a
;   dd_a = ishft(dd_a, 8) + ishft(dd_a, -8)
;   dd_a = rotate(dd_a, 7)
ENDIF ELSE BEGIN
   dd_a(*, *) = 0
ENDELSE
   ;;
IF ch_b EQ '1' THEN BEGIN
;   dummy = bytarr(1)
;   readu, 1, dummy
   readu, 1, dd_b
;   dd_b = ishft(dd_b, 8) + ishft(dd_b, -8)
;   dd_b = rotate(dd_b, 7)
ENDIF ELSE BEGIN
   dd_b(*, *) = 0
ENDELSE
;;
close, 1
d_err = 0
RETURN
;;
no_data :
;;
close, 1
d_err = 1
RETURN
;;
END









