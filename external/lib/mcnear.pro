; This procedure returns the value and index of the element in an array which is closest to a supplied value
function mcnear, par1, par2
      array = par1
	  if n_elements(par1) lt n_elements(par2) then array = par2
	  difz  = abs(par1 - par2)
	  idx   = where(difz eq min(difz))
	  idx   = idx(0)
	  return, {value: array(idx), index: idx}
end