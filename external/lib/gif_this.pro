; Make a GIF file from the current window:

pro gif_this, file=fname, png=png
    trc = !d.n_colors gt 65536
    ftr = '*.gif'
    if keyword_set(png) then ftr = '*.png'
    if not(keyword_set(fname)) then fname = dialog_pickfile(filter=ftr)
    if fname ne '' then begin
       img = tvrd(true=trc)
       tvlct, r, g, b, /get
       if keyword_set(png) then write_png, fname, img else begin
          write_gif, fname, img, r, g, b
       endelse
    endif
end