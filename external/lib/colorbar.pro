;===============================================================================
;
;    Make a color scale bar for image plots:

pro colorbar, barbox, loshade, hishade, lodat, hidat, $
              parname=parname, units=units, $
              color=color, thick=thick, charsize=charsize, format=fmt
              
      if not(keyword_set(parname))  then parname=''
      if not(keyword_set(units))    then units=''
      if not(keyword_set(color))    then color=0
      if not(keyword_set(thick))    then thick=1
      if not(keyword_set(charsize)) then charsize=1
      if (not(keyword_set(fmt)))    then fmt = '(g14.4)'
              
     !p.position = barbox
     lopix = convert_coord(!p.position(0), !p.position(1), /normal, /to_device)
     hipix = convert_coord(!p.position(2), !p.position(3), /normal, /to_device)
     
     nlev = hipix(1) - lopix(1)
     npix = hipix(0) - lopix(0)
     if !d.name eq 'PS' then begin
        npix = 200*npix/nlev
        nlev = 200
     endif 
     map  = loshade + indgen(nlev+1) * (float(hishade - loshade - 1)/(nlev+1))
     tv, (bytarr(npix) + 1)#map, !p.position(0), !p.position(1), /normal, $
          xsize=barbox(2) - barbox(0), ysize=barbox(3) - barbox(1)
     plot,  /nodata, [0,hishade-loshade], $
         xstyle=1, ystyle=4, $
         xtitle=' ', ytitle=' ', $
         xticks=2, xticklen = 0.001, xtickname=replicate(' ', 3), $
             color=color, xthick=thick, ythick=thick, /noerase
     lolbl = strcompress(parname  + string(lodat, format=fmt)) + '!C' + units
     hilbl = strcompress(parname  + string(hidat, format=fmt))
                         
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
     !p.position = 0
     empty
end




