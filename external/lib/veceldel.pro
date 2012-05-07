;===================================================================
; This pocedure removes an element, identified by selidx, from a 
; vector (invec):
pro veceldel, invec, selidx
    nel = n_elements(invec)
    if nel lt 2 then return
    if selidx lt 0     then return
    if selidx ge nel   then return
    if selidx eq 0     then invec = invec(1:*)
    if selidx eq nel-1 then invec = invec(0:selidx-1)
    if selidx gt 0 and selidx lt nel-1 then invec = [invec(0:selidx-1), invec(selidx+1:*)]
end
