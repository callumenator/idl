
pro hires_bin_power

	restore, 'c:\cal\idlsource\newalaskacode\davis\hiresvertical\power_data.idlsave'

	nxbins = 50.
	nybins = 50.

	tr = [min(all_time), max(all_time)]
	dx = (tr[1]-tr[0])/nxbins

	pr = [min(all_period), max(all_period)]
	dy = (pr[1]-pr[0])/nybins

	bin = fltarr(nxbins, nybins)

	for i = 0, nxbins - 1 do begin
	for j = 0, nybins - 1 do begin

		pts = where(all_time ge tr[0] + i*dx and $
					all_time lt tr[0] + (i+1)*dx and $
					all_period ge pr[0] + j*dy and $
					all_period lt pr[0] + (j+1)*dy, npts)

		if npts gt 3 then bin[i,j] = median(all_power[pts])

	endfor
	endfor

	stop

end