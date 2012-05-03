
;\\ Alpha blend tru color images, with interleaving in the first dimension.
;\\ Alpha applies to layer2.

function alpha_blend, layer1, layer2, alpha

	l1 = (layer1)
	l2 = (layer2)

	out = (layer1)
	nd = size(alpha, /n_dimensions)
	if nd eq 3 then begin
		out[0, *, *] = bytscl((l1[0,*,*] * (1-alpha[0,*,*])) + (l2[0,*,*] * alpha[0,*,*]))
		out[1, *, *] = bytscl((l1[1,*,*] * (1-alpha[1,*,*])) + (l2[1,*,*] * alpha[1,*,*]))
		out[2, *, *] = bytscl((l1[2,*,*] * (1-alpha[2,*,*])) + (l2[2,*,*] * alpha[2,*,*]))
	endif

	if nd eq 2 then begin
		out[0, *, *] = (l1[0,*,*] * (1-alpha)) + (l2[0,*,*] * alpha)
		out[1, *, *] = (l1[1,*,*] * (1-alpha)) + (l2[1,*,*] * alpha)
		out[2, *, *] = (l1[2,*,*] * (1-alpha)) + (l2[2,*,*] * alpha)
	endif
	return, out

end