pro mc_oploterr, x, y, err, thick=thick, $
    bar_color=bar_color, line_color=line_color, dash_color=dash_color, $
    psym=psym, symbol_color=symbol_color, twosigma_off=tsig, xerrors=xerrors, errthick=errthick, symsize=symsize, $
    linestyle=linestyle

    if not(keyword_set(thick))        then thick        = 2
    if not(keyword_set(bar_color))    then bar_color    = [1, 1]
    if not(keyword_set(line_color))   then line_color   = 1
    if not(arg_present(dash_color))   then dash_color   = 0
    if not(keyword_set(symbol_color)) then symbol_color = 1
    if not(keyword_set(psym))         then psym         = 1
;    if not(keyword_set(tsig))         then tsig         = 0
    if not(keyword_set(errthick))     then errthick     = 1
    if not(keyword_set(symsize))      then symsize      = 1
    if not(keyword_set(linestyle))    then linestyle    = 0

    culsave = !p.color
    !p.color = bar_color(0)
    if n_elements(bar_color) eq 1 then bar_color = [bar_color, bar_color]

    if keyword_set(xerrors) then begin
       for j=0, n_elements(x)-1 do oplot, [x(j) -   err(j), x(j) +   err(j)], [y(j), y(j)], color=bar_color(0), thick=errthick

       if (keyword_set(tsig)) then begin
          for j=0, n_elements(x)-1 do oplot, [x(j) +   2*err(j), x(j) + 1.*err(j)], [y(j), y(j)], color=bar_color(1), thick=errthick
          for j=0, n_elements(x)-1 do oplot, [x(j) -   2*err(j), x(j) - 1.*err(j)], [y(j), y(j)], color=bar_color(1), thick=errthick
       endif
    endif else begin
       for j=0, n_elements(x)-1 do oplot, [x(j), x(j)], [y(j) -   err(j), y(j) +   err(j)], color=bar_color(0), thick=errthick

       if (keyword_set(tsig)) then begin
          for j=0, n_elements(x)-1 do oplot, [x(j), x(j)], [y(j) +   2*err(j), y(j) + 1.*err(j)], color=bar_color(1), thick=errthick
          for j=0, n_elements(x)-1 do oplot, [x(j), x(j)], [y(j) -   2*err(j), y(j) - 1.*err(j)], color=bar_color(1), thick=errthick
       endif
    endelse

;    for j=0, n_elements(x)-1 do begin
;             for k=1,10 do plots, x(j), y(j) - err(j)*(1+k/10.), color=bar_color(1), psym=3, noclip=0
;             for k=1,10 do plots, x(j), y(j) + err(j)*(1+k/10.), color=bar_color(1), psym=3, noclip=1
;    endfor

;    !p.linestyle = 0
;    oploterr, x, y, err, psym

;    oplot, x, y + 0.25*err, color=dash_color, thick=errthick, linestyle=1
;    oplot, x, y - 0.25*err, color=dash_color, thick=errthick, linestyle=1
;    oplot, x, y +  0.5*err, color=dash_color, thick=errthick, linestyle=1
;    oplot, x, y -  0.5*err, color=dash_color, thick=errthick, linestyle=1
    if dash_color gt 0 then oplot, x, y +  err, color=dash_color, thick=errthick, linestyle=2
    if dash_color gt 0 then oplot, x, y -  err, color=dash_color, thick=errthick, linestyle=2

    if keyword_set(xerrors) then begin
       if not(keyword_set(tsig)) then begin
          if dash_color gt 0 then oplot, x + err, y, color=dash_color, thick=errthick, linestyle=1
          if dash_color gt 0 then oplot, x - err, y, color=dash_color, thick=errthick, linestyle=1
       endif
    endif else begin
       if not(keyword_set(tsig)) then begin
          if dash_color gt 0 then oplot, x, y + err, color=dash_color, thick=errthick, linestyle=1
          if dash_color gt 0 then oplot, x, y - err, color=dash_color, thick=errthick, linestyle=1
       endif
    endelse

    !p.color = line_color
    oplot, x, y, color=line_color,   thick=thick, linestyle=linestyle
    oplot, x, y, color=symbol_color, thick=thick, psym=psym, symsize=symsize
    !p.color = culsave

end