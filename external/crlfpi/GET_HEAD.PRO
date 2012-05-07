;;
PRO get_head
;;
COMMON Hdr_para, header, yy, mo, day, hh, mm, ss, stime, etime, $
       ch_a, ch_b, sum_a, sum_b, thld_a, thld_b   
;;
COMMON mtime_para, sdt, edt
;;
hdr = string(header)
print, hdr
yy = strmid(header, 0, 2)
mo = strmid(header, 3, 2)
day = strmid(header, 6, 2)
hh = strmid(header, 9, 2)
mm = strmid(header, 12, 2)
ss = strmid(header, 15, 2)
ms = strmid(header, 18, 3)
;;
ehh = strmid(header, 23, 2)
emm = strmid(header, 26, 2)
ess = strmid(header, 29, 2)
ems = strmid(header, 32, 3)
;;
sdt = fix(hh)*360. + fix(mm)*60. + fix(ss) + fix(ms)/1000.
edt = fix(ehh)*360. + fix(emm)*60. + fix(ess) + fix(ems)/1000.
;;
print, '***** OBS-PARA *****' 
print, yy, '/', mo, ' ', day, ' ', hh, ':', mm, ':', ss, '(', ms, ')', ' - ', emm, ':', ess, '(', ems, ')'
;;
stime = strmid(header, 9, 8)
etime = strmid(header, 23, 8)
;;
ch_a = strmid(header, 39, 1)
ch_b = strmid(header, 43, 1)
print, 'ch-A : ', ch_a
print, 'ch-B : ', ch_b
;;
;;sum_a = strmid(header, 56, 5)
sum_a = strmid(header, 53, 5)
;;sum_b = strmid(header, 65, 5)
sum_b = strmid(header, 59, 5)
print, 'sum-A : ', sum_a
print, 'sum-B : ', sum_b
;;
;;thld_a = strmid(header, 74, 3)
thld_a = strmid(header, 65, 3)
;;thld_b = strmid(header, 81, 3)
thld_b = strmid(header, 69, 3)
print, 'thld-A : ', thld_a
print, 'thld-B : ', thld_b
print, '********************'
;;
END












