;======================================================================
; This routine checks an array of keywords against a source string.
; It returns the array index of the first keyword found in the source,
; or -1 if no match occurred:
function keycheck, check_string, keys
    idx   = -1
    trial = 0
    while idx lt 0 and trial lt n_elements(keys) do begin
          if strpos(strupcase(check_string), strupcase(keys(trial))) ge 0 then idx = trial
          trial = trial + 1
    endwhile
    return, idx
end