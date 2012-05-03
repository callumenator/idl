
;\\ Theta is the angle (in degrees) between the new and old (orthogonal) axes,
;\\ positive if the new axes are rotated clockwise relative to the old.

function rotate_wind_gradients, dudx, dudy, dvdx, dvdy, theta

	ang = theta*!dtor

	ndel_ux = dudx*cos(ang)*cos(ang) - dudy*cos(ang)*sin(ang) - $
			  dvdx*cos(ang)*sin(ang) + dvdy*sin(ang)*sin(ang)

	ndel_uy = dudx*sin(ang)*cos(ang) + dudy*cos(ang)*cos(ang) - $
			  dvdx*sin(ang)*sin(ang) - dvdy*cos(ang)*sin(ang)

	ndel_vx = dudx*cos(ang)*sin(ang) - dudy*sin(ang)*sin(ang) + $
			  dvdx*cos(ang)*cos(ang) - dvdy*sin(ang)*cos(ang)

	ndel_vy = dudx*sin(ang)*sin(ang) + dudy*cos(ang)*sin(ang) + $
			  dvdx*cos(ang)*sin(ang) + dvdy*cos(ang)*cos(ang)

	return, reform([[ndel_ux], [ndel_uy], [ndel_vx], [ndel_vy]])

end