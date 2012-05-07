pro nice_pal

if !d.n_colors lt 4 then device,pseudo_color=8
pcnt = 20
loadct,13
tvlct, r,g,b, /get
r = float(r)
g = float(g)
b = float(b)

alo =  30.*!d.n_colors/240
ahi = 135.*!d.n_colors/240
blo = 160.*!d.n_colors/240
bhi = 192.*!d.n_colors/240
clo = 185.*!d.n_colors/240


       rr = [r(alo:ahi), r(blo:bhi), r(clo:*)]
       gg = [g(alo:ahi), g(blo:bhi), g(clo:*)]
       bb = [b(alo:ahi), b(blo:bhi), b(clo:*)]
       rr = congrid(rr, n_elements(r))
       gg = congrid(gg, n_elements(g))
       bb = congrid(bb, n_elements(b))

;      Setup the "rainbow" colours:
       rbwmin = 0
       rbwmax = n_elements(r) - 1
       satval = 255.
       step = satval/(1 + rbwmax - rbwmin)
       rgbw = float(rbwmax - rbwmin)
       rw   = rgbw/0.9
       gw   = rgbw/3.8
       bw   = rgbw/1.8
       rp   = 1.4*rgbw
       gp   = 0.5*rgbw
       bp   = 0.18*rgbw
       i = findgen (rbwmax - rbwmin + 1)
       r(rbwmin:rbwmax) = exp(-((i-rp)/rw)^2)
       g(rbwmin:rbwmax) = exp(-((i-gp)/gw)^2)
       b(rbwmin:rbwmax) = exp(-((i-bp)/bw)^2)
       g(gp:gp+gw/2) = 1
       g(gp+gw/2:rbwmax) = exp(-((i(gp+gw/2:rbwmax)-(gp+gw/2))/(0.9*gw))^2)
       r = satval*r/max(r)
       g = satval*g/max(g)
       b = satval*b/max(b)

       wgt = findgen(n_elements(r))/n_elements(r)
       r = (0.5*r + r*(1-wgt) + 0.5*rr + rr*wgt)/2
       g = (0.5*g + g*(1-wgt) + 0.5*gg + gg*wgt)/2
       b = (0.5*b + b*(1-wgt) + 0.5*bb + bb*wgt)/2
       r = smooth(r, 15)
       g = smooth(g, 15)
       b = smooth(b, 15)

       range = fix(rgbw*(pcnt/100.))
       coeff = sqrt((findgen(range)/range))
       r(1:range-1) = r(1:range-1)*coeff(1:range-1)
       g(1:range-1) = g(1:range-1)*coeff(1:range-1)
       b(1:range-1) = b(1:range-1)*coeff(1:range-1)

       r(0) = 0
       g(0) = 0
       b(0) = 0
       r(n_elements(r)-1) = 255
       g(n_elements(r)-1) = 255
       b(n_elements(r)-1) = 255
       tvlct, r, g, b

end