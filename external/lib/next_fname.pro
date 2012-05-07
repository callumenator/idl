function next_fname, path=path, namepart=namepart, extn=extn

fcount=0
fullname = path + namepart + '_' + strcompress(string(fcount, format='(i9)') + '.' + extn, /remove_all)

while file_test(fullname) do begin
      fcount = fcount + 1
      fullname = path + namepart + '_' + strcompress(string(fcount, format='(i9)') + '.' + extn, /remove_all)
endwhile
return, fullname
end