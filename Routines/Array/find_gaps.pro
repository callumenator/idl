
;\\ Returns the number and start and end indexs of continuous blocks
;\\ of subscripts in 1-D arrays of subscripts (as returned by where command)

pro find_gaps, array, block_indxs, nblocks, min_block_length = minLen

	if not keyword_set(minLen) then minLen = 1

	asize = n_elements(array)
	nblocks = 0


	;\\ New version
	pts = [array[0]]
	for n = 1, asize - 1 do begin
		if (array(n) - array(n-1)) gt 1 then begin
			pts = [pts, array[n-1], array[n]]
		endif
	endfor

	if n_elements(pts) eq 1 then begin
		nblocks = 1
		block_indxs = intarr(1,2)
		block_indxs[0,*] = [array[0], array[asize-1]]
		return
	endif

	pts = [pts, array[asize-1]]
	npts = n_elements(pts)

	if pts[npts-1] eq pts[npts-2] then pts = pts[0:npts-2]
	if pts[0] eq pts[1] then pts = pts[1:*]
	npts = n_elements(pts)

	gPts = [0]
	for j = 1, npts - 1, 2 do begin
		if (pts[j] - pts[j-1]) ge minLen then begin
			gPts = [gPts, pts[j-1], pts[j]]
		endif
	endfor
	gPts = gPts[1:*]
	npts = n_elements(gPts)

	nblocks = npts/2
	block_indxs = intarr(nblocks, 2)
	for j = 0, nblocks - 1 do begin
		block_indxs[j,*] = gPts[j*2:j*2+1]
	endfor

;	;\\ Count the blocks
;		for n = 1, asize - 1 do begin
;			if array(n) - array(n-1) gt 1 then nblocks = nblocks + 1
;			if n eq asize - 1 and array(n) - array(n-1) ge 1 then nblocks = nblocks + 1
;		endfor
;
;	if nblocks gt 0 then begin
;		block_indxs = intarr(nblocks,2)
;		block_cnt = 0
;		block_indxs(0,0) = array(0)
;
;		;\\ Fill in the block starts and ends
;			for n = 1, asize - 1 do begin
;				if array(n) - array(n-1) gt 1 then begin
;					block_indxs(block_cnt,1) = array(n-1)
;					block_cnt = block_cnt + 1
;					block_indxs(block_cnt,0) = array(n)
;				endif else begin
;					if n eq asize - 1 then begin
;						block_indxs(block_cnt,1) = array(n)
;						block_cnt = block_cnt + 1
;					endif
;				endelse
;			endfor
;	endif else begin
;		block_indxs = 0
;	endelse
;
;END_FIND_GAPS:
end


