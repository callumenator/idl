    function get_gap, mapfile
    restore, mapfile
    nn    = n_elements(base(0,*))

    ccd_size = 0.008192
    efl      = 0.3
    if strpos(strupcase(mapfile), 'HAARP') ge 0 then begin
       efl = 0.4
       ccd_size = 0.013312
    endif

    lambda   = 632.8e-9
    mu       = 1.000271714
    xx    = transpose(lindgen(nn,nn)/nn)
    yy    = lindgen(nn,nn)/nn
    cc    = where(base eq min(base))
    xcen  = xx(cc)
    ycen  = yy(cc)

    xcen  = nn/2
    ycen  = nn/2

    xx    = transpose(lindgen(nn,nn)/nn) - xcen
    yy    = lindgen(nn,nn)/nn            - ycen
    rr    = sqrt(xx^2 + yy^2)

    theta = atan(0.5*ccd_size*rr/(0.5*nn), efl)
    ord   = ((base - min(median(base, 5)) > 0)/128)

    gap   = ord*lambda/((theta^2)*mu)
    goods = where(rr gt 150 and rr lt 240)
    medgap= 1000*median(gap(goods))

    print, "Median gap estimate from file ", mapfile, " is ", string(medgap,format='(f6.3)'), " mm"
    return, medgap
    end

;---Main program starts here:
    sum   = 0
    count = 0
    xx = dialog_pickfile(path="D:\users\SDI3000\Data", /multi)
    for j=0,n_elements(xx)-1 do begin
        sum   = sum + get_gap(xx(j))
        count = count + 1
    endfor
    print, "Average gap over all files is: ", string(sum/count,format='(f6.3)')
    end