pro mcgauss, inx, iny, xpos, width, height, fit

;=============================================
;
;  Given arrays inx, and iny, this routine
;  returns the position, width, height, and
;  the best-fit Gaussian for those data.
;
;  Mark Conde, Fairbanks, June 1998.

   npt    = n_elements(inx)
   n      = total(iny)
   xy     = total(inx*iny)
   xpos   = xy/n
   dev    = iny*(inx-xpos)^2
   width  = sqrt(total(dev)/n)
   steps  = inx(1:npt-1) - inx(0:npt-2)
   area   = total(steps*(iny(1:npt-1) + iny(0:npt-2))/2)
   height = area/(width*2*sqrt(!pi))*sqrt(2)
   fit    = height*exp(-0.5*((inx-xpos)/width)^2)
end

;============================================
;
;  Check the "mcgauss" routine with some
;  test data:

npts = 80
xx   = 190.
xw   = 40.
xh   = 40.
nse  = 4.
x = 5.*findgen(npts)
y = xh*exp(-0.5*((x-xx)/xw)^2) + nse*(randomu(seed, npts)-0.5)
plot,  x, y
mcgauss, x, y, pos, wid, height, fit
oplot, x, fit
end