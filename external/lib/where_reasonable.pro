function where_reasonable, wot, n_sigma
    goodcount = 0
    goods = where(finite(wot(*)), goodcount)
    if goodcount le 0 then return, -1
    wotok = wot(goods)
    okidx = indgen(n_elements(goods))
    for j=0,goodcount-1 do begin
        nothers = 0
        others = where(okidx ne j, nothers)
        if nothers gt 2 then begin
           wotsam = wotok(others)
           sigma = sqrt((total(wotsam^2) - ((total(wotsam))^2) $
                       /(goodcount-1))/(goodcount-2))
           middle= median(wotsam)
        endif else begin
              sigma = 9e9
              middle = median(wotok)
        endelse
        if (abs(wotok(j) - middle))/sigma gt n_sigma then goods(j) = -1
     endfor
     nkeep = 0
     keepers = where(goods ge 0, nkeep)
     if nkeep gt 0 then goods = goods(keepers) else goods = -1
     return, goods
end
