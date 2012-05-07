nph = 128
restore, 'D:\USERS\sdi2000\data\phc2002080.pf'
phl = phase
;restore, '\\Thing\USERS\sdi2000\data\doy065_special_cals\phs2002065.pf'
restore, 'D:\USERS\sdi2000\data\phs2002080.pf'
phn = phase

phl = phl(30:210, 70:250)
phn = phn(30:210, 70:250)

phl = (!pi + phl)/(2*!pi)
phn = (!pi + phn)/(2*!pi)
window, 0, xsize=181, ysize=181

ccph = fltarr(nph)

for j=0,nph-1 do begin
    ccph(j) = total(phn*((float(j)/nph+phl) mod 1))
endfor

bestph = where(ccph eq max(ccph))
bestph = bestph(0)/float(nph)

phl = (bestph+phl) mod 1

for j=0,20 do begin
    tvscl, phn
    wait, 0.1
    tvscl, phl
    wait, 0.1
endfor
;stop

fac = 2.
bphn = congrid(phn, 181*fac, 181*fac, /cubic)
bphl = congrid(phl, 181*fac, 181*fac, /cubic)

nshf = 8

ccar = fltarr(nshf, nshf)
xarr = fltarr(nshf, nshf)
yarr = fltarr(nshf, nshf)

for j=0,nshf-1 do begin
    for k=0,nshf-1 do begin
        ccar(j,k) = total(bphn*shift(bphl, j-nshf/2, k-nshf/2))
        xarr(j,k) = j-nshf/2
        yarr(j,k) = k-nshf/2
        wait, 0.001
    endfor
endfor

best = where(ccar eq max(ccar))
print, xarr(best)/fac, yarr(best)/fac


end