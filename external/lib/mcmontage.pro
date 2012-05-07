;=============================================================================================
pro mcmontage, gif_list, columns, rows, montage, background=bg, color_tables = rgb, bit24=bit24, png=png

    if not(keyword_set(bg)) then bg = 0b
;---Create arrays to store the height and width of each image in the montage:
    nframe = 1+ n_elements(gif_list)/fix(rows*columns)
    width  = intarr(columns, rows, 1)
    height = intarr(columns, rows, 1)
    
    montage = -1
    nn = rows*columns
;---Read the images into an array of heap variables, to be accessed via a pointer array:
    for j=0,n_elements(gif_list)-1 do begin
        if keyword_set(png) then begin
           piccy= read_png(gif_list(j))
           stop
        endif else read_gif, gif_list(j), piccy, r,g,b
        if j eq 0 then coltab = {s_cltb, r:r, g:g, b:b}
        coltab.r = r
        coltab.g = g
        coltab.b = b

        
        frame = j/nn
        row = fix((j-frame*nn)/columns)
        col = j - frame*nn - row*columns
        if frame ge n_elements(width(0,0,*)) then begin
           width  = [ [[width]],  [[intarr(columns, rows)]] ]
           height = [ [[height]], [[intarr(columns, rows)]] ]
           pix    = [ [[pix]],    [[replicate(p, columns, rows)]] ]
           rgb    = [ [[rgb]],    [[replicate(coltab, columns, rows)]] ]
        endif
        
        height(col, row, frame) = n_elements(piccy(0,*))
        width(col,  row, frame) = n_elements(piccy(*,0))
        p = ptr_new(piccy)
        if n_elements(pix) eq 0 then begin
           rgb = replicate(coltab, columns, rows, 1)
           pix = replicate(p, columns, rows, 1)
        endif else begin
           pix(col, row, frame) = p
           rgb(col, row, frame) = coltab
        endelse
    endfor

;---Calculate the total height and width of the montage frames, in pixels:
    th = 0
    tw = 0
    for r=0,rows-1 do begin
        th = th + max(height(*,r,*))
    endfor
    for c=0,columns-1 do begin
        tw = tw + max(width(c,*,*))
    endfor

;---Calculate the lower left corner of each image, in pixels:
    btm = intarr(rows)
    lft = intarr(columns)
    btm(0) = th - max(height(*, 0, *))
    for r=1,rows-1 do begin
        btm(r) = btm(r-1) - max(height(*,r,*))
    endfor
    lft(0) = 0
    for c=1,columns-1 do begin
        lft(c) = lft(c-1) + max(width(c,*,*))
    endfor

;---Assemble the montage frames for all the pictures:
    montage = bg+bytarr(tw, th, frame+1)
    bit24   = bg+bytarr(3, tw, th, frame+1)
    for j=0,n_elements(gif_list)-1 do begin
        frame = j/nn
        row = fix((j-frame*nn)/columns)
        col = j - frame*nn - row*columns
        montage(lft(col):lft(col) +  width(col, row, frame)-1, $
                btm(row):btm(row) + height(col, row, frame)-1, frame) = *pix(col, row, frame)
        bit24(0,lft(col):lft(col) +  width(col, row, frame)-1, $
                btm(row):btm(row) + height(col, row, frame)-1, frame) = rgb(col, row, frame).r(*pix(col, row, frame))
        bit24(1,lft(col):lft(col) +  width(col, row, frame)-1, $
                btm(row):btm(row) + height(col, row, frame)-1, frame) = rgb(col, row, frame).g(*pix(col, row, frame))
        bit24(2,lft(col):lft(col) +  width(col, row, frame)-1, $
                btm(row):btm(row) + height(col, row, frame)-1, frame) = rgb(col, row, frame).b(*pix(col, row, frame))
        
    endfor
end