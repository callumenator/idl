pro mpeg_these, images=images, result=result, fill=fill, path=pth, show_frames=show_frames


    if not(keyword_set(images)) then begin
    images = dialog_pickfile(/multiple, filter=['*.gif', '*.png', '*.jpg'], /must_exist, $
                             title='Image files to MPEG?', get_path=pth, path=pth)
    if not(keyword_set(pth))  then pth='.'
    if not(keyword_set(fill)) then fill=1
 endif

    if not(keyword_set(result)) then begin
    result = dialog_pickfile(filter='*.mpg', title='Filename for output MPEG movie?', path=pth )
 endif

 
 type = str_sep(images(0), '.', /trim)
 type = strupcase(type(n_elements(type)-1))
 
 fcount = 0
 images = images(sort(images))
 for frame=0,n_elements(images)-1 do begin
     has_palette = 1
     case type of
     'GIF': read_gif,  images(frame), scene, r, g, b
     'JPG': read_jpeg, images(frame), scene, /grayscale
     'PNG': begin
            status = query_png(images(frame), info)
            has_palette = info.has_palette
            if (has_palette) then scene = read_png(images(frame), r, g, b) else scene = read_png(images(frame))
            end
      else: read_gif,  images(frame), scene, r, g, b
  endcase
  
  if (has_palette) then begin
      dimz = [n_elements(scene(*,0)), n_elements(scene(0,*))]
      dimz = 2*(dimz/2)
      scene = scene(0:dimz(0)-1, 0:dimz(1)-1)
  endif else begin
      dimz = [n_elements(scene(0,*,0)), n_elements(scene(0,0,*))]
      dimz = 2*(dimz/2)
      scene = scene(*,0:dimz(0)-1, 0:dimz(1)-1)
  endelse
  if frame eq 0 then begin
;           mpegID = OBJ_NEW('IDLgrMPEG', dimensions=dimz, format=0, quality=99, bitrate=100000000L, iframe_gap=fill)
           mpegID = OBJ_NEW('IDLgrMPEG', dimensions=dimz, format=0, quality=75, bitrate=0, iframe_gap=fill)
  endif
  
  print, 'Frame number:', frame 
  if keyword_set(show_frames) then begin  
     window, show_frames, xsize=dimz(0), ysize=dimz(1)
     tv, scene
  endif

    image24 = bytarr(3, dimz(0), dimz(1))
    if has_palette then begin
       image8 = scene
       image24(0,*,*) = r(image8)
       image24(1,*,*) = g(image8)
       image24(2,*,*) = b(image8)
    endif else image24 = scene
    MPEG_PUT, mpegID, FRAME=fcount, /order, image=image24
    fcount = fcount + 1
    wait, 0.05
 endfor
    MPEG_SAVE, mpegID, FILENAME=result
    MPEG_CLOSE, mpegID


end
