
;\\ Convert yymmdd string to year dayno floats or srtings

pro yymmdd2ydn, yymmdd, ryear, rdayno, str=str

	year = float(strmid(yymmdd, 0, 2))
	month = float(strmid(yymmdd, 2, 2))
	day = float(strmid(yymmdd, 4, 2))

	if year gt 50 then year = year + 1900 else year = year + 2000

	dayno = ymd2dn(year, month, day)

	if keyword_set(str) then begin
		ryear = string(year, f='(i0)')
		rdayno = string(dayno, f='(i3.3)')
	endif else begin
		ryear = year
		rdayno = dayno
	endelse

end