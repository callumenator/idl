
;\\ Dot product of two row vectors
function dotp, a, b
	return, total(matrix_multiply(reform(a), reform(b), /atranspose))
end