function mc_fileparse, flis

;---Get OS-specific path component delimiter character
    delimiter = '\'
    if strupcase(!version.os_family) eq 'UNIX' then delimiter = '/'
    
    filez = file_expand_path(flis)
    
    fspec = {mc_fparse_s, fullname: 'Unknown', $
                              path: 'Unknown', $
                          namepart: 'Unknown', $
                         name_only: 'Unknown', $
                         extension: 'Unknown'}
    reply = replicate(fspec, n_elements(flis))

    for j=0, n_elements(flis)-1 do begin
        pbits = str_sep(filez(j), delimiter)
        reply(j).fullname  = filez(j)
        reply(j).namepart  = pbits(n_elements(pbits)-1)
        reply(j).path      = strmid(filez(j), 0, strlen(filez(j)) - strlen(reply(j).namepart))
        nbits = str_sep(reply(j).namepart, '.')
        reply(j).name_only = nbits(0)
        reply(j).extension = strmid(reply(j).namepart, strlen(reply(j).name_only), 99)
    endfor
    return, reply
end