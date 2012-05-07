;================================================================
;
;   This function returns a list of files matching the
;   supplied filter string. Unlike 'findfile', it can
;   search subdirectories if desired.  This should work
;   for both Windows and Unix variants of IDL. So far,
;   it isn't setup for MAC or VMS versions.
;
;   Mark Conde, Fairbanks, December 2000.

function mcfindfile, filter, subdir=subdir, count=count

;---Just use the native "findfile" if we need not search subdirectories:
    if not(keyword_set(subdir)) then begin
       file_list = findfile(filter, count=count)
       return, file_list
    endif

;---Windows subdirectory search:    
    if strupcase(!version.os_family) eq 'WINDOWS' then begin
       spawn, 'dir/b/s ' + filter, file_list, /hide
    endif

;---Unix subdirectory search:
    if strupcase(!version.os_family) eq 'UNIX' then begin
;------First, get the name portion of the filter string:
       namebits = str_sep(filter, '/')
       namepart = namebits(n_elements(namebits)-1)
;------Now get the path specifier:
       if n_elements(namebits) eq 1 then path = '.' else begin
          path  = strmid(filter, 0, strlen(filter) - strlen(namepart))
       endelse
;------Finally, use the "find" command to get the result:
       findit   = 'find ' + path + ' -name "' + namepart + '" -print'
       spawn, findit, file_list
    endif
    
    count = n_elements(file_list)
    return, file_list
end