xx = dialog_pickfile(filter='*.sav', title='File name for SDI data to restore?')
restore, xx

device, decomposed=0
loadct, 15

window, 0, xsize=1200, ysize=800
erase, color=255
plot, exposure_times.doy + exposure_times.decimal_hour/24., median(spectral_fits.temperature, dim=1), $
     /noerase, xthick=3, ythick=3, thick=1, color=0, charsize=1.8, charthick=2, xtitle='Day of Year', ytitle='Temperature [K]', $
     title='Poker Flat 6300 Fabry-Perot Data for Spring 2009', yrange=[500,1100], /ystyle

window, 1, xsize=1200, ysize=800
erase, color=255
plot, exposure_times.doy + exposure_times.decimal_hour/24., wind_parameters.geo_zonal_wind, $
     /noerase, xthick=3, ythick=3, thick=1, color=0, charsize=1.8, charthick=2, xtitle='Day of Year', ytitle='Geographic Zonal Wind [m/s]', $
     title='Poker Flat 6300 Fabry-Perot Data for Spring 2009', yrange=[-350,350], /ystyle

window, 2, xsize=1200, ysize=800
erase, color=255
plot, exposure_times.doy + exposure_times.decimal_hour/24., wind_parameters.geo_meridional_wind, $
     /noerase, xthick=3, ythick=3, thick=1, color=0, charsize=1.8, charthick=2, xtitle='Day of Year', ytitle='Geographic Meridional Wind [m/s]', $
     title='Poker Flat 6300 Fabry-Perot Data for Spring 2009', yrange=[-350,350], /ystyle

end