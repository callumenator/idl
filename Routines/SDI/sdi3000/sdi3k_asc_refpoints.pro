
pro sdi3k_asc_refpoints, flis, refpoints, culz, ascrot=ascrot
    if strpos(strupcase(flis(0)), '.FITS') gt 0 then $
       timelis = strmid(flis, strlen(flis(0)) - 15, 2) + '-' + strmid(flis, strlen(flis(0)) - 13, 2) + '-' + strmid(flis, strlen(flis(0)) - 11, 2) else $
       timelis = strmid(flis, strlen(flis(0)) - 10, 2) + '-' + strmid(flis, strlen(flis(0)) - 8, 2)  + '-' + strmid(flis, strlen(flis(0)) - 6, 2)
    subsidx = 10*(indgen(n_elements(timelis)/10))
    timelis = timelis(subsidx)
    mcchoice, 'Example Image: ', timelis, choice, $
               heading = {text: 'Choose an ASC image to use for scaling points.', font: 'Helvetica*Bold*Proof*30'}

       this_asc = overead_asc(flis(subsidx(choice.index)), ascrot=ascrot)
       window, 5, xsize=512, ysize=512
       xcen=256
       ycen=256

       tv, culz.greymin+bytscl(hist_equal(this_asc), top=(culz.greymax - culz.greymin))
       xyouts, xcen, ycen, "Click cursor on the LEFT horizon", $
     color=culz.green, /device, align=0.5, charthick=2, charsize=1.2
       cursor, x, y, 4, /device
       lox = x
       tv, culz.greymin+bytscl(hist_equal(this_asc), top=(culz.greymax - culz.greymin))
       xyouts, xcen, ycen, "Click cursor on the RIGHT horizon", $
     color=culz.orange, /device, align=0.5, charthick=2, charsize=1.2
       cursor, x, y, 4, /device
       hix = x
       tv, culz.greymin+bytscl(hist_equal(this_asc), top=(culz.greymax - culz.greymin))
       xyouts, xcen, ycen, "Click cursor on the BOTTOM horizon", $
     color=culz.green, /device, align=0.5, charthick=2, charsize=1.2
       cursor, x, y, 4, /device
       loy = y
       tv, culz.greymin+bytscl(hist_equal(this_asc), top=(culz.greymax - culz.greymin))
       xyouts, xcen, ycen, "Click cursor on the TOP horizon", $
     color=culz.orange, /device, align=0.5, charthick=2, charsize=1.2
       cursor, x, y, 4, /device
       hiy = y
       wdelete, 5

       zang = 360.*mc_dist(n_elements(this_asc(*,0)), n_elements(this_asc(0, *)), (lox+hix)/2, (loy+hiy)/2, x=xx, y=yy)/(lox + hix + loy + hiy)
       azi = atan(yy, xx)
       azi = 180 + rotate(reverse(azi, 1), 1)/!dtor
       rdist  = 100.*tan(!dtor*zang)
       xdist  = rdist*sin(!dtor*azi)
       ydist  = rdist*cos(!dtor*azi)
       useful = where(zang lt 85.)
       useord = sort(zang(useful))
       useful = useful(reverse(useord))
       dims   = [n_elements(this_asc(*,0)), n_elements(this_asc(0, *))]
       refpoints = {dims: dims, horizon: [lox, hix, loy, hiy], zang: zang, azimuth: azi, xdist: xdist, ydist: ydist, useful: useful}
end

pro sdi3k_get_asc_indices, xpix, ypix, mm, refpoints, mapvec, ascvec

    dummy   = mc_dist(xpix, ypix, 0., 0., x=xx, y=yy)
    lonlats = convert_coord(xx, yy, /device, /to_data)
    dx      = 111.12*(lonlats(0, *) - mm.longitude)*cos(!dtor*mm.latitude)
    dy      = 111.12*(lonlats(1, *) - mm.latitude)
    rads    = sqrt(dx^2 + dy^2)
    use     = where(rads lt 450.)
    zang    = atan(rads(use)/105.)/!dtor
    pixrad  = 0.25*total(refpoints.horizon)*zang/(90.)
    maxrad  = max(rads(use))
    azi     = atan(dy(use), dx(use))
    radhere = sqrt((dx(use))^2 + (dy(use))^2)
    xx      = pixrad*dx(use)/radhere + (refpoints.horizon(0) + refpoints.horizon(1))/2
    yy      = pixrad*dy(use)/radhere + (refpoints.horizon(2) + refpoints.horizon(3))/2
    mapvec  = use
    ascvec  = long(yy)*refpoints.dims(0) + xx
end
