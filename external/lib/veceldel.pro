;===================================================================
; This pocedure removes an element, identified by selidx, from a
; vector (invec):
pro veceldel, invec, selidx, last=last
    nel = n_elements(invec)
    if nel lt 2 and ~keyword_set(last) then return
    if nel eq 1        then undefine, invec
    if nel eq 1        then return
    if selidx lt 0     then return
    if selidx ge nel   then return
    if selidx eq 0     then invec = invec(1:*)
    if selidx eq nel-1 then invec = invec(0:selidx-1)
    if selidx gt 0 and selidx lt nel-1 then invec = [invec(0:selidx-1), invec(selidx+1:*)]
end
