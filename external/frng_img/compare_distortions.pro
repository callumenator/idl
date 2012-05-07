frng_setres, ltest, img, php, 2.
php.minord = 0.
php.delord = 6
window, 0, xsize=php.nx, ysize=php.ny, xpos=2, ypos=2, title='Includes distortions'
fringemap, fringes, pmap, php, field_stop
get_xcorr, xcorr, img, php, culz
save0 = tvrd()
empty

frng_setres, ltest, img, phq, 2.
phq.minord = 0.
phq.delord = 5
window, 1, xsize=phq.nx, ysize=phq.ny, xpos=2+phq.nx, ypos=2, title='Excludes distortions'
fringemap, disfringes, dispmap, phq, field_stop
get_xcorr, xcorr, img, phq, culz
save1 = tvrd()
empty

wset, 1
tv, save1
wset, 0
tv, save0

!p.charsize=4
load_pal, culz, idl=[3,1]
sscl=10
sshd = intarr(phq.nx/sscl, phq.ny/sscl) + culz.bground

gap = 20e-3
lambda = 630e-9
fsr = lambda^2/(2*gap)
ordspeed = 3e8*fsr/lambda
velmap = ordspeed*(pmap - dispmap)/!pi

bad = fltarr(phq.nx, phq.ny)
bad(field_stop) = 1
bads = where(bad eq 0)
velmap(bads) = -9e9


window, 2, xsize=1000, ysize=1000, xpos=2, ypos=phq.ny/3, title='Phase difference'
erase, color=culz.white
mcshow3,  velmap, sscale=sscl, /white_bg, $
        locolor=min(save0), hicolor=max(save0), altimage=save0, $
        e_contour={nlevels: 15, xticks: 1, yticks: 1, $
                   xtickname: [' ', ' '], ytickname: [' ', ' '], follow: 1, c_charsize: 3, $
                   min_value: -9999, color: culz.black, c_colors: culz.red, $
                   xthick: 2, ythick: 2, C_charthick: 2}, $
        e_surface ={az: 60, ax: 27, upper: 1, color: culz.black, xticks: 1, yticks: 1, $
                   xtickname: [' ', ' '], ytickname: [' ', ' '], $
                   noerase: 1, zaxis: 0, shades: sshd, charsize: 4, $
                   min_value: -9999, ztitle: 'Velocity Error [m/s]', zrange: [-250, 250], zstyle: 1, $
                   xthick: 2, ythick: 2, zthick: 2, charthick: 2}

empty
gif_this, file='d:\users\conde\main\idl\frng_img\compare_distortions.gif'

frng_setres, ltest, img, php, 1.
frng_setres, ltest, img, phq, 1.
