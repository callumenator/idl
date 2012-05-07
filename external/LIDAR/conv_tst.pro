
window, 0
loadct, 2

npts   = 200
w      = 10.
pos    = npts/3.
height = 1.
dummy  = " "


x = findgen(npts) 
f = exp(-abs((x-0.8*pos)/(0.6*w)))
g = exp(-((x-pos)/w)^2)
g = height*g
h = fltarr(npts)
hlo = pos - npts/20
hhi = pos+ npts/20
h(hlo:hhi) = findgen(hhi-hlo+1)/(hhi-hlo)
plot, g
oplot, f, color=100
oplot, h, color=150

gh = g*h

window, 1


ff   = fft(f, -1)
gg   = fft(g, -1)
hh   = fft(h, -1)
ghgh = fft(gh, -1)

plot, fft(ff*ghgh, 1)
oplot, fft(ff*gg, 1), color=100
oplot, fft(ff*hh, 1), color=150

end