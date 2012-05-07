; DE2 UA Data reader - test file.

    get_lun,  pltun
    fullname = 'test.asc'
    openr,    pltun, fullname, /get_lun
    while not eof(pltun) do begin
          read, pltun, oneline
          oneline = strcompress(oneline)
          values  = str_sep(oneline, ' ')
    endwhile
    close,    pltun
    free_lun, pltun
    end

