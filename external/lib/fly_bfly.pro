pro fly_bfly, new=new, filter=fltr, finish=finish, transpose=transpose
    common butter, gifs, gidx, widx
    if n_elements(widx) eq 0 then widx = -1

    wsave = !d.window
    if not(keyword_set(fltr)) then fltr='f:\users\conde\main\idl\lib\bfly*.gif'
    if keyword_set(new) or n_elements(gifs) eq 0 then begin
       glis = findfile(fltr)
       glis = glis(sort(glis))
       for j=0,n_elements(glis)-1 do begin
           read_gif, glis(j), bfly
           if n_elements(gifs) eq 0 then begin
              gifs = bytarr(n_elements(glis), n_elements(bfly(*,0)), n_elements(bfly(*,0)))
           endif
           gifs(j, *, *) = bfly
       endfor
       gidx = 0
    endif
    if widx eq -1 then begin
       window, /free, xsize=n_elements(gifs(0, *, 0)), ysize=n_elements(gifs(0, 0, *)), title='B-fly'
       widx = !d.window
    endif else wset, widx
    if keyword_set(transpose) then begin
       tvscl, transpose(reform(gifs(gidx, *, *))) 
    endif else tvscl, gifs(gidx, *, *)
    gidx = gidx + 1
    if gidx ge n_elements(gifs(*, 0, 0)) then gidx = 0
    
    if keyword_set(finish) then begin
       if widx ne -1 then wdelete, widx
       widx = -1
    endif
;    wset, wsave
end