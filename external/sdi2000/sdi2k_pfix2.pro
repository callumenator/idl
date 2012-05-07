restore, 'D:\USERS\sdi2000\data\phl4_unwrapped2002070.pf'
l4 = phase
restore, 'D:\USERS\sdi2000\data\phn4_unwrapped2002070.pf'
n4 = phase
restore, 'D:\USERS\sdi2000\data\phn1_unwrapped2002070.pf'
n1 = phase

n4 = mc_im_sm(n4, 3)
n1 = mc_im_sm(n1, 3)
l4 = mc_im_sm(l4, 3)

epsilon = n1 - n4

dpix    = 3
dn4dx   = (shift(n4, dpix, 0) - n4)/dpix
dn4dy   = (shift(n4, 0, dpix) - n4)/dpix

sqgrad  = dn4dx^2 + dn4dy^2 + 0.001

delx    = epsilon*dn4dx/sqgrad
dely    = epsilon*dn4dy/sqgrad

dl4dx   = (shift(l4, dpix, 0) - nl)/dpix
dl4dy   = (shift(l4, 0, dpix) - nl)/dpix

lgamma  = delx*dl4dx + dely*dl4dy
lgamma  = lgamma < 70
lgamma  = lgamma > (-70)

shade_surf, lgamma(20:220, 40:300)
end

