

pro plot_zone_bounds, width, rads, secs, color=color, $
								  		 ctable=ctable, $
								  		 thick=thick, $
								  		 fill=fill, $	;\\ this should be an array of colors (nzones)
								  		 offset=offset	;\\ xy offset in device coords


		if not keyword_set(color) then color = 255
		if not keyword_set(offset) then offset = [0,0]
		if not keyword_set(thick) then thick = 1

		if n_elements(ctable) ne 0 then loadct, ctable, /silent

		if not keyword_set(fill) then begin

			for r = 1, n_elements(rads) - 1 do begin
				rad = rads(r)*(width/2.)
				ang = findgen(361)*!dtor
				plots, offset[0] + width/2. + rad*cos(ang), $
					   offset[1] + width/2. + rad*sin(ang), color = color, /device, thick = thick
				if r le n_elements(rads) - 2 then begin
					zwidth = 360. / secs(r)
					a = findgen(secs(r))*zwidth*!dtor
					rinner = rads(r)*(width/2.)
					router = rads(r+1)*(width/2.)

					for s = 0, n_elements(a) - 1 do $
							plots, offset[0] + [width/2.+rinner*cos(a(s)),width/2.+router*cos(a(s))], $
								   offset[1] + [width/2.+rinner*sin(a(s)),width/2.+router*sin(a(s))], color = color, /device, thick = thick

				endif
			endfor

		endif else begin

			nzones = total(secs)
			idx = 0
			zone = 0
			xc = offset[0] + width/2.
			yc = offset[1] + width/2.
			for idx = 0, n_elements(rads) - 2 do begin

				rinner = rads[idx]*(width/2.)
				router = rads[idx+1]*(width/2.) + .1
				zwidth = 360. / secs[idx]
				angles = [findgen(secs[idx])*zwidth, 360]*!dtor

				if zone eq 0 then begin

					arc = findgen(361)*!DTOR
					x_hi = (xc + router*cos(arc))
					y_hi = (yc + router*sin(arc))
					polyfill, x_hi, y_hi, /device, color = fill[zone]

					zone ++
				endif else begin

					for k = 0, secs[idx] - 1 do begin

						arc = (findgen(100)/99) * (angles[k+1] - angles[k]) + angles[k]
						x_lo = xc + rinner*cos(arc)
						y_lo = yc + rinner*sin(arc)
						x_hi = reverse(xc + router*cos(arc))
						y_hi = reverse(yc + router*sin(arc))
						polyfill, [x_lo, x_hi], [y_lo, y_hi], /device, color = fill[zone]
						zone ++

					endfor

				endelse
			endfor
		endelse
end