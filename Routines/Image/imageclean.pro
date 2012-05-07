

function imageclean, isig

    isignew = isig
    nbad = 0

;---First, fix really big blotches:
    medsig = median(isignew, 15)
    difsig = abs(isignew - medsig)
    bads   = where(difsig/(medsig + max(medsig/200.)) gt 0.5, nbad)
    if nbad gt 0 then isignew(bads) = medsig(bads)

;---Then look closer:
    medsig = median(isignew, 10)
    difsig = abs(isignew - medsig)
    bads   = where(difsig/(medsig + max(medsig/200.)) gt 0.3, nbad)
    if nbad gt 0 then isignew(bads) = medsig(bads)

;---Then look even closer:
    medsig = median(isignew, 5)
    difsig = abs(isignew - medsig)
    bads   = where(difsig/(medsig + max(medsig/200.)) gt 0.2, nbad)
    if nbad gt 0 then isignew(bads) = medsig(bads)

return, isignew

end



