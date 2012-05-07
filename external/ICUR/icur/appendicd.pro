;****************************************************************************
pro appendicd,file1,file0
icdfile,file1,nr
for i=0,nr do begin
   gdat,file1,h,w,f,e,i
   if n_elements(h) eq 1 then goto,endfile
   kdat,file0,h,w,f,e,-1
   endfor
endfile:
print,i,' files copied from ',file1,' to ', file0
return
end
