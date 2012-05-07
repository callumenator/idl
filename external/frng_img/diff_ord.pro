pro diff_ord, fringes, php, field_stop

;   Determine the range of orders to be used:
    nout       = 0
    if php.minord ge 0. then begin 
       maxord  = php.minord+php.delord
    endif else begin
       maxord = php.delord
    endelse


;   Warping also shifts the apparent center of the fringes - make a crude correction
;   for that:
    shiftcoef = 0.5/sqrt(maxord/(0.5*php.xmag+0.5*php.ymag))

    xx   = transpose(lindgen(php.ny,php.nx)/php.ny) - (php.xcen - php.xwarp*shiftcoef)
    yy   = lindgen(php.nx,php.ny)/php.nx            - (php.ycen - php.ywarp*shiftcoef)
    xx   = xx + php.xwarp*abs(xx)
    yy   = yy + php.ywarp*abs(yy)
    
    pmap = php.xmag*xx*xx + php.ymag*yy*yy + php.xymag*xx*yy 

    pmap = (pmap + php.phisq*pmap*pmap)
    if php.lambda ne 630.03 then pmap = pmap*(630.03/php.lambda)
    
    pmap    = (php.zerph - pmap)*!pi
    

    xx   = transpose(lindgen(php.ny,php.nx)/php.ny) - (php.xcen)
    yy   = lindgen(php.nx,php.ny)/php.nx            - (php.ycen)
    mmag = (php.xmag + php.ymag)/2.
    
    pref = mmag*xx*xx + mmag*yy*yy

    pref = (pref + php.phisq*pref*pref)
    if php.lambda ne 630.03 then pref = pref*(630.03/php.lambda)
    
    pref    = (php.zerph - pref)*!pi
    
    fringes = pmap - pref
    
end
