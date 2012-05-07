
;\\ Returns the great circle length to a given point at given altitude (km) and zenith angle (degrees)

function get_great_circle_length, zenith_angle, altitude

	;\\ Calculate triangle side (cosine rule quadratic)
		re = 6356.752 			;\\ Earth radius
		b = re
		c = re + float(altitude)
		y = (180 - zenith_angle)*!dtor

		a = b*cos(y) + sqrt( (c^2.0) - (b^2.0)*(sin(y)^2.0) )

	;\\ Calculate angle at pole
		k = acos( ((b^2.0) + (c^2.0) - (a^2.0))/(2.0*b*c) )

	;\\ Distance
		dist = (re) * k

	;\\ Sine rule is simpler!
		a = asin( (re*sin(y)) / (c) )
		alpha = !pi - y - a
		dist = re * alpha

		return, dist

end