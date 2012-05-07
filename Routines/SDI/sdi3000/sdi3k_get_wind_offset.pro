pro sdi3k_get_wind_offset, offset_specifier, wind_offset, mm
    if strlen(offset_specifier)    eq 0 then return
    if strupcase(offset_specifier) eq 'NONE' then return
    if strupcase(offset_specifier) ne 'AUTO' then begin
       restore, offset_specifier
       wind_offset = wind_flat_field.wind_offset
    endif
    if strupcase(offset_specifier) ne 'AUTO' then return
    sdi3k_auto_flat, mm, wind_offset
end

