
function get_zone_centers, zmap

	nzones = max(zmap) + 1

	;\\ Get the x,y positions of the zone centers for plotting
		zone_centers = intarr(nzones, 2)
		for zn = 0, nzones - 1 do begin
			pts = where(zmap eq zn, npts)
			ind = array_indices(zmap, pts)
			zone_centers(zn,0) = (max(ind(0,*))+min(ind(0,*)))/2
			zone_centers(zn,1) = (max(ind(1,*))+min(ind(1,*)))/2
			;xyouts, zone_centers(zn,0), zone_centers(zn,1), string(zn,f='(i0)'), /device, color=0
		endfor

	return, zone_centers

end