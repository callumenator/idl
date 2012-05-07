xx = 'F:\users\SDI3000\phase_maps\Phasemap 2008 042 unwrapped.dat'
restore, xx
base(0:3, *) = 0
base(509:511, *) = 0
base(*, 0:3) = 0
base(*, 509:511) = 0

while !d.window ge 0 do wdelete, !d.window
window, xsize=512, ysize=512
tvscl, base mod 128

end