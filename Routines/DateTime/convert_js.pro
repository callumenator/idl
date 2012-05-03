

;\\ General purpose convert from js to ...
function convert_js, js

	nt = n_elements(js)

	js2ymds, js, year, month, day, sec
	daynumber = ymd2dn(year, month, day)
	daynumber_string = string(daynumber, f='(i03)')
	jd0 = ymd2jd(year, month, day)

	month_n = intarr(nt)
	day_n = intarr(nt)
	for k = 0,  - 1 do begin
		ydn2md, year[k], daynumber[k]+1, _month_n, _day_n
		month_n[k] = _month_n
		day_n[k] = _day_n
	endfor
	jd0_n = ymd2jd(year, month_n, day_n)

	yy = dt_tm_mk(jd0, sec, f='y$')
	len = strlen(yy)
	pts = where(len eq 1, n_one)
	if n_one gt 0 then yy[pts] = '0' + yy[pts]

	mmdd = dt_tm_mk(jd0, sec, f='0n$0d$')
	yymmdd = yy + mmdd

	yy_n = dt_tm_mk(jd0_n, sec, f='y$')
	len = strlen(yy_n)
	pts = where(len eq 1, n_one)
	if n_one gt 0 then yy_n[pts] = '0' + yy_n[pts]

	mmdd_n = dt_tm_mk(jd0_n, sec, f='0n$0d$')
	yymmdd_n = yy_n + mmdd_n


	def_date_string = dt_tm_mk(jd0, sec)
	full_month_string = dt_tm_mk(jd0, sec, f='N$')
	part_month_string = dt_tm_mk(jd0, sec, f='n$')
	full_day_string = dt_tm_mk(jd0, sec, f='W$')
	part_day_string = dt_tm_mk(jd0, sec, f='w$')

	return, {year:year, $
			 month:month, $
			 day:day, $
			 sec:sec, $
			 dayno:daynumber, $
			 dayno_string:daynumber_string, $
			 jd:jd0, $
			 yymmdd:long(yymmdd), $
			 yymmdd_string:yymmdd, $
			 yymmdd_n_string:yymmdd_n, $
			 def_date_string:def_date_string, $
			 full_month_string:full_month_string, $
			 part_month_string:part_month_string, $
			 full_day_string:full_day_string, $
			 part_day_string:part_day_string }

end