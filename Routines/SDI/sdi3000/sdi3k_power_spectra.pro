function sdi_interp, valbefore, valafter, timebefore, timeafter, when
         return, valbefore + (valafter - valbefore)*(when - timebefore)/(timeafter - timebefore)
end

data_path = 'c:\users\sdi3000\data\spectra\'
if getenv('computername') eq 'VERTEX'   then data_path = 'd:\'
if getenv('computername') eq 'FLYWHEEL' then data_path = 'D:\users\SDI3000\Data\Spectra\'
ncfile = dialog_pickfile(path=data_path, get_path=data_path, /read, /must_exist)

sdi3k_read_netcdf_data, ncfile, metadata=mm, zonemap=zonemap, zone_centers=zone_centers, zone_edges=zone_edges, spekfits=spekfits

while !d.window gt 0 do wdelete, !d.window
window, xsize=1400, ysize=700
;---Choose the color palette:
    load_pal, culz, proportion=0.5

centimes    = (spekfits.start_time + spekfits.end_time)/2
tot_seconds = centimes(n_elements(centimes) - 2) - centimes(1)
regtimes    = centimes(1) + 20*findgen(tot_seconds/20)

    channel_spacing = (1e-9*mm.wavelength_nm)^2/(2e-3*mm.gap_mm*mm.scan_channels)
    c=2.997925e8
    amu=1.66053e-27
    bk=1.380658e-23
    f = c*channel_spacing/(1e-9*mm.wavelength_nm)
    g = mm.mass_amu*amu/(2*bk)
    spekfits.velocity = spekfits.velocity - median(spekfits.velocity)
    spekfits.velocity = f*spekfits.velocity



regvel = fltarr(mm.nzones, n_elements(regtimes))
regtem = fltarr(mm.nzones, n_elements(regtimes))
velps  = fltarr(mm.nzones, n_elements(regtimes))
temps  = fltarr(mm.nzones, n_elements(regtimes))

for j=0,mm.nzones-1 do begin
    regvel(j,*) = interpol(spekfits.velocity(j),    centimes, regtimes)
    regtem(j,*) = interpol(spekfits.temperature(j), centimes, regtimes)
endfor


for j=0,mm.nzones-1 do begin
    dcfs = poly_fit(regtimes - regtimes(0), smooth(reform(regvel(j,*)), 50), 5, yfit=drift, /double)
    regvel(j,*) = regvel(j,*) - drift
    velft = fft(regvel(j,*))
    temft = fft(regtem(j,*))
    velps(j,*)  = abs(velft*conj(velft))
    temps(j,*)  = abs(temft*conj(temft))
endfor

period = tot_seconds/((1e-6+findgen(n_elements(regtimes)))*60.)


erase, color=culz.white
plot, period(5:100), velps(0,5:200), color=culz.black, /noerase, yrange=[0,max(velps(0:80,5:200))]
for j=1,80 do begin
    oplot, period(5:100), velps(j,5:200), color=culz.imgmin + j
endfor
end
