
pro zonemap_tester

	rads =  [.0, .16, .27, .39, .51,  .63, .75, .87, .99]
	secs =  [1,   6,  8,  12, 16,  20, 24, 28]

	;rads = [0, 0.1 + (findgen(11)/10.) * (0.99 - 0.1)]
	;secs = [1, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44]

	nums = secs
	nums[0] = 0
	for n = 1, n_elements(secs) - 1 do nums(n) = total(secs(0:n-1))

	zmap = zonemapper(512,512,[256,256], rads, secs, nums)
	bounds = get_zone_bounds(zmap)

	window, 0, xs = 512, ys = 512
	print, max(zmap) + 1
	zmap[where(bounds eq 1)] = max(zmap) + 2

	loadct, 39
	tvscl, zmap

	print, rads
	print, secs

end