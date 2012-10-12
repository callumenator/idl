
;\\ Count pixels in each zone.
;\\ Keyword relative = divide by pixels in central zone

function pixels_per_zone, meta, relative=relative, zonemap=zonemap

	if not keyword_set(zonemap) then begin
		rads = [0., meta.zone_radii[0:meta.rings-1]]/100
		secs = meta.zone_sectors[0:meta.rings-1]
		zmap = zonemapper(400,400,[200,200],rads,secs,0)
	endif else begin
		zmap = zonemap
	endelse

	pix_count = fltarr(max(zmap)+1)
	for z = 0, max(zmap) do begin
		pts = where(zmap eq z, npts)
		pix_count[z] = npts
	endfor

	if keyword_set(relative) then pix_count = pix_count / pix_count[0]
	return, pix_count

end