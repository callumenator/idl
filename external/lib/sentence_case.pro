function sentence_case, instrarr
    outstrarr = instrarr
    for j=0,n_elements(outstrarr)-1 do begin
        ttest = size(outstrarr(j))
        if ttest(1) eq 7 then begin
           outstrarr(j) = strupcase(strmid(outstrarr(j), 0, 1)) + strlowcase(strmid(outstrarr(j), 1, 9999))
        endif
    endfor
    return, outstrarr
end