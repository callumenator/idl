pro deg_tik, x, ttvals, nttix, minor, minimum=mint
if not(keyword_set(mint)) then mint   = 6 ; Minimum number of major ticks

ttvals = -1
nttix  = 0

lo     = min(x)
hi     = max(x)
range  = hi - lo

ytix   = [10000, 5000, 1000, 500, 100, 60, 30, 20, 10,  5,  4, 2]*365.25*86400L
yminor = [   10,   10,   10,  10,  10, 10, 10, 10, 10,  5,  8, 8]
dtix   = [360, 300, 150, 120, 90, 60, 30, 20, 10,  5,  4, 2]*86400L
dminor = [12,   10,  10, 120,  9, 10, 10, 10, 10,  5,  8, 8]
htix   = [24, 12, 10,  6,  5, 2]*3600L
hminor = [12,  6, 10,  6,  5, 8]
mtix   = [60, 30, 20, 15, 10, 5]*60L
mminor = [ 6,  6, 10,  5,  5, 5]
stix   = [120, 90, 60, 45, 30, 15, 10, 5, 2, 1]
sminor = [8,    6,  6,  9,  6,  5,  5, 5, 8, 5]
tix    = [  ytix, dtix,     htix,   mtix,   stix]
minor  = [yminor, dminor, hminor, mminor, sminor]

enough = where(range/tix ge mint)
tick   = tix(enough(0))
minor  = minor(enough(0))

start  = tick*long(lo/tick)
ttvals = start + lindgen(fix(range/tick) + 5)*tick
inx    = 0
intix  = where((ttvals ge lo) and (ttvals le hi), inx)
if       inx gt 0 then begin
         ttvals = ttvals(intix)
         nttix  = n_elements(ttvals)-1
endif
end
