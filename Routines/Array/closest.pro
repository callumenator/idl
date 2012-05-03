
;\\ Find the array index for which the array value is closest to the desired value.
function closest, in_array, in_value, $
		 absolute=absolute, $
		 difference=difference, $
		 value=value

	diff = in_array - in_value
	if keyword_set(absolute) then diff = abs(diff)
	pt = (where(diff eq min(diff)))[0]
	difference = diff(pt)
	value = in_array[pt]
	return, pt

end