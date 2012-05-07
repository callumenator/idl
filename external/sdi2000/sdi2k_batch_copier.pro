 pro sdi2k_batch_copier, source_dir, dest_dir
 
 
 srclis = findfile(source_dir + '*.pf')
 dstlis = findfile(dest_dir   + '*.pf')
 
 srclis = strupcase(srclis)
 dstlis = strupcase(dstlis)
 
 ni     = 0
 for j=0,n_elements(dstlis)-1 do begin
      name_string = strmid(dstlis(j), strpos(dstlis(j), '\DATA\')+6, 999)
      srcpos      = strpos(srclis, name_string)
      srcidx      = where(srcpos gt 0, ni)
      if ni gt 0 then begin
         if n_elements(srclis) gt 1 then veceldel, srclis, srcidx(0) else undefine, srclis
      endif
 endfor

 for j=0,n_elements(srclis)-1 do begin
     print, 'copy ' + srclis(j) + ' ' + dest_dir
     spawn, 'copy ' + srclis(j) + ' ' + dest_dir
 endfor
 end
