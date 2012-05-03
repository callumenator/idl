

;\\ Spherical linear interpolation between two 3d UNIT vectors
function slerp, a, b, t

	sigma = acos(dotp(a,b))

	return, (sin((1-t)*sigma)/sin(sigma))*a + (sin(t*sigma)/sin(sigma))*b

end