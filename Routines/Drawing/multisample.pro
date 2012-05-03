


pro multisample, alpha=alpha, sm=sm, win=win

	if not keyword_set(sm) then sm = 3
	if not keyword_set(alpha) then alpha = .3

	if keyword_set(win) then begin

		image = tvrd(/true)

		talpha = float(image)
		talpha[*] = alpha

		aa_image = (image)
		si = 2*smooth(float(image), [0,sm,sm], /edge)
		aa_image = alpha_blend(aa_image, si, talpha)

		device, decomp = 1
		tv, aa_image, /true
		device, decomp = 0
 	endif

end