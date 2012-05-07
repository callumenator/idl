frng_setres, ltest, img, php, 2.
php.minord = 0.2
php.delord = 6
window, 0, xsize=php.nx, ysize=php.ny, xpos=2, ypos=2, title=wintit
get_xcorr, xcorr, img, php, culz
gif_this, file='d:\users\conde\main\idl\frng_img\alright.gif'

wait, 2

save_php = php
php.ycen = 1.08*php.ycen
get_xcorr, xcorr, img, php, culz
gif_this, file='d:\users\conde\main\idl\frng_img\wrong_ycen.gif'
wait, 1

php = save_php
php.xwarp = 0.1
get_xcorr, xcorr, img, php, culz
gif_this, file='d:\users\conde\main\idl\frng_img\wrong_xwarp.gif'
wait, 1 

php = save_php
php.ymag = 1.3*php.ymag
get_xcorr, xcorr, img, php, culz
gif_this, file='d:\users\conde\main\idl\frng_img\wrong_ymag.gif'
wait, 1 

php = save_php
php.phisq = .05
get_xcorr, xcorr, img, php, culz
gif_this, file='d:\users\conde\main\idl\frng_img\wrong_phisq.gif'
wait, 1

php = save_php
frng_setres, ltest, img, php, 1
window, 0, xsize=php.nx, ysize=php.ny, xpos=2, ypos=2, title=wintit

