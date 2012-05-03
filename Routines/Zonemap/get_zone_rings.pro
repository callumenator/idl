
function get_zone_rings, inZenAngs

	uzen = get_unique(inZenAngs)
	ring = inZenAngs
	ring[*] = 0
	for j = 0, n_elements(ring) - 1 do begin
		pts = where(uzen eq inZenAngs[j])
		pts = pts[0]
		ring[j] = pts
	endfor
	return, ring

end