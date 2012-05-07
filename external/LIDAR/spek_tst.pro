
window, 0
loadct, 2

npts   = 200
w      = 15.
pos    = npts/2.
height = 5.
dummy  = " "


x = findgen(npts) 
g = exp(-((x-pos)/w)^2)
g = height*g
;g = fltarr(npts)
;g(1:npts-2) = height
gg= g
plot, g
read, "Press RETURN to continue", dummy

h     = fft(g, -1) 
hh    = h
h     = abs(h*conj(h))
window, 1
plot, alog10(h(0:npts/5))

print,h(1:5)
print
print,reverse(h(npts-1-4:npts-1))
print, "============"
read, "Press RETURN to continue", dummy

loop:
w = w+5
print, w
x = findgen(npts) 
g = exp(-((x-pos)/w)^2)
g = height*g
gg= g
h     = fft(g, -1) 
hh    = h
h     = abs(h*conj(h))
oplot, alog10(h(0:npts/5))
if w lt 70 then goto, loop


f1    = npts/!pi
ftpos = 2*pos/f1
ftwid = (w/f1)^2

trial  = findgen(npts)
trial  = complex(ftwid*trial*trial, ftpos*trial)
trial  = (height/npts)*exp(-trial)*w*sqrt(!pi)
trial(npts-npts/2:npts-1) = conj(reverse(trial(1:npts/2)))
hg     = h
h      = abs(trial*conj(trial))
oplot, alog10(h(0:npts/5)), color=100
;oplot, h(0:10), color=100
print,h(1:5)
print
print,reverse(h(npts-1-4:npts-1))
print, "============"
read, "Press RETURN to continue", dummy

g = abs(fft(trial, 1))

window, 0
plot, gg
oplot, g, color=100
read, "Press RETURN to continue", dummy

window, 1
plot, gg/g

end