;===============================================================================
;
;    Make a color scale bar for image plots:

pro mccolbar, barbox, loshade, hishade, lodat, hidat, $
              parname=parname, units=units, $
              color=color, thick=thick, charsize=charsize, format=fmt, $
              horizontal=horizontal, match=match, both_units = both_units, $
              rgb_vector = rgb_vector, reserved_colors=reserved_colors
               
      if not(keyword_set(parname))  then parname=''
      if not(keyword_set(units))    then units=''
      if not(keyword_set(color))    then color=0
      if not(keyword_set(thick))    then thick=1
      if not(keyword_set(charsize)) then charsize=1
      if (not(keyword_set(fmt)))    then fmt = '(g14.4)'
      if not(keyword_set(reserved_colors)) then reserved_colors = 0
     
     posisave    = !p.position
     !p.position = barbox
     lopix = convert_coord(!p.position(0), !p.position(1), /normal, /to_device)
     hipix = convert_coord(!p.position(2), !p.position(3), /normal, /to_device)

     if keyword_set(horizontal) then begin
        npix = hipix(1) - lopix(1)
        nlev = hipix(0) - lopix(0)
     endif else begin
        nlev = hipix(1) - lopix(1)
        npix = hipix(0) - lopix(0)
     endelse
     if !d.name eq 'PS' then begin
        npix = 200*npix/nlev
        nlev = 200
     endif
     
     if not(keyword_set(match)) then begin
        map  = loshade + indgen(nlev+1) * (float(hishade - loshade - 1)/(nlev+1))
     endif else begin
        key  = intarr(n_elements(match.r))
        sel  = indgen(1 + hishade - loshade) + loshade
        tvlct, r, g, b, /get
        for j=0,n_elements(match.r)-1 do begin
            err  = abs(match.r(j) - float(r(sel))) + $
                   abs(match.g(j) - float(g(sel))) + $
                   abs(match.b(j) - float(b(sel)))
            best = where(err eq min(err))
            key(j) = best(0) + loshade
        endfor
        map = congrid(key, nlev+1)
     endelse
     
     if keyword_set(rgb_vector) then begin
         tvlct, r,g,b, /get
         loadct, 0, /silent
         mapr = (bytarr(npix+1) + 1)#congrid(rgb_vector.red,   nlev+1)
         mapg = (bytarr(npix+1) + 1)#congrid(rgb_vector.green, nlev+1)
         mapb = (bytarr(npix+1) + 1)#congrid(rgb_vector.blue,  nlev+1)
	 if keyword_set(horizontal) then begin
	    mapr = transpose(mapr)
	    mapg = transpose(mapg)
	    mapb = transpose(mapb)
	 endif
	 if !d.n_colors gt 256 then begin
  	    tv, [[[mapr]], [[mapg]], [[mapb]]], !p.position(0), !p.position(1), /normal, $
	         xsize=barbox(2) - barbox(0), ysize=barbox(3) - barbox(1), true=3
	 endif else begin
	    tv, color_quan(mapr, mapg, mapb, r, g, b, cube=6) + reserved_colors, !p.position(0), !p.position(1), /normal, $
	         xsize=barbox(2) - barbox(0), ysize=barbox(3) - barbox(1)
	 endelse
         tvlct, r,g,b
     endif else begin
	 map  = (bytarr(npix+1) + 1)#map
	 if keyword_set(horizontal) then map = transpose(map)
	 tv, map, !p.position(0), !p.position(1), /normal, $
	      xsize=barbox(2) - barbox(0), ysize=barbox(3) - barbox(1)
     endelse

     lolbl = strcompress(parname  + string(lodat, format=fmt)) + units
     hilbl = strcompress(parname  + string(hidat, format=fmt))
	 if keyword_set(both_units) then hilbl = hilbl + units
     plot,  /nodata, [0,hishade-loshade], xstyle=4, ystyle=4, $
             color=color, xthick=thick, ythick=thick, /noerase
                         
     if keyword_set(horizontal) then begin
           AXIS, xaxis=0, xstyle=1, xtitle=' ', xticks=1, $
                 xticklen = 0.0001, xtickname=[lolbl, hilbl], charsize=charsize, $
                 color=color, xthick=thick, ythick=thick, charthick=thick
           AXIS, yaxis=1,ystyle=1, ytitle=' ',  yticks=1, $
                 yticklen = 0.0001, ytickname=[' ', ' '], charsize=charsize, $
                 color=color, xthick=thick, ythick=thick, charthick=thick
           AXIS, yaxis=0, ystyle=1, ytitle=' ', yticks=1, $
                 yticklen = 0.0001, ytickname=[' ', ' '], $
                 color=color, xthick=thick, ythick=thick
           AXIS, xaxis=1, xstyle=1, xtitle=' ', xticks=1, $
                 xticklen = 0.0001, xtickname=[' ', ' '], $
                 color=color, xthick=thick, ythick=thick
     endif else begin
           AXIS, xaxis=0, xstyle=1, xtitle=' ', xticks=2, $
                 xticklen = 0.0001, xtickname=[' ', lolbl, ' '], charsize=charsize, $
                 color=color, xthick=thick, ythick=thick, charthick=thick
           AXIS, xaxis=1,xstyle=1, xtitle=' ',  xticks=2, $
                 xticklen = 0.0001, xtickname=[' ', hilbl, ' '], charsize=charsize, $
                 color=color, xthick=thick, ythick=thick, charthick=thick
           AXIS, yaxis=0, ystyle=1, ytitle=' ', yticks=2, $
                 yticklen = 0.0001, ytickname=[' ', ' ', ' '], $
                 color=color, xthick=thick, ythick=thick
           AXIS, yaxis=1, ystyle=1, ytitle=' ', yticks=2, $
                 yticklen = 0.0001, ytickname=[' ', ' ', ' '], $
                 color=color, xthick=thick, ythick=thick
     endelse
     !p.position = posisave
     empty
end




